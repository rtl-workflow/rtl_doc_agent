#!/usr/bin/env python3
"""Check an IP directory against the rtl-flow documentation standard.

Usage:
    python check_docs.py <ip_dir> [--stage req|spec|arch|rtl|dv|signoff]

Stages are cumulative; each enables stricter checks (see SKILL.md gates G0-G3):
    req      files, front matter, mandatory sections, ID definitions/references, data file validity
    spec     + every REQ referenced in 01_spec, generated docs up to date, 00 approved (G0)
    arch     + 02 sub-module table complete, 01 approved (G1)
    rtl      + RTL top-level ports match data/<ip>.yaml, sub-modules of 02 exist in RTL and 05,
               reports/lint.log present, current and without error, 02 approved (G2)
    dv       + every REQ covered by a TP in 07_dv_plan
    signoff  + no placeholders/TODO/TBD/Open Q/unconfirmed ASM, all docs Released, checklist complete,
               every review gate approved by a person (approved: skipped not allowed)

Exit code 0 if no ERROR.
"""
import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_docs  # noqa: E402
import run_lint  # noqa: E402
from check_style import parse_rtl_ports, strip_hdl_comments  # noqa: E402

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except AttributeError:
    pass

STAGES = ["req", "spec", "arch", "rtl", "dv", "signoff"]
TEMPLATES = Path(__file__).resolve().parent.parent / "templates"
HAND_DOCS = ["00_requirements", "01_spec", "02_architecture", "05_rtl_structure",
             "06_programmers_guide", "07_dv_plan", "08_iteration_log", "09_decisions", "10_checklist"]
GEN_DOCS = ["03_interfaces", "04_registers"]
STATUSES = {"Draft", "Review", "Released"}
FM_FIELDS = ["doc", "ip", "version", "status", "updated", "owner"]

# reviewed doc -> first stage that requires its approval (gate G0/G1/G2)
REVIEW_GATES = {"00_requirements": "spec", "01_spec": "arch", "02_architecture": "rtl"}
APPROVED_RE = re.compile(r"(\d+\.\d+)@(\d{4}-\d{2}-\d{2})")

ID_RE = r"(?:REQ-(?:[A-Z]+-)?\d{3}|ASM-\d{3}|Q-\d{3}|DEC-\d{3}|TP-\d{3}|ITR-\d{3}|BUG-\d{3})"
ID_HOME = {"REQ": "00_requirements", "ASM": "00_requirements", "Q": "00_requirements",
           "DEC": "09_decisions", "TP": "07_dv_plan", "ITR": "08_iteration_log", "BUG": "08_iteration_log"}


class Report:
    def __init__(self):
        self.items = []

    def err(self, where, msg):
        self.items.append(("ERROR", where, msg))

    def warn(self, where, msg):
        self.items.append(("WARN", where, msg))

    def at(self, enforce, where, msg):
        (self.err if enforce else self.warn)(where, msg)

    def print(self):
        for lvl, where, msg in sorted(self.items, key=lambda x: (x[0] != "ERROR", x[1])):
            print(f"{lvl:5}  {where}: {msg}")
        e = sum(1 for i in self.items if i[0] == "ERROR")
        w = len(self.items) - e
        print(f"\n{e} error(s), {w} warning(s)")
        return e


# --------------------------------------------------------------------------- markdown helpers
def split_front_matter(text):
    m = re.match(r"---\r?\n(.*?)\r?\n---\r?\n", text, re.S)
    if not m:
        return None, text
    fm = {}
    for line in m.group(1).splitlines():
        line = line.split("#", 1)[0].rstrip()
        if ":" in line:
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip()
    return fm, text[m.end():]


def strip_code(text):
    return re.sub(r"```.*?```", "", text, flags=re.S)


def h2_headings(text):
    return [l[3:].strip() for l in strip_code(text).splitlines() if l.startswith("## ")]


