import json
from pathlib import Path
import tempfile
import unittest

from agent.doctor import check


class AgentDoctorTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "agent").mkdir()
        (self.root / "SKILL.md").write_text("entry", encoding="utf-8")
        self.value = {
            "schema_version": "verification-agent-registry/v1",
            "execution_model": "host_agent_assisted", "entrypoint": "SKILL.md",
            "required_documents": ["SKILL.md"],
            "capabilities": [{"id": "a", "entrypoint": "SKILL.md", "kind": "subskill",
                              "status": "agent_assisted", "depends_on": []}]}

    def run_check(self):
        (self.root / "agent/registry.json").write_text(json.dumps(self.value), encoding="utf-8")
        return check(self.root)

    def test_valid_catalog_is_not_execution_proof(self):
        result = self.run_check()
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["scope"], "asset_catalog")
        self.assertEqual(result["execution_readiness"], "not_assessed")

    def test_missing_entry_fails(self):
        self.value["capabilities"][0]["entrypoint"] = "missing.md"
        self.assertEqual(self.run_check()["status"], "fail")

    def test_traversal_fails(self):
        self.value["entrypoint"] = "../SKILL.md"
        self.assertEqual(self.run_check()["status"], "fail")

    def test_unknown_dependency_fails(self):
        self.value["capabilities"][0]["depends_on"] = ["missing"]
        self.assertEqual(self.run_check()["status"], "fail")

    def test_cycle_fails(self):
        self.value["capabilities"][0]["depends_on"] = ["a"]
        self.assertEqual(self.run_check()["status"], "fail")

    def test_duplicate_id_fails(self):
        self.value["capabilities"].append(dict(self.value["capabilities"][0]))
        self.assertEqual(self.run_check()["status"], "fail")

    def test_non_object_registry_fails(self):
        self.value = []
        self.assertEqual(self.run_check()["status"], "fail")

    def test_malformed_json_fails(self):
        (self.root / "agent/registry.json").write_text("{", encoding="utf-8")
        self.assertEqual(check(self.root)["status"], "fail")


if __name__ == "__main__":
    unittest.main()
