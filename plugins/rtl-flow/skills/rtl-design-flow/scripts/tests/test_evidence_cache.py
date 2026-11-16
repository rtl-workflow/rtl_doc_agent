"""Cache compatibility and review invalidation for optional evidence contracts."""
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import flow
import dv_review


class EvidenceCacheTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.ip = Path(self.temp.name).resolve()
        self.base = dict(rtl_sha256='rtl', tb_sha256='tb', tests_sha256='tests')

    def current(self, stub, recorded, expected, damage=None):
        path = self.ip / (flow.run_regress.STUB_REPORT if stub else flow.run_regress.REPORT)
        path.parent.mkdir(parents=True, exist_ok=True)
        report = dict(self.base, mode='stub' if stub else 'rtl')
        report.update(recorded)
        if recorded.get('evidence_sha256', 'absent') != 'absent':
            report['evidence'] = flow.run_regress.evidence.begin(self.ip, stub, False)
            flow.run_regress.evidence.save(self.ip, report['evidence'], 'compile.log', b'original log')
        text = json.dumps(report)
        path.write_text(text, encoding='utf-8')
        if report.get('evidence'):
            flow.run_regress.evidence.archive_result(self.ip, report, text)
            root = self.ip / report['evidence']['path']
            if damage == 'tamper':
                (root / 'compile.log').write_text('tampered', encoding='utf-8')
            elif damage == 'missing':
                (root / 'manifest.json').unlink()
        with patch.object(flow.gen_docs, 'outputs', return_value=({}, [], [])), \
             patch.object(flow.run_regress, 'digests', return_value=dict(self.base, evidence_sha256=expected)):
            return (flow.stub_current if stub else flow.regress_current)(self.ip)

    def test_old_reports_remain_current_without_contract(self):
        for stub in (False, True):
            self.assertIsNotNone(self.current(stub, {}, 'absent'))

    def test_added_changed_removed_contract_invalidates_both_modes(self):
        for stub in (False, True):
            for recorded, expected in (({}, 'new'), ({'evidence_sha256': 'old'}, 'new'),
                                       ({'evidence_sha256': 'old'}, 'absent')):
                with self.subTest(stub=stub, recorded=recorded, expected=expected):
                    self.assertIsNone(self.current(stub, recorded, expected))

    def test_identical_contract_keeps_cache(self):
        for stub in (False, True):
            self.assertIsNotNone(self.current(stub, {'evidence_sha256': 'same'}, 'same'))

    def test_malformed_archive_record_is_rejected(self):
        with self.assertRaises(ValueError):
            flow.run_regress.evidence.verify_archive(self.ip, {'evidence': {'files': []}}, None, self.ip / 'unused')

    def test_missing_or_tampered_archive_invalidates_cache(self):
        for stub in (False, True):
            for damage in ('tamper', 'missing'):
                with self.subTest(stub=stub, damage=damage):
                    self.assertIsNone(self.current(stub, {'evidence_sha256': 'same'}, 'same', damage))

    def test_enabled_plan_and_data_changes_invalidate_both_modes(self):
        for stub in (False, True):
            for key in ('plan_sha256', 'data_sha256'):
                with self.subTest(stub=stub, key=key):
                    self.base[key] = 'new'
                    try:
                        self.assertIsNone(self.current(stub, {key: 'old', 'evidence_sha256': 'same'}, 'same'))
                    finally:
                        self.base.pop(key)

    def test_evidence_contract_changes_reopen_dv_review(self):
        (self.ip / 'dv').mkdir()
        path = self.ip / 'dv/evidence.json'
        before = dv_review.fingerprint(self.ip)
        path.write_text('{"schema_version":1}', encoding='utf-8')
        after = dv_review.fingerprint(self.ip)
        self.assertNotEqual(before, after)
        path.write_text('{"schema_version":2}', encoding='utf-8')
        self.assertNotEqual(after, dv_review.fingerprint(self.ip))


if __name__ == '__main__':
    unittest.main()
