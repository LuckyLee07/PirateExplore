#!/usr/bin/env python3
"""Render/dispatch support-page fixtures on surfaceless Cocos/EGL, no GUI/save.
Reuse the production-backed offscreen view and gesture harness from loot QA.
PIRATE_BUILD_DIR chooses an existing Linux Makefiles build.
COHERENT_SUPPORT_CAPTURE_DIR chooses PNG output, default /tmp/coherent-progress-support.
"""
from pathlib import Path
import os
import shlex
import subprocess
import tempfile
from PIL import Image, ImageChops

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
_build_temp = tempfile.TemporaryDirectory(prefix='coherent-progress-support-render-')
out = Path(_build_temp.name) / 'render'
obj = out.with_suffix('.o')
env = os.environ.copy()
env.setdefault('EGL_PLATFORM', 'surfaceless')
env.setdefault('MESA_SHADER_CACHE_DISABLE', 'true')
captures = Path(env.setdefault('COHERENT_SUPPORT_CAPTURE_DIR', '/tmp/coherent-progress-support'))
captures.mkdir(parents=True, exist_ok=True)
subprocess.run([compiler, *flags['CXX_DEFINES'], *flags['CXX_INCLUDES'],
                '-std=c++11', '-g', '-c', str(root / 'tools/tests/coherent_loot_pages_render.cpp'),
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
result = subprocess.run([str(out), 'tools/tests/coherent_progress_support_native.lua'],
                        cwd=root, check=True, env=env, text=True, capture_output=True)
output = result.stdout + result.stderr
assert '[LUA ERROR]' not in output, output
for line in output.splitlines():
    if 'PASS' in line or 'description drag' in line:
        print(line)
assert (captures / 'achievement-dispatched-scroll.png').is_file()
print(f'PASS support page native offscreen PNG and actual dispatched scroll: {captures}')

# A visible LabelTTF can still be fully covered by a same-z DrawNode after a
# later child insertion. Compare actual pixels from consecutive native visits,
# not just node visibility, bounds, sibling order or a single initial image.
def header_frames(directory, counterfactual=False):
    directory.mkdir(parents=True, exist_ok=True)
    header_env = env.copy()
    header_env['COHERENT_HEADER_CAPTURE_DIR'] = str(directory)
    if counterfactual:
        header_env['COHERENT_HEADER_COUNTERFACTUAL'] = '1'
    else:
        header_env.pop('COHERENT_HEADER_COUNTERFACTUAL', None)
    result = subprocess.run([str(out), 'tools/tests/coherent_header_layers_native.lua'],
                            cwd=root, env=header_env, text=True, capture_output=True)
    assert result.returncode == 0 and '[LUA ERROR]' not in result.stdout + result.stderr, result.stdout + result.stderr
    references, failures, count = {}, [], 0
    for line in (directory / 'frames.tsv').read_text().splitlines():
        name, width, height, state, path = line.split('\t')
        width, height = int(width), int(height)
        scale = min(width / 480, height / 800)
        left = (width - 480 * scale) / 2
        top = (height - 800 * scale) / 2
        # Both title and subtitle, safely inside the plain navy header.
        box = (round(left + 24 * scale), round(top + 20 * scale),
               round(left + 456 * scale), round(top + 116 * scale))
        with Image.open(path) as frame:
            pixels = frame.convert('RGB').crop(box)
        key = name, width, height
        if state == 'initial':
            references[key] = pixels
            # Ensure the reference actually contains both light text lines.
            for label, band in [('title', (0, 0, pixels.width, round(58 * scale))),
                                ('subtitle', (0, round(62 * scale), pixels.width, pixels.height))]:
                sample = pixels.crop(band)
                light = sum(n for n, p in sample.getcolors(sample.width * sample.height) if min(p) > 150)
                assert light > 30, f'{key}: initial {label} not visibly rendered'
        elif ImageChops.difference(references[key], pixels).getbbox():
            failures.append((*key, state))
        count += 1
    assert len(references) == 15, 'Talent, Achievement and shared shell at five sizes'
    receipt_count = 0
    for line in (directory / 'receipts.tsv').read_text().splitlines():
        name, width, height, state, path, *bounds = line.split('\t')
        inset = 2 * min(int(width) / 480, int(height) / 800)
        left, top, right, bottom = map(float, bounds)
        box = tuple(round(value) for value in (left + inset, top + inset, right - inset, bottom - inset))
        with Image.open(path) as frame:
            pixels = frame.convert('RGB').crop(box)
        area = pixels.width * pixels.height
        colors = pixels.getcolors(area)
        dark = sum(n for n, p in colors if max(p) < 125)
        light = sum(n for n, p in colors if min(p) > 180)
        assert dark > area * .4 and light > area * .05, (name, width, height, state, dark, light)
        receipt_count += 1
    assert receipt_count == 30, 'visible receipt backdrop and text on both pages, three receipt states, five sizes'
    return failures, count

failures, count = header_frames(captures / 'header-layers')
assert not failures, f'header title/subtitle pixels changed after a dynamic child: {failures[:12]}'
print(f'PASS explicit header background layer: {count} consecutive native frames retain identical title/subtitle pixels')
print('PASS visible alchemy receipt backdrop and text pixels: Talent/Achievement, first/accumulated/recreated, five sizes')
with tempfile.TemporaryDirectory(prefix='coherent-header-counterfactual-') as temporary:
    failures, _ = header_frames(Path(temporary), counterfactual=True)
    assert ('talent', 480, 800, 'first-receipt') in failures, failures
    assert ('achievement', 480, 800, 'first-receipt') in failures, failures
    assert ('shared-shell', 480, 800, 'children-added-3') in failures, failures
print('PASS old equal-z header counterfactual loses rendered text after the first real Talent/Achievement receipt and shared-shell child mutations')
