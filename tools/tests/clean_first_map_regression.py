#!/usr/bin/env python3
"""Validate the opt-in TMX and exercise its production Lua rules without a GUI."""
import base64
from collections import Counter, deque
import hashlib
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zlib

ROOT = Path(__file__).resolve().parents[2]
MAPS = ROOT / 'bin/res/assets/Images/Map'


def layer(root, name):
    data = root.find("layer[@name='%s']/data" % name)
    assert data.get('encoding') == 'base64' and data.get('compression') == 'zlib'
    return list(struct.unpack('<441I', zlib.decompress(base64.b64decode(data.text))))


def lua(value):
    if isinstance(value, dict):
        return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in value.items()) + '}'
    if isinstance(value, (list, tuple)):
        return '{' + ','.join(lua(v) for v in value) + '}'
    if isinstance(value, str):
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'
    return str(value)


def main():
    original = MAPS / 'map_1.tmx'
    assert hashlib.sha256(original.read_bytes()).hexdigest() == (
        'c3301577753252ee3f6d55541716430cfc01452f2415a5594b738adf7d512d66'), 'legacy map changed'
    old = ET.parse(original).getroot()
    new = ET.parse(MAPS / 'map_1_clean_v1.tmx').getroot()
    assert old.attrib == new.attrib
    assert [ET.tostring(t) for t in old.findall('tileset')] == [ET.tostring(t) for t in new.findall('tileset')]
    assert [l.get('name') for l in old.findall('layer')] == [l.get('name') for l in new.findall('layer')]
    for name in ('Sea', 'GridLayer', 'Fogs'):
        assert layer(old, name) == layer(new, name), name
    blocks, meta, old_meta = layer(new, 'Blocks_1'), layer(new, 'Meta'), layer(old, 'Meta')
    assert Counter(g for g in meta if g) == Counter(g for g in old_meta if g)
    assert {i: g for i, g in enumerate(meta) if g} == {7+11*21: 51, 10+7*21: 47, 12+8*21: 30, 13+10*21: 46}
    props = {}
    for tileset in new.findall('tileset'):
        for tile in tileset.findall('tile'):
            props[int(tileset.get('firstgid')) + int(tile.get('id'))] = {
                p.get('name'): p.get('value') for p in tile.findall('./properties/property')}
    assert all(props[g].get('eventid') == '1' for g in blocks if g), 'new terrain bypasses collision rules'
    for gid, event in ((51, '3001'), (47, '3003'), (30, '3068'), (46, '3002'), (26, '3067'), (24, '3070')):
        assert props[gid]['eventid'] == event
    harbor = {(x, y) for y in range(12, 16) for x in range(4, 8) if (x, y) != (4, 12)}
    for y in range(21):
        for x in range(21):
            px = 340 + ((x-7) - (y-11)) * 67
            py = 468 - ((x-7) + (y-11)) * 37
            if (px < 68 and py < 362) or (28 <= px <= 368 and abs(py - (px*.57 + 280.19)) < 35):
                harbor.add((x, y))
    harbor.discard((7, 11))
    assert len(harbor) == 50, 'approved conservative harbor coast mask changed'
    assert all(blocks[x+y*21] for x, y in harbor)
    connected, pending = {next(iter(harbor))}, [next(iter(harbor))]
    while pending:
        x, y = pending.pop()
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            p = x+dx, y+dy
            if p in harbor and p not in connected:
                connected.add(p)
                pending.append(p)
    assert connected == harbor and any(y == 20 for x, y in harbor), 'harbor mainland disconnected'
    assert all(not blocks[x+y*21] for x in range(5, 8) for y in range(9, 12)), 'near-harbor channel narrowed'
    old_objects, objects = list(old.find('objectgroup')), list(new.find('objectgroup'))
    assert len(old_objects) == len(objects) == 80
    assert Counter(o.get('type') for o in old_objects) == Counter(o.get('type') for o in objects)
    seen, slots, world_objects = set(), [], []
    for prior, obj in zip(old_objects, objects):
        assert {k: v for k, v in prior.attrib.items() if k not in ('x', 'y')} == {
            k: v for k, v in obj.attrib.items() if k not in ('x', 'y')}
        x, y = int(float(obj.get('x'))) // 64, int(float(obj.get('y'))) // 64
        assert (x, y) not in seen and not blocks[x+y*21], ('invalid object slot', x, y)
        seen.add((x, y))
        if obj.get('name') == 'Start':
            assert (x, y) == (7, 11) and meta[x+y*21] == 51
        else:
            assert not meta[x+y*21], ('random slot overlaps fixed event', x, y)
            if obj.get('type') == '2':
                assert x in (0, 20) or y in (0, 20), 'peripheral slot moved inland'
            slots.append({'x': x, 'y': y, 'type': obj.get('type')})
        # Cocos flips Tiled's object y coordinate when loading its object group.
        world_objects.append(dict(obj.attrib, x=float(obj.get('x')), y=1344-float(obj.get('y'))))
    walkable = {(x, y) for y in range(21) for x in range(21) if not blocks[x+y*21]}
    reachable, queue = {(7, 11)}, deque([(7, 11)])
    while queue:
        x, y = queue.popleft()
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            p = x+dx, y+dy
            if p in walkable and p not in reachable:
                reachable.add(p)
                queue.append(p)
    assert reachable == walkable, 'disconnected navigable water'
    assert seen <= reachable
    assert all((i % 21, i // 21) in reachable for i, gid in enumerate(meta) if gid)
    fixture = {'blocks': blocks, 'meta': meta, 'props': props, 'objects': world_objects, 'slots': slots,
               'harbor': [{'x': x, 'y': y} for x, y in sorted(harbor)]}
    interpreter = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('LUA_BIN') or shutil.which('lua5.1') or shutil.which('lua')
    assert interpreter, 'pass a Lua 5.1 interpreter or set LUA_BIN'
    with tempfile.NamedTemporaryFile('w', suffix='.lua') as output:
        output.write('return ' + lua(fixture))
        output.flush()
        subprocess.run([interpreter, 'tools/tests/clean_first_map_regression.lua', output.name], cwd=ROOT, check=True)
    print('PASS original TMX bytes, unchanged tilesets/fog/grid/event IDs, 79 unique safe random slots, connected cardinal water and authored harbor channel')


if __name__ == '__main__':
    main()
