#!/usr/bin/env python3
"""Run the IP regression with Synopsys VCS and save a structured result.

Usage:
    python run_regress.py <ip_dir> [--stub] [--test NAME] [--seeds N]

Where it runs: with RTLFLOW_EXEC=remote (the EDA server is reached through remote_exec.py) the IP
is copied to the server, this script runs there, and the report and logs are written back here;
otherwise VCS must be in PATH (module load vcs).

Code coverage: a full RTL run compiles and runs with -cm, limited to <ip>_tb.U_dut, merges all runs
with urg and records the percentages under "coverage" in the report (details: dv/build/regress/urgReport).
Coverage does not change PASS/FAIL here; check_docs.py compares it with the goals of 07 §5.

Test list: the test cases of doc/07_dv_plan.md §3 whose 测试活动 is 仿真 (tc_* ids), each
mapped to the test points it covers. Older plans: the "用例" column (backticked names). Tests whose name contains "random" run with
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
import dv_plan  # noqa: E402
import gen_docs  # noqa: E402
import remote_exec  # noqa: E402

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except AttributeError:
    pass

REPORT = Path("reports") / "regress.json"
STUB_REPORT = Path("dv") / "build" / "stub" / "result.json"
LAST = "last_result.json"
COV_METRICS = "line+cond+fsm+tgl+branch"
COV_DB = "cov.vdb"
COV_REPORT = "urgReport"
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
        raise SystemExit(remote_exec.missing_tool_message(name))
    return path


def vcs_messages(text, limit=40):
    """One line per VCS Error/Warning/Lint block: 'Error-[ID] title | file, line | detail'."""
    out = [" | ".join(l.strip() for l in m.group(0).splitlines() if l.strip())[:400]
           for m in VCS_MSG_RE.finditer(text)]
    return out[:limit]


def parse_dashboard(text):
    """{metric: percent or None} from the first summary table of urg's dashboard.txt."""
    lines = text.splitlines()
    for i, line in enumerate(lines[:-1]):
        names = line.split()
        if names[:1] == ["SCORE"]:
            values = lines[i + 1].split()
            if len(values) < len(names):
                return {}
            return {n.lower(): (float(v) if re.fullmatch(r"\d+(\.\d+)?", v) else None)
                    for n, v in zip(names, values)}
    return {}


def collect_coverage(build: Path):
    """Merge the coverage of all runs with urg; 'error' is set when no figures could be read."""
    shutil.rmtree(build / COV_REPORT, ignore_errors=True)
    try:
        p = subprocess.run([tool("urg"), "-full64", "-dir", COV_DB, "-format", "text", "-report", COV_REPORT],
                           cwd=build, capture_output=True, text=True, encoding="utf-8", errors="replace",
                           timeout=TEST_TIMEOUT_S)
    except subprocess.TimeoutExpired:
        return {"metrics": {}, "report": None, "error": f"urg killed after {TEST_TIMEOUT_S} s"}
    out = p.stdout + p.stderr
    if p.returncode != 0 and LICENSE_RE.search(out):
        raise SystemExit("ERROR: urg license problem:\n" + "\n".join(out.splitlines()[-15:]))
    dash = build / COV_REPORT / "dashboard.txt"
    metrics = parse_dashboard(dash.read_text(encoding="utf-8", errors="replace")) if dash.exists() else {}
    if not any(v is not None for v in metrics.values()):
        tail = " | ".join(l.strip() for l in out.splitlines() if l.strip())[-400:]
        return {"metrics": {}, "report": None, "error": f"no coverage figures from urg (exit {p.returncode}): {tail}"}
    return {"metrics": metrics, "report": f"dv/build/regress/{COV_REPORT}/dashboard.txt", "error": None}


def plan_tests(ip: Path):
    """{test: [test point, ...]} from 07_dv_plan §3."""
    p = ip / "doc" / "07_dv_plan.md"
    if not p.exists():
        return {}
    raw = p.read_text(encoding="utf-8", errors="replace")
    cases = dv_plan.parse(raw).cases
    if cases:
        return {c.id: c.tps for c in cases if c.simulated}
    # older format: TP-xxx rows with a 用例 column
    text = re.sub(r"```.*?```", "", raw, flags=re.S)
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


