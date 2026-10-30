#!/usr/bin/env python3
"""Run commands on the remote EDA server (no SSH there) through FTP and the server-side watcher.

The local side packs files, uploads a signed job to ~/jobs/inbox, waits for ~/jobs/outbox/<id>.done and
downloads the log and the collected files; remote_server/watcher.py runs the job with `bash -lc` (the
default module environment is loaded) and writes the results.

Library (run_lint.py / run_regress.py use it when RTLFLOW_EXEC=remote):
    enabled()                                     RTLFLOW_EXEC == "remote"
    run_ip_script(script, ip, args, collect)      push the IP and these scripts, run the script there with
                                                  the remote python, write the collected IP files back
    submit(...) / wait(...)                       any command

CLI:
    python remote_exec.py status
    python remote_exec.py run [--push DIR --dest '~/x' --clean] [--cwd '~/x'] [--collect GLOB ...] "CMD"
    python remote_exec.py wait|tail|kill <id>
    python remote_exec.py init | update | set-password

Configuration directory (REXEC_CONFIG, default ~/.rexec):
    rexec.ini   [server] host, port, user, python (remote interpreter, default python3.11)
    key         HMAC signing key shared with the watcher (created by `init`)
Password: Windows Credential Manager / keyring (`set-password`), or REXEC_PASS.

CLI exit codes: 0 ok; remote exit code on failure; 124 timeout; 130 killed;
                125 environment/infrastructure problem (license, watcher, network) - not a design bug;
                100 still running (use "wait <id>").
"""
import argparse
import configparser
import fnmatch
import ftplib
import getpass
import hashlib
import hmac
import io
import json
import os
import re
import secrets
import shlex
import shutil
import sys
import tarfile
import time
import warnings
from dataclasses import dataclass, field
from pathlib import Path, PureWindowsPath

SCRIPTS = Path(__file__).resolve().parent
SERVER_DIR = SCRIPTS / "remote_server"
FTP_JOBS = "/jobs"
KEYRING_SERVICE = "rexec-ftp"
DEFAULT_EXCLUDES = [".git", ".svn", "__pycache__", "*.pyc", ".rexec", ".vscode", ".idea"]
# never needed by the tool scripts on the server: build output, old reports, flow state
IP_EXCLUDES = ["dv/build", "reports", ".flow"]
TEXT_MAX = 20 << 20
HEARTBEAT_MAX_AGE = 60

EXIT_PENDING, EXIT_TIMEOUT, EXIT_INFRA, EXIT_KILLED = 100, 124, 125, 130


class RemoteError(Exception):
    """The remote environment could not run the job (network, login, watcher, server): not a design problem."""


def enabled():
    return os.environ.get("RTLFLOW_EXEC", "local").strip().lower() == "remote"


# ---------- config / secrets ----------
def config_dir():
    return Path(os.environ.get("REXEC_CONFIG") or Path.home() / ".rexec")


def load_cfg():
    d = config_dir()
    ini = d / "rexec.ini"
    if not ini.exists():
        raise RemoteError(f"no remote configuration: {ini} missing (set REXEC_CONFIG)")
    cp = configparser.ConfigParser()
    cp.read(ini, encoding="utf-8")
    s = cp["server"] if cp.has_section("server") else {}
    if not s.get("host") or not s.get("user"):
        raise RemoteError(f"{ini}: [server] host and user are required")
    return {"host": s["host"], "port": int(s.get("port", "21")), "user": s["user"],
            "python": s.get("python", "python3.11"), "dir": d}


def key_file(cfg):
    for p in (cfg["dir"] / "key", cfg["dir"] / ".rexec" / "key"):
        if p.exists():
            return p
    return cfg["dir"] / "key"


def load_key(cfg):
    p = key_file(cfg)
    if not p.exists():
        raise RemoteError(f"missing signing key {p}; run `python remote_exec.py init` first")
    return p.read_bytes().strip()


def get_password(cfg):
    if os.environ.get("REXEC_PASS"):
        return os.environ["REXEC_PASS"]
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            import keyring
        pw = keyring.get_password(KEYRING_SERVICE, f"{cfg['user']}@{cfg['host']}")
    except Exception:
        pw = None
    if not pw:
        raise RemoteError("no FTP password: run `python remote_exec.py set-password` in your own terminal, "
                          "or set REXEC_PASS")
    return pw


