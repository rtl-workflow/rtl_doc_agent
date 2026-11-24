"""RTL-42 checks reset conditions using SSOT names, including prefixed ports."""
import sys
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_style
import flow
import gen_docs


class ResetConditionTests(unittest.TestCase):
    def violations(self, name, condition, std=None, reset_names=None):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'probe.v'
            path.write_text(
                f'module probe(input i_clk, input {name}, output reg o_q);\n'
                f'always @(posedge i_clk) if ({condition}) o_q <= #`U_DLY 1\'b0;\n'
                'endmodule\n', encoding='utf-8')
            return [v for v in check_style.check_file(
                path, path.name, std=std, reset_names=reset_names) if v[2] == 'RTL-42']

    def test_ssot_resets_reject_boolean_and_inequality_conditions(self):
        for name, std in [('rst', {}), ('i_rst', {}), ('ResetIn', {}),
                          ('i_PRESETn', {'i_PRESETn': 'low'})]:
            for condition in (name, f'!{name}', f'~{name}', f'{name} != 1\'b0'):
                with self.subTest(name=name, condition=condition):
                    errors = self.violations(name, condition, std, [name])
                    self.assertEqual(1, len(errors))
                    self.assertEqual(2, errors[0][1])

    def test_equality_checks_internal_and_standard_reset_polarity(self):
        for name, std, expected, wrong in [
                ('i_rst', {}, '`RST_ACT', "1'b0"),
                ('i_PRESETn', {'i_PRESETn': 'low'}, "1'b0", "1'b1"),
                ('i_Reset', {'i_Reset': 'high'}, "1'b1", "1'b0")]:
            with self.subTest(name=name):
                self.assertEqual([], self.violations(name, f'{name} == {expected}', std, [name]))
                self.assertEqual(1, len(self.violations(name, f'{name} == {wrong}', std, [name])))

    def test_standalone_fallback_accepts_legacy_and_prefixed_reset_names(self):
        for name in ('rst', 'rst_n', 'i_rst', 'i_rst_sys'):
            with self.subTest(name=name):
                self.assertEqual(1, len(self.violations(name, f'!{name}')))

    def test_ssot_names_do_not_match_unrelated_signals(self):
        for name in ('rst_ready', 'i_rst_done', 'i_ready'):
            with self.subTest(name=name):
                self.assertEqual([], self.violations(name, name, reset_names=['i_rst']))

    def test_initialized_project_checks_default_reset(self):
        with tempfile.TemporaryDirectory() as directory:
            ip = Path(directory) / 'ResetProbe'
            flow.cmd_init(Namespace(ip_dir=ip, input=[], auto=False))
            data = gen_docs.load_data(ip / 'data' / 'ResetProbe.yaml')
            self.assertEqual('i_rst', data['resets'][0]['name'])
            path = ip / 'rtl' / 'ResetProbe.v'
            path.write_text(
                'module ResetProbe(input i_clk, input i_rst, output reg o_q);\n'
                'always @(posedge i_clk or `RST_EDGE i_rst)\n'
                '    if (!i_rst) o_q <= #`U_DLY 1\'b0;\n'
                'endmodule\n', encoding='utf-8')
            errors = check_style.check_ip(ip, data['rtl_files'], data['resets'], top=data['top'])
            self.assertEqual(1, len([v for v in errors if v[2] == 'RTL-42']))


if __name__ == '__main__':
    unittest.main()
