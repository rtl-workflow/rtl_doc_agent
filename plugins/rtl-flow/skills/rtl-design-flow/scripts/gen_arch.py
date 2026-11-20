#!/usr/bin/env python3
"""Generate an offline HTML architecture diagram from 02's architecture-graph JSON."""
import argparse
import hashlib
import html
import json
import re
from pathlib import Path

from arch_layout import layout

OUTPUT = 'doc/02_architecture.html'


def render(text):
    blocks = re.findall(r'```architecture-graph\s*\n(.*?)```', text, re.S)
    if len(blocks) != 1:
        raise ValueError('02 must contain exactly one architecture-graph JSON block')
    graph = json.loads(blocks[0])
    if not isinstance(graph, dict):
        raise ValueError('architecture graph must be an object')
    nodes, edges = graph.get('nodes'), graph.get('edges')
    if not isinstance(nodes, list) or not nodes:
        raise ValueError('architecture graph needs a nonempty nodes list')
    if not isinstance(edges, list):
        raise ValueError('architecture graph needs an edges list')
    for key in ('title', 'summary'):
        if key in graph and not isinstance(graph[key], str):
            raise ValueError('graph ' + key + ' must be text')
    ids = set()
    for n in nodes:
        if not isinstance(n, dict) or not all(isinstance(n.get(k), str) and n[k].strip()
                                              for k in ('id', 'name', 'role', 'group')):
            raise ValueError('each node needs nonempty id/name/role/group')
        if n['id'] in ids:
            raise ValueError('duplicate node id: ' + n['id'])
        ids.add(n['id'])
        if type(n.get('layer')) is not int or not 0 <= n['layer'] <= 20:
            raise ValueError('node layer must be an integer between 0 and 20')
    if len(nodes) > 1 and not edges:
        raise ValueError('multi-node graph needs explicit relationships')
    for e in edges:
        if not isinstance(e, dict):
            raise ValueError('each edge must be an object')
        if any(not isinstance(e.get(k), str) or e[k] not in ids for k in ('from', 'to')):
            raise ValueError('edge endpoint not found')
        if (not isinstance(e.get('label'), str) or not e['label'].strip()
                or e.get('kind') not in ('data', 'control', 'clock', 'reset')):
            raise ValueError('edge needs label and kind: data/control/clock/reset')
    import check_docs
    missing = set(check_docs.arch_modules(text)) - {n['name'] for n in nodes}
    if missing:
        raise ValueError('modules missing from graph: ' + ', '.join(sorted(missing)))
    esc = lambda value: html.escape(str(value), quote=True)
    colors = {'data': '#2563eb', 'control': '#b45309', 'clock': '#7c3aed', 'reset': '#dc2626'}
    geometry = layout(nodes, edges)
    width, height = geometry['width'], geometry['height']
    svg = [f'<svg viewBox="0 0 {width} {height}" width="{width}" height="{height}" role="img" aria-label="系统模块关系图">',
           '<defs>' + ''.join(f'<marker id="{k}" markerUnits="userSpaceOnUse" markerWidth="10" markerHeight="8" refX="10" refY="4" orient="auto"><path d="M0,0 L10,4 L0,8 Z" fill="{v}"/></marker>' for k, v in colors.items()) + '</defs>']
    rows = []
    names = {n['id']: n['name'] for n in nodes}
    for i, (e, route) in enumerate(zip(edges, geometry['edges']), 1):
        color = colors[e['kind']]
        bx, by, bw, bh = route['badge']
        sx, sy = route['source_port']
        points = route['points']
        # The logical centerline passes its own source badge; the visible stroke
        # stops at its left boundary and resumes at its right boundary.
        prefix = f'M{sx},{sy} L{bx},{sy}'
        tail = [(bx + bw, sy)] + points[1:]
        # A simplified first segment may turn before/after the badge: source
        # routing start is guaranteed to be to the right of the badge.
        path = 'M' + ' L'.join(f'{x},{y}' for x, y in tail)
        svg.append(f'<path d="{prefix}" fill="none" stroke="{color}" stroke-width="2"/>')
        svg.append(f'<path data-edge="{i}" d="{path}" fill="none" stroke="{color}" stroke-width="2" marker-end="url(#{e["kind"]})"><title>{esc(str(i) + ". " + e["label"])}</title></path>')
        rows.append(f'<tr><td>{i}</td><td>{esc(names[e["from"]])}</td><td>→ {esc(names[e["to"]])}</td><td>{esc(e["kind"])}</td><td>{esc(e["label"])}</td></tr>')
    for i, (e, route) in enumerate(zip(edges, geometry['edges']), 1):
        bx, by, bw, bh = route['badge']
        color = colors[e['kind']]
        svg.append(f'<g class="edge-label" data-edge="{i}"><title>{esc(e["label"])}</title><rect x="{bx}" y="{by}" width="{bw}" height="{bh}" rx="5" fill="white" stroke="{color}"/><text x="{bx+bw/2}" y="{by+bh/2}" dy="0.35em" text-anchor="middle" fill="{color}">{i}</text></g>')
    for n in nodes:
        card = geometry['nodes'][n['id']]
        x, y, w, h = (card[k] for k in ('x', 'y', 'width', 'height'))
        svg.append(f'<g class="node"><title>{esc(n["name"] + ": " + n["role"])}</title><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12"/>')
        for line, (style, value) in enumerate(card['lines']):
            svg.append(f'<text class="{style}" x="{x+14}" y="{y+26+22*line}">{esc(value)}</text>')
        svg.append('</g>')
    svg.append('</svg>')
    source = re.sub(r'\A---\r?\n.*?\r?\n---\r?\n', '', text, count=1, flags=re.S).replace('\r\n', '\n')
    digest = hashlib.sha256(source.encode('utf-8')).hexdigest()
    title = esc(graph.get('title', '系统微架构'))
    return f'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title><style>
