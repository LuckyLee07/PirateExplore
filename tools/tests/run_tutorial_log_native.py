#!/usr/bin/env python3
"""Build/run isolated native LabelTTF and ScrollView regression on surfaceless EGL.
Uses an existing Linux Makefiles build; never opens a GUI or loads a save.
Set PIRATE_BUILD_DIR and PIRATE_RUNTIME as for linux.sh.
"""
from pathlib import Path
import os,shlex,subprocess
root=Path(__file__).resolve().parents[2]
build=Path(os.environ.get('PIRATE_BUILD_DIR',root/'build/linux')).resolve()
meta=build/'CMakeFiles/PirateExplore.dir'
assert (meta/'link.txt').is_file(), 'Build linux.sh with Unix Makefiles first.'
flags={}
for line in (meta/'flags.make').read_text().splitlines():
    if ' = ' in line:
        key,value=line.split(' = ',1);flags[key]=shlex.split(value)
link=shlex.split((meta/'link.txt').read_text()); compiler=link[0]
out=build/'tests/tutorial-log-native';out.parent.mkdir(parents=True,exist_ok=True)
obj=out.with_suffix('.o')
env=os.environ.copy()
env.setdefault('MESA_SHADER_CACHE_DISABLE','true')
runtime=env.get('PIRATE_RUNTIME')
extra=[]
if runtime:
    extra=['-I'+runtime+'/usr/include']
    env['LD_LIBRARY_PATH']=runtime+'/usr/lib/x86_64-linux-gnu:'+env.get('LD_LIBRARY_PATH','')
    env['LIBRARY_PATH']=runtime+'/usr/lib/x86_64-linux-gnu:'+env.get('LIBRARY_PATH','')
obj=out.with_suffix('.o')
subprocess.run([compiler,*flags['CXX_DEFINES'],*flags['CXX_INCLUDES'],*extra,'-std=c++11','-g','-c',str(root/'tools/tests/tutorial_log_native.cpp'),'-o',str(obj)],check=True,env=env)
args=[];skip=False
for token in link[1:]:
    if skip:skip=False;continue
    if token=='-o':skip=True;continue
    if token.endswith('.o') or token.startswith('-Wl,--dependency-file='):continue
    args.append(token)
subprocess.run([compiler,str(obj),*args,'-lEGL','-o',str(out)],cwd=build,check=True,env=env)
subprocess.run([str(out),str(root/'tools/tests/tutorial_log_native.lua')],cwd=root,check=True,env=env)
