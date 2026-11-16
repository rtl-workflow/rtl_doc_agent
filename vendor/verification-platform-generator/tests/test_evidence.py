import json
from pathlib import Path
import sys
import tempfile
import unittest

from bt_uvm.evidence import evaluate, run


GOOD = {
    "stimulus": 1, "accepted": 1, "executed": 1, "returned": 1,
    "expected": 1, "actual": 1, "compared": 1, "rejected": 0,
    "cancelled": 0, "outstanding": 0, "mismatch": 0, "coverage_samples": 1,
}


class EvidenceTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "rtl.sv").write_text("module dut; endmodule\n", encoding="utf-8")
        self.runs = self.root / "runs"

    def execute(self, metrics=None, *, passline="BT_TEST_PASS sanity", extra="",
                kind="data", dut="real", exitcode=0, mutate=False, compile_exit=0):
        metrics = GOOD if metrics is None else metrics
        lines = [f"BT_METRIC {key}={value}" for key, value in metrics.items()]
        lines += [passline, extra]
        script = f"print({chr(10).join(lines)!r}); "
        if mutate:
            script += "open('rtl.sv','w').write('changed') ; "
        script += f"raise SystemExit({exitcode})"
        folder = run(self.root, self.runs, ["rtl.sv"], [sys.executable, "-c", script],
                     "sanity", 7, kind, dut,
                     compile_command=[sys.executable, "-c", f"print('compiled'); raise SystemExit({compile_exit})"],
                     plan={"tests": [{"name": "sanity", "kind": kind, "seeds": [7]}]})
        return folder, evaluate(folder, "sanity", 7)

    def test_valid_data_run(self):
        _, result = self.execute()
        self.assertEqual(result["status"], "pass", result)

    def test_zero_activity_with_pass_marker_fails(self):
        _, result = self.execute({key: 0 for key in GOOD})
        self.assertEqual(result["status"], "fail")

    def test_missing_metric_fails(self):
        _, result = self.execute({k: v for k, v in GOOD.items() if k != "coverage_samples"})
        self.assertIn("missing metric: coverage_samples", result["errors"])

    def test_duplicate_metric_fails(self):
        _, result = self.execute(extra="BT_METRIC compared=1")
        self.assertEqual(result["status"], "fail")

    def test_test_mismatch_fails(self):
        _, result = self.execute(passline="BT_TEST_PASS other")
        self.assertEqual(result["status"], "fail")

    def test_seed_mismatch_fails(self):
        folder, _ = self.execute()
        self.assertEqual(evaluate(folder, "sanity", 8)["status"], "fail")

    def test_mutated_rtl_fails(self):
        _, result = self.execute(mutate=True)
        self.assertIn("read-only baseline changed", result["errors"])

    def test_nonzero_exit_fails(self):
        _, result = self.execute(exitcode=1)
        self.assertEqual(result["status"], "fail")

    def test_compile_failure_skips_sim_and_fails(self):
        folder, result = self.execute(compile_exit=1)
        self.assertEqual(result["status"], "fail")
        self.assertEqual((folder / "stdout.log").read_text(), "")

    def test_model_is_not_real_dut_pass(self):
        _, result = self.execute(dut="model")
        self.assertEqual(result["status"], "fail")

    def test_assertion_fails_despite_pass(self):
        _, result = self.execute(extra="UVM_ERROR: unexpected")
        self.assertEqual(result["status"], "fail")

    def test_changed_log_fails(self):
        folder, _ = self.execute()
        with (folder / "stdout.log").open("a", encoding="utf-8") as f:
            f.write("injected\n")
        self.assertIn("stdout.log hash mismatch", evaluate(folder)["errors"])

    def test_replayed_record_in_other_directory_fails(self):
        folder, _ = self.execute()
        other = self.runs / "replayed"
        other.mkdir()
        for name in ("run.json", "compile.log", "compile.err", "stdout.log", "stderr.log"):
            (other / name).write_bytes((folder / name).read_bytes())
        self.assertIn("run identity mismatch", evaluate(other)["errors"])

    def test_reject_requires_no_execution(self):
        metrics = {**GOOD, "rejected": 1, "returned": 0, "executed": 0,
                   "expected": 0, "actual": 0, "compared": 0}
        _, result = self.execute(metrics, kind="reject")
        self.assertEqual(result["status"], "pass", result)

    def test_reject_with_execution_fails(self):
        metrics = {**GOOD, "rejected": 1, "returned": 0}
        _, result = self.execute(metrics, kind="reject")
        self.assertEqual(result["status"], "fail")

    def test_compile_log_cannot_fake_sim_pass(self):
        metrics = "\n".join(f"BT_METRIC {k}={v}" for k, v in GOOD.items())
        folder = run(self.root, self.runs, ["rtl.sv"], [sys.executable, "-c", "print('simulation without activity')"],
                     "sanity", 7, "data", "real",
                     compile_command=[sys.executable, "-c", f"print({(metrics + chr(10) + 'BT_TEST_PASS sanity')!r})"],
                     plan={"tests": [{"name": "sanity", "kind": "data", "seeds": [7]}]})
        self.assertEqual(evaluate(folder)["status"], "fail")

    def test_summary_cannot_mask_failure_on_same_line(self):
        _, result = self.execute(extra="UVM_ERROR : 0 UVM_FATAL unexpected")
        self.assertEqual(result["status"], "fail")

    def test_missing_record_fails(self):
        self.assertEqual(evaluate(self.root / "absent")["status"], "fail")

    def test_invalid_readonly_path_fails(self):
        with self.assertRaises(ValueError):
            run(self.root, self.runs, ["../external"], [sys.executable, "-c", "print(1)"], "sanity", 7, "data", "real")


if __name__ == "__main__":
    unittest.main()
