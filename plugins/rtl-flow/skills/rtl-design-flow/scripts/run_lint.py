#!/usr/bin/env python3
"""Run RTL lint on an IP and save the result to <ip_dir>/reports/lint.log.

Usage:
    python run_lint.py <ip_dir> [--tool verilator|verible]

The RTL file list and top module come from data/<ip>.yaml (rtl_files, top).
The log header records a digest of the RTL sources; check_docs.py --stage rtl
uses it to reject a missing, failing or stale lint report.

Exit code 0 if lint reports no error.
"""
import argparse
import hashlib
import os
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_docs  # noqa: E402

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except AttributeError:
    pass

LOG = Path("reports") / "lint.log"


def rtl_digest(ip: Path, files):
    """sha256 over the RTL sources (line endings normalized, so CRLF checkouts match)."""
    h = hashlib.sha256()
    for f in files:
        h.update(f.encode() + b"\0")
        h.update((ip / f).read_bytes().replace(b"\r\n", b"\n") + b"\0")
    return h.hexdigest()


def read_header(path: Path):
    """Return {key: value} from the '# key: value' header lines of a lint log."""
    hdr = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.startswith("# "):
            break
        if ":" in line:
            k, v = line[2:].split(":", 1)
            hdr[k.strip()] = v.strip()
    return hdr


def find_exe(*names):
    for n in names:
        p = shutil.which(n)
        if p:
            return p
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ip_dir", type=Path)
    ap.add_argument("--tool", choices=["verilator", "verible"], default="verilator")
    a = ap.parse_args()
    ip = a.ip_dir

    data, derrs, _ = gen_docs.outputs(ip)
    if derrs:
        sys.exit("ERROR: data file invalid, run check_docs.py first")
    files, top = data.get("rtl_files") or [], data["top"]
    if not files:
        sys.exit("ERROR: data/<ip>.yaml has no rtl_files")
    missing = [f for f in files if not (ip / f).exists()]
    if missing:
        sys.exit(f"ERROR: rtl file(s) missing: {', '.join(missing)}")

    if a.tool == "verilator":
        # on Windows 'verilator' is a Perl wrapper that cannot be executed directly
        names = ("verilator_bin", "verilator") if os.name == "nt" else ("verilator", "verilator_bin")
        exe = find_exe(*names)
        args = ["--lint-only", "-Wall", "--top-module", top]
    else:
        exe = find_exe("verible-verilog-lint")
        args = []
    if not exe:
        sys.exit(f"ERROR: {a.tool} not found in PATH")

    cmd = [exe] + args + files
    r = subprocess.run(cmd, cwd=ip, capture_output=True, text=True, encoding="utf-8", errors="replace")
    out = (r.stdout + r.stderr).strip()

    if a.tool == "verilator":
        # "%Error: Exiting due to N error(s)/warning(s)" is a summary line, not a finding of its own
        errors = len(re.findall(r"^%Error(?!: Exiting due to)", out, re.M))
        warnings = len(re.findall(r"^%Warning", out, re.M))
    else:
        warnings = len(re.findall(r"^\S+:\d+:\d+(?:-\d+)?:", out, re.M))
        errors = 0
    if r.returncode != 0 and errors == 0 and warnings == 0:
        errors = 1  # tool failed without a parsable message
    result = "FAIL" if errors else ("WARN" if warnings else "PASS")

    shown = " ".join([Path(exe).stem] + args + files)
    log = ip / LOG
    log.parent.mkdir(exist_ok=True)
    log.write_text(
        "# rtl-flow lint report\n"
        f"# command: {shown}\n"
        f"# date: {date.today().isoformat()}\n"
        f"# rtl-sha256: {rtl_digest(ip, files)}\n"
        f"# result: {result}\n"
        f"# errors: {errors}\n"
        f"# warnings: {warnings}\n"
        "\n" + (out + "\n" if out else "(no output)\n"),
        encoding="utf-8")
    print(out or "(no output)")
    print(f"\nlint {result}: {errors} error(s), {warnings} warning(s) -> {LOG.as_posix()}")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
