#!/usr/bin/env python3
"""Check RTL files against references/rtl-coding-style.md (rules marked "自动").

Usage:
    python check_style.py <ip_dir>

The RTL file list comes from data/<ip>.yaml (rtl_files). run_lint.py runs the same
checks and counts every violation as a lint error.

Exit code 0 if no violation.
"""
import argparse
import re
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except AttributeError:
    pass


# --------------------------------------------------------------------------- HDL parsing
def strip_hdl_comments(s):
    """Blank out comments and string literals, keeping newlines so line numbers stay valid."""
    blank = lambda m: re.sub(r"[^\n]", " ", m.group(0))  # noqa: E731
    return re.sub(r'/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\\n])*"', blank, s, flags=re.S)


def matching(s, i):
    """Index of the bracket matching s[i]."""
    pairs = {"(": ")", "[": "]", "{": "}"}
    depth, close = 0, pairs[s[i]]
    for j in range(i, len(s)):
        if s[j] == s[i]:
            depth += 1
        elif s[j] == close:
            depth -= 1
            if depth == 0:
                return j
    return -1


def split_top(s, sep=","):
    parts, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == sep and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur)
    return [p.strip() for p in parts if p.strip()]


DECL_RE = re.compile(
    r"^(input|output|inout)?\s*"
    r"(?:(?:wire|reg|logic|var|tri|bit)\s+)?"
    r"(?:(?:signed|unsigned)\s+)?"
    r"(?:([A-Za-z_]\w*(?:::\w+)?)\s+(?=[A-Za-z_\[]))?"
    r"((?:\[[^\]]*\]\s*)*)"
    r"([A-Za-z_]\w*)\s*(?:\[[^\]]*\]\s*)*(?:=.*)?$", re.S)
KEYWORDS = {"wire", "reg", "logic", "var", "tri", "bit", "signed", "unsigned"}


def module_ports(src, module):
    """Return {name: (dir, width)} in declaration order for `module` in comment-stripped src."""
    m = re.search(r"\bmodule\s+" + re.escape(module) + r"\b", src)
    if not m:
        raise ValueError(f"module '{module}' not found")
    i = m.end()
    end = src.find("endmodule", i)
    body_end = end if end >= 0 else len(src)
    while True:
        rest = src[i:]
        mm = re.match(r"\s*import\s+[^;]*;", rest)
        if mm:
            i += mm.end()
            continue
        break
    j = src.find("#", i)
    k = src.find("(", i)
    if 0 <= j < k:
        k = src.find("(", matching(src, src.find("(", j)) + 1)
    if k < 0 or k > body_end:
        return {}
    close = matching(src, k)
    header, body = src[k + 1:close], src[close + 1:body_end]

    ports, cur_dir, cur_w = {}, None, ""
    names_only = []
    for item in split_top(header):
        dm = DECL_RE.match(item)
        if not dm:
            raise ValueError(f"cannot parse port declaration: '{item}'")
        d, utype, dims, name = dm.groups()
        if utype in KEYWORDS:
            utype = None
        if d:
            cur_dir, cur_w = d, (utype or "") + re.sub(r"\s+", "", dims or "")
        elif cur_dir is None:
            names_only.append(name)
            continue
        ports[name] = (cur_dir, cur_w)
    if names_only:  # non-ANSI style: directions declared in body
        for stmt in body.split(";"):
            dm = re.match(r"\s*(input|output|inout)\b(.*)$", stmt, re.S)
            if not dm:
                continue
            first, *others = split_top(dm.group(2))
            fm_ = DECL_RE.match(dm.group(1) + " " + first)
            if not fm_:
                continue
            w = re.sub(r"\s+", "", fm_.group(3) or "")
            for nm in [fm_.group(4)] + [o.split("=")[0].strip() for o in others]:
                ports[nm] = (dm.group(1), w)
    return ports


def parse_rtl_ports(path: Path, top: str):
    """Return {name: (dir, width)} or raise ValueError."""
    src = strip_hdl_comments(path.read_text(encoding="utf-8", errors="replace"))
    try:
        return module_ports(src, top)
    except ValueError as e:
        raise ValueError(f"{e} in {path}")


