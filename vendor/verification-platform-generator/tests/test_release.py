import json
from pathlib import Path
import tempfile
import unittest
import zipfile
from agent.release import build, verify, collect


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / 'src'
        (self.root / 'agent').mkdir(parents=True)
        (self.root / 'SKILL.md').write_text('entry', encoding='utf-8')
        registry = {'schema_version': 'verification-agent-registry/v1',
                    'execution_model': 'host_agent_assisted', 'entrypoint': 'SKILL.md',
                    'required_documents': ['SKILL.md'],
                    'capabilities': [{'id': 'one', 'entrypoint': 'SKILL.md',
                                      'kind': 'subskill', 'status': 'agent_assisted', 'depends_on': []}]}
        (self.root / 'agent/registry.json').write_text(json.dumps(registry), encoding='utf-8')
        self.meta = {'name': 'agent', 'version': '1.0-rc.1', 'license_status': 'unresolved',
                     'public_release_ready': False, 'include_roots': ['SKILL.md', 'agent', 'release.json']}
        self.save_meta()

    def save_meta(self):
        (self.root / 'release.json').write_text(json.dumps(self.meta), encoding='utf-8')

    def test_deterministic_round_trip(self):
        first = build(self.root, self.base / 'a')
        second = build(self.root, self.base / 'b')
        self.assertEqual(first['sha256'], second['sha256'])
        self.assertFalse(first['public_release_ready'])
        self.assertEqual(verify(first['archive'])['status'], 'pass')

    def test_no_output_inside_source_or_overwrite(self):
        with self.assertRaises(ValueError): build(self.root, self.root / 'dist')
        first = build(self.root, self.base / 'a')
        old = Path(first['archive']).read_bytes()
        with self.assertRaises(FileExistsError): build(self.root, self.base / 'a')
        self.assertEqual(Path(first['archive']).read_bytes(), old)

    def test_excludes_caches(self):
        cache = self.root / 'agent/__pycache__'
        cache.mkdir()
        (cache / 'old.pyc').write_bytes(b'old')
        _, files = collect(self.root)
        self.assertNotIn('agent/__pycache__/old.pyc', files)

    def test_broken_link_or_escaping_whitelist_fails(self):
        (self.root / 'SKILL.md').write_text('[missing](../outside.md)', encoding='utf-8')
        with self.assertRaises(ValueError): collect(self.root)
        self.meta['include_roots'] = ['../outside']
        self.save_meta()
        with self.assertRaises(ValueError): collect(self.root)

    def test_extra_zip_entry_is_rejected(self):
        result = build(self.root, self.base / 'a')
        with zipfile.ZipFile(result['archive'], 'a') as z:
            z.writestr('agent-1.0-rc.1/unlisted.txt', 'unexpected')
        with self.assertRaises(ValueError): verify(result['archive'])

    def test_modified_file_is_rejected(self):
        result = build(self.root, self.base / 'a')
        corrupt = self.base / 'corrupt.zip'
        with zipfile.ZipFile(result['archive']) as src, zipfile.ZipFile(corrupt, 'w') as dst:
            for name in src.namelist():
                data = b'changed' if name.endswith('/SKILL.md') else src.read(name)
                dst.writestr(name, data)
        with self.assertRaises(ValueError): verify(corrupt)


if __name__ == '__main__':
    unittest.main()
