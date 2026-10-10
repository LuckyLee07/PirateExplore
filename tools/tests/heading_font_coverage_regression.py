#!/usr/bin/env python3
"""Catch silently blank Chinese glyphs in the bundled native heading subset."""
from pathlib import Path
from fontTools.ttLib import TTFont

root = Path(__file__).resolve().parents[2]
font = TTFont(root / 'bin/res/assets/fonts/HarborSerif-Bold.ttf')
cmap = font.getBestCmap()
missing = {}
for path in sorted((root / 'bin/res/scripts/LuaClass').glob('*.lua')):
    # The build script includes runtime source text (including future headings).
    # Check CJK only: ASCII/layout symbols can legitimately use platform fallback.
    for char in set(path.read_text(encoding='utf-8')):
        if 0x3400 <= ord(char) <= 0x9fff and ord(char) not in cmap:
            missing.setdefault(char, []).append(path.name)
assert not missing, 'Missing heading glyphs; rebuild with tools/build_harbor_heading_font.py: ' + repr(missing)
assert all(ord(char) in cmap for char in '救援补给航图员林恩沉船残骸'), 'Adventure labels must remain complete'
print('PASS bundled heading font covers all CJK runtime source text and adventure labels')
