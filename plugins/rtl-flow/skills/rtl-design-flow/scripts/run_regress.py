#!/usr/bin/env python3
"""Run the IP regression with Synopsys VCS and save a structured result.

Usage:
    python run_regress.py <ip_dir> [--stub] [--test NAME] [--seeds N]

Where it runs: with RTLFLOW_EXEC=remote (the EDA server is reached through remote_exec.py) the IP
is copied to the server, this script runs there, and the report and logs are written back here;
otherwise VCS must be in PATH (module load vcs).

Test list: the "用例" column of doc/07_dv_plan.md §3 (backticked names, e.g. `test_reset`);
each test is mapped to the TP of its row. Tests whose name contains "random" run with
seeds 1..N (default 3), the others with seed 1.

Testbench convention (rtl-coding-style §10): every file dv/tb/*.v is compiled (Verilog-2001, +v2k),
top module <ip>_tb, `simv +TEST=<name> +SEED=<n>`; the TB prints
    [<time>] ERROR: <msg>                       on every check failure
    COVER <name>=<hits>                         functional cover counters
    TEST <name> [SEED <n>] PASSED|FAILED errors=<n>
and has a watchdog that prints a FAILED line and calls $finish.

Modes:
    default  RTL from data/<ip>.yaml (rtl_files) + TB  -> reports/regress.json
    --stub   a port stub generated from data/<ip>.yaml replaces the RTL (outputs tied to 0).
             Used by the TB author, who must not see the RTL: it only proves the TB compiles,
             knows every test name and terminates.          -> dv/build/stub/result.json

The json records digests of the RTL, TB and test list; flow.py uses them to decide
whether the result is current. Every run (also --test) leaves dv/build/<mode>/last_result.json.
Exit code 0 if every test passed (stub: every test ran); 1 otherwise. A missing simulator, a
license failure or an unreachable server stop the script with an "ERROR:" message (exit 1, no
report written): an environment problem, not a design one.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_docs  # noqa: E402
import remote_exec  # noqa: E402

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except AttributeError:
    pass

REPORT = Path("reports") / "regress.json"
STUB_REPORT = Path("dv") / "build" / "stub" / "result.json"
LAST = "last_result.json"
TEST_TIMEOUT_S = 600
REMOTE_TIMEOUT_S = 6 * 3600
RESULT_RE = re.compile(r"^TEST (\S+) (?:SEED (\d+) )?(PASSED|FAILED) errors=(\d+)", re.M)
# VCS message blocks: "Error-[ID] title" followed by "file, line" and detail lines up to a blank line
VCS_MSG_RE = re.compile(r"^(Error|Warning|Lint)-\[[^\]]+\].*?(?=^\s*$|\Z)", re.M | re.S)
LICENSE_RE = re.compile(r"licen[cs]e.*(fail|error|unavailable|not available|checkout|denied)"
                        r"|unable to (check ?out|obtain).*licen|FLEXnet|lmgrd", re.I)


def tool(name):
    path = shutil.which(name)
    if not path:
        raise SystemExit(f"ERROR: '{name}' not found in PATH: load the EDA module (module load vcs), "
                         "or set RTLFLOW_EXEC=remote to run on the EDA server")
    return path


def vcs_messages(text, limit=40):
    """One line per VCS Error/Warning/Lint block: 'Error-[ID] title | file, line | detail'."""
    out = [" | ".join(l.strip() for l in m.group(0).splitlines() if l.strip())[:400]
           for m in VCS_MSG_RE.finditer(text)]
    return out[:limit]


def plan_tests(ip: Path):
    """{test: [TP-xxx, ...]} from the 用例 column of 07_dv_plan §3."""
    p = ip / "doc" / "07_dv_plan.md"
    if not p.exists():
        return {}
    text = re.sub(r"```.*?```", "", p.read_text(encoding="utf-8", errors="replace"), flags=re.S)
    m = re.search(r"^## 3\.[^\n]*\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    tests, col = {}, None
    for line in (m.group(1) if m else "").splitlines():
        s = line.strip()
        if not s.startswith("|") or re.fullmatch(r"\|[\s:\-|]+\|?", s):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if col is None:
            col = next((i for i, c in enumerate(cells) if "用例" in c), None)
            continue
        if col < len(cells) and re.fullmatch(r"TP-\d{3}", cells[0]):
            for t in re.findall(r"`([A-Za-z_]\w*)`", cells[col]):
                tests.setdefault(t, []).append(cells[0])
    return tests


def tb_files(ip: Path):
    return sorted((ip / "dv" / "tb").glob("*.v"))


def digest(ip: Path, files):
    h = hashlib.sha256()
    for f in files:
        h.update(f.relative_to(ip).as_posix().encode() + b"\0")
        h.update(f.read_bytes().replace(b"\r\n", b"\n") + b"\0")
    return h.hexdigest()


def digests(ip: Path, data):
    """Digests that decide whether a regression result is current."""
    rtl = [ip / f for f in data.get("rtl_files") or [] if (ip / f).exists()]
    return {"rtl_sha256": digest(ip, rtl),
            "tb_sha256": digest(ip, tb_files(ip)),
            "tests_sha256": hashlib.sha256(json.dumps(plan_tests(ip), sort_keys=True).encode()).hexdigest()}


def width_decl(w):
    if w == 1:
        return ""
    return f"[{w - 1}:0] " if isinstance(w, int) else f"[{w}-1:0] "


def gen_stub(data):
    """Verilog-2001 module with the top-level ports of data/<ip>.yaml; outputs tied to 0."""
    params = [p for p in data.get("params") or [] if not p.get("local")]
    lines = ["`timescale 1ns / 1ps", "// Port stub generated by run_regress.py --stub (no RTL behaviour)"]
    head = f"module {data['top']}"
    if params:
        plist = ",\n".join(f"    parameter {p['name']} = {p['default']}" for p in params)
        head += f" #(\n{plist}\n)"
    ports = data["ports"]
    plines = [f"    {p['dir']} {width_decl(p['width'])}{p['name']}" for p in ports]
    lines += [head + " (", ",\n".join(plines), ");"]
    for p in ports:
        if p["dir"] == "output":
            lines.append(f"assign {p['name']} = 0;")
    lines += ["endmodule", ""]
    return "\n".join(lines)


def run_remote(ip: Path, stub=False, only=None, seeds=3):
    """Run this script on the EDA server; the report and logs come back into `ip`."""
    ip = ip.resolve()
    mode = "stub" if stub else "regress"
    args = (["--stub"] if stub else []) + (["--test", only] if only else []) + ["--seeds", seeds]
    build = f"dv/build/{mode}"
    collect = [f"{build}/{LAST}", f"{build}/compile.log", f"{build}/logs/**"]
    if not only:
        collect.append((STUB_REPORT if stub else REPORT).as_posix())
    try:
        fin = remote_exec.run_ip_script("run_regress.py", ip, args, collect, timeout=REMOTE_TIMEOUT_S,
                                        clean_local=[build])
    except remote_exec.RemoteError as e:
        raise SystemExit(f"ERROR: remote regression could not run (environment problem): {e}")
    last = ip / build / LAST
    if f"{ip.name}/{build}/{LAST}" not in fin.files:
        raise SystemExit("ERROR: remote regression stopped before producing a result:\n" +
                         "\n".join(fin.output().splitlines()[-20:]))
    return json.loads(last.read_text(encoding="utf-8"))


def run(ip: Path, stub=False, only=None, seeds=3):
    """Run the regression and return the result dict (also written to the report file)."""
    if remote_exec.enabled():
        return run_remote(ip, stub, only, seeds)
    data, derrs, _ = gen_docs.outputs(ip)
    if derrs:
        raise SystemExit("ERROR: data file invalid, run check_docs.py first")
    tests = plan_tests(ip)
    build = ip / "dv" / "build" / ("stub" if stub else "regress")
    (build / "logs").mkdir(parents=True, exist_ok=True)
    res = {"mode": "stub" if stub else "rtl", "date": datetime.now().isoformat(timespec="seconds"),
           **digests(ip, data), "compile": {"ok": False, "messages": []}, "tests": [], "cover": {},
           "uncovered": [], "problems": []}

    tbs = tb_files(ip)
    top_tb = f"{data['name']}_tb"
    if not tests:
        res["problems"].append("07_dv_plan §3 lists no test (用例 column, backticked names)")
    if not tbs:
        res["problems"].append("no testbench file in dv/tb/*.v")
    if stub:
        stub_file = build / f"{data['top']}_stub.v"
        stub_file.write_text(gen_stub(data), encoding="utf-8")
        srcs = [stub_file]
    else:
        srcs = [ip / f for f in data.get("rtl_files") or []]
        missing = [str(s.relative_to(ip)) for s in srcs if not s.exists()]
        if missing:
            res["problems"].append(f"rtl files missing: {', '.join(missing)}")
    if res["problems"]:
        return finish(ip, res, stub)

    simv = build / "simv"
    # +vcs+lic+wait: queue for a license instead of failing when all are in use
    comp = subprocess.run([tool("vcs"), "-full64", "+v2k", "-timescale=1ns/1ps", "+vcs+lic+wait",
                           "-top", top_tb, "-Mdir=csrc", "-o", "simv", "-l", "compile.log"]
                          + [str(s.resolve()) for s in srcs + tbs],
                          cwd=build, capture_output=True, text=True, encoding="utf-8", errors="replace")
    out = comp.stdout + comp.stderr
    if comp.returncode != 0 and LICENSE_RE.search(out):
        raise SystemExit("ERROR: VCS license problem:\n" + "\n".join(out.splitlines()[-15:]))
    msgs = vcs_messages(out)
    if comp.returncode != 0 and not msgs:
        msgs = [l for l in out.splitlines() if l.strip()][-20:]
    res["compile"] = {"ok": comp.returncode == 0, "messages": msgs}
    if comp.returncode != 0:
        res["problems"].append("compile failed")
        return finish(ip, res, stub)

    runs = []
    for t in tests:
        if only and t != only:
            continue
        runs += [(t, s) for s in range(1, seeds + 1)] if "random" in t else [(t, 1)]
    for test, seed in runs:
        log = build / "logs" / f"{test}_{seed}.log"
        try:
            p = subprocess.run([str(simv.resolve()), f"+TEST={test}", f"+SEED={seed}", "+vcs+lic+wait"],
                               cwd=build, capture_output=True, text=True, encoding="utf-8", errors="replace",
                               timeout=TEST_TIMEOUT_S)
            out = p.stdout + p.stderr
        except subprocess.TimeoutExpired as e:
            out = (e.stdout or b"").decode(errors="replace") if isinstance(e.stdout, bytes) else (e.stdout or "")
            out += f"\n<run_regress: killed after {TEST_TIMEOUT_S} s>"
        log.write_text(out, encoding="utf-8")
        m = next((x for x in RESULT_RE.finditer(out) if x.group(1) == test), None)
        errs = [l.strip() for l in out.splitlines() if "ERROR" in l]
        res["tests"].append({"test": test, "tp": tests[test], "seed": seed,
                             "status": m.group(3) if m else "NO RESULT",
                             "errors": int(m.group(4)) if m else None,
                             "first_errors": errs[:5], "log": log.relative_to(ip).as_posix()})
        for name, n in re.findall(r"^COVER (\w+)=(\d+)", out, re.M):
            res["cover"][name] = res["cover"].get(name, 0) + int(n)
    res["uncovered"] = sorted(n for n, c in res["cover"].items() if c == 0)
    return finish(ip, res, stub, partial=bool(only))


def finish(ip: Path, res, stub, partial=False):
    t = res["tests"]
    if stub:
        ok = not res["problems"] and all(x["status"] != "NO RESULT" for x in t)
    else:
        ok = (not res["problems"] and bool(t) and all(x["status"] == "PASSED" for x in t)
              and (partial or not res["uncovered"]))
    res["result"] = "PASS" if ok else "FAIL"
    res["summary"] = (f"{sum(x['status'] == 'PASSED' for x in t)}/{len(t)} passed; "
                      f"{len(res['cover']) - len(res['uncovered'])}/{len(res['cover'])} cover points hit")
    text = json.dumps(res, ensure_ascii=False, indent=2) + "\n"
    if not partial:
        out = ip / (STUB_REPORT if stub else REPORT)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
    last = ip / "dv" / "build" / ("stub" if stub else "regress") / LAST
    last.parent.mkdir(parents=True, exist_ok=True)
    last.write_text(text, encoding="utf-8")
    return res


def print_result(res):
    for p in res["problems"]:
        print(f"PROBLEM  {p}")
    for m in res["compile"]["messages"]:
        print(f"compile: {m}")
    if res["tests"]:
        print("\n| 用例 | 测试点 | 种子 | 结果 | 错误数 |")
        print("|---|---|---|---|---|")
        for x in res["tests"]:
            print(f"| {x['test']} | {', '.join(x['tp'])} | {x['seed']} | {x['status']} | {x['errors']} |")
    if res["cover"]:
        print("\n| 覆盖点 | 命中次数 |")
        print("|---|---|")
        for n in sorted(res["cover"]):
            print(f"| {n} | {res['cover'][n]} |")
    for x in res["tests"]:
        if x["status"] != "PASSED" and res["mode"] == "rtl":
            print(f"FAILED {x['test']} seed={x['seed']}: {(x['first_errors'] or [''])[0]}  (log: {x['log']})")
    if res["uncovered"]:
        print("UNCOVERED: " + ", ".join(res["uncovered"]))
    print(f"\n[{res['mode']}] {res['result']}: {res['summary']}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ip_dir", type=Path)
    ap.add_argument("--stub", action="store_true", help="run the TB against a port stub instead of the RTL")
    ap.add_argument("--test", help="run a single test (result file is not written)")
    ap.add_argument("--seeds", type=int, default=3, help="seeds for tests named *random* (default 3)")
    a = ap.parse_args()
    res = run(a.ip_dir.resolve(), a.stub, a.test, a.seeds)
    print_result(res)
    sys.exit(0 if res["result"] == "PASS" else 1)


if __name__ == "__main__":
    main()
