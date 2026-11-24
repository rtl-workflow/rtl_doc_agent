import re
import sys
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parents[1]
SKILL_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(SCRIPT_DIR))

import check_style
import gen_docs


class ReferenceConsistencyTests(unittest.TestCase):
    def setUp(self):
        self.example = SKILL_DIR / "examples" / "demo_timer"

    def test_demo_timer_matches_current_naming_rules(self):
        data, errors, outputs = gen_docs.outputs(self.example)
        self.assertEqual([], errors)
        self.assertTrue(all(content == path.read_text(encoding="utf-8")
                            for path, content in outputs.items()))
        self.assertTrue(all(port["name"].startswith("i_")
                            for port in data["ports"] if port["dir"] == "input"))
        self.assertTrue(all(port["name"].startswith("o_")
                            for port in data["ports"] if port["dir"] == "output"))
        self.assertEqual([], check_style.check_ip(
            self.example,
            data["rtl_files"],
            data.get("resets"),
            data.get("source_naming"),
            top=data["top"],
        ))

    def test_fsm_reference_uses_wire_prefix_for_next_state(self):
        style = (SKILL_DIR / "references" / "rtl-coding-style.md").read_text(encoding="utf-8")
        self.assertIn("w_nxt_state", style)
        self.assertIsNone(re.search(r"(?<!w_)\bnxt_state\b", style))

    def test_demo_timer_instance_bindings_are_column_aligned(self):
        source = (self.example / "rtl" / "demo_timer.v").read_text(encoding="utf-8")
        groups = []
        current = []
        for line in source.splitlines():
            if re.match(r"^\s+\.\w+\s+\(", line):
                current.append(line)
            elif current:
                groups.append(current)
                current = []
        if current:
            groups.append(current)

        self.assertGreaterEqual(len(groups), 2)
        for group in groups:
            self.assertTrue(all(len(re.findall(r"\.\w+\s*\(", line)) == 1 for line in group))
            columns = []
            for line in group:
                left = line.index("(")
                signal = next(i for i in range(left + 1, len(line)) if not line[i].isspace())
                columns.append((line.index("."), left, signal, line.rfind(")")))
            self.assertEqual(1, len(set(columns)))


if __name__ == "__main__":
    unittest.main()
