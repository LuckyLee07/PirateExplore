#!/usr/bin/env python3
"""Build the opt-in surfaceless Cocos capture harness using an existing build.
No app window/profile is opened. Ordinary aggregate runs use the Lua fixtures.
PIRATE_BUILD_DIR selects the existing Linux build; COHERENT_LOOT_CAPTURE_DIR
selects image output (default /tmp/coherent-loot-pages).
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
_build_temp = tempfile.TemporaryDirectory(prefix='coherent-loot-pages-render-')
out = Path(_build_temp.name) / 'render'
obj = out.with_suffix('.o')
env = os.environ.copy()
env.setdefault('EGL_PLATFORM', 'surfaceless')
env.setdefault('MESA_SHADER_CACHE_DISABLE', 'true')
captures = Path(env.setdefault('COHERENT_LOOT_CAPTURE_DIR', '/tmp/coherent-loot-pages'))
captures.mkdir(parents=True, exist_ok=True)
subprocess.run([compiler, *flags['CXX_DEFINES'], *flags['CXX_INCLUDES'],
                '-std=c++11', '-g', '-c', str(root / 'tools/tests/coherent_loot_pages_render.cpp'),
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
for script in ('coherent_loot_pages_native.lua', 'coherent_chest_feedback_native.lua', 'coherent_diamond_shortage_native.lua', 'coherent_diamond_shortage_store_native.lua'):
    result = subprocess.run([str(out), 'tools/tests/' + script],
                            cwd=root, check=False, env=env, text=True, capture_output=True)
    print(result.stdout)
    print(result.stderr)
    assert result.returncode == 0, script + ' failed'
    assert '[LUA ERROR]' not in result.stdout + result.stderr, 'native callbacks reported Lua errors'
    assert 'cocos2d: error:' not in result.stdout + result.stderr, 'native binding error'
    assert 'Assert failed:' not in result.stdout + result.stderr, 'native assertion'
print(f'PASS native offscreen loot/chest images: {captures}')

# A counterfactual must fail through the actual dispatched gesture, not merely
# a structural listener assertion. No production file is modified.
source = (root / 'tools/tests/coherent_loot_pages_native.lua').read_text()
needle = "assert(chest.tapEventListener==nil,'Warm description is not dismissed on touch-began')"
assert needle in source
with tempfile.TemporaryDirectory(prefix='coherent-chest-counterfactual-') as temporary:
    case = Path(temporary) / 'old-listener.lua'
    case.write_text(source.replace(needle,
        'chest:setTapEventListener(function() chest:hideInfo() end)'))
    negative_env = env.copy()
    negative_env['COHERENT_LOOT_CAPTURE_DIR'] = temporary
    negative = subprocess.run([str(out), str(case)], cwd=root, env=negative_env,
                              text=True, capture_output=True)
    output = negative.stdout + negative.stderr
    assert negative.returncode != 0 or '[LUA ERROR]' in output
    assert 'real dispatched description drag remains visible and scrolls' in output
print('PASS old tap-began listener counterfactual is rejected by dispatched drag')

# Restore each old receipt source independently; the actual native action must reject it.
feedback = (root / 'tools/tests/coherent_chest_feedback_native.lua').read_text()
needle = "local source=read('bin/res/scripts/LuaClass/FightMode.lua')"
assert needle in feedback
for name, old, restored in (
    ('coin', 'addCoin(propNum, not self.coherentChest)', 'addCoin(propNum)'),
    ('diamond', 'addDiamond(propNum, false, not self.coherentChest)', 'addDiamond(propNum, false)'),
    ('material', 'if not self.coherentChest then ToastUtil:downString("打开宝箱成功!") end', 'ToastUtil:downString("打开宝箱成功!")'),
):
    with tempfile.TemporaryDirectory(prefix='chest-feedback-counterfactual-') as temporary:
        case = Path(temporary) / (name + '.lua')
        patch = "\nlocal a,b=assert(source:find([=[" + old + "]=],1,true));source=source:sub(1,a-1)..[=[" + restored + "]=]..source:sub(b+1)"
        case.write_text(feedback.replace(needle, needle + patch, 1))
        negative_env = env.copy()
        negative_env.pop('COHERENT_LOOT_CAPTURE_DIR', None)
        result = subprocess.run([str(out), str(case)], cwd=root, env=negative_env, text=True, capture_output=True)
        output = result.stdout + result.stderr
        assert result.returncode != 0 or '[LUA ERROR]' in output, name
        assert 'coherent reward has no overlapping success toast' in output, output
    print('PASS old ' + name + ' success toast rejected by real native chest action')

# The second activation must not close its sheet while the first callback runs.
shortage = (root / 'tools/tests/coherent_diamond_shortage_native.lua').read_text()
needle = "local source=read('bin/res/scripts/LuaClass/DataManager.lua');local a="
assert needle in shortage
with tempfile.TemporaryDirectory(prefix='shortage-order-counterfactual-') as temporary:
    case = Path(temporary) / 'premature-close.lua'
    guard = 'if offered or (presentation and not presentation.isActive()) then return false end'
    restored = guard.replace('return false', 'return')
    mutation = "local source=read('bin/res/scripts/LuaClass/DataManager.lua');local first,last=assert(source:find([=[" + guard + "]=],1,true));source=source:sub(1,first-1)..[=[" + restored + "]=]..source:sub(last+1);local a="
    case.write_text(shortage.replace(needle, mutation, 1))
    negative_env = env.copy()
    negative_env.pop('COHERENT_LOOT_CAPTURE_DIR', None)
    result = subprocess.run([str(out), str(case)], cwd=root, env=negative_env, text=True, capture_output=True)
    output = result.stdout + result.stderr
    assert result.returncode != 0 or '[LUA ERROR]' in output
    assert 'reentrant click must not close during original gift callback' in output, output
print('PASS premature close counterfactual rejected by reentrant native gift callback')
