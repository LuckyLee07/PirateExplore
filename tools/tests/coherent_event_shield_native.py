#!/usr/bin/env python3
"""Actual surfaceless GLView taps against EventLayer show/hide/cleanup.
Uses an existing Linux build selected by PIRATE_BUILD_DIR; no game profile or desktop.
"""
from pathlib import Path
import os
import shlex
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
build = Path(os.environ.get('PIRATE_BUILD_DIR', root / 'build/linux')).resolve()
metadata = build / 'CMakeFiles/PirateExplore.dir'
flags = {}
for line in (metadata / 'flags.make').read_text().splitlines():
    if ' = ' in line:
        key, value = line.split(' = ', 1)
        flags[key] = shlex.split(value)
link = shlex.split((metadata / 'link.txt').read_text())
compiler = link[0]
out = Path('/tmp/coherent-event-shield-native')
obj = out.with_suffix('.o')
env = os.environ.copy()
env.setdefault('EGL_PLATFORM', 'surfaceless')
env.setdefault('MESA_SHADER_CACHE_DISABLE', 'true')
subprocess.run([compiler, *flags['CXX_DEFINES'], *flags['CXX_INCLUDES'],
                '-std=c++11', '-g', '-c', str(root / 'tools/tests/coherent_event_shield_native.cpp'),
                '-o', str(obj)], check=True, env=env)
args = []
skip = False
for token in link[1:]:
    if skip:
        skip = False
        continue
    if token == '-o':
        skip = True
        continue
    if token.endswith('.o') or token.startswith('-Wl,--dependency-file='):
        continue
    args.append(token)
subprocess.run([compiler, str(obj), *args, '-lEGL',
                '-Wl,--wrap=_ZN7cocos2d6Device6getDPIEv', '-o', str(out)], cwd=build, check=True, env=env)
result = subprocess.run([str(out), 'tools/tests/coherent_event_shield_native.lua'],
                        cwd=root, env=env, text=True, capture_output=True)
print(result.stdout)
print(result.stderr)
result.check_returncode()
assert '[LUA ERROR]' not in result.stdout + result.stderr, 'native callbacks reported Lua errors'
print('PASS real native event shield input lifecycle')


negative_env=env.copy();negative_env['EVENT_SHIELD_COUNTERFACTUAL']='1'
negative=subprocess.run([str(out),'tools/tests/coherent_event_shield_native.lua'],cwd=root,env=negative_env,text=True,capture_output=True)
output=negative.stdout+negative.stderr
assert negative.returncode!=0 or '[LUA ERROR]' in output
assert 'hidden encounter must release underlying map input' in output
print(output[-1200:])
print('PASS original always-true shield counterfactual rejected by actual GLView tap')
