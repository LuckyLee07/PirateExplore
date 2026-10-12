#!/usr/bin/env python3
"""Build/run real market child/window-close lifecycle and guard counterfactuals.
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
build_temporary = tempfile.TemporaryDirectory(prefix='coherent-event-child-build-')
output = Path(os.environ.get('COHERENT_EVENT_CHILD_OUTPUT', str(Path(build_temporary.name)/'native')))
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
                '-std=c++11', '-g', '-c', str(ROOT / 'tools/tests/coherent_event_child_shutdown_native.cpp'),
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
command = [str(output), str(ROOT / 'tools/tests/coherent_event_child_shutdown_native.lua')]
result = subprocess.run(command, cwd=ROOT, env=env, text=True,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
logs=Path(os.environ.get('COHERENT_EVENT_CHILD_LOG_DIR','/tmp/coherent-event-child-shutdown-logs'));logs.mkdir(parents=True,exist_ok=True)
(logs/'current.log').write_text(result.stdout)
print(result.stdout, end='')
assert result.returncode == 0, 'Current native event-child lifecycle failed'
assert all(error not in result.stdout for error in ('LUA ERROR', 'ASSERT FAILED', 'Assert failed:', 'Assertion failed', "invalid 'cobj'", 'cocos2d: error:')), 'Current native event-child lifecycle logged an error'
assert 'PASS native event child Director::end/purgeDirector' in result.stdout

# Guard sensitivity: each rollback must be rejected, including errors logged
# by Lua/native handlers even if the process happens to return zero.
resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
owner = (ROOT / 'bin/res/scripts/LuaClass/EventLayer.lua').read_text()
dialog = (ROOT / 'bin/res/scripts/LuaClass/WarmDialog.lua').read_text()
base = (ROOT / 'bin/res/scripts/LuaClass/EventBaseView.lua').read_text()
def replace_once(source, old, new):
    assert source.count(old) == 1, 'Update event-child counterfactual anchor'
    return source.replace(old, new, 1)
legacy_owner = replace_once(owner,
    "        if event=='exit' or event=='cleanup'then self:dismissEventDetails(event)end\n",
    '')
legacy_owner = replace_once(legacy_owner,
    '            self.eventDisposed=true;self.eventGeneration=self.eventGeneration+1\n',
    '            self.eventDisposed=true;self.eventGeneration=self.eventGeneration+1\n            self:dismissEventDetails()\n')
legacy_start = legacy_owner.index('function EventLayer:adoptEventDetails(layer)')
legacy_owner = legacy_owner[:legacy_start] + '''function EventLayer:adoptEventDetails(layer)
    if not self.coherentEventPage then return end
    self.eventDetails=layer;layer.ownerEvent=self
end
function EventLayer:dismissEventDetails()
    local child=self.eventDetails;self.eventDetails=nil
    if child then
        child.ownerEvent=nil;child.eventClosed=true
        local scene=cc.Director:getInstance():getRunningScene()
        if not (self.eventDisposed and scene and not scene:isRunning() and child:isRunning())then child:removeFromParent(true)end
    end
end
'''
observer = """    observer:registerScriptHandler(function(event)
        if (event=='exit' or event=='cleanup') and self.eventDetails==layer then
            self:dismissEventDetails(event)
        end
    end)