def table_rows(text):
    """Yield list of cells for every markdown table row (separator rows skipped)."""
    for line in strip_code(text).splitlines():
        s = line.strip()
        if s.startswith("|") and not re.fullmatch(r"\|[\s:\-|]+\|?", s):
            yield [c.strip() for c in s.strip("|").split("|")]


def defined_ids(text):
    """IDs defined as the first cell of a table row, or as a ### heading (ITR/DEC details)."""
    ids = {}
    for cells in table_rows(text):
        m = re.fullmatch(r"(?:~~)?(" + ID_RE + r")(?:~~)?", cells[0])
        if m:
            ids.setdefault(m.group(1), cells)
    for m in re.finditer(r"^###\s+(" + ID_RE + r")\b", text, re.M):
        ids.setdefault(m.group(1), None)
    return ids


def expected_width(w):
    if isinstance(w, int):
        return "" if w == 1 else f"[{w - 1}:0]"
    return f"[{str(w).replace(' ', '')}-1:0]"


def arch_modules(text):
    """{module: cells} from the sub-module table in 02 §2 (first column `module_name`)."""
    body = strip_code(split_front_matter(text)[1])
    m = re.search(r"^## [^\n]*Sub-modules[^\n]*\n(.*?)(?=^## |\Z)", body, re.S | re.M)
    mods = {}
    for cells in table_rows(m.group(1) if m else ""):
        mm = re.match(r"`([A-Za-z_]\w*)`", cells[0])
        if mm:
            mods[mm.group(1)] = cells
    return mods


def check_review(rep, name, fm, required, signoff):
    """Gate approval in front matter: reviewer + approved: <version>@YYYY-MM-DD, or approved: skipped."""
    appr, who = fm.get("approved", ""), fm.get("reviewer", "")
    if appr == "skipped":
        rep.at(signoff, name, "review skipped (auto mode); a person must approve before signoff")
        return
    if not appr:
        if required:
            rep.err(name, "not approved: ask the user to review at the gate, then fill reviewer/approved")
        return
    m = APPROVED_RE.fullmatch(appr)
    if not m:
        rep.err(name, f"approved '{appr}' must be <version>@YYYY-MM-DD or skipped")
        return
    if not who:
        rep.err(name, "approved is set but reviewer is empty")
    if m.group(1) != fm.get("version"):
        rep.at(required, name, f"approved version {m.group(1)} != current version {fm.get('version')}: "
                               "changed after review, re-review required")


