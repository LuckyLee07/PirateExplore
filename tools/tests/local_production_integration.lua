-- Synthetic profile and frozen wall clock. Record storage is mocked; no real save I/O.
package.path='bin/res/scripts/?.lua;'..package.path
for _,n in ipairs({'LuaClass/Header','LuaClass/Utils','LuaClass/SDButton','LuaClass/HttpSingleton','LuaClass/SevenDayBonus','LuaClass/simplejson.lua'}) do package.loaded[n]={} end
class=function() local c={};c.__index=c; c.new=function() return setmetatable({retain=function()end},c) end;return c end
cclog=function()end
roleEncrypted='encrypted';rolePack='pack';roleMoney='money';roleProduceTime='phase';roleResourceCD='cd';roleOfflineBonusTime='cap';roleProducerQueue='workers';csvOfWorker='recipes';csvOfResourceInfo='res';dataKeyID='id';dataKeyNum='num'
json=dofile('bin/res/scripts/LuaClass/simplejson.lua');package.loaded.json=json
local disk,fail,writes=nil,false,0
Record={GetInstance=function(self)return self end,loadData=function() return disk end,saveData=function(_,str) disk=str end,saveDataAtomic=function(_,str) writes=writes+1;if fail then return false end;disk=str;return true end}
require 'LuaClass/SaveDataManager';require 'LuaClass/UserData';require 'LuaClass/NotificationNode'
local dm={__roleData=UserData.new(),events={},toasts={}}
DataManager={getInstance=function()return dm end}
function dm:getRoleData(k)return self.__roleData:getRoleData(k) end
function dm:postEvent(k) assert(disk,'event without disk');self.events[#self.events+1]=k end
function dm:getCSVByID(k) if k=='recipes' then return {['1']={resume={{'0'}},produce={{'1005','1'}}}} else return {['1005']={name='food'}} end end
local checks, unlocks = 0, 0
function dm:checkAutoLearnedTallent() checks=checks+1;return {fixtureTalent=true} end
function dm:unlockTallentByKey(key) assert(key=='fixtureTalent');unlocks=unlocks+1 end
ToastUtil={productionString=function(_,str)dm.toasts[#dm.toasts+1]=str end}
local now=1000;os.time=function()return now end
NotificationNode.lastUpdateTime=1000
local node=NotificationNode.new()
assert(not dm.__roleData:loadData())
for k,v in pairs({pack={marker=21},money=7,phase=0,cd=20,cap=3600,workers={{id='1',num=2}}}) do dm.__roleData:setRoleData(k,v) end
dm.__roleData:saveData()
local original=disk
fail=true;node:settleLocalProduction();assert(disk==original);assert(dm:getRoleData('localProductionV1')==nil);assert(#dm.events==0 and checks==0 and unlocks==0)
fail=false;node:settleLocalProduction();assert(dm:getRoleData('localProductionV1').wall==1000);assert(dm:getRoleData('pack').marker==21)
now=1060;dm.events={};dm.toasts={};original=disk;fail=true
node:settleLocalProduction();assert(disk==original);assert(dm:getRoleData('pack')['1005']==nil);assert(dm:getRoleData('localProductionV1').wall==1000);assert(#dm.events==0 and #dm.toasts==0)
fail=false;node:settleLocalProduction();assert(dm:getRoleData('pack')['1005']==6);assert(dm:getRoleData('money')==7);assert(dm:getRoleData('localProductionV1').wall==1060);assert(#dm.events==4 and #dm.toasts==1)
for i=1,4 do
 dm.__roleData=UserData.new();assert(dm.__roleData:loadData());dm.events={};dm.toasts={};local before=disk
 node:settleLocalProduction();assert(disk==before);assert(dm:getRoleData('pack')['1005']==6);assert(#dm.events==0 and #dm.toasts==0)
end
now=1079;node:settleLocalProduction();assert(dm:getRoleData('pack')['1005']==6)
now=1080;node:settleLocalProduction();assert(dm:getRoleData('pack')['1005']==8)
print('PASS real NotificationNode→UserData proxy→SaveDataManager: failed migration, failed reward preserve disk/memory/anchor, zero failed events/toasts, retry once, four JSON cold reloads, online boundary no overlap; mocked Record only')

-- A resume inside a partial cycle rebases display time without changing reward.
now=1085;NotificationNode.lastUpdateTime=1040
local beforeFood=dm:getRoleData('pack')['1005']
node:settleLocalProduction(true)
assert(dm:getRoleData('pack')['1005']==beforeFood)
assert(dm:getRoleData('phase')==1055)
assert(dm:getRoleData('localProductionV1').remaining==15)
assert(checks==unlocks and unlocks>0)
print('PASS successful transactions preserve talent checks; resume checkpoints partial phase without granting or advancing voyage time')

local callbacks={};local dispatcher={addEventListenerWithFixedPriority=function()end};local director={getNotificationNode=function()return {getEventDispatcher=function()return dispatcher end}end}
cc={EventListenerCustom={create=function(_,name,fn)callbacks[name]=fn;return {} end},Director={getInstance=function()return director end}}
GuideController={getInstance=function(self)return self end,getIsHaveStep=function()return false end}
node:registeventDispatcher();local before=disk;local count=writes
callbacks.getLasttime({_usedata='9000000000'});callbacks.getLasttime({_usedata='9000000000'})
assert(disk==before and writes==count and dm:getRoleData('pack')['1005']==beforeFood)
local requests=0;requestLastTime=function()requests=requests+1 end;node.localProductionStarted=true
callbacks.backtobefor();callbacks.backtobefor();assert(requests==2 and dm:getRoleData('pack')['1005']==beforeFood)
assert(dm:getRoleData('localProductionV1').wall==1085)
print('PASS real registered server callback cannot double local reward; repeated foreground checkpoints preserve quantity and retain separate server request')

-- Sea production updates home inventory, but does not emit the dock food event
-- or advance the simulation clock used by voyage consumption.
isEnterMap=true;now=1100;dm.events={};dm.toasts={}
local gameClock=NotificationNode.lastUpdateTime
node:settleLocalProduction()
assert(NotificationNode.lastUpdateTime==gameClock and #dm.toasts==0)
for _,event in ipairs(dm.events) do assert(event~='breadBirth') end
print('PASS sea resume produces home resources without dock food event, production text, or elapsed voyage-time advance')
