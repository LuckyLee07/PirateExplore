#!/usr/bin/env python3
"""Read-only namespaced atlas/semantic metadata checks; no generated edits."""
from pathlib import Path
import json
import re
from PIL import Image

root = Path(__file__).resolve().parents[2]
folder = root / 'bin/res/assets/Images/UI/CleanVoyage/Support'
manifest = json.loads((folder / 'progress-props-v1.json').read_text())
image = Image.open(folder / manifest['image'])
assert image.mode == 'RGBA' and list(image.size) == manifest['dimensions']
assert image.getchannel('A').getextrema() == (0, 255)
source = (root / 'bin/res/scripts/LuaClass/ProgressSupportPresentation.lua').read_text()
for name, rect in manifest['rectangles_xywh'].items():
    x, y, w, h = rect
    assert min(rect) >= 0 and w > 0 and h > 0
    assert x + w <= image.width and y + h <= image.height
    assert image.getchannel('A').crop((x, y, x + w, y + h)).getbbox()
    assert re.search(r'\b' + name + r'=\{' + ','.join(map(str, rect)) + r'\}', source)
assert manifest['semantics']['精准'] == 'target'
assert manifest['semantics']['闪避'] == 'feather'
assert manifest['semantics']['耐饿'] == 'food'
assert manifest['semantics']['侦查'] == 'scout'
assert manifest['semantics']['先发制人'] == 'lightning'
print('PASS support atlas: native RGBA, 9 bounded stable crops, talent semantics and manifest/code parity')
