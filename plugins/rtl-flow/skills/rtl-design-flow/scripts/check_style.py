#!/usr/bin/env python3
"""Check RTL files against references/rtl-coding-style.md (rules marked "自动").

Usage:
    python check_style.py <ip_dir>

The RTL file list comes from data/<ip>.yaml (rtl_files); rtl/define.v comes first and holds
every macro. run_lint.py runs the same checks and counts every violation as a lint error.

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
              r"struct|union|interface|modport|package|import|unique|priority|uwire)\b",
     "keyword '{0}' not allowed in Verilog-2001 RTL"),
    ("HW-01", r"(?<![\w'])'[01xzXZ]\b", "unsized fill literal '{0}': write {{N{{1'b0}}}} instead"),
    ("HW-01", r"\+\+|--|[-+*/|&^]=(?!=)", "SystemVerilog operator '{0}'"),
    ("HW-01", r"[(,]\s*\.\s*(?:\*|[A-Za-z_]\w*\s*(?=[,)]))", "implicit port connection '{0}': use .port(signal)"),
    ("HW-05", r"`include\b", "`include not allowed"),
    ("HW-34", r"\d*'[sS]?[bBoOhH][0-9a-fA-F_]*[zZ][0-9a-fA-F_zZ]*", "tri-state value '{0}' not allowed inside IP"),
    ("HW-07", r"`(?:define|undef)\b", "'{0}' only allowed in define.v"),
    ("HW-42", r"\bif\s*\(\s*[!~]?\s*rst\w*\s*\)", "reset condition '{0}': compare with ==, e.g. if (rst == `RST_ACT)"),
    ("HW-42", r"\bif\s*\(\s*rst\w*\s*!=[^)]*\)", "reset condition '{0}': compare with ==, e.g. if (rst == `RST_ACT)"),
    ("HW-46", r"\breg\b[^;=()]*=(?!=)", "initial value in reg declaration: initialize by reset"),
    ("HW-51", r"\balways\s*@\s*\((?![^)]*\b(?:posedge|negedge)\b)(?![^)]*`RST_EDGE\b)(?!\s*\*\s*\))[^)]*\)",
     "combinational sensitivity list '{0}': use always @(*)"),
    ("HW-54", r"\bcasex\b", "'{0}' not allowed: use case or casez"),
    ("HW-60", r"\b(initial|wait|fork|join|disable|force|release|deassign|event)\b", "'{0}' not allowed in RTL"),
    ("HW-60", r"#\s*\d", "delay '{0}' not allowed in RTL: write <= #`U_DLY"),
    ("HW-60", r"#\s*[A-Za-z_]\w*", "delay '{0}' not allowed in RTL: write <= #`U_DLY"),
    ("HW-62", r"===|!==", "'{0}' not synthesizable"),
    ("HW-62", r"\d*'[sS]?[bBoOhH][0-9a-fA-F_?zZ]*[xX][0-9a-fA-F_xX?zZ]*", "x literal '{0}' not allowed in RTL"),
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
DEFINE_FILE = "define.v"
DEFINE_RE = re.compile(r"`define\s+([A-Za-z_]\w*)[ \t]*([^\n]*)")
# macros define.v must provide, with their allowed values
REQUIRED_MACROS = {"RST_EDGE": r"(?:posedge|negedge)", "RST_ACT": r"1'b[01]", "U_DLY": r"\d+"}
POLARITY = {"low": ("negedge", "1'b0"), "high": ("posedge", "1'b1")}
LITERAL_RE = re.compile(r"\d*'[sS]?[bBoOhH][0-9a-fA-F_xXzZ?]+")


def line_of(text, pos):
    return text.count("\n", 0, pos) + 1


def is_define_file(rel):
    return Path(rel).name == DEFINE_FILE


def spans(code, start_re, end_kw):
    """[(start, end)] of regions from each start_re match to the next end_kw."""
    out = []
    for m in re.finditer(start_re, code):
        e = re.compile(r"\b" + end_kw + r"\b").search(code, m.end())
        out.append((m.start(), e.end() if e else len(code)))
    return out


def inside(pos, regions):
    return any(s <= pos < e for s, e in regions)


def param_spans(code):
    """Regions where $clog2 is allowed: module #( ... ) parameter lists and parameter/localparam statements."""
    out = []
    for m in re.finditer(r"\bmodule\s+[A-Za-z_]\w*\s*#\s*\(", code):
        out.append((m.end(), matching(code, m.end() - 1)))
    for m in re.finditer(r"\b(?:parameter|localparam)\b", code):
        if not inside(m.start(), out):
            e = code.find(";", m.end())
            out.append((m.start(), e if e >= 0 else len(code)))
    return out


