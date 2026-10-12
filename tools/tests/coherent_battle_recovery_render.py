#!/usr/bin/env python3
"""Render battle component evidence using the shared real Cocos/EGL harness.
No application window or profile is opened. Set PIRATE_BUILD_DIR to an existing
compatible Linux build and COHERENT_BATTLE_CAPTURE_DIR to the evidence folder.
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
_build_temp = tempfile.TemporaryDirectory(prefix='coherent-battle-stage-render-')
out = Path(_build_temp.name) / 'render'
obj = out.with_suffix('.o')
env = os.environ.copy()
env.setdefault('EGL_PLATFORM', 'surfaceless')
env.setdefault('MESA_SHADER_CACHE_DISABLE', 'true')
captures = Path(env.setdefault('COHERENT_BATTLE_CAPTURE_DIR', '/workspace/shared/pirate-defeat-recovery'))
captures.mkdir(parents=True, exist_ok=True)
# Reuse the tested renderer, font metrics and native event infrastructure.
subprocess.run([compiler, *flags['CXX_DEFINES'], *flags['CXX_INCLUDES'],
                '-std=c++11', '-g', '-c', str(root / 'tools/tests/coherent_battle_stage_render.cpp'),
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
for test in ('warm_battle_recovery_native.lua', 'warm_battle_recovery_lifecycle_native.lua',
             'warm_battle_recovery_shortage_ownership_native.lua'):
    result = subprocess.run([str(out), 'tools/tests/' + test],
                            cwd=root, env=env, text=True, capture_output=True)
    print(result.stdout)
    print(result.stderr)
    result.check_returncode()
    assert '[LUA ERROR]' not in result.stdout + result.stderr, 'native callbacks reported Lua errors'
    assert 'Assert failed:' not in result.stdout + result.stderr and 'cocos2d: error:' not in result.stdout + result.stderr, 'native assertion or binding error'
print(f'PASS native offscreen recovery images and original callbacks: {captures}')
