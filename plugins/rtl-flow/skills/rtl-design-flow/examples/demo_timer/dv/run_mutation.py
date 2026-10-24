#!/usr/bin/env python3
"""demo_timer testbench effectiveness check (mutation testing).

Usage:
    python dv/run_mutation.py

Each mutation injects one known bug into a copy of the RTL (dv/build/mut/), then
runs all tests. A mutation must make at least one test fail ("killed"); a
surviving mutation means the testbench has a checking hole. Exit code 1 if any survives.
"""
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

IP_DIR = Path(__file__).resolve().parent.parent
DV_DIR = IP_DIR / "dv"
WORK = DV_DIR / "build" / "mut"
sys.path.insert(0, str(DV_DIR))
from run_sim import TESTS, tool  # noqa: E402

# (编号, 描述, 文件, 原文, 替换)
MUTATIONS = [
    ("M1", "到时比较改为 ==（违反 DEC-001）", "demo_timer_core.v",
     "(count_r >= i_cmp)", "(count_r == i_cmp)"),
    ("M2", "硬件清 EN 优先于软件写（违反 DEC-002）", "demo_timer_reg.v",
     "        ctrl_en_r <= i_pwdata[0];",
     "        ctrl_en_r <= ((i_expire == 1'b1) && (ctrl_mode_r == MODE_ONESHOT)) ? 1'b0 : i_pwdata[0];"),
    ("M3", "软件清除优先于硬件置位（违反 DEC-003）", "demo_timer_reg.v",
     "    else if (i_expire == 1'b1) begin\n        intr_state_r <= 1'b1;",
     "    else if ((i_expire == 1'b1) && !((wr_en == 1'b1) && (hit_intr_state == 1'b1) && (i_pwdata[0] == 1'b1))) begin\n"
     "        intr_state_r <= 1'b1;"),
    ("M4", "非对齐地址命中 CMP（违反 REQ-IF-002）", "demo_timer_reg.v",
     "(i_paddr == ADDR_CMP)", "(i_paddr[11:2] == 10'h001)"),
    ("M5", "CMP 复位值错为 0（违反 REQ-REG-001）", "demo_timer_reg.v",
     "cmp_r <= 32'hFFFF_FFFF;", "cmp_r <= 32'h0;"),
    ("M6", "o_irq 未经使能屏蔽（违反 REQ-FUNC-005）", "demo_timer.v",
     "assign o_irq = intr_state & intr_enable;", "assign o_irq = intr_state;"),
    ("M7", "CTRL.CLR 不生效（违反 REQ-FUNC-006）", "demo_timer_core.v",
     "((i_clr == 1'b1) || (o_expire == 1'b1))", "(o_expire == 1'b1)"),
]


def main():
    data = yaml.safe_load((IP_DIR / "data" / "demo_timer.yaml").read_text(encoding="utf-8"))
    iverilog, vvp = tool("iverilog"), tool("vvp")
    print("| 编号 | 注入缺陷 | 结果 | 失败用例 |")
    print("|---|---|---|---|")
    survived = 0
    for mid, desc, fname, old, new in MUTATIONS:
        if WORK.exists():
            shutil.rmtree(WORK)
        shutil.copytree(IP_DIR / "rtl", WORK)
        target = WORK / fname
        text = target.read_text(encoding="utf-8")
        if text.count(old) != 1:
            sys.exit(f"ERROR: {mid}: pattern not found exactly once in {fname}; update MUTATIONS")
        target.write_text(text.replace(old, new), encoding="utf-8")

        srcs = [str(WORK / Path(f).name) for f in data["rtl_files"]] + [str(DV_DIR / "tb" / "demo_timer_tb.v")]
        vvp_file = WORK / "tb.vvp"
        subprocess.run([iverilog, "-g2001", "-o", str(vvp_file), "-s", "demo_timer_tb"] + srcs,
                       capture_output=True, text=True, check=True)
        failed = []
        for test in TESTS:
            out = subprocess.run([vvp, "-n", str(vvp_file), f"+TEST={test}", "+SEED=1"],
                                 capture_output=True, text=True).stdout
            if "PASSED" not in out:
                failed.append(test)
        status = "killed" if failed else "SURVIVED"
        survived += not failed
        print(f"| {mid} | {desc} | {status} | {', '.join(failed) or '—'} |")
    shutil.rmtree(WORK, ignore_errors=True)
    print(f"\n{len(MUTATIONS) - survived}/{len(MUTATIONS)} mutations killed")
    sys.exit(1 if survived else 0)


if __name__ == "__main__":
    main()
