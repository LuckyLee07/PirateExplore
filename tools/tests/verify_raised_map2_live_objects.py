#!/usr/bin/env python3
"""Read-only verification of native object/context evidence and frozen source scope."""
from pathlib import Path
import argparse, hashlib, json, subprocess
import numpy as np
from PIL import Image
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--evidence',required=True,type=Path);a=p.parse_args()
root=Path(__file__).resolve().parents[2];out=a.evidence
base='e1e7fd8bddc960afe5a650092cb16bb7d7a98ebc';prototype='62790b07a29f1c2ccdef84d4b319264e48b61532'
checks={};failures=[]
def check(name,value):
 checks[name]=value
 if value is False:failures.append(name)
def image(folder,name):return np.asarray(Image.open(folder/(name+'.png')).convert('RGBA')).astype(int)
def pixels(folder,before,after):
 x,y=image(folder,before),image(folder,after);diff=np.abs(x-y)
 result={'maxChannelError':int(diff.max()),'changedPixels':int(np.any(diff!=0,axis=2).sum())}
 checks[str(folder.relative_to(out))+'/'+after]=result
 if result['changedPixels']:failures.append(str(folder.relative_to(out))+'/'+after)
def fog(folder,before,after):
 x,y=image(folder,before),image(folder,after);lines=(folder/'fog-transform.txt').read_text().splitlines()
 origin,px,py=[np.array(list(map(float,line.split())))for line in lines[:3]]
 matrix=np.array([px-origin,py-origin]).T;yy,xx=np.indices(x.shape[:2])
 world=(np.stack([xx+.5,x.shape[0]-yy-.5],axis=2)-origin)@np.linalg.inv(matrix).T
 tx=np.floor(world[:,:,0]/64).astype(int);ty=30-np.floor(world[:,:,1]/64).astype(int)
 inside=(tx>=0)&(tx<31)&(ty>=0)&(ty<31);unknown=np.array([[c=='1'for c in line]for line in lines[3:]])
 mask=inside&unknown[np.clip(ty,0,30),np.clip(tx,0,30)]
 mask&=np.minimum(np.mod(world,64),64-np.mod(world,64)).min(axis=2)>2
 error=int(np.abs(x[mask]-y[mask]).max());assert mask.sum()>1000
 checks[str(folder.relative_to(out))+'/unknownFog']={'sampledPixels':int(mask.sum()),'maxChannelError':error}
 if error:failures.append(str(folder.relative_to(out))+'/unknownFog')
def buffers(folder,name):
 rows=[list(map(int,line.split()))for line in (folder/name).read_text().splitlines()]
 stable=all(len({r[1]for r in rows if r[0]%2==phase})==1 for phase in (0,1))
 one=all(r[2]==r[3] and r[4]==1 for r in rows)
 checks[str(folder.relative_to(out))+'/buffers']={'columns':['cycle','liveBuffers','drawNodes','listeners','maxPerNode'],'cycles':rows,'samePhaseStable':stable,'oneListenerPerNode':one}
 if not stable or not one:failures.append(str(folder.relative_to(out))+'/buffers')
controller=out/'controller';baseline=out/'baseline'
for marker in ['PASS live map2 initial native proof','PASS real controller parity','PASS native pause-save-resume','PASS six active/paused context recoveries','PASS native context and original-route fallback capture fixtures']:
 check(marker,marker in (controller/'native.log').read_text())
for name in ['live-child-added','live-child-removed','live-context-active','live-context-paused',*[f'live-context-repeat-{i}'for i in range(3,7)]]:pixels(controller,'live-context-before',name)
for pair in [('source-only-before','source-only-after'),('raised-only-before','raised-only-after')]:pixels(controller,*pair)
for name in ['original-context-after','original-context-paused',*[f'original-context-repeat-{i}'for i in range(3,7)]]:pixels(baseline,'original-context-before',name)
fog(controller,'live-fog-overlay','live-fog-reference');buffers(controller,'buffer-counts.txt');buffers(baseline,'buffer-counts.txt')
for folder in [controller,baseline]:
 before=(folder/'texture-before.txt').read_text()
 check(str(folder.relative_to(out))+'/GPUTextures',before==(folder/'texture-after.txt').read_text())
