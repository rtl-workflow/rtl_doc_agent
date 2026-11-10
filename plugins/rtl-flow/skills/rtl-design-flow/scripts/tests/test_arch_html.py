import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path
from argparse import Namespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import gen_arch
import check_docs
import flow


class ArchitectureHtmlTests(unittest.TestCase):
    def setUp(self):
        self.graph = {'title': 'OriginalIP', 'summary': '输入到处理', 'nodes': [
            {'id': 'host', 'name': 'Host', 'role': 'External input', 'group': 'External', 'layer': 0},
            {'id': 'core', 'name': 'OriginalCore', 'role': 'Process <data>', 'group': 'IP / PCLK', 'layer': 1}],
            'edges': [{'from': 'host', 'to': 'core', 'kind': 'data', 'label': 'Data[31:0] & valid'}]}

    def source(self, graph=None):
        return ('---\nversion: 0.1\nstatus: Draft\n---\n## 1. 图\n```architecture-graph\n'
                + json.dumps(self.graph if graph is None else graph) + '\n```\n'
                '## 2. 子模块划分 (Sub-modules)\n\n| 子模块 | 实例名 | 职责 | 关键接口 |\n'
                '|---|---|---|---|\n| `OriginalCore` | `U_Core` | Process | Data |\n')

    def test_offline_graph_and_escaped_labels(self):
        output = gen_arch.render(self.source())
        for fragment in ('<svg', 'marker-end=', 'OriginalCore', 'Data[31:0] &amp; valid', 'Process &lt;data&gt;'):
            self.assertIn(fragment, output)
        self.assertNotIn('<script', output)
        self.assertNotIn('cdn', output)

    def test_invalid_endpoint_and_missing_module(self):
        graph = copy.deepcopy(self.graph)
        graph['edges'][0]['to'] = 'unknown'
        with self.assertRaisesRegex(ValueError, 'endpoint'):
            gen_arch.render(self.source(graph))
        graph = copy.deepcopy(self.graph)
        graph['nodes'][1]['name'] = 'RenamedCore'
        with self.assertRaisesRegex(ValueError, 'missing from graph'):
            gen_arch.render(self.source(graph))

    def test_body_change_invalidates_but_review_metadata_does_not(self):
        source = self.source()
        self.assertEqual(gen_arch.render(source), gen_arch.render(source.replace('status: Draft', 'status: Review\napproved: 0.1@2026-11-10')))
        self.assertNotEqual(gen_arch.render(source), gen_arch.render(source + '\nMore architecture detail\n'))

    def test_check_docs_rejects_missing_and_stale_html(self):
        with tempfile.TemporaryDirectory() as tmp:
            ip = Path(tmp) / 'OriginalIP'
            flow.cmd_init(Namespace(ip_dir=ip, input=[], auto=False))
            doc = ip / 'doc' / '02_architecture.md'
            doc.write_text(self.source(), encoding='utf-8')
            def errors():
                return [m for w, m in check_docs.run_checks(ip, 'arch').errors() if 'architecture HTML' in m]
            self.assertTrue(errors())
            output = ip / gen_arch.OUTPUT
            output.write_text(gen_arch.expected(ip), encoding='utf-8')
            self.assertFalse(errors())
            doc.write_text(self.source() + '\nChanged detail\n', encoding='utf-8')
            self.assertTrue(errors())


if __name__ == '__main__':
    unittest.main()
