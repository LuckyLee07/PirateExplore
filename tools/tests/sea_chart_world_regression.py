#!/usr/bin/env python3
"""Read every real TMX and source alpha; exercise production world Lua without a GUI."""
import base64
import gzip
import hashlib
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zlib

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MAPS = ROOT / 'bin/res/assets/Images/Map'
ART = ROOT / 'bin/res/assets/Images/UI/Adventure/SeaChart/Tiles'
FAMILIES = dict(zip(('dt_ludi', 'dt_senlin', 'dt_huoshan', 'dt_bingdao', 'dt_ziseludi', 'dt_youlingdao'),
                    ('sand', 'forest', 'volcanic', 'ice', 'violet', 'ghost')))
EXPECTED = ['sand', 'forest sand', 'forest sand', 'forest volcanic', 'volcanic',
            'ice sand', 'ice', 'ice', 'ice', 'forest ice', 'forest violet',
            'violet', 'ghost violet', 'sand violet', 'violet volcanic', 'volcanic']


def lua(value):
    if isinstance(value, dict):
        return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in value.items()) + '}'
    if isinstance(value, (list, tuple)):
        return '{' + ','.join(lua(v) for v in value) + '}'
    if isinstance(value, str):
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'
    return str(value)


def main():
    before, fixtures, flip_maps, total_land = {}, [], {}, 0
    for index in range(1, 17):
        path = MAPS / ('map_%d.tmx' % index)
        before[path] = hashlib.sha256(path.read_bytes()).digest()
        root = ET.parse(path).getroot()
        sets = [(int(t.get('firstgid')), t.find('image').get('source')) for t in root.findall('tileset')]
        fixture = {'index': index, 'width': int(root.get('width')), 'height': int(root.get('height')), 'layers': []}
        themes, flipped = set(), 0
        for z, layer in enumerate(root.findall('layer')):
            data = layer.find('data')
            raw = base64.b64decode(data.text)
            raw = gzip.decompress(raw) if data.get('compression') == 'gzip' else zlib.decompress(raw)
            gids = struct.unpack('<%dI' % (len(raw) // 4), raw)
            first = next(g & 0x1fffffff for g in gids if g & 0x1fffffff)
            start, atlas = max((t for t in sets if t[0] <= first), key=lambda t: t[0])
            name = layer.get('name')
            if name.startswith('Blocks_'):
                used = {max((t for t in sets if t[0] <= (g & 0x1fffffff)), key=lambda t: t[0])[1] for g in gids if g & 0x1fffffff}
                assert used == {atlas}, (index, name, used)
                themes.add(FAMILIES[Path(atlas).stem])
                flipped += sum(bool(g & 0xe0000000) for g in gids)
                total_land += sum(bool(g & 0x1fffffff) for g in gids)
            fixture['layers'].append({'name': name, 'z': z, 'atlas': atlas, 'firstgid': start,
                                      'gids': gids, 'offsetx': float(layer.get('offsetx', 0)),
                                      'offsety': float(layer.get('offsety', 0))})
        assert sorted(themes) == EXPECTED[index-1].split(), (index, themes)
        if flipped:
            flip_maps[index] = flipped
        fixtures.append(fixture)
    assert flip_maps == {7: 1, 11: 10, 12: 119, 16: 28}, flip_maps
    for atlas, family in FAMILIES.items():
        alpha = Image.open(MAPS / (atlas + '.png')).convert('RGBA').getchannel('A')
        for tile in (10, 18, 19, 20, 21, 22):
            x, y = tile % 6 * 64, tile // 6 * 64
            assert alpha.crop((x, y, x+64, y+64)).getextrema()[0] == 255, (atlas, tile)
        material = Image.open(ART / ('land-' + family + '-repeat.png'))
        assert material.size == (512, 512)
        if material.mode == 'RGBA':
            assert material.getchannel('A').getextrema() == (255, 255)
    sheet = Image.open(ART / 'decor-world.png')
    assert sheet.mode == 'RGBA' and sheet.size == (1536, 1024)
    decor_bases = {}
    for i in range(6):
        alpha = sheet.getchannel('A').crop((i%3*512, i//3*512, i%3*512+512, i//3*512+512))
        assert alpha.getextrema()[0] == 0 and alpha.getextrema()[1] >= 250
        assert alpha.getpixel((0, 0)) == 0 and alpha.getpixel((511, 511)) == 0
        footprint = alpha.crop((0, 384, 512, 512)).point(lambda a: 255 if a > 128 else 0).getbbox()
        assert footprint
        decor_bases[i] = (footprint[0], footprint[1]+384, footprint[2], footprint[3]+384)
    landmarks = Image.open(ART / 'landmarks-world-b.png')
    assert landmarks.mode == 'RGBA' and landmarks.size == (1536, 1024)
    landmark_bases = {}
    for i in range(6):
        alpha = landmarks.getchannel('A').crop((i%3*512, i//3*512, i%3*512+512, i//3*512+512))
        assert alpha.getextrema()[0] == 0 and alpha.getextrema()[1] >= 250
        assert alpha.getbbox()[0] >= 32 and alpha.getbbox()[2] <= 480
        assert alpha.getbbox()[3] <= 488, 'landmark has no bottom transparency gutter'
        footprint = alpha.crop((0, 384, 512, 512)).point(lambda a: 255 if a > 128 else 0).getbbox()
        assert footprint
        landmark_bases[i] = (footprint[0], footprint[1]+384, footprint[2], footprint[3]+384)
    interpreter = sys.argv[1] if len(sys.argv) > 1 else shutil.which('lua5.1') or shutil.which('lua')
    if not interpreter:
        interpreter = str(ROOT / 'build/linux/tests/lua-ui-tests')
    with tempfile.NamedTemporaryFile('w', suffix='.lua') as fixture_file:
        fixture_file.write('local fixtures = ' + lua(fixtures) + '\nfixtures.decorBases = ' + lua(decor_bases)
                           + '\nfixtures.landmarkBases = ' + lua(landmark_bases) + '\nreturn fixtures')
        fixture_file.flush()
        subprocess.run([interpreter, 'tools/tests/sea_chart_world_regression.lua', fixture_file.name], cwd=ROOT, check=True)
    for path, digest in before.items():
        assert hashlib.sha256(path.read_bytes()).digest() == digest, path
    print('PASS all 16 unchanged TMX files, six actual terrain families, %d land cells, 158 flipped cells, original safe-base alpha and seven art imports' % total_land)


if __name__ == '__main__':
    main()
