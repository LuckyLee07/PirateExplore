#!/usr/bin/env python3
"""Ordinary import of the two generated chest-state cells; no painting/masking."""
from pathlib import Path
from PIL import Image
import argparse
p=argparse.ArgumentParser();p.add_argument('source',type=Path);a=p.parse_args()
root=Path(__file__).resolve().parents[1]
sheet=Image.open(a.source).convert('RGBA')
assert abs(sheet.width/sheet.height-368/239)<.01
assert sheet.getchannel('A').getextrema()[0]==0
dest=root/'bin/res/assets/Images/UI/Adventure/Combat';dest.mkdir(parents=True,exist_ok=True)
for index,name in enumerate(['chest-closed-b.png','chest-open-b.png']):
    crop=sheet.crop((round(index*sheet.width/2),0,round((index+1)*sheet.width/2),sheet.height))
    crop.thumbnail((176,231),Image.Resampling.LANCZOS)
    cell=Image.new('RGBA',(184,239))
    cell.paste(crop,((184-crop.width)//2,(239-crop.height)//2))
    crop=cell
    bounds=crop.getchannel('A').getbbox()
    assert bounds[0]>=4 and bounds[1]>=4 and bounds[2]<=180 and bounds[3]<=235, bounds
    crop.save(dest/name);print(dest/name)
