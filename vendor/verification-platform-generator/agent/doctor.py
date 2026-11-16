"""Read-only asset catalog validation. Never imports or executes child skills."""
import argparse
import json
from pathlib import Path

SCHEMA = "verification-agent-registry/v1"
KINDS = {"agent_procedure", "subskill", "python_cli", "contract"}
STATUSES = {"documented", "agent_assisted", "templates_and_helpers",
            "opt_in_agent_assisted", "implemented_local", "not_implemented"}


def check(root):
    root = Path(root).resolve()
    errors = []

    def asset(value, label):
        if not isinstance(value, str) or not value or "\\" in value:
            errors.append(f"{label}: expected nonempty relative POSIX path")
            return
        path = Path(value)
        if path.is_absolute() or ".." in path.parts or ":" in value:
            errors.append(f"{label}: escaping or absolute path")
            return
        resolved = (root / path).resolve()
        if root not in resolved.parents or not resolved.is_file():
            errors.append(f"{label}: missing file or escaping link: {value}")

    try:
        registry = json.loads((root / "agent" / "registry.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        return {"status": "fail", "scope": "asset_catalog", "errors": [str(exc)]}
    if not isinstance(registry, dict):
        return {"status": "fail", "scope": "asset_catalog", "errors": ["registry must be an object"]}
    if registry.get("schema_version") != SCHEMA:
        errors.append("unsupported schema_version")
    if registry.get("execution_model") != "host_agent_assisted":
        errors.append("execution_model must be host_agent_assisted")
    asset(registry.get("entrypoint"), "entrypoint")
    rows = registry.get("capabilities")
    if not isinstance(rows, list) or not rows:
        errors.append("capabilities must be a nonempty list")
        rows = []
    ids = set()
    graph = {}
    for index, row in enumerate(rows):
        label = f"capabilities[{index}]"
        if not isinstance(row, dict):
            errors.append(f"{label}: expected object")
            continue
        ident = row.get("id")
        if not isinstance(ident, str) or not ident or ident in ids:
            errors.append(f"{label}: missing or duplicate id")
            continue
        ids.add(ident)
        asset(row.get("entrypoint"), ident)
        if row.get("kind") not in KINDS or row.get("status") not in STATUSES:
            errors.append(f"{ident}: invalid kind/status")
        deps = row.get("depends_on")
        if not isinstance(deps, list) or any(not isinstance(d, str) for d in deps):
            errors.append(f"{ident}: depends_on must be string list")
            deps = []
        elif len(set(deps)) != len(deps):
            errors.append(f"{ident}: duplicate dependency")
        graph[ident] = deps
    active, visited = set(), set()

    def visit(ident):
        if ident in active:
            errors.append(f"dependency cycle at {ident}")
            return
        if ident in visited:
            return
        active.add(ident)
        for dep in graph.get(ident, []):
            if dep not in graph:
                errors.append(f"{ident}: unknown dependency {dep}")
            else:
                visit(dep)
        active.remove(ident)
        visited.add(ident)

    for ident in graph:
        visit(ident)
    docs = registry.get("required_documents")
    if not isinstance(docs, list) or not docs:
        errors.append("required_documents must be a nonempty list")
    else:
        for item in docs:
            asset(item, "required_documents")
    return {"status": "fail" if errors else "pass", "scope": "asset_catalog",
            "capabilities_checked": len(ids), "errors": errors,
            "execution_readiness": "not_assessed",
            "notice": "No child scripts, tools, SSH connections or UVM simulations were executed."}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args(argv)
    result = check(args.root)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
