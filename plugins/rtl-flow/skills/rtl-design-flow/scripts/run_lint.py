#!/usr/bin/env python3
"""Run RTL lint on an IP and save the result to <ip_dir>/reports/lint.log.

Usage:
    python run_lint.py <ip_dir> [--tool spyglass|vcs]

Two passes, both counted in the report:
  1. coding-style check (check_style.py, references/rtl-coding-style.md): every violation is an error;
  2. the lint tool: SpyGlass goal lint/lint_rtl (default, rtl_handoff methodology; Fatal/Error count
     as errors, Warning as warnings) or VCS +lint=all (Error-[..] errors, Warning-/Lint-[..] warnings).
     Both read Verilog-2005 (for $clog2); check_style keeps the rest of the code within Verilog-2001.

Where it runs: with RTLFLOW_EXEC=remote the IP is copied to the EDA server (remote_exec.py), this
script runs there and reports/lint.log is written back here; otherwise the tool must be in PATH.

The RTL file list and top module come from data/<ip>.yaml (rtl_files, top); files are passed
in that order, so rtl/define.v (listed first) supplies the macros to the rest.
The log header records a digest of the RTL sources; check_docs.py --stage rtl
uses it to reject a missing, failing or stale lint report.

Exit code 0 if lint reports no error. A missing tool, a license failure or an unreachable server
stop the script with an "ERROR:" message and no report: an environment problem, not a design one.
"""
import argparse
import hashlib
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_style  # noqa: E402
import gen_docs  # noqa: E402
import remote_exec  # noqa: E402

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


BUILD = Path("dv") / "build" / "lint"
TOOL_TIMEOUT_S = 1800
# SpyGlass moresimple.rpt rows: "[id] Rule Alias Severity File Line Wt Message" (Alias may contain spaces)
SG_ROW_RE = re.compile(r"^\[\w+\]\s+(\S+)\s.*?\s(Fatal|Error|Warning|Info)\s+(\S+)\s+(\d+)\s+\d+\s+(.*)$")
VCS_MSG_RE = re.compile(r"^(Error|Warning|Lint)-\[([^\]]+)\]\s*(.*?)(?=^\s*$|\Z)", re.M | re.S)
LICENSE_RE = re.compile(r"licen[cs]e.*(fail|error|unavailable|not available|checkout|denied)"
                        r"|unable to (check ?out|obtain).*licen|FLEXnet|lmgrd", re.I)


def tool_exe(name):
    p = shutil.which(name)
    if not p:
        sys.exit(f"ERROR: '{name}' not found in PATH: load the EDA module, "
                 "or set RTLFLOW_EXEC=remote to run on the EDA server")
    return p


def run_tool(cmd, cwd: Path, logname):
    """Run a lint tool, keep its full output in dv/build/lint/<logname>; stop on license problems."""
    try:
        r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, encoding="utf-8", errors="replace",
                           timeout=TOOL_TIMEOUT_S)
    except subprocess.TimeoutExpired:
        sys.exit(f"ERROR: {Path(cmd[0]).name} did not finish in {TOOL_TIMEOUT_S}s")
    out = r.stdout + r.stderr
    (cwd / logname).write_text(out, encoding="utf-8")
    if LICENSE_RE.search(out) and r.returncode != 0:
        sys.exit(f"ERROR: {Path(cmd[0]).name} license problem:\n" + "\n".join(out.splitlines()[-15:]))
    return r.returncode, out


