"""Independent execution evidence and fail-closed BT UVM run verdicts.

Only the runner may create run records. This is a tamper-detection boundary, not
an OS sandbox: execute untrusted commands in a separately permissioned worker.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
from datetime import datetime, timezone
from uuid import uuid4

SCHEMA = "bt-uvm-run/v1"
RESULT = "bt-uvm-verdict/v1"
KINDS = {"data", "reject", "reset"}
METRICS = ("stimulus", "accepted", "executed", "returned", "expected", "actual", "compared", "rejected", "cancelled", "outstanding", "mismatch", "coverage_samples")
METRIC_RE = re.compile(r"^BT_METRIC\s+([a-z_]+)=([0-9]+)\s*$")
PASS_RE = re.compile(r"^BT_TEST_PASS\s+([A-Za-z_][\w.:-]*)\s*$")
FAIL_RE = re.compile(r"\b(?:UVM_FATAL|UVM_ERROR|SCOREBOARD_MISMATCH|ASSERT(?:ION)?[_ ]FAIL(?:ED|URE)?|BT_TEST_FAIL)\b", re.I)
SUMMARY_RE = re.compile(r"^\s*UVM_(?:FATAL|ERROR)\s*:\s*0\s*$")


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _inside(root: Path, item: Path) -> bool:
    return item == root or root in item.parents


def _files(root: Path, paths: list[str]) -> dict[str, str]:
    """Expand explicit paths; symlinks and paths escaping root are rejected."""
    result = {}
    for name in paths:
        p = root / name
        if p.is_symlink() or not _inside(root, p.resolve()):
            raise ValueError(f"read-only path escapes project: {name}")
        if not p.exists():
            raise ValueError(f"missing read-only path: {name}")
        candidates = [p] if p.is_file() else sorted(p.rglob("*"))
        for file in candidates:
            if file.is_symlink() or not _inside(root, file.resolve()):
                raise ValueError(f"read-only path escapes project: {file}")
            if file.is_file():
                result[file.relative_to(root).as_posix()] = _sha(file)
    return result


def snapshot(root: Path, read_only: list[str]) -> dict[str, str]:
    root = root.resolve()
    if not root.is_dir() or not read_only:
        raise ValueError("project and nonempty read_only paths required")
    result = _files(root, read_only)
    if not result:
        raise ValueError("read_only paths contain no files")
    return result


def plan_hash(plan: dict) -> str:
    return hashlib.sha256(json.dumps(plan, ensure_ascii=False, sort_keys=True,
                                     separators=(",", ":")).encode("utf-8")).hexdigest()


def _persist(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def run(project: Path, runs_dir: Path, read_only: list[str], command: list[str],
        test: str, seed: int, kind: str, dut: str, timeout: int = 120,
        compile_command: list[str] | None = None, plan: dict | None = None) -> Path:
    """Capture one command; read-only mutation is detected after execution."""
    project = project.resolve()
    runs_dir = runs_dir.resolve()
    if not command or not compile_command or not test or kind not in KINDS or dut not in ("real", "model"):
        raise ValueError("compile_command, command, test, kind and real/model DUT are required")
    if not isinstance(seed, int) or isinstance(seed, bool) or seed < 0 or timeout < 1:
        raise ValueError("seed must be nonnegative and timeout positive")
    if not isinstance(plan, dict) or not isinstance(plan.get("tests"), list):
        raise ValueError("approved plan with tests required")
    matches = [item for item in plan["tests"] if isinstance(item, dict)
               and item.get("name") == test and item.get("kind") == kind
               and seed in item.get("seeds", [])]
    if len(matches) != 1:
        raise ValueError("test/seed/kind must occur exactly once in approved plan")
    before = snapshot(project, read_only)
    if _inside(project, runs_dir) and any(_inside(project / name, runs_dir) for name in read_only):
        raise ValueError("runs_dir overlaps read-only paths")
    runs_dir.mkdir(parents=True, exist_ok=True)
    run_dir = runs_dir / (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ-") + uuid4().hex)
    run_dir.mkdir(exist_ok=False)
    started = datetime.now(timezone.utc).isoformat()
    timeout_hit = False
    returncode = None
    compile_returncode = None
    with (run_dir / "compile.log").open("wb") as out, (run_dir / "compile.err").open("wb") as err:
        try:
            completed = subprocess.run(compile_command, cwd=project, stdout=out, stderr=err,
                                       timeout=timeout, shell=False, check=False)
            compile_returncode = completed.returncode
        except subprocess.TimeoutExpired:
            timeout_hit = True
        except OSError as exc:
            err.write(f"execution_error: {exc}\n".encode("utf-8", errors="replace"))
    with (run_dir / "stdout.log").open("wb") as out, (run_dir / "stderr.log").open("wb") as err:
        if compile_returncode == 0 and not timeout_hit:
            try:
                completed = subprocess.run(command, cwd=project, stdout=out, stderr=err,
                                           timeout=timeout, shell=False, check=False)
                returncode = completed.returncode
            except subprocess.TimeoutExpired:
                timeout_hit = True
            except OSError as exc:
                err.write(f"execution_error: {exc}\n".encode("utf-8", errors="replace"))
    try:
        after = _files(project, read_only)
        modified = sorted({*before, *after} - {k for k in before.keys() & after.keys() if before[k] == after[k]})
    except ValueError as exc:
        modified = [str(exc)]
    record = {
        "schema": SCHEMA, "run_id": run_dir.name, "project": str(project),
        "plan_sha256": plan_hash(plan),
        "test": test, "seed": seed, "kind": kind, "dut": dut,
        "command": command, "compile_command": compile_command,
        "compile_returncode": compile_returncode, "started_utc": started,
        "finished_utc": datetime.now(timezone.utc).isoformat(),
        "returncode": returncode, "timeout": timeout_hit,
        "read_only_before": before, "read_only_changed": modified,
        "logs": {name: _sha(run_dir / name) for name in ("compile.log", "compile.err", "stdout.log", "stderr.log")},
    }
    _persist(run_dir / "run.json", record)
    return run_dir


def evaluate(run_dir: Path, expected_test: str | None = None,
             expected_seed: int | None = None) -> dict:
    """Read-only evaluation. Never trust an existing verdict or a bare PASS line."""
    run_dir = run_dir.resolve()
    errors: list[str] = []
    try:
        record = json.loads((run_dir / "run.json").read_text(encoding="utf-8"))
        if not isinstance(record, dict) or record.get("schema") != SCHEMA:
            raise ValueError("invalid run schema")
    except (OSError, ValueError, TypeError) as exc:
        return {"schema": RESULT, "status": "fail", "errors": [f"run record unavailable: {exc}"]}
    required = ("run_id", "plan_sha256", "test", "seed", "kind", "dut", "command", "compile_command", "compile_returncode", "returncode", "logs", "read_only_before", "read_only_changed")
    errors.extend(f"missing {field}" for field in required if field not in record)
    if record.get("run_id") != run_dir.name:
        errors.append("run identity mismatch")
    if record.get("dut") != "real":
        errors.append("not a real DUT run")
    if record.get("compile_returncode") != 0 or not record.get("compile_command"):
        errors.append("compile failed or missing")
    if record.get("returncode") != 0 or record.get("timeout"):
        errors.append("command failed or timed out")
    if record.get("read_only_changed"):
        errors.append("read-only baseline changed")
    if expected_test is not None and record.get("test") != expected_test:
        errors.append("test identity mismatch")
    if expected_seed is not None and record.get("seed") != expected_seed:
        errors.append("seed identity mismatch")
    try:
        baseline = record["read_only_before"]
        root = Path(record["project"]).resolve()
        if not isinstance(baseline, dict) or not baseline:
            raise ValueError("empty baseline")
        if any(not _inside(root, (root / key).resolve()) or (root / key).is_symlink() for key in baseline):
            raise ValueError("unsafe baseline path")
        if any(not (root / key).is_file() or _sha(root / key) != digest for key, digest in baseline.items()):
            errors.append("read-only baseline no longer matches")
    except (OSError, KeyError, TypeError, ValueError) as exc:
        errors.append(f"invalid baseline: {exc}")
    logs = {}
    for name in ("compile.log", "compile.err", "stdout.log", "stderr.log"):
        try:
            path = run_dir / name
            if _sha(path) != record["logs"][name]:
                errors.append(f"{name} hash mismatch")
            logs[name] = path.read_text(encoding="utf-8", errors="replace")
        except (OSError, KeyError, TypeError) as exc:
            errors.append(f"missing {name}: {exc}")
    compile_text = "\n".join(logs.get(name, "") for name in ("compile.log", "compile.err"))
    text = "\n".join(logs.get(name, "") for name in ("stdout.log", "stderr.log"))
    if not compile_text.strip():
        errors.append("empty compile log")
    if not text.strip():
        errors.append("empty simulation log")
    if any(FAIL_RE.search(line) for line in (compile_text + "\n" + text).splitlines()
           if not SUMMARY_RE.fullmatch(line)):
        errors.append("UVM/assertion/scoreboard failure marker")
    markers = [m.group(1) for line in text.splitlines() if (m := PASS_RE.fullmatch(line.strip()))]
    if markers != [record.get("test")]:
        errors.append("missing or inconsistent BT_TEST_PASS marker")
    metrics = {}
    for line in text.splitlines():
        match = METRIC_RE.fullmatch(line.strip())
        if match:
            key, value = match.groups()
            if key not in METRICS or key in metrics:
                errors.append(f"invalid or duplicate metric: {key}")
            else:
                metrics[key] = int(value)
    errors.extend(f"missing metric: {key}" for key in METRICS if key not in metrics)
    kind = record.get("kind")
    if kind not in KINDS:
        errors.append("unknown test kind")
    if metrics:
        for key in ("stimulus", "accepted", "coverage_samples"):
            if metrics.get(key, 0) < 1:
                errors.append(f"zero activity: {key}")
        for key in ("mismatch", "outstanding"):
            if metrics.get(key, 1) != 0:
                errors.append(f"nonzero {key}")
        if metrics.get("expected") != metrics.get("compared") or metrics.get("actual") != metrics.get("compared"):
            if kind == "data":
                errors.append("data comparison counts disagree")
        if kind == "data" and (metrics.get("compared", 0) < 1 or metrics.get("executed", 0) < 1):
            errors.append("data test lacks executed operations/comparisons")
        if kind == "reject" and (metrics.get("rejected", 0) < 1 or metrics.get("executed", -1) != 0):
            errors.append("reject test lacks rejection or has execution")
        if kind == "reset" and metrics.get("cancelled", 0) < 1:
            errors.append("reset test lacks cancellation")
        if metrics.get("accepted", -1) != metrics.get("returned", 0) + metrics.get("cancelled", 0) + metrics.get("rejected", 0):
            errors.append("transaction conservation failed")
    return {"schema": RESULT, "run_id": record.get("run_id"), "test": record.get("test"),
            "seed": record.get("seed"), "plan_sha256": record.get("plan_sha256"),
            "dut": record.get("dut"), "kind": kind,
            "status": "fail" if errors else "pass", "metrics": metrics, "errors": errors}
