#!/usr/bin/env python3
"""Catch silently blank Chinese glyphs in the bundled native heading subset."""
from pathlib import Path
from fontTools.ttLib import TTFont

root = Path(__file__).resolve().parents[2]
font = TTFont(root / 'bin/res/assets/fonts/HarborSerif-Bold.ttf')
cmap = font.getBestCmap()
sans_cmap = TTFont(root / "bin/res/assets/fonts/CleanVoyageSans-Regular.ttf").getBestCmap()
missing = {}
for path in sorted((root / 'bin/res/scripts/LuaClass').glob('*.lua')):
    # The build script includes runtime source text (including future headings).
    # Check CJK only: ASCII/layout symbols can legitimately use platform fallback.
    active_cmap = sans_cmap if (path.name.startswith("Warm") or path.name in {"CleanVoyageHUD.lua", "CleanVoyageView.lua"}) else cmap
    source = path.read_text(encoding='utf-8')
    sections = [(source, active_cmap)]
    if path.name == 'Ranking.lua':
        # The explicit Warm-only adapter uses W.font/CleanVoyageSans; retain
        # strict serif coverage for every preceding legacy routing/title string.
        legacy, marker, coherent = source.partition('-- Warm-only composition.')
        assert marker, 'Ranking font boundary must match its explicit adapter'
        sections = [(legacy, cmap), (coherent, sans_cmap)]
    if path.name == 'DataManager.lua':
        # The shortage branch explicitly uses WarmDialog's CleanVoyageSans.
        # Keep the unchanged legacy source's serif check as well.
        start = source.index("if rawget(_G, 'WARM_PIRATE_V1') ~= false then", source.index('function DataManager:addDiamond('))
        end = source.index('local _newalert = AlertView:create', start)
        sections.append((source[start:end], sans_cmap))
    for section, section_cmap in sections:
        for char in set(section):
            if 0x3400 <= ord(char) <= 0x9fff and ord(char) not in section_cmap:
                missing.setdefault(char, []).append(path.name)
assert not missing, 'Missing runtime glyphs; rebuild the corresponding harbor serif or clean voyage sans font: ' + repr(missing)
assert all(ord(char) in cmap for char in '救援补给航图员林恩沉船残骸'), 'Adventure labels must remain complete'
print('PASS bundled serif/sans fonts cover their CJK runtime source text and adventure labels')
