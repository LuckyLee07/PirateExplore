#!/usr/bin/env python3
"""Verify the bounded native map2 HUD/actor delta, including exact source scope."""
from pathlib import Path
import argparse, hashlib, json, subprocess, os, re
import numpy as np
from PIL import Image
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--evidence',required=True,type=Path);p.add_argument('--guarded-rollout',action='store_true');a=p.parse_args()
root=Path(__file__).resolve().parents[2];out=a.evidence;checks={}
# The fixture can report a native/Lua error and still return zero. A success
# marker never cancels an assertion earlier in the same log.
for name in ('controller','baseline','objects-480','objects-360','hud-480','hud-360'):
 log=(out/name/'native.log').read_text()
 assert 'PASS native clean-world fixture' in log,name
 assert not re.search(r'LUA ERROR|Assert failed|Assertion failed|Invalid index|Segmentation fault|attempt to|stack traceback|cocos2d:\s*error:|wrong number of arguments|argument #\d+[^\n]*expected|#ferror|invalid [\"\']cobj',log,re.I),name+' contains native/Lua errors'
checks['strictNativeErrorGate']='six fixture logs contain final success and no native/Lua errors'
def image(folder,name):return np.asarray(Image.open(folder/(name+'.png')).convert('RGBA')).astype(int)
def pixels(folder,first,last):
 x,y=image(folder,first),image(folder,last);diff=np.abs(x-y)
 result={'maxChannelError':int(diff.max()),'changedPixels':int(np.any(diff,axis=2).sum())}
 assert result['changedPixels']==0,(folder,last,result)
 checks[str(folder.relative_to(out))+'/'+last]=result

def fog(folder,first,last):
 x,y=image(folder,first),image(folder,last);lines=(folder/'fog-transform.txt').read_text().splitlines()
 origin,px,py=[np.array(list(map(float,line.split())))for line in lines[:3]]
 matrix=np.array([px-origin,py-origin]).T;yy,xx=np.indices(x.shape[:2]);world=(np.stack([xx+.5,x.shape[0]-yy-.5],axis=2)-origin)@np.linalg.inv(matrix).T
 tx=np.floor(world[:,:,0]/64).astype(int);ty=30-np.floor(world[:,:,1]/64).astype(int)
 unknown=np.array([[c=='1'for c in line]for line in lines[3:]])
 mask=(tx>=0)&(tx<31)&(ty>=0)&(ty<31)&unknown[np.clip(ty,0,30),np.clip(tx,0,30)]
 mask&=np.minimum(np.mod(world,64),64-np.mod(world,64)).min(axis=2)>2
 error=int(np.abs(x[mask]-y[mask]).max());assert mask.sum()>1000 and error==0
 checks[str(folder.relative_to(out))+'/nativeUnknownFog']={'sampledPixels':int(mask.sum()),'maxChannelError':error}
def buffers(folder,name,skip_warmup=False):
 rows=[list(map(int,line.split()))for line in (folder/name).read_text().splitlines()]
 steady=rows[1:]if skip_warmup else rows
 assert all(len({r[1]for r in steady if r[0]%2==phase})==1 for phase in (0,1)),(folder,rows)
 assert all(r[2]==r[3] and r[4]==1 for r in rows)
 checks[str(folder.relative_to(out))+'/drawLifetime']={'cycles':rows,'samePhaseStableAfterWarmup':True,'oneContextListenerPerDrawNode':True}
controller,baseline=out/'controller',out/'baseline'
for marker in ['PASS live map2 initial native proof','PASS real controller parity','PASS native pause-save-resume','PASS six active/paused context recoveries','PASS native context and original-route fallback capture fixtures']:
 assert marker in (controller/'native.log').read_text(),marker
