"""Noninteractive, fail-closed EDA connection orchestration (no secret output)."""
import argparse
import base64
import hashlib
import hmac
import ipaddress
import json
import os
import re
import secrets
import socket
import time
from pathlib import Path

BOOTSTRAP = "bash -lc 'bash ~/setup_watcher.sh --if-stopped'"
PROBE = ("for t in vcs urg sg_shell; do command -v $t >/dev/null || echo MISSING:$t; done; "
         "python3.11 -c 'import yaml' 2>/dev/null || echo MISSING:PyYAML; echo PROBE_DONE")


class Stop(Exception):
    def __init__(self, action, code=2, **details):
        self.result = dict(status="required" if code == 2 else "error", action=action, **details)
        self.code = code


def port(value):
    try:
        n = int(value)
        if str(n) != str(value) or not 1 <= n <= 65535:
            raise ValueError
        return n
    except (ValueError, TypeError):
        raise Stop("invalid_input", 3, field="port") from None


def metadata(host, user):
    for field, value in (("host", host), ("user", user)):
        if not value or any(ord(c) < 32 or ord(c) == 127 for c in value):
            raise Stop("invalid_input", 3, field=field)
    if not re.fullmatch(r"[A-Za-z0-9_.@-]+", user) or user.startswith("-"):
        raise Stop("invalid_input", 3, field="user")
    try:
        ipaddress.ip_address(host)
    except ValueError:
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.-]*", host):
            raise Stop("invalid_input", 3, field="host", hint="Supply host only; use --port and --ssh-port separately.") from None


def secure_store():
    # Only the native Windows vault is accepted for newly collected secrets.
    try:
        from keyring.backends.Windows import WinVaultKeyring
        store = WinVaultKeyring()
        if os.name != "nt" or store.priority <= 0:
            raise RuntimeError
        return store
    except Exception:
        raise Stop("credential_store_required", hint="Install keyring with a working Windows Credential Manager backend.") from None


def credential_dialog(host, user):
    if os.name != "nt":
        raise Stop("credential_dialog_unavailable")
    import ctypes
    from ctypes import wintypes

    class Info(ctypes.Structure):
        _fields_ = [("cbSize", wintypes.DWORD), ("hwndParent", wintypes.HWND),
                    ("pszMessageText", wintypes.LPCWSTR), ("pszCaptionText", wintypes.LPCWSTR),
                    ("hbmBanner", wintypes.HANDLE)]

    dll = ctypes.WinDLL("credui", use_last_error=True)
    prompt = dll.CredUIPromptForCredentialsW
    prompt.argtypes = [ctypes.POINTER(Info), wintypes.LPCWSTR, ctypes.c_void_p,
                       wintypes.DWORD, wintypes.LPWSTR, wintypes.ULONG,
                       wintypes.LPWSTR, wintypes.ULONG, ctypes.POINTER(wintypes.BOOL), wintypes.DWORD]
    prompt.restype = wintypes.DWORD
    username = ctypes.create_unicode_buffer(user, 514)
    password = ctypes.create_unicode_buffer(514)
    save = wintypes.BOOL(False)
    info = Info(ctypes.sizeof(Info), None, "Enter the server password locally. It will be saved in Windows Credential Manager.",
                "rtl-flow server credentials", None)
    try:
        # GENERIC_CREDENTIALS | ALWAYS_SHOW_UI | DO_NOT_PERSIST | KEEP_USERNAME
        rc = prompt(ctypes.byref(info), host, None, 0, username, len(username),
                    password, len(password), ctypes.byref(save), 0x40000 | 0x80 | 0x2 | 0x100000)
        if rc == 1223:
            raise Stop("cancelled", 130)
        if rc or username.value != user or not password.value:
            raise Stop("credentials_required")
        return password.value
    finally:
        ctypes.memset(ctypes.addressof(password), 0, ctypes.sizeof(password))


def password_for(rx, cfg, existing, dialog):
    account = f"{cfg['user']}@{cfg['host']}"
    if dialog:
        store = secure_store()  # Check secure persistence before collecting a fresh secret.
        pw = credential_dialog(cfg["host"], cfg["user"])
        try:
            store.set_password(rx.KEYRING_SERVICE, account, pw)
            if store.get_password(rx.KEYRING_SERVICE, account) != pw:
                raise RuntimeError
        except Exception:
            raise Stop("credential_store_required") from None
        return pw
    pw = None
    if existing:
        try:
            import keyring
            pw = keyring.get_password(rx.KEYRING_SERVICE, account)
        except Exception:
            pass
    if pw:
        return pw
    try:
        store = secure_store()
        pw = store.get_password(rx.KEYRING_SERVICE, account)
    except Exception:
        store = None
    # Legacy file is eligible only after an exact endpoint match was established.
    if not pw and existing:
        legacy = cfg["dir"] / rx.PASSWORD_FILE
        if legacy.exists():
            pw = legacy.read_text(encoding="utf-8").strip()
    if pw:
        return pw
    raise Stop("credentials_required", hint="Rerun with --credential-dialog to enter the password locally.")


