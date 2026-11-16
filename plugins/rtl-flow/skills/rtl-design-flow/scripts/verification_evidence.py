"""Optional v1 verification evidence contract; no protocol-specific assumptions."""
import hashlib
import json
from pathlib import Path
import re
import uuid

CONFIG = Path("dv/evidence.json")
NAME = re.compile(r"[A-Za-z][A-Za-z0-9_]*\Z")
METRIC = re.compile(r"RTL_FLOW_METRIC ([A-Za-z][A-Za-z0-9_]*)=([0-9]+)\Z")
RESULT = re.compile(r"TEST (\S+) SEED ([0-9]+) (PASSED|FAILED) errors=([0-9]+)\Z")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def text_sha(path):
    """Match remote transport's CRLF normalization for portable input binding."""
    return hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()


def fingerprint(ip):
    path = ip / CONFIG
    return text_sha(path) if path.exists() else "absent"


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key: " + key)
        result[key] = value
    return result


def names(value, minimum=0):
    return (isinstance(value, list) and len(value) >= minimum
            and all(isinstance(n, str) and NAME.fullmatch(n) for n in value)
            and len(set(value)) == len(value))


def load(ip, tests):
    """Return validated config, or None for legacy projects. Reject bool integers."""
    if not (ip / CONFIG).exists():
        return None
    cfg = json.loads((ip / CONFIG).read_text(encoding="utf-8"), object_pairs_hook=unique_object)
    if (not isinstance(cfg, dict) or set(cfg) != {"schema_version", "tests"}
            or type(cfg["schema_version"]) is not int or cfg["schema_version"] != 1):
        raise ValueError("evidence requires schema_version 1 and tests")
    if not isinstance(cfg["tests"], dict) or set(cfg["tests"]) != set(tests):
        raise ValueError("evidence tests must exactly match the simulation plan")
    for test, rule in cfg["tests"].items():
        if not isinstance(test, str) or not NAME.fullmatch(test):
            raise ValueError("invalid evidence test identifier")
        if not isinstance(rule, dict) or set(rule) != {"seeds", "minimum", "zero", "equal"}:
            raise ValueError(test + ": requires seeds, minimum, zero, equal")
        seeds = rule["seeds"]
        if (not isinstance(seeds, list) or not seeds
                or any(type(s) is not int or s < 1 for s in seeds) or len(set(seeds)) != len(seeds)):
            raise ValueError(test + ": seeds must be positive unique integers")
        mins = rule["minimum"]
        if (not isinstance(mins, dict) or any(not NAME.fullmatch(n) or type(v) is not int or v < 0
                                            for n, v in mins.items())
                or mins.get("observations", 0) < 1 or mins.get("checks", 0) < 1):
            raise ValueError(test + ": minimum requires positive observations and checks")
        if (not names(rule["zero"]) or not {"mismatches", "outstanding"}.issubset(rule["zero"])
                or not isinstance(rule["equal"], list) or any(
                not names(group, 2) for group in rule["equal"])):
            raise ValueError(test + ": zero requires mismatches/outstanding; invalid zero/equal counter lists")
        if any(mins.get(n, 0) > 0 for n in rule["zero"]):
            raise ValueError(test + ": positive minimum conflicts with zero")
    return cfg


def matrix(cfg, only=None):
    return [(test, seed) for test, rule in cfg["tests"].items() if not only or test == only
            for seed in rule["seeds"]]