for name in ['live-child-added','live-child-removed','live-context-active','live-context-paused',*[f'live-context-repeat-{i}'for i in range(3,7)]]:pixels(controller,'live-context-before',name)
for first,last in [('source-only-before','source-only-after'),('raised-only-before','raised-only-after')]:pixels(controller,first,last)
for name in ['original-context-after','original-context-paused',*[f'original-context-repeat-{i}'for i in range(3,7)]]:pixels(baseline,'original-context-before',name)
fog(controller,'live-fog-overlay','live-fog-reference');buffers(controller,'buffer-counts.txt');buffers(baseline,'buffer-counts.txt')
for folder in (controller,baseline):assert (folder/'texture-before.txt').read_bytes()==(folder/'texture-after.txt').read_bytes()
for i in range(3,7):assert (controller/'texture-before.txt').read_bytes()==(controller/f'texture-repeat-{i}.txt').read_bytes()
for width in (480,360):
 folder=out/f'objects-{width}';log=(folder/'native.log').read_text()
 for marker in ['PASS six exact semantic-object toggles','PASS live occupancy','PASS hidden/partial/animated fog','PASS six active/paused object context recoveries','PASS parent cleanup']:assert marker in log,marker
 pixels(folder,f'compact{width}-original-before',f'compact{width}-original-after')
 for i in range(1,7):pixels(folder,f'compact{width}-context-before',f'compact{width}-context-{i}')
 fog(folder,'objects-fog-overlay','objects-fog-reference');buffers(folder,'object-buffer-counts.txt')
 folder=out/f'hud-{width}';log=(folder/'native.log').read_text()
 for marker in ['PASS shafted projected controls','PASS native touch cancellation','PASS interrupted HUD generations','PASS owner-local method leases','PASS actual pause, chart and log access','PASS native actor/art hide-show','PASS native actor replacement','PASS second-owner nested mount/unmount','PASS coast boundary clip']:
  assert marker in log,(width,marker)
 for i in range(1,7):pixels(folder,'context-before',f'context-{i}')
 buffers(folder,'context-counts.txt',True)
 # The original outside-map decorative-gutter counterfactual is retained.
 fixed=image(folder,'compact-edge-fixed');bad=image(folder,'outside-coast-counterfactual')
 opaque=np.all(fixed[:,:,:3]==(3,35,52),axis=2)
 assert np.any(opaque & ((bad[:,:,1]>70)|(bad[:,:,2]>70))),'edge counterfactual did not expose the original fringe'
 assert tuple(fixed[95,0,:3])==(3,35,52),'outside-map chart ink differs from native opaque fog'
 source=image(folder,'compact-edge-source-only');assert np.array_equal(fixed[130:210,170:260],source[130:210,170:260]),'isolated native fog specks differ'
 checks[f'hud-{width}/outsideMapCoast']={'counterfactualRetained':True,'opaqueInk':[3,35,52]}
base='a18c54f05a3a678aabc957a0a3d07dc6c40faaf8' if a.guarded_rollout else '6106b2b579712438681ed05ecd594c8cd3f135ee'
def git(*args):return subprocess.check_output(['git',*args],cwd=root)
allowed={'bin/res/scripts/LuaClass/RaisedSeaMap2Live.lua','tools/tests/raised_map2_live_native.cpp'}
if a.guarded_rollout:
 allowed={'README.md','bin/res/scripts/LuaClass/Explore.lua','bin/res/scripts/LuaClass/RaisedSeaMap2Live.lua',
  'tools/tests/coherent_intelligence_return_conservation.py','tools/tests/raised_map2_live_native.lua',
  'tools/tests/raised_map2_hud_boat_native.lua','tools/tests/verify_raised_map2_hud_boat.py'}
 old=git('show',base+':bin/res/scripts/LuaClass/Explore.lua').decode()
 expected=old.replace("    if rawget(_G,'RAISED_MAP2_LIVE')==true then RaisedSeaMap2Live.mount(self)end",'    RaisedSeaMap2Live.mount(self)')
 assert (root/'bin/res/scripts/LuaClass/Explore.lua').read_text()==expected,'Explore delta exceeds guarded end-of-init activation'
 for width in (480,360):
  folder=out/f'guard-{width}';log=(folder/'native.log').read_text()
  assert 'PASS guarded default map2' in log and 'PASS native clean-world fixture' in log
  assert 'PASS malformed optional APIs: 122 missing/noncallable' in log
  assert len(list(folder.glob('original-api-*.png')))==122
  assert 'PASS malformed package metadata: 50' in log
  assert len(list(folder.glob('original-metadata-*.png')))==50
  assert not re.search(r'LUA ERROR|Assert failed|Assertion failed|Invalid index|Segmentation fault|attempt to|stack traceback|cocos2d:\s*error:|wrong number of arguments|argument #\d+[^\n]*expected|#ferror|invalid [\"\']cobj',log,re.I)
  for path in folder.glob('*.png'):pixels(folder,'original-reference',path.stem)
 checks['guardedDefault']='Default map2 only; read-only negative preflight and exact original pixels at 480/360'
