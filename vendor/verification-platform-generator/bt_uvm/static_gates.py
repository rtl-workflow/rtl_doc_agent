"""Read-only structural gates for decoded JSON verification artifacts.

These functions validate declarations against an explicit, independently supplied
contract or approved plan. A pass is not a source-code, compile, or run verdict.
"""

import re
from collections.abc import Mapping


_DIGEST = re.compile(r"[0-9a-fA-F]{64}\Z")


def _error(errors, path, code, message):
    errors.append({"path": path, "code": code, "message": message})


def _object(value, path, errors):
    if not isinstance(value, Mapping):
        _error(errors, path, "type", "expected a JSON object")
        return {}
    return value


def _list(value, path, errors, *, nonempty=True):
    if not isinstance(value, list) or (nonempty and not value):
        _error(errors, path, "type", "expected a non-empty JSON array" if nonempty else "expected a JSON array")
        return []
    return value


def _text(value, path, errors):
    if not isinstance(value, str) or not value.strip():
        _error(errors, path, "required", "expected non-empty text")
        return ""
    return value.strip()


def _fields(item, fields, path, errors):
    for field in fields:
        _text(item.get(field), path + "." + field, errors)


def _ids(value, path, errors):
    items = _list(value, path, errors)
    result = []
    for i, entry in enumerate(items):
        result.append(_text(entry, f"{path}[{i}]", errors))
    if len(result) != len(set(result)):
        _error(errors, path, "duplicate", "duplicate identifiers")
    return set(result) - {""}


def _records(value, path, key, errors):
    entries = _list(value, path, errors)
    found = {}
    for i, raw in enumerate(entries):
        entry = _object(raw, f"{path}[{i}]", errors)
        ident = _text(entry.get(key), f"{path}[{i}].{key}", errors)
        if ident in found and ident:
            _error(errors, f"{path}[{i}].{key}", "duplicate", "duplicate identifier")
        elif ident:
            found[ident] = entry
    return found


def _equal_sets(actual, expected, path, errors):
    for missing in sorted(expected - actual):
        _error(errors, path, "missing", f"missing declared item {missing!r}")
    for extra in sorted(actual - expected):
        _error(errors, path, "unexpected", f"unapproved item {extra!r}")


def _match_records(actual, expected, fields, path, errors):
    _equal_sets(set(actual), set(expected), path, errors)
    for key in sorted(set(actual) & set(expected)):
        for field in fields:
            val = _text(actual[key].get(field), f"{path}.{key}.{field}", errors)
            target = _text(expected[key].get(field), f"contract.{path}.{key}.{field}", errors)
            if val and target and val != target:
                _error(errors, f"{path}.{key}.{field}", "mismatch", "does not match approved contract")


def _result(errors):
    return {"status": "fail" if errors else "pass", "errors": errors}


def _contract(contract, errors):
    return _object(contract, "contract", errors)


def _interfaces(value, path, errors):
    records = _records(value, path, "name", errors)
    for name, row in records.items():
        _fields(row, ("direction",), f"{path}.{name}", errors)
        if row.get("direction") not in ("input", "output", "inout"):
            _error(errors, f"{path}.{name}.direction", "invalid", "direction must be input, output or inout")
    return records


def _components(value, path, errors):
    records = _records(value, path, "id", errors)
    for ident, row in records.items():
        _fields(row, ("kind", "path"), f"{path}.{ident}", errors)
        p = row.get("path")
        if isinstance(p, str) and (p.startswith(("/", "\\")) or re.match(r"^[A-Za-z]:", p) or
                                   ".." in p.replace("\\", "/").split("/")):
            _error(errors, f"{path}.{ident}.path", "unsafe_path", "component path must stay relative to project root")
    return records


