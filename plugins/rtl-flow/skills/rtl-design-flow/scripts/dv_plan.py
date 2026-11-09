#!/usr/bin/env python3
"""Parse the test point / test case tables of doc/07_dv_plan.md (§3).

Shared by check_docs.py and run_regress.py. Documents in the older format (TP-xxx rows with
a 用例 column) yield an empty plan; callers handle that format themselves.
"""
import re
from dataclasses import dataclass, field

TP_RE = r"tp_[a-z0-9_]+"
TC_RE = r"tc_[a-z0-9_]+"


@dataclass
class TestCase:
    id: str
    tps: list = field(default_factory=list)
    activity: str = ""

    @property
    def simulated(self):
        return "仿真" in self.activity


@dataclass
class Plan:
    tps: dict = field(default_factory=dict)  # {tp id: 是否被覆盖 cell}
    cases: list = field(default_factory=list)
    duplicates: list = field(default_factory=list)
    trace_tps: set = field(default_factory=set)  # tp ids referenced by §6


def section(text, n):
    """Body of the '## <n>.' section, without fenced code blocks."""
    text = re.sub(r"```.*?```", "", text, flags=re.S)
    m = re.search(rf"^## {n}\.[^\n]*\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    return m.group(1) if m else ""


def _rows(body):
    for line in body.splitlines():
        s = line.strip()
        if s.startswith("|") and not re.fullmatch(r"\|[\s:\-|]+\|?", s):
            yield [c.strip().strip("`").strip() for c in s.strip("|").split("|")]


def parse(text):
    plan = Plan()
    tp_col = cov_col = case = None
    for cells in _rows(section(text, 3)):
        if "Feature编号" in cells[0]:
            tp_col = next((i for i, c in enumerate(cells) if c == "测试点编号"), None)
            cov_col = next((i for i, c in enumerate(cells) if "是否被测试用例覆盖" in c), None)
            continue
        if len(cells) == 2 and cells[0] == "测试用例编号":
            case = None
            if re.fullmatch(TC_RE, cells[1]):
                case = TestCase(cells[1])
                if any(c.id == case.id for c in plan.cases):
                    plan.duplicates.append(case.id)
                plan.cases.append(case)
        elif len(cells) == 2 and case and cells[0] == "所覆盖测试点编号":
            case.tps = re.findall(TP_RE, cells[1])
        elif len(cells) == 2 and case and cells[0] == "测试活动":
            case.activity = cells[1]
        elif tp_col is not None and len(cells) > tp_col and re.fullmatch(TP_RE, cells[tp_col]):
            tp = cells[tp_col]
            if tp in plan.tps:
                plan.duplicates.append(tp)
            plan.tps[tp] = cells[cov_col] if cov_col is not None and cov_col < len(cells) else ""
    for cells in _rows(section(text, 6)):
        for c in cells[1:]:
            plan.trace_tps.update(re.findall(TP_RE, c))
    return plan
