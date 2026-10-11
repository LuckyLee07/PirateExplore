#!/usr/bin/env python3
"""Host syntax-check HttpClient against every bundled curl API surface.
This is not an Android/iOS/Windows cross-build or platform runtime test.
"""
import os,pathlib,re,shlex,subprocess,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
build=pathlib.Path(os.environ.get('PIRATE_BUILD_DIR',ROOT/'build/linux'))
flags={}
for line in (build/'engine/cocos/network/CMakeFiles/network.dir/flags.make').read_text().splitlines():
 if ' = ' in line:
  key,value=line.split(' = ',1);flags[key]=shlex.split(value)
source=ROOT/'src/engine/cocos2d-x/cocos/network/HttpClient.cpp'
with tempfile.TemporaryDirectory()as temp:
 temp=pathlib.Path(temp)
 for platform in ('android','ios','win32','wp8'):
  include=ROOT/'src/engine/cocos2d-x/external/curl/include'/platform
  version=(include/'curl/curlver.h').read_text()
  number=int(re.search(r'#define LIBCURL_VERSION_NUM\s+(0x[0-9a-fA-F]+)',version).group(1),16)
  assert number==(0x072200 if platform=='wp8' else 0x071a00),'Unexpected bundled curl version'
  extra=[]
  if platform=='android':
   # Bundled Android curlbuild.h assumes a 32-bit target; this test uses the
   # host compiler. Match only sizeof(long), leaving API declarations intact.
   shim=temp/'android-host-abi.h'
   shim.write_text('#include "'+str(include/'curl/curlbuild.h')+'"\n#undef CURL_SIZEOF_LONG\n#define CURL_SIZEOF_LONG __SIZEOF_LONG__\n')
   extra=['-include',str(shim)]
  args=['c++','-I'+str(include),*extra,*flags['CXX_DEFINES'],*flags['CXX_INCLUDES'],'-std=c++11','-fsyntax-only']
  subprocess.run([*args,str(source)],check=True)
  # Counterfactual proves each original unsupported API is rejected by the
  # actual selected old headers rather than silently using system curl.
  for name,expression in [('xfer','curl_easy_setopt(h,CURLOPT_XFERINFOFUNCTION,0);'),('wait','curl_multi_wait(m,0,0,100,0);')]:
   probe=temp/(platform+'-'+name+'.cpp');probe.write_text('#include <curl/curl.h>\nvoid probe(CURL*h,CURLM*m){'+expression+'}\n')
   result=subprocess.run([*args,str(probe)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
   if platform=='wp8':
    assert result.returncode==0,result.stderr
   else:
    assert result.returncode!=0,(platform,name,'old API counterfactual unexpectedly built')
    expected='CURLOPT_XFERINFOFUNCTION' if name=='xfer' else 'curl_multi_wait'
    assert expected in result.stderr,result.stderr
  print('PASS full HttpClient host syntax with bundled '+platform+'; modern API probes '+('accepted by7.34' if platform=='wp8' else 'rejected by7.26'))
print('PASS curl API backward compatibility; no platform runtime acceptance claimed')
