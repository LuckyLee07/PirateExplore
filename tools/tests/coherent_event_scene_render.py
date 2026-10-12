#!/usr/bin/env python3
"""Render semantic event scenes on surfaceless Cocos/EGL, no GUI/save.
Reuse the production-backed offscreen view and gesture harness from loot QA.
PIRATE_BUILD_DIR chooses an existing Linux Makefiles build.
COHERENT_EVENT_SCENE_CAPTURE_DIR chooses the persistent native PNG evidence folder.
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
_build_temp = tempfile.TemporaryDirectory(prefix='coherent-event-scene-render-')
out = Path(_build_temp.name) / 'render'
obj = out.with_suffix('.o')
env = os.environ.copy()
env.setdefault('EGL_PLATFORM', 'surfaceless')
env.setdefault('MESA_SHADER_CACHE_DISABLE', 'true')
captures = Path(env.setdefault('COHERENT_EVENT_SCENE_CAPTURE_DIR', '/workspace/shared/pirate-audit/event-scene-identity'))
captures.mkdir(parents=True, exist_ok=True)
subprocess.run([compiler, *flags['CXX_DEFINES'], *flags['CXX_INCLUDES'],
                '-std=c++11', '-g', '-c', str(root / 'tools/tests/coherent_event_scene_render.cpp'),
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
result = subprocess.run([str(out), 'tools/tests/coherent_event_rebind_native.lua'],
                        cwd=root, env=env, text=True, capture_output=True)
print(result.stdout + result.stderr)
result.check_returncode()
assert '[LUA ERROR]' not in result.stdout + result.stderr
result = subprocess.run([str(out), 'tools/tests/coherent_event_scene_native.lua'],
                        cwd=root, env=env, text=True, capture_output=True)
output = result.stdout + result.stderr
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
        assert ImageChops.difference(original,Image.open(changed).convert('RGB')).getbbox() is None, f'Dynamic sibling insertion changed event pixels: {changed}'
        pairs+=1
assert pairs>=136, pairs
print(f'PASS {pairs} exact event-page pixel comparisons after native dynamic child additions/removals: {captures}')