entries=git('ls-tree','-r','-z',base).split(b'\0');protected={}
reader=subprocess.Popen(['git','cat-file','--batch'],cwd=root,stdin=subprocess.PIPE,stdout=subprocess.PIPE)
try:
 for entry in entries:
  if not entry:continue
  metadata,path=entry.split(b'\t',1);mode,kind,oid=metadata.split();file=path.decode()
  if file in allowed:continue
  reader.stdin.write(oid+b'\n');reader.stdin.flush()
  header=reader.stdout.readline().split();old=reader.stdout.read(int(header[2]));assert reader.stdout.read(1)==b'\n'
  target=root/file;actual=os.readlink(target).encode()if target.is_symlink()else target.read_bytes()
  assert actual==old,'Protected source changed: '+file
  protected[file]=hashlib.sha256(old).hexdigest()
finally:
 reader.stdin.close();reader.stdout.close();reader.wait()
checks['exactProtectedSourceFiles']=len(protected)
assert git('diff','--', 'src/engine')==b''
for path in ['RaisedSeaMap2Live.lua','RaisedSeaMap2Boat.lua','RaisedSeaMap2HUD.lua']:
 source=(root/'bin/res/scripts/LuaClass'/path).read_text()
 for forbidden in ['setRoleData','setMapData','commitAdventure','saveCurDatas','saveDataAtomic']:assert forbidden not in source,(path,forbidden)
cpp=(root/'tools/tests/raised_map2_live_native.cpp').read_text();old=git('show',base+':tools/tests/raised_map2_live_native.cpp').decode()
start=cpp.index('// Test-only held/cancelled gestures');end=cpp.index('\nint main(',start)
normalized=cpp[:start]+cpp[end+1:];normalized=normalized.replace('lua_register(L,"liveMap2Gesture",liveGesture);','')
assert (cpp if a.guarded_rollout else normalized)==old,'Native fixture change exceeds accepted test-only gesture API'
checks['testHarnessOnlyDelta']='Begin/Move/End/Cancel GLView API; production engine exact'
receipt={'base':base,'activationReady':False,'nativeContractPassed':True,'checks':checks,
 'sourceSHA256':{str(f.relative_to(root)):hashlib.sha256(f.read_bytes()).hexdigest()for f in [*(root/'bin/res/scripts/LuaClass').glob('RaisedSeaMap2*.lua'),root/'tools/tests/raised_map2_hud_boat_native.lua',root/'tools/tests/raised_map2_live_native.cpp']},
 'scope':'Guarded map2 default; seeded native evidence only, no GUI/publication/profile used here.' if a.guarded_rollout else 'Map2 runtime-only presentation; no GUI, publication, profile or production activation.',
 'limits':['Seeded native controller/render fixture, not natural progression.','Cargo/return tests verify delegation targets; full contents and actual desktop interaction require isolated app review.','Source-art actions use original art for their native action lifetime.','Six context cycles are bounded EGL evidence, not Android/device or indefinite leak acceptance.']}
(out/'HUD_BOAT_VERIFICATION.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('PASS map2 HUD/boat native contract; exact protected source files:',len(protected),'guarded default; actual application validation is separate' if a.guarded_rollout else 'activation remains off')