def parse(text, rule, test, seed, stub=False):
    """All declared metrics occur exactly once; additional metrics are errors."""
    declared = set(rule["minimum"]) | set(rule["zero"])
    for group in rule["equal"]:
        declared.update(group)
    counters, problems, results = {}, [], []
    for line in text.splitlines():
        if "RTL_FLOW_METRIC" in line and not stub:
            match = METRIC.fullmatch(line)
            if not match:
                problems.append("malformed RTL_FLOW_METRIC line")
                continue
            name, value = match.groups()
            if name in counters:
                problems.append("duplicate metric: " + name)
            if name not in declared:
                problems.append("undeclared metric: " + name)
            counters[name] = int(value)
        if line.startswith("TEST "):
            match = RESULT.fullmatch(line)
            results.append(match.groups() if match else None)
    if (len(results) != 1 or results[0] is None or results[0][0] != test
            or int(results[0][1]) != seed):
        problems.append("missing, duplicate or mismatched TEST/SEED result")
    elif not stub and (results[0][2] != "PASSED" or int(results[0][3]) != 0):
        problems.append("test did not pass with zero errors")
    if stub:
        return counters, problems
    for name in sorted(declared - set(counters)):
        problems.append("missing metric: " + name)
    for name, minimum in rule["minimum"].items():
        if name in counters and counters[name] < minimum:
            problems.append("metric below minimum: " + name)
    for name in rule["zero"]:
        if counters.get(name, 0) != 0:
            problems.append("metric must be zero: " + name)
    for group in rule["equal"]:
        if all(n in counters for n in group) and len({counters[n] for n in group}) != 1:
            problems.append("metrics differ: " + ", ".join(group))
    return counters, problems


def begin(ip, stub, partial):
    path = Path("reports/evidence") / uuid.uuid4().hex
    (ip / path).mkdir(parents=True, exist_ok=False)
    return {"schema_version": 1, "path": path.as_posix(), "metrics_enforced": not stub,
            "partial": partial, "files": {}}


def save(ip, evidence, name, content):
    path = ip / evidence["path"] / name
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("xb") as stream:
        stream.write(content)
    evidence["files"][name] = sha(path)


def verify_archive(ip, res, collected, alias):
    """Accept only hash-checked files fetched by this job, never local history."""
    record = res["evidence"]
    if not isinstance(record, dict) or not isinstance(record.get("files"), dict):
        raise ValueError("invalid evidence record")
    relative = record["path"]
    if not isinstance(relative, str) or not re.fullmatch(r"reports/evidence/[0-9a-f]{32}", relative):
        raise ValueError("invalid archive path")
    root = ip / relative
    root.resolve().relative_to(ip.resolve())

    def fetched(name):
        if not isinstance(name, str) or not re.fullmatch(r"(?:logs/)?[A-Za-z0-9_.-]+", name):
            raise ValueError("invalid archive filename")
        if collected is not None and ip.name + "/" + relative + "/" + name not in collected:
            raise ValueError("archive file not collected: " + name)
        (root / name).resolve().relative_to(root.resolve())
        return root / name

    manifest = json.loads(fetched("manifest.json").read_text(encoding="utf-8"),
                          object_pairs_hook=unique_object)
    if not isinstance(manifest, dict):
        raise ValueError("invalid archive manifest")
    hashes = manifest["sha256"]
    if manifest.get("schema_version") != 1 or not isinstance(hashes, dict) or "result.json" not in hashes:
        raise ValueError("invalid archive manifest")
    for name, expected in hashes.items():
        if sha(fetched(name)) != expected:
            raise ValueError("archive hash mismatch: " + name)
    if fetched("result.json").read_bytes() != alias.read_bytes():
        raise ValueError("archive result differs from result alias")
    for name, expected in record["files"].items():
        if hashes.get(name) != expected:
            raise ValueError("report file hash differs from manifest: " + name)


def archive_result(ip, res, text):
    evidence = res.get("evidence")
    if not evidence:
        return
    root = ip / evidence["path"]
    with (root / "result.json").open("x", encoding="utf-8") as stream:
        stream.write(text)
    manifest = dict(evidence["files"], **{"result.json": sha(root / "result.json")})
    with (root / "manifest.json").open("x", encoding="utf-8") as stream:
        json.dump({"schema_version": 1, "sha256": manifest}, stream, indent=2, sort_keys=True)
        stream.write("\n")
