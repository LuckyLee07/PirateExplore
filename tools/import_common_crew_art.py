#!/usr/bin/env python3
"""Crop/resize approved and generated portraits into existing 64px footprints."""
from pathlib import Path
from PIL import Image
import argparse

p=argparse.ArgumentParser()
p.add_argument('--new-pair',type=Path,required=True)
a=p.parse_args()
root=Path(__file__).resolve().parents[1]
assets=root/'bin/res/assets/Images'
approved=Image.open(assets/'UI/Adventure/Master/crew-trio.png').convert('RGBA')
pair=Image.open(a.new_pair).convert('RGBA')
assert pair.width==2*pair.height and pair.getchannel('A').getextrema()[0]==0
crops={100:pair.crop((0,0,pair.height,pair.height)),
       101:pair.crop((pair.height,0,pair.width,pair.height))}
# Exact approved runtime cells from MasterTheme.portrait, not new identities.
for id,(x,y,w,h) in {107:(37,70,663,587),102:(764,87,666,570),124:(1488,70,647,587)}.items():
    crops[id]=approved.crop((x,y,x+w,y+h))
out=assets/'Icon/B';out.mkdir(parents=True,exist_ok=True)
for id,crop in crops.items():
    crop=crop.crop(crop.getchannel('A').getbbox())
    crop.thumbnail((60,60),Image.Resampling.LANCZOS)
    icon=Image.new('RGBA',(64,64))
    icon.paste(crop,((64-crop.width)//2,62-crop.height))
    dest=out/f'crew-{id}.png';icon.save(dest);print(dest.relative_to(root))
