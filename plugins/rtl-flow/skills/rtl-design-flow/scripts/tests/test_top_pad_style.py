import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_style


class TopPadStyleTests(unittest.TestCase):
    def violations(self, body, top="chip"):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "unrelated_filename.v"
            path.write_text(body, encoding="utf-8")
            return [v for v in check_style.check_file(path, path.name, top=top)
                    if v[2] == "RTL-34"]

    def test_top_boundary_only(self):
        body = """module chip(input en, input data, inout pad, output result);
wire internal_net;
assign pad = en ? data : 1'bz;
assign result = en ? data : 1'bz;
assign internal_net = en ? data : 1'bz;
endmodule"""
        self.assertEqual(1, len(self.violations(body)))
        self.assertEqual(3, len(self.violations(body, top="parent")))
        self.assertEqual(3, len(self.violations(body, top=None)))

    def test_vector_pad_and_non_ansi(self):
        body = """module chip(en, pad);
input en;
inout [3:0] pad;
assign pad[3:0] = en ? 4'b1010 : 4'bzzzz;
endmodule"""
        self.assertEqual([], self.violations(body))

    def test_input_internal_procedural_and_unknown_lhs_stay_errors(self):
        body = """module chip(input en, inout pad, output reg result);
wire n;
assign en = 1'bz;
assign n = 1'bz;
assign {pad, n} = 2'bzz;
always @(*) result = 1'bz;
endmodule"""
        self.assertEqual(4, len(self.violations(body)))

    def test_extra_module_not_exempted(self):
        body = "module chip(inout pad); assign pad = 1'bz; endmodule\n"
        body += "module child(inout pad); assign pad = 1'bz; endmodule\n"
        self.assertEqual(2, len(self.violations(body)))

    def test_comments_cannot_grant_exemption(self):
        body = """module child(inout pad);
// module chip(inout pad); assign pad =
assign pad = 1'bz;
endmodule"""
        self.assertEqual(1, len(self.violations(body)))

    def test_multiple_assignment_internal_net_not_exempted(self):
        body = "module chip(inout pad); wire n; assign pad = 1'b0, n = 1'bz; endmodule"
        self.assertEqual(1, len(self.violations(body)))

    def test_ip_entry_forwards_ssot_top(self):
        with tempfile.TemporaryDirectory() as directory:
            ip = Path(directory)
            (ip / "chip.v").write_text("module chip(inout pad); assign pad = 1'bz; endmodule")
            rules = check_style.check_ip(ip, ["chip.v"], top="chip")
            self.assertFalse(any(v[2] == "RTL-34" for v in rules))
            rules = check_style.check_ip(ip, ["chip.v"], top="other")
            self.assertEqual(1, sum(v[2] == "RTL-34" for v in rules))


if __name__ == "__main__":
    unittest.main()
