#!/usr/bin/env python3
"""Inspect native PNG/GPU evidence without modifying images. Nonzero if the native contract fails; activation remains gated separately."""
from pathlib import Path
import argparse, hashlib, json, subprocess
import numpy as np
from PIL import Image
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--capture-dir',required=True,type=Path)
p.add_argument('--baseline-dir',required=True,type=Path)
p.add_argument('--record-only',action='store_true')
a=p.parse_args();root=Path(__file__).resolve().parents[2];out=a.capture_dir
checks={};blockers=[]
source=(root/'src/engine/cocos2d-x/cocos/2d/platform/android/javaactivity.cpp').read_text().split('    else\n    {',1)[1].split('\n    }',1)[0]
fixture=(root/'tools/tests/raised_map2_live_native.cpp').read_text().split('static int restore(',1)[1].split('static int textureHash',1)[0]
sequence=['invalidateStateCache','reloadDefaultShaders','DrawPrimitives::init','reloadAllTextures','EVENT_COME_TO_FOREGROUND','dispatchEvent','setGLDefaultValues']
for text in (source,fixture):
 positions=[text.index(call)for call in sequence];assert positions==sorted(positions),'Android context call order differs'
checks['androidRecoveryCallOrder']=sequence
def pixels(folder,name):return np.asarray(Image.open(folder/(name+'.png')).convert('RGBA')).astype(int)
def compare(folder,first,second):
 x,y=pixels(folder,first),pixels(folder,second)
 return {'maxChannelError':int(np.abs(x-y).max()),'changedPixels':int(np.count_nonzero(np.any(x!=y,axis=2)))}
log=(out/'native.log').read_text()
for marker in ('PASS live map2 initial native proof','PASS real controller parity','PASS native pause-save-resume','PASS native context and original-route fallback capture fixtures','PASS six active/paused context recoveries','PASS same-context texture replacement'):
 assert marker in log,marker
for name in ('live-child-added','live-child-removed','live-context-active','live-context-paused',*[f'live-context-repeat-{i}'for i in range(3,7)]):
 checks[name]=compare(out,'live-context-before',name)
 if checks[name]['changedPixels']:blockers.append(name)
checks['sourceInLive']=compare(out,'source-only-before','source-only-after')
checks['raisedOnly']=compare(out,'raised-only-before','raised-only-after')
checks['independentOriginalContext']=compare(a.baseline_dir,'original-context-before','original-context-after')
checks['independentOriginalPausedContext']=compare(a.baseline_dir,'original-context-before','original-context-paused')
for key in ('sourceInLive','raisedOnly','independentOriginalContext','independentOriginalPausedContext'):
 if checks[key]['changedPixels']:blockers.append(key)
# Exact source fog mask outside the full-known ground cells, with two native
# source pixels excluded along raster/stencil boundaries (no image alteration).
x,y=pixels(out,'live-fog-overlay'),pixels(out,'live-fog-reference')
lines=(out/'fog-transform.txt').read_text().splitlines()
p0,px,py=[np.array(list(map(float,line.split())))for line in lines[:3]]
m=np.array([px-p0,py-p0]).T;yy,xx=np.indices(x.shape[:2])
world=(np.stack([xx+.5,x.shape[0]-yy-.5],axis=2)-p0)@np.linalg.inv(m).T
tx=np.floor(world[:,:,0]/64).astype(int);ty=30-np.floor(world[:,:,1]/64).astype(int)
inside=(tx>=0)&(tx<31)&(ty>=0)&(ty<31)
unknown=np.array([[c=='1'for c in line]for line in lines[3:]])
mask=inside&unknown[np.clip(ty,0,30),np.clip(tx,0,30)]
border=np.minimum(np.mod(world,64),64-np.mod(world,64)).min(axis=2);mask&=border>2
error=int(np.abs(x[mask]-y[mask]).max());assert error==0,'Partial/unknown original fog pixels changed'
checks['partialUnknownFog']={'sampledPixels':int(mask.sum()),'maxChannelError':error}
def hashes(path):return dict(line.rsplit(' ',1)for line in path.read_text().splitlines())
before,after=hashes(out/'texture-before.txt'),hashes(out/'texture-after.txt')
checks['liveGPUTextures']={k:{'before':v,'after':after[k],'equal':v==after[k]}for k,v in before.items()}
checks['originalGPUTexturesEqual']=hashes(a.baseline_dir/'texture-before.txt')==hashes(a.baseline_dir/'texture-after.txt')
assert checks['originalGPUTexturesEqual']
checks['repeatedGPUTextures']={str(i):hashes(out/f'texture-repeat-{i}.txt')==before for i in range(3,7)}
if not all(checks['repeatedGPUTextures'].values()):blockers.append('repeated GPU texture restoration')
counts=[list(map(int,line.split()))for line in (out/'texture-counts.txt').read_text().splitlines()]
assert len(counts)==5 and [r[0]for r in counts]==list(range(2,7))
checks['textureNamesAndCacheEntries']={'cycles':counts,'stable':all(r[1:]==counts[0][1:]for r in counts),'staleDeletes':counts[-1][-1]}
if not checks['textureNamesAndCacheEntries']['stable'] or counts[-1][-1]!=0:blockers.append('texture lifetime counts')
if any(not v['equal']for v in checks['liveGPUTextures'].values()):blockers.append('live GPU texture restoration')
pixelTextureParity=not blockers
bufferChecks={}
for name,folder in (('live',out),('original',a.baseline_dir)):
 rows=[list(map(int,line.split()))for line in (folder/'buffer-counts.txt').read_text().splitlines()]
 assert len(rows)==5 and all(len(r)==5 for r in rows)
 samePhase=all(len({r[1]for r in rows if r[0]%2==phase})==1 for phase in (0,1))
 oneListener=all(r[2]==r[3] and r[4]==1 for r in rows)
 bufferChecks[name]={'columns':['cycle','liveBufferNames','drawNodes','drawListeners','maxListenersPerDrawNode'],'cycles':rows,'samePhaseBufferCountStable':samePhase,'oneListenerPerDrawNode':oneListener}
 if not samePhase or not oneListener:blockers.append(name+' buffer/listener growth')
 for i in range(3,7):
  if name=='original':
   result=compare(folder,'original-context-before',f'original-context-repeat-{i}')
   checks[f'original-context-repeat-{i}']=result
   if result['changedPixels']:blockers.append(f'original-context-repeat-{i}');pixelTextureParity=False
