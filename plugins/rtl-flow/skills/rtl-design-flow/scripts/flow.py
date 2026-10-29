#!/usr/bin/env python3
"""rtl-flow multi-agent orchestration state machine.

The orchestrator (main Claude session) never decides the next step itself: it runs
`flow.py next <ip_dir>` and executes the single action printed as JSON, then runs `next` again.
All gate decisions (document checks, lint, testbench stub check, regression) are made here.

Usage:
    python flow.py init    <ip_dir> [--auto] [--input FILE_OR_TEXT ...]
    python flow.py next    <ip_dir>
    python flow.py answers <ip_dir> (--file F | --none)          answers to the Q of 00_requirements
    python flow.py review  <ip_dir> --pass --reviewer NAME        user approved the gate(s) under review
    python flow.py review  <ip_dir> --changes F                   user asked for changes (comments in F)
    python flow.py iter    <ip_dir> --kind failure|change (--file F | --text T)
    python flow.py resume  <ip_dir> [--note F]                    continue after an escalation
    python flow.py status  <ip_dir>
    python flow.py guard   <ip_dir> on|off                        hook path guard (off only on user request)

Actions printed by `next` (field "action"):
    dispatch   start every agent in "agents" (in parallel when more than one), wait for all, run next
    ask_user   ask the questions in "questions" (AskUserQuestion), write answers, run `answers`
    review     human review gate: present "docs"/"highlights", ask pass / changes, run `review`
    escalate   report "reason"/"detail" to the user, then `resume` or `iter` as the user decides
    finish     report "summary" to the user; the flow is complete
"""
import argparse
import json
import re
import shutil
import sys
from datetime import date, datetime
from pathlib import Path

import yaml

SCRIPTS = Path(__file__).resolve().parent
SKILL = SCRIPTS.parent
sys.path.insert(0, str(SCRIPTS))
import check_docs  # noqa: E402
import gen_docs  # noqa: E402
import run_regress  # noqa: E402

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except AttributeError:
    pass

STATE = Path(".flow") / "state.json"
AGENT_NS = "rtl-flow:"
ROLES = ["spec-author", "architect", "rtl-engineer", "tb-engineer", "debugger"]
MAX_ATTEMPTS = 3      # re-dispatches of one role in one stage before escalating
MAX_ROUNDS = 3        # debug/fix rounds per iteration before escalating

# gate -> (reviewed doc, author role, check stage used to verify review fixes)
GATES = {"G0": ("00_requirements", "spec-author", "req"),
         "G1": ("01_spec", "spec-author", "spec"),
         "G2": ("02_architecture", "architect", "arch")}
GATE_SCOPE = {"G0": "00 需求（含 Q 的答复、ASM）",
              "G1": "01 规格、03/04（即 yaml 端口与寄存器）、06 编程指南初稿、新增 ASM",
              "G2": "02 微架构、本阶段新增的 DEC（09）"}
REVIEW_ERR = ("not approved", "re-review required", "review skipped", "approved is set")
# implementation stage -> task kind each role gets when it has to fix check problems
IMPL_KIND = {"BUILD": {"rtl-engineer": "rtl", "tb-engineer": "tb"},
             "FIX": {"rtl-engineer": "fix", "tb-engineer": "fix"},
             "CHANGE_IMPL": {"rtl-engineer": "change", "tb-engineer": "change"}}


# --------------------------------------------------------------------------- state
def today():
    return date.today().isoformat()


def load(ip: Path):
    p = ip / STATE
    if not p.exists():
        raise SystemExit(f"ERROR: {p} not found; run `flow.py init {ip}` first")
    return json.loads(p.read_text(encoding="utf-8"))


