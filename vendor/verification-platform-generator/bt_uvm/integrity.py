"""Measure source files independently of declarative platform JSON."""
import hashlib
from pathlib import Path


def verify_sources(project: Path, design: Path, platform: dict, contract: dict) -> dict:
    errors = []
    project = project.resolve()
    design = design.resolve()
    if not project.is_dir() or project not in design.parents or not design.is_file():
        return {"status": "fail", "errors": ["design must be a file inside project"]}
    digest = hashlib.sha256(design.read_bytes()).hexdigest()
    if digest != contract.get("design_sha256") or digest != platform.get("design_sha256"):
        errors.append("design source digest mismatch")
    for row in platform.get("components", []):
        if not isinstance(row, dict):
            errors.append("invalid component")
            continue
        name = row.get("path")
        if not isinstance(name, str) or not name or Path(name).is_absolute():
            errors.append("invalid source path")
            continue
        file = project / name
        if project not in file.resolve().parents or file.is_symlink() or not file.is_file():
            errors.append(f"unsafe or missing source: {name}")
        elif hashlib.sha256(file.read_bytes()).hexdigest() != row.get("source_sha256"):
            errors.append(f"source digest mismatch: {name}")
    return {"status": "fail" if errors else "pass", "errors": errors}
