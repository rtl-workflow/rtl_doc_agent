#!/usr/bin/env python3
"""Measure how good the testbench is: inject single bugs into the RTL and see whether a test fails.

Usage:
    python run_mutation.py <ip_dir> [--max N] [--jobs N] [--list]

Mutants are generated from the rtl_files of data/<ip>.yaml: compare, logic and arithmetic operators,
removed negations, and constants assigned to signals. Reset conditions and sensitivity lists are left
alone. Each mutant is compiled with VCS and run against the simulation test cases of 07_dv_plan,
seed 1, stopping at the first failing test.

A surviving mutant is either a hole in the testbench or an equivalent mutant (same behaviour), so a
person has to read the survivors. Results go to reports/mutation.json and contain RTL text: this
report is not for the testbench author, and it does not change the outcome of the flow.

Exit code 0 when the run completed, whatever the score. A failing baseline or a tool problem stops
the script with an "ERROR:" message and writes no report.
"""
import argparse
import json
import random
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_docs  # noqa: E402
import remote_exec  # noqa: E402
import run_regress  # noqa: E402

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except AttributeError:
    pass

REPORT = Path("reports") / "mutation.json"
BUILD = Path("dv") / "build" / "mutation"
REMOTE_TIMEOUT_S = 6 * 3600
DEFAULT_MAX = 60
DEFAULT_JOBS = 4
MIN_RUN_TIMEOUT_S = 120
SAMPLE_SEED = 1

SKIP_LINE = re.compile(r"\s*(`|module\b|endmodule\b|input\b|output\b|inout\b|parameter\b|localparam\b|reg\b|wire\b"
                       r"|integer\b|genvar\b|always\b|\)|$)")
SWAP = {"==": "!=", "!=": "==", ">=": ">", "<=": "<", "&&": "||", "||": "&&",
        ">": ">=", "<": "<=", "&": "|", "|": "&", "+": "-", "-": "+"}
RULE = {"==": "compare", "!=": "compare", ">=": "compare", "<=": "compare", ">": "compare", "<": "compare",
        "&&": "logic", "||": "logic", "&": "bitwise", "|": "bitwise", "+": "arith", "-": "arith"}
CONST_RHS = re.compile(r"\s*(?:#\s*`\w+\s+)?((\d+)'([bBdDhH])([0-9a-fA-F_]+))\s*;")


@dataclass
class Mutant:
    id: str
    file: str
    line: int
    rule: str
    before: str
    after: str
    source: str
    col: int


def is_operand_end(ch):
    return ch.isalnum() or ch in "_)]"


def constant_mutant(code, rhs):
    """(column, old text, new text) flipping bit 0 of a constant that is the whole right-hand side."""
    m = CONST_RHS.match(code[rhs:])
    if not m:
        return None
    width, base, digits = m.group(2), m.group(3).lower(), m.group(4).replace("_", "")
    try:
        value = int(digits, {"b": 2, "d": 10, "h": 16}[base])
    except ValueError:         # x / z digits
        return None
    return rhs + m.start(1), m.group(1), f"{width}'h{value ^ 1:x}"


def line_edits(code):
    """(rule, column, old, new) for every mutation of one line of code without its comment."""
    if SKIP_LINE.match(code) or "RST_" in code or "/*" in code:
        return []
    is_assign = code.lstrip().startswith("assign")
    edits, paren, bracket, rhs, i = [], 0, 0, None, 0
    while i < len(code):
        ch, two = code[i], code[i:i + 2]
        paren += (ch == "(") - (ch == ")")
        bracket += (ch == "[") - (ch == "]")
        prev = code[:i].rstrip()[-1:]
        binary = bool(prev) and is_operand_end(prev)
        if two in ("<<", ">>"):
            i += 2
            continue
        if two in ("==", "!=", ">=", "<=", "&&", "||"):
            if two == "<=" and paren == 0 and not is_assign:
                rhs = i + 2          # non-blocking assignment
            elif bracket == 0:
                edits.append((RULE[two], i, two, SWAP[two]))
            i += 2
            continue
        if ch == "=" and paren == 0 and bracket == 0:
            rhs = i + 1
        elif ch in "<>&|+-" and bracket == 0 and binary and (ch not in "<>" or paren > 0 or is_assign):
            edits.append((RULE[ch], i, ch, SWAP[ch]))
        elif ch in "!~" and bracket == 0 and code[i + 1:i + 2] not in ("=", "&", "|", "^"):
            edits.append(("negate", i, ch, ""))
        i += 1
    if rhs is not None:
        c = constant_mutant(code, rhs)
        if c:
            edits.append(("constant", *c))
    return edits


