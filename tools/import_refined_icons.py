#!/usr/bin/env python3
"""Deterministic crop/alpha-aware scale/pad import; never redraws silhouettes.

Masters are built-in imagegen output. Alpha>=32 selects the content bounds only:
all source alpha inside the bounds survives, including antialiased edges. White
RGB in navigation exports is the engine's neutral vertex-tint mask convention.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'docs/art-sources/icon-refinement'
ASSETS = ROOT / 'bin/res/assets/Images'

def export(name, destination, side, inset, mask=False):
    source = Image.open(SOURCES / (name + '-master.png')).convert('RGBA')
    assert source.getchannel('A').getextrema() == (0, 255)
    bounds = source.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()
    crop = source.crop(bounds)
    available = side - inset * 2
    factor = min(available / crop.width, available / crop.height)
    dimensions = (round(crop.width * factor), round(crop.height * factor))
    # Filter premultiplied channels to prevent hidden RGB bleeding at edges.
    crop = crop.convert('RGBa').resize(dimensions, Image.Resampling.LANCZOS).convert('RGBA')
    if mask:
        alpha = crop.getchannel('A')
        crop = Image.new('RGBA', crop.size, (255, 255, 255, 0))
        crop.putalpha(alpha)
    icon = Image.new('RGBA', (side, side))
    icon.paste(crop, ((side-crop.width)//2, (side-crop.height)//2))
    destination.parent.mkdir(parents=True, exist_ok=True)
    icon.save(destination)
    print(destination.relative_to(ROOT))

for name, icon in [('food', 'r_2.png'), ('stone', 'r_3.png'), ('wood', 'r_4.png')]:
    export(name, ASSETS/'Icon/B'/icon, 64, 4)
for name in ['port', 'barrel']:
    export(name, ASSETS/'UI/Adventure/Master/Icons'/(name+'.png'), 128, 4, True)
