"""Deterministic offline orthogonal layout (Python 3.8+, no dependencies).

Routes avoid closed card interiors and number badges. Separate incident ports and
reserved grid segments prevent shared tracks; perpendicular crossings are allowed.
The finite visibility grid bounds the search; failure is explicit, never a route
silently drawn through a card. Input order breaks ties and preserves manual layers.
"""
import heapq
import unicodedata

CARD_WIDTH = 280
PITCH = 30
TRACK = 12


def wrap_text(text, columns=30):
    """Conservative character-cell wrapping, including wide CJK characters."""
    lines = []
    for paragraph in text.split('\n'):
        line, size = '', 0
        for char in paragraph:
            width = 2 if unicodedata.east_asian_width(char) in ('W', 'F') else 1
            if size + width > columns and line:
                lines.append(line)
                line, size = '', 0
            line += char
            size += width
        lines.append(line)
    return lines


def _inside(x, y, rect):
    rx, ry, rw, rh = rect
    return rx < x < rx + rw and ry < y < ry + rh


def _simplify(points):
    result = []
    for point in points:
        if result and point == result[-1]:
            continue
        if len(result) >= 2:
            a, b = result[-2:]
            if (a[0] == b[0] == point[0]) or (a[1] == b[1] == point[1]):
                result.pop()
        result.append(point)
    return result


