#!/usr/bin/env python3
"""Build/run real pause scene/window-close lifecycle and its crash counterfactual.
Requires an existing Linux Makefiles build and the same environment as linux.sh.
Surfaceless EGL only; never opens the shared GUI or any player profile/save.
"""
from pathlib import Path
import os
import resource
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
BUILD = Path(os.environ.get('PIRATE_BUILD_DIR', ROOT / 'build/linux')).resolve()
META = BUILD / 'CMakeFiles/PirateExplore.dir'
assert (META / 'link.txt').is_file(), 'Build linux.sh with Unix Makefiles first.'
flags = {}
for line in (META / 'flags.make').read_text().splitlines():
    if ' = ' in line:
        key, value = line.split(' = ', 1)
        flags[key] = shlex.split(value)
link = shlex.split((META / 'link.txt').read_text())
compiler = link[0]
output = BUILD / 'tests/coherent-pause-close-native'
output.parent.mkdir(parents=True, exist_ok=True)
obj = output.with_suffix('.o')
env = os.environ.copy()
env.setdefault('MESA_SHADER_CACHE_DISABLE', 'true')
extra = []
if env.get('PIRATE_RUNTIME'):
    runtime = env['PIRATE_RUNTIME']
    extra = ['-I' + runtime + '/usr/include']
    for key in ('LD_LIBRARY_PATH', 'LIBRARY_PATH'):
        env[key] = runtime + '/usr/lib/x86_64-linux-gnu:' + env.get(key, '')
subprocess.run([compiler, *flags['CXX_DEFINES'], *flags['CXX_INCLUDES'], *extra,
                '-std=c++11', '-g', '-c', str(ROOT / 'tools/tests/coherent_pause_close_native.cpp'),
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
subprocess.run([compiler, str(obj), *args, '-lEGL', '-o', str(output)],
               cwd=BUILD, env=env, check=True)
command = [str(output), str(ROOT / 'tools/tests/coherent_pause_close_native.lua')]
result = subprocess.run(command, cwd=ROOT, env=env, text=True,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
print(result.stdout, end='')
assert result.returncode == 0, 'Current native pause lifecycle failed'
assert all(error not in result.stdout for error in ('LUA ERROR', 'ASSERT FAILED', 'Assert failed:', 'cocos2d: error:')), 'Current native pause lifecycle logged an error'
assert 'PASS native pause Director::end/purgeDirector' in result.stdout

# Remove one guard at a time, preserving the current UI and business logic.
# Each isolated counterfactual must reproduce native running-node destruction.
# The dialog mutation keeps dispose idempotent so it tests unsafe sibling
# removal rather than recursively re-entering its own native onExit handler.
cases = [
    ('pause scene exit', 'COHERENT_PAUSE_SOURCE', 'WarmPause.lua',
     "if not scene:isRunning() and layer:isRunning() then dispose(false)\n   else layer:close(false)end", "layer:close(false)"),
    ('dialog scene exit', 'COHERENT_PAUSE_DIALOG_SOURCE', 'WarmDialog.lua',
     "  dispose(true);removeLater(layer)", "  if not closed then dispose(true);layer:removeFromParent(true)end"),
    ('settings scene exit', 'COHERENT_PAUSE_SETTINGS_SOURCE', 'WarmSettings.lua',
     "if not scene:isRunning() and layer:isRunning() then dispose()\n            else close() end", "close()"),
    ('dialog scene-owner observer', 'COHERENT_PAUSE_DIALOG_SOURCE', 'WarmDialog.lua',
     "if lifecycle then removeLater(token)\n   elseif owner~=scene or scene:isRunning()then token:removeFromParent(true)end", "token:removeFromParent(true)"),
    ('settings scene-owner observer', 'COHERENT_PAUSE_SETTINGS_SOURCE', 'WarmSettings.lua',
     "(owner ~= scene or scene:isRunning())", "(true)"),
]
resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
for name, key, filename, guard, replacement in cases:
    source = (ROOT / 'bin/res/scripts/LuaClass' / filename).read_text()
    assert source.count(guard) == 1, 'Update counterfactual for revised ' + name
    with tempfile.TemporaryDirectory(prefix='coherent-pause-close-') as temporary:
        legacy = Path(temporary) / filename
        legacy.write_text(source.replace(guard, replacement, 1))
        old_env = dict(env, **{key: str(legacy)})
        old = subprocess.run(command, cwd=ROOT, env=old_env, text=True,
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        assert old.returncode != 0, 'Counterfactual failed to detect ' + name
        assert 'Node still marked as running on node destruction' in old.stdout, old.stdout
        print('PASS counterfactual: %s guard removal reproduces native running-node destruction (exit %s)' % (name, old.returncode))