for i in range(3,7):check('controller/GPUTexturesRepeat'+str(i),(controller/'texture-before.txt').read_text()==(controller/f'texture-repeat-{i}.txt').read_text())
rows=[list(map(int,line.split()))for line in (controller/'texture-counts.txt').read_text().splitlines()]
check('controller/TextureLifetime',all(r[1:]==rows[0][1:] and r[-1]==0 for r in rows))
for width in (480,360):
 folder=out/f'objects-{width}';log=(folder/'native.log').read_text()
 for marker in ['PASS six exact semantic-object toggles','PASS live occupancy','PASS hidden/partial/animated fog','PASS six active/paused object context recoveries','PASS parent cleanup']:
  check(f'objects-{width}/'+marker,marker in log)
 pixels(folder,f'compact{width}-original-before',f'compact{width}-original-after')
 for i in range(1,7):pixels(folder,f'compact{width}-context-before',f'compact{width}-context-{i}')
 fog(folder,'objects-fog-overlay','objects-fog-reference');buffers(folder,'object-buffer-counts.txt')
def git(*args):return subprocess.check_output(['git',*args],cwd=root)
changed=git('diff','--name-only',base,'--').decode().splitlines()
allowed={'bin/res/scripts/LuaClass/RaisedSeaMap2.lua','bin/res/scripts/LuaClass/RaisedSeaMap2Live.lua'}
# Existing tracked files must retain exact identity beyond the narrow two-file adapter/palette delta.
existing=git('ls-tree','-r','--name-only',base).decode().splitlines()
check('protectedExistingSource',all(path in allowed for path in changed if path in existing))
rpath='bin/res/scripts/LuaClass/RaisedSeaMap2.lua';expected=git('show',base+':'+rpath).decode().replace('c(218,198,161)','c(231,211,174)').replace('c(200,183,150)','c(184,167,134)')
check('rendererExactTwoColorDelta',(root/rpath).read_text()==expected)
imports=[root/'bin/res/scripts/LuaClass/RaisedSeaObjectPresentation.lua',*(root/'bin/res/assets/Images/UI/CleanSeaObjects').rglob('*')]
imports=[p for p in imports if p.is_file()]
check('prototypeImportByteIdentity',all(p.read_bytes()==git('show',prototype+':'+p.relative_to(root).as_posix())for p in imports))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
receipt={'base':base,'prototype':prototype,'activationReady':False,'inheritedSourceHold':'Recovery-shortage ownership HOLD in base e1e7; separate repair not imported here.',
 'nativeContractPassed':not failures,'checks':checks,'failures':failures,
 'sourceSHA256':{str(p.relative_to(root)):sha(p) for p in [root/rpath,root/'bin/res/scripts/LuaClass/RaisedSeaMap2Live.lua',root/'bin/res/scripts/LuaClass/RaisedSeaMap2ObjectsLive.lua',*imports]},
 'nativePNG_SHA256':{str(p.relative_to(out)):sha(p)for folder in ['controller','baseline','objects-480','objects-360']for p in sorted((out/folder).glob('*.png'))},
 'limits':['Seeded native EGL controller and semantic occupancy fixtures, not independent desktop GUI/device/full-session acceptance.',
 'Six context cycles and retained native lifetime counts are bounded evidence, not an unbounded leak proof.',
 'Animated native sites conservatively restore their authored sprite before runAction; replacements never own actor actions.',
 'Mixed-viewport/recentering diagnostics and the e1e7 equal-Z counterfactual remain preserved; final recovery captures freeze exact native camera matrices. Production window-resize behavior is not accepted here.']}
(out/'VERIFICATION.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('PASS native live-map2 object adapter' if not failures else 'FAIL '+', '.join(failures));raise SystemExit(bool(failures))
