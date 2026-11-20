"""Geometry regressions: routing guarantees, not snapshots of implementation."""
import copy
import json
from html.parser import HTMLParser
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from arch_layout import layout, wrap_text


def node(identifier, layer=0, **kwargs):
    result = dict(id=identifier, name=identifier, role='Process data', group='IP', layer=layer)
    result.update(kwargs)
    return result


def edge(source, target, label='valid / ready'):
    return {'from': source, 'to': target, 'kind': 'data', 'label': label}


def intersects_interior(a, b, rect):
    x, y, w, h = rect
    if a[0] == b[0]:
        return x < a[0] < x + w and max(min(a[1], b[1]), y) < min(max(a[1], b[1]), y + h)
    return y < a[1] < y + h and max(min(a[0], b[0]), x) < min(max(a[0], b[0]), x + w)


def assert_parallel_clearance(test, a, b, c, d):
    for axis in (0, 1):
        if a[axis] != b[axis] or c[axis] != d[axis]:
            continue
        along = 1 - axis
        lo, hi = sorted((a[along], b[along]))
        other_lo, other_hi = sorted((c[along], d[along]))
        if max(lo, other_lo) < min(hi, other_hi):
            test.assertGreaterEqual(abs(a[axis] - c[axis]), 4,
                                    f'parallel segments {a, b} and {c, d} need 2px of visible space')


