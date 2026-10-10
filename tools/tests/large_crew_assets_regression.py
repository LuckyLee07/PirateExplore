#!/usr/bin/env python3
from pathlib import Path
from PIL import Image
import hashlib,subprocess
root=Path(__file__).resolve().parents[2]
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
small={p:digest(p) for p in (root/'bin/res/assets/Images/Icon/B').glob('crew-*.png')}
large=[root/f'bin/res/assets/Images/UI/Adventure/Master/Portraits/crew-{id}.png' for id in (100,101)]
old={p:digest(p) for p in large}
subprocess.run(['python3','tools/import_large_crew_art.py'],cwd=root,check=True)
assert old=={p:digest(p) for p in large},'large import must be reproducible'
assert small=={p:digest(p) for p in small},'existing small portraits must not change'
for p in large:
    im=Image.open(p);assert im.mode=='RGBA' and max(im.size)==528 and min(im.size)>=400
    a=im.getchannel('A');assert a.getextrema()==(0,255)
    b=a.getbbox();assert b[0]>=8 and b[1]>=8 and b[2]<=im.width-8 and b[3]<=im.height-8
    assert min(im.size)>2*185,'large art must have actual headroom, not64px upscale'
    print('PASS large crew real alpha, padding, resolution:',p.name,im.size)
print('PASS deterministic large portraits and all five existing64px crew files unchanged')