body{{font:16px system-ui,sans-serif;margin:28px;background:#f5f7fb;color:#172033}}h1{{margin-bottom:8px}}
.diagram{{overflow:auto;background:white;border:1px solid #cbd5e1;border-radius:12px}}
svg text{{font:14px ui-monospace,Consolas,monospace;fill:#172033}}.edge-label text{{font-weight:bold}}
.node rect{{fill:#eff6ff;stroke:#64748b;stroke-width:2}}.node .name{{font-weight:bold}}.node .group{{fill:#475569}}
table{{border-collapse:collapse;width:100%;background:white}}td,th{{border:1px solid #cbd5e1;padding:10px;text-align:left;overflow-wrap:anywhere}}
@media print{{.diagram{{overflow:visible}}svg{{width:100%;height:auto}}body{{margin:0}}}}
</style></head><body><h1>{title}</h1><p>{esc(graph.get('summary', ''))}</p>
<p>按左→右阅读；卡片显示原始模块名、职责与所属层次/时钟域。源端编号对应下方接口表，箭头指向目的模块。蓝：数据；棕：控制；紫：时钟；红：复位。线条交叉不表示连接。图可横向滚动，浏览器缩放或打印。</p>
<div class="diagram">{''.join(svg)}</div><h2>模块间接口与方向</h2>
<table><thead><tr><th>编号</th><th>源</th><th>目的</th><th>类型</th><th>接口 / 位宽 / 握手 / CDC说明</th></tr></thead><tbody>{''.join(rows)}</tbody></table>
<p>源文档：<a href="02_architecture.md">02_architecture.md</a> · 离线单文件 · 自动生成，请修改源文档后重新生成。</p>
<!-- architecture-source-sha256: {digest} --></body></html>
'''


def expected(ip):
    return render((ip / 'doc' / '02_architecture.md').read_text(encoding='utf-8'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ip_dir', type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    try:
        content = expected(args.ip_dir)
    except (ValueError, KeyError, TypeError, OSError) as exc:
        parser.exit(1, f'ERROR: {exc}\n')
    output = args.ip_dir / OUTPUT
    if args.check:
        if not output.exists() or output.read_text(encoding='utf-8') != content:
            parser.exit(1, 'ERROR: architecture HTML missing or stale; run gen_arch.py\n')
    else:
        with output.open('w', encoding='utf-8', newline='\n') as stream:
            stream.write(content)
    print(output)


if __name__ == '__main__':
    main()