def validate_design(design, *, contract):
    """Validate design JSON against approved requirements/interfaces/components.

    Design fields: dut{name,top}, requirements[{id,source,status}],
    interfaces[{name,direction,driver,observer}], components[{id,kind,path}],
    trace[{requirement_id,stimulus,expected,observed,checker,coverage,tests}].
    Contract fields: requirements[id,...], interfaces[{name,direction}],
    components[{id,kind,path}], dut{name,top}. All lists are nonempty.
    """
    errors = []
    design = _object(design, "design", errors)
    contract = _contract(contract, errors)
    dut = _object(design.get("dut"), "design.dut", errors)
    approved_dut = _object(contract.get("dut"), "contract.dut", errors)
    for field in ("name", "top"):
        actual = _text(dut.get(field), "design.dut." + field, errors)
        approved = _text(approved_dut.get(field), "contract.dut." + field, errors)
        if actual and approved and actual != approved:
            _error(errors, "design.dut." + field, "mismatch", "DUT identity differs from approved contract")
    approved_req = _ids(contract.get("requirements"), "contract.requirements", errors)
    requirements = _records(design.get("requirements"), "design.requirements", "id", errors)
    _equal_sets(set(requirements), approved_req, "design.requirements", errors)
    for ident, req in requirements.items():
        _fields(req, ("source", "status"), f"design.requirements.{ident}", errors)
        if req.get("status") != "confirmed":
            _error(errors, f"design.requirements.{ident}.status", "unconfirmed", "requirement must be confirmed")
    interfaces = _interfaces(design.get("interfaces"), "design.interfaces", errors)
    approved_interfaces = _interfaces(contract.get("interfaces"), "contract.interfaces", errors)
    _match_records(interfaces, approved_interfaces, ("direction",), "interfaces", errors)
    for name, row in interfaces.items():
        _fields(row, ("driver", "observer"), f"design.interfaces.{name}", errors)
    components = _components(design.get("components"), "design.components", errors)
    approved_components = _components(contract.get("components"), "contract.components", errors)
    _match_records(components, approved_components, ("kind", "path"), "components", errors)
    trace = _records(design.get("trace"), "design.trace", "requirement_id", errors)
    _equal_sets(set(trace), approved_req, "design.trace", errors)
    for ident, row in trace.items():
        _fields(row, ("stimulus", "expected", "observed", "checker", "coverage"), f"design.trace.{ident}", errors)
        _ids(row.get("tests"), f"design.trace.{ident}.tests", errors)
    return _result(errors)


def validate_ir(ir, *, contract):
    """Validate IR JSON and feature trace against the approved design contract.

    IR: dut{name,top}, interfaces[{name,direction}], sources{requirements,rtl},
    features[{id,requirement_ids,description,stimulus,expected,observability,
              coverage_item,priority,tests}]. Contract additionally needs features[id].
    """
    errors = []
    ir = _object(ir, "ir", errors)
    contract = _contract(contract, errors)
    dut = _object(ir.get("dut"), "ir.dut", errors)
    approved = _object(contract.get("dut"), "contract.dut", errors)
    for field in ("name", "top"):
        a = _text(dut.get(field), "ir.dut." + field, errors)
        b = _text(approved.get(field), "contract.dut." + field, errors)
        if a and b and a != b:
            _error(errors, "ir.dut." + field, "mismatch", "DUT identity differs from approved contract")
    req = _ids(contract.get("requirements"), "contract.requirements", errors)
    interfaces = _interfaces(ir.get("interfaces"), "ir.interfaces", errors)
    approved_interfaces = _interfaces(contract.get("interfaces"), "contract.interfaces", errors)
    _match_records(interfaces, approved_interfaces, ("direction",), "interfaces", errors)
    sources = _object(ir.get("sources"), "ir.sources", errors)
    _ids(sources.get("requirements"), "ir.sources.requirements", errors)
    _ids(sources.get("rtl"), "ir.sources.rtl", errors)
    features = _records(ir.get("features"), "ir.features", "id", errors)
    approved_features = _ids(contract.get("features"), "contract.features", errors)
    _equal_sets(set(features), approved_features, "ir.features", errors)
    seen = set()
    for ident, feature in features.items():
        _fields(feature, ("description", "stimulus", "expected", "observability", "coverage_item", "priority"), f"ir.features.{ident}", errors)
        linked = _ids(feature.get("requirement_ids"), f"ir.features.{ident}.requirement_ids", errors)
        _equal_sets(linked & req, linked, f"ir.features.{ident}.requirement_ids", errors)
        seen.update(linked)
        _ids(feature.get("tests"), f"ir.features.{ident}.tests", errors)
    _equal_sets(seen & req, req, "ir.features.requirement_ids", errors)
    return _result(errors)


def _digest(value, path, errors):
    if not isinstance(value, str) or not _DIGEST.fullmatch(value):
        _error(errors, path, "digest", "expected a SHA-256 hex digest")
        return ""
    return value.lower()


def _connections(value, path, errors):
    rows = _list(value, path, errors, nonempty=False)
    links = set()
    for i, raw in enumerate(rows):
        row = _object(raw, f"{path}[{i}]", errors)
        link = tuple(_text(row.get(k), f"{path}[{i}].{k}", errors) for k in ("from", "to", "role"))
        if link in links:
            _error(errors, f"{path}[{i}]", "duplicate", "duplicate connection")
        links.add(link)
    return links


