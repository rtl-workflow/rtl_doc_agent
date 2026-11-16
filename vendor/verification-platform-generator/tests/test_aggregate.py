from pathlib import Path
import sys
import tempfile
import unittest

from bt_uvm.aggregate import aggregate
from bt_uvm.evidence import run


SCRIPT = "; ".join(["print('BT_METRIC %s=%s')" % (k, v) for k, v in {
    "stimulus": 1, "accepted": 1, "executed": 1, "returned": 1,
    "expected": 1, "actual": 1, "compared": 1, "rejected": 0,
    "cancelled": 0, "outstanding": 0, "mismatch": 0, "coverage_samples": 1,
}.items()] + ["print('BT_TEST_PASS sanity')"])


class AggregateTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "rtl.sv").write_text("module dut; endmodule")
        self.runs = self.root / "runs"
        self.plan = {"tests": [{"name": "sanity", "kind": "data", "seeds": [1, 2]}]}

    def execute(self, seed):
        return run(self.root, self.runs, ["rtl.sv"], [sys.executable, "-c", SCRIPT],
                   "sanity", seed, "data", "real",
                   compile_command=[sys.executable, "-c", "print('compiled')"], plan=self.plan)

    def test_missing_seed_rejected(self):
        self.execute(1)
        self.assertIn("missing run: sanity seed=2", aggregate(self.plan, self.runs)["errors"])

    def test_full_plan_passes(self):
        self.execute(1)
        self.execute(2)
        self.assertEqual(aggregate(self.plan, self.runs)["status"], "pass")

    def test_duplicate_runs_rejected(self):
        self.execute(1)
        self.execute(1)
        self.execute(2)
        self.assertEqual(aggregate(self.plan, self.runs)["status"], "fail")

    def test_deleted_run_record_rejected(self):
        self.execute(1)
        second = self.execute(2)
        (second / "run.json").unlink()
        self.assertEqual(aggregate(self.plan, self.runs)["status"], "fail")

    def test_changed_plan_rejects_old_results(self):
        self.execute(1)
        self.execute(2)
        revised = {**self.plan, "revision": 2}
        self.assertEqual(aggregate(revised, self.runs)["status"], "fail")

    def test_unplanned_run_rejected(self):
        self.execute(1)
        self.execute(2)
        with self.assertRaises(ValueError):
            self.execute(3)


if __name__ == "__main__":
    unittest.main()
