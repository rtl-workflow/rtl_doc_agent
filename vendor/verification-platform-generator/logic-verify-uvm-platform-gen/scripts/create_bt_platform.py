#!/usr/bin/env python3
"""Create a fresh legacy scaffold. Does not integrate components or run EDA.

Local filesystem checks prevent accidental traversal/overwrite, not hostile
same-account races. Use an isolated output root for untrusted concurrent jobs.
"""
import argparse
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile

PROFILES = {"1": ("superbench_demo", "legacy_superbench"),
            "2": ("gaea_demo", "legacy_gaea")}


def is_valid_c_variable(name):
    return (isinstance(name, str) and
            re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name) is not None and
            name.upper() not in {"CON", "PRN", "AUX", "NUL", "CLOCK$",
                                 *(f"COM{i}" for i in range(10)),
                                 *(f"LPT{i}" for i in range(10))})


def _no_links(path):
    """Reject symlinks and Windows reparse points, including ancestors."""
    path = Path(os.path.abspath(path))
    for item in (path, *path.parents):
        try:
            info = item.lstat()
        except FileNotFoundError:
            continue
        if stat.S_ISLNK(info.st_mode) or getattr(info, "st_file_attributes", 0) & 0x400:
            raise ValueError(f"links/reparse points are not allowed: {item}")
    return path


def _inside(root, path):
    root, path = root.resolve(), path.resolve()
    if path == root or root not in path.parents:
        raise ValueError(f"path must be strictly inside output root: {path}")
    return path


def _source_tree(source):
    source = _no_links(source)
    if not source.is_dir():
        raise ValueError(f"template directory does not exist: {source}")
    files = []
    for parent, dirs, names in os.walk(source, followlinks=False):
        for name in dirs + names:
            path = _no_links(Path(parent) / name)
            if not path.is_dir():
                if not stat.S_ISREG(path.stat().st_mode):
                    raise ValueError(f"template contains a special file: {path}")
                files.append(path)
    if not files:
        raise ValueError("template contains no files")
    return source


def copy_and_rename(src, dst):
    """Copy to a NEW destination; never remove or merge an existing path."""
    source = _source_tree(src)
    destination = _no_links(dst)
    if os.path.lexists(destination):
        raise FileExistsError(f"refusing existing destination: {destination}")
    if destination == source or source in destination.parents:
        raise ValueError("destination cannot be inside template")
    # copytree reserves the destination with exist_ok=False. Preserve bytes;
    # no broad line-ending transformation of binary/cache files.
    shutil.copytree(source, destination)
    return destination


def sync_directories(dir_a, dir_b):
    """Compatibility wrapper; destructive synchronization is no longer allowed."""
    return copy_and_rename(dir_b, dir_a)


def create_platform(template_dir, output_root, bt_index, p_name=None):
    index = str(bt_index)
    if index not in PROFILES:
        raise ValueError("bt_index must be 1 or 2")
    demo, profile = PROFILES[index]
    name = demo if p_name is None else p_name
    if not is_valid_c_variable(name):
        raise ValueError("p_name must be a non-reserved ASCII identifier")
    source = _source_tree(Path(template_dir) / demo / demo)
    root = _no_links(output_root)
    if root == source or source in root.parents:
        raise ValueError("output_root cannot be inside template")
    root.mkdir(parents=True, exist_ok=True)
    root = _no_links(root).resolve()
    bucket = _no_links(root / "BT_PLATFORM")
    _inside(root, bucket)
    bucket.mkdir(exist_ok=True)
    # Atomic unique allocation, including concurrent requests in the same second.
    run_dir = Path(tempfile.mkdtemp(
        prefix=datetime.now().strftime("%Y-%m-%d_%H-%M-%S_"), dir=bucket))
    _inside(root, _no_links(run_dir))
    destination = _inside(run_dir, _no_links(run_dir / name))
    copy_and_rename(source, destination)
    artifacts = [{"path": p.relative_to(destination).as_posix(),
                  "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
                 for p in sorted(destination.rglob("*")) if p.is_file()]
    # Failure leaves the new attempt for diagnosis; never delete earlier output.
    return {"schema_version": "bt-platform-result/v1", "status": "scaffold_created",
            "platform_path": str(destination), "framework_profile": profile,
            "uvm_compatibility": "unverified_legacy", "compile_status": "not_run",
            "simulation_status": "not_run", "artifacts": artifacts, "errors": []}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template_dir", required=True)
    parser.add_argument("--output_root", required=True)
    parser.add_argument("--bt_index", required=True, choices=("1", "2"))
    parser.add_argument("--p_name")
    args = parser.parse_args(argv)
    try:
        result = create_platform(args.template_dir, args.output_root, args.bt_index, args.p_name)
    except (OSError, ValueError, shutil.Error) as exc:
        result = {"schema_version": "bt-platform-result/v1", "status": "failed",
                  "platform_path": None, "framework_profile": PROFILES[args.bt_index][1],
                  "uvm_compatibility": "unverified_legacy", "compile_status": "not_run",
                  "simulation_status": "not_run", "artifacts": [], "errors": [str(exc)]}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["status"] == "scaffold_created" else 1


if __name__ == "__main__":
    sys.exit(main())
