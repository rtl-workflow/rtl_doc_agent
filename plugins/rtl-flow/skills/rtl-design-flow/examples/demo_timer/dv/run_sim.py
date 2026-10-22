#!/usr/bin/env python3
"""demo_timer regression runner (Icarus Verilog).

Usage:
    python dv/run_sim.py [--test NAME] [--seeds N]

Compiles RTL (file list from data/demo_timer.yaml) + dv/tb/tb_demo_timer.sv,
runs every test, aggregates COVER counters, prints a markdown summary.
Logs: dv/build/logs/<test>_<seed>.log.  Exit code 1 on any failure or uncovered point.
"""
import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

IP_DIR = Path(__file__).resolve().parent.parent
DV_DIR = IP_DIR / "dv"
BUILD = DV_DIR / "build"

# 测试名 -> 测试点，与 doc/07_dv_plan.md §3 一致
TESTS = {
    "test_reset": "TP-001",
    "test_reg_rw": "TP-002",
    "test_apb_err": "TP-003",
    "test_oneshot": "TP-004",
    "test_irq": "TP-005",
    "test_periodic": "TP-006",
    "test_cmp_boundary": "TP-007",
    "test_priority": "TP-008",
    "test_random": "TP-009",
    "test_clr": "TP-011",
}


def tool(name):
    path = shutil.which(name)
    if not path:
        sys.exit(f"ERROR: '{name}' not found in PATH (install Icarus Verilog >= 12)")
    return path


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--test", choices=list(TESTS), help="run a single test")
    ap.add_argument("--seeds", type=int, default=5, help="number of seeds for test_random (default 5)")
    a = ap.parse_args()

    data = yaml.safe_load((IP_DIR / "data" / "demo_timer.yaml").read_text(encoding="utf-8"))
    srcs = [str(IP_DIR / f) for f in data["rtl_files"]] + [str(DV_DIR / "tb" / "tb_demo_timer.sv")]
    (BUILD / "logs").mkdir(parents=True, exist_ok=True)
    vvp_file = BUILD / "tb.vvp"

    comp = subprocess.run([tool("iverilog"), "-g2012", "-o", str(vvp_file), "-s", "tb_demo_timer"] + srcs,
                          capture_output=True, text=True)
    errors = [l for l in comp.stderr.splitlines() if "sorry" not in l]
    if comp.returncode != 0:
        print(comp.stderr)
        sys.exit("ERROR: compile failed")
    for l in errors:
        print(f"compile: {l}")

    runs = [(t, 1) for t in TESTS if t != "test_random"]
    runs += [("test_random", s) for s in range(1, a.seeds + 1)]
    if a.test:
        runs = [r for r in runs if r[0] == a.test]

    results, cover = [], {}
    for test, seed in runs:
        p = subprocess.run([tool("vvp"), "-n", str(vvp_file), f"+TEST={test}", f"+SEED={seed}"],
                           capture_output=True, text=True)
        log = BUILD / "logs" / f"{test}_{seed}.log"
        log.write_text(p.stdout + p.stderr, encoding="utf-8")
        m = re.search(r"^TEST \S+ (?:SEED \d+ )?(PASSED|FAILED) errors=(\d+)", p.stdout, re.M)
        status = m.group(1) if m else "NO RESULT"
        nerr = int(m.group(2)) if m else -1
        first_err = next((l for l in p.stdout.splitlines() if "ERROR" in l), "")
        results.append((test, seed, status, nerr, first_err))
        for name, n in re.findall(r"^COVER (\w+)=(\d+)", p.stdout, re.M):
            cover[name] = cover.get(name, 0) + int(n)

    print("\n| 用例 | 测试点 | 种子 | 结果 | 错误数 |")
    print("|---|---|---|---|---|")
    for test, seed, status, nerr, _ in results:
        print(f"| {test} | {TESTS[test]} | {seed} | {status} | {nerr} |")
    print("\n| 覆盖点 | 命中次数 |")
    print("|---|---|")
    for name in sorted(cover):
        print(f"| {name} | {cover[name]} |")

    failed = [r for r in results if r[2] != "PASSED"]
    uncovered = [n for n, c in cover.items() if c == 0]
    print(f"\n{len(results) - len(failed)}/{len(results)} passed; "
          f"{len(cover) - len(uncovered)}/{len(cover)} cover points hit")
    for test, seed, _, _, err in failed:
        print(f"FAILED {test} seed={seed}: {err}  (log: dv/build/logs/{test}_{seed}.log)")
    if uncovered and not a.test:
        print("UNCOVERED: " + ", ".join(uncovered))
    sys.exit(1 if failed or (uncovered and not a.test) else 0)


if __name__ == "__main__":
    main()