def generate(ip: Path, rtl_files):
    out = []
    for rel in rtl_files:
        lines = (ip / rel).read_text(encoding="utf-8", errors="replace").splitlines()
        for no, line in enumerate(lines, 1):
            for rule, col, old, new in line_edits(line.split("//", 1)[0]):
                out.append(Mutant(f"m{len(out) + 1:03d}", rel, no, rule, old, new, line.strip(), col))
    return out


def select(mutants, limit):
    if limit <= 0 or len(mutants) <= limit:
        return mutants
    chosen = set(random.Random(SAMPLE_SEED).sample(range(len(mutants)), limit))
    return [m for i, m in enumerate(mutants) if i in chosen]


def compile_rtl(ip: Path, work: Path, top_tb, srcs, incdirs):
    work.mkdir(parents=True, exist_ok=True)
    cmd = [run_regress.tool("vcs"), "-full64", "+v2k", "-timescale=1ns/1ps", "+vcs+lic+wait", "-top", top_tb,
           "-Mdir=csrc", "-o", "simv", "-l", "compile.log"] + [f"+incdir+{d}" for d in incdirs] + [str(s) for s in srcs]
    p = subprocess.run(cmd, cwd=work, capture_output=True, text=True, encoding="utf-8", errors="replace")
    out = p.stdout + p.stderr
    if p.returncode != 0 and run_regress.LICENSE_RE.search(out):
        raise SystemExit("ERROR: VCS license problem:\n" + "\n".join(out.splitlines()[-15:]))
    return p.returncode == 0, out


def run_test(work: Path, test, timeout):
    """'pass', or why the test failed."""
    try:
        p = subprocess.run([str((work / "simv").resolve()), f"+TEST={test}", "+SEED=1", "+vcs+lic+wait"], cwd=work,
                           capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout)
    except subprocess.TimeoutExpired:
        return "timeout"
    m = next((x for x in run_regress.RESULT_RE.finditer(p.stdout + p.stderr) if x.group(1) == test), None)
    if not m:
        return "no result"
    return "pass" if m.group(3) == "PASSED" and m.group(4) == "0" else "failed"


def evaluate(m: Mutant, ip: Path, build: Path, top_tb, sources, incdirs, tests, timeout):
    work = build / m.id
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    src = ip / m.file
    lines = src.read_bytes().decode("utf-8", errors="replace").splitlines(keepends=True)
    text = lines[m.line - 1]
    lines[m.line - 1] = text[:m.col] + m.after + text[m.col + len(m.before):]
    mutated = work / src.name
    mutated.write_bytes("".join(lines).encode("utf-8"))
    srcs = [mutated if s == src.resolve() else s for s in sources]
    ok, _ = compile_rtl(ip, work, top_tb, srcs, incdirs)
    result = {"status": "invalid", "killed_by": None, "reason": None}
    if ok:
        result["status"] = "survived"
        for test in tests:
            why = run_test(work, test, timeout)
            if why != "pass":
                result.update(status="killed", killed_by=test, reason=why)
                break
    shutil.rmtree(work, ignore_errors=True)
    return {**asdict(m), **result}


