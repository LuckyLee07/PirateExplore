#!/usr/bin/env python3
"""Normal crop/scale/atlas import of generated event subjects, with CSV meanings.
No data, GIDs, callbacks or event overlays are changed. Existing flag art is reused.
"""
from pathlib import Path
from PIL import Image
import argparse,json
p=argparse.ArgumentParser();p.add_argument('source',type=Path);a=p.parse_args()
root=Path(__file__).resolve().parents[1];assets=root/'bin/res/assets';original=Image.open(assets/'Images/Map/t_00.png').convert('RGBA');sheet=Image.open(a.source).convert('RGBA');out=original.copy()
def box(gid):
 i=gid-19;return (i%8*64,i//8*64,i%8*64+64,i//8*64+64)
# Frame 48 is the original standalone occupation flag. Copy before changing supply.
flag=original.crop(box(48));flag=flag.crop(flag.getchannel('A').getbbox());flag.thumbnail((23,23),Image.Resampling.LANCZOS)
subjects=[('supply',[34,100,494,378],48,None),('pub',[577,84,399,397],32,None),('market',[1035,86,471,398],52,None),('iron',[30,537,487,434],30,31),('teleport',[574,535,391,425],49,50),('arena',[1038,538,483,435],45,None)]
changed={47};accepted=Image.open(assets/'Images/UI/Adventure/SeaChart/Slice/events-map1.png').convert('RGBA');out.paste(accepted.crop(box(47)),box(47))
for name,(x,y,w,h),gid,occupied in subjects:
 crop=sheet.crop((max(0,x-3),max(0,y-3),min(sheet.width,x+w+3),min(sheet.height,y+h+3)));crop.thumbnail((58,58),Image.Resampling.LANCZOS)
 frame=Image.new('RGBA',(64,64));frame.paste(crop,((64-crop.width)//2,61-crop.height));out.paste(frame,box(gid));changed.add(gid)
 if occupied:
  frame.alpha_composite(flag,(62-flag.width,61-flag.height));out.paste(frame,box(occupied));changed.add(occupied)
# Supply consumed state44 deliberately remains the original empty camp/house.
check=out.copy()
for gid in changed:check.paste(original.crop(box(gid)),box(gid))
assert check.tobytes()==original.tobytes()
dest=assets/'Images/UI/Adventure/SeaChart/Tiles/events-world.png';out.save(dest)
print(json.dumps({'changed_gids':sorted(changed),'unchanged_supply_consumed_gid':44,'iron_corrected':[30,31]},indent=2))