class ArchitectureLayoutTests(unittest.TestCase):
    def assert_geometry(self, nodes, edges, result=None):
        result = layout(nodes, edges) if result is None else result
        cards, routes = result['nodes'], result['edges']
        self.assertEqual(set(cards), {n['id'] for n in nodes})
        self.assertEqual(len(routes), len(edges))
        width, height = result['width'], result['height']
        all_segments = []
        ports = set()
        badges = []
        for card in cards.values():
            self.assertGreaterEqual(card['x'], 0)
            self.assertGreaterEqual(card['y'], 0)
            self.assertLessEqual(card['x'] + card['width'], width)
            self.assertLessEqual(card['y'] + card['height'], height)
        for i, (edge_data, route) in enumerate(zip(edges, routes)):
            points = route['points']
            self.assertGreaterEqual(len(points), 2)
            self.assertEqual(points[0], route['source_port'])
            self.assertEqual(points[-1], route['target_port'])
            for key, endpoint, right in (('source_port', 'from', True), ('target_port', 'to', False)):
                px, py = route[key]
                card = cards[edge_data[endpoint]]
                self.assertEqual(px, card['x'] + (card['width'] if right else 0))
                self.assertTrue(card['y'] < py < card['y'] + card['height'])
                self.assertNotIn((px, py), ports, 'incident ports must be separate')
                ports.add((px, py))
            bx, by, bw, bh = route['badge']
            self.assertGreaterEqual(bx, 0)
            self.assertGreaterEqual(by, 0)
            self.assertLessEqual(bx + bw, width)
            self.assertLessEqual(by + bh, height)
            for card in cards.values():
                self.assertFalse(bx < card['x'] + card['width'] and card['x'] < bx + bw and
                                 by < card['y'] + card['height'] and card['y'] < by + bh,
                                 'badge intersects card')
            for x, y, w, h in badges:
                self.assertFalse(bx < x + w and x < bx + bw and by < y + h and y < by + bh,
                                 'badges overlap')
            badges.append(route['badge'])
            for a, b in zip(points, points[1:]):
                self.assertNotEqual(a, b, 'zero-length segment')
                self.assertTrue(a[0] == b[0] or a[1] == b[1], 'nonorthogonal segment')
                for px, py in (a, b):
                    self.assertTrue(0 <= px <= width and 0 <= py <= height, 'route outside canvas')
                for card in cards.values():
                    rect = (card['x'], card['y'], card['width'], card['height'])
                    self.assertFalse(intersects_interior(a, b, rect), 'route through card including endpoint')
                for j, other in enumerate(routes):
                    # Own badge masks a source stub in SVG; all other badges are obstacles.
                    if i != j:
                        self.assertFalse(intersects_interior(a, b, other['badge']), 'route through another badge')
                all_segments.append((i, a, b))
        for index, (i, a, b) in enumerate(all_segments):
            for j, c, d in all_segments[index + 1:]:
                if i != j:
                    assert_parallel_clearance(self, a, b, c, d)
        return result

    def test_adjacent_forward_is_compact_and_deterministic(self):
        nodes, edges = [node('a'), node('b', 1)], [edge('a', 'b')]
        before = copy.deepcopy((nodes, edges))
        result = self.assert_geometry(nodes, edges)
        self.assertEqual(result, layout(nodes, edges))
        self.assertEqual(before, (nodes, edges), 'layout must not mutate schema data')
        self.assertEqual(len(result['edges'][0]['points']), 2)
        self.assertLess(result['width'], 800)
        self.assertLess(result['height'], 220)

    def test_parallel_edges_use_separate_ports_and_tracks(self):
        nodes = [node('a'), node('b', 1)]
        edges = [edge('a', 'b', str(i)) for i in range(12)]
        result = self.assert_geometry(nodes, edges)
        self.assertGreater(result['nodes']['a']['height'], 300)
        self.assertEqual(len({tuple(r['points']) for r in result['edges']}), 12)

    def test_parallel_strokes_near_feedback_and_self_loops(self):
        nodes = [node('A'), node('B'), node('C', 1)]
        edges = [edge(source, target) for source, target in
                 ('CC', 'BA', 'CB', 'CA', 'BA', 'CC', 'CB', 'AA')]
        self.assert_geometry(nodes, edges)

    def test_same_layer_feedback_and_multiple_selfloops(self):
        nodes = [node('a'), node('b'), node('c', 1), node('d', 1)]
        edges = [edge('a', 'b'), edge('b', 'a'), edge('c', 'a'), edge('d', 'b'),
                 edge('a', 'a'), edge('a', 'a'), edge('a', 'c'), edge('b', 'd')]
        self.assert_geometry(nodes, edges)

    def test_skip_layer_avoids_intermediate_cards(self):
        nodes = [node('left'), node('middle', 1), node('middle2', 1), node('right', 2)]
        edges = [edge('left', 'right'), edge('right', 'left'), edge('left', 'middle2'),
                 edge('middle', 'right'), edge('middle2', 'middle')]
        self.assert_geometry(nodes, edges)

    def test_dense_mixed_topology(self):
        nodes = [node('n%d' % i, i % 4) for i in range(12)]
        edges = [edge('n0', 'n%d' % i) for i in range(1, 12)]
        edges += [edge('n%d' % i, 'n%d' % ((i * 5 + 1) % 12)) for i in range(12)]
        edges += [edge('n0', 'n1'), edge('n1', 'n0'), edge('n2', 'n2'), edge('n2', 'n2')]
        result = self.assert_geometry(nodes, edges)
        self.assertEqual(result, layout(nodes, edges))
        # Routing uses gutters near cards instead of assigning every edge a bottom lane.
        bottom = max(c['y'] + c['height'] for c in result['nodes'].values())
        self.assertLess(result['height'] - bottom, len(edges) * 12)

    def test_sparse_manual_layers_and_input_row_order(self):
        nodes = [node('z', 20), node('b', 0), node('a', 0), node('m', 9)]
        result = self.assert_geometry(nodes, [edge('a', 'z'), edge('z', 'm'), edge('m', 'b')])
        cards = result['nodes']
        self.assertLess(cards['b']['x'], cards['m']['x'])
        self.assertLess(cards['m']['x'], cards['z']['x'])
        self.assertLess(cards['b']['y'], cards['a']['y'])
        self.assertEqual(cards['z']['layer'], 20)
        self.assertLess(result['width'], 1600)

    def test_single_node_and_long_wrapped_text(self):
        name = 'VeryLongOriginalModuleName_' * 9
        role = '跨时钟域处理与数据同步' * 12
        group = 'group\nwith a second line'
        result = self.assert_geometry([node('only', name=name, role=role, group=group)], [])
        card = result['nodes']['only']
        self.assertEqual(''.join(t for s, t in card['lines'] if s == 'name'), name)
        self.assertEqual(''.join(t for s, t in card['lines'] if s == 'role'), role)
        self.assertGreater(card['height'], 160)
        self.assertGreaterEqual(card['height'], 32 + 22 * len(card['lines']))
        self.assertEqual(wrap_text('中文' * 16), ['中文' * 7 + '中', '文' + '中文' * 7, '中文'])


