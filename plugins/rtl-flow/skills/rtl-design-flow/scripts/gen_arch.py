#!/usr/bin/env python3
"""Generate an offline HTML architecture diagram from the architecture-graph JSON in 02."""
import argparse
import hashlib
import html
import json
import re
from pathlib import Path

OUTPUT = 'doc/02_architecture.html'


def render(text):
    blocks = re.findall(r'```architecture-graph\s*\n(.*?)```', text, re.S)
    if len(blocks) != 1:
        raise ValueError('02 must contain exactly one architecture-graph JSON block')
    graph = json.loads(blocks[0])
    nodes, edges = graph['nodes'], graph['edges']
    if not nodes:
        raise ValueError('architecture graph needs nodes')
    ids = set()
    for n in nodes:
        if not all(isinstance(n.get(k), str) and n[k].strip() for k in ('id', 'name', 'role', 'group')):
            raise ValueError('each node needs nonempty id/name/role/group')
        if n['id'] in ids:
            raise ValueError('duplicate node id: ' + n['id'])
        ids.add(n['id'])
        if type(n.get('layer')) is not int or not 0 <= n['layer'] <= 20:
            raise ValueError('node layer must be an integer between 0 and 20')
    if len(nodes) > 1 and not edges:
        raise ValueError('multi-node graph needs explicit relationships')
    for e in edges:
        if e.get('from') not in ids or e.get('to') not in ids:
            raise ValueError('edge endpoint not found')
        if not e.get('label') or e.get('kind') not in ('data', 'control', 'clock', 'reset'):
            raise ValueError('edge needs label and kind: data/control/clock/reset')
    # Every implementation module in the existing §2 table must appear under its original name.
    import check_docs
    modules = check_docs.arch_modules(text)
    missing = set(modules) - {n['name'] for n in nodes}
    if missing:
        raise ValueError('modules missing from graph: ' + ', '.join(sorted(missing)))
    esc = lambda value: html.escape(str(value), quote=True)
    colors = {'data': '#2563eb', 'control': '#b45309', 'clock': '#7c3aed', 'reset': '#dc2626'}
    counts, pos = {}, {}
    for n in nodes:
        layer = n['layer']
        row = counts.get(layer, 0)
        counts[layer] = row + 1
        pos[n['id']] = (60 + layer * 380, 80 + row * 230)
    width, height = 420 + max(counts) * 380, 120 + max(counts.values()) * 230 + len(edges) * 24
    svg = [f'<svg viewBox="0 0 {width} {height}" width="{width}" height="{height}" role="img" aria-label="系统模块关系图">',
           '<defs>' + ''.join(f'<marker id="{k}" markerWidth="10" markerHeight="8" refX="9" refY="4" orient="auto"><path d="M0,0 L10,4 L0,8 Z" fill="{v}"/></marker>' for k, v in colors.items()) + '</defs>']
    rows = []
    names = {n['id']: n['name'] for n in nodes}
    for i, e in enumerate(edges, 1):
        x1, y1 = pos[e['from']]
        x2, y2 = pos[e['to']]
        x1 += 280
        y1 += 70
        y2 += 70
        bend = max(45, abs(x2 - x1) / 2)
        color = colors[e['kind']]
        label = f'{i}. {e["label"]}'
        if x2 < x1:
            # Route feedback/same-column edges below cards instead of through their text.
            lane = 100 + max(counts.values()) * 230 + i * 24
            start, end = x1 - 140, x2 + 140
            path = f'M{start},{y1+90} V{lane} H{end} V{y2+90}'
            lx, ly = (start + end) / 2, lane - 5
        else:
            path = f'M{x1},{y1} C{x1+bend},{y1} {x2-bend},{y2} {x2},{y2}'
            lx, ly = (x1 + x2) / 2, (y1 + y2) / 2 - 8
        svg.append(f'<path d="{path}" fill="none" stroke="{color}" stroke-width="2" marker-end="url(#{e["kind"]})"><title>{esc(label)}</title></path>')
        svg.append(f'<text x="{lx}" y="{ly}" text-anchor="middle" fill="{color}">{i}</text>')
        rows.append(f'<tr><td>{i}</td><td>{esc(names[e["from"]])}</td><td>→ {esc(names[e["to"]])}</td><td>{esc(e["kind"])}</td><td>{esc(e["label"])}</td></tr>')
    for n in nodes:
        x, y = pos[n['id']]
        svg.append(f'<foreignObject x="{x}" y="{y}" width="280" height="160"><div xmlns="http://www.w3.org/1999/xhtml" class="node"><small>{esc(n["group"])}</small><strong>{esc(n["name"])}</strong><span>{esc(n["role"])}</span></div></foreignObject>')
    svg.append('</svg>')
    # Review/status metadata must not make the derived view stale.
    source = re.sub(r'\A---\r?\n.*?\r?\n---\r?\n', '', text, count=1, flags=re.S).replace('\r\n', '\n')
    digest = hashlib.sha256(source.encode('utf-8')).hexdigest()
    title = esc(graph.get('title', '系统微架构'))
    return f'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title><style>
body{{font:16px system-ui,sans-serif;margin:28px;background:#f5f7fb;color:#172033}}h1{{margin-bottom:8px}}
.diagram{{overflow:auto;background:white;border:1px solid #cbd5e1;border-radius:12px}}svg text{{font-size:15px;font-weight:bold}}
.node{{box-sizing:border-box;height:150px;padding:14px;background:#eff6ff;border:2px solid #64748b;border-radius:12px;overflow:auto}}
.node strong,.node span{{display:block;overflow-wrap:anywhere;margin-top:6px}}small{{color:#475569}}
table{{border-collapse:collapse;width:100%;background:white}}td,th{{border:1px solid #cbd5e1;padding:10px;text-align:left;overflow-wrap:anywhere}}
@media print{{.diagram{{overflow:visible}}svg{{width:100%;height:auto}}body{{margin:0}}}}
</style></head><body><h1>{title}</h1><p>{esc(graph.get('summary', ''))}</p>
<p>按左→右阅读；卡片显示原始模块名、职责与所属层次/时钟域。箭头编号对应下方接口表。蓝：数据；棕：控制；紫：时钟；红：复位。图可横向滚动，浏览器缩放或打印。</p>
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
        output.write_text(content, encoding='utf-8', newline='\n')
    print(output)


if __name__ == '__main__':
    main()