def lint_spyglass(ip: Path, files, top):
    """SpyGlass lint/lint_rtl -> (findings, errors, warnings, command shown in the header)."""
    build = ip / BUILD / "spyglass"
    shutil.rmtree(build, ignore_errors=True)
    build.mkdir(parents=True)
    prj = build / "lint.prj"
    reads = " ".join(str((ip / f).resolve()) for f in files)
    prj.write_text(f"read_file -type verilog {reads}\n"
                   f"set_option top {top}\n"
                   "set_option enableV05 yes\n"
                   "current_methodology $env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff\n"
                   f"current_goal lint/lint_rtl -top {top}\n"
                   "run_goal\n"
                   "exit -force\n", encoding="utf-8")
    code, out = run_tool([tool_exe("sg_shell"), "-tcl", "lint.prj"], build, "sg_shell.log")
    rpt = next(build.rglob("moresimple.rpt"), None)
    if rpt is None:
        sys.exit("ERROR: SpyGlass produced no moresimple.rpt (see dv/build/lint/spyglass/sg_shell.log):\n" +
                 "\n".join(out.splitlines()[-15:]))
    findings, errors, warnings = [], 0, 0
    root = ip.resolve()
    for line in rpt.read_text(encoding="utf-8", errors="replace").splitlines():
        m = SG_ROW_RE.match(line)
        if not m or m.group(2) == "Info":
            continue
        rule, sev, f, ln, msg = m.groups()
        try:
            f = Path(f).resolve().relative_to(root).as_posix()
        except ValueError:
            pass
        findings.append(f"%{'Error' if sev in ('Fatal', 'Error') else 'Warning'}-SG: {f}:{ln}: [{rule}] {msg.strip()}")
        errors += sev in ("Fatal", "Error")
        warnings += sev == "Warning"
    return findings, errors, warnings, f"sg_shell lint/lint_rtl -top {top} " + " ".join(files)


def lint_vcs(ip: Path, files, top):
    """VCS +lint=all elaboration -> (findings, errors, warnings, command shown in the header)."""
    build = ip / BUILD / "vcs"
    shutil.rmtree(build, ignore_errors=True)
    build.mkdir(parents=True)
    args = ["-full64", "+v2k", "+lint=all", "+vcs+lic+wait", "-top", top, "-Mdir=csrc", "-o", "simv_lint"]
    code, out = run_tool([tool_exe("vcs")] + args + [str((ip / f).resolve()) for f in files], build, "vcs_lint.log")
    findings, errors, warnings = [], 0, 0
    for m in VCS_MSG_RE.finditer(out):
        kind, rid, body = m.groups()
        detail = " | ".join(l.strip() for l in body.splitlines() if l.strip())[:400]
        findings.append(f"%{'Error' if kind == 'Error' else 'Warning'}-VCS: [{rid}] {detail}")
        errors += kind == "Error"
        warnings += kind != "Error"
    if code != 0 and errors == 0:
        errors = 1  # tool failed without a parsable message
        findings.append("%Error-VCS: elaboration failed: " + " | ".join(out.splitlines()[-5:]))
    return findings, errors, warnings, "vcs " + " ".join(args) + " " + " ".join(files)


def lint_remote(ip: Path, tool):
    """Run this script on the EDA server; reports/lint.log comes back into `ip`."""
    ip = ip.resolve()
    try:
        fin = remote_exec.run_ip_script("run_lint.py", ip, ["--tool", tool], [LOG.as_posix()], timeout=3600)
    except remote_exec.RemoteError as e:
        sys.exit(f"ERROR: remote lint could not run (environment problem): {e}")
    print(fin.output())
    if f"{ip.name}/{LOG.as_posix()}" not in fin.files:
        sys.exit("ERROR: remote lint stopped before writing reports/lint.log")
    sys.exit(fin.exit_code if fin.exit_code in (0, 1) else 1)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ip_dir", type=Path)
    ap.add_argument("--tool", choices=["spyglass", "vcs"], default="spyglass")
    a = ap.parse_args()
    ip = a.ip_dir
    if remote_exec.enabled():
        lint_remote(ip, a.tool)

    data, derrs, _ = gen_docs.outputs(ip)
    if derrs:
        sys.exit("ERROR: data file invalid, run check_docs.py first")
    files, top = data.get("rtl_files") or [], data["top"]
    if not files:
        sys.exit("ERROR: data/<ip>.yaml has no rtl_files")
    missing = [f for f in files if not (ip / f).exists()]
    if missing:
        sys.exit(f"ERROR: rtl file(s) missing: {', '.join(missing)}")

    findings, errors, warnings, shown = (lint_spyglass if a.tool == "spyglass" else lint_vcs)(ip, files, top)

    style = check_style.check_ip(ip, files, data.get("resets"))
    lines = [f"%Error-STYLE: {f}:{ln}: [{rule}] {msg}" for f, ln, rule, msg in style] + findings
    out = "\n".join(lines)
    errors += len(style)
    result = "FAIL" if errors else ("WARN" if warnings else "PASS")

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
    print(f"\nlint {result}: {errors} error(s) ({len(style)} style), {warnings} warning(s) -> {LOG.as_posix()}")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