def check_system_calls(code):
    """Yield (pos, msg): system tasks/functions, except $clog2 on the right side of a parameter (HW-61)."""
    params = param_spans(code)
    for m in re.finditer(r"\$\w+", code):
        if m.group(0) == "$clog2":
            if not inside(m.start(), params):
                yield m.start(), "$clog2 only allowed in parameter / localparam declarations"
        else:
            yield m.start(), f"system task/function '{m.group(0)}' not allowed in RTL"


def check_literals(code):
    """Yield (pos, msg) for '?' literals outside casez item labels (HW-62)."""
    casez = spans(code, r"\bcasez\b", "endcase")
    for m in LITERAL_RE.finditer(code):
        lit = m.group(0)
        if "?" in lit and "x" not in lit.lower():
            label = re.match(r"\s*[,:]", code[m.end():])
            if not (inside(m.start(), casez) and label):
                yield m.start(), f"'?' literal '{lit}' only allowed as a casez item"


def check_delays(code):
    """Yield (pos, msg): nonblocking assignments without #`U_DLY (HW-50), other macro delays (HW-60)."""
    loops = []
    for m in re.finditer(r"\bfor\s*\(", code):
        loops.append((m.end(), matching(code, m.end() - 1)))
    for m in re.finditer(r"(?<![<>=!])<=", code):
        if inside(m.start(), loops):
            continue
        j = m.start()
        while j > 0 and code[j - 1].isspace():
            j -= 1
        # walk back over the left-hand side: name, bit/part selects, or a {concatenation}
        while j > 0 and code[j - 1] in "]}":
            k = j - 1
            depth = 0
            while k >= 0:
                if code[k] in "]}":
                    depth += 1
                elif code[k] in "[{":
                    depth -= 1
                    if depth == 0:
                        break
                k -= 1
            j = k
            while j > 0 and code[j - 1].isspace():
                j -= 1
        if j < len(code) and code[j] == "{":
            pass
        else:
            nm = re.search(r"[A-Za-z_]\w*$", code[:j])
            if not nm:
                continue  # comparison: left side is an expression, not a variable
            j = nm.start()
        before = code[:j].rstrip()
        if not re.search(r"(?:[;):]|\bbegin|\belse)$", before):
            continue  # comparison inside an expression
        if not re.match(r"\s*#\s*`U_DLY\b", code[m.end():]):
            yield m.start(), "nonblocking assignment must be written <= #`U_DLY"
    for m in re.finditer(r"#\s*`(\w+)", code):
        if m.group(1) != "U_DLY" or not code[:m.start()].rstrip().endswith("<="):
            yield m.start(), f"delay '{m.group(0)}' not allowed: only <= #`U_DLY"


def check_resets(code, std):
    """Yield (pos, rule, msg) for reset edges (HW-41) and reset conditions (HW-42).

    std maps standard-interface reset names (std_if in data) to their active level; every other
    rst* signal is an internal reset whose polarity comes from `RST_EDGE / `RST_ACT.
    """
    for m in re.finditer(r"(\bposedge|\bnegedge|`RST_EDGE)\s+(rst\w*)", code):
        edge, n = m.group(1), m.group(2)
        if n in std:
            want = POLARITY[std[n]][0]
            if edge != want:
                yield m.start(), "HW-41", f"standard-interface reset '{n}' is active-{std[n]}: write {want} {n}"
        elif edge != "`RST_EDGE":
            yield m.start(), "HW-41", f"reset edge '{m.group(0)}': write `RST_EDGE {n}"
    for m in re.finditer(r"\bif\s*\(\s*(rst\w*)\s*==\s*([^)]*?)\s*\)", code):
        n, v = m.group(1), m.group(2)
        want = POLARITY[std[n]][1] if n in std else "`RST_ACT"
        if v != want:
            yield m.start(), "HW-42", f"reset condition '{m.group(0)}': write if ({n} == {want})"