def modules_in(src):
    return re.findall(r"\bmodule\s+([A-Za-z_]\w*)", src)


# --------------------------------------------------------------------------- rules
# (rule, pattern on comment-stripped code, message)
PATTERNS = [
    ("HW-01", r"\b(logic|bit|byte|shortint|int|longint|string|always_ff|always_comb|always_latch|typedef|enum|"
              r"struct|union|interface|modport|package|import|unique|priority)\b",
     "SystemVerilog keyword '{0}' not allowed in Verilog-2001 RTL"),
    ("HW-01", r"(?<![\w'])'[01xzXZ]\b", "unsized fill literal '{0}': write {{N{{1'b0}}}} instead"),
    ("HW-01", r"\+\+|--|[-+*/|&^]=(?!=)", "SystemVerilog operator '{0}'"),
    ("HW-01", r"[(,]\s*\.\s*(?:\*|[A-Za-z_]\w*\s*(?=[,)]))", "implicit port connection '{0}': use .port(signal)"),
    ("HW-05", r"`include\b", "`include not allowed"),
    ("HW-34", r"\d*'[sS]?[bBoOhH][0-9a-fA-F_]*[zZ][0-9a-fA-F_zZ]*", "tri-state value '{0}' not allowed inside IP"),
    ("HW-42", r"\bif\s*\(\s*[!~]?\s*rst\w*\s*\)", "reset condition '{0}': write if (rst_n == 1'b0) / if (rst == 1'b1)"),
    ("HW-46", r"\breg\b[^;=()]*=(?!=)", "initial value in reg declaration: initialize by reset"),
    ("HW-50", r"<=\s*#", "delay in nonblocking assignment"),
    ("HW-51", r"\balways\s*@\s*\((?![^)]*\b(?:posedge|negedge)\b)(?!\s*\*\s*\))[^)]*\)",
     "combinational sensitivity list '{0}': use always @(*)"),
    ("HW-54", r"\b(casex|casez)\b", "'{0}' not allowed: use case"),
    ("HW-60", r"\b(initial|wait|fork|join|disable|force|release|deassign|event)\b", "'{0}' not allowed in RTL"),
    ("HW-60", r"#\s*\d", "delay '{0}' not allowed in RTL"),
    ("HW-61", r"\$\w+", "system task/function '{0}' not allowed in RTL"),
    ("HW-62", r"===|!==", "'{0}' not synthesizable"),
    ("HW-62", r"\d*'[sS]?[bBoOhH][0-9a-fA-F_]*[xX?][0-9a-fA-F_xX?]*", "x/? literal '{0}' not allowed in RTL"),
    ("HW-63", r"\b(real|realtime|time|integer)\b", "'{0}' type not allowed in RTL"),
    ("HW-64", r"\b(forever|repeat|while|task)\b", "'{0}' not allowed in RTL"),
    ("HW-65", r"\b(tri0|tri1|triand|trior|trireg|supply0|supply1|nmos|pmos|cmos|rnmos|rpmos|rcmos|tran|tranif0|"
              r"tranif1|rtran|rtranif0|rtranif1|strong0|strong1|weak0|weak1|pull0|pull1|highz0|highz1|"
              r"specify|primitive)\b", "'{0}' not allowed in RTL"),
]
RAW_PATTERNS = [  # checked on raw text, because synthesis pragmas live in comments
    ("HW-54", r"\b(full_case|parallel_case)\b", "synthesis directive '{0}' not allowed"),
]
HEADER_FIELDS = ["Module name", "Function", "Version", "Date"]
DIR_ORDER = {"input": 0, "inout": 1, "output": 2}
PORT_PREFIX = {"input": ("i_", "clk", "rst"), "inout": ("io_",), "output": ("o_",)}
PARAM_RE = re.compile(r"\b(?:parameter|localparam)\b\s*(?:signed\s+)?(?:\[[^\]]*\]\s*)?([A-Za-z_]\w*)\s*=")
DEFINE_RE = re.compile(r"`define\s+([A-Za-z_]\w*)")


def line_of(text, pos):
    return text.count("\n", 0, pos) + 1


