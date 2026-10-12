#!/usr/bin/env python3
"""Run the original-map2 native prototype and inspect its unedited PNG evidence.
Requires the additive Cocos executable documented in clean_world_native.md.
Pillow/numpy only read PNG bytes; no image is drawn, repainted or composited here.
"""
from pathlib import Path
import argparse, hashlib, json, os, subprocess
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--capture-dir',required=True,type=Path)
p.add_argument('--native-bin',type=Path,default=Path('/workspace/shared/pirate-audit/clean-world-native/clean-world-native'))
p.add_argument('--verify-only',action='store_true')
a=p.parse_args();out=a.capture_dir.resolve();out.mkdir(parents=True,exist_ok=True)
base='923a04b6b2afabb53248d52ea5f2ea958b509245'
protected=sorted(set(root.glob('bin/res/assets/Images/Map/*.tmx'))|set(root.glob('bin/res/assets/Images/Map/*.png'))|set(root.glob('bin/res/**/*.csv'))|set(root.glob('bin/res/assets/Images/UI/CleanSea/**/*.png')))
for name in ('Explore','CleanFirstMap','CleanVoyageView','AdventureSea','FogManager','MapLayoutManagers','ExploreDataManager','AdventureNavigation','KnownRoute','WorldMapLayer','SeaChartWorldTheme','SeaChartTheme'):
 protected.append(root/'bin/res/scripts/LuaClass'/f'{name}.lua')
protected=[x for x in protected if x.is_file()]
digest=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
before={str(x.relative_to(root)):digest(x)for x in protected}
subprocess.run(['git','diff','--exit-code',base,'--',*before],cwd=root,check=True,stdout=subprocess.DEVNULL)
if not a.verify_only:
 env=os.environ.copy();env['RAISED_MAP2_CAPTURE_DIR']=str(out);env.setdefault('EGL_PLATFORM','surfaceless');env.setdefault('MESA_SHADER_CACHE_DISABLE','true')
 if env.get('PIRATE_RUNTIME'):env['LD_LIBRARY_PATH']=env['PIRATE_RUNTIME']+'/usr/lib/x86_64-linux-gnu:'+env.get('LD_LIBRARY_PATH','')
 with(out/'native.log').open('w')as log:subprocess.run([str(a.native_bin),'tools/tests/raised_map2_native.lua'],cwd=root,env=env,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=240)
assert before=={str(x.relative_to(root)):digest(x)for x in protected},'protected source mutation'
assert 'PASS raised map2 native prototype' in(out/'native.log').read_text()
def pixels(name):return np.asarray(Image.open(out/(name+'-v8.png')).convert('RGB')).astype(int)
reference=pixels('map2-restore-before');checks={}
for name in ('map2-restore-active','map2-restore-paused','map2-insertion','map2-removal','map2-reveal-return'):
 error=int(np.abs(reference-pixels(name)).max());assert error==0,(name,error);checks[name]={'maxPixelError':error}
actual=(np.asarray(Image.open(out/'source-alpha-eight-flips.png').convert('RGB'))>240).all(2)
expected=np.array([[c=='1'for c in row]for row in(out/'source-alpha-flips.txt').read_text().splitlines()])
assert actual.shape==expected.shape and np.array_equal(actual,expected),'native flip/alpha disagreement'
checks['eightSourceAlphaFlips']={'pixels':int(actual.size),'mismatches':0}
unknown=pixels('map2-all-unknown');assert np.all(unknown==[201,222,224]);checks['allUnknown']={'pixels':int(unknown.shape[0]*unknown.shape[1]),'leaks':0}
half=pixels('map2-half-known');yy,xx=np.indices(half.shape[:2]);sx=xx+.5-600;sy=760-yy-.5-380
wx=(sx/(.5**.5)-sy/((.5**.5)*.56))/2+992
hidden=wx>1028 # four world pixels beyond exact source discovery boundary
assert np.all(half[hidden]==[201,222,224]);checks['halfKnown']={'hiddenPixels':int(hidden.sum()),'leaks':0}
receipt={'baseCommit':base,'engine':'real Cocos TMX / Lua / surfaceless EGL; no GUI or player save','scope':'map2-only opt-in presentation prototype','protectedFileCount':len(before),'protectedHashes':before,'checks':checks,'nativePNGs':{x.name:digest(x)for x in sorted(out.glob('*.png'))},'limitations':['Hard fully-known-only fog clip; partial native fog silhouettes/animation not implemented.','Snapshot rebuild required after owner state changes; no Explore activation or movement dispatch.','Static original map2 event fixture plus synthetic live-layout identity/state contracts, not a full player session.','Portal/revive bitmaps remain legacy art; only source event identity is exact.','Per-tile clips and pixel-derived wall mesh need mobile profiling before extension.']}
(out/'evidence.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('PASS raised native pixel checks:',json.dumps(checks,sort_keys=True));print('Protected files unchanged:',len(before))
