from hashlib import sha256
from pathlib import Path
import tempfile
import unittest

from bt_uvm.integrity import verify_sources


class IntegrityTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.design = self.root / "design.md"
        self.design.write_text("approved", encoding="utf-8")
        (self.root / "tb.sv").write_text("module tb; endmodule", encoding="utf-8")
        digest = lambda path: sha256(path.read_bytes()).hexdigest()
        self.contract = {"design_sha256": digest(self.design)}
        self.platform = {"design_sha256": digest(self.design), "components": [
            {"id": "tb", "path": "tb.sv", "source_sha256": digest(self.root / "tb.sv")}]}

    def test_measured_hashes_pass(self):
        self.assertEqual(verify_sources(self.root, self.design, self.platform, self.contract)["status"], "pass")

    def test_modified_source_fails(self):
        (self.root / "tb.sv").write_text("changed")
        self.assertEqual(verify_sources(self.root, self.design, self.platform, self.contract)["status"], "fail")

    def test_modified_design_fails(self):
        self.design.write_text("changed")
        self.assertEqual(verify_sources(self.root, self.design, self.platform, self.contract)["status"], "fail")

    def test_path_escape_fails(self):
        self.platform["components"][0]["path"] = "../foreign.sv"
        self.assertEqual(verify_sources(self.root, self.design, self.platform, self.contract)["status"], "fail")


if __name__ == "__main__":
    unittest.main()
