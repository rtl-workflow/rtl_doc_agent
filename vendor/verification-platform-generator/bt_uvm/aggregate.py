"""Aggregate an approved test plan against captured, individually evaluated runs."""
from __future__ import annotations

from pathlib import Path

from .evidence import evaluate, plan_hash


def aggregate(plan: dict, runs_dir: Path) -> dict:
    errors = []
    entries = []
    if not isinstance(plan, dict) or not isinstance(plan.get("tests"), list) or not plan["tests"]:
        return {"status": "fail", "errors": ["nonempty approved tests required"], "entries": []}
    required = {}
    for i, item in enumerate(plan["tests"]):
        if not isinstance(item, dict) or not isinstance(item.get("name"), str) or not item["name"] or not isinstance(item.get("seeds"), list) or not item["seeds"]:
            errors.append(f"invalid plan.tests[{i}]")
            continue
        for seed in item["seeds"]:
            if not isinstance(seed, int) or isinstance(seed, bool) or seed < 0:
                errors.append(f"invalid seed in {item['name']}")
                continue
            key = (item["name"], seed)
            if key in required:
                errors.append(f"duplicate plan entry: {key}")
            required[key] = item
    observed = {}
    for folder in sorted(p for p in Path(runs_dir).iterdir() if p.is_dir()) if Path(runs_dir).is_dir() else []:
        path = folder / "run.json"
        if not path.is_file():
            errors.append(f"missing run record: {folder.name}")
            continue
        result = evaluate(folder)
        key = (result.get("test"), result.get("seed"))
        if key not in required:
            errors.append(f"unplanned run: {folder.name}")
        elif result.get("plan_sha256") != plan_hash(plan):
            errors.append(f"plan version mismatch: {folder.name}")
        elif key in observed:
            errors.append(f"multiple runs for {key}; review failures and reruns explicitly")
        else:
            observed[key] = result
    for (test, seed), item in required.items():
        result = observed.get((test, seed))
        if result is None:
            errors.append(f"missing run: {test} seed={seed}")
        elif result.get("kind") != item.get("kind"):
            errors.append(f"kind mismatch: {test} seed={seed}")
        elif result["status"] != "pass":
            errors.append(f"failed run: {test} seed={seed}")
        entries.append({"test": test, "seed": seed, "status": result["status"] if result else "not_run",
                        "run_id": result.get("run_id") if result else None})
    return {"status": "fail" if errors else "pass", "errors": errors, "entries": entries}