def canon(obj):
    body = {k: v for k, v in obj.items() if k != "sig"}
    return json.dumps(body, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def sign(obj, key):
    obj["sig"] = hmac.new(key, canon(obj), hashlib.sha256).hexdigest()
    return obj


# ---------- FTP ----------
class Remote:
    def __init__(self, cfg=None):
        self.cfg, self.ftp, self.pw = cfg or load_cfg(), None, None

    def conn(self):
        if self.ftp:
            try:
                self.ftp.voidcmd("NOOP")
                return self.ftp
            except Exception:
                self.close()
        if self.pw is None:
            self.pw = get_password(self.cfg)
        ftp = ftplib.FTP(timeout=30, encoding="utf-8")
        try:
            ftp.connect(self.cfg["host"], self.cfg["port"])
            ftp.login(self.cfg["user"], self.pw)
        except ftplib.error_perm as e:
            # no retry on bad credentials: repeated failures may lock the account
            raise RemoteError(f"FTP login failed: {e}")
        except OSError as e:
            raise RemoteError(f"cannot reach {self.cfg['host']}:{self.cfg['port']} ({e}); check VPN/network")
        ftp.set_pasv(True)
        self.ftp = ftp
        return ftp

    def close(self):
        if self.ftp:
            try:
                self.ftp.close()
            except Exception:
                pass
        self.ftp = None

    def _retry(self, fn):
        for attempt in range(3):
            try:
                return fn(self.conn())
            except (OSError, EOFError, ftplib.error_temp) as e:
                self.close()
                if attempt == 2:
                    raise RemoteError(f"FTP transfer failed: {e}")
                time.sleep(2)

    def put(self, path, data):
        self._retry(lambda f: f.storbinary(f"STOR {path}", io.BytesIO(data)))

    def get(self, path):
        """Return file content, or None when it does not exist."""
        def fn(f):
            buf = io.BytesIO()
            try:
                f.retrbinary(f"RETR {path}", buf.write)
            except ftplib.error_perm as e:
                if str(e).startswith("550"):
                    return None
                raise RemoteError(f"FTP RETR {path}: {e}")
            return buf.getvalue()
        return self._retry(fn)


# ---------- packing ----------
def excluded(rel, patterns):
    return any(fnmatch.fnmatch(rel.name, p) or fnmatch.fnmatch(rel.as_posix(), p) for p in patterns)


def pack(entries, extra_excludes=(), keep_crlf=False):
    """tar.gz of [(local file or dir, archive prefix)]; CRLF -> LF in text files unless keep_crlf."""
    files = []
    for src, prefix in entries:
        src = Path(src).resolve()
        if not src.exists():
            raise RemoteError(f"push path {src} does not exist")
        arc = (lambda rel: f"{prefix}/{rel}" if prefix else rel)
        if src.is_file():
            files.append((src, arc(src.name)))
            continue
        patterns = DEFAULT_EXCLUDES + list(extra_excludes)
        if (src / ".rexecignore").exists():
            patterns += [ln.strip() for ln in (src / ".rexecignore").read_text(encoding="utf-8").splitlines()
                         if ln.strip() and not ln.startswith("#")]
        for root, dirs, names in os.walk(src):
            rel_root = Path(root).relative_to(src)
            dirs[:] = sorted(d for d in dirs if not excluded(rel_root / d, patterns))
            files += [(Path(root) / n, arc((rel_root / n).as_posix())) for n in sorted(names)
                      if not excluded(rel_root / n, patterns)]
    buf, converted = io.BytesIO(), 0
    with tarfile.open(fileobj=buf, mode="w:gz") as tf:
        for path, name in files:
            data = path.read_bytes()
            if not keep_crlf and len(data) <= TEXT_MAX and b"\0" not in data and b"\r\n" in data:
                data = data.replace(b"\r\n", b"\n")
                converted += 1
            ti = tarfile.TarInfo(name)
            ti.size, ti.mtime = len(data), int(path.stat().st_mtime)
            ti.mode = 0o755 if path.suffix in (".sh", ".csh", ".py", ".pl", ".tcl") or data.startswith(b"#!") else 0o644
            tf.addfile(ti, io.BytesIO(data))
    return buf.getvalue(), len(files), converted


def remote_path(p):
    """Undo Git Bash (MSYS) argument rewriting: ~/x -> C:/Users/me/x, /home/x -> C:/Program Files/Git/home/x."""
    if not p or not re.match(r"^[A-Za-z]:[\\/]", p):
        return p
    wp = PureWindowsPath(p)
    roots = [(PureWindowsPath(Path.home()), "~")]
    if os.environ.get("EXEPATH"):
        roots.append((PureWindowsPath(os.environ["EXEPATH"]).parent, ""))
    roots.append((PureWindowsPath("C:/Program Files/Git"), ""))
    for root, prefix in roots:
        try:
            rel = wp.relative_to(root).as_posix()
        except ValueError:
            continue
        rel = "" if rel == "." else rel
        return f"{prefix}/{rel}" if prefix else f"/{rel}"
    raise RemoteError(f"{p!r} looks like a Windows path; use a server path like '~/proj' (quote it)")


# ---------- jobs ----------
@dataclass
class Finished:
    id: str
    done: dict
    log: str = ""
    summary: str = ""
    files: dict = field(default_factory=dict)     # collected path (relative to the remote cwd) -> bytes
    result_tar: bytes | None = None

    @property
    def status(self):
        return self.done.get("status")

    @property
    def exit_code(self):
        return self.done.get("exit_code")

    def output(self):
        """The command's own output, without the watcher's [rexec] lines."""
        return "\n".join(l for l in self.log.splitlines() if not l.startswith("[rexec] "))


def new_id():
    return time.strftime("%Y%m%d_%H%M%S") + "_" + secrets.token_hex(3)


def heartbeat(r):
    hb = r.get(f"{FTP_JOBS}/outbox/heartbeat.json")
    return json.loads(hb) if hb else None


def check_watcher(r):
    hb = heartbeat(r)
    if hb is None:
        raise RemoteError("watcher not installed: run `python remote_exec.py init`, then in VNC: bash ~/setup_watcher.sh")
    age = time.time() - hb["time"]
    if age > HEARTBEAT_MAX_AGE:
        raise RemoteError(f"watcher heartbeat is {age:.0f}s old, watcher seems down; "
                          "in a VNC terminal run: bash ~/jobs/setup_watcher.sh")
    return hb


def status(cfg=None):
    """(ok, message) for runners and health checks; never raises."""
    r = None
    try:
        r = Remote(cfg)
        hb = check_watcher(r)
        return True, f"watcher {hb['version']} on {hb['host']}: running {len(hb['running'])}, queued {len(hb['queued'])}"
    except RemoteError as e:
        return False, str(e)
    finally:
        if r:
            r.close()


def submit(r, cmd=None, *, push=(), dest=None, clean=False, cwd=None, collect=(), timeout=1800, excludes=(),
           keep_crlf=False, cleanup=False, meta=None, max_collect_mb=200, check=True):
    """Upload the payload and the signed job; returns (job id, upload info)."""
    key = load_key(r.cfg)
    if check:
        check_watcher(r)
    jid = new_id()
    job = {"id": jid, "created": time.time(), "cmd": cmd, "cwd": cwd, "timeout": timeout, "dest": dest,
           "clean": clean, "collect": list(collect), "max_collect_mb": max_collect_mb, "cleanup": cleanup,
           "meta": meta or {}, "payload": None}
    info = None
    if push:
        data, n, conv = pack(push, excludes, keep_crlf)
        job["payload"] = {"size": len(data), "sha256": hashlib.sha256(data).hexdigest()}
        r.put(f"{FTP_JOBS}/inbox/{jid}.tar.gz", data)
        info = {"files": n, "bytes": len(data), "converted": conv}
    sign(job, key)
    r.put(f"{FTP_JOBS}/inbox/{jid}.job.json", json.dumps(job, ensure_ascii=False).encode())
    return jid, job, info


def fetch(r, jid, done_bytes):
    done = json.loads(done_bytes)
    fin = Finished(jid, done)
    fin.log = (r.get(f"{FTP_JOBS}/outbox/{jid}.log") or b"").decode("utf-8", "replace")
    fin.summary = (r.get(f"{FTP_JOBS}/outbox/{jid}.summary.txt") or b"").decode("utf-8", "replace")
    if done.get("result"):
        fin.result_tar = r.get(f"{FTP_JOBS}/outbox/{done['result']}")
        if fin.result_tar:
            with tarfile.open(fileobj=io.BytesIO(fin.result_tar)) as tf:
                for m in tf.getmembers():
                    if m.isfile():
                        fin.files[m.name] = tf.extractfile(m).read()
    return fin


def wait(r, jid, wait_max):
    """Finished, or None when the job is still running after wait_max seconds."""
    deadline, delay = time.time() + wait_max, 1.0
    while True:
        done = r.get(f"{FTP_JOBS}/outbox/{jid}.done")
        if done is not None:
            return fetch(r, jid, done)
        if time.time() > deadline:
            return None
        time.sleep(delay)
        delay = min(delay * 1.5, 5.0)


def run_ip_script(script, ip, args=(), collect=(), timeout=3600, clean_local=()):
    """Run scripts/<script> on the server against a copy of the IP directory.

    The IP (without build output, reports and flow state) and the scripts of this directory are pushed;
    the command runs with RTLFLOW_EXEC=local there. Collected files (globs relative to the IP) are written
    back into `ip`, after deleting the local directories in `clean_local`. Raises RemoteError when the job
    could not run; the script's own failures are in the returned Finished (exit_code, output())."""
    ip = Path(ip).resolve()
    name = ip.name
    r = Remote()
    py = shlex.quote(r.cfg["python"])
    cmd = f"RTLFLOW_EXEC=local {py} scripts/{script} {shlex.quote(name)} " + " ".join(shlex.quote(str(a)) for a in args)
    meta = {"script": script, "ip": name}
    if os.environ.get("HUB_RUN_ID"):
        meta["hub_run_id"] = os.environ["HUB_RUN_ID"]
    try:
        jid, _, _ = submit(r, cmd, push=[(ip, name)] + [(p, "scripts") for p in sorted(SCRIPTS.glob("*.py"))],
                           excludes=IP_EXCLUDES, collect=[f"{name}/{c}" for c in collect], timeout=timeout,
                           cleanup=os.environ.get("RTLFLOW_REMOTE_KEEP") != "1", meta=meta)
        fin = wait(r, jid, timeout + 600)
    finally:
        r.close()
    if fin is None:
        raise RemoteError(f"remote job {jid} did not finish within {timeout + 600}s")
    if fin.status in ("error", "rejected", "timeout", "killed"):
        tail = "\n".join(fin.output().splitlines()[-20:])
        raise RemoteError(f"remote job {jid} {fin.status}: {fin.done.get('error') or ''}\n{tail}".rstrip())
    for d in clean_local:
        shutil.rmtree(ip / d, ignore_errors=True)
    for arc, data in fin.files.items():
        if arc.startswith(name + "/"):
            p = ip / arc[len(name) + 1:]
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(data)
    return fin


# ---------- CLI ----------
def runs_dir(cfg):
    return Path(os.environ.get("REXEC_RUNS") or cfg["dir"] / "runs")


def save_and_report(cfg, fin):
    d = runs_dir(cfg) / fin.id
    d.mkdir(parents=True, exist_ok=True)
    (d / "done.json").write_text(json.dumps(fin.done, ensure_ascii=False, indent=1), encoding="utf-8")
    (d / "log.txt").write_text(fin.log, encoding="utf-8")
    (d / "summary.txt").write_text(fin.summary, encoding="utf-8")
    if fin.result_tar:
        try:
            with tarfile.open(fileobj=io.BytesIO(fin.result_tar)) as tf:
                tf.extractall(d / "result", filter="data")
        except (tarfile.TarError, OSError) as e:
            (d / "result.tar.gz").write_bytes(fin.result_tar)
            print(f"[rexec] warning: could not extract result ({e}), saved {d / 'result.tar.gz'}")
    res = fin.done
    print(fin.summary or json.dumps(res, indent=1))
    print(f"[rexec] job {fin.id}: status={res['status']} exit={res['exit_code']} duration={res.get('duration')}s")
    print(f"[rexec] local files: {d}" + (f"  (collected files in {d / 'result'})" if (d / "result").exists() else ""))
    st = res["status"]
    if st == "ok":
        return 0
    if res.get("env_error") or st in ("error", "rejected"):
        print("[rexec] ENVIRONMENT/INFRA problem - check license/tools/watcher before changing code")
        return EXIT_INFRA
    if st == "timeout":
        return EXIT_TIMEOUT
    if st == "killed":
        return EXIT_KILLED
    rc = res.get("exit_code")
    return rc if isinstance(rc, int) and 0 < rc < 256 else 1


def cli_wait(r, jid, wait_max):
    fin = wait(r, jid, wait_max)
    if fin is None:
        print(f"[rexec] job {jid} still running after {wait_max}s; "
              f"check with `remote_exec.py tail {jid}`, collect with `remote_exec.py wait {jid}`")
        return EXIT_PENDING
    return save_and_report(r.cfg, fin)


def cmd_run(a, r):
    if not (a.cmd or a.push or a.collect):
        raise RemoteError("nothing to do: give a command, --push or --collect")
    if a.push and not a.dest:
        raise RemoteError("--push needs --dest (remote directory, e.g. '~/proj')")
    jid, job, info = submit(r, a.cmd, push=[(a.push, "")] if a.push else (), dest=remote_path(a.dest),
                            clean=a.clean, cwd=remote_path(a.cwd), collect=[remote_path(c) for c in a.collect],
                            timeout=a.timeout, excludes=a.exclude, keep_crlf=a.keep_crlf,
                            max_collect_mb=a.max_collect_mb, check=not a.no_check)
    if info:
        print(f"[rexec] uploaded {info['files']} files ({info['bytes'] / 1024:.1f} KiB, "
              f"{info['converted']} converted CRLF->LF) for {job['dest']}")
    d = runs_dir(r.cfg) / jid
    d.mkdir(parents=True, exist_ok=True)
    (d / "job.json").write_text(json.dumps(job, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"[rexec] submitted job {jid}")
    if a.async_:
        print(f"[rexec] running in background; `remote_exec.py wait {jid}` to collect results")
        return 0
    return cli_wait(r, jid, a.wait_max)


def cmd_wait(a, r):
    return cli_wait(r, a.id, a.wait_max)


def cmd_tail(a, r):
    data = r.get(f"{FTP_JOBS}/outbox/{a.id}.log")
    if data is None:
        print(f"[rexec] no log for {a.id} yet (queued, or unknown id)")
        return 1
    lines = data.decode("utf-8", "replace").splitlines()
    print("\n".join(lines[-a.n:]))
    done = r.get(f"{FTP_JOBS}/outbox/{a.id}.done")
    print(f"[rexec] {len(lines)} lines total; job " + ("finished" if done else "still running"))
    return 0


def cmd_kill(a, r):
    req = sign({"id": a.id, "action": "kill", "created": time.time()}, load_key(r.cfg))
    r.put(f"{FTP_JOBS}/inbox/{a.id}.kill.json", json.dumps(req).encode())
    print(f"[rexec] kill request sent for {a.id}; `remote_exec.py wait {a.id}` to confirm")
    return 0


def cmd_status(a, r):
    hb = heartbeat(r)
    if hb is None:
        print("[rexec] watcher not installed (no heartbeat)")
        return EXIT_INFRA
    age = time.time() - hb["time"]
    alive = age <= HEARTBEAT_MAX_AGE
    print(f"[rexec] watcher {'ALIVE' if alive else 'DOWN'}: version={hb['version']} pid={hb['pid']} "
          f"host={hb['host']} heartbeat {age:.0f}s ago max_parallel={hb.get('max_parallel')}")
    print(f"[rexec] running={hb['running']} queued={hb['queued']}")
    return 0 if alive else EXIT_INFRA


def server_file(name):
    return (SERVER_DIR / name).read_bytes().replace(b"\r\n", b"\n")


def cmd_init(a, r):
    kf = key_file(r.cfg)
    if not kf.exists():
        kf.parent.mkdir(parents=True, exist_ok=True)
        kf.write_text(secrets.token_hex(32))
        print(f"[rexec] generated signing key {kf}")
    r.put("/rexec_watcher.py", server_file("watcher.py"))
    r.put("/setup_watcher.sh", server_file("setup_watcher.sh"))
    r.put("/rexec.key", kf.read_bytes().strip() + b"\n")
    print("[rexec] uploaded rexec_watcher.py, setup_watcher.sh, rexec.key to your home directory")
    print("[rexec] now open a terminal in the VNC desktop and type:\n\n    bash ~/setup_watcher.sh\n")
    return 0


def cmd_update(a, r):
    before = heartbeat(r)
    r.put(f"{FTP_JOBS}/watcher.py", server_file("watcher.py"))
    print("[rexec] uploaded new watcher.py; it reloads when idle")
    if not before:
        return 0
    for _ in range(30):
        time.sleep(2)
        hb = heartbeat(r)
        if hb and hb.get("started") != before.get("started"):
            print(f"[rexec] watcher reloaded, version {hb['version']}")
            return 0
    print("[rexec] reload not confirmed yet (a job may be running); see `remote_exec.py status`")
    return 0


def cmd_set_password(a, r):
    import keyring
    cfg = r.cfg
    pw = getpass.getpass(f"Linux/FTP password for {cfg['user']}@{cfg['host']}: ")
    keyring.set_password(KEYRING_SERVICE, f"{cfg['user']}@{cfg['host']}", pw)
    print("[rexec] password stored in the system credential store")
    return 0


def main(argv=None):
    for s in (sys.stdout, sys.stderr):
        s.reconfigure(encoding="utf-8", errors="replace")
    p = argparse.ArgumentParser(prog="remote_exec", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="action", required=True)
    pr = sub.add_parser("run", help="submit a job (optionally push files / collect results) and wait")
    pr.add_argument("cmd", nargs="?", help="shell command, run with `bash -lc` (module env loaded)")
    pr.add_argument("--cwd", help="remote working dir (default: --dest, else ~/jobs/work/<id>)")
    pr.add_argument("--push", help="local file/dir to upload before running")
    pr.add_argument("--dest", help="remote dir to extract --push into (inside home)")
    pr.add_argument("--clean", action="store_true", help="delete --dest before extracting")
    pr.add_argument("--exclude", action="append", default=[], help="glob to skip when packing (repeatable)")
    pr.add_argument("--keep-crlf", action="store_true", help="do not convert CRLF to LF in text files")
    pr.add_argument("--collect", action="append", default=[],
                    help="remote glob (relative to cwd) to download after the command (repeatable, ** allowed)")
    pr.add_argument("--max-collect-mb", type=int, default=200)
    pr.add_argument("--timeout", type=int, default=1800, help="remote kill timeout, seconds")
    pr.add_argument("--wait-max", type=int, default=540, help="max seconds to wait locally before returning 100")
    pr.add_argument("--async", dest="async_", action="store_true", help="submit and return immediately")
    pr.add_argument("--no-check", action="store_true", help="skip watcher heartbeat check")
    pw_ = sub.add_parser("wait", help="wait for a job and download its results")
    pw_.add_argument("id")
    pw_.add_argument("--wait-max", type=int, default=540)
    pt = sub.add_parser("tail", help="show the latest lines of a job log")
    pt.add_argument("id")
    pt.add_argument("-n", type=int, default=50)
    pk = sub.add_parser("kill", help="kill a queued/running job")
    pk.add_argument("id")
    sub.add_parser("status", help="show watcher state")
    sub.add_parser("init", help="upload watcher, setup script and signing key")
    sub.add_parser("update", help="upload a new remote_server/watcher.py")
    sub.add_parser("set-password", help="store the FTP password in the system credential store")
    a = p.parse_args(argv)
    handler = {"run": cmd_run, "wait": cmd_wait, "tail": cmd_tail, "kill": cmd_kill, "status": cmd_status,
               "init": cmd_init, "update": cmd_update, "set-password": cmd_set_password}[a.action]
    r = None
    try:
        r = Remote()
        return handler(a, r)
    except RemoteError as e:
        print(f"[rexec] ERROR: {e}", file=sys.stderr)
        return EXIT_INFRA
    finally:
        if r:
            r.close()


if __name__ == "__main__":
    sys.exit(main())
