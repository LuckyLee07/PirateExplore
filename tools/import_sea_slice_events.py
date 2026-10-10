#!/usr/bin/env python3
"""Import three generated transparent event cells into the original atlas.
Only texture pixels change; TMX GIDs/metadata remain owned by the original game.
"""
from pathlib import Path
import argparse
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path, help='3x1 square-cell RGBA generated sheet')
parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
a = parser.parse_args()
sheet = Image.open(a.source).convert('RGBA')
assert sheet.width == sheet.height * 3, 'Expected three equal square cells'
original = Image.open(a.root/'bin/res/assets/Images/Map/t_00.png').convert('RGBA')
assert original.size == (512, 384)
result = original.copy()
rects = [(256, 192, 320, 256), (192, 64, 256, 128), (256, 64, 320, 128)]
cells = [sheet.crop((i*sheet.height, 0, (i+1)*sheet.height, sheet.height)) for i in range(3)]
bounds = [cell.getchannel('A').point(lambda a: 255 if a >= 8 else 0).getbbox() for cell in cells]
assert all(bounds), 'Each event needs visible alpha'
# Skull variants share a crop, scale and bottom baseline: occupation must not
# make the underlying skull jump or change size. Keep a three-pixel cell margin.
skull = (min(bounds[1][0], bounds[2][0]), min(bounds[1][1], bounds[2][1]),
         max(bounds[1][2], bounds[2][2]), max(bounds[1][3], bounds[2][3]))
for i, rect in enumerate(rects):
    cell = cells[i].crop(bounds[0] if i == 0 else skull)
    scale = min(58 / cell.width, 58 / cell.height)
    width, height = round(cell.width * scale), round(cell.height * scale)
    cell = cell.resize((width, height), Image.Resampling.LANCZOS)
    frame = Image.new('RGBA', (64, 64))
    frame.paste(cell, ((64-width)//2, 61-height))
    result.paste(frame, rect)
# Prove every unrelated event frame is pixel-identical to the original.
check = result.copy()
for rect in rects:
    check.paste(original.crop(rect), rect)
assert check.tobytes() == original.tobytes()
out = a.root/'bin/res/assets/Images/UI/Adventure/SeaChart/Slice/events-map1.png'
out.parent.mkdir(parents=True, exist_ok=True)
result.save(out)
print(out)
