#!/usr/bin/env python3
"""Native event-child list/receipt regressions, real pixels and rollback checks.
Use an existing Linux Makefiles build via PIRATE_BUILD_DIR. Surfaceless only;
never opens a desktop, persistent player profile, payment route or service.
"""
from pathlib import Path
import os
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
BASE = 'ea0d6923c48bf7fbbfa34b3da97ccf8a5fba209a'
FILE = 'bin/res/scripts/LuaClass/EventDetailsLayer.lua'
current = (ROOT / FILE).read_text()
original = subprocess.check_output(['git', 'show', BASE + ':' + FILE], cwd=ROOT, text=True)

def method(source, name):
    start = source.index('function EventDetailsLayer:' + name + '(')
    end = source.find('\nfunction EventDetailsLayer:', start + 1)
    return source[start:len(source) if end < 0 else end]

allowed = ('buyHeroCallBack', 'buyItemCallBack', 'coherentDetailTitle', 'initCoherentDetailTable', 'reloadDetails')
a, b = original, current
for name in allowed:
    a = a.replace(method(a, name), '\n')
    b = b.replace(method(b, name), '\n')
assert a == b, 'Changes outside scoped list/title/receipt presentation'
hero = method(current, 'buyHeroCallBack').replace('''            -- The original crew grant already reports the exact new quantity.
            -- Keep that receipt instead of stacking a second generic success.
            if not self.coherentEventPage then showPopTips("购买成功！")end''', '''            showPopTips("购买成功！")''')
assert hero == method(original, 'buyHeroCallBack'), 'Original recruitment transaction changed'
market = method(current, 'buyItemCallBack').replace('''    if result == 1 then  -- 购买成功
        ExploreBagController''', '''    if result == 1 then  -- 购买成功
        showPopTips("购买成功！")
        ExploreBagController''').replace('''        if self.coherentEventPage then
            showPopTips(tostring(data.name or '物品')..' × '..tostring(data.num or 1)..' · '..(data.costType=='1' and '金币 −'or'钻石 −')..tostring(cost))
        else showPopTips("购买成功！")end
''', '')
assert market == method(original, 'buyItemCallBack'), 'Original market transaction changed'
# Guard the transaction boundary, not unrelated owner/lifecycle work that may
# legitimately land in the same integrated candidate.
for cls, names in (
    ('DataManager', ('addCoin', 'addSoilderWithId')),
    ('ExploreBagController', ('addItemToBattlePack',)),
    ('EventLayer', ('enterPubLayer', 'enterBlackMarket')),
):
    file = 'bin/res/scripts/LuaClass/' + cls + '.lua'
    old = subprocess.check_output(['git', 'show', BASE + ':' + file], cwd=ROOT, text=True)
    new = (ROOT / file).read_text()
    for name in names:
        def extract(source):
            start = source.index('function ' + cls + ':' + name + '(')
            end = source.find('\nfunction ' + cls + ':', start + 1)
            return source[start:len(source) if end < 0 else end]
        assert extract(new) == extract(old), cls + ':' + name + ' transaction changed'
print('PASS source conservation: original recruitment/market transactions, debit/grant methods and stock entry routes')

