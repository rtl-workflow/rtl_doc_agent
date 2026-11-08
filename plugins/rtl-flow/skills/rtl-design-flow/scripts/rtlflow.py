#!/usr/bin/env python3
"""rtl-flow one-time setup: after it, Claude Code and OpenCode run lint and simulation on the EDA server.

    python rtlflow.py setup              ask for the server account, deploy the watcher, verify the tools
    python rtlflow.py doctor             check that everything still works (no change is made)
    python rtlflow.py install-opencode   (re)connect rtl-flow to OpenCode; setup does this when OpenCode is found

Everything lives in ~/.rtl-flow (outside the plugin, so upgrades keep it); the password goes to the
system credential store. Run setup in your own terminal: the password must not pass through an AI chat.
"""
import argparse
import configparser
import getpass
import ftplib
import os
import re
import secrets
import shutil
import subprocess
import sys
import time
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
PLUGIN_ROOT = SCRIPTS.parents[2]
sys.path.insert(0, str(SCRIPTS))

DEFAULT_PORT = 21
REMOTE_PYTHON = "python3.11"
WATCHER_WAIT_S = 900
PROBE = ("for t in vcs sg_shell; do command -v $t >/dev/null || echo MISSING:$t; done; "
         f"{REMOTE_PYTHON} -c 'import yaml' 2>/dev/null || "
         f"{REMOTE_PYTHON} -m pip install --user -q pyyaml >/dev/null 2>&1 || echo MISSING:PyYAML; "
         "echo PROBE_DONE")


def say(msg=""):
    print(msg, flush=True)


def ensure_packages():
    """PyYAML (required) and keyring (password store)."""
    missing = []
    for module, package in (("yaml", "pyyaml"), ("keyring", "keyring")):
        try:
            __import__(module)
        except ImportError:
            missing.append(package)
    if missing:
        say(f"安装依赖：{', '.join(missing)}")
        in_venv = sys.prefix != sys.base_prefix          # pip refuses --user inside a virtual environment
        code = subprocess.call([sys.executable, "-m", "pip", "install", "-q"] + ([] if in_venv else ["--user"]) + missing)
        if code != 0 and "pyyaml" in missing:
            sys.exit(f"ERROR: 无法安装 PyYAML，请手动运行：{sys.executable} -m pip install pyyaml")


def read_ini(path: Path):
    cp = configparser.ConfigParser()
    if path.exists():
        cp.read(path, encoding="utf-8")
    return cp["server"] if cp.has_section("server") else {}


def write_ini(path: Path, host, port, user):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.parent.chmod(0o700)
    path.write_text("[server]\n"
                    f"host = {host}\nport = {port}\nuser = {user}\npython = {REMOTE_PYTHON}\n"
                    "# the password is not stored here: run `python rtlflow.py setup` to change it\n",
                    encoding="utf-8")


def ask(label, default=""):
    while True:
        value = input(f"{label}{f' [{default}]' if default else ''}: ").strip() or default
        if value:
            return value


def login(rx, cfg, password):
    """A logged-in Remote. One attempt only: repeated wrong passwords may lock the account."""
    r = rx.Remote(dict(cfg))
    r.pw = password
    try:
        r.conn()
    except rx.RemoteError as e:
        sys.exit(f"ERROR: 无法登录服务器：{e}\n请确认 VPN 已连接、账号和密码正确后重新运行 setup。")
    return r


def store_password(rx, cfg, password):
    key = f"{cfg['user']}@{cfg['host']}"
    try:
        import keyring
        keyring.set_password(rx.KEYRING_SERVICE, key, password)
        if keyring.get_password(rx.KEYRING_SERVICE, key) == password:
            (cfg["dir"] / rx.PASSWORD_FILE).unlink(missing_ok=True)
            say("密码已保存到系统凭据库。")
            return
    except Exception as e:  # noqa: BLE001 - no usable backend on this machine
        say(f"系统凭据库不可用（{type(e).__name__}）。")
    if input("是否保存到仅当前用户可读的本地文件？不保存则无法自动运行 [y/N]: ").strip().lower() != "y":
        sys.exit("未保存密码，配置未完成。")
    p = cfg["dir"] / rx.PASSWORD_FILE
    p.touch(mode=0o600, exist_ok=True)
    p.chmod(0o600)
    p.write_text(password, encoding="utf-8")
    say(f"密码已保存到 {p}。")


