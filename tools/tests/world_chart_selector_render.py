#!/usr/bin/env python3
"""Render the actual world-chart selector on surfaceless Cocos/EGL, no GUI/save.
Reuse the production-backed offscreen view and gesture harness from loot QA.
PIRATE_BUILD_DIR chooses an existing Linux Makefiles build.
COHERENT_WORLD_CAPTURE_DIR chooses the persistent native PNG evidence folder.
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
captures = Path(env.setdefault('COHERENT_WORLD_CAPTURE_DIR', '/workspace/shared/pirate-audit/world-chart-selector'))
captures.mkdir(parents=True, exist_ok=True)
out=captures / "world-selector-native"
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
result = subprocess.run([str(out), env.get('COHERENT_WORLD_TEST','tools/tests/world_chart_selector_native.lua')],
                        cwd=root, env=env, text=True, capture_output=True)
output = result.stdout + result.stderr
(captures / (Path(env.get('COHERENT_WORLD_TEST','native')).stem+'.log')).write_text(output)
if result.returncode: print(output)
result.check_returncode()
assert '[LUA ERROR]' not in output, output
for line in output.splitlines():
    if 'PASS' in line or 'description drag' in line:
        print(line)

from PIL import Image, ImageChops
pairs=0
for added in captures.glob('*-dynamic-add.png'):
    base=added.with_name(added.name.replace('-dynamic-add.png','.png'))
    removed=added.with_name(added.name.replace('-dynamic-add.png','-dynamic-remove.png'))
    original=Image.open(base).convert('RGB')
    for changed in (added,removed):
        assert ImageChops.difference(original,Image.open(changed).convert('RGB')).getbbox() is None, f'Dynamic sibling insertion changed selector pixels: {changed}'
        pairs+=1
assert pairs>=54, pairs
print(f'PASS {pairs} exact selector dynamic-child pixel comparisons: {captures}')