def ssh_preflight(cfg, ssh_port, pin, password):
    try:
        import paramiko
    except ImportError:
        raise Stop("dependency_required", package="paramiko", command="python -m pip install paramiko") from None
    transport = None
    try:
        sock = socket.create_connection((cfg["host"], ssh_port), timeout=10)
        transport = paramiko.Transport(sock)
        transport.start_client(timeout=10)
        key = transport.get_remote_server_key()
        fingerprint = "SHA256:" + base64.b64encode(hashlib.sha256(key.asbytes()).digest()).decode().rstrip("=")
        if pin:
            if not hmac.compare_digest(pin, fingerprint):
                raise Stop("ssh_host_key_mismatch", 3, fingerprint=fingerprint)
        else:
            known = paramiko.HostKeys()
            for filename in (Path.home() / ".ssh" / "known_hosts", Path("/etc/ssh/ssh_known_hosts")):
                if filename.is_file():
                    known.load(str(filename))
            name = cfg["host"] if ssh_port == 22 else f"[{cfg['host']}]:{ssh_port}"
            found = known.lookup(name)
            if not found:
                raise Stop("ssh_host_key_required", fingerprint=fingerprint,
                           hint="Verify this fingerprint independently, then supply --ssh-fingerprint.")
            if not known.check(name, key):
                raise Stop("ssh_host_key_mismatch", 3, fingerprint=fingerprint)
        # Authentication begins only after trust verification, on this same transport.
        transport.auth_timeout = 10
        agent = paramiko.Agent()
        try:
            for key in agent.get_keys():
                try:
                    transport.auth_publickey(cfg["user"], key)
                except paramiko.AuthenticationException:
                    continue
                if transport.is_authenticated():
                    break
        finally:
            agent.close()
        if not transport.is_authenticated():
            transport.auth_password(cfg["user"], password)
        if not transport.is_authenticated():
            raise Stop("ssh_auth_failed", 3)
        return transport
    except Stop:
        if transport:
            transport.close()
        raise
    except Exception as exc:
        if transport:
            transport.close()
        action = "ssh_auth_failed" if isinstance(exc, paramiko.AuthenticationException) else "ssh_connection_failed"
        raise Stop(action, 3) from None


def fresh(rx, hb):
    return hb and 0 <= time.time() - hb["time"] <= rx.HEARTBEAT_MAX_AGE


def signed_probe(rx, r, deadline):
    if time.monotonic() >= deadline:
        raise Stop("timeout", 124)
    jid, _, _ = rx.submit(r, PROBE, timeout=max(1, int(deadline - time.monotonic())), check=False)
    while time.monotonic() < deadline:
        data = r.get(f"{rx.FTP_JOBS}/outbox/{jid}.done")
        if data is not None:
            fin = rx.fetch(r, jid, data)
            if fin.status == "rejected":
                raise Stop("signing_key_mismatch", 3)
            if fin.status != "ok" or "PROBE_DONE" not in fin.output():
                raise Stop("probe_failed", 3)
            missing = re.findall(r"^MISSING:(\S+)", fin.output(), re.M)
            if missing:
                raise Stop("tools_missing", 3, tools=missing)
            if not fresh(rx, rx.heartbeat(r)):
                raise Stop("timeout", 124)
            return
        time.sleep(min(1, max(0, deadline - time.monotonic())))
    raise Stop("timeout", 124)


def deploy(rx, r, cfg):
    kf = rx.key_file(cfg)
    # Never replace either an existing server key or a local key on mismatch.
    remote_keys = [r.get("/rexec.key"), r.get("/jobs/rexec.key")]
    present = [k.strip() for k in remote_keys if k is not None]
    if present and (not kf.exists() or any(k != kf.read_bytes().strip() for k in present)):
        raise Stop("signing_key_mismatch", 3)
    if not kf.exists():
        kf.parent.mkdir(parents=True, exist_ok=True)
        with kf.open("x", encoding="utf-8") as stream:
            stream.write(secrets.token_hex(32))
        kf.chmod(0o600)
    r.put("/rexec_watcher.py", rx.server_file("watcher.py"))
    r.put("/setup_watcher.sh", rx.server_file("setup_watcher.sh"))
    if remote_keys[0] is None:
        r.put("/rexec.key", kf.read_bytes().strip() + b"\n")