"""
cases = [
 ('original exited-child guard', 'COHERENT_EVENT_OWNER_SOURCE', legacy_owner, {'COHERENT_EVENT_CHILD_ONLY_END':'1'}),
 ('child detach observer', 'COHERENT_EVENT_OWNER_SOURCE', replace_once(owner, observer, ''), {}),
 ('stale dialog observer', 'COHERENT_EVENT_DIALOG_SOURCE', replace_once(dialog, '  if retired then return end;retired=true\n', ''), {}),
 ('destroyed Close callback', 'COHERENT_EVENT_BASE_SOURCE', replace_once(base, 'if not disposed and E.alive(self)', 'if E.alive(self)'), {}),
]
for name, key, mutated, changes in cases:
    with tempfile.TemporaryDirectory(prefix='coherent-event-child-negative-') as tmp:
        file=Path(tmp)/'mutated.lua';file.write_text(mutated)
        old = subprocess.run(command, cwd=ROOT, env=dict(env, **{key:str(file)}, **changes),
                             text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        (logs/(name.replace(' ','-')+'.log')).write_text(old.stdout)
        error = any(marker in old.stdout for marker in ('LUA ERROR','ASSERT FAILED','Assert failed:',
                    'cocos2d: error:', "invalid 'cobj'", 'Assertion failed', 'Node still marked as running'))
        assert old.returncode != 0 or error, 'Undetected event-child regression: '+name
        if name=='original exited-child guard':
            assert old.returncode != 0, 'Original lifetime must fail true native purge'
        print('PASS event-child negative:',name,'exit',old.returncode)
print('PASS event-child lifetime guard sensitivity (4 isolated counterfactuals)')

# The adjacent selector used the same invalid running-child cleanup guard.
selector_command=[str(output),str(ROOT/'tools/tests/coherent_world_child_shutdown_native.lua')]
for path in ('purge','owner','child','detach','replace','push_pop'):
    for first in (False,True):
        current_env=dict(env,SELECTOR_PATH=path)
        current_env.pop('SELECTOR_FIRST',None)
        if first:current_env['SELECTOR_FIRST']='1'
        current=subprocess.run(selector_command,cwd=ROOT,env=current_env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=60)
        (logs/('selector-'+path+'-'+str(first)+'.log')).write_text(current.stdout)
        assert current.returncode==0,current.stdout
        assert not any(marker in current.stdout for marker in ('LUA ERROR','Assert failed:','Assertion failed',"invalid 'cobj'",'cocos2d: error:')),current.stdout
        assert 'PASS native event child Director::end/purgeDirector' in current.stdout
        print('PASS native unretained selector',path,'selectorFirst',first)
selector_new="""            if map then
                map:setVisible(false);map:stopAllActions()
                if map.coherentWorldSelector then
                    map.worldDisposed=true;map.worldSuspended=true
                    require('LuaClass/WorldChartSelector').closeModal(map,event)
                end
                -- The selector is also a scene sibling. Its onExit has already
                -- finished at scene cleanup, but erasing it still invalidates
                -- the native child-vector traversal.
                map:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function()
                    if map:getParent()then map:removeFromParent(true)end
                end)))
            end
"""
selector_old="""            local scene=cc.Director:getInstance():getRunningScene()
            if map and not(scene and not scene:isRunning() and map:isRunning())then map:removeFromParent(true)end
"""
with tempfile.TemporaryDirectory(prefix='coherent-selector-negative-')as tmp:
    file=Path(tmp)/'EventLayer.lua';file.write_text(replace_once(owner,selector_new,selector_old))
    for first in (False,):
        current_env=dict(env,COHERENT_EVENT_OWNER_SOURCE=str(file),SELECTOR_PATH='purge')
        current_env.pop('SELECTOR_FIRST',None)
        if first:current_env['SELECTOR_FIRST']='1'
        old=subprocess.run(selector_command,cwd=ROOT,env=current_env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=60)
        (logs/('selector-original-guard-'+str(first)+'.log')).write_text(old.stdout)
        assert old.returncode!=0,'Selector vector mutation escaped native cleanup witnesses'
        print('PASS selector exited-child guard negative',first,'exit',old.returncode)

selector=(ROOT/'bin/res/scripts/LuaClass/WorldChartSelector.lua').read_text()
selector_clear="  if event=='cleanup' and v.owner and v.owner.worldMapLayer==v then v.owner.worldMapLayer=nil end\n"
with tempfile.TemporaryDirectory(prefix='coherent-selector-owner-negative-')as tmp:
    file=Path(tmp)/'WorldChartSelector.lua';file.write_text(replace_once(selector,selector_clear,''))
    for first in (False,True):
        current_env=dict(env,COHERENT_WORLD_SELECTOR_SOURCE=str(file),SELECTOR_PATH='child')
        current_env.pop('SELECTOR_FIRST',None)
        if first:current_env['SELECTOR_FIRST']='1'
        old=subprocess.run(selector_command,cwd=ROOT,env=current_env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=60)
        (logs/('selector-stale-owner-'+str(first)+'.log')).write_text(old.stdout)
        assert old.returncode!=0,'Destroyed selector retained a stale native owner pointer'
        print('PASS selector stale owner negative',first,'exit',old.returncode)
