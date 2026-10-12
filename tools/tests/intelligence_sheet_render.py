#!/usr/bin/env python3
"""Native production sheet QA with real GLView input, pixels and negative controls.
Surfaceless Cocos/EGL only. No GUI, profiles, remote writes or real billing.
Use PIRATE_BUILD_DIR for an existing Linux build and INTELLIGENCE_CAPTURE_DIR
for evidence. Optional INTELLIGENCE_NATIVE_BIN reuses its offscreen harness.
"""
from pathlib import Path
import os,shlex,subprocess,tempfile,shutil
from PIL import Image,ImageChops
root=Path(__file__).resolve().parents[2]
env=os.environ.copy();env.pop('LUA_INIT',None)
env.setdefault('EGL_PLATFORM','surfaceless');env.setdefault('MESA_SHADER_CACHE_DISABLE','true')
captures=Path(env.setdefault('INTELLIGENCE_CAPTURE_DIR','/tmp/intelligence-sheet')).resolve();captures.mkdir(parents=True,exist_ok=True)
build=Path(env.get('PIRATE_BUILD_DIR',root/'build/linux')).resolve()
if env.get('INTELLIGENCE_NATIVE_BIN'):
 native=Path(env['INTELLIGENCE_NATIVE_BIN']).resolve()
else:
 metadata=build/'CMakeFiles/PirateExplore.dir';flags={}
 for line in (metadata/'flags.make').read_text().splitlines():
  if ' = 'in line:key,value=line.split(' = ',1);flags[key]=shlex.split(value)
 link=shlex.split((metadata/'link.txt').read_text());compiler=link[0]
 native=captures/'intelligence-sheet-native';obj=native.with_suffix('.o')
 subprocess.run([compiler,*flags['CXX_DEFINES'],*flags['CXX_INCLUDES'],'-std=c++11','-g','-c',str(root/'tools/tests/world_chart_selector_render.cpp'),'-o',str(obj)],check=True,env=env)
 args=[];skip=False
 for token in link[1:]:
  if skip:skip=False;continue
  if token=='-o':skip=True;continue
  if token.endswith('.o')or token.startswith('-Wl,--dependency-file='):continue
  args.append(token)
 subprocess.run([compiler,str(obj),*args,'-lEGL','-Wl,--wrap=_ZN7cocos2d6Device6getDPIEv','-o',str(native)],cwd=build,check=True,env=env)
def run(test,cwd=root,name=None):
 result=subprocess.run([str(native),'tools/tests/'+test],cwd=cwd,env=env,text=True,capture_output=True,timeout=120)
 output=result.stdout+result.stderr;(captures/(name or Path(test).stem+'.log')).write_text(output)
 return result,output
for test in ('intelligence_sheet_native.lua','coherent_intelligence_return_ownership_native.lua'):
 result,output=run(test)
 assert result.returncode==0 and '[LUA ERROR]'not in output,output[-5000:]
 for line in output.splitlines():
  if 'PASS'in line:print(line)
# Inspect actual raster output, including title/close within safe bounds, and
# enforce unchanged full pixels after dynamic sibling insertion.
for line in (captures/'frames.tsv').read_text().splitlines():
 path,w,h,x,y,pw,ph=line.split('\t');w,h=int(w),int(h);x,y,pw,ph=map(float,(x,y,pw,ph))
 with Image.open(path)as original:im=original.convert('RGB')
 assert im.size==(w,h)
 top=h-y-ph
 title=im.crop((round(x+18),round(top+9),round(x+pw-94),round(top+48)))
 light=sum(n for n,p in title.getcolors(title.width*title.height)if min(p)>170)
 assert light>120,'Title not visibly rendered: '+path
 close=im.crop((round(x+pw-79),round(top+10),round(x+pw-16),round(top+51)))
 dark=sum(n for n,p in close.getcolors(close.width*close.height)if max(p)<150)
 assert dark>70,'Close text not visibly rendered: '+path
 assert x>=15 and y>=15 and x+pw<=w-15 and y+ph<=h-15,'Safe sheet margins'
 dynamic=Path(path).with_name(Path(path).stem+'-dynamic.png')
 if dynamic.exists():
  with Image.open(dynamic)as after:assert ImageChops.difference(im,after.convert('RGB')).getbbox()is None,'Header/content overwritten by dynamic sibling sorting'
print('PASS real native title/close pixels, viewport-safe margins, and identical dynamic-sibling frames')
subprocess.run(['python3','tools/tests/intelligence_sheet_conservation.py'],cwd=root,env=env,check=True)
# Overlay only the module under review. Base package bytes and engine are linked
# read-only; deliberate broken gestures/identity must fail exact native checks.
mutations=[
 ('missing-render-generation','buildEpoch==view.intelligenceRenderGeneration and ','','interrupted talent rebuild never opens shortage'),
 ('drag-activation','if armed and (math.abs(p.x-start.x)>8 or math.abs(p.y-start.y)>8)then reset()end','if false then reset()end','out-and-back drag never activates'),
 ('stale-source-generation','view.warmIntelligenceGeneration==generation and ','','interrupted talent generation never opens shortage'),
]
with tempfile.TemporaryDirectory(prefix='intelligence-native-negative-')as tmp:
 shadow=Path(tmp);(shadow/'bin/res').mkdir(parents=True)
 shutil.copytree(root/'bin/res/scripts',shadow/'bin/res/scripts')
 for path in ('src','tools'):(shadow/path).symlink_to(root/path,target_is_directory=True)
 (shadow/'bin/res/assets').symlink_to(root/'bin/res/assets',target_is_directory=True)
 path=shadow/'bin/res/scripts/LuaClass/IntelligencePresentation.lua';source=path.read_text()
 # Negative frames get a separate directory, preserving successful previews.
 successful=env['INTELLIGENCE_CAPTURE_DIR'];negative=captures/'negative';negative.mkdir(exist_ok=True);env['INTELLIGENCE_CAPTURE_DIR']=str(negative)
 for name,before,after,expected in mutations:
  assert source.count(before)==1;path.write_text(source.replace(before,after))
  result,output=run('intelligence_sheet_native.lua',shadow,name+'-counterfactual.log')
  assert result.returncode and expected in output,name+' did not fail its intended assertion: '+output[-2500:]
  print('PASS native counterfactual rejected: '+name)
 # Reproduce the real engine's equal-z re-sort failure, and prove the pixel
 # assertion distinguishes it from merely visible LabelTTF nodes.
 path.write_text(source.replace(':setLocalZOrder(-30)',':setLocalZOrder(-10)').replace(':setLocalZOrder(-20)',':setLocalZOrder(-10)'))
 result,output=run('intelligence_sheet_native.lua',shadow,'equal-z-header-counterfactual.log')
 assert result.returncode==0,output[-2500:]
 before=Image.open(negative/'intelligence-talent-360x640.png').convert('RGB')
 after=Image.open(negative/'intelligence-talent-360x640-dynamic.png').convert('RGB')
 assert ImageChops.difference(before,after).getbbox(),'Equal-z counterfactual did not lose rendered header/ribbon'
 print('PASS native pixel counterfactual rejected: equal-z header/ribbon overpaint')
 path.write_text(source);env['INTELLIGENCE_CAPTURE_DIR']=successful
print('PASS clean intelligence native render/input/conservation suite: '+str(captures))
