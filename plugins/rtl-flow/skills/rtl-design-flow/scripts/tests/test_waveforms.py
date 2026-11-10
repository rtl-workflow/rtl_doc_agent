import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import run_regress as regress
import remote_exec
import open_verdi


class WaveformTests(unittest.TestCase):
    def test_script(self):
        text = regress.wave_script('timer_tb', 'tc_read_2.fsdb')
        self.assertIn('dump -file tc_read_2.fsdb -type FSDB', text)
        self.assertIn('/timer_tb -depth 99 -aggregates', text)
        self.assertTrue(text.endswith('run\nquit\n'))
        with self.assertRaises(ValueError):
            regress.wave_script('tb;quit', 'x.fsdb')
        with self.assertRaises(ValueError):
            regress.wave_script('tb', '../x.fsdb')

    def test_remote_options(self):
        args, _, files = regress.remote_job(False, 'tc_read', 2, False)
        self.assertIn('--no-fsdb', args)
        self.assertNotIn('reports/regress.json', files)
        # Large waves stay remote; logs/manifest come back.
        self.assertFalse(any('.fsdb' in f for f in files))

    def test_keep_wave_workspace(self):
        class Remote:
            cfg = {'python': 'python3'}
        for args, cleanup in [([], False), (['--no-fsdb'], True), (['--stub'], True)]:
            with patch.object(remote_exec, 'submit', return_value=('job', {}, {})) as submit:
                with patch.dict(remote_exec.os.environ, {'RTLFLOW_REMOTE_KEEP': '0'}):
                    remote_exec._start_ip_job(Remote(), 'run_regress.py', Path('ip'), args, [], 10)
                self.assertEqual(submit.call_args.kwargs['cleanup'], cleanup)

    def test_missing_wave_cannot_pass(self):
        with tempfile.TemporaryDirectory() as temp:
            res = {'tests': [{'status': 'PASSED'}], 'problems': ['FSDB missing or empty'],
                   'cover': {'a': 1}, 'uncovered': []}
            self.assertEqual(regress.finish(Path(temp), res, False)['result'], 'FAIL')

    def test_stub_constants(self):
        self.assertEqual(regress.verilog_param_value('0x00000001'), '1')
        self.assertEqual(regress.verilog_param_value("32'h1234"), "32'h1234")

    def test_verdi_failure_record(self):
        with patch.object(open_verdi, 'launch', side_effect=RuntimeError('no display')):
            result = open_verdi.launch_record('x.fsdb', 'simv.daidir')
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(result['error'], 'no display')


if __name__ == '__main__':
    unittest.main()
