#!/usr/bin/env python3
"""Compile current Record/binding against built engine libraries; no game/GUI.

Requires the existing Linux CMake build and optional PIRATE_RUNTIME SDK.
Only fresh TemporaryDirectory files are written; no real profile is opened.
"""
from pathlib import Path
import os, shlex, subprocess, tempfile
root=Path(__file__).resolve().parents[2]
build=Path(os.environ.get('PIRATE_BUILD_DIR',root/'build/linux')).resolve()
meta=build/'CMakeFiles/PirateExplore.dir'
flags={}
for line in (meta/'flags.make').read_text().splitlines():
    if ' = ' in line:
        key,value=line.split(' = ',1);flags[key]=shlex.split(value)
link=shlex.split((meta/'link.txt').read_text());compiler=link[0]
env=os.environ.copy();extra=[]
sanitize=['-fsanitize=address','-fno-omit-frame-pointer'] if env.get('PIRATE_NATIVE_ASAN') else []
runtime=env.get('PIRATE_RUNTIME')
if runtime:
    extra=['-I'+runtime+'/usr/include']
    for key in ['LD_LIBRARY_PATH','LIBRARY_PATH']:
        env[key]=runtime+'/usr/lib/x86_64-linux-gnu:'+env.get(key,'')
with tempfile.TemporaryDirectory(prefix='pirate-record-native-') as temporary:
    temp=Path(temporary);objects=[]
    sources=[root/'tools/tests/record_atomic_native.cpp',
             root/'src/NewPirate/common/UtilTools/Record.cpp',
             root/'src/NewPirate/common/UtilTools/LZSS.cpp',
             root/'src/NewPirate/game/ToLua/TOLUA_LuaRecord.cpp']
    for source in sources:
        obj=temp/(source.stem+'.o');objects.append(str(obj))
        subprocess.run([compiler,*flags['CXX_DEFINES'],*flags['CXX_INCLUDES'],*extra,
                        *sanitize,'-std=c++11','-g','-c',str(source),'-o',str(obj)],check=True,env=env)
    # Checked-in immutable baseline works in shallow/squashed clones as well.
    # See the fixture README for original revision and content hashes.
    legacy=root/'tools/tests/fixtures/legacy_record/Record.cpp'
    legacyObj=temp/'LegacyRecord.o';objects.append(str(legacyObj))
    subprocess.run([compiler,*flags['CXX_DEFINES'],*flags['CXX_INCLUDES'],*extra,
                    *sanitize,'-DRecord=LegacyRecord','-std=c++11','-g','-c',str(legacy),
                    '-o',str(legacyObj)],check=True,env=env)
    args=[];skip=False
    for token in link[1:]:
        if skip:skip=False;continue
        if token=='-o':skip=True;continue
        if token.endswith('.o') or token.startswith('-Wl,--dependency-file=') or token=='-DNDEBUG':continue
        args.append(token)
    out=temp/'record-atomic-native'
    subprocess.run([compiler,*sanitize,*objects,*args,'-o',str(out)],cwd=build,check=True,env=env)
    profile=temp/'synthetic-profile';profile.mkdir();env['XDG_CONFIG_HOME']=str(profile)
    subprocess.run([str(out)],cwd=root,check=True,env=env)
