#!/usr/bin/env python3
"""Open an existing regression FSDB in remote Verdi, without rerunning VCS.

Usage: python open_verdi.py IP [--test tc_name] [--seed 1] [--display :1.0]
The latest run's last_result.json selects the immutable remote build. Launch
evidence is saved in reports/verdi.json; GUI status is distinct from simulation PASS.
"""
import argparse
import json
import shlex
import subprocess
import time
from pathlib import Path

import remote_exec


def launch(wave, database, display=None):
    import os
    import shutil
    wave, database = Path(wave), Path(database)
    record = {"fsdb": str(wave), "database": str(database), "status": "failed"}
    if not wave.is_file() or not wave.stat().st_size or not database.is_dir():
        raise RuntimeError("FSDB or KDB missing; retained remote workspace may have been removed")
    env = os.environ.copy()
    if display:
        env["DISPLAY"] = display
    record["display"] = env.get("DISPLAY", "")
    if not record["display"]:
        raise RuntimeError("DISPLAY missing; specify the existing VNC display with --display")
    subprocess.run(["xdpyinfo", "-display", record["display"]], env=env,
                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, check=True, timeout=20)
    exe = shutil.which("verdi")
    if not exe:
        raise RuntimeError("Verdi not found in remote tool environment")
    stamp = time.strftime("%Y%m%d_%H%M%S")
    folder = wave.parent / ("verdi_" + stamp)
    folder.mkdir(exist_ok=False)
    log = folder / "launch.log"
    cmd = [exe, "-full64", "-dbdir", str(database), "-ssf", str(wave)]
    before = subprocess.run(["xwininfo", "-root", "-tree", "-display", record["display"]],
                            env=env, capture_output=True, text=True, timeout=20)
    existing_ids = {line.strip().split()[0] for line in before.stdout.splitlines() if line.strip()}
    with log.open("w") as output:
        proc = subprocess.Popen(cmd, cwd=folder, env=env, stdin=subprocess.DEVNULL,
                                stdout=output, stderr=subprocess.STDOUT, start_new_session=True)
    record.update(pid=proc.pid, command=cmd, log=str(log), time=stamp)
    # Startup is asynchronous: require a real matching window, not just a live launcher.
    for _ in range(12):
        time.sleep(5)
        if proc.poll() is not None and proc.returncode != 0:
            break
        tree = subprocess.run(["xwininfo", "-root", "-tree", "-display", record["display"]],
                              env=env, capture_output=True, text=True, timeout=20)
        matches = [line.strip() for line in tree.stdout.splitlines()
                   if wave.name in line and ("Verdi" in line or "nWave" in line)
                   and line.strip().split()[0] not in existing_ids]
        if matches:
            record.update(status="opened", windows=matches)
            break
    (folder / "launch.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ip_dir", type=Path)
    parser.add_argument("--test")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--display")
    args = parser.parse_args()
    ip = args.ip_dir.resolve()
    report = json.loads((ip / "dv/build/regress/last_result.json").read_text(encoding="utf-8"))
    rows = [r for r in report["tests"] if r.get("fsdb") and r["seed"] == args.seed
            and (not args.test or r["test"] == args.test)]
    if not rows:
        parser.error("no matching FSDB in latest run; run VCS with default FSDB enabled")
    wave = rows[0]["fsdb"]["path"]
    database = report["waveforms"]["database"]
    if remote_exec.enabled():
        remote = remote_exec.Remote()
        try:
            py = remote.cfg["python"]
            code = ("import json; from open_verdi import launch_record; "
                    f"r=launch_record({wave!r}, {database!r}, {args.display!r}); "
                    "open('verdi.json','w').write(json.dumps(r,indent=2)); "
                    "print(json.dumps(r)); raise SystemExit(0 if r['status']=='opened' else 1)")
            command = f"{shlex.quote(py)} -c {shlex.quote(code)}"
            jid, _, _ = remote_exec.submit(remote, command,
                push=[(Path(__file__), ""), (Path(remote_exec.__file__), "")],
                collect=["verdi.json"], timeout=180)
            fin = remote_exec.wait(remote, jid, 240)
            if fin is None:
                raise RuntimeError(f"launch pending; remote_exec.py wait {jid}")
            if "verdi.json" not in fin.files:
                raise RuntimeError(fin.output())
            record = json.loads(fin.files["verdi.json"])
            record["job"] = jid
        finally:
            remote.close()
    else:
        record = launch_record(wave, database, args.display)
    record.update(test=rows[0]["test"], seed=args.seed)
    (ip / "reports").mkdir(exist_ok=True)
    (ip / "reports/verdi.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    print(json.dumps(record, indent=2))
    return 0 if record["status"] == "opened" else 1


def launch_record(wave, database, display=None):
    try:
        return launch(wave, database, display)
    except (OSError, RuntimeError, subprocess.SubprocessError) as exc:
        return {"status": "failed", "fsdb": str(wave), "database": str(database),
                "display": display, "error": str(exc)}


if __name__ == "__main__":
    raise SystemExit(main())
