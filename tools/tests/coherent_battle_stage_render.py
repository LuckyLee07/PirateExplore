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
captures = Path(env.setdefault('COHERENT_BATTLE_CAPTURE_DIR', '/tmp/coherent-battle-stage'))
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
result = subprocess.run([str(out), 'tools/tests/coherent_battle_stage_native.lua'],
                        cwd=root, check=True, env=env, text=True, capture_output=True)
print(result.stdout)
print(result.stderr)
assert '[LUA ERROR]' not in result.stdout + result.stderr, 'native callbacks reported Lua errors'
print(f'PASS native offscreen battle images: {captures}')

# Exact-identity bodies use the same production renderer and native Menu input.
# This also captures a six-member 480x800 viewport before and after real taps.
result = subprocess.run([str(out), 'tools/tests/coherent_boarding_bodies_native.lua'],
                        cwd=root, check=True, env=env, text=True, capture_output=True)
print(result.stdout)
print(result.stderr)
assert '[LUA ERROR]' not in result.stdout + result.stderr, 'body native callbacks reported Lua errors'
from PIL import Image
for name in ('bodies-actual-six-480x800.png', 'bodies-six-controls-used-480x800.png'):
    image = Image.open(captures / name).convert('RGB')
    assert image.size == (480, 800), 'full viewport is not cropped'
    # Top-left image coordinates, away from rounded edges and label glyphs.
    # Enough real colored pixels must exist inside BOTH visible hit regions.
    food = [image.getpixel((x, y)) for x in range(193, 442) for y in range(739, 775)]
    instant = [image.getpixel((x, y)) for x in range(31, 172) for y in range(739, 775)]
    assert sum(g > r + 35 and b > r + 35 for r, g, b in food) > len(food) * .65, 'food CTA pixels absent/clipped'
    assert sum(r > 190 and g > 190 and b > 160 for r, g, b in instant) > len(instant) * .65, 'paid CTA pixels absent/clipped'
print('PASS full 480x800 six-unit pixels: both complete action targets rendered before/after actual native touches')

# Reject the old three-times boarding pulse through the production native action.
# Only this test's in-memory loaded source is changed; production stays frozen.
source = (root / 'tools/tests/coherent_battle_stage_native.lua').read_text()
needle = "source=read('bin/res/scripts/LuaClass/FightMode.lua')"
assert needle in source
with tempfile.TemporaryDirectory(prefix='coherent-battle-counterfactual-') as temporary:
    case = Path(temporary) / 'old-pulse.lua'
    case.write_text(source.replace("if data.icon=='g_303.png' then", "if id=='10027' then").replace(needle, needle + "\nsource=source:gsub('self%.cleanBattleRoot and 1%.12 or 3%.0','self.cleanBattleRoot and 3.0 or 3.0')", 1))
    negative_env = env.copy()
    negative_env.pop('COHERENT_BATTLE_CAPTURE_DIR', None)
    result = subprocess.run([str(out), str(case)], cwd=root, env=negative_env,
                            text=True, capture_output=True)
    output = result.stdout + result.stderr
    assert result.returncode != 0 or '[LUA ERROR]' in output
    assert 'bounded attack pulse before reset' in output, output
print('PASS old 3x boarding pulse rejected by actual native action sampling')
