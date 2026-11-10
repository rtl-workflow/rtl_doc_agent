import sys
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import flow
import dv_review
import importlib.util

spec = importlib.util.spec_from_file_location('flow_hook', Path(flow.SKILL).parents[1] / 'hooks' / 'flow_hook.py')
hook = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hook)


class VerificationReviewTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.ip = Path(self.tmp.name) / 'Demo'
        flow.cmd_init(Namespace(ip_dir=self.ip, input=[], auto=False))
        (self.ip / 'dv' / 'tb').mkdir(parents=True, exist_ok=True)
        self.tb = self.ip / 'dv' / 'tb' / 'Demo_tb.v'
        self.tb.write_text('module Demo_tb; endmodule\n')
        self.st = flow.load(self.ip)
        self.st['stage'] = 'REGRESS'

    def review(self):
        self.assertIsNone(flow.step(self.ip, self.st))
        action = flow.step(self.ip, self.st)
        self.assertEqual('review', action['action'])
        self.assertIn('G3', action['gates'])
        flow.save(self.ip, self.st)

    def approve(self):
        flow.cmd_review(Namespace(ip_dir=self.ip, changes=None, reviewer='Reviewer'))
        self.st = flow.load(self.ip)

    def test_manual_gate_blocks_regression_until_approved(self):
        with patch.object(flow.run_regress, 'run', side_effect=AssertionError('premature regression')):
            self.review()
            self.approve()
            self.assertTrue(flow.gate_valid(self.ip, self.st, 'G3'))
            self.assertIsNone(flow.step(self.ip, self.st))
            self.assertEqual('REGRESS', self.st['stage'])

    def test_auto_cannot_skip(self):
        self.st['mode'] = 'auto'
        self.review()
        flow.set_front_matter(self.ip, '07_dv_plan', approved='skipped')
        self.assertFalse(flow.gate_valid(self.ip, self.st, 'G3'))

    def test_changed_stimulus_reopens_even_without_version_bump(self):
        self.review()
        self.approve()
        flow.step(self.ip, self.st)
        self.tb.write_text('module Demo_tb; initial begin end endmodule\n')
        self.review()

    def test_changed_during_review_cannot_be_approved(self):
        self.review()
        self.tb.write_text('// changed stimulus\n')
        with self.assertRaisesRegex(SystemExit, 'content changed'):
            self.approve()

    def test_changes_dispatch_tb_and_require_review_again(self):
        self.review()
        note = self.ip / '.flow' / 'reviews' / 'comments.md'
        note.write_text('Add reset boundary stimulus')
        flow.cmd_review(Namespace(ip_dir=self.ip, changes=str(note), reviewer=None))
        self.st = flow.load(self.ip)
        result = flow.step(self.ip, self.st)
        self.assertEqual('dispatch', result['action'])
        self.assertEqual('rtl-flow:tb-engineer', result['agents'][0]['subagent_type'])
        self.assertIn('review_fix', result['agents'][0]['description'])
        self.assertFalse(flow.gate_valid(self.ip, self.st, 'G3'))

    def test_build_outputs_do_not_invalidate_review(self):
        before = dv_review.fingerprint(self.ip)
        build = self.ip / 'dv' / 'build'
        build.mkdir(exist_ok=True)
        (build / 'sim.log').write_text('simulation output')
        self.assertEqual(before, dv_review.fingerprint(self.ip))

    def test_legacy_done_requires_review(self):
        self.st['stage'] = 'DONE'
        self.review()

    def test_review_fields_are_guarded(self):
        self.assertIn('doc/07_dv_plan.md', hook.REVIEWED)
        self.assertEqual({'approved_dv_digest': 'abc'},
                         hook.review_fields('---\napproved_dv_digest: abc\n---\n'))

    def test_implementation_enters_g3(self):
        self.st['stage'] = 'BUILD'
        self.st['pending'] = [{'id': 'tb', 'role': 'tb-engineer', 'kind': 'tb'}]
        with patch.object(flow, 'read_handoff', return_value={'status': 'done'}), \
             patch.object(flow, 'deferred', return_value=False), \
             patch.object(flow.remote_exec, 'enabled', return_value=False), \
             patch.object(flow, 'impl_problems', return_value={}):
            self.assertIsNone(flow.collect(self.ip, self.st))
        self.assertEqual('REVIEW', self.st['stage'])
        self.assertEqual(['G3'], self.st['review']['gates'])


if __name__ == '__main__':
    unittest.main()
