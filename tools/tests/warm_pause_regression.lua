-- Real encrypted UserData role commits with separate isolated map-file storage.
-- Verifies honest partial-pair failure semantics and actual cold JSON reload.
local F=dofile('tools/tests/fixtures/warm_upgrade_fixture.lua')
package.loaded['LuaClass/simplejson.lua']=json
local P=require 'LuaClass/WarmPause';local dm=F.dm;local eq=F.equal
local owner={statue='ready',mapIndex=1,playerTitlePosition={x=7,y=9},breadCostDecimal=.75,
 moveWaitingQueue={},moveDirectionQueue={},eventManger={eventWaitingQueue={0}}}
local map={titlesInfo={['187']={fogId='0',statues='11'}}}
F.reset({[roleStatue]=1,[roleMapInfo]={curIndex=1,playerTitlePosition={x=3,y=4},fristReturnBaseByTool='1'},
 [roleBreadCostDecimal]=.25,[roleBattlePack]={['1005']={id='1005',num=12},['1008']={id='1008',num=2}},
 [roleBattleQueue]={['100']=1},adventureProgressV1={version=1,enabled=true,voyage=2,activeVoyage=2,pending={voyage=2,episode='crew',action='rescue',choice='chart'}}})
dm.__roleData:setRoleData(mapInfo,F.copy(map))
local mapDisk='old-map';local mapWrites=0;local mapFail=false
local storage={saveDataAtomic=function(_,bytes,name)
 eq(name,'gameMap1');if mapFail then return false end;mapDisk=bytes;mapWrites=mapWrites+1;return true
end}
local originalRoleDisk=F.disk;local originalLive=F.capture();local originalCargo=F.snapshot(dm:getRoleData(roleBattlePack));local originalLedger=F.snapshot(dm:getRoleData('adventureProgressV1'))
mapFail=true;local ok,reason=P.checkpoint(owner,dm,storage);eq(ok,false);eq(reason,'map_failed');eq(F.disk,originalRoleDisk);eq(mapDisk,'old-map');eq(F.atomic,0)
mapFail=false;F.fail=true;ok,reason=P.checkpoint(owner,dm,storage);eq(ok,false);eq(reason,'role_failed')
eq(F.disk,originalRoleDisk,'role file remains original after failed second write');eq(mapWrites,1)
eq(json.decode(mapDisk).titlesInfo['187'].fogId,'0','map file is explicitly newer after partial pair')
eq(F.capture(),originalLive,'failed role write does not publish candidate tile')
-- Actual encrypted role reload establishes precisely what the partial pair can
-- promise: previous role tile/food/cargo/active voyage, with the newly saved fog.
dm.__roleData=UserData.new();assert(dm.__roleData:loadData())
eq(dm:getRoleData(roleMapInfo).playerTitlePosition.x,3,'partial cold load retains old saved tile')
eq(dm:getRoleData(roleBreadCostDecimal),.25,'partial cold load retains old food fraction')
eq(F.snapshot(dm:getRoleData(roleBattlePack)),originalCargo,'partial cold load preserves cargo')
eq(F.snapshot(dm:getRoleData('adventureProgressV1')),originalLedger,'partial cold load does not start/finish voyage')
dm.__roleData:setRoleData(mapInfo,json.decode(mapDisk));F.fail=false
ok,reason=P.checkpoint(owner,dm,storage);eq(ok,true);eq(reason,'saved');eq(F.atomic,1)
local savedDisk=F.disk;dm.__roleData=UserData.new();assert(dm.__roleData:loadData())
eq(dm:getRoleData(roleMapInfo).playerTitlePosition.x,7);eq(dm:getRoleData(roleMapInfo).playerTitlePosition.y,9)
eq(dm:getRoleData(roleBreadCostDecimal),.75,'successful retry cold-loads current food fraction')
eq(F.snapshot(dm:getRoleData(roleBattlePack)),originalCargo);eq(F.snapshot(dm:getRoleData('adventureProgressV1')),originalLedger)
eq(dm:getRoleData(roleMapInfo).fristReturnBaseByTool,'1','checkpoint never resets existing paid-return flag')
eq(F.capture(),originalLive,'snapshot changes only separately tested tile/fraction; economy unchanged')
dm.__roleData:setRoleData(mapInfo,F.copy(map))
local info=F.copy(dm:getRoleData(roleMapInfo));info.willFight='pending-battle';dm.__roleData:setRoleData(roleMapInfo,info)
local before=F.disk;local writes=mapWrites;ok,reason=P.checkpoint(owner,dm,storage)
eq(ok,false);eq(reason,'unavailable');eq(mapWrites,writes);eq(F.disk,before);eq(dm:getRoleData(roleMapInfo).willFight,'pending-battle','pending fight is untouched')
info.willFight=nil;dm.__roleData:setRoleData(roleMapInfo,info)
owner.statue='Triggering';eq(P.checkpoint(owner,dm,storage),false);owner.statue='ready'
owner.isHungry=true;eq(P.checkpoint(owner,dm,storage),false);owner.isHungry=false
owner.moveWaitingQueue={1};eq(P.checkpoint(owner,dm,storage),false);owner.moveWaitingQueue={}
owner.eventManger.eventWaitingQueue={'battle'};eq(P.checkpoint(owner,dm,storage),false)
eq(F.disk,before,'all busy/unsafe checkpoints leave role disk unchanged')
print('PASS WarmPause real encrypted cold reload: map failure, explicit partial pair, saved retry, unchanged cargo/economy/voyage, pending-fight and busy gates')