checks['bufferAndDrawListenerLifetime']=bufferChecks
resourceLifetimeReady=all(v['samePhaseBufferCountStable'] and v['oneListenerPerDrawNode']for v in bufferChecks.values())
base='4925032767ae9ab1451623d4e9c3cca81aabcd7e'
paths=sorted(set(root.glob('bin/res/assets/Images/Map/*.tmx'))|set(root.glob('bin/res/assets/Images/Map/*.png'))|set(root.glob('bin/res/**/*.csv'))|set(root.glob('bin/res/assets/Images/UI/CleanSea/**/*.png')))
for name in ('CleanFirstMap','CleanVoyageView','AdventureSea','FogManager','MapLayoutManagers','ExploreDataManager','AdventureNavigation','KnownRoute','WorldMapLayer','SeaChartWorldTheme','SeaChartTheme','EventLayer'):
 paths.append(root/'bin/res/scripts/LuaClass'/f'{name}.lua')
digest=lambda raw:hashlib.sha256(raw).hexdigest()
protected={}
for path in paths:
 rel=path.relative_to(root).as_posix();old=subprocess.check_output(['git','show',f'{base}:{rel}'],cwd=root)
 assert old==path.read_bytes(),f'Protected source changed: {rel}'
 protected[rel]=digest(old)
receipt={'base':base,'scope':'Explicit runtime-only map2 live adapter, default off; no profile or GUI used',
 'adapterBase':'19eff906e66d73647b421d78e1cadd7d2b771e3e',
 'activationReady':False,'nativeContextParity':pixelTextureParity,'resourceLifetimeReady':resourceLifetimeReady,'nativeBlockers':blockers,
 'activationGates':['Independent source review','Actual desktop route visual/input QA','Android runtime and mobile profiling','Full event/combat/return and semantic populated-route art acceptance'],'checks':checks,'protectedFiles':protected,
 'nativePNGs':{p.name:digest(p.read_bytes())for p in sorted(out.glob('*.png'))},
 'limits':['Seeded native controller with deterministic event dispatch/encounter probes, not a full battle playthrough.',
 'Native partial/fading fog and source actors retained; partial cells retain original ground art.',
 'Legacy portal/revive/occupied art and upright dynamic actor/populated-route art acceptance remain pending.',
 'Six-cycle texture/VBO-name and DrawNode-listener checks are bounded fixture evidence, not an all-GPU or process leak guarantee.',
 'Mesa EGL context fixture is not Android-device or mobile-performance acceptance.']}
(out/'VERIFICATION.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(('BLOCKED: '+', '.join(blockers))if blockers else 'PASS native live-map2 contract; activation remains gated')
print('Original source unchanged:',len(protected),'Partial/unknown pixels:',int(mask.sum()))
raise SystemExit(1 if blockers and not a.record_only else 0)
