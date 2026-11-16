"""CLI: python -m bt_uvm [static|run|evaluate] ..."""
import argparse
import json
from pathlib import Path
import sys

from .aggregate import aggregate
from .evidence import evaluate, run
from .integrity import verify_sources
from .static_gates import validate_design, validate_ir, validate_manifest, validate_platform


def _json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def main(argv=None):
    parser = argparse.ArgumentParser(description="BT UVM deterministic gates")
    sub = parser.add_subparsers(dest="action", required=True)
    static = sub.add_parser("static", help="validate JSON design/IR/platform/manifest")
    static.add_argument("gate", choices=("design", "ir", "platform", "manifest"))
    static.add_argument("--input", required=True)
    static.add_argument("--contract", required=True, help="contract; for manifest use test plan JSON")
    static.add_argument("--project", help="required for platform: measure source files")
    static.add_argument("--design", help="required for platform: measure approved design")
    execute = sub.add_parser("run", help="capture a real command and immutable-by-convention logs")
    execute.add_argument("--project", required=True)
    execute.add_argument("--runs-dir", required=True)
    execute.add_argument("--read-only", nargs="+", required=True)
    execute.add_argument("--test", required=True)
    execute.add_argument("--seed", required=True, type=int)
    execute.add_argument("--kind", required=True, choices=("data", "reject", "reset"))
    execute.add_argument("--dut", required=True, choices=("real", "model"))
    execute.add_argument("--compile-json", required=True, help="JSON array of compiler executable and arguments")
    execute.add_argument("--plan", required=True, help="approved JSON test plan")
    execute.add_argument("--timeout", type=int, default=120)
    execute.add_argument("command", nargs=argparse.REMAINDER, help="after --: executable and args")
    verdict = sub.add_parser("evaluate", help="evaluate original captured run")
    verdict.add_argument("--run-dir", required=True)
    verdict.add_argument("--test", required=True)
    verdict.add_argument("--seed", required=True, type=int)
    summary = sub.add_parser("aggregate", help="require every approved test/seed to pass")
    summary.add_argument("--plan", required=True)
    summary.add_argument("--runs-dir", required=True)
    args = parser.parse_args(argv)
    try:
        if args.action == "static":
            fn = {"design": validate_design, "ir": validate_ir,
                  "platform": validate_platform, "manifest": validate_manifest}[args.gate]
            source = _json(args.input)
            approved = _json(args.contract)
            kwargs = {"plan" if args.gate == "manifest" else "contract": approved}
            result = fn(source, **kwargs)
            if args.gate == "platform":
                if not args.project or not args.design:
                    raise ValueError("platform requires --project and --design")
                measured = verify_sources(Path(args.project), Path(args.design), source, approved)
                result["errors"].extend(measured["errors"])
                result["status"] = "fail" if result["errors"] else "pass"
        elif args.action == "run":
            cmd = args.command[1:] if args.command[:1] == ["--"] else args.command
            path = run(Path(args.project), Path(args.runs_dir), args.read_only, cmd,
                       args.test, args.seed, args.kind, args.dut, args.timeout,
                       compile_command=_json(args.compile_json), plan=_json(args.plan))
            result = evaluate(path, args.test, args.seed)
            result["run_dir"] = str(path)
        elif args.action == "aggregate":
            result = aggregate(_json(args.plan), Path(args.runs_dir))
        else:
            result = evaluate(Path(args.run_dir), args.test, args.seed)
    except (OSError, ValueError, TypeError, json.JSONDecodeError) as exc:
        result = {"status": "fail", "errors": [f"invalid input or execution: {exc}"]}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result.get("status") == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
