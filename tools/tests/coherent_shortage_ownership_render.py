#!/usr/bin/env python3
"""Run real store/event/chest/selector shortage ownership in native scenes.
Surfaceless Cocos/EGL only; fixtures block profiles, network and real payment.
PIRATE_BUILD_DIR chooses the existing corrected Linux build.
COHERENT_SHORTAGE_CAPTURE_DIR chooses the native binary and evidence folder.
"""
from pathlib import Path
import os
import shlex
import subprocess

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
env = os.environ.copy()
env.setdefault('EGL_PLATFORM', 'surfaceless')
env.setdefault('MESA_SHADER_CACHE_DISABLE', 'true')
captures = Path(env.setdefault('COHERENT_SHORTAGE_CAPTURE_DIR', '/workspace/shared/pirate-audit/coherent-shortage-owners'))
captures.mkdir(parents=True, exist_ok=True)
out=captures / "shortage-owners-native"
obj=out.with_suffix(".o")
subprocess.run([compiler, *flags['CXX_DEFINES'], *flags['CXX_INCLUDES'],
                '-std=c++11', '-g', '-c', str(root / 'tools/tests/world_chart_selector_render.cpp'),
                '-o', str(obj)], check=True, env=env)
args, skip = [], False
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
for test in ('coherent_store_shortage_ownership_native.lua',
             'coherent_event_shortage_ownership_native.lua',
             'coherent_chest_shortage_ownership_native.lua',
             'world_chart_shortage_ownership_native.lua',
             'coherent_intelligence_return_ownership_native.lua'):
    result = subprocess.run([str(out), 'tools/tests/' + test], cwd=root,
                            env=env, text=True, capture_output=True, timeout=120)
    output = result.stdout + result.stderr
    (captures / (Path(test).stem + '-running.log')).write_text(output)
    if result.returncode: print(output)
    result.check_returncode()
    assert all(error not in output for error in ('[LUA ERROR]', 'Assert failed:', 'cocos2d: error:', 'response failed')), output
    for line in output.splitlines():
        if 'PASS' in line: print(line)
print('PASS real shortage caller ownership in genuine native scenes')
