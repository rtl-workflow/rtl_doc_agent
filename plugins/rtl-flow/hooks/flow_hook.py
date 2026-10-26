#!/usr/bin/env python3
"""rtl-flow hooks: enforce the multi-agent rules that prompts alone cannot guarantee.

Called by Claude Code with the hook input JSON on stdin (see hooks.json):
    PreToolUse    role-based path guard inside IP directories managed by flow.py
                  (an IP is managed when <ip>/.flow/state.json exists and its "guard" is true)
    PostToolUse   coding-style check after an RTL .v file is written
    SubagentStop  rtl-flow agents must end with "HANDOFF: <path>" pointing to a valid handoff file

Roles come from the hook input `agent_type` ("rtl-flow:tb-engineer" -> tb-engineer); the main
session (no agent_type) is the orchestrator. Any internal error lets the tool call through
(fail open), so the plugin never blocks work outside rtl-flow.
"""
import json
import re
import sys
from pathlib import Path

ROLES = {"spec-author", "architect", "rtl-engineer", "tb-engineer", "debugger"}
SCRIPTS = Path(__file__).resolve().parent.parent / "skills" / "rtl-design-flow" / "scripts"

# where each role may write, relative to the IP directory (prefix match on posix paths)
WRITE = {
    "orchestrator": [".flow/answers/", ".flow/reviews/", ".flow/inputs/", "doc/08_iteration_log.md"],
    "spec-author": ["README.md", "CHANGELOG.md", "raw/", "data/", "doc/00_requirements.md", "doc/01_spec.md",
                    "doc/06_programmers_guide.md", "doc/08_iteration_log.md", "doc/09_decisions.md",
                    "doc/10_checklist.md", ".flow/handoff/"],
    "architect": ["doc/02_architecture.md", "doc/09_decisions.md", "doc/08_iteration_log.md", ".flow/handoff/"],
    "rtl-engineer": ["rtl/", "syn/", "doc/05_rtl_structure.md", "doc/02_architecture.md", "doc/08_iteration_log.md",
                     "doc/09_decisions.md", "doc/10_checklist.md", "README.md", "CHANGELOG.md", ".flow/handoff/"],
    "tb-engineer": ["dv/", "doc/07_dv_plan.md", "doc/08_iteration_log.md", ".flow/handoff/"],
    "debugger": ["doc/08_iteration_log.md", ".flow/debug/", ".flow/handoff/", "dv/build/"],
}
GENERATED = ["doc/03_interfaces.md", "doc/04_registers.md"]
REVIEWED = ["doc/00_requirements.md", "doc/01_spec.md", "doc/02_architecture.md"]
# what the testbench author must not see (independent verification)
TB_HIDDEN = ["rtl/", "syn/", "reports/", "doc/05_rtl_structure.md", "dv/build/regress/", ".flow/handoff/",
             ".flow/state.json"]
TB_BASH_DENY = [r"(^|[\s\"'/\\=])rtl[/\\]", r"\bsyn[/\\]", r"\breports[/\\]", r"05_rtl_structure", r"lint\.log",
                r"build[/\\]regress", r"\.flow[/\\](handoff|state)", r"\bgit\b",
                r"run_regress\.py(?![^\n;&|]*--stub)"]
FLOW_ADMIN = r"flow\.py\b[^\n;&|]*?\b(init|next|answers|review|iter|resume|guard)\b"


def role_of(inp):
    at = inp.get("agent_type") or ""
    if not at:
        return "orchestrator"
    name = at.rsplit(":", 1)[-1]
    return name if name in ROLES else "other"


def managed_root(path: Path):
    """Nearest ancestor (or the path itself) holding .flow/state.json with the guard on."""
    for d in [path] + list(path.parents):
        st = d / ".flow" / "state.json"
        if st.is_file():
            try:
                return d if json.loads(st.read_text(encoding="utf-8")).get("guard", True) else None
            except (OSError, ValueError):
                return d
    return None


def resolve(inp, p):
    q = Path(p)
    if not q.is_absolute():
        q = Path(inp.get("cwd") or ".") / q
    return q.resolve()


def under(rel, prefixes):
    return any(rel == p.rstrip("/") or rel.startswith(p) for p in prefixes)


def deny(reason):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                             "permissionDecisionReason": f"[rtl-flow guard] {reason}"}},
                     ensure_ascii=False))
    sys.exit(0)


def review_fields(text):
    m = re.match(r"---\r?\n(.*?)\r?\n---", text or "", re.S)
    if not m:
        return {}
    out = {}
    for line in m.group(1).splitlines():
        mm = re.match(r"(reviewer|approved)\s*:\s*([^#]*)", line)
        if mm:
            out[mm.group(1)] = mm.group(2).strip()
    return out


