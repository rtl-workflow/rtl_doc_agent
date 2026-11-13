"""UVM platform manifest, ordered filelists and simulation result contract.

All project verification dependencies stay inside dv/ (outside build/). RTL is
supplied separately by the runner, so a stub build never needs the DUT sources.
"""
from dataclasses import dataclass, field
from pathlib import Path, PureWindowsPath
import re
import shlex

import yaml

MANIFEST = Path("dv/uvm.yaml")
IDENT = r"[A-Za-z_][A-Za-z0-9_]*"
RESULT = re.compile(r"^TEST (\S+) SEED (\d+) (PASSED|FAILED) errors=(\d+)\s*$", re.M)


def enabled(ip):
    return (ip / MANIFEST).exists()


def local_path(ip, value, directory=False):
    if not isinstance(value, str) or not value or Path(value).is_absolute() or PureWindowsPath(value).is_absolute():
        raise ValueError(f"UVM path must be relative to dv/: {value!r}")
    root = (ip / "dv").resolve()
    path = root / value
    resolved = path.resolve()
    try:
        rel = resolved.relative_to(root)
    except ValueError:
        raise ValueError(f"UVM dependency escapes dv/: {value}") from None
    if not rel.parts or {"build", "__pycache__"}.intersection(rel.parts):
        raise ValueError(f"UVM dependency must be a source path outside build/: {value}")
    if not (path.is_dir() if directory else path.is_file()):
        raise ValueError(f"UVM {'directory' if directory else 'file'} missing: dv/{value}")
    return path


@dataclass
class Platform:
    top: str
    version: str
    test_map: dict = field(default_factory=dict)
    sources: list = field(default_factory=list)
    incdirs: list = field(default_factory=list)
    defines: list = field(default_factory=list)
    dependencies: list = field(default_factory=list)

    def test_class(self, test):
        return self.test_map.get(test, test)

    def compile_args(self):
        return (["-sverilog", "-ntb_opts", self.version]
                + ["+incdir+" + str(p.resolve()) for p in self.incdirs]
                + self.defines)

    def run_args(self, test, seed):
        return [f"+UVM_TESTNAME={self.test_class(test)}", f"+ntb_random_seed={seed}"]


