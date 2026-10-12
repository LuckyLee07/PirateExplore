#!/usr/bin/env python3
"""Read-only pixel/scale/contact/provenance assertions for semantic map sprites."""
from pathlib import Path
from PIL import Image
import hashlib,json,numpy as np
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'bin/res/assets/Images/UI/CleanSeaObjects'
manifest=json.loads((OUT/'IMPORT.json').read_text())
for relative,sha in manifest['sourceHashes'].items():assert hashlib.sha256((ROOT/relative).read_bytes()).hexdigest()==sha
specs={'port':(112,140.5),'world-chart':(68,134),'resurrection':(60,132),'gateway':(76,130),'tavern':(90,130),'arena':(96,130.5)}
checks={}
for family,(extent,cx) in specs.items():
 path=OUT/(family+'-v1.png');im=Image.open(path);assert im.mode=='RGBA' and im.size==(256,256)
 assert hashlib.sha256(path.read_bytes()).hexdigest()==manifest['objects'][family]['sha256']
 alpha=np.asarray(im)[:,:,3];visible=alpha>=128;yy,xx=np.where(visible);assert len(xx)>1000
 left,top,right,bottom=int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)
 assert abs((left+right)/2-cx)<.01,'horizontal contact anchor must center visible object'
 scale=extent/224;foot=(256-bottom-.18*256)*scale;center=4;radius=extent*.14
 assert center-radius<=foot<=center+radius,'opaque feet must intersect contact band, never hover above it'
 assert extent<=112 and (right-left)*scale<=112 and (bottom-top)*scale<=112
 assert not np.any(alpha[[0,-1],:]>32) and not np.any(alpha[:,[0,-1]]>32),'sprite cut by cell edge'
 checks[family]={'opaqueBounds':[left,top,right,bottom],'visibleWidth':(right-left)*scale,'frontFootY':foot,'waterContactBand':[center-radius,center+radius]}
print('PASS semantic sprite alpha, modest real scale, centered ground/water contact and retained source hashes')
print(json.dumps(checks,sort_keys=True))