def save(ip: Path, st):
    (ip / STATE).write_text(json.dumps(st, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def log(st, event):
    st["history"].append(f"{datetime.now().isoformat(timespec='seconds')} {event}")


def goto(st, stage):
    log(st, f"stage {st['stage']} -> {stage}")
    st["stage"], st["attempts"] = stage, {}


def emit(obj):
    print(json.dumps(obj, ensure_ascii=False, indent=2))


def rel(ip: Path, p: Path):
    return p.relative_to(ip).as_posix()


# --------------------------------------------------------------------------- front matter
def front_matter(ip: Path, doc):
    p = ip / "doc" / f"{doc}.md"
    if not p.exists():
        return {}
    fm, _ = check_docs.split_front_matter(p.read_text(encoding="utf-8", errors="replace"))
    return fm or {}


def set_front_matter(ip: Path, doc, **fields):
    p = ip / "doc" / f"{doc}.md"
    text = p.read_text(encoding="utf-8")
    m = re.match(r"---\r?\n(.*?)\r?\n---\r?\n", text, re.S)
    if not m:
        raise SystemExit(f"ERROR: {p} has no front matter")
    lines = m.group(1).splitlines()
    for k, v in fields.items():
        idx = next((i for i, l in enumerate(lines) if re.match(rf"{k}\s*:", l)), None)
        if idx is None:
            lines.append(f"{k}: {v}")
        else:
            lines[idx] = f"{k}: {v}"
    p.write_text("---\n" + "\n".join(lines) + "\n---\n" + text[m.end():], encoding="utf-8", newline="\n")


def gate_valid(ip: Path, st, gate):
    fm = front_matter(ip, GATES[gate][0])
    appr = fm.get("approved", "")
    if st["mode"] == "auto" and appr == "skipped":
        return True
    m = check_docs.APPROVED_RE.fullmatch(appr)
    return bool(m and m.group(1) == fm.get("version") and fm.get("reviewer"))


def stale_gates(ip: Path, st):
    """Gates passed before whose document changed (or lost approval) since."""
    return [g for g in GATES if g in st["passed"] and not gate_valid(ip, st, g)]


# --------------------------------------------------------------------------- checks
def doc_errors(ip: Path, stage):
    """ERRORs of check_docs at `stage`, without review-gate errors (gates are handled by the flow)."""
    return [f"{w}: {m}" for w, m in check_docs.run_checks(ip, stage).errors()
            if not any(k in m for k in REVIEW_ERR)]


def open_questions(ip: Path):
    p = ip / "doc" / "00_requirements.md"
    if not p.exists():
        return []
    qs = []
    for cells in check_docs.table_rows(check_docs.split_front_matter(p.read_text(encoding="utf-8"))[1]):
        if re.fullmatch(r"Q-\d{3}", cells[0]) and any(c.lower() == "open" for c in cells[1:]):
            qs.append({"id": cells[0], "question": cells[1], "impact": cells[2] if len(cells) > 2 else ""})
    return qs


def regress_current(ip: Path):
    """Current rtl-mode regression result, or None if missing/stale."""
    p = ip / run_regress.REPORT
    if not p.exists():
        return None
    res = json.loads(p.read_text(encoding="utf-8"))
    data, derrs, _ = gen_docs.outputs(ip)
    if derrs or res.get("mode") != "rtl":
        return None
    cur = run_regress.digests(ip, data)
    return res if all(res.get(k) == v for k, v in cur.items()) else None


def record_itr(ip: Path, itr, text):
    """Write the regression result into the ITR summary row and detail block of 08 (best effort)."""
    p = ip / "doc" / "08_iteration_log.md"
    if not itr or not p.exists():
        return
    s = p.read_text(encoding="utf-8")
    s = re.sub(rf"^(\|\s*{itr}\s*\|.*\|)[^|\n]*\|\s*$",
               lambda m: f"{m.group(1)} {text} |", s, count=1, flags=re.M)
    block = re.search(rf"^###\s+{itr}\b.*?(?=^###\s|^##\s|\Z)", s, re.S | re.M)
    if block:
        b = re.sub(r"^(- \*\*回归结果\*\*[:：]).*$", lambda m: f"{m.group(1)}{text}", block.group(0), flags=re.M)
        s = s[:block.start()] + b + s[block.end():]
    p.write_text(s, encoding="utf-8", newline="\n")


# --------------------------------------------------------------------------- tasks
HANDOFF_KEYS = ["task", "agent", "status", "summary"]

TASKS = {
    ("spec-author", "requirements"):
        "执行 P0 需求规范化。模板已复制到 IP 目录，原始材料已保存在 raw/（只读）。\n"
        "1. 在 00_requirements 的「输入来源」表登记 raw/ 中每个文件；逐条抽取 REQ（单一、可验证、带量化指标、有来源）。\n"
        "2. 能合理推断的写 ASM；关键且无法推断的写 Q（状态 Open）。不要自己向用户提问，编排者会统一提问。\n"
        "3. 填写 README.md 的概述与特性。\n"
        "4. 运行 check_docs.py --stage req，直到没有 ERROR（not approved 类除外）。",
    ("spec-author", "answers"):
        "用户已答复 00_requirements 中的 Q，答复见附加输入。\n"
        "1. 每条已答复的 Q：状态改为 Closed，结论列写答复，并据此新增或修改 REQ / ASM。\n"
        "2. 用户未答复的 Q：改写为 ASM（理由写「用户未答复，按推断」），或保留 Open 并在结论列说明原因。\n"
        "3. 运行 check_docs.py --stage req，直到没有 ERROR。",
    ("spec-author", "spec"):
        "执行 P1 规格与数据。\n"
        "1. 编写 data/<ip>.yaml（参数、时钟复位、端口、中断、寄存器），运行 gen_docs.py。\n"
        "2. 编写 01_spec：每个功能小节以 `> 覆盖需求: REQ-xxx` 开头，所有 REQ 都要被引用。\n"
        "3. 编写 06_programmers_guide 初稿。新增的 ASM 写回 00_requirements。\n"
        "4. 运行 check_docs.py --stage spec，直到没有 ERROR（not approved 类除外）。",
    ("spec-author", "review_fix"):
        "用户在人工审核中要求修改，意见见附加输入。按意见修改相关文档（修改要落到 REQ / ASM / DEC，不只改正文）。"
        "不要修改 front matter 的 reviewer / approved。修改 yaml 后重新运行 gen_docs.py。"
        "完成后运行附加说明中给出的 check_docs 阶段，直到没有 ERROR。",
    ("spec-author", "change"):
        "处理一次需求变更，变更内容见附加输入。\n"
        "1. 按 00 → 01 → data/<ip>.yaml → 06 的顺序修改；已审核文档内容实质变化时提升其 version（编排者会据此重开审核）。\n"
        "2. 在 08_iteration_log 新增一条 ITR（触发：需求变更；根因类别：需求变化），写清楚变更与影响文档；有取舍时在 09 记 DEC；对外可见变化写入 CHANGELOG.md。\n"
        "3. 运行 gen_docs.py 和 check_docs.py --stage spec。\n"
        "4. 交接文件中写 itr（新 ITR 编号）和 affects（arch / rtl / tb 中需要跟着修改的部分）。",
    ("architect", "arch"):
        "执行 P2 微架构。\n"
        "1. 编写 02_architecture：框图（Mermaid）、§2 子模块表（第一列 `模块名`，职责、关键接口必填）、数据通路、FSM（状态图 + 状态表）、时钟复位、CDC、关键时序（WaveDrom）、PPA 估计。\n"
        "2. 重要取舍记入 09_decisions（DEC-xxx）。\n"
        "3. 运行 check_docs.py --stage arch，直到没有 ERROR（not approved 类除外）。",
    ("architect", "review_fix"):
        "用户在人工审核中要求修改，意见见附加输入。按意见修改 02 / 09，不要修改 reviewer / approved。"
        "完成后运行 check_docs.py --stage arch，直到没有 ERROR。",
    ("architect", "change"):
        "需求变更已更新 00 / 01 / yaml（见附加输入与 ITR）。同步修改 02_architecture 与 09_decisions；"
        "02 实质变化时提升 version。在该 ITR 的「修改」表中补充你的修改。运行 check_docs.py --stage arch。",
    ("rtl-engineer", "rtl"):
        "执行 P3 RTL 实现。\n"
        "1. 按 02 子模块表和 references/rtl-coding-style.md 编写 rtl/ 下全部模块；顶层端口（含顺序）与 yaml 一致；"
        "把全部 RTL 文件写进 yaml 的 rtl_files（define.v 第一、顶层第二；yaml 中只能改这个字段）。\n"
        "2. 编写 05_rtl_structure（文件清单、层次、模块职责、参数、偏离说明）。\n"
        "3. 运行 run_lint.py，修复全部 error；warning 修复或在 05 §7 写豁免原因。\n"
        "4. 在 08_iteration_log 新增 ITR（触发：初始实现），回归结果留空（由编排者填写）；交接文件写 itr。\n"
        "5. 不要编写或修改 dv/（验证由 tb-engineer 独立完成）。",
    ("rtl-engineer", "fix"):
        "回归失败，debugger 的定位报告见附加输入。修复 RTL：\n"
        "1. 只改报告指出的问题；影响微架构时同步 02 / 05（02 实质变化须提升 version）。\n"
        "2. 在报告中的 ITR 下补写「修改」表和「影响文档」。\n"
        "3. 重新运行 run_lint.py。不要修改 dv/。",
    ("rtl-engineer", "change"):
        "需求变更已更新 00 / 01 / 02 / yaml（见附加输入与 ITR）。按更新后的文档修改 RTL 与 05，"
        "重新运行 run_lint.py，并在该 ITR 的「修改」表中补充你的修改。不要修改 dv/。",
    ("tb-engineer", "tb"):
        "执行 P4 验证。你看不到、也不能读取 RTL：只根据 00 / 01 / 03 / 04 / 06 与 yaml 构建验证。\n"
        "1. 编写 07_dv_plan：测试点 TP-xxx 关联 REQ，§3 表「用例」列写反引号用例名（如 `test_reset`）；每条 REQ 都要被 TP 覆盖。\n"
        "2. 编写 dv/tb/<ip>_tb.v：黑盒自检查 testbench（只通过顶层端口访问 DUT，禁止 U_dut.xxx 层次引用），"
        "参考模型逐周期比对，COVER 计数，看门狗；输出格式见 rtl-coding-style §10。\n"
        "3. 运行 run_regress.py <ip_dir> --stub，直到结果为 PASS（证明 TB 能编译、识别全部用例并能结束；桩模块输出恒 0，用例本身失败属正常）。",
    ("tb-engineer", "fix"):
        "回归失败，debugger 判定测试平台有问题，说明见附加输入（只描述与规格不符之处）。\n"
        "1. 以规格为准修正 testbench / 参考模型 / 07_dv_plan；不要为了让用例通过而放宽检查。\n"
        "2. 在说明中的 ITR 下补写「修改」表（标注 TB bug）。\n"
        "3. 运行 run_regress.py <ip_dir> --stub 直到 PASS。\n"
        "如果你认为规格本身有歧义、说明与规格矛盾，status 写 blocked 并在 blocked_reason 中说明。",
    ("tb-engineer", "change"):
        "需求变更已更新 00 / 01 / yaml（见附加输入与 ITR）。按更新后的规格修改 07_dv_plan 与 testbench，"
        "在该 ITR 的「修改」表中补充你的修改，运行 run_regress.py <ip_dir> --stub 直到 PASS。",
    ("debugger", "diagnose"):
        "回归失败，结果见 reports/regress.json（日志在 dv/build/regress/logs/）。定位根因并分类：\n"
        "- rtl：RTL 行为与规格不符；tb：testbench / 参考模型期望与规格不符；both：两者都有；\n"
        "- spec：规格没有写清或自相矛盾，需要用户决定；tool：仿真工具或环境问题。\n"
        "以规格（00 / 01 / 04 / 06 / yaml）为准判定谁错。可以读取全部文件、运行仿真；"
        "需要临时测试时放在 dv/build/debug/，不要修改 rtl/ 与 dv/tb/。\n"
        "1. 在 08_iteration_log 新增 ITR：触发、现象、根因（含类别）；「修改」和「回归结果」留给修复者和编排者。\n"
        "2. 写完整报告 .flow/debug/<任务ID>.md：失败用例、第一个不匹配的时刻与信号、根因、建议修改（文件 / 位置）。\n"
        "3. 涉及 TB（tb / both）时另写 .flow/debug/<任务ID>_tb.md：只用规格语言说明 TB 哪个期望与规格哪一条不符，"
        "不得出现 RTL 代码、内部信号名、RTL 文件名或行号。\n"
        "4. 交接文件写 class、itr、report、tb_brief（如有）；class 为 spec 时在 question 中写出需要用户决定的问题。",
}

HANDOFF_EXTRA = {
    ("rtl-engineer", "rtl"): "itr: ITR-xxx",
    ("spec-author", "change"): "itr: ITR-xxx\naffects: [arch, rtl, tb]   # 需要跟着修改的部分",
    ("debugger", "diagnose"): "class: rtl            # rtl | tb | both | spec | tool\nitr: ITR-xxx\n"
                              "report: .flow/debug/<任务ID>.md\ntb_brief: .flow/debug/<任务ID>_tb.md   # 仅 tb / both\n"
                              "question: \"\"          # 仅 spec",
}


def new_task(ip: Path, st, role, kind, inputs=(), extra=""):
    st["seq"] += 1
    tid = f"{st['seq']:03d}-{role}-{kind}"
    handoff = ip / ".flow" / "handoff" / f"{tid}.yaml"
    note = st.pop("note", None)
    lines = [f"你是 rtl-flow 的 {role}。任务 ID：{tid}",
             f"IP 目录：{ip}",
             f"Skill 目录（$SKILL）：{SKILL}",
             f"模式：{'自动（不停顿审核）' if st['mode'] == 'auto' else '人工审核'}",
             "", "## 任务", TASKS[(role, kind)].replace("<任务ID>", tid).replace("<ip_dir>", str(ip))]
    if extra:
        lines += ["", "## 附加说明", extra]
    if inputs:
        lines += ["", "## 附加输入（先阅读）"] + [f"- {p}" for p in inputs]
    if note:
        lines += ["", "## 用户补充说明", f"- {note}"]
    skel = (f"task: {tid}\nagent: {role}\nstatus: done        # done | blocked | failed\n"
            "summary:            # 3–8 条要点，供编排者汇报给用户\n  - ...\n"
            "outputs: []         # 新建或修改的文件\nnew_ids: []         # 新增的 REQ / ASM / Q / DEC / TP / ITR / BUG\n"
            "blocked_reason: \"\"")
    if (role, kind) in HANDOFF_EXTRA:
        skel += "\n" + HANDOFF_EXTRA[(role, kind)]
    lines += ["", "## 完成后",
              f"把交接文件写到 {handoff}（YAML）：", "```yaml", skel, "```",
              f"回复的最后一行必须是：HANDOFF: {handoff}"]
    task = {"id": tid, "role": role, "kind": kind, "inputs": list(inputs), "extra": extra}
    st["pending"].append(task)
    log(st, f"dispatch {tid}")
    return {"subagent_type": AGENT_NS + role, "description": f"{role} {kind}", "task_id": tid,
            "prompt": "\n".join(lines)}


def dispatch(agents):
    return {"action": "dispatch", "agents": agents,
            "instructions": "用 Agent 工具启动 agents 中的每一项（subagent_type、description、prompt 原样传入；"
                            "多于一项时在同一条消息中并行启动）。等全部完成后再运行 flow.py next。"
                            "不要自己做这些任务，也不要修改 prompt 的要求。"}


def escalate(st, reason, detail, resume_stage=None, tasks=None, options=None):
    """Stop and hand the decision to the user; nothing stays running."""
    st["pending"] = []
    st["escalation"] = {"reason": reason, "detail": detail, "resume_stage": resume_stage or st["stage"],
                        "tasks": tasks or [], "options": options or []}
    log(st, f"escalate: {reason}")
    return escalation_action(st)


def escalation_action(st):
    e = st["escalation"]
    return {"action": "escalate", "reason": e["reason"], "detail": e["detail"], "options": e["options"],
            "instructions": "把 reason / detail 简要汇报给用户，用 AskUserQuestion 请用户决定。"
                            "继续当前步骤：把用户的说明写到文件后运行 flow.py resume <ip_dir> --note <文件>；"
                            "按需求变更处理：运行 flow.py iter <ip_dir> --kind change --file <文件>。"}


def read_handoff(ip: Path, task):
    p = ip / ".flow" / "handoff" / f"{task['id']}.yaml"
    if not p.exists():
        return None
    try:
        h = yaml.safe_load(p.read_text(encoding="utf-8"))
    except yaml.YAMLError:
        return None
    return h if isinstance(h, dict) and all(k in h for k in HANDOFF_KEYS) else None


def task_ref(t):
    return {k: t[k] for k in ("role", "kind", "inputs")}


def retry(ip: Path, st, task, problems):
    """Re-dispatch a task with the problems to fix; None once MAX_ATTEMPTS is used up."""
    key = f"{st['stage']}:{task['role']}"
    if st["attempts"].get(key, 0) >= MAX_ATTEMPTS:
        return None
    st["attempts"][key] = st["attempts"].get(key, 0) + 1
    errs = "\n".join(f"- {p}" for p in problems[:40])
    extra = (task.get("extra", "") + "\n\n" if task.get("extra") else "") + \
        f"上一次产出未通过编排者的检查（第 {st['attempts'][key]} 次重试），先修复以下问题：\n{errs}"
    return new_task(ip, st, task["role"], task["kind"], task["inputs"], extra)


# --------------------------------------------------------------------------- stage logic
def verify_docs(ip: Path, st, tasks, check_stage):
    """Verification for single-author document stages: returns (agents_to_redispatch, escalation)."""
    errs = doc_errors(ip, check_stage)
    if not errs:
        return [], None
    agents = [retry(ip, st, t, errs) for t in tasks]
    if None in agents:
        return [], escalate(st, f"{tasks[0]['role']} 连续 {MAX_ATTEMPTS} 次未通过 check_docs --stage {check_stage}",
                            "\n".join(errs[:20]), tasks=[task_ref(t) for t in tasks])
    return agents, None


def impl_problems(ip: Path):
    """{role: [problems]} for the implementation stages (RTL docs/lint + TB plan/stub check).

    Raises SystemExit when the simulator is missing (an environment problem, not an agent's)."""
    out = {"rtl-engineer": [], "tb-engineer": []}
    for e in doc_errors(ip, "dv"):
        out["tb-engineer" if "07_dv_plan" in e else "rtl-engineer"].append(e)
    stub = run_regress.run(ip, stub=True)
    out["tb-engineer"] += [f"stub check: {p}" for p in stub["problems"]]
    out["tb-engineer"] += [f"compile: {m}" for m in stub["compile"]["messages"] if "error" in m.lower()][:20]
    out["tb-engineer"] += [f"stub check: {t['test']} 没有输出 TEST 结果行（用例名未识别、没有看门狗或提前退出）"
                           for t in stub["tests"] if t["status"] == "NO RESULT"]
    return out


def enter_review(ip: Path, st, gates, return_to):
    gates = sorted(set(gates) | set(stale_gates(ip, st)), key=list(GATES).index)
    st["review"] = {"gates": gates, "return_to": return_to, "changes_file": None}
    goto(st, "REVIEW")


def collect(ip: Path, st):
    """Process finished tasks; returns an action, or None when the state advanced."""
    tasks, st["pending"] = st["pending"], []
    done, again, stuck = [], [], []
    for t in tasks:
        h = read_handoff(ip, t)
        if h is None:
            a = retry(ip, st, t, [f"没有找到有效的交接文件 .flow/handoff/{t['id']}.yaml（必须包含 {', '.join(HANDOFF_KEYS)}）"])
            if a is None:
                return escalate(st, f"{t['role']} 多次没有写交接文件", t["id"], tasks=[task_ref(t)])
            again.append(a)
            continue
        if h.get("status") != "done":
            stuck.append((t, h))
            continue
        st["last_handoff"][t["role"]] = {"task": t["id"], "summary": h.get("summary"), "new_ids": h.get("new_ids")}
        if h.get("itr"):
            st["itr"], st["itr_open"] = h["itr"], True   # waits for the next regression result
        done.append((t, h))
    if stuck:   # only the blocked/failed tasks are re-run on resume; finished ones are kept
        return escalate(st, "; ".join(f"{t['role']} 报告 {h.get('status')}: {h.get('blocked_reason', '')}"
                                      for t, h in stuck),
                        "\n".join(yaml.safe_dump(h, allow_unicode=True, sort_keys=False) for _, h in stuck),
                        tasks=[task_ref(t) for t, _ in stuck])
    if again:
        return dispatch(again)

    stage = st["stage"]
    ts = [t for t, _ in done]
    if stage == "P0":
        agents, esc = verify_docs(ip, st, ts, "req")
        if esc or agents:
            return esc or dispatch(agents)
        if open_questions(ip) and not st["asked"]:
            goto(st, "ASK")
        else:
            enter_review(ip, st, ["G0"], "P1")
    elif stage == "ASK":
        agents, esc = verify_docs(ip, st, ts, "req")
        if esc or agents:
            return esc or dispatch(agents)
        enter_review(ip, st, ["G0"], "P1")
    elif stage == "REVIEW":
        stages = {GATES[g][2] for g in st["review"]["gates"]}
        agents, esc = verify_docs(ip, st, ts, max(stages, key=check_docs.STAGES.index))
        if esc or agents:
            return esc or dispatch(agents)
        st["review"]["changes_file"] = None
    elif stage == "P1":
        agents, esc = verify_docs(ip, st, ts, "spec")
        if esc or agents:
            return esc or dispatch(agents)
        enter_review(ip, st, ["G1"], "P2")
    elif stage == "P2":
        agents, esc = verify_docs(ip, st, ts, "arch")
        if esc or agents:
            return esc or dispatch(agents)
        enter_review(ip, st, ["G2"], "BUILD")
    elif stage in IMPL_KIND:
        try:
            probs = impl_problems(ip)
        except SystemExit as e:
            return escalate(st, "testbench 桩检查无法运行（仿真工具或数据文件问题）", str(e))
        by_role = {t["role"]: t for t in ts}
        agents = []
        for role, ps in probs.items():
            if not ps:
                continue
            t = by_role.get(role) or {"role": role, "kind": IMPL_KIND[stage][role], "inputs": [], "extra": ""}
            a = retry(ip, st, t, ps)
            if a is None:
                return escalate(st, f"{role} 连续 {MAX_ATTEMPTS} 次未通过实现阶段检查", "\n".join(ps[:20]),
                                tasks=[task_ref(t)])
            agents.append(a)
        if agents:
            return dispatch(agents)
        goto(st, "REGRESS")
    elif stage == "DEBUG":
        t, h = done[0]
        cls = str(h.get("class", "")).strip()
        if cls not in ("rtl", "tb", "both", "spec", "tool"):
            a = retry(ip, st, t, [f"交接文件 class 必须是 rtl / tb / both / spec / tool，实际为 '{cls}'"])
            return dispatch([a]) if a else escalate(st, "debugger 未给出有效的根因分类", str(h))
        if cls in ("spec", "tool"):
            return escalate(st, f"debugger 判定根因为 {cls}" + ("（规格不明确，需要用户决定）" if cls == "spec" else "（工具/环境问题）"),
                            f"{h.get('question') or ''}\n报告：{h.get('report', '')}\n" + "\n".join(map(str, h.get("summary") or [])),
                            resume_stage="REGRESS" if cls == "tool" else "DEBUG",
                            options=["按需求变更处理：flow.py iter --kind change", "补充说明后继续：flow.py resume --note"])
        st["fix"] = {"class": cls, "report": h.get("report", ""), "tb_brief": h.get("tb_brief", ""), "itr": h.get("itr")}
        goto(st, "FIX")
    elif stage == "CHANGE_SPEC":
        agents, esc = verify_docs(ip, st, ts, "spec")
        if esc or agents:
            return esc or dispatch(agents)
        aff = done[0][1].get("affects") or ["arch", "rtl", "tb"]
        st["iteration"]["affects"] = [str(x) for x in aff]
        goto(st, "CHANGE_ARCH" if "arch" in st["iteration"]["affects"] else "CHANGE_IMPL")
    elif stage == "CHANGE_ARCH":
        agents, esc = verify_docs(ip, st, ts, "arch")
        if esc or agents:
            return esc or dispatch(agents)
        goto(st, "CHANGE_IMPL")
    return None


def step(ip: Path, st):
    """One decision; returns an action or None (state advanced, decide again)."""
    if st.get("escalation"):
        return escalation_action(st)
    if st["pending"]:
        return collect(ip, st)
    stage = st["stage"]
    if stage not in ("REVIEW", "ASK", "DONE", "P0", "CHANGE_SPEC") and stale_gates(ip, st):
        enter_review(ip, st, [], stage)
        return None

    if stage == "P0":
        return dispatch([new_task(ip, st, "spec-author", "requirements", st["inputs"])])
    if stage == "ASK":
        if st.get("answers_file") is not None:
            f = st.pop("answers_file")
            st["asked"] = True
            if not f:      # user gave no answers
                enter_review(ip, st, ["G0"], "P1")
                return None
            return dispatch([new_task(ip, st, "spec-author", "answers", [f])])
        return {"action": "ask_user", "questions": open_questions(ip),
                "answers_file": str(ip / ".flow" / "answers" / f"answers-{st['seq'] + 1:03d}.md"),
                "instructions": "用 AskUserQuestion 把这些 Q 合并提问（每次最多 4 个，可分多次；选项给出你推荐的答案，用户可在 Other 中自由回答）。"
                                "把每个 Q 的答复按「Q-xxx: 答复」写入 answers_file，然后运行 flow.py answers <ip_dir> --file <answers_file>；"
                                "用户不愿回答时运行 flow.py answers <ip_dir> --none。"}
    if stage == "REVIEW":
        rv = st["review"]
        if rv.get("changes_file"):
            authors = {}
            for g in rv["gates"]:
                authors.setdefault(GATES[g][1], []).append(g)
            stage_hint = max((GATES[g][2] for g in rv["gates"]), key=check_docs.STAGES.index)
            return dispatch([new_task(ip, st, role, "review_fix", [rv["changes_file"]],
                                      f"被审文档：{', '.join(GATES[g][0] for g in gs)}；完成后运行 check_docs.py --stage {stage_hint}")
                             for role, gs in authors.items()])
        todo = [g for g in rv["gates"] if not gate_valid(ip, st, g)]
        if st["mode"] == "auto":
            for g in todo:
                set_front_matter(ip, GATES[g][0], reviewer="", approved="skipped")
            todo = []
        if not todo:
            st["passed"] = sorted(set(st["passed"]) | set(rv["gates"]))
            goto(st, rv["return_to"])
            st.pop("review")
            return None
        docs = []
        for g in todo:
            doc = GATES[g][0]
            if front_matter(ip, doc).get("status") == "Draft":
                set_front_matter(ip, doc, status="Review")
            fm = front_matter(ip, doc)
            docs.append({"gate": g, "doc": f"doc/{doc}.md", "version": fm.get("version"), "scope": GATE_SCOPE[g]})
        highlights = {r: v for r, v in st["last_handoff"].items() if r in {GATES[g][1] for g in todo}}
        return {"action": "review", "gates": todo, "docs": docs, "highlights": highlights,
                "reviewer_known": st.get("reviewer") or None,
                "comments_file": str(ip / ".flow" / "reviews" / f"review-{st['seq'] + 1:03d}.md"),
                "instructions": "向用户汇报：被审文档路径、要点（highlights 中的 summary，3–8 条）、新增的 ASM / DEC、需要用户特别判断的地方。"
                                "然后用 AskUserQuestion 请用户选择「通过」或「需要修改」（意见可在 Other 中填写）；"
                                "reviewer_known 为空时同时询问审核人姓名。"
                                "通过：flow.py review <ip_dir> --pass --reviewer <姓名>；"
                                "需要修改：把意见写入 comments_file，运行 flow.py review <ip_dir> --changes <comments_file>。"
                                "只有用户明确表示通过时才能使用 --pass。"}
    if stage == "P1":
        return dispatch([new_task(ip, st, "spec-author", "spec")])
    if stage == "P2":
        return dispatch([new_task(ip, st, "architect", "arch")])
    if stage == "BUILD":
        return dispatch([new_task(ip, st, "rtl-engineer", "rtl"), new_task(ip, st, "tb-engineer", "tb")])
    if stage == "REGRESS":
        res = regress_current(ip)
        if res is None:
            try:
                res = run_regress.run(ip)
            except SystemExit as e:
                return escalate(st, "回归无法运行", str(e), resume_stage="REGRESS")
        st["last_regress"] = res["summary"]
        failed = [t for t in res["tests"] if t["status"] != "PASSED"]
        if st.pop("itr_open", False):
            record_itr(ip, st.get("itr"), res["summary"] +
                       (f"；失败：{', '.join(sorted({t['test'] for t in failed}))}" if failed else ""))
        log(st, f"regress {res['result']}: {res['summary']}")
        it = st.get("iteration") or {}
        if res["result"] == "PASS" and it.get("kind") == "failure" and not it.get("debugged"):
            goto(st, "DEBUG")      # user-reported problem the regression does not catch
            return None
        if res["result"] == "PASS":
            st["iteration"] = None
            goto(st, "DONE")
            return None
        st["round"] += 1
        if st["round"] > MAX_ROUNDS:
            st["round"] = 0
            return escalate(st, f"修复 {MAX_ROUNDS} 轮后回归仍失败", res["summary"] + "\n" +
                            "\n".join(f"{t['test']} seed={t['seed']}: {(t['first_errors'] or [''])[0]}" for t in failed[:10]),
                            resume_stage="DEBUG")
        goto(st, "DEBUG")
        return None
    if stage == "DEBUG":
        inputs = [rel(ip, ip / run_regress.REPORT)]
        it = st.get("iteration") or {}
        if it.get("file"):
            inputs.append(it["file"])
            it["debugged"] = True
        res = regress_current(ip)
        extra = f"这是本次迭代的第 {st['round'] or 1} 轮调试。" + (f"上一条 ITR 是 {st['itr']}。" if st.get("itr") else "")
        if res and res["result"] == "PASS":
            extra += ("\n当前回归全部通过：用户报告的问题没有被现有用例发现。先复现问题（在 dv/build/debug/ 下），"
                      "再判断是 RTL 错误（rtl，同时 TB 有盲区时为 both）、TB 期望错误（tb）还是规格问题（spec）。"
                      "TB 有盲区时在 tb_brief 中说明需要新增的检查。")
        return dispatch([new_task(ip, st, "debugger", "diagnose", inputs, extra)])
    if stage == "FIX":
        fx = st["fix"]
        agents = []
        if fx["class"] in ("rtl", "both"):
            agents.append(new_task(ip, st, "rtl-engineer", "fix", [fx["report"]], f"ITR：{fx['itr']}"))
        if fx["class"] in ("tb", "both"):
            agents.append(new_task(ip, st, "tb-engineer", "fix", [fx["tb_brief"]], f"ITR：{fx['itr']}"))
        return dispatch(agents)
    if stage == "CHANGE_SPEC":
        return dispatch([new_task(ip, st, "spec-author", "change", [st["iteration"]["file"]])])
    if stage == "CHANGE_ARCH":
        return dispatch([new_task(ip, st, "architect", "change", [st["iteration"]["file"]], f"ITR：{st.get('itr')}")])
    if stage == "CHANGE_IMPL":
        aff = (st.get("iteration") or {}).get("affects") or ["rtl", "tb"]
        roles = [r for r, k in (("rtl-engineer", "rtl"), ("tb-engineer", "tb")) if k in aff] or ["rtl-engineer", "tb-engineer"]
        return dispatch([new_task(ip, st, r, "change", [st["iteration"]["file"]], f"ITR：{st.get('itr')}") for r in roles])
    if stage == "DONE":
        return {"action": "finish", "summary": {
            "regression": st.get("last_regress"), "itr": st.get("itr"),
            "gates": {g: front_matter(ip, GATES[g][0]).get("approved") for g in GATES},
            "remaining_warnings": [f"{w}: {m}" for lvl, w, m in check_docs.run_checks(ip, "dv").items if lvl == "WARN"][:20]},
            "instructions": "向用户汇报：回归结果、各审核点状态、遗留 WARN。说明签核（P6）需要用户确认："
                            "按 doc/10_checklist.md 勾选并把文档改为 Released 后运行 check_docs.py --stage signoff；"
                            "后续验证失败或需求变更用 /rtl-flow:ip-iter。"}
    raise SystemExit(f"ERROR: unknown stage '{stage}'")


# --------------------------------------------------------------------------- commands
def cmd_init(a):
    ip = a.ip_dir.resolve()
    name = ip.name
    if not re.fullmatch(r"[a-z][a-z0-9_]*", name):
        raise SystemExit(f"ERROR: IP name '{name}' must be lower_snake_case")
    if (ip / STATE).exists():
        raise SystemExit(f"ERROR: {ip / STATE} already exists; use `flow.py next`")
    tpl = SKILL / "templates"
    for src in tpl.rglob("*"):
        if src.is_dir():
            continue
        r = src.relative_to(tpl).as_posix()
        dst = ip / (f"data/{name}.yaml" if r == "data/ip.yaml" else r)
        if dst.exists():
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        text = src.read_text(encoding="utf-8").replace("{{ip}}", name).replace("{{date}}", today())
        dst.write_text(text, encoding="utf-8", newline="\n")
    raw, inputs, texts = ip / "raw", [], []
    raw.mkdir(exist_ok=True)
    for x in a.input or []:
        p = Path(x)
        if p.exists():
            dst = raw / p.name
            if p.is_dir():
                shutil.copytree(p, dst, dirs_exist_ok=True)
            elif not dst.exists():
                shutil.copy2(p, dst)
            inputs.append(f"raw/{p.name}")
        else:
            texts.append(x)
    if texts:
        f = raw / "user_description.md"
        f.write_text(f"# 用户口头需求（{today()}）\n\n" + "\n\n".join(texts) + "\n", encoding="utf-8")
        inputs.append("raw/user_description.md")
    for d in ("handoff", "debug", "answers", "reviews", "inputs"):
        (ip / ".flow" / d).mkdir(parents=True, exist_ok=True)
    st = {"ip": name, "mode": "auto" if a.auto else "manual", "stage": "P0", "seq": 0, "pending": [],
          "attempts": {}, "round": 0, "passed": [], "asked": False, "reviewer": None, "inputs": inputs,
          "itr": None, "iteration": None, "escalation": None, "last_handoff": {}, "guard": True,
          "created": today(), "history": []}
    log(st, f"init mode={st['mode']} inputs={inputs}")
    save(ip, st)
    print(f"initialized {ip} (mode={st['mode']}); raw inputs: {inputs or 'none'}")
    if not inputs:
        print("WARNING: no requirement input given; put the material into raw/ before running next")


def cmd_next(a):
    ip = a.ip_dir.resolve()
    st = load(ip)
    for _ in range(30):
        act = step(ip, st)
        if act is not None:
            act["stage"] = st["stage"]
            save(ip, st)
            emit(act)
            return
    save(ip, st)
    raise SystemExit("ERROR: flow did not settle after 30 transitions; see .flow/state.json history")


def cmd_answers(a):
    ip = a.ip_dir.resolve()
    st = load(ip)
    if st["stage"] != "ASK":
        raise SystemExit(f"ERROR: not waiting for answers (stage {st['stage']})")
    st["answers_file"] = "" if a.none else rel(ip, Path(a.file).resolve())
    log(st, f"answers {st['answers_file'] or 'none'}")
    save(ip, st)
    print("recorded; run flow.py next")


def cmd_review(a):
    ip = a.ip_dir.resolve()
    st = load(ip)
    if st["stage"] != "REVIEW" or st["pending"]:
        raise SystemExit(f"ERROR: no review is waiting (stage {st['stage']})")
    rv = st["review"]
    if a.changes:
        rv["changes_file"] = rel(ip, Path(a.changes).resolve())
        log(st, f"review changes {rv['gates']} {rv['changes_file']}")
    else:
        if not a.reviewer:
            raise SystemExit("ERROR: --pass requires --reviewer")
        for g in rv["gates"]:
            doc = GATES[g][0]
            fm = front_matter(ip, doc)
            set_front_matter(ip, doc, reviewer=a.reviewer, approved=f"{fm.get('version')}@{today()}",
                             status="Review" if fm.get("status") == "Draft" else fm.get("status"))
        st["reviewer"] = a.reviewer
        log(st, f"review pass {rv['gates']} by {a.reviewer}")
    save(ip, st)
    print("recorded; run flow.py next")


def cmd_iter(a):
    ip = a.ip_dir.resolve()
    st = load(ip)
    if st["pending"]:
        raise SystemExit("ERROR: agents are still running; finish them first")
    if st["stage"] not in ("DONE", "REGRESS", "DEBUG", "FIX") and not st.get("escalation"):
        raise SystemExit(f"ERROR: stage {st['stage']}: iterations start after the first implementation")
    st["seq"] += 1
    f = ip / ".flow" / "inputs" / f"iter-{st['seq']:03d}-{a.kind}.md"
    body = Path(a.file).read_text(encoding="utf-8") if a.file else a.text
    f.write_text(f"# {'需求变更' if a.kind == 'change' else '验证失败 / 问题报告'}（{today()}）\n\n{body}\n", encoding="utf-8")
    st["iteration"] = {"kind": a.kind, "file": rel(ip, f), "affects": None}
    st["escalation"], st["round"] = None, 0
    goto(st, "CHANGE_SPEC" if a.kind == "change" else "REGRESS")   # failure: fresh regression first
    save(ip, st)
    print(f"iteration started ({a.kind}): {rel(ip, f)}; run flow.py next")


def cmd_resume(a):
    ip = a.ip_dir.resolve()
    st = load(ip)
    e = st.get("escalation")
    if not e:
        raise SystemExit("ERROR: nothing to resume")
    note = None
    if a.note:
        note = rel(ip, Path(a.note).resolve()) if Path(a.note).exists() else a.note
    st["escalation"], st["attempts"] = None, {}
    st["stage"] = e["resume_stage"]
    agents = []
    for t in e["tasks"]:
        if note:
            st["note"] = note
        agents.append(new_task(ip, st, t["role"], t["kind"], t["inputs"]))
    if note and not agents:
        st["note"] = note        # picked up by the next dispatch
    log(st, f"resume stage={st['stage']} note={note}")
    save(ip, st)
    if agents:
        emit({**dispatch(agents), "stage": st["stage"]})
    else:
        print("resumed; run flow.py next")


def cmd_status(a):
    ip = a.ip_dir.resolve()
    st = load(ip)
    print(f"IP {st['ip']}  mode={st['mode']}  stage={st['stage']}  round={st['round']}")
    for g, (doc, _, _) in GATES.items():
        fm = front_matter(ip, doc)
        print(f"  {g} {doc}: version={fm.get('version')} approved={fm.get('approved') or '-'} "
              f"reviewer={fm.get('reviewer') or '-'}{'  (stale, re-review)' if g in stale_gates(ip, st) else ''}")
    if st["pending"]:
        print("  running: " + ", ".join(t["id"] for t in st["pending"]))
    if st.get("escalation"):
        print(f"  ESCALATED: {st['escalation']['reason']}")
    if st.get("last_regress"):
        print(f"  last regression: {st['last_regress']}")
    if st.get("itr"):
        print(f"  current ITR: {st['itr']}")
    print("  recent:")
    for h in st["history"][-8:]:
        print(f"    {h}")


def cmd_guard(a):
    ip = a.ip_dir.resolve()
    st = load(ip)
    st["guard"] = a.state == "on"
    log(st, f"guard {a.state}")
    save(ip, st)
    print(f"guard {a.state}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("init")
    p.add_argument("ip_dir", type=Path)
    p.add_argument("--auto", action="store_true", help="do not stop at review gates G0-G2 (approved: skipped)")
    p.add_argument("--input", action="append", help="requirement file/dir (copied to raw/) or free text")
    for n in ("next", "status"):
        sub.add_parser(n).add_argument("ip_dir", type=Path)
    p = sub.add_parser("answers")
    p.add_argument("ip_dir", type=Path)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--file")
    g.add_argument("--none", action="store_true")
    p = sub.add_parser("review")
    p.add_argument("ip_dir", type=Path)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--pass", dest="passed", action="store_true")
    g.add_argument("--changes")
    p.add_argument("--reviewer")
    p = sub.add_parser("iter")
    p.add_argument("ip_dir", type=Path)
    p.add_argument("--kind", choices=["failure", "change"], required=True)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--file")
    g.add_argument("--text")
    p = sub.add_parser("resume")
    p.add_argument("ip_dir", type=Path)
    p.add_argument("--note")
    p = sub.add_parser("guard")
    p.add_argument("ip_dir", type=Path)
    p.add_argument("state", choices=["on", "off"])
    a = ap.parse_args()
    {"init": cmd_init, "next": cmd_next, "answers": cmd_answers, "review": cmd_review, "iter": cmd_iter,
     "resume": cmd_resume, "status": cmd_status, "guard": cmd_guard}[a.cmd](a)


if __name__ == "__main__":
    main()
