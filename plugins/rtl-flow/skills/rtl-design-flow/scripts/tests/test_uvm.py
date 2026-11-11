import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from argparse import Namespace
from unittest.mock import patch

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import flow
import dv_review
import run_regress as regress
import run_mutation
import uvm_support as uvm


def transcript(test="tc_smoke", seed=1, cls="svf_smoke", errors=0, fatal=0):
    return (f"RTL_FLOW_UVM_STARTED {test} SEED {seed} CLASS {cls}\n"
            "COVER loopback=4\n"
            f"RTL_FLOW_UVM_COMPLETED {test} SEED {seed} CLASS {cls}\n"
            f"TEST {test} SEED {seed} {'FAILED' if errors else 'PASSED'} errors={errors}\n"
            f"UVM_ERROR : {errors}\nUVM_FATAL : {fatal}\n")


def prepare_fixture(target):
    """Use the maintained base-test template rather than a divergent fixture copy."""
    source = Path(__file__).parent / "fixtures" / "uvm_loopback"
    shutil.copytree(source, target)
    common = target / "dv/env/common"
    common.mkdir()
    shutil.copyfile(flow.SKILL / "templates/dv/env/common/rtlflow_test_base.svh",
                    common / "rtlflow_test_base.svh")
    return target


class UvmTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.ip = Path(self.temp.name) / "MixedCase"
        for d in ("dv/top", "dv/env/common", "dv/tests", "dv/sim/scripts", "rtl", "doc"):
            (self.ip / d).mkdir(parents=True, exist_ok=True)
        self.cfg = {"schema_version": 1, "top": "MixedCase_tb", "uvm_version": "uvm-1.2",
                    "filelist": "sim/scripts/tb_list.f", "test_map": {"tc_smoke": "svf_smoke"}}
        self.write_cfg()
        (self.ip / "dv/sim/scripts/tb_list.f").write_text(
            "+incdir+env/common\n-f sim/scripts/pkg.f\ntop/tb_top.sv\n")
        (self.ip / "dv/sim/scripts/pkg.f").write_text("env/env_pkg.sv\n")
        (self.ip / "dv/env/env_pkg.sv").write_text('`include "common.svh"\npackage demo; endpackage\n')
        (self.ip / "dv/env/common/common.svh").write_text('`include "uvm_macros.svh"\n')
        (self.ip / "dv/top/tb_top.sv").write_text("module MixedCase_tb; endmodule\n")
        (self.ip / "rtl/dut.v").write_text("module dut; endmodule\n")
        (self.ip / "doc/07_dv_plan.md").write_text("verification plan\n")
        self.data = {"name": "MixedCase", "top": "dut", "rtl_files": ["rtl/dut.v"],
                     "ports": [{"name": "clk", "dir": "input", "width": 1},
                               {"name": "out", "dir": "output", "width": 8}]}

    def write_cfg(self):
        (self.ip / "dv/uvm.yaml").write_text(yaml.safe_dump(self.cfg))

    def test_ordered_compile_units_and_include_dependencies(self):
        p = uvm.load(self.ip)
        self.assertEqual(["env_pkg.sv", "tb_top.sv"], [f.name for f in p.sources])
        self.assertIn(self.ip / "dv/env/common/common.svh", p.dependencies)
        self.assertEqual(["-sverilog", "-ntb_opts", "uvm-1.2"], p.compile_args()[:3])
        self.assertEqual(["+UVM_TESTNAME=svf_smoke", "+ntb_random_seed=7"], p.run_args("tc_smoke", 7))

    def test_bad_manifest_and_filelists_fail_before_compile(self):
        cases = ["-f sim/scripts/tb_list.f\n", "../../rtl/dut.v\n", "-y ../../rtl\n",
                 "top/tb_top.sv\ntop/tb_top.sv\n", "top/missing.sv\n", "+incdir+build\n"]
        for text in cases:
            with self.subTest(text=text):
                (self.ip / "dv/sim/scripts/tb_list.f").write_text(text)
                with self.assertRaises(ValueError):
                    uvm.load(self.ip)

    def test_include_cannot_read_rtl(self):
        (self.ip / "dv/env/env_pkg.sv").write_text('`include "../../rtl/dut.v"\n')
        with self.assertRaisesRegex(ValueError, "escapes dv"):
            uvm.load(self.ip)

    def test_include_change_invalidates_regression_and_g3(self):
        before = regress.digests(self.ip, self.data)
        review = dv_review.fingerprint(self.ip)
        (self.ip / "dv/env/common/common.svh").write_text("// changed included model\n")
        self.assertNotEqual(before["tb_sha256"], regress.digests(self.ip, self.data)["tb_sha256"])
        self.assertNotEqual(review, dv_review.fingerprint(self.ip))
        after = regress.digests(self.ip, self.data)
        (self.ip / "dv/build").mkdir()
        (self.ip / "dv/build/compile.log").write_text("build output\n")
        self.assertEqual(after, regress.digests(self.ip, self.data))

    def test_mapping_change_invalidates_cache(self):
        before = regress.digests(self.ip, self.data)
        self.cfg["test_map"]["tc_smoke"] = "new_class"
        self.write_cfg()
        self.assertNotEqual(before["tb_sha256"], regress.digests(self.ip, self.data)["tb_sha256"])

    def test_legacy_project_still_uses_verilog(self):
        (self.ip / "dv/uvm.yaml").unlink()
        (self.ip / "dv/tb").mkdir()
        tb = self.ip / "dv/tb/MixedCase_tb.v"
        tb.write_text("module MixedCase_tb; endmodule\n")
        self.assertFalse(uvm.enabled(self.ip))
        self.assertEqual([tb], regress.tb_files(self.ip))

    def run_mock(self, output=None, stub=False, code=0, only=None):
        self.commands = []

        def execute(args, **kwargs):
            self.commands.append(args)
            compile_step = args[0] == "vcs"
            return subprocess.CompletedProcess(args, 0 if compile_step else code,
                                               "compiled" if compile_step else output or transcript(), "")

        with patch.object(regress.remote_exec, "enabled", return_value=False), \
             patch.object(regress.gen_docs, "outputs", return_value=(self.data, [], {})), \
             patch.object(regress, "plan_tests", return_value={"tc_smoke": ["tp_loopback"]}), \
             patch.object(regress, "tool", return_value="vcs"), \
             patch.object(regress, "collect_coverage", return_value={"metrics": {}, "error": None}), \
             patch.object(regress.subprocess, "run", side_effect=execute):
            return regress.run(self.ip, stub=stub, only=only, fsdb=False)

    def test_runner_compiles_and_runs_mapped_uvm_test(self):
        res = self.run_mock()
        self.assertEqual("PASS", res["result"])
        self.assertEqual("uvm", res["backend"])
        self.assertIn("-sverilog", self.commands[0])
        self.assertIn(str((self.ip / "rtl/dut.v").resolve()), self.commands[0])
        self.assertIn("+UVM_TESTNAME=svf_smoke", self.commands[1])
        self.assertIn("+ntb_random_seed=1", self.commands[1])

    def test_stub_never_reads_or_compiles_rtl(self):
        original = Path.read_bytes

        def read(path):
            if "rtl" in path.parts:
                raise AssertionError("stub read DUT RTL")
            return original(path)

        with patch.object(Path, "read_bytes", read):
            res = self.run_mock(transcript(errors=4), stub=True)
        self.assertEqual("PASS", res["result"])
        self.assertEqual("FAILED", res["tests"][0]["status"])
        self.assertNotIn(str((self.ip / "rtl/dut.v").resolve()), self.commands[0])
        self.assertIn("+define+RTLFLOW_STUB", self.commands[0])
        self.assertTrue(any("dut_stub.v" in arg for arg in self.commands[0]))

    def test_wrong_class_seed_fatal_and_missing_completion_fail_stub(self):
        lines = transcript().splitlines()
        reordered = "\n".join([lines[2], lines[0], lines[1]] + lines[3:]) + "\n"
        for text in (transcript(cls="wrong"), transcript(seed=2), transcript(fatal=1),
                     transcript().replace("RTL_FLOW_UVM_COMPLETED", "INCOMPLETE"),
                     "UVM_ERROR : 0\nUVM_FATAL : 0\n", transcript() + transcript(), reordered):
            with self.subTest(text=text):
                self.assertEqual("FAIL", self.run_mock(text, stub=True)["result"])

    def test_real_run_rejects_uvm_error_even_with_pass_line(self):
        text = transcript().replace("UVM_ERROR : 0", "UVM_ERROR : 2")
        self.assertEqual("FAIL", self.run_mock(text)["result"])
        text = transcript() + "UVM_ERROR file.sv(1) @ 10: reporter [CHECK] late failure\n"
        self.assertEqual("FAIL", self.run_mock(text)["result"])

    def test_padded_zero_severity_summaries_are_not_errors(self):
        text = transcript().replace("UVM_ERROR : 0", "  UVM_ERROR   :    0").replace("UVM_FATAL : 0", "UVM_FATAL    : 0")
        self.assertEqual("PASS", self.run_mock(text)["result"])

    def test_nonzero_exit_and_no_coverage_cannot_pass(self):
        self.assertEqual("FAIL", self.run_mock(code=1)["result"])
        self.assertEqual("FAIL", self.run_mock(transcript().replace("COVER loopback=4\n", ""))["result"])

    def test_invalid_manifest_does_not_fall_back_to_legacy(self):
        self.cfg["uvm_version"] = "typo"
        self.write_cfg()
        self.assertEqual("FAIL", self.run_mock()["result"])
        self.assertEqual([], self.commands)

    def test_partial_failure_does_not_replace_full_report(self):
        report = self.ip / regress.REPORT
        report.parent.mkdir()
        report.write_text("existing full report")
        self.cfg["uvm_version"] = "invalid"
        self.write_cfg()
        self.assertEqual("FAIL", self.run_mock(only="tc_smoke")["result"])
        self.assertEqual("existing full report", report.read_text())

    def test_mutation_uses_same_uvm_failure_contract(self):
        platform = uvm.load(self.ip)
        result = subprocess.CompletedProcess([], 0, transcript(fatal=1), "")
        with patch.object(run_mutation.subprocess, "run", return_value=result) as run:
            self.assertEqual("failed", run_mutation.run_test(self.ip, "tc_smoke", 1, platform))
            self.assertIn("+UVM_TESTNAME=svf_smoke", run.call_args.args[0])

    def test_new_projects_default_to_uvm(self):
        new_ip = Path(self.temp.name) / "NewIP"
        flow.cmd_init(Namespace(ip_dir=new_ip, input=[], auto=False))
        cfg = yaml.safe_load((new_ip / uvm.MANIFEST).read_text())
        self.assertEqual("NewIP_tb", cfg["top"])
        self.assertEqual("uvm-1.2", cfg["uvm_version"])
        for name in ("gen", "bfm", "rm", "scb", "funcov", "ral"):
            self.assertTrue((new_ip / "dv/env" / name).is_dir())
        self.assertTrue((new_ip / "dv/env/common/rtlflow_test_base.svh").is_file())
        # A scaffold is not a completed testbench, and must not pass validation.
        with self.assertRaisesRegex(ValueError, "missing"):
            uvm.load(new_ip)

    def test_complete_fixture_resolves_real_components_and_ssot(self):
        ip = prepare_fixture(Path(self.temp.name) / "uvm_loopback")
        platform = uvm.load(ip)
        self.assertEqual(3, len(platform.sources))
        self.assertGreater(len(platform.dependencies), 10)
        data, errors, _ = regress.gen_docs.outputs(ip)
        self.assertEqual([], errors)
        self.assertEqual("uvm_loopback", data["top"])
        self.assertEqual({"tc_loopback_smoke": ["tp_loopback_data"]}, regress.plan_tests(ip))


if __name__ == "__main__":
    unittest.main()
