"""Evidence contract and mocked simulator regression; no EDA tools required."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import run_regress as regress
import verification_evidence as evidence


def config():
    return {"schema_version": 1, "tests": {"tc_smoke": {
        "seeds": [2, 7], "minimum": {"observations": 1, "checks": 1},
        "zero": ["mismatches", "outstanding"], "equal": [["expected", "actual", "checks"]]}}}


def transcript(test="tc_smoke", seed=2):
    return ("RTL_FLOW_METRIC observations=3\nRTL_FLOW_METRIC checks=3\n"
            "RTL_FLOW_METRIC mismatches=0\nRTL_FLOW_METRIC outstanding=0\n"
            "RTL_FLOW_METRIC expected=3\nRTL_FLOW_METRIC actual=3\n"
            "COVER smoke=1\nTEST {} SEED {} PASSED errors=0\n".format(test, seed))


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.ip = Path(self.temp.name) / "demo"
        for folder in ("dv/tb", "rtl", "data", "doc"):
            (self.ip / folder).mkdir(parents=True)
        (self.ip / "dv/tb/demo_tb.v").write_text("module demo_tb; endmodule\n")
        (self.ip / "rtl/dut.v").write_text("module dut; endmodule\n")
        (self.ip / "data/demo.yaml").write_text("name: demo\n")
        (self.ip / "doc/07_dv_plan.md").write_text("verification plan\n")
        self.data = {"name": "demo", "top": "dut", "rtl_files": ["rtl/dut.v"],
                     "ports": [{"name": "clk", "dir": "input", "width": 1}]}
        self.cfg = config()
        self.write_config()

    def write_config(self):
        (self.ip / evidence.CONFIG).write_text(json.dumps(self.cfg), encoding="utf-8")

    def run_mock(self, output=None, stub=False, only=None, compile_code=0, change=None, sim_code=0):
        self.commands = []

        def execute(args, **kwargs):
            self.commands.append(args)
            if args[0] == "vcs":
                return subprocess.CompletedProcess(args, compile_code, "compile stdout\n", "compile stderr\n")
            seed = int(next(arg.split("=", 1)[1] for arg in args if arg.startswith("+SEED=")))
            if change:
                change()
            text = transcript(seed=seed) if output is None else (output(seed) if callable(output) else output)
            return subprocess.CompletedProcess(args, sim_code, text, "")

        with patch.object(regress.remote_exec, "enabled", return_value=False), \
             patch.object(regress.gen_docs, "outputs", return_value=(self.data, [], {})), \
             patch.object(regress, "plan_tests", return_value={"tc_smoke": ["tp_smoke"]}), \
             patch.object(regress, "tool", return_value="vcs"), \
             patch.object(regress, "collect_coverage", return_value={"metrics": {}, "error": None}), \
             patch.object(regress.subprocess, "run", side_effect=execute):
            return regress.run(self.ip, stub=stub, only=only, fsdb=False)

    def test_schema_exact_plan_and_typed_seeds(self):
        bad = [True, 0, -1, "2", 2.0]
        for value in bad:
            with self.subTest(seed=value):
                self.cfg = config()
                self.cfg["tests"]["tc_smoke"]["seeds"] = [value]
                self.write_config()
                with self.assertRaises(ValueError):
                    evidence.load(self.ip, {"tc_smoke": []})
        for seeds in ([], [2, 2]):
            self.cfg = config()
            self.cfg["tests"]["tc_smoke"]["seeds"] = seeds
            self.write_config()
            with self.assertRaises(ValueError):
                evidence.load(self.ip, {"tc_smoke": []})
        self.cfg = config()
        self.write_config()
        for tests in ({}, {"tc_other": []}, {"tc_smoke": [], "tc_other": []}):
            with self.assertRaises(ValueError):
                evidence.load(self.ip, tests)

    def test_schema_rejects_zero_activity_unknown_fields_and_duplicates(self):
        cases = []
        for name in ("observations", "checks"):
            cfg = config()
            cfg["tests"]["tc_smoke"]["minimum"][name] = 0
            cases.append(cfg)
        cfg = config()
        cfg["schema_version"] = True
        cases.append(cfg)
        cfg = config()
        cfg["extra"] = 1
        cases.append(cfg)
        cfg = config()
        cfg["tests"]["tc_smoke"]["zero"] = []
        cases.append(cfg)
        for cfg in cases:
            self.cfg = cfg
            self.write_config()
            with self.assertRaises(ValueError):
                evidence.load(self.ip, {"tc_smoke": []})
        (self.ip / evidence.CONFIG).write_text('{"schema_version":1,"schema_version":1,"tests":{}}')
        with self.assertRaisesRegex(ValueError, "duplicate JSON key"):
            evidence.load(self.ip, {})

    def test_strict_metrics_and_exact_result(self):
        rule = self.cfg["tests"]["tc_smoke"]
        self.assertEqual([], evidence.parse(transcript(), rule, "tc_smoke", 2)[1])
        texts = [transcript().replace("observations=3", "observations=0"),
                 transcript().replace("checks=3", "checks=0"),
                 transcript().replace("actual=3", "actual=2"),
                 transcript().replace("mismatches=0", "mismatches=1"),
                 transcript().replace("outstanding=0", "outstanding=1"),
                 transcript().replace("checks=3", "checks=-1"),
                 transcript().replace("checks=3", "checks=3 trailing"),
                 transcript().replace("RTL_FLOW_METRIC checks=3\n", ""),
                 transcript() + "RTL_FLOW_METRIC checks=3\n",
                 transcript() + "RTL_FLOW_METRIC extra=0\n",
                 transcript(seed=7), transcript() + "TEST tc_other SEED 2 PASSED errors=0\n",
                 transcript().replace("errors=0", "errors=1")]
        for text in texts:
            with self.subTest(text=text):
                self.assertTrue(evidence.parse(text, rule, "tc_smoke", 2)[1])

    def test_runner_uses_explicit_seeds_and_preserves_archives(self):
        first = self.run_mock()
        self.assertEqual("PASS", first["result"])
        self.assertEqual([2, 7], [test["seed"] for test in first["tests"]])
        root = self.ip / first["evidence"]["path"]
        self.assertEqual("compile stdout\ncompile stderr\n", (root / "compile.log").read_text())
        snapshot = (root / "result.json").read_bytes()
        manifest = json.loads((root / "manifest.json").read_text())["sha256"]
        for name, value in manifest.items():
            self.assertEqual(value, hashlib.sha256((root / name).read_bytes()).hexdigest())
        second = self.run_mock(output=transcript().replace("PASSED", "FAILED"))
        self.assertEqual("FAIL", second["result"])
        self.assertNotEqual(first["evidence"]["path"], second["evidence"]["path"])
        self.assertEqual(snapshot, (root / "result.json").read_bytes())
        self.assertIn("FAILED", (self.ip / second["evidence"]["path"] / "logs/tc_smoke_2.log").read_text())

    def test_compile_failure_archives_original_output_and_partial_keeps_full(self):
        full = self.run_mock()
        previous = (self.ip / regress.REPORT).read_bytes()
        result = self.run_mock(compile_code=1, only="tc_smoke")
        self.assertEqual("FAIL", result["result"])
        self.assertTrue(result["partial"])
        self.assertEqual(previous, (self.ip / regress.REPORT).read_bytes())
        self.assertTrue((self.ip / result["evidence"]["path"] / "compile.log").is_file())

    def test_stub_uses_seeds_without_enforcing_metrics_or_reading_rtl(self):
        original = Path.read_bytes
        def read(path):
            if "rtl" in path.parts:
                raise AssertionError("stub read RTL")
            return original(path)
        with patch.object(Path, "read_bytes", read):
            result = self.run_mock(stub=True, output=lambda seed: "TEST tc_smoke SEED {} FAILED errors=3\n".format(seed))
        self.assertEqual("PASS", result["result"])
        self.assertEqual([2, 7], [test["seed"] for test in result["tests"]])
        self.assertFalse(result["evidence"]["metrics_enforced"])

    def test_legacy_without_contract_retains_single_seed(self):
        (self.ip / evidence.CONFIG).unlink()
        result = self.run_mock(output="TEST tc_smoke PASSED errors=0\n")
        self.assertEqual("PASS", result["result"])
        self.assertEqual([1], [test["seed"] for test in result["tests"]])
        self.assertNotIn("evidence", result)
        self.assertEqual("absent", result["evidence_sha256"])

    def test_inputs_and_plan_prose_bound_and_changed_during_run_fails(self):
        before = regress.digests(self.ip, self.data)
        (self.ip / "doc/07_dv_plan.md").write_text("approved new prose\n")
        self.assertNotEqual(before["plan_sha256"], regress.digests(self.ip, self.data)["plan_sha256"])
        result = self.run_mock(change=lambda: (self.ip / "rtl/dut.v").write_text("changed\n"))
        self.assertEqual("FAIL", result["result"])
        self.assertIn("verification inputs changed during execution", result["problems"])
        (self.ip / evidence.CONFIG).unlink()
        self.assertEqual("absent", regress.digests(self.ip, self.data)["evidence_sha256"])
        self.assertNotEqual(before["tb_sha256"], regress.digests(self.ip, self.data)["tb_sha256"])

    def test_remote_and_local_archive_integrity(self):
        result = self.run_mock()
        root = self.ip / result["evidence"]["path"]
        alias = self.ip / "dv/build/regress/last_result.json"
        files = [self.ip.name + "/" + path.relative_to(self.ip).as_posix()
                 for path in root.rglob("*") if path.is_file()]
        evidence.verify_archive(self.ip, result, files, alias)
        evidence.verify_archive(self.ip, result, None, alias)
        with self.assertRaisesRegex(ValueError, "not collected"):
            evidence.verify_archive(self.ip, result, [], alias)
        log = root / "logs/tc_smoke_2.log"
        log.write_text("tampered")
        with self.assertRaisesRegex(ValueError, "hash mismatch"):
            evidence.verify_archive(self.ip, result, files, alias)
        with self.assertRaisesRegex(ValueError, "hash mismatch"):
            evidence.verify_archive(self.ip, result, None, alias)

    def test_crlf_input_binding_matches_remote_normalization(self):
        cfg = self.ip / evidence.CONFIG
        cfg.write_bytes(json.dumps(self.cfg, indent=2).encode().replace(b"\n", b"\r\n"))
        plan = self.ip / "doc/07_dv_plan.md"
        plan.write_bytes(b"plan\r\napproved\r\n")
        before = regress.digests(self.ip, self.data)
        cfg.write_bytes(cfg.read_bytes().replace(b"\r\n", b"\n"))
        plan.write_bytes(plan.read_bytes().replace(b"\r\n", b"\n"))
        self.assertEqual(before, regress.digests(self.ip, self.data))

    def test_stub_rejects_wrong_observed_seed(self):
        result = self.run_mock(stub=True, output="TEST tc_smoke SEED 99 FAILED errors=3\n")
        self.assertEqual("FAIL", result["result"])

    def test_invalid_data_and_midrun_change_keep_failure_archive(self):
        import yaml
        with patch.object(regress.remote_exec, "enabled", return_value=False), \
             patch.object(regress.gen_docs, "outputs", side_effect=yaml.YAMLError("broken yaml")):
            result = regress.run(self.ip, fsdb=False)
        self.assertEqual("FAIL", result["result"])
        self.assertTrue((self.ip / result["evidence"]["path"] / "manifest.json").is_file())
        for value in (None, [], "scalar"):
            def change():
                regress.gen_docs.outputs.return_value = (value, [], {})
            result = self.run_mock(change=change)
            self.assertEqual("FAIL", result["result"])
            self.assertTrue((self.ip / result["evidence"]["path"] / "result.json").is_file())

    def test_remote_collects_archives_without_cleaning_history(self):
        args, build, collect = regress.remote_job(only="tc_smoke")
        self.assertIn("reports/evidence/**", collect)
        self.assertNotIn("reports/regress.json", collect)
        self.assertEqual("dv/build/regress", build)


if __name__ == "__main__":
    unittest.main()