def remote_job(stub=False, only=None, seeds=3):
    """(script arguments, build directory, files to collect) of a remote run."""
    build = f"dv/build/{'stub' if stub else 'regress'}"
    args = (["--stub"] if stub else []) + (["--test", only] if only else []) + ["--seeds", seeds]
    collect = [f"{build}/{LAST}", f"{build}/compile.log", f"{build}/logs/**"]
    if not only:
        collect.append((STUB_REPORT if stub else REPORT).as_posix())
        if not stub:
            collect.append(f"{build}/{COV_REPORT}/**")
    return args, build, collect


def remote_result(ip: Path, build, fin):
    last = ip / build / LAST
    if f"{ip.name}/{build}/{LAST}" not in fin.files:
        raise SystemExit("ERROR: remote regression stopped before producing a result:\n" +
                         "\n".join(fin.output().splitlines()[-20:]))
    return json.loads(last.read_text(encoding="utf-8"))


def run_remote(ip: Path, stub=False, only=None, seeds=3):
    """Run this script on the EDA server; the report and logs come back into `ip`."""
    ip = ip.resolve()
    args, build, collect = remote_job(stub, only, seeds)
    try:
        fin = remote_exec.run_ip_script("run_regress.py", ip, args, collect, timeout=REMOTE_TIMEOUT_S,
                                        clean_local=[build])
    except remote_exec.RemoteError as e:
        raise SystemExit(f"ERROR: remote regression could not run (environment problem): {e}")
    return remote_result(ip, build, fin)


def start_remote(ip: Path, stub=False, seeds=3):
    """Submit a full remote run without waiting; returns the job id for poll_remote."""
    args, _, collect = remote_job(stub, None, seeds)
    try:
        return remote_exec.start_ip_script("run_regress.py", ip.resolve(), args, collect, timeout=REMOTE_TIMEOUT_S)
    except remote_exec.RemoteError as e:
        raise SystemExit(f"ERROR: remote regression could not start (environment problem): {e}")


def poll_remote(ip: Path, jid, stub=False):
    """The result of a job from start_remote, or None while it runs (NetworkError when unreachable)."""
    ip = ip.resolve()
    _, build, _ = remote_job(stub)
    try:
        fin = remote_exec.poll_ip_script(ip, jid, clean_local=[build])
    except remote_exec.NetworkError:
        raise
    except remote_exec.RemoteError as e:
        raise SystemExit(f"ERROR: remote regression could not run (environment problem): {e}")
    return None if fin is None else remote_result(ip, build, fin)


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
        res["problems"].append("07_dv_plan §3 lists no simulation test case (tc_* with 测试活动 仿真)")
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
    cov_args = []
    if not stub:
        shutil.rmtree(build / COV_DB, ignore_errors=True)
        (build / "cov.hier").write_text(f"+tree {top_tb}.U_dut\n", encoding="utf-8")
        cov_args = ["-cm", COV_METRICS, "-cm_dir", COV_DB]
    # +vcs+lic+wait: queue for a license instead of failing when all are in use
    comp = subprocess.run([tool("vcs"), "-full64", "+v2k", "-timescale=1ns/1ps", "+vcs+lic+wait",
                           "-top", top_tb, "-Mdir=csrc", "-o", "simv", "-l", "compile.log"]
                          + cov_args + (["-cm_hier", "cov.hier"] if cov_args else [])
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
            p = subprocess.run([str(simv.resolve()), f"+TEST={test}", f"+SEED={seed}", "+vcs+lic+wait"]
                               + cov_args + (["-cm_name", f"{test}_{seed}"] if cov_args else []),
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
    if not stub and not only and res["tests"]:
        res["coverage"] = collect_coverage(build)
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
    figures = {k: v for k, v in (res.get("coverage") or {}).get("metrics", {}).items() if v is not None}
    if figures:
        res["summary"] += "; code coverage " + ", ".join(f"{k} {v:g}%" for k, v in figures.items())
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
    if (res.get("coverage") or {}).get("error"):
        print(f"COVERAGE UNAVAILABLE: {res['coverage']['error']}")
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