# --------------------------------------------------------------------------- checks
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ip_dir", type=Path)
    ap.add_argument("--stage", choices=STAGES, default="req")
    a = ap.parse_args()
    ip, lvl = a.ip_dir, STAGES.index(a.stage)
    at_least = lambda s: lvl >= STAGES.index(s)  # noqa: E731
    signoff = a.stage == "signoff"
    rep = Report()

    # ---- data file
    data, derrs = None, []
    try:
        data, derrs, gen_files = gen_docs.outputs(ip)
        for e in derrs:
            rep.err("data", e)
    except SystemExit as e:
        rep.err("data", str(e).replace("ERROR: ", ""))
        gen_files = {}
    ip_name = data.get("name") if isinstance(data, dict) else None

    # ---- files and front matter
    docs = {}
    for name in ["README", "CHANGELOG"] + [f"doc/{n}" for n in HAND_DOCS + GEN_DOCS]:
        p = ip / f"{name}.md"
        if not p.exists():
            if Path(name).name not in GEN_DOCS:  # generated docs are reported by the freshness check
                rep.err(name, "missing file")
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        fm, body = split_front_matter(text)
        stem = Path(name).name
        docs[stem] = text
        if fm is None:
            rep.err(name, "missing front matter")
            continue
        generated = stem in GEN_DOCS
        for f in (["doc", "ip", "version", "status"] if generated else FM_FIELDS):
            if not fm.get(f):
                rep.err(name, f"front matter field '{f}' missing or empty")
        if fm.get("doc") and fm["doc"] != stem:
            rep.err(name, f"front matter doc '{fm['doc']}' != file name '{stem}'")
        if ip_name and fm.get("ip") and fm["ip"] != ip_name:
            rep.err(name, f"front matter ip '{fm['ip']}' != data name '{ip_name}'")
        if not generated:
            if fm.get("status") and fm["status"] not in STATUSES:
                rep.err(name, f"status '{fm['status']}' not in {sorted(STATUSES)}")
            if fm.get("updated") and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", fm["updated"]):
                rep.err(name, f"updated '{fm['updated']}' must be YYYY-MM-DD")
            if signoff and fm.get("status") != "Released":
                rep.err(name, f"status is '{fm.get('status')}', must be Released for signoff")
            if stem in REVIEW_GATES:
                check_review(rep, name, fm, at_least(REVIEW_GATES[stem]), signoff)

        # mandatory sections from template
        tpl = TEMPLATES / f"{name}.md"
        if tpl.exists():
            have = set(h2_headings(body))
            for h in h2_headings(tpl.read_text(encoding="utf-8")):
                if h not in have:
                    rep.err(name, f"missing mandatory section '## {h}'")

        # placeholders / TODO / TBD
        released = signoff or fm.get("status") == "Released"
        for ln, line in enumerate(text.splitlines(), 1):
            if "{{" in line:
                rep.at(released, f"{name}:{ln}", f"unfilled placeholder: {line.strip()[:80]}")
            if re.search(r"\bTODO\b", line):
                rep.at(released, f"{name}:{ln}", "TODO left in document")
            for m in re.finditer(r"\bTBD\b(\(Q-\d{3}\))?", line):
                if not m.group(1):
                    rep.err(f"{name}:{ln}", "TBD must be written as TBD(Q-xxx)")
                elif released:
                    rep.err(f"{name}:{ln}", f"{m.group(0)} not allowed in Released document")

    # ---- generated docs freshness
    for path, content in gen_files.items():
        rel = path.relative_to(ip).as_posix()
        if not path.exists():
            rep.at(at_least("spec"), rel, "generated file missing, run gen_docs.py")
        elif path.read_text(encoding="utf-8").replace("\r\n", "\n") != content:
            rep.at(at_least("spec"), rel, "stale or hand-edited, run gen_docs.py")

    # ---- IDs: definitions, duplicates, dangling references
    defs = {}
    for stem, text in docs.items():
        for i in defined_ids(split_front_matter(text)[1]):
            prefix = i.split("-")[0]
            if ID_HOME.get(prefix) == stem:
                defs[i] = stem
    for stem, text in docs.items():
        for i in sorted(set(re.findall(r"\b" + ID_RE + r"\b", text))):
            if i not in defs:
                home = ID_HOME[i.split("-")[0]]
                rep.err(stem, f"{i} referenced but not defined in {home}")

    req_text = docs.get("00_requirements", "")
    reqs = sorted(i for i, s in defs.items() if i.startswith("REQ-"))
    if "00_requirements" in docs and not reqs:
        rep.err("00_requirements", "no REQ defined")

    def refs_in(stem):
        return set(re.findall(r"\b" + ID_RE + r"\b", docs.get(stem, "")))

    spec_refs, dv_refs = refs_in("01_spec"), refs_in("07_dv_plan")
    tps = [i for i, s in defs.items() if i.startswith("TP-")]
    for r in reqs:
        if r not in spec_refs:
            rep.at(at_least("spec"), "01_spec", f"{r} not covered by any spec section")
        if r not in dv_refs:
            rep.at(at_least("dv"), "07_dv_plan", f"{r} not covered by any test point")
    if at_least("dv") and not tps:
        rep.err("07_dv_plan", "no TP defined")

    # open questions / unconfirmed assumptions
    for cells in table_rows(split_front_matter(req_text)[1] if req_text else ""):
        if re.fullmatch(r"Q-\d{3}", cells[0]) and any(c.lower() == "open" for c in cells[1:]):
            rep.at(signoff, "00_requirements", f"{cells[0]} is still Open")
        if re.fullmatch(r"ASM-\d{3}", cells[0]) and any("待确认" in c for c in cells[1:]):
            rep.at(signoff, "00_requirements", f"{cells[0]} not confirmed by user")

    # checklist
    cl = docs.get("10_checklist", "")
    todo = len(re.findall(r"^\s*- \[ \]", cl, re.M))
    done = len(re.findall(r"^\s*- \[[xX]\]", cl, re.M))
    if signoff and todo:
        rep.err("10_checklist", f"{todo} item(s) unchecked")
    elif cl:
        print(f"INFO   10_checklist: {done}/{done + todo} items checked")

    # ---- architecture sub-modules
    arch_text = docs.get("02_architecture")
    mods = arch_modules(arch_text) if arch_text else {}
    if at_least("arch") and arch_text is not None:
        if not mods:
            rep.err("02_architecture", "§2 sub-module table lists no module (first column must be `module_name`)")
        for n, cells in mods.items():
            if len(cells) < 4 or not cells[2] or not cells[3] or "{{" in cells[2] + cells[3]:
                rep.err("02_architecture", f"sub-module '{n}': responsibility and key interface must be filled")

    # ---- RTL ports, modules, lint
    if at_least("rtl") and isinstance(data, dict) and data.get("rtl_files") and not derrs:
        top_file = ip / data["rtl_files"][0]
        for f in data["rtl_files"]:
            if not (ip / f).exists():
                rep.err("rtl", f"rtl file '{f}' listed in data but missing")
        if top_file.exists():
            try:
                rtl = parse_rtl_ports(top_file, data["top"])
            except ValueError as e:
                rep.err("rtl", str(e))
                rtl = None
            if rtl is not None:
                spec = {p["name"]: p for p in data["ports"]}
                for n, p in spec.items():
                    if n not in rtl:
                        rep.err("rtl", f"port '{n}' in data but not in RTL module '{data['top']}'")
                        continue
                    d, w = rtl[n]
                    if d != p["dir"]:
                        rep.err("rtl", f"port '{n}': direction RTL={d} data={p['dir']}")
                    ew = expected_width(p["width"])
                    if w != ew:
                        rep.err("rtl", f"port '{n}': width RTL='{w or '1'}' data='{ew or '1'}'")
                for n in rtl:
                    if n not in spec:
                        rep.err("rtl", f"port '{n}' in RTL but not in data/{data['_src']}")

        present = [f for f in data["rtl_files"] if (ip / f).exists()]
        rtl_mods = set()
        for f in present:
            src = strip_hdl_comments((ip / f).read_text(encoding="utf-8", errors="replace"))
            rtl_mods |= set(re.findall(r"\bmodule\s+([A-Za-z_]\w*)", src))
        s05 = docs.get("05_rtl_structure", "")
        for n in sorted(mods):
            if n not in rtl_mods:
                rep.err("02_architecture", f"sub-module '{n}' not found in RTL files")
        for n in sorted(rtl_mods):
            if f"`{n}`" not in s05:
                rep.err("05_rtl_structure", f"RTL module '{n}' not described")
            if mods and n not in mods:
                rep.warn("02_architecture", f"RTL module '{n}' not listed in §2 sub-modules")

        log = ip / run_lint.LOG
        if not log.exists():
            rep.err(run_lint.LOG.as_posix(), "missing, run run_lint.py")
        elif len(present) == len(data["rtl_files"]):
            hdr = run_lint.read_header(log)
            if hdr.get("rtl-sha256") != run_lint.rtl_digest(ip, data["rtl_files"]):
                rep.err(run_lint.LOG.as_posix(), "stale (RTL changed after lint), run run_lint.py")
            elif hdr.get("result") == "FAIL":
                rep.err(run_lint.LOG.as_posix(), f"lint failed with {hdr.get('errors')} error(s)")
            elif hdr.get("result") != "PASS":
                rep.warn(run_lint.LOG.as_posix(),
                         f"{hdr.get('warnings')} lint warning(s): fix, or waive in 05_rtl_structure §7")

    sys.exit(1 if rep.print() else 0)


if __name__ == "__main__":
    main()