def local_watcher_version():
    text = (SCRIPTS / "remote_server" / "watcher.py").read_text(encoding="utf-8")
    return re.search(r'^VERSION = "([^"]+)"', text, re.M).group(1)


def alive(rx, r):
    """The watcher's heartbeat when it is fresh, else None."""
    hb = rx.heartbeat(r)
    return hb if hb and time.time() - hb["time"] <= rx.HEARTBEAT_MAX_AGE else None


def probe(rx, r):
    """Run a real job: returns (status, missing tools); status 'rejected' means another signing key."""
    jid, _, _ = rx.submit(r, PROBE, timeout=180, check=False)
    fin = rx.wait(r, jid, 200)
    if fin is None:
        return "timeout", []
    return fin.status, re.findall(r"^MISSING:(\S+)", fin.output(), re.M)


def deploy_watcher(rx, r, cfg):
    """Upload the watcher and key, then wait for the user to start it once in VNC."""
    before = rx.heartbeat(r)
    rx.cmd_init(None, r)
    say("=" * 60)
    say("只需这一次：请打开服务器的 VNC 桌面，在终端里粘贴并运行：")
    say()
    say("    bash ~/setup_watcher.sh")
    say()
    say("=" * 60)
    say("正在等待 watcher 上线（按 Ctrl+C 可退出，之后重新运行 setup 即可）...")
    deadline = time.time() + WATCHER_WAIT_S
    try:
        while time.time() < deadline:
            hb = alive(rx, r)
            if hb and (not before or hb.get("started") != before.get("started")):
                say(f"watcher 已上线（{hb['host']}）。")
                return
            time.sleep(3)
    except KeyboardInterrupt:
        sys.exit("\n已退出。在 VNC 运行上面的命令后，重新运行 setup。")
    sys.exit("ERROR: 等待超时，没有检测到 watcher。请确认已在 VNC 运行上面的命令，然后重新运行 setup。")


def report_missing(missing):
    if missing:
        sys.exit(f"ERROR: 账号的默认环境中缺少：{', '.join(missing)}。\n"
                 "这是服务器账号环境问题，请联系服务器管理员确认该账号登录后能使用这些工具，然后运行 doctor。")


def opencode_config_dir():
    base = os.environ.get("XDG_CONFIG_HOME")
    return (Path(base) if base else Path.home() / ".config") / "opencode"


def opencode_loader():
    return opencode_config_dir() / "plugins" / "rtl-flow.js"


def loader_text():
    target = (PLUGIN_ROOT / "opencode" / "rtl-flow.js").resolve().as_uri()
    python = Path(sys.executable).as_posix()
    return ("// Generated by rtlflow.py install-opencode; points at the rtl-flow plugin directory.\n"
            f'import {{ createPlugin }} from "{target}"\n\n'
            f'export const RtlFlow = createPlugin("{python}")\n')


def install_opencode():
    loader = opencode_loader()
    loader.parent.mkdir(parents=True, exist_ok=True)
    loader.write_text(loader_text(), encoding="utf-8")
    say(f"已接入 OpenCode：{loader}（重启 OpenCode 后生效）")


def warn_python_command():
    """The Claude Code hooks and the flow's commands call `python`: without it the role guard does not run."""
    if not shutil.which("python"):
        say("WARN  找不到 `python` 命令，权限隔离 hook 和流程命令依赖它。"
            "请安装提供该命令的软件包（如 Ubuntu 的 python-is-python3）。")