build = Path(os.environ.get('PIRATE_BUILD_DIR', ROOT / 'build/linux')).resolve()
meta = build / 'CMakeFiles/PirateExplore.dir'
env = dict(os.environ, EGL_PLATFORM='surfaceless', MESA_SHADER_CACHE_DISABLE='true')
captures = Path(env.setdefault('COHERENT_EVENT_LIST_CAPTURE_DIR', '/workspace/shared/pirate-audit/event-list-feedback/final')).resolve()
captures.mkdir(parents=True, exist_ok=True)
errors = ('LUA ERROR', 'ASSERT FAILED', 'Assert failed:', 'Assertion failed', "invalid 'cobj'", 'cocos2d: error:')
with tempfile.TemporaryDirectory(prefix='coherent-event-list-feedback-') as tmp:
    tmp = Path(tmp)
    executable = os.environ.get('COHERENT_EVENT_LIST_HARNESS')
    if not executable:
        flags = {}
        for line in (meta / 'flags.make').read_text().splitlines():
            if ' = ' in line:
                k, v = line.split(' = ', 1); flags[k] = shlex.split(v)
        link = shlex.split((meta / 'link.txt').read_text()); compiler = link[0]
        executable = str(tmp / 'native'); obj = tmp / 'native.o'
        subprocess.run([compiler, *flags['CXX_DEFINES'], *flags['CXX_INCLUDES'], '-std=c++11', '-g', '-c',
                        str(ROOT / 'tools/tests/coherent_event_scene_render.cpp'), '-o', str(obj)], check=True, env=env)
        args, skip = [], False
        for token in link[1:]:
            if skip: skip = False; continue
            if token == '-o': skip = True; continue
            if token.endswith('.o') or token.startswith('-Wl,--dependency-file='): continue
            args.append(token)
        subprocess.run([compiler, str(obj), *args, '-lEGL', '-Wl,--wrap=_ZN7cocos2d6Device6getDPIEv', '-o', executable],
                       cwd=build, env=env, check=True)
    def run(name, script, changes=None, failure=None):
        result = subprocess.run([executable, 'tools/tests/' + script], cwd=ROOT, env=dict(env, **(changes or {})),
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
        (captures / (name + '.log')).write_text(result.stdout)
        if failure:
            assert result.returncode != 0 or any(e in result.stdout for e in errors), 'Undetected rollback: ' + name
            assert failure in result.stdout, result.stdout[-3000:]
            print('PASS rollback rejected:', name)
        else:
            assert result.returncode == 0 and not any(e in result.stdout for e in errors), result.stdout[-6000:]
            assert 'PASS' in result.stdout
            for line in result.stdout.splitlines():
                if 'PASS' in line: print(line)
    run('current', 'coherent_event_list_feedback_cases.lua')
    run('entry-rebind', 'coherent_event_rebind_native.lua')
    run('shortage-ownership', 'coherent_event_shortage_ownership_native.lua')
    cases = [
        ('original-bottom-anchored-list', ('initCoherentDetailTable', 'reloadDetails'), 'content-sized native list height'),
        ('duplicate-recruitment-feedback', ('buyHeroCallBack',), 'recruitment emits one precise receipt'),
        ('generic-market-feedback', ('buyItemCallBack',), 'market exact item quantity cost receipt'),
    ]
    mutations = []
    for name, methods, failure in cases:
        mutated = current
        for m in methods: mutated = mutated.replace(method(mutated, m), method(original, m))
        mutations.append((name, mutated, failure))
    for name, target, old, new, failure in (
        ('recruit-price', 'buyHeroCallBack', 'local cost = data.costs or 0', 'local cost = (data.costs or 0) + 1', 'original model debit 307 to7'),
        ('recruit-debit', 'buyHeroCallBack', 'addCoin(-cost,true)', 'addCoin(-1,true)', 'original model debit 307 to7'),
        ('recruit-quantity', 'buyHeroCallBack', 'addSoilderWithId(data.id, 1)', 'addSoilderWithId(data.id, 2)', 'original crew grant exactly one'),
        ('market-quantity', 'buyItemCallBack', 'addItemToBattlePack(data.id, data.num,true)', 'addItemToBattlePack(data.id, data.num*2,true)', 'original bag model receives exactly one limited item'),
        ('market-once-only', 'buyItemCallBack', 'self:trySaveLimitedData(data.id,index)', '-- removed once-only restriction', 'once-only stock exhausted'),
    ):
        body = method(current, target)
        assert body.count(old) == 1, 'Update mutation anchor: ' + name
        mutations.append((name, current.replace(body, body.replace(old, new, 1)), failure))
    for name, mutated, failure in mutations:
        file = tmp / (name + '.lua'); file.write_text(mutated)
        negative = captures / 'counterfactuals' / name; negative.mkdir(parents=True, exist_ok=True)
        run(name, 'coherent_event_list_feedback_cases.lua',
            {'COHERENT_EVENT_DETAIL_SOURCE':str(file), 'COHERENT_EVENT_LIST_CAPTURE_DIR':str(negative)}, failure)
print('PASS focused event list/feedback native pixels and eight rollback-sensitive checks:', captures)
