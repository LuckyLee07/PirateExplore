#!/usr/bin/env python3
"""Build/run native Cocos lifecycle checks from an already built Makefiles tree.

Set PIRATE_BUILD_DIR and (for the extracted SDK) PIRATE_RUNTIME as for linux.sh.
The EGL context recreation and texture cache/readback run actual engine source.
A test-only forced-cache build selects the Android cache branch on Linux; mobile
app/platform integration and drivers still require an Android build/device.
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
out=build/'tests/chart-lifecycle-native';out.parent.mkdir(parents=True,exist_ok=True)
obj=out.with_suffix('.o')
env=os.environ.copy()
env.setdefault('MESA_SHADER_CACHE_DISABLE','true')
runtime=env.get('PIRATE_RUNTIME')
extra=[]
if runtime:
    extra=['-I'+runtime+'/usr/include']
    env['LD_LIBRARY_PATH']=runtime+'/usr/lib/x86_64-linux-gnu:'+env.get('LD_LIBRARY_PATH','')
    env['LIBRARY_PATH']=runtime+'/usr/lib/x86_64-linux-gnu:'+env.get('LIBRARY_PATH','')
# The engine normally compiles this path only on Android/WP8. Compile its real
# implementation with the cache option enabled, without changing platform APIs.
force=out.parent/'chart-lifecycle-cache.h'
force.write_text('#include "base/CCPlatformMacros.h"\n#undef CC_ENABLE_CACHE_TEXTURE_DATA\n#define CC_ENABLE_CACHE_TEXTURE_DATA 1\n')
# Exercise the actual Android pause body without claiming an NDK/JNI build.
# Only export/calling-convention macros are omitted in this Linux test TU.
android=root/'src/engine/cocos2d-x/cocos/2d/platform/android/jni/Java_org_cocos2dx_lib_Cocos2dxRenderer.cpp'
text=android.read_text();start=text.index('JNIEXPORT void JNICALL Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeOnPause()')
brace=text.index('{',start);end=brace+1;depth=1
while depth:
    depth += (text[end]=='{')-(text[end]=='}');end+=1
pause=out.parent/'android-pause-body.cpp'
pause.write_text('#include "cocos2d.h"\n#define JNIEXPORT\n#define JNICALL\nusing namespace cocos2d;\nextern "C" {\n'+text[start:end]+'\n}\n')
java=(root/'src/engine/cocos2d-x/cocos/2d/platform/android/java/src/org/cocos2dx/lib/Cocos2dxGLSurfaceView.java').read_text()
assert 'this.queueEvent(new Runnable()' in java[java.index('public void onPause()'):java.index('public boolean onTouchEvent')]
objects=[]
sources=[root/'tools/tests/chart_lifecycle_native.cpp',pause]+[root/'src/engine/cocos2d-x/cocos/2d'/name for name in ('CCRenderTexture.cpp','CCTextureCache.cpp','CCTexture2D.cpp','CCGLProgram.cpp')]
for source in sources:
    obj=out.parent/(source.stem+'-lifecycle.o');objects.append(str(obj))
    subprocess.run([compiler,*flags['CXX_DEFINES'],*flags['CXX_INCLUDES'],*extra,'-include',str(force),'-std=c++11','-g','-c',str(source),'-o',str(obj)],check=True,env=env)
args=[];skip=False
for token in link[1:]:
    if skip:skip=False;continue
    if token=='-o':skip=True;continue
    if token.endswith('.o') or token.startswith('-Wl,--dependency-file='):continue
    args.append(token)
subprocess.run([compiler,*objects,*args,'-lEGL','-o',str(out)],cwd=build,check=True,env=env)
subprocess.run([str(out),str(root/'tools/tests/chart_lifecycle_native.lua')],cwd=root,check=True,env=env)