def check_define_file(path: Path, rel: str):
    """Return ([(rel, line, rule, msg)], {macro: value}) for define.v (HW-07)."""
    raw = path.read_text(encoding="utf-8", errors="replace")
    code = strip_hdl_comments(raw)
    out, macros = [], {}

    def add(pos, rule, msg):
        out.append((rel, line_of(raw, pos) if pos is not None else 1, rule, msg))

    first = next((ln.strip() for ln in raw.splitlines() if ln.strip()), "")
    if not re.fullmatch(r"`timescale\s+1\s*ns\s*/\s*1\s*ps", first):
        add(None, "HW-03", "first line must be `timescale 1ns / 1ps")
    head = "\n".join(raw.splitlines()[:30])
    for f in HEADER_FIELDS[1:]:
        if not re.search(r"//.*\b" + f + r"\s*:", head):
            add(None, "HW-04", f"file header field '{f}' missing")

    pos = 0
    for ln in code.splitlines(keepends=True):
        s = ln.strip()
        if s and not re.match(r"`(?:define|timescale)\b", s):
            add(pos, "HW-07", f"define.v may only contain `define: '{s[:40]}'")
        pos += len(ln)
    for m in DEFINE_RE.finditer(code):
        n, v = m.group(1), m.group(2).strip()
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", n) or len(n) > 20:
            add(m.start(1), "HW-13", f"macro '{n}' must be UPPER_SNAKE_CASE, at most 20 characters")
        if n in macros:
            add(m.start(1), "HW-07", f"macro '{n}' defined twice")
        macros[n] = v
    for n, pat in REQUIRED_MACROS.items():
        if n not in macros:
            add(None, "HW-07", f"macro '{n}' must be defined in define.v")
        elif not re.fullmatch(pat, macros[n]):
            add(code.find(n), "HW-07", f"macro '{n}' = '{macros[n]}' is not one of {pat}")
    edge, act = macros.get("RST_EDGE"), macros.get("RST_ACT")
    if (edge, act) in (("negedge", "1'b1"), ("posedge", "1'b0")):
        add(code.find("RST_ACT"), "HW-07", f"RST_EDGE = {edge} does not match RST_ACT = {act}")
    return out, macros


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


def check_file(path: Path, rel: str, std=None):
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
    for pos, msg in check_system_calls(code):
        add(pos, "HW-61", msg)
    for pos, msg in check_literals(code):
        add(pos, "HW-62", msg)
    for pos, rule, msg in check_resets(code, std or {}):
        add(pos, rule, msg)
    for pos, msg in check_delays(code):
        add(pos, "HW-50" if msg.startswith("nonblocking") else "HW-60", msg)

    for m in PARAM_RE.finditer(code):
        n = m.group(1)
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", n) or len(n) > 20:
            add(m.start(1), "HW-13", f"parameter '{n}' must be UPPER_SNAKE_CASE, at most 20 characters")

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


def check_ip(ip: Path, files, resets=None):
    """Style violations of the RTL files; resets (data/<ip>.yaml) are checked against define.v."""
    out = []
    std = {r.get("name"): r.get("active") for r in resets or [] if r.get("std_if")}
    internal = [r for r in resets or [] if not r.get("std_if")]
    defs = [f for f in files if is_define_file(f)]
    if not files or not is_define_file(files[0]):
        out.append((files[0] if files else "rtl_files", 1, "HW-07",
                    f"rtl_files must list rtl/{DEFINE_FILE} first"))
    for f in defs[1:]:
        out.append((f, 1, "HW-07", f"only one {DEFINE_FILE} allowed in rtl_files"))
    for f in files:
        if not (ip / f).exists():
            continue
        if is_define_file(f):
            vs, macros = check_define_file(ip / f, f)
            out += vs
            want = POLARITY.get(internal[0].get("active")) if internal else None
            if want and (macros.get("RST_EDGE"), macros.get("RST_ACT")) != want:
                out.append((f, 1, "HW-07", f"internal reset is active-{internal[0]['active']} in data: "
                                           f"RST_EDGE / RST_ACT must be {want[0]} / {want[1]}"))
        else:
            out += check_file(ip / f, f, std)
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
    vs = check_ip(a.ip_dir, data.get("rtl_files") or [], data.get("resets"))
    for f, ln, rule, msg in vs:
        print(f"{f}:{ln}: [{rule}] {msg}")
    print(f"\nstyle: {len(vs)} violation(s)")
    sys.exit(1 if vs else 0)


if __name__ == "__main__":
    main()
