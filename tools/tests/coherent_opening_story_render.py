#!/usr/bin/env python3
"""Original-startup EGL evidence in a new, write-isolated empty profile per size.
No GUI, startup replacement, player profile access or timing override.
PIRATE_BUILD_DIR selects the existing native build; STORY_CAPTURE_DIR selects QA output.
Arguments are physical widths/heights, e.g. 480x800 640x960.
"""
from pathlib import Path
import ctypes, hashlib, json, os, shlex, shutil, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
root=Path(__file__).resolve().parents[2]
build=Path(os.environ.get('PIRATE_BUILD_DIR',root/'build/linux')).resolve()
metadata=build/'CMakeFiles/PirateExplore.dir'
output=Path(os.environ.get('STORY_CAPTURE_DIR','/tmp/coherent-opening-story')).resolve()
output.mkdir(parents=True,exist_ok=True)
flags={}
for line in (metadata/'flags.make').read_text().splitlines():
 if ' = ' in line:
  key,value=line.split(' = ',1);flags[key]=shlex.split(value)
link=shlex.split((metadata/'link.txt').read_text());env=os.environ.copy()
env.update(EGL_PLATFORM='surfaceless',MESA_SHADER_CACHE_DISABLE='true')
# Runtime executable is separate from the accepted desktop binary.
runtime=Path(tempfile.mkdtemp(prefix='opening-runtime-',dir=output));obj=runtime/'opening.o';exe=runtime/'PirateExplore'
(runtime/'Resources').symlink_to(root/'bin/res')
subprocess.run([link[0],*flags['CXX_DEFINES'],*flags['CXX_INCLUDES'],'-std=c++11','-g','-c',str(root/'tools/tests/coherent_opening_story_render.cpp'),'-o',str(obj)],check=True,env=env)
args=[];skip=False
for token in link[1:]:
 if skip:skip=False;continue
 if token=='-o':skip=True;continue
 if token.startswith('-Wl,--dependency-file=') or token.endswith('/main.cpp.o'):continue
 args.append(token)
subprocess.run([link[0],str(obj),*args,'-lEGL','-o',str(exe)],cwd=build,check=True,env=env)
class Cmp(ctypes.Structure):
 _fields_=[('arg',ctypes.c_uint),('op',ctypes.c_int),('a',ctypes.c_uint64),('b',ctypes.c_uint64)]
def network_filter(fd):
 s=ctypes.CDLL('libseccomp.so.2',use_errno=True)
 s.seccomp_init.argtypes=[ctypes.c_uint32];s.seccomp_init.restype=ctypes.c_void_p
 s.seccomp_rule_add_array.argtypes=[ctypes.c_void_p,ctypes.c_uint32,ctypes.c_int,ctypes.c_uint,ctypes.POINTER(Cmp)]
 s.seccomp_export_bpf.argtypes=[ctypes.c_void_p,ctypes.c_int];s.seccomp_release.argtypes=[ctypes.c_void_p]
 s.seccomp_syscall_resolve_name.argtypes=[ctypes.c_char_p];s.seccomp_syscall_resolve_name.restype=ctypes.c_int
 ctx=s.seccomp_init(0x7fff0000);assert ctx
 try:
  nr=s.seccomp_syscall_resolve_name(b'socket');assert nr>=0
  for family in (2,10):assert s.seccomp_rule_add_array(ctx,0x50000|13,nr,1,ctypes.byref(Cmp(0,4,family,0)))==0
  assert s.seccomp_export_bpf(ctx,fd)==0
 finally:s.seccomp_release(ctx)
def run(size):
 skip_mode=size.endswith('-skip');dimensions=size[:-5] if skip_mode else size
 w,h=map(int,dimensions.split('x'));run=Path(tempfile.mkdtemp(prefix=size+'-',dir=output));profile=run/'profile';(profile/'PirateExplore').mkdir(parents=True)
 runenv=env.copy();runenv.update(HOME=str(run),XDG_CONFIG_HOME=str(profile),XDG_CACHE_HOME=str(run/'cache'),TMPDIR=str(run))
 if skip_mode:runenv['OPENING_STORY_SKIP']='1'
 scripts=root/'src/engine/cocos2d-x/cocos/scripting/lua-bindings/script'
 cmd=['bwrap','--die-with-parent','--ro-bind','/','/','--bind',str(run),str(run),'--proc','/proc','--dev','/dev','--chdir',str(runtime),str(exe),str(w),str(h),str(run),str(scripts)]
 hashes={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'bin/res').rglob('*') if p.is_file()}
 (run/'manifest.json').write_text(json.dumps({'source':str(root),'physical':[w,h],'profile':str(profile),'emptyProfile':True,'originalStartup':True,'bootstrap':None,'input':'native Next twice, one advance' if skip_mode else 'automatic only','renderer':'surfaceless EGL, real AppDelegate and Director frames','binarySha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'resources':hashes},indent=2))
 with tempfile.TemporaryFile(dir=run) as sec,(run/'native.log').open('w') as log:
  network_filter(sec.fileno());sec.seek(0);cmd[1:1]=['--seccomp',str(sec.fileno())]
  result=subprocess.run(cmd,env=runenv,stdout=log,stderr=subprocess.STDOUT,pass_fds=(sec.fileno(),),timeout=180)
 (run/'exit.txt').write_text(str(result.returncode)+'\n')
 text=(run/'native.log').read_text();assert result.returncode==0,text[-5000:];assert 'LUA ERROR' not in text,text[-5000:]
 assert all((run/f'scene-{i}.png').is_file() for i in range(1,8));assert (run/'home.png').is_file()
 print('PASS',size,run,flush=True);return str(run)
sizes=sys.argv[1:] or ['480x800']
with ThreadPoolExecutor(max_workers=3) as pool:runs=list(pool.map(run,sizes))
(output/'latest.json').write_text(json.dumps(runs,indent=2)+'\n')