def cmd_setup(_):
    ensure_packages()
    warn_python_command()
    import remote_exec as rx

    d = rx.config_dir()
    ini = d / "rexec.ini"
    old = read_ini(ini)
    say("rtl-flow 配置（只需一次）。开始前请先连接 VPN。")
    say()
    host = ask("服务器地址", old.get("host", ""))
    port = int(old.get("port", DEFAULT_PORT))
    user = ask("服务器账号", old.get("user", ""))
    password = ""
    while not password:
        password = getpass.getpass("服务器密码（输入时不显示）: ")
    cfg = {"host": host, "port": port, "user": user, "python": REMOTE_PYTHON, "dir": d}

    say("\n正在登录...")
    r = login(rx, cfg, password)
    try:
        write_ini(ini, host, port, user)
        store_password(rx, cfg, password)
        kf = rx.key_file(cfg)
        if not kf.exists():
            kf.write_text(secrets.token_hex(32))
        kf.chmod(0o600)
        status = "none"
        if alive(rx, r):
            status, missing = probe(rx, r)
        if status != "ok":
            deploy_watcher(rx, r, cfg)
            say("正在验证远程工具...")
            status, missing = probe(rx, r)
        if status != "ok":
            sys.exit(f"ERROR: 远程验证任务失败（状态 {status}）。请运行 doctor 查看详情。")
        report_missing(missing)
        hb = alive(rx, r)
        if hb and hb.get("version") != local_watcher_version():
            rx.cmd_update(None, r)
    except ftplib.all_errors as e:
        sys.exit(f"ERROR: 与服务器通信失败：{e}。请确认 VPN 正常后重新运行 setup。")
    except rx.RemoteError as e:
        sys.exit(f"ERROR: {e}")
    finally:
        r.close()
    if shutil.which("opencode"):
        install_opencode()
    say("\n配置完成，VCS 和 SpyGlass 可用。之后在 Claude Code 或 OpenCode 中直接使用 rtl-flow，无需再次配置。")


def cmd_doctor(_):
    try:
        import yaml  # noqa: F401
    except ImportError:
        sys.exit("FAIL  缺少 PyYAML：请运行 setup")
    import remote_exec as rx

    warn_python_command()
    if not rx.configured():
        sys.exit(f'FAIL  尚未配置：请在终端运行 python "{Path(__file__).resolve()}" setup')
    say(f"OK    配置目录：{rx.config_dir()}")
    r = None
    try:
        r = rx.Remote()
        hb = alive(rx, r)
        if not hb:
            sys.exit("FAIL  watcher 未运行：请在服务器 VNC 终端执行 bash ~/jobs/setup_watcher.sh")
        say(f"OK    watcher 在线（版本 {hb['version']}，运行中 {len(hb['running'])}）")
        if hb.get("version") != local_watcher_version():
            say(f"WARN  watcher 版本与插件（{local_watcher_version()}）不一致：重新运行 setup 可更新")
        status, missing = probe(rx, r)
        if status == "rejected":
            sys.exit("FAIL  服务器拒绝了任务（本机签名密钥与服务器不一致）：请重新运行 setup")
        if status != "ok":
            sys.exit(f"FAIL  远程验证任务失败（状态 {status}）")
        if missing:
            sys.exit(f"FAIL  账号的默认环境中缺少：{', '.join(missing)}")
        say("OK    远程任务正常，vcs、sg_shell、PyYAML 可用")
    except rx.RemoteError as e:
        sys.exit(f"FAIL  {e}")
    finally:
        if r:
            r.close()
    if shutil.which("opencode"):
        if opencode_loader().exists():
            say("OK    已接入 OpenCode")
        else:
            say("WARN  检测到 OpenCode 但尚未接入：请运行 install-opencode")
    say("全部正常。")


def main():
    for s in (sys.stdout, sys.stderr):
        s.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("setup", "doctor", "install-opencode"):
        sub.add_parser(name)
    a = ap.parse_args()
    {"setup": cmd_setup, "doctor": cmd_doctor, "install-opencode": lambda _: install_opencode()}[a.cmd](a)


if __name__ == "__main__":
    main()