def load(ip):
    """Load the manifest and resolve ordered sources, nested lists and includes."""
    ip = ip.resolve()
    manifest = local_path(ip, "uvm.yaml")
    try:
        cfg = yaml.safe_load(manifest.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        raise ValueError(f"invalid dv/uvm.yaml: {exc}") from exc
    keys = {"schema_version", "top", "uvm_version", "filelist", "test_map"}
    if not isinstance(cfg, dict) or cfg.get("schema_version") != 1 or set(cfg) - keys:
        raise ValueError("dv/uvm.yaml requires schema_version: 1 and only top, uvm_version, filelist, test_map")
    if not isinstance(cfg.get("top"), str) or not re.fullmatch(IDENT, cfg["top"]):
        raise ValueError("dv/uvm.yaml top must be a SystemVerilog identifier")
    version = cfg.get("uvm_version", "uvm-1.2")
    if version not in ("uvm-1.2", "uvm-1.1", "uvm"):
        raise ValueError("uvm_version must be a VCS built-in selector: uvm-1.2, uvm-1.1 or uvm")
    mapping = cfg.get("test_map", {})
    if not isinstance(mapping, dict) or any(not isinstance(k, str) or not re.fullmatch(IDENT, k)
            or not isinstance(v, str) or not re.fullmatch(IDENT, v) for k, v in mapping.items()):
        raise ValueError("test_map must map test identifiers to registered UVM class identifiers")
    result = Platform(cfg["top"], version, mapping, dependencies=[manifest])
    active, visited = set(), set()

    def filelist(value):
        path = local_path(ip, value)
        if path in active:
            raise ValueError(f"cyclic UVM filelist: {value}")
        if path in visited:
            return
        active.add(path)
        result.dependencies.append(path)
        for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            line = raw.strip()
            if not line or line.startswith(("#", "//")):
                continue
            try:
                words = shlex.split(line, comments=True)
            except ValueError as exc:
                raise ValueError(f"{value}:{number}: {exc}") from exc
            if not words:
                continue
            if words[0] == "-f" and len(words) == 2:
                filelist(words[1])
            elif len(words) == 1 and words[0].startswith("+incdir+"):
                for name in words[0][8:].split("+"):
                    directory = local_path(ip, name, directory=True)
                    if directory not in result.incdirs:
                        result.incdirs.append(directory)
            elif len(words) == 1 and re.fullmatch(r"\+define\+(?:[A-Za-z_]\w*(?:=[A-Za-z0-9_'().:-]+)?)(?:\+[A-Za-z_]\w*(?:=[A-Za-z0-9_'().:-]+)?)*", words[0]):
                result.defines.append(words[0])
            elif len(words) == 1 and not words[0].startswith(("-", "+")):
                source = local_path(ip, words[0])
                if source.suffix not in (".v", ".sv"):
                    raise ValueError(f"compile units must be .v/.sv; include headers from a package: {value}:{number}")
                if source in result.sources:
                    raise ValueError(f"duplicate UVM compile unit: {words[0]}")
                result.sources.append(source)
            else:
                raise ValueError(f"unsupported UVM filelist entry: {value}:{number}: {line}")
        active.remove(path)
        visited.add(path)

    filelist(cfg.get("filelist", "sim/scripts/tb_list.f"))
    if not result.sources:
        raise ValueError("UVM filelist contains no compile unit")
    seen = set()

    def includes(path):
        if path in seen:
            return
        seen.add(path)
        result.dependencies.append(path)
        content = path.read_text(encoding="utf-8")
        content = re.sub(r"/\*.*?\*/|//[^\n]*", "", content, flags=re.S)
        for name in re.findall(r'`include\s+"([^"\n]+)"', content):
            if name == "uvm_macros.svh":
                continue  # provided by the selected VCS UVM library
            candidates = [path.parent / name] + [p / name for p in result.incdirs]
            found = next((p for p in candidates if p.is_file()), None)
            if found is None:
                raise ValueError(f"missing UVM include {name!r} from {path.relative_to(ip)}")
            # Resolve and validate before opening it; includes cannot read DUT RTL.
            value = found.relative_to(ip / "dv").as_posix()
            includes(local_path(ip, value))

    for source in result.sources:
        includes(source)
    result.dependencies = sorted(set(result.dependencies))
    return result


def input_files(ip):
    """Fingerprint all verification sources/config, including newly added files."""
    files = []
    # Path ordering is case-insensitive on Windows, but not on Linux. Hash
    # inputs must use the same relative POSIX string order on both hosts.
    for path in sorted((ip / "dv").rglob("*"),
                       key=lambda p: p.relative_to(ip).as_posix()):
        rel = path.relative_to(ip / "dv")
        if {"build", "__pycache__"}.intersection(rel.parts) or not path.is_file():
            continue
        files.append(local_path(ip, rel.as_posix()))
    return files


def parse_result(text, test, seed, class_name, stub=False):
    """Never treat a UVM banner or zero exit code alone as a completed test."""
    problems = []
    token = f"{test} SEED {seed} CLASS {class_name}"
    started = re.findall(r"^RTL_FLOW_UVM_STARTED (.+)$", text, re.M)
    completed = re.findall(r"^RTL_FLOW_UVM_COMPLETED (.+)$", text, re.M)
    matches = list(RESULT.finditer(text))
    if started != [token] or completed != [token]:
        problems.append("UVM test did not start and complete exactly once with the requested test/class/seed")
    if len(matches) != 1 or matches[0].group(1) != test or int(matches[0].group(2)) != seed:
        problems.append("missing, duplicate or mismatched TEST result")
        match = None
    else:
        match = matches[0]
    if match and started == [token] and completed == [token]:
        begin = text.index("RTL_FLOW_UVM_STARTED " + token)
        end = text.index("RTL_FLOW_UVM_COMPLETED " + token)
        if not begin < end < match.start():
            problems.append("UVM lifecycle markers are out of order")
    counts = {}
    for severity in ("UVM_ERROR", "UVM_FATAL"):
        summaries = [int(n) for n in re.findall(rf"^\s*{severity}\s*:\s*(\d+)\s*$", text, re.M)]
        messages = len(re.findall(rf"^\s*{severity}\s+(?=[^\s:])", text, re.M))
        counts[severity] = max([messages] + summaries)
    if counts["UVM_FATAL"]:
        problems.append("UVM_FATAL reported")
    if counts["UVM_ERROR"] and not stub:
        problems.append("UVM_ERROR reported")
    if match and match.group(3) == "PASSED" and int(match.group(4)) != 0:
        problems.append("PASSED result has nonzero error count")
    return {"status": match.group(3) if match else "NO RESULT",
            "errors": max(int(match.group(4)), sum(counts.values())) if match else None,
            "uvm_counts": counts, "problems": problems}