class ArchitectureSchemaTests(unittest.TestCase):
    def render(self, graph):
        import gen_arch
        return gen_arch.render('```architecture-graph\n' + json.dumps(graph) + '\n```\n')

    def test_malformed_shapes_raise_valueerror(self):
        valid = {'nodes': [node('a')], 'edges': []}
        variants = [None, [], {}, {'nodes': None, 'edges': []},
                    {'nodes': [None], 'edges': []}, {'nodes': {}, 'edges': []},
                    {'nodes': [node('a')], 'edges': None},
                    {'nodes': [node('a')], 'edges': [None]},
                    {'nodes': [node('a'), node('a')], 'edges': []}]
        for field, value in [('id', []), ('name', None), ('role', ' '), ('group', 1),
                             ('layer', True), ('layer', -1), ('layer', 21)]:
            graph = copy.deepcopy(valid)
            graph['nodes'][0][field] = value
            variants.append(graph)
        for field, value in [('from', []), ('to', {}), ('label', 12), ('label', ' '),
                             ('kind', None), ('kind', []), ('kind', 'unknown')]:
            graph = copy.deepcopy(valid)
            graph['edges'] = [edge('a', 'a')]
            graph['edges'][0][field] = value
            variants.append(graph)
        for field in ('title', 'summary'):
            graph = copy.deepcopy(valid)
            graph[field] = []
            variants.append(graph)
        for graph in variants:
            with self.subTest(graph=graph):
                with self.assertRaises(ValueError):
                    self.render(graph)

    def test_html_like_values_cannot_create_markup(self):
        attack = '<script>alert("x")</script><img src=x onerror="alert(1)">'
        graph = {'title': attack, 'summary': attack,
                 'nodes': [node(attack, name=attack, role=attack, group=attack)],
                 'edges': [edge(attack, attack, attack)]}
        output = self.render(graph)
        class Tags(HTMLParser):
            def __init__(self):
                super().__init__()
                self.tags, self.attrs = [], []
            def handle_starttag(self, tag, attrs):
                self.tags.append(tag)
                self.attrs.extend(attrs)
        parsed = Tags()
        parsed.feed(output)
        self.assertNotIn('script', parsed.tags)
        self.assertNotIn('img', parsed.tags)
        self.assertFalse(any(k.startswith('on') for k, v in parsed.attrs))
        self.assertIn('&lt;script&gt;', output)
        self.assertNotIn('foreignobject', parsed.tags)
        self.assertIn('architecture-source-sha256:', output)

    def test_rendered_stroke_leaves_badge_interior_clear(self):
        import re
        graph = {'nodes': [node('a'), node('b', 1)], 'edges': [edge('a', 'b')]}
        geometry = layout(graph['nodes'], graph['edges'])
        output = self.render(graph)
        path = re.search(r'<path data-edge="1" d="([^"]+)"', output).group(1)
        coordinates = [tuple(map(int, pair)) for pair in re.findall(r'[ML](-?\d+),(-?\d+)', path)]
        badge = geometry['edges'][0]['badge']
        for a, b in zip(coordinates, coordinates[1:]):
            self.assertFalse(intersects_interior(a, b, badge))


if __name__ == '__main__':
    unittest.main()