def run(args, api, rx):
    r = ssh = None
    try:
        directory = rx.config_dir()
        ini = directory / "rexec.ini"
        old = api.read_ini(ini)
        host, user = args.host or old.get("host"), args.user or old.get("user")
        missing = [k for k, v in (("host", host), ("user", user)) if not v]
        if missing:
            raise Stop("input_required", fields=missing)
        metadata(host, user)
        ftp_port = port(args.port if args.port is not None else old.get("port", 21))
        ssh_port = port(args.ssh_port)
        if not 1 <= args.wait_seconds <= 900:
            raise Stop("invalid_input", 3, field="wait_seconds")
        if args.ssh_fingerprint and not re.fullmatch(r"SHA256:[A-Za-z0-9+/]{43}", args.ssh_fingerprint):
            raise Stop("invalid_input", 3, field="ssh_fingerprint")
        existing = bool(old)
        if existing and (host, user, ftp_port) != (old.get("host"), old.get("user"), port(old.get("port", 21))):
            raise Stop("endpoint_change_required", 3,
                       hint="Use a separate REXEC_CONFIG directory for a different server/account/FTP port.")
        cfg = dict(host=host, user=user, port=ftp_port, python="python3.11", dir=directory)
        password = password_for(rx, cfg, existing, args.credential_dialog)
        r = rx.Remote(cfg)
        r.pw = password
        r.conn()
        hb = rx.heartbeat(r)
        deadline = time.monotonic() + args.wait_seconds
        if fresh(rx, hb):
            if not rx.key_file(cfg).exists():
                raise Stop("signing_key_required", 3)
            signed_probe(rx, r, deadline)
        else:
            if hb and (hb.get("running") or hb.get("queued")):
                raise Stop("active_jobs", 3)
            if args.start_watcher == "ssh":
                ssh = ssh_preflight(cfg, ssh_port, args.ssh_fingerprint, password)
            # Recheck after preflight: never take over a watcher that came online meanwhile.
            hb = rx.heartbeat(r)
            if fresh(rx, hb):
                if not rx.key_file(cfg).exists():
                    raise Stop("signing_key_required", 3)
                signed_probe(rx, r, deadline)
            else:
                if hb and (hb.get("running") or hb.get("queued")):
                    raise Stop("active_jobs", 3)
                deploy(rx, r, cfg)
                if not existing:
                    api.write_ini(ini, host, ftp_port, user)
                if args.start_watcher == "manual":
                    raise Stop("bootstrap_required", command="bash ~/setup_watcher.sh --if-stopped",
                               hint="Run this in the server account terminal, then rerun connect.")
                hb = rx.heartbeat(r)
                if fresh(rx, hb):
                    signed_probe(rx, r, deadline)
                    return dict(status="ok", action="ready"), 0
                if hb and (hb.get("running") or hb.get("queued")):
                    raise Stop("active_jobs", 3)
                if time.monotonic() >= deadline:
                    raise Stop("timeout", 124)
                channel = ssh.open_session(timeout=10)
                try:
                    channel.settimeout(10)
                    channel.exec_command(BOOTSTRAP)
                    while not fresh(rx, rx.heartbeat(r)):
                        if channel.exit_status_ready() and channel.recv_exit_status() != 0:
                            raise Stop("bootstrap_failed", 3)
                        if time.monotonic() >= deadline:
                            raise Stop("timeout", 124)
                        time.sleep(min(1, max(0, deadline - time.monotonic())))
                    signed_probe(rx, r, deadline)
                finally:
                    channel.close()
        if not existing and not ini.exists():
            api.write_ini(ini, host, ftp_port, user)
        return dict(status="ok", action="ready"), 0
    except Stop as exc:
        return exc.result, exc.code
    except KeyboardInterrupt:
        return dict(status="error", action="cancelled"), 130
    except Exception:
        # Library exceptions may embed credentials: never serialize them.
        return dict(status="error", action="connection_failed"), 3
    finally:
        for connection in (ssh, r):
            if connection:
                try:
                    connection.close()
                except Exception:
                    pass  # Never let cleanup expose a library exception containing a secret.


def command(args, api):
    try:
        import remote_exec as rx
    except ImportError:
        result, code = dict(status="required", action="dependency_required", command="python -m pip install pyyaml"), 2
    else:
        result, code = run(args, api, rx)
    print(json.dumps(result, ensure_ascii=False))
    return code


class ArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        import sys
        if len(sys.argv) > 1 and sys.argv[1] == "connect":
            print(json.dumps(dict(status="error", action="invalid_input",
                                  hint="Check connect --help for accepted arguments.")))
            self.exit(3)
        super().error(message)


def add_parser(sub):
    parser = sub.add_parser("connect", help="Noninteractive EDA setup; emits JSON without passwords")
    parser.add_argument("--host")
    parser.add_argument("--user")
    parser.add_argument("--port", help="FTP port (default 21 or configured port)")
    parser.add_argument("--credential-dialog", action="store_true")
    parser.add_argument("--start-watcher", choices=("ssh", "manual"), default="manual")
    parser.add_argument("--ssh-port", default="22")
    parser.add_argument("--ssh-fingerprint")
    parser.add_argument("--wait-seconds", type=int, default=60)
