#!/usr/bin/env python3
"""Deterministic alpha-aware import of two original built-in imagegen masters."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
NAMES = ('siege-ram-1039', 'iron-sword-1049')

def render(source):
    image = Image.open(source).convert('RGBA')
    assert image.getchannel('A').getextrema() == (0, 255)
    bounds = image.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()
    crop = image.crop(bounds)
    factor = min(56 / crop.width, 56 / crop.height)
    size = (round(crop.width * factor), round(crop.height * factor))
    crop = crop.convert('RGBa').resize(size, Image.Resampling.LANCZOS).convert('RGBA')
    result = Image.new('RGBA', (64, 64))
    result.paste(crop, ((64 - crop.width) // 2, (64 - crop.height) // 2))
    return result

if __name__ == '__main__':
    for name in NAMES:
        output = ROOT / 'bin/res/assets/Images/Icon/B' / (name + '.png')
        render(ROOT / 'docs/art-sources/missing-item-icons' / (name + '-master.png')).save(output)
        print(output.relative_to(ROOT))
