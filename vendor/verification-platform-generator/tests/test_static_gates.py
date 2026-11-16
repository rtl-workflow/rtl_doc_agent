"""Regression tests for the read-only structural gates."""

import copy
import json
import unittest

from bt_uvm.static_gates import (
    validate_design,
    validate_ir,
    validate_manifest,
    validate_platform,
)


class StaticGateTests(unittest.TestCase):
    def setUp(self):
        self.contract = {
            "dut": {"name": "block", "top": "block_top"},
            "requirements": ["R-17"],
            "interfaces": [{"name": "request", "direction": "input"}],
            "features": ["F-17"],
            "components": [
                {"id": "input_monitor", "kind": "monitor", "path": "tb/mon.sv"},
                {"id": "checker", "kind": "scoreboard", "path": "tb/check.sv"},
            ],
            "connections": [{"from": "input_monitor", "to": "checker", "role": "actual"}],
            "design_sha256": "a" * 64,
        }
        self.design = {
            "dut": copy.deepcopy(self.contract["dut"]),
            "requirements": [{"id": "R-17", "source": "approved specification v2", "status": "confirmed"}],
            "interfaces": [{"name": "request", "direction": "input", "driver": "bfm", "observer": "input_monitor"}],
            "components": copy.deepcopy(self.contract["components"]),
            "trace": [{
                "requirement_id": "R-17", "stimulus": "send legal request",
                "expected": "expected response from independent model", "observed": "response handshake",
                "checker": "checker compares response", "coverage": "request accepted",
                "tests": ["basic"],
            }],
        }
        self.ir = {
            "dut": copy.deepcopy(self.contract["dut"]),
            "interfaces": copy.deepcopy(self.contract["interfaces"]),
            "sources": {"requirements": ["spec-v2"], "rtl": ["rtl/block.sv"]},
            "features": [{
                "id": "F-17", "requirement_ids": ["R-17"], "description": "response",
                "stimulus": "request", "expected": "model output",
                "observability": "response handshake", "coverage_item": "request observed",
                "priority": "P0", "tests": ["basic"],
            }],
        }
        self.platform = {
            "design_sha256": "a" * 64,
            "components": [{**row, "source_sha256": "b" * 64} for row in self.contract["components"]],
            "connections": copy.deepcopy(self.contract["connections"]),
        }
        self.plan = {
            "features": ["F-17"],
            "tests": [{"name": "basic", "type": "sanity", "kind": "data", "source_id": "R-17", "features": ["F-17"], "seeds": [0, 7]}],
        }
        self.manifest = {
            "tests": [{
                **self.plan["tests"][0], "source_id": "R-17",
                "preconditions": "reset complete", "stimulus": "request",
                "expected": "model response", "monitor": "response monitor",
                "checker": "checker comparison", "coverage": "accepted request",
                "run_command": "sim +TEST=basic",
            }],
        }

    def assert_failure(self, result, code):
        self.assertEqual(result["status"], "fail", result)
        self.assertIn(code, {item["code"] for item in result["errors"]})
        json.dumps(result)

    def test_complete_structures_pass_without_mutating_inputs(self):
        cases = (
            (validate_design, self.design, {"contract": self.contract}),
            (validate_ir, self.ir, {"contract": self.contract}),
            (validate_platform, self.platform, {"contract": self.contract}),
            (validate_manifest, self.manifest, {"plan": self.plan}),
        )
        for gate, artifact, kwargs in cases:
            with self.subTest(gate=gate.__name__):
                original = copy.deepcopy((artifact, kwargs))
                result = gate(artifact, **kwargs)
                self.assertEqual(result, {"status": "pass", "errors": []})
                self.assertEqual((artifact, kwargs), original)

    def test_missing_and_invalid_inputs_fail_closed(self):
        for gate, kwargs in (
            (validate_design, {"contract": self.contract}),
            (validate_ir, {"contract": self.contract}),
            (validate_platform, {"contract": self.contract}),
            (validate_manifest, {"plan": self.plan}),
        ):
            with self.subTest(gate=gate.__name__):
                self.assert_failure(gate(None, **kwargs), "type")
                self.assert_failure(gate({}, **kwargs), "type")
        self.assert_failure(validate_design(self.design, contract=None), "type")
        self.assert_failure(validate_manifest(self.manifest, plan=None), "type")

    def test_design_trace_and_approval_are_required(self):
        artifact = copy.deepcopy(self.design)
        artifact["trace"] = []
        self.assert_failure(validate_design(artifact, contract=self.contract), "missing")
        artifact = copy.deepcopy(self.design)
        artifact["requirements"][0]["status"] = "pending"
        self.assert_failure(validate_design(artifact, contract=self.contract), "unconfirmed")
        artifact = copy.deepcopy(self.design)
        artifact["interfaces"][0]["direction"] = "output"
        self.assert_failure(validate_design(artifact, contract=self.contract), "mismatch")
        artifact = copy.deepcopy(self.design)
        artifact["trace"][0]["checker"] = "  "
        self.assert_failure(validate_design(artifact, contract=self.contract), "required")

    def test_ir_rejects_unapproved_feature_and_missing_trace(self):
        artifact = copy.deepcopy(self.ir)
        artifact["features"][0]["id"] = "invented"
        self.assert_failure(validate_ir(artifact, contract=self.contract), "unexpected")
        artifact = copy.deepcopy(self.ir)
        artifact["features"][0]["requirement_ids"] = ["R-OTHER"]
        self.assert_failure(validate_ir(artifact, contract=self.contract), "missing")
        artifact = copy.deepcopy(self.ir)
        artifact["sources"]["rtl"] = []
        self.assert_failure(validate_ir(artifact, contract=self.contract), "type")

    def test_platform_rejects_missing_components_connections_and_stale_design(self):
        artifact = copy.deepcopy(self.platform)
        artifact["components"].pop()
        self.assert_failure(validate_platform(artifact, contract=self.contract), "missing")
        artifact = copy.deepcopy(self.platform)
        artifact["connections"] = []
        self.assert_failure(validate_platform(artifact, contract=self.contract), "missing")
        artifact = copy.deepcopy(self.platform)
        artifact["design_sha256"] = "c" * 64
        self.assert_failure(validate_platform(artifact, contract=self.contract), "stale")
        artifact = copy.deepcopy(self.platform)
        artifact["components"][0]["path"] = "../outside.sv"
        self.assert_failure(validate_platform(artifact, contract=self.contract), "unsafe_path")
        artifact = copy.deepcopy(self.platform)
        artifact["components"][0]["source_sha256"] = "not a hash"
        self.assert_failure(validate_platform(artifact, contract=self.contract), "digest")

    def test_manifest_requires_exact_planned_tests_features_and_seeds(self):
        artifact = copy.deepcopy(self.manifest)
        artifact["tests"] = []
        self.assert_failure(validate_manifest(artifact, plan=self.plan), "missing")
        artifact = copy.deepcopy(self.manifest)
        artifact["tests"][0]["seeds"] = [0, 8]
        self.assert_failure(validate_manifest(artifact, plan=self.plan), "missing")
        artifact = copy.deepcopy(self.manifest)
        artifact["tests"][0]["features"] = ["F-OTHER"]
        self.assert_failure(validate_manifest(artifact, plan=self.plan), "unexpected")
        artifact = copy.deepcopy(self.manifest)
        artifact["tests"][0]["source_id"] = "fabricated"
        self.assert_failure(validate_manifest(artifact, plan=self.plan), "mismatch")
        artifact = copy.deepcopy(self.manifest)
        artifact["tests"][0]["kind"] = "reject"
        self.assert_failure(validate_manifest(artifact, plan=self.plan), "mismatch")
        artifact = copy.deepcopy(self.manifest)
        artifact["tests"][0]["checker"] = ""
        self.assert_failure(validate_manifest(artifact, plan=self.plan), "required")
        artifact = copy.deepcopy(self.manifest)
        artifact["tests"][0]["seeds"] = [True, 7]
        self.assert_failure(validate_manifest(artifact, plan=self.plan), "invalid_seed")

    def test_no_fixed_component_paths_or_test_names(self):
        contract = copy.deepcopy(self.contract)
        design = copy.deepcopy(self.design)
        contract["components"][0]["path"] = "custom/channel_probe.sv"
        design["components"][0]["path"] = "custom/channel_probe.sv"
        self.assertEqual(validate_design(design, contract=contract)["status"], "pass")
        plan = copy.deepcopy(self.plan)
        manifest = copy.deepcopy(self.manifest)
        plan["tests"][0]["name"] = "initial_check"
        manifest["tests"][0]["name"] = "initial_check"
        self.assertEqual(validate_manifest(manifest, plan=plan)["status"], "pass")


if __name__ == "__main__":
    unittest.main()