def check_write(inp, role, tool, ti, path: Path):
    root = managed_root(path.parent if not path.exists() or path.is_file() else path)
    if root is None:
        return
    rel = path.relative_to(root).as_posix()
    if rel in GENERATED or re.fullmatch(r"sw/[^/]+_regs\.h", rel):
        deny(f"{rel} 由 gen_docs.py 从 data/<ip>.yaml 生成，禁止手改：修改 yaml 后运行 gen_docs.py")
    if rel.startswith("raw/") and path.exists():
        deny("raw/ 中的原始材料只读，不得修改")
    if rel in REVIEWED and path.exists():
        old = review_fields(path.read_text(encoding="utf-8", errors="replace"))
        if tool == "Write":
            new = review_fields(ti.get("content", ""))
            if new != old:
                deny("reviewer / approved 只能由编排者在用户明确通过后通过 flow.py review 写入")
        else:
            olds = ti.get("old_string", "") + "".join(e.get("old_string", "") for e in ti.get("edits", []) or [])
            news = ti.get("new_string", "") + "".join(e.get("new_string", "") for e in ti.get("edits", []) or [])
            if re.search(r"^\s*(reviewer|approved)\s*:", olds + "\n" + news, re.M):
                deny("reviewer / approved 只能由编排者在用户明确通过后通过 flow.py review 写入")
    if role == "other":
        deny(f"{root.name} 由 rtl-flow 管理，只有 rtl-flow 的 agent 可以修改；如需手工修改请让用户执行 flow.py guard off")
    if not under(rel, WRITE[role]):
        who = "编排者只负责调度，不能直接修改设计内容；请派发对应的 agent" if role == "orchestrator" else \
            f"{role} 不能写 {rel}；可写范围：{', '.join(WRITE[role])}"
        deny(who)


def check_tb_read(inp, path: Path):
    root = managed_root(path if path.is_dir() else path.parent)
    if root is None:
        # searching from above an IP directory would reach its RTL
        if path.is_dir():
            for pat in ("*/.flow/state.json", "*/*/.flow/state.json"):
                if next(path.glob(pat), None):
                    deny("tb-engineer 搜索时必须把 path 限定在 IP 目录内允许的子目录（doc/、data/、dv/、raw/、sw/）")
        return
    rel = path.relative_to(root).as_posix() if path != root else ""
    if rel == "" and inp.get("tool_name") in ("Grep", "Glob"):
        deny("tb-engineer 不能在整个 IP 目录中搜索（会读到 RTL）；请把 path 限定到 doc/、data/、dv/、raw/、sw/")
    if under(rel, TB_HIDDEN) or (rel.startswith(".flow/debug/") and not rel.endswith("_tb.md")):
        deny(f"tb-engineer 必须独立于 RTL 构建验证，不能读取 {rel}")


def pre_tool_use(inp):
    role, tool, ti = role_of(inp), inp.get("tool_name", ""), inp.get("tool_input") or {}
    if tool in ("Bash", "PowerShell"):
        cmd = ti.get("command", "")
        if role != "orchestrator" and re.search(FLOW_ADMIN, cmd):
            deny("flow.py 的 init / next / answers / review / iter / resume / guard 只能由编排者（主会话）运行")
        if role == "tb-engineer":
            for pat in TB_BASH_DENY:
                if re.search(pat, cmd):
                    deny("tb-engineer 不能通过命令访问 RTL、lint/综合报告、真实回归结果或 git 历史；"
                         "自检请用 run_regress.py <ip_dir> --stub")
        return
    p = ti.get("file_path") or ti.get("notebook_path") or ti.get("path")
    if tool in ("Write", "Edit", "MultiEdit", "NotebookEdit") and p:
        check_write(inp, role, tool, ti, resolve(inp, p))
    elif role == "tb-engineer" and tool in ("Read", "Grep", "Glob"):
        if not p:
            if tool in ("Grep", "Glob"):
                p = inp.get("cwd") or "."
            else:
                return
        check_tb_read(inp, resolve(inp, p))


def post_tool_use(inp):
    ti = inp.get("tool_input") or {}
    p = ti.get("file_path")
    if not p or not p.endswith(".v"):
        return
    path = resolve(inp, p)
    root = managed_root(path.parent)
    if root is None or not path.relative_to(root).as_posix().startswith("rtl/"):
        return
    sys.path.insert(0, str(SCRIPTS))
    import check_style
    vs = check_style.check_file(path, path.relative_to(root).as_posix())
    if vs:
        lines = [f"{f}:{ln}: [{rule}] {msg}" for f, ln, rule, msg in vs[:25]]
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext":
                          "[rtl-flow] 编码规范检查发现问题，请修复：\n" + "\n".join(lines)}}, ensure_ascii=False))


def subagent_stop(inp):
    if role_of(inp) not in ROLES or inp.get("stop_hook_active"):
        return
    msg = inp.get("last_assistant_message") or ""
    m = re.findall(r"HANDOFF:\s*(\S+)", msg)
    problem = None
    if not m:
        problem = "回复最后一行必须是 `HANDOFF: <交接文件路径>`，且交接文件已按任务提示的格式写好"
    else:
        hp = resolve(inp, m[-1].strip("`\"'"))
        if not hp.is_file():
            problem = f"交接文件 {hp} 不存在，请按任务提示写好后再结束"
        else:
            try:
                import yaml
                h = yaml.safe_load(hp.read_text(encoding="utf-8"))
                missing = [k for k in ("task", "agent", "status", "summary") if not isinstance(h, dict) or k not in h]
                if missing:
                    problem = f"交接文件 {hp} 缺少字段：{', '.join(missing)}"
            except ImportError:
                pass
            except Exception as e:  # noqa: BLE001 - report YAML errors to the agent
                problem = f"交接文件 {hp} 不是合法 YAML：{e}"
    if problem:
        print(json.dumps({"decision": "block", "reason": f"[rtl-flow] {problem}"}, ensure_ascii=False))


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        inp = json.loads(sys.stdin.buffer.read().decode("utf-8") or "{}")
        {"PreToolUse": pre_tool_use, "PostToolUse": post_tool_use,
         "SubagentStop": subagent_stop}.get(inp.get("hook_event_name"), lambda _: None)(inp)
    except SystemExit:
        raise
    except Exception as e:  # noqa: BLE001 - fail open
        print(f"rtl-flow hook error (ignored): {e}", file=sys.stderr)
    sys.exit(0)


if __name__ == "__main__":
    main()
