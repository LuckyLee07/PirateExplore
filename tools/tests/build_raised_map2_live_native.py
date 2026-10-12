#!/usr/bin/env python3
"""Build current texture fix and fixture; compile both bundled cache branches. Donors stay read-only."""
from pathlib import Path
import os, shlex, subprocess, hashlib, json
root=Path(__file__).resolve().parents[2]
build=Path(os.environ['PIRATE_BUILD_DIR']).resolve()
donor=Path(os.environ['CLEAN_WORLD_BUILD_DIR']).resolve()
out=Path(os.environ['RAISED_MAP2_LIVE_BUILD_DIR']).resolve();out.mkdir(parents=True,exist_ok=True)
assert out!=build and build not in out.parents and out!=donor
meta=build/'CMakeFiles/PirateExplore.dir';flags={}
for line in (meta/'flags.make').read_text().splitlines():
 if ' = ' in line:
  k,v=line.split(' = ',1);flags[k]=shlex.split(v)
link=shlex.split((meta/'link.txt').read_text());env=os.environ.copy();extra=[]
if env.get('PIRATE_RUNTIME'):
 runtime=env['PIRATE_RUNTIME'];extra=['-I'+runtime+'/usr/include'];env['LIBRARY_PATH']=runtime+'/usr/lib/x86_64-linux-gnu';env['LD_LIBRARY_PATH']=env['LIBRARY_PATH']
# Compile against this worktree's bundled headers, never a stale donor header.
flags['CXX_INCLUDES']=[v.replace(str(build.parents[1]),str(root))for v in flags['CXX_INCLUDES']]
for cache in (0,1):
 header=out/f'cache-{cache}.h'
 header.write_text('#include "base/CCPlatformMacros.h"\n#undef CC_ENABLE_CACHE_TEXTURE_DATA\n#define CC_ENABLE_CACHE_TEXTURE_DATA '+str(cache)+'\n')
 for name in ('CCTexture2D','CCDrawNode'):
  subprocess.run([link[0],*flags['CXX_DEFINES'],*flags['CXX_INCLUDES'],*extra,'-include',str(header),'-std=c++11','-g','-c',str(root/f'src/engine/cocos2d-x/cocos/2d/{name}.cpp'),'-o',str(out/f'{name}-cache-{cache}.o')],env=env,check=True)
  print(f'PASS {name} current bundled headers CC_ENABLE_CACHE_TEXTURE_DATA={cache}',flush=True)
objects=[]
for source in (root/'tools/tests/raised_map2_live_native.cpp',root/'src/engine/cocos2d-x/cocos/2d/CCTexture2D.cpp',root/'src/engine/cocos2d-x/cocos/2d/CCDrawNode.cpp'):
 obj=out/(source.stem+'-current.o');objects.append(str(obj))
 subprocess.run([link[0],*flags['CXX_DEFINES'],*flags['CXX_INCLUDES'],*extra,'-include',str(out/'cache-1.h'),'-std=c++11','-g','-c',str(source),'-o',str(obj)],env=env,check=True)
links=[];skip=False
for token in link[1:]:
 if skip:skip=False;continue
 if token=='-o':skip=True;continue
 if token.endswith('.o') or token.startswith('-Wl,--dependency-file='):continue
 links.append(token)
objects += [str(p)for p in sorted(donor.glob('*.o'))if p.name not in ('clean_world_native.o','CCTexture2D.o','CCDrawNode.o')]
subprocess.run([link[0],*objects,*links,'-lEGL','-Wl,--wrap=_ZN7cocos2d6Device6getDPIEv','-Wl,--wrap=glDeleteTextures','-Wl,--wrap=glGenTextures','-o',str(out/'raised-map2-live-native')],cwd=build,env=env,check=True)
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs=[root/'src/engine/cocos2d-x/cocos/2d'/f'{n}.cpp'for n in ('CCTexture2D','CCDrawNode')]+[root/'tools/tests'/f'raised_map2_live_native.{ext}'for ext in ('cpp','lua')]
archives=[build/t for t in links if t.endswith('.a') and (build/t).is_file()]
receipt={'compiler':subprocess.check_output([link[0],'--version'],text=True).splitlines()[0],
 'sourceSHA256':{str(p.relative_to(root)):digest(p)for p in inputs},
 'donorObjectSHA256':{p.name:digest(p)for p in donor.glob('*.o')if str(p)in objects},
 'archiveSHA256':{str(p):digest(p)for p in archives},
 'buildMetadataSHA256':{p.name:digest(p)for p in (meta/'flags.make',meta/'link.txt')},
 'binarySHA256':digest(out/'raised-map2-live-native'),
 'compileBranches':[0,1],'headerRoot':str(root),'linkInputs':links}
(out/'BUILD_RECEIPT.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(out/'raised-map2-live-native')
