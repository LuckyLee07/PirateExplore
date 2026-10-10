#!/usr/bin/env python3
"""Ordinary crop/scale/pad import of built-in imagegen production masters.

No painting, masking, recoloring, map geometry, CSV or original assets are edited.
"""
from pathlib import Path
from PIL import Image
import argparse
import json

p = argparse.ArgumentParser()
p.add_argument('--ship', type=Path, required=True)
p.add_argument('--boarding', type=Path, required=True)
p.add_argument('--resources', type=Path, required=True)
p.add_argument('--landmarks', type=Path, required=True)
a = p.parse_args()
root = Path(__file__).resolve().parents[1]
assets = root / 'bin/res/assets/Images'
outputs = []

def read(path):
    im = Image.open(path).convert('RGBA')
    assert im.getchannel('A').getextrema()[0] == 0, 'master must have real transparency'
    return im

def save(image, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    image.save(dest)
    outputs.append(str(dest.relative_to(root)))

for source, name, size in ((a.ship, 'ship-deck-b.png', (640, 423)),
                           (a.boarding, 'boarding-deck-b.png', (640, 569))):
    image = read(source)
    assert abs(image.width / image.height - size[0] / size[1]) < .005
    save(image.resize(size, Image.Resampling.LANCZOS), assets / 'UI/Adventure/Combat' / name)

# Names verified against the decoded packaged resourceInfo.csv. The key is
# intentionally shared by simple key 1037 and library key 1120, as in the CSV.
names = ['r_1', 'r_2', 'r_3', 'r_4', 'r_5', 'r_6', 'r_8', 'r_19',
         'r_20', 'r_21', 'r_9', 'r_16']
sheet = read(a.resources)
for index, name in enumerate(names):
    x, y = index % 4, index // 4
    crop = sheet.crop((round(x*sheet.width/4), round(y*sheet.height/3),
                       round((x+1)*sheet.width/4), round((y+1)*sheet.height/3)))
    crop = crop.crop(crop.getchannel('A').getbbox())
    crop.thumbnail((56, 56), Image.Resampling.LANCZOS)
    icon = Image.new('RGBA', (64, 64))
    icon.paste(crop, ((64-crop.width)//2, (64-crop.height)//2))
    save(icon, assets / 'Icon/B' / (name + '.png'))

sheet = read(a.landmarks)
assert sheet.size == (1536, 1024)
atlas = Image.new('RGBA', sheet.size)
for index in range(6):
    x, y = index % 3 * 512, index // 3 * 512
    crop = sheet.crop((x, y, x+512, y+512))
    crop = crop.crop(crop.getchannel('A').getbbox())
    crop.thumbnail((448, 448), Image.Resampling.LANCZOS)
    atlas.paste(crop, (x+(512-crop.width)//2, y+488-crop.height))
save(atlas, assets / 'UI/Adventure/SeaChart/Tiles/landmarks-world-b.png')
print(json.dumps(outputs, indent=2))