def check_case_default(code):
    """Yield (pos, msg) for each case ... endcase without a default item."""
    stack = []
    for m in re.finditer(r"\b(case|casex|casez|endcase|default)\b", code):
        kw = m.group(1)
        if kw.startswith("case"):
            stack.append([m.start(), False])
        elif kw == "default" and stack:
            stack[-1][1] = True
        elif kw == "endcase" and stack:
            start, has_default = stack.pop()
            if not has_default:
                yield start, "case without default"


def check_file(path: Path, rel: str):
    """Return [(rel, line, rule, msg)] for one RTL file."""
    raw = path.read_text(encoding="utf-8", errors="replace")
    code = strip_hdl_comments(raw)
    out = []

    def add(pos, rule, msg):
        out.append((rel, line_of(raw, pos) if pos is not None else 1, rule, msg))

    if path.suffix != ".v":
        add(None, "HW-02", f"file extension '{path.suffix}' must be .v")
    mods = modules_in(code)
    if len(mods) != 1:
        add(None, "HW-02", f"file must contain exactly one module, found {len(mods)}")
    elif mods[0] != path.stem:
        add(None, "HW-02", f"module '{mods[0]}' != file name '{path.stem}'")

    first = next((ln.strip() for ln in raw.splitlines() if ln.strip()), "")
    if not re.fullmatch(r"`timescale\s+1\s*ns\s*/\s*1\s*ps", first):
        add(None, "HW-03", "first line must be `timescale 1ns / 1ps")
    head = "\n".join(raw.splitlines()[:30])
    for f in HEADER_FIELDS:
        if not re.search(r"//.*\b" + f + r"\s*:", head):
            add(None, "HW-04", f"file header field '{f}' missing")

    for rule, pat, msg in PATTERNS:
        for m in re.finditer(pat, code):
            add(m.start(), rule, msg.format(m.group(0).strip()))
    for rule, pat, msg in RAW_PATTERNS:
        for m in re.finditer(pat, raw):
            add(m.start(), rule, msg.format(m.group(0)))
    for pos, msg in check_case_default(code):
        add(pos, "HW-54", msg)

    for m in PARAM_RE.finditer(code):
        n = m.group(1)
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", n) or len(n) > 20:
            add(m.start(1), "HW-13", f"parameter '{n}' must be UPPER_SNAKE_CASE, at most 20 characters")
    for m in DEFINE_RE.finditer(code):
        n = m.group(1)
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", n) or len(n) > 20:
            add(m.start(1), "HW-13", f"macro '{n}' must be UPPER_SNAKE_CASE, at most 20 characters")

    for mod in mods:
        try:
            ports = module_ports(code, mod)
        except ValueError as e:
            add(None, "HW-30", str(e))
            continue
        pos = code.find("module " + mod)
        last = 0
        for n, (d, _) in ports.items():
            if not n.startswith(PORT_PREFIX[d]):
                add(pos, "HW-12", f"{d} port '{n}' must start with {' / '.join(PORT_PREFIX[d])}")
            if not re.fullmatch(r"[a-z][a-z0-9_]*", n):
                add(pos, "HW-11", f"port '{n}' must be lower_snake_case")
            if DIR_ORDER[d] < last:
                add(pos, "HW-30", f"port '{n}': order must be inputs, then inouts, then outputs")
            last = max(last, DIR_ORDER[d])
    return out


def check_ip(ip: Path, files):
    out = []
    for f in files:
        if (ip / f).exists():
            out += check_file(ip / f, f)
    return sorted(out, key=lambda x: (x[0], x[1]))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ip_dir", type=Path)
    a = ap.parse_args()
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import gen_docs
    data, derrs, _ = gen_docs.outputs(a.ip_dir)
    if derrs:
        sys.exit("ERROR: data file invalid, run check_docs.py first")
    vs = check_ip(a.ip_dir, data.get("rtl_files") or [])
    for f, ln, rule, msg in vs:
        print(f"{f}:{ln}: [{rule}] {msg}")
    print(f"\nstyle: {len(vs)} violation(s)")
    sys.exit(1 if vs else 0)


if __name__ == "__main__":
    main()
