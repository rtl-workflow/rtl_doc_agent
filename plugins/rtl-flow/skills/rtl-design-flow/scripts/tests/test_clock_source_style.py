"""RTL-43 / RTL-44: clocks and async resets must come straight from a scalar input port."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_style

RULES = {"RTL-43", "RTL-44"}


class ClockSourceStyleTests(unittest.TestCase):
    def violations(self, body, reset_names=None):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "m.v"
            path.write_text(body, encoding="utf-8")
            return [v for v in check_style.check_file(path, path.name, reset_names=reset_names)
                    if v[2] in RULES]

    def test_inverted_chip_select_used_as_clock(self):
        body = """module spi_slv(input cs_n, input mosi, output reg [7:0] shreg);
wire cs_clock;
assign cs_clock = !cs_n;
always @(posedge cs_clock) begin
    shreg <= #`U_DLY {shreg[6:0], mosi};
end
endmodule"""
        vs = self.violations(body)
        self.assertEqual(1, len(vs))
        self.assertEqual("RTL-43", vs[0][2])
        self.assertIn("cs_clock", vs[0][3])
        self.assertEqual(4, vs[0][1])  # line of the always block

    def test_input_clock_and_reset_pass(self):
        body = """module ok(input clk, input rst, input d, output reg q);
always @(posedge clk or `RST_EDGE rst) begin
    if (rst == `RST_ACT) begin
        q <= #`U_DLY 1'b0;
    end
    else begin
        q <= #`U_DLY d;
    end
end
endmodule"""
        self.assertEqual([], self.violations(body, reset_names=["rst"]))

    def test_negedge_of_input_port_passes(self):
        body = """module ok(input sck, input d, output reg q);
always @(negedge sck) q <= #`U_DLY d;
endmodule"""
        self.assertEqual([], self.violations(body))

    def test_non_ansi_input_clock_passes(self):
        body = """module ok(clk, d, q);
input clk;
input d;
output reg q;
always @(posedge clk) q <= #`U_DLY d;
endmodule"""
        self.assertEqual([], self.violations(body))

    def test_divided_register_clock(self):
        body = """module div(input clk, input d, output reg q);
reg clk_div;
always @(posedge clk) clk_div <= #`U_DLY ~clk_div;
always @(posedge clk_div) q <= #`U_DLY d;
endmodule"""
        vs = self.violations(body)
        self.assertEqual(["RTL-43"], [v[2] for v in vs])

    def test_gated_or_generated_reset(self):
        body = """module gr(input clk, input rst, input soft, input d, output reg q);
wire rst_all;
assign rst_all = rst & soft;
always @(posedge clk or `RST_EDGE rst_all) begin
    if (rst_all == `RST_ACT) begin
        q <= #`U_DLY 1'b0;
    end
    else begin
        q <= #`U_DLY d;
    end
end
endmodule"""
        vs = self.violations(body, reset_names=["rst"])
        self.assertEqual(1, len(vs))
        self.assertIn("async reset", vs[0][3])

    def test_expression_and_vector_clock(self):
        body = """module bad(input [1:0] clks, input a, input b, input d, output reg q, output reg r);
always @(posedge (a & b)) q <= #`U_DLY d;
always @(posedge clks[0]) r <= #`U_DLY d;
endmodule"""
        self.assertEqual(["RTL-43", "RTL-44"], sorted(v[2] for v in self.violations(body)))

    def test_output_port_used_as_clock(self):
        body = """module fb(input clk, input d, output reg clk_o, output reg q);
always @(posedge clk) clk_o <= #`U_DLY ~clk_o;
always @(posedge clk_o) q <= #`U_DLY d;
endmodule"""
        vs = self.violations(body)
        self.assertEqual(1, len(vs))
        self.assertIn("output port", vs[0][3])

    def test_comment_cannot_hide_or_create_violation(self):
        body = """module ok(input clk, input d, output reg q);
// always @(posedge internal_clk)
always @(posedge clk) q <= #`U_DLY d;
endmodule"""
        self.assertEqual([], self.violations(body))


class ClockSourceWaiverTests(unittest.TestCase):
    CLKGEN = """`timescale 1ns / 1ps
// Module name : clk_gen
// Function    : clock divider
// Version     : 1.0
// Date        : 2026-11-13
module clk_gen(input clk, input d, output reg q);
reg clk_div;
always @(posedge clk) clk_div <= #`U_DLY ~clk_div;
always @(posedge clk_div) q <= #`U_DLY d;
endmodule
"""

    def run_ip(self, waivers):
        with tempfile.TemporaryDirectory() as directory:
            ip = Path(directory)
            (ip / "rtl").mkdir()
            (ip / "data").mkdir()
            (ip / "rtl" / "clk_gen.v").write_text(self.CLKGEN, encoding="utf-8")
            if waivers is not None:
                (ip / check_style.WAIVER_FILE).write_text(waivers, encoding="utf-8")
            return [v for v in check_style.check_ip(ip, ["rtl/clk_gen.v"]) if v[2] in RULES]

    def test_no_waiver_is_error(self):
        self.assertEqual(1, len(self.run_ip(None)))

    def test_module_waiver_with_reason(self):
        self.assertEqual([], self.run_ip("RTL-43 clk_gen dedicated clock generation module, DEC-012\n"))

    def test_waiver_for_other_module_does_not_apply(self):
        self.assertEqual(1, len(self.run_ip("RTL-43 other_mod dedicated clock generation module\n")))

    def test_project_wide_or_reasonless_waiver_rejected(self):
        self.assertEqual(1, len(self.run_ip("RTL-43 clk_gen\n")))
        self.assertEqual(1, len(self.run_ip("RTL-43\n")))


if __name__ == "__main__":
    unittest.main()
