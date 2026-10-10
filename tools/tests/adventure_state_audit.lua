-- Independent audit: real encrypted UserData and SaveDataManager; only Record I/O mocked.
package.path='bin/res/scripts/?.lua;'..package.path
for _,n in ipairs({'LuaClass/Header','LuaClass/Utils','LuaClass/simplejson.lua'}) do package.loaded[n]={} end
class=function() local c={};c.__index=c;c.new=function()return setmetatable({retain=function()end},c)end;return c end
cclog=function()end
for _,k in ipairs({'roleEncrypted','rolePack','roleMoney','roleDiamond','roleAlchemyCanLongPress','roleGuideStep','roleSoildierQueue','roleBattlePack','roleBattleQueue','roleSelectUnit','rolePackSize','roleCabinSize','roleMapCoin','roleStatue','roleBreadCostDecimal','roleMapInfo','roleBuilding','roleDeathInformation','roleTempReceivedDatas','roleBlackMarketRestrictions','csvOfResourceInfo'}) do _G[k]=k end
dataKeyID='id';dataKeyNum='num'
json=dofile('bin/res/scripts/LuaClass/simplejson.lua');package.loaded.json=json
local disk,fail,writes=nil,false,0
Record={GetInstance=function(self)return self end,loadData=function()return disk end,saveData=function(_,str)disk=str end,saveDataAtomic=function(_,str)writes=writes+1;if fail then return false end;disk=str;return true end}
require 'LuaClass/SaveDataManager';require 'LuaClass/UserData';local A=require 'LuaClass/AdventureProgress'
local dm={__roleData=UserData.new(),events={}}
function dm:getRoleData(k)return self.__roleData:getRoleData(k)end
function dm:postEvent(k)self.events[#self.events+1]=k end
function dm:getCSVByID(k)return {['1999']={cubage=0,carryType='2'},['1001']={cubage=0},['1002']={cubage=0},['1005']={cubage=1,carryType='1'},['1008']={cubage=1},['1007']={cubage=1}}end
local function fixture(extra)
 disk=nil;dm.__roleData=UserData.new();assert(not dm.__roleData:loadData());dm.events={};fail=false
 local f={[A.KEY]={version=1,enabled=true,voyage=0,objective='rescue'},[rolePack]={['1005']=100},[roleSoildierQueue]={['100']={id='100',num=3}},[roleMoney]=40,[roleDiamond]=500,[roleAlchemyCanLongPress]=1,[roleGuideStep]='s001_r030',[roleBattlePack]={},[roleBattleQueue]={},[roleSelectUnit]={},[rolePackSize]=20,[roleCabinSize]=2,[roleBuilding]={},[roleMapInfo]={},[roleMapCoin]=0,[roleStatue]=0,[roleBreadCostDecimal]=0}
 for k,v in pairs(extra or {})do f[k]=v end
 for k,v in pairs(f)do dm.__roleData:setRoleData(k,v)end;dm.__roleData:saveData()
end
local function reload()dm.__roleData=UserData.new();assert(dm.__roleData:loadData())end
local function stableFail(fn)
 local before=disk;dm.events={};fail=true;local ok,err=fn();assert(ok==false and err=='save_failed',tostring(ok)..':'..tostring(err));assert(disk==before and #dm.events==0);reload();assert(disk==before);fail=false
end
fixture({[roleGuideStep]='s001'})
stableFail(function()return A.claimStarter(dm)end)
assert(A.claimStarter(dm));assert(dm:getRoleData(roleSoildierQueue)['100'].num==4);assert(dm:getRoleData(rolePack)['1005']==200)
assert(not A.claimStarter(dm));reload();assert(dm:getRoleData(roleSoildierQueue)['100'].num==4)
fixture();stableFail(function()return A.depart(dm,{['1005']=10,['10100']=2})end)
assert(A.depart(dm,{['1005']=10,['10100']=2}));assert(dm:getRoleData(roleSoildierQueue)['100'].num==1);assert(dm:getRoleData(roleBattleQueue)['100']==2)
stableFail(function()return A.resolveEvent(dm,'rescue')end)
assert(A.resolveEvent(dm,'rescue'));assert(dm:getRoleData(roleBattlePack)['1005'].num==7);assert(dm:getRoleData(roleBattlePack)['1008'].num==2)
local before=disk;assert(not A.resolveEvent(dm,'supply'));assert(disk==before)
dm.__roleData:setRoleData(roleMapCoin,11);dm.__roleData:setRoleData(roleBattlePack,{['1005']={id='1005',num=7},['1008']={id='1008',num=2},['1001']={id='1001',num=3},['1002']={id='1002',num=2}});dm.__roleData:saveData()
stableFail(function()return A.returnVoyage(dm,nil)end)
assert(dm:getRoleData(roleBattleQueue)['100']==2)
local ok,awarded=A.returnVoyage(dm,nil);assert(ok and awarded)
assert(dm:getRoleData(roleMoney)==79,'cargo + map coins + 25 award counted once')
assert(dm:getRoleData(roleDiamond)==502,'cargo diamond must use original currency field')
assert(dm:getRoleData(rolePack)['1002']==nil)
assert(dm:getRoleData(roleSoildierQueue)['100'].num==3,'same class retained exactly')
assert(dm:getRoleData(roleAlchemyCanLongPress)==1,'paid entitlement preserved')
assert(dm:getRoleData(rolePack)['1008']==2 and dm:getRoleData(rolePack)['1005']==97)
assert(next(dm:getRoleData(roleBattlePack))==nil and next(dm:getRoleData(roleBattleQueue))==nil)
for i=1,4 do reload();local before=disk;assert(A.returnVoyage(dm,nil));assert(disk==before);assert(dm:getRoleData(roleMoney)==79 and dm:getRoleData(roleSoildierQueue)['100'].num==3)end
print('PASS real transaction path: starter/depart/event/return save failure cold reload, no failed events, repeated event/return idempotent, crew schema and currencies conserved, paid entitlement preserved')
fixture();assert(A.depart(dm,{['1005']=10,['10100']=1}));assert(A.resolveEvent(dm,'rescue'));local p=dm:getRoleData(roleBattlePack);p['1008'].num=1;dm.__roleData:setRoleData(roleBattlePack,p)
assert(A.returnVoyage(dm,nil));assert(not A.getState(dm).firstReturnClaimed);assert(dm:getRoleData(roleMoney)==40)
print('PASS iron discarded before return cannot claim construction subsidy')
fixture();dm.__roleData:setRoleData(A.KEY,nil);dm.__roleData:saveData();local before=disk
assert(not A.getState(dm).enabled);assert(not A.claimStarter(dm));assert(not A.depart(dm,{['1005']=10,['10100']=1}));assert(disk==before)
print('PASS missing marker legacy role never gets grants or migrated by ledger reads')
fixture();assert(A.depart(dm,{['1005']=10,['10100']=1}));reload()
-- Production controller.lua chooses sea iff roleStatue == 1 at cold startup.
local startupDestination=dm:getRoleData(roleStatue)==1 and 'sea' or 'harbor'
assert(startupDestination=='sea','departure snapshot must route cold startup to the sea')
local before=disk;local ok=A.depart(dm,{['1005']=10,['10100']=1});assert(not ok,'active voyage must reject repeated departure');assert(disk==before)
print('PASS departed snapshot resumes sea and cannot overwrite live voyage assets')
fixture();assert(A.depart(dm,{['1005']=19,['10100']=1}));local before=disk
local ok,why=A.resolveEvent(dm,'supply');assert(not ok and why=='cargo_full');assert(disk==before and dm:getRoleData(roleBattlePack)['1005'].num==19)
local ok,why=A.resolveEvent(dm,'sailor');assert(not ok and why=='crew_required');assert(disk==before)
fixture();assert(A.depart(dm,{['1005']=2,['10100']=1}));local before=disk
local ok,why=A.resolveEvent(dm,'rescue');assert(not ok and why=='food_required');assert(disk==before)
print('PASS capacity/crew/food rejection changes neither stock nor pending ledger')
fixture();assert(A.depart(dm,{['1005']=10,['10100']=1}));assert(A.resolveEvent(dm,'supply'));assert(A.returnVoyage(dm,nil));assert(not A.getState(dm).npcRescued)
assert(A.availableEpisode(dm)==nil)
dm.__roleData:setRoleData(rolePackSize,30);dm.__roleData:setRoleData(roleSoildierQueue,{['101']={id='101',num=1},['100']={id='100',num=3}})
assert(A.availableEpisode(dm)=='crew');assert(A.depart(dm,{['1005']=10,['10101']=1}));assert(A.resolveEvent(dm,'sailor'))
assert(dm:getRoleData(roleBattlePack)['1005'].num==9)
assert(A.returnVoyage(dm,nil));reload();assert(A.getState(dm).followupReturned);assert(not A.getState(dm).npcRescued,'later rescue must not rewrite abandoned first NPC fate');assert(dm:getRoleData(roleMoney)==65,'follow-up has no repeated subsidy');assert(A.availableEpisode(dm)==nil)
print('PASS later occupation event is reachable after 30 cargo and cannot repeat subsidy or rewrite first NPC choice')
fixture();assert(A.depart(dm,{['1005']=10,['10100']=1}));dm.__roleData:setRoleData(roleMapCoin,11)
assert(A.returnVoyage(dm,true));assert(dm:getRoleData(roleMoney)==40,'legacy scroll return drops mapCoin');assert(dm:getRoleData(roleMapCoin)==0)
fixture();assert(A.depart(dm,{['1005']=10,['10100']=1}));assert(A.resolveEvent(dm,'rescue'));local before=disk
assert(not A.returnVoyage(dm,'Killed'));assert(not A.returnVoyage(dm,'NoBread'));assert(disk==before)
assert(not A.getState(dm).firstReturnClaimed and not A.getState(dm).npcRescued)
print('PASS scroll mapCoin rules retained; normal-return API cannot turn death into reward or rescued NPC')
-- Exercise the real Explore death-record assembler as well as its atomic ledger call.
local file=assert(io.open('bin/res/scripts/LuaClass/Explore.lua'));local source=file:read('*a');file:close()
Explore={};DataManager={getInstance=function()return dm end}
dataController={getSoilderInfoById=function()return {name='fixture',hp=10,attack=2,star=1,speed=1,skill='1',icon='fixture',rebornConsume={{'1001','2'}}}end,getSkillValueByIdAndKey=function()return 'fixture skill'end,getResourceValueByIdAndKey=function()return 'coin'end}
local fn=assert(source:match('(function Explore:addDeadData%(%s*%)%s*.-)\nfunction Explore:getbackObjectStr'))
assert(loadstring("local AdventureProgress=require 'LuaClass/AdventureProgress'\n"..fn))()
fixture({[roleDeathInformation]={{id='100',num=2}},[roleMapInfo]={curIndex=1,playerTitlePosition={x=2,y=3}},[roleBlackMarketRestrictions]={tempRestrictions={one=1},permanent=7}})
assert(A.depart(dm,{['1005']=10,['10100']=1}));assert(A.resolveEvent(dm,'rescue'));dm.__roleData:setRoleData(roleMapCoin,11);dm.__roleData:saveData()
local owner={playerfighters={{id='100',num=1}},bagController={battlePackData=dm:getRoleData(roleBattlePack),mapCoin=11}}
local before=disk;fail=true;assert(Explore.addDeadData(owner)==false);assert(disk==before);assert(#owner.playerfighters==1 and owner.bagController.mapCoin==11);reload()
assert(A.getState(dm).activeVoyage and A.getState(dm).pending and dm:getRoleData(roleStatue)==1 and dm:getRoleData(roleBattleQueue)['100']==1 and dm:getRoleData(roleDeathInformation)[1].num==2)
fail=false;assert(Explore.addDeadData(owner));reload()
assert(dm:getRoleData(roleDeathInformation)[1].num==3 and dm:getRoleData(roleSoildierQueue)['100'].num==2)
assert(dm:getRoleData(roleMoney)==40 and dm:getRoleData(roleDiamond)==500 and dm:getRoleData(roleMapCoin)==0)
assert(next(dm:getRoleData(roleBattlePack))==nil and next(dm:getRoleData(roleBattleQueue))==nil)
assert(dm:getRoleData(roleStatue)==0 and not A.getState(dm).activeVoyage and not A.getState(dm).pending and not A.getState(dm).npcRescued and not A.getState(dm).firstReturnClaimed)
assert(dm:getRoleData(roleMapInfo).playerTitlePosition==nil and dm:getRoleData(roleBlackMarketRestrictions).tempRestrictions==nil and dm:getRoleData(roleBlackMarketRestrictions).permanent==7)
for i=1,3 do local before=disk;assert(Explore.addDeadData(owner));assert(disk==before);reload();assert(dm:getRoleData(roleDeathInformation)[1].num==3)end
print('PASS real Explore death assembler + atomic failVoyage: failed storage preserves fleet/death records for retry; successful death clears sea assets, keeps home crew and paid entitlement, cold reload and replay cannot duplicate revival records or rewards')
fixture({[roleBlackMarketRestrictions]={tempRestrictions={one=1},permanent=7},[roleTempReceivedDatas]={one=1}})
assert(A.depart(dm,{['1005']=10,['10100']=1}));assert(A.returnVoyage(dm,nil));reload()
assert(dm:getRoleData(roleBlackMarketRestrictions).tempRestrictions==nil and dm:getRoleData(roleBlackMarketRestrictions).permanent==7,'normal return must clear temporary market restrictions')
assert(next(dm:getRoleData(roleTempReceivedDatas) or {})==nil)
fixture();assert(A.depart(dm,{['1005']=10,['10100']=1}));local p=dm:getRoleData(roleBattlePack);p['1999']={id='1999',num=2};dm.__roleData:setRoleData(roleBattlePack,p);dm.__roleData:saveData()
stableFail(function()return A.failVoyage(dm,{{id='100',num=1}})end)
assert(A.failVoyage(dm,{{id='100',num=1}}));reload();assert(dm:getRoleData(rolePack)['1999']==2,'legacy carryType2 mission items survive death');assert(dm:getRoleData(rolePack)['1005']==90,'ordinary food is lost on death')
local before=disk;assert(A.failVoyage(dm,{}));assert(disk==before and dm:getRoleData(rolePack)['1999']==2)
print('PASS normal-return transient cleanup and legacy mission-item survival on death retained atomically')