def validate_platform(platform, *, contract):
    """Validate declared platform components and connections, not SV wiring.

    Contract: design_sha256, components[{id,kind,path}], connections[{from,to,role}].
    Platform: design_sha256, components[{id,kind,path,source_sha256}], connections.
    Hashes in platform are declarations, not independently measured file hashes.
    """
    errors = []
    platform = _object(platform, "platform", errors)
    contract = _contract(contract, errors)
    a = _digest(platform.get("design_sha256"), "platform.design_sha256", errors)
    b = _digest(contract.get("design_sha256"), "contract.design_sha256", errors)
    if a and b and a != b:
        _error(errors, "platform.design_sha256", "stale", "approved design digest differs")
    actual = _components(platform.get("components"), "platform.components", errors)
    expected = _components(contract.get("components"), "contract.components", errors)
    _match_records(actual, expected, ("kind", "path"), "components", errors)
    for ident, row in actual.items():
        digest = _digest(row.get("source_sha256"), f"platform.components.{ident}.source_sha256", errors)
        if ident in expected and "source_sha256" in expected[ident]:
            approved = _digest(expected[ident]["source_sha256"], f"contract.components.{ident}.source_sha256", errors)
            if digest and approved and digest != approved:
                _error(errors, f"platform.components.{ident}.source_sha256", "mismatch", "source digest differs from approved contract")
    links = _connections(platform.get("connections"), "platform.connections", errors)
    approved_links = _connections(contract.get("connections"), "contract.connections", errors)
    _equal_sets(links, approved_links, "platform.connections", errors)
    for source, target, _ in links:
        if source not in actual or target not in actual:
            _error(errors, "platform.connections", "unknown_component", "connection endpoint has no declared component")
    return _result(errors)


def _seeds(value, path, errors):
    items = _list(value, path, errors)
    result = set()
    for i, seed in enumerate(items):
        if type(seed) is not int or seed < 0:
            _error(errors, f"{path}[{i}]", "invalid_seed", "seed must be a nonnegative integer")
        elif seed in result:
            _error(errors, f"{path}[{i}]", "duplicate", "duplicate seed")
        else:
            result.add(seed)
    return result


def validate_manifest(manifest, *, plan):
    """Check every planned test/feature/seed against an approved JSON plan.

    Both contain tests[{name,type,kind,source_id,features,seeds}]. Plan also requires
    features[id]. Manifest entries additionally require preconditions,
    stimulus, expected, monitor, checker, coverage and run_command.
    No test name is special; coverage is exact, including sanity-type tests.
    """
    errors = []
    manifest = _object(manifest, "manifest", errors)
    plan = _object(plan, "plan", errors)
    approved_features = _ids(plan.get("features"), "plan.features", errors)
    planned = _records(plan.get("tests"), "plan.tests", "name", errors)
    actual = _records(manifest.get("tests"), "manifest.tests", "name", errors)
    _equal_sets(set(actual), set(planned), "manifest.tests", errors)
    used = set()
    for name, entry in planned.items():
        _text(entry.get("type"), f"plan.tests.{name}.type", errors)
        approved_kind = _text(entry.get("kind"), f"plan.tests.{name}.kind", errors)
        if approved_kind and approved_kind not in ("data", "reject", "reset"):
            _error(errors, f"plan.tests.{name}.kind", "invalid", "kind must be data, reject or reset")
        approved_source = _text(entry.get("source_id"), f"plan.tests.{name}.source_id", errors)
        features = _ids(entry.get("features"), f"plan.tests.{name}.features", errors)
        _equal_sets(features & approved_features, features, f"plan.tests.{name}.features", errors)
        used.update(features)
        seeds = _seeds(entry.get("seeds"), f"plan.tests.{name}.seeds", errors)
        if name not in actual:
            continue
        row = actual[name]
        kind = _text(row.get("type"), f"manifest.tests.{name}.type", errors)
        if kind and kind != entry.get("type"):
            _error(errors, f"manifest.tests.{name}.type", "mismatch", "test type differs from plan")
        runtime_kind = _text(row.get("kind"), f"manifest.tests.{name}.kind", errors)
        if runtime_kind and runtime_kind != approved_kind:
            _error(errors, f"manifest.tests.{name}.kind", "mismatch", "runtime kind differs from plan")
        _fields(row, ("source_id", "preconditions", "stimulus", "expected", "monitor", "checker", "coverage", "run_command"), f"manifest.tests.{name}", errors)
        if approved_source and row.get("source_id") != approved_source:
            _error(errors, f"manifest.tests.{name}.source_id", "mismatch", "test source differs from approved plan")
        mapped = _ids(row.get("features"), f"manifest.tests.{name}.features", errors)
        _equal_sets(mapped, features, f"manifest.tests.{name}.features", errors)
        _equal_sets(_seeds(row.get("seeds"), f"manifest.tests.{name}.seeds", errors), seeds, f"manifest.tests.{name}.seeds", errors)
    _equal_sets(used, approved_features, "plan.features", errors)
    return _result(errors)
