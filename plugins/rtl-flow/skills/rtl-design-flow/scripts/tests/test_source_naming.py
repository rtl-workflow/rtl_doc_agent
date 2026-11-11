import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_style
import gen_docs
import flow
from argparse import Namespace


class SourceNamingTests(unittest.TestCase):
    def test_original_file_and_module_names_need_no_exemption(self):
        with tempfile.TemporaryDirectory() as folder:
            file = Path(folder) / 'spi_adapter.v'
            file.write_text('module SPI_WRAP(); endmodule\n')
            def errors(mapping):
                return [x for x in check_style.check_file(file, 'rtl/spi_adapter.v', source_naming=mapping)
                        if x[2] == 'RTL-02']
            self.assertFalse(errors([]))
            self.assertFalse(errors([{'module': 'SPI_WRAP', 'file': 'rtl/spi_adapter.v'}]))
            self.assertFalse(errors([{'module': 'SPI_WRAP', 'file': 'rtl/other.v', 'source': 'raw/a.md'}]))
            self.assertFalse(errors([{'module': 'SPI_WRAP', 'file': 'rtl/spi_adapter.v', 'source': 'raw/a.md §2'}]))

    def test_original_unprefixed_name(self):
        with tempfile.TemporaryDirectory() as folder:
            file = Path(folder) / 'spi_intf_adapt.v'
            file.write_text('module spi_intf_adapt(); endmodule\n')
            self.assertFalse([x for x in check_style.check_file(file, 'rtl/spi_intf_adapt.v')
                               if x[2] in ('RTL-02', 'RTL-10')])

    def test_mixed_case_interface_and_generated_header(self):
        d = dict(name='OriginalIP', version='1.0.0', desc='original names', top='SPI_WRAP',
                 rtl_files=['rtl/define.v', 'rtl/Adapter.v'],
                 clocks=[dict(name='PCLK')],
                 resets=[dict(name='PRESETn', active='low', std_if=True)],
                 params=[dict(name='OriginalParameterLongerThanTwenty', default=32)],
                 ports=[dict(name=n, dir=direction, width=1) for n, direction in
                        [('PCLK', 'input'), ('PRESETn', 'input'), ('DataOut', 'output')]],
                 registers=[dict(name='Control', offset=0, fields=[
                     dict(name='Enable', bits='0', swaccess='rw',
                          enum=[dict(name='On', value=1)])])], _src='OriginalIP.yaml')
        self.assertEqual([], gen_docs.validate(d))
        header = gen_docs.gen_c_header(d)
        self.assertIn('OriginalIP_Control_Enable_VALUE_On', header)
        self.assertNotIn('ORIGINALIP', header)
        d['ports'].append(dict(name='DataOut', dir='output', width=1))
        self.assertTrue(any('duplicate port' in e for e in gen_docs.validate(d)))

    def test_style_preserves_names_but_still_checks_module_count(self):
        with tempfile.TemporaryDirectory() as folder:
            file = Path(folder) / 'OriginalFile.sv'
            file.write_text('module DifferentModule #(parameter OriginalLongParameterName = 1) '
                            '(input PCLK, input PRESETn, output DataOut); endmodule\n')
            rules = [x[2] for x in check_style.check_file(file, file.name)]
            self.assertFalse(set(rules) & {'RTL-02', 'RTL-11', 'RTL-12', 'RTL-13'})
            file.write_text('module A(); endmodule\nmodule B(); endmodule\n')
            self.assertIn('RTL-02', [x[2] for x in check_style.check_file(file, file.name)])

    def test_original_reset_names_still_check_polarity(self):
        code = "always @(posedge PCLK or posedge PRESETn) if (PRESETn == 1'b1) Q <= D;"
        errors = list(check_style.check_resets(code, {'PRESETn': 'low'}))
        self.assertEqual({'RTL-41', 'RTL-42'}, {e[1] for e in errors})
        self.assertFalse(list(check_style.check_resets(
            code.replace('posedge PRESETn', 'negedge PRESETn').replace("1'b1", "1'b0"),
            {'PRESETn': 'low'})))

    def test_init_keeps_ip_case(self):
        with tempfile.TemporaryDirectory() as folder:
            ip = Path(folder) / 'OriginalIP'
            flow.cmd_init(Namespace(ip_dir=ip, input=[], auto=False))
            self.assertTrue((ip / 'data' / 'OriginalIP.yaml').exists())
            self.assertEqual('OriginalIP', gen_docs.load_data(ip / 'data' / 'OriginalIP.yaml')['name'])


if __name__ == '__main__':
    unittest.main()
