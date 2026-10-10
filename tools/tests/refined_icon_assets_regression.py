#!/usr/bin/env python3
"""Check real alpha, dimensions, padding, neutral tint masks and stable imports."""
from pathlib import Path
from PIL import Image
import hashlib
import subprocess

root=Path(__file__).resolve().parents[2]
assets=root/'bin/res/assets/Images'
paths=[assets/'Icon/B'/name for name in ('r_2.png','r_3.png','r_4.png')]
paths += [assets/'UI/Adventure/Master/Icons'/name for name in ('port.png','barrel.png')]
before={p:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
subprocess.run(['python3',str(root/'tools/import_refined_icons.py')],check=True,cwd=root)
assert before=={p:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},'import is deterministic'
for p in paths:
    im=Image.open(p)
    size=64 if p.parent.name=='B' else 128
    assert im.mode=='RGBA' and im.size==(size,size)
    alpha=im.getchannel('A');assert alpha.getextrema()==(0,255)
    b=alpha.getbbox();assert min(b[:2])>=4 and max(b[2:])<=size-4
    # Cocos sprites use the full padded texture, not shared atlas rectangles.
    assert all(alpha.getpixel(q)==0 for q in ((0,0),(size-1,0),(0,size-1),(size-1,size-1)))
    if size==128:
        assert all((r,g,b)==(255,255,255) for r,g,b,a in im.getdata() if a)
    print('PASS refined alpha/padding/tint:',p.relative_to(root))
print('PASS exact deterministic import of five built-in-generated icon masters')
