"""Build/verify a deterministic release candidate; no upload or EDA execution."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import zipfile
from .doctor import check

MANIFEST = "RELEASE-MANIFEST.json"
IGNORED_DIRS = {"__pycache__", ".git", ".venv", "venv", ".pytest_cache", "dist", "build"}
IGNORED_SUFFIXES = {".pyc", ".pyo", ".log", ".key", ".zip", ".vvp", ".fsdb", ".vcd", ".fst"}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def relative(value):
    if not isinstance(value, str) or not value or "\\" in value or ":" in value:
        raise ValueError("invalid relative path")
    p = PurePosixPath(value)
    if p.is_absolute() or ".." in p.parts or str(p) != value:
        raise ValueError("noncanonical or escaping path")
    return p


def collect(root):
    root = Path(root).resolve()
    result = check(root)
    if result["status"] != "pass":
        raise ValueError("asset doctor failed: " + str(result["errors"]))
    meta = json.loads((root / "release.json").read_text(encoding="utf-8"))
    for key in ("name", "version"):
        if not isinstance(meta.get(key), str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", meta[key]):
            raise ValueError("invalid release name/version")
    roots = meta.get("include_roots")
    if not isinstance(roots, list) or not roots:
        raise ValueError("include_roots required")
    files = {}
    for value in roots:
        relative(value)
        start = root / value
        if not start.exists():
            raise ValueError(f"missing release input: {value}")
        for path in [start, *sorted(start.rglob("*"))] if start.is_dir() else [start]:
            # Resolve every item before reading; reject links/reparse points.
            if path.is_symlink() or getattr(path.lstat(), "st_file_attributes", 0) & 0x400 or root not in path.resolve().parents:
                raise ValueError(f"escaping or linked input: {path.name}")
            if not path.is_file():
                continue
            name = path.relative_to(root).as_posix()
            if any(p in IGNORED_DIRS for p in path.relative_to(root).parts) or path.suffix in IGNORED_SUFFIXES:
                continue
            if name == MANIFEST:
                raise ValueError("reserved manifest name")
            data = path.read_bytes()
            if path.suffix == ".json":
                json.loads(data.decode("utf-8"))
            files[name] = data
    # The package must be self-contained; links may not rely on workspace history.
    for name, data in files.items():
        if not name.endswith(".md"):
            continue
        for match in re.finditer(r"\[[^\]]*\]\((?:<([^>]+)>|([^)]*))\)", data.decode("utf-8")):
            target = (match[1] or match[2]).split("#")[0]
            if not target or re.match(r"[a-zA-Z][a-zA-Z0-9+.-]*:", target):
                continue
            resolved = (root / name).parent.joinpath(target).resolve()
            if root not in resolved.parents or resolved.relative_to(root).as_posix() not in files:
                raise ValueError(f"broken/outside package link: {name} -> {target}")
    return meta, dict(sorted(files.items()))


def build(root, output_dir):
    root, output = Path(root).resolve(), Path(output_dir).resolve()
    if output == root or root in output.parents:
        raise ValueError("output must be outside source tree")
    meta, files = collect(root)
    prefix = meta["name"] + "-" + meta["version"]
    output.mkdir(parents=True, exist_ok=True)
    target = output / (prefix + ".zip")
    checksum = output / (prefix + ".zip.sha256")
    if target.exists() or checksum.exists():
        raise FileExistsError("release output exists; refusing overwrite")
    manifest = {"schema_version": "agent-release-manifest/v1", "name": meta["name"],
                "version": meta["version"], "license_status": meta["license_status"],
                "public_release_ready": meta["public_release_ready"],
                "files": [{"path": name, "bytes": len(data), "sha256": digest(data)} for name, data in files.items()]}
    entries = dict(files)
    entries[MANIFEST] = (json.dumps(manifest, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode("utf-8")
    # ZIP_STORED avoids compression-library version differences.
    with zipfile.ZipFile(target, "x", compression=zipfile.ZIP_STORED) as archive:
        for name, data in sorted(entries.items()):
            item = zipfile.ZipInfo(prefix + "/" + name, date_time=(1980, 1, 1, 0, 0, 0))
            item.create_system = 3
            item.external_attr = 0o100644 << 16
            archive.writestr(item, data)
    sha = digest(target.read_bytes())
    with checksum.open("x", encoding="utf-8") as stream:
        stream.write(sha + "  " + target.name + "\n")
    return {"status": "pass", "scope": "release_packaging", "files": len(files),
            "archive": str(target), "sha256": sha, "public_release_ready": meta["public_release_ready"]}


def verify(path):
    path = Path(path)
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError("duplicate ZIP entries")
        for name in names:
            relative(name)
        manifests = [n for n in names if n.endswith("/" + MANIFEST)]
        if len(manifests) != 1:
            raise ValueError("exactly one manifest required")
        prefix = manifests[0][:-len(MANIFEST)]
        if prefix.count("/") != 1:
            raise ValueError("unexpected package root")
        manifest = json.loads(archive.read(manifests[0]))
        if manifest.get("schema_version") != "agent-release-manifest/v1":
            raise ValueError("unsupported manifest")
        expected = {manifests[0]}
        rows = manifest.get("files")
        if not isinstance(rows, list) or not rows:
            raise ValueError("nonempty files manifest required")
        for row in rows:
            relative(row["path"])
            name = prefix + row["path"]
            if name in expected:
                raise ValueError("duplicate manifest path")
            expected.add(name)
            data = archive.read(name)
            if len(data) != row["bytes"] or digest(data) != row["sha256"]:
                raise ValueError(f"integrity mismatch: {row['path']}")
        if set(names) != expected:
            raise ValueError("unlisted ZIP entries")
    checksum = path.with_suffix(path.suffix + ".sha256")
    sha = digest(path.read_bytes())
    if checksum.exists() and checksum.read_text(encoding="utf-8").split()[0] != sha:
        raise ValueError("archive checksum mismatch")
    return {"status": "pass", "scope": "release_integrity", "files": len(rows),
            "sha256": sha, "authenticity": "not_assessed"}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--output-dir", type=Path)
    group.add_argument("--verify", type=Path)
    args = parser.parse_args(argv)
    try:
        result = verify(args.verify) if args.verify else build(args.root, args.output_dir)
    except (OSError, ValueError, KeyError, TypeError, IndexError, zipfile.BadZipFile) as exc:
        result = {"status": "fail", "errors": [str(exc)]}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