def run_local(ip: Path, limit, jobs):
    data, derrs, _ = gen_docs.outputs(ip)
    if derrs:
        raise SystemExit("ERROR: data file invalid, run check_docs.py first")
    tests = sorted(run_regress.plan_tests(ip), key=lambda t: "random" in t)
    tbs = run_regress.tb_files(ip)
    if not tests or not tbs:
        raise SystemExit("ERROR: no simulation test case or testbench to run")
    build, top_tb = ip / BUILD, f"{data['name']}_tb"
    shutil.rmtree(build, ignore_errors=True)
    sources = [(ip / f).resolve() for f in data["rtl_files"]] + [t.resolve() for t in tbs]
    incdirs = sorted({str(s.parent) for s in sources})

    base = build / "baseline"
    ok, out = compile_rtl(ip, base, top_tb, sources, incdirs)
    if not ok:
        raise SystemExit("ERROR: the unmodified design does not compile:\n" + "\n".join(out.splitlines()[-15:]))
    started = datetime.now()
    with ThreadPoolExecutor(jobs) as pool:
        verdicts = list(pool.map(lambda t: (t, run_test(base, t, run_regress.TEST_TIMEOUT_S)), tests))
    bad = [f"{t}: {v}" for t, v in verdicts if v != "pass"]
    if bad:
        raise SystemExit("ERROR: the regression fails on the unmodified design, fix that first: " + "; ".join(bad))
    timeout = max(MIN_RUN_TIMEOUT_S, int((datetime.now() - started).total_seconds()) * 5)

    every = generate(ip, data["rtl_files"])
    chosen = select(every, limit)
    print(f"{len(every)} mutants generated, running {len(chosen)} with {jobs} jobs", flush=True)
    results = []
    with ThreadPoolExecutor(jobs) as pool:
        futures = [pool.submit(evaluate, m, ip, build, top_tb, sources, incdirs, tests, timeout) for m in chosen]
        for n, f in enumerate(futures, 1):
            results.append(f.result())
            print(f"[{n}/{len(chosen)}] {results[-1]['id']} {results[-1]['status']}", flush=True)
    shutil.rmtree(build, ignore_errors=True)

    count = {s: sum(r["status"] == s for r in results) for s in ("killed", "survived", "invalid")}
    valid = count["killed"] + count["survived"]
    res = {"date": datetime.now().isoformat(timespec="seconds"), **run_regress.digests(ip, data),
           "generated": len(every), "run": len(chosen), **count,
           "score": round(100.0 * count["killed"] / valid, 2) if valid else None, "results": results}
    out_file = ip / REPORT
    out_file.parent.mkdir(parents=True, exist_ok=True)
    out_file.write_text(json.dumps(res, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return res


def run_remote(ip: Path, limit, jobs):
    try:
        fin = remote_exec.run_ip_script("run_mutation.py", ip, ["--max", limit, "--jobs", jobs], [REPORT.as_posix()],
                                        timeout=REMOTE_TIMEOUT_S)
    except remote_exec.RemoteError as e:
        raise SystemExit(f"ERROR: remote mutation run could not start (environment problem): {e}")
    if f"{ip.name}/{REPORT.as_posix()}" not in fin.files:
        raise SystemExit("ERROR: remote mutation run stopped before producing a report:\n" +
                         "\n".join(fin.output().splitlines()[-20:]))
    return json.loads((ip / REPORT).read_text(encoding="utf-8"))


def print_result(res):
    print(f"\nkilled {res['killed']}, survived {res['survived']}, not compilable {res['invalid']}; "
          f"{res['run']} of {res['generated']} generated mutants run")
    if res["score"] is not None:
        print(f"mutation score {res['score']:g}%")
    survivors = [r for r in res["results"] if r["status"] == "survived"]
    if survivors:
        print("\n| 编号 | 位置 | 变异 | 源码 |\n|---|---|---|---|")
        for r in survivors:
            print(f"| {r['id']} | {r['file']}:{r['line']} | `{r['before']}` -> `{r['after'] or '(删除)'}` | `{r['source']}` |")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ip_dir", type=Path)
    ap.add_argument("--max", type=int, default=DEFAULT_MAX, help=f"run at most N mutants, 0 for all (default {DEFAULT_MAX})")
    ap.add_argument("--jobs", type=int, default=DEFAULT_JOBS, help=f"parallel simulations (default {DEFAULT_JOBS})")
    ap.add_argument("--list", action="store_true", help="only print the mutants, nothing is run")
    a = ap.parse_args()
    ip = a.ip_dir.resolve()
    if a.list:
        data, derrs, _ = gen_docs.outputs(ip)
        if derrs:
            raise SystemExit("ERROR: data file invalid, run check_docs.py first")
        every = generate(ip, data["rtl_files"])
        for m in every:
            print(f"{m.id} {m.file}:{m.line} [{m.rule}] {m.before!r} -> {m.after!r}  {m.source}")
        print(f"{len(every)} mutants")
        return
    res = run_remote(ip, a.max, a.jobs) if remote_exec.enabled() else run_local(ip, a.max, a.jobs)
    print_result(res)


if __name__ == "__main__":
    main()
