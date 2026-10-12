#!/usr/bin/env python3
"""Mechanical transparent crop/resize/pad of retained imagegen map-object masters.
No color/alpha painting, TMX writes or source-atlas changes. Run from any directory.
"""
from pathlib import Path
from PIL import Image
import hashlib, json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'bin/res/assets/Images/UI/CleanSeaObjects'
NEW=OUT/'source/sites-five-kind-v1.png'
PORT=ROOT/'bin/res/assets/Images/UI/CleanSea/source/event-three-kind-v1.png'
sheet=Image.open(NEW).convert('RGBA');assert sheet.size==(1536,1024)
port=Image.open(PORT).convert('RGBA');assert port.width==port.height*3
subjects={'port':(port,(0,0,port.height,port.height))}
for name,(x,y) in {'world-chart':(0,0),'resurrection':(1,0),'gateway':(2,0),'tavern':(0,1),'arena':(1,1)}.items():
 subjects[name]=(sheet,(x*512,y*512,(x+1)*512,(y+1)*512))
records={}
for name,(master,cell) in subjects.items():
 cut=master.crop(cell);bounds=cut.getchannel('A').getbbox();assert bounds
 cut=cut.crop(bounds);cut.thumbnail((224,224),Image.Resampling.LANCZOS)
 canvas=Image.new('RGBA',(256,256));origin=((256-cut.width)//2,232-cut.height)
 canvas.alpha_composite(cut,origin);path=OUT/(name+'-v1.png');canvas.save(path)
 records[name]={'master':str((PORT if name=='port' else NEW).relative_to(ROOT)),'cell':cell,'alphaBounds':bounds,'packedOrigin':origin,'packedSize':cut.size,'footBaselineFromBottom':24,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
(OUT/'IMPORT.json').write_text(json.dumps({'operation':'alpha-preserving crop/resize/transparent padding only','sourceHashes':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [PORT,NEW]},'objects':records},indent=2)+'\n')
print('Imported six semantic map-object sprites; original source atlases unchanged.')