def layout(nodes, edges):
    """Return JSON-like geometry: nodes, edges, width and height.

    Node records contain x/y/width/height, manual layer, and (style, text) lines.
    Edge records contain orthogonal points, explicit source_port/target_port and
    a badge rectangle (x,y,width,height). Coordinates include final canvas margin.
    Caller validates the architecture-graph schema before invoking this function.
    """
    incident = {n['id']: [] for n in nodes}
    for i, edge in enumerate(edges):
        incident[edge['from']].append((i, 'source'))
        incident[edge['to']].append((i, 'target'))
    layers = sorted({n['layer'] for n in nodes})
    layer_index = {layer: i for i, layer in enumerate(layers)}
    # Local gutter widths follow traffic, not a single graph-wide edge multiplier.
    traffic = [0] * (len(layers) + 1)
    for edge in edges:
        a = layer_index[next(n['layer'] for n in nodes if n['id'] == edge['from'])]
        b = layer_index[next(n['layer'] for n in nodes if n['id'] == edge['to'])]
        for boundary in range(min(a + 1, b), max(a + 1, b) + 1):
            traffic[boundary] += 1
    xs, x = {}, 0
    for index, layer in enumerate(layers):
        xs[layer] = x
        x += CARD_WIDTH + 112 + TRACK * traffic[index + 1]
    cards, ports = {}, {}
    bottoms = []
    for layer in layers:
        y = 0
        for node in (n for n in nodes if n['layer'] == layer):
            lines = []
            for style, key in (('group', 'group'), ('name', 'name'), ('role', 'role')):
                lines.extend((style, line) for line in wrap_text(node[key]))
            height = max(100, 32 + 22 * len(lines), 30 + PITCH * len(incident[node['id']]))
            card = dict(x=xs[layer], y=y, width=CARD_WIDTH, height=height,
                        layer=layer, lines=lines)
            cards[node['id']] = card
            for slot, (i, side) in enumerate(incident[node['id']]):
                ports[i, side] = (xs[layer] + (CARD_WIDTH if side == 'source' else 0),
                                  y + 24 + slot * PITCH)
            y += height + 84
        bottoms.append(y - 84)
    routes, obstacles = [], []
    for card in cards.values():
        obstacles.append((card['x'] - 8, card['y'] - 8,
                          card['width'] + 16, card['height'] + 16))
    for i, edge in enumerate(edges):
        source, target = ports[i, 'source'], ports[i, 'target']
        badge_width = max(26, 12 + 8 * len(str(i + 1)))
        badge = (source[0] + 10, source[1] - 10, badge_width, 20)
        start = (source[0] + badge_width + 24, source[1])
        finish = (target[0] - 20, target[1])
        routes.append(dict(source_port=source, target_port=target, badge=badge,
                           start=start, finish=finish))
        obstacles.append((badge[0] - 3, badge[1] - 3, badge[2] + 6, badge[3] + 6))
    # Include every obstacle boundary: each grid link is wholly free or blocked.
    xvalues, yvalues = set(), set()
    for rx, ry, rw, rh in obstacles:
        xvalues.update((rx, rx + rw))
        yvalues.update((ry, ry + rh))
    for route in routes:
        for key in ('source_port', 'target_port', 'start', 'finish'):
            px, py = route[key]
            xvalues.add(px)
            yvalues.add(py)
    outer = TRACK * (len(edges) + 2)
    right = max(c['x'] + CARD_WIDTH for c in cards.values())
    bottom = max(bottoms)
    for layer in layers:
        left = xs[layer] + CARD_WIDTH + 48
        next_x = xs[layers[layer_index[layer] + 1]] if layer_index[layer] + 1 < len(layers) else right + outer + 60
        xvalues.update(range(left, next_x - 19, TRACK))
    xvalues.update(range(-outer - 24, -19, TRACK))
    yvalues.update(range(-outer - 24, -11, TRACK))
    yvalues.update(range(bottom + 12, bottom + outer + 25, TRACK))
    for card in cards.values():
        yvalues.update(range(card['y'] + card['height'] + 12,
                            card['y'] + card['height'] + 73, TRACK))
    xx, yy = sorted(xvalues), sorted(yvalues)
    xi, yi = {v: i for i, v in enumerate(xx)}, {v: i for i, v in enumerate(yy)}
    nx, ny = len(xx), len(yy)
    # Rasterize interiors and links once. No platform-dependent geometry library.
    blocked = set()
    blocked_links = set()
    for rx, ry, rw, rh in obstacles:
        ix = [i for i, v in enumerate(xx) if rx < v < rx + rw]
        iy = [j for j, v in enumerate(yy) if ry < v < ry + rh]
        blocked.update(j * nx + i for j in iy for i in ix)
        # Boundary-to-boundary links also intersect an obstacle when there is no
        # interior coordinate, hence midpoint checks on its covered rows/columns.
        for j in iy:
            for i in range(xi[rx], xi[rx + rw]):
                blocked_links.add((j * nx + i, j * nx + i + 1))
        for i in ix:
            for j in range(yi[ry], yi[ry + rh]):
                blocked_links.add((j * nx + i, (j + 1) * nx + i))
    used = set()

    def vertex(point):
        return yi[point[1]] * nx + xi[point[0]]

    def reserve(points):
        for a, b in zip(points, points[1:]):
            va, vb = sorted((vertex(a), vertex(b)))
            stride = 1 if a[1] == b[1] else nx
            used.update((v, v + stride) for v in range(va, vb, stride))

    # All endpoint stubs are reserved before routing any edge, so later ports
    # cannot accidentally be consumed by an earlier connection.
    for route in routes:
        reserve([route['source_port'], route['start']])
        reserve([route['finish'], route['target_port']])
    for route in routes:
        start, goal = vertex(route['start']), vertex(route['finish'])
        target_x, target_y = route['finish']
        initial = (start, 0)
        best, previous = {initial: 0}, {}
        queue = [(0, 0, start, 0)]
        final = None
        while queue:
            _, cost, current, direction = heapq.heappop(queue)
            state = (current, direction)
            if cost != best.get(state):
                continue
            if current == goal:
                final = state
                break
            row, col = divmod(current, nx)
            neighbors = []
            if col: neighbors.append((current - 1, 1))
            if col + 1 < nx: neighbors.append((current + 1, 1))
            if row: neighbors.append((current - nx, 2))
            if row + 1 < ny: neighbors.append((current + nx, 2))
            for neighbor, axis in neighbors:
                link = (min(current, neighbor), max(current, neighbor))
                if neighbor in blocked or link in blocked_links or link in used:
                    continue
                nr, nc = divmod(neighbor, nx)
                length = abs(xx[nc] - xx[col]) + abs(yy[nr] - yy[row])
                extra = 18 if direction and direction != axis else 0
                # Prefer fewer perpendicular crossings while admitting them.
                cross_stride = nx if axis == 1 else 1
                if ((neighbor - cross_stride, neighbor) in used or
                        (neighbor, neighbor + cross_stride) in used):
                    extra += 24
                new_cost = cost + length + extra
                new_state = (neighbor, axis)
                if new_cost < best.get(new_state, float('inf')):
                    best[new_state] = new_cost
                    previous[new_state] = state
                    heuristic = abs(xx[nc] - target_x) + abs(yy[nr] - target_y)
                    heapq.heappush(queue, (new_cost + heuristic, new_cost, neighbor, axis))
        if final is None:
            raise ValueError('architecture routing grid exhausted; reduce graph density or split the diagram')
        path = []
        while final != initial:
            v = final[0]
            path.append((xx[v % nx], yy[v // nx]))
            final = previous[final]
        path.append(route['start'])
        path.reverse()
        reserve(path)
        route['points'] = _simplify([route['source_port']] + path + [route['target_port']])
        del route['start'], route['finish']
    # Crop unused escape lanes, keeping sparse/simple graphs compact.
    all_x = [0, right]
    all_y = [0, bottom]
    for route in routes:
        all_x.extend(p[0] for p in route['points'])
        all_y.extend(p[1] for p in route['points'])
        bx, by, bw, bh = route['badge']
        all_x.extend((bx, bx + bw))
        all_y.extend((by, by + bh))
    dx, dy = 24 - min(all_x), 24 - min(all_y)
    for card in cards.values():
        card['x'] += dx
        card['y'] += dy
    for route in routes:
        route['points'] = [(px + dx, py + dy) for px, py in route['points']]
        for key in ('source_port', 'target_port'):
            px, py = route[key]
            route[key] = (px + dx, py + dy)
        bx, by, bw, bh = route['badge']
        route['badge'] = (bx + dx, by + dy, bw, bh)
    return dict(nodes=cards, edges=routes, width=max(all_x) + dx + 24,
                height=max(all_y) + dy + 24)
