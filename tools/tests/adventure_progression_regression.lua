-- Isolated production-method regression, real packaged recipes and encrypted
-- UserData; never accesses a player profile. This is not a GUI playthrough.
package.path='bin/res/scripts/?.lua;'..package.path
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local function eq(a,b,why)assert(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
cc={c3b=function(...)return {...}end,Node={create=function()return {}end}}
class=function()local c={};c.__index=c;c.new=function()return setmetatable({retain=function()end},c)end;return c end
cclog=function()end
local function copy(t)if type(t)~='table' then return t end;local o={};for k,v in pairs(t)do o[k]=copy(v)end;return o end
clone=copy
package.loaded.Cocos2d={};package.loaded.Cocos2dConstants={}
require 'LuaClass/Header'
local source=read('tools/tests/home_master_regression.lua')
local first=assert(source:find('local function readFile(path)',1,true));local last=assert(source:find("\nlocal soldiers=packagedCSV('soilderAttribute')",first,true))
local csvRead=assert(loadstring('local equal=...\n'..source:sub(first,last-1)..'\nreturn packagedCSV'))(eq)
local csv={}
for key,name in pairs({[csvOfBuild]='build',[csvOfStore]='store',[csvOfProduce]='produce',[csvOfResourceInfo]='resourceInfo',[csvOfSoilderAttribute]='soilderAttribute',[csvOfStrongholdDistribution]='strongholdDistribution',[csvOfShopItem]='shopitem'})do
 csv[key]=csvRead(name)
 for _,row in pairs(csv[key])do for _,field in ipairs({'activateID','raiseType','resume','activeInfo'})do
  if row[field] then local rr={};for part in row[field]:gmatch('[^;]+')do local r={};for value in part:gmatch('[^_]+')do r[#r+1]=value end;rr[#rr+1]=r end;row[field]=rr end
 end end
end
for _,m in ipairs({'Utils','CSVParser','StaticData','DynamicData','AlertView','simplejson.lua'})do package.loaded['LuaClass/'..m]={}end
json=dofile('bin/res/scripts/LuaClass/simplejson.lua');package.loaded.json=json
local disk,fail,writes=nil,false,0
Record={GetInstance=function(self)return self end,loadData=function()return disk end,saveData=function(_,s)disk=s end,saveDataAtomic=function(_,s)if fail then return false end;disk=s;writes=writes+1;return true end}
require 'LuaClass/UserData';require 'LuaClass/DataManager';require 'LuaClass/GuideController'
local dm=DataManager.new();DataManagerSingleton=dm;dm.__roleData=UserData.new()
function dm:getCSVByID(id)return csv[id] or {}end
function dm:postEvent()end
function dm:sendSystemInfo()end
function dm:checkAutoLearnedTallent()return {}end
getTableRowNum=function(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
MissionManagers={getInstance=function(self)return self end,onTriggerMission=function()end}
ToastUtil={downString=function()end}
local A=require 'LuaClass/AdventureProgress'
assert(not dm.__roleData:loadData())
for _,f in ipairs({'loadProducerQueueData','loadMoney','loadPackage','loadExpedition','loadSoildier','loadGuideStep'})do dm.__roleData[f](dm.__roleData,nil)end
dm.__roleData:loadBuild(csv[csvOfBuild]);dm.__roleData:loadMake(csv[csvOfProduce],csv[csvOfResourceInfo]);dm.__roleData:loadStore(csv[csvOfStore],csv[csvOfResourceInfo])
assert(A.initializeNewRole(dm.__roleData,dm));eq(dm:getRoleData(roleMoney),0,'prebuild is not cash reward');eq(dm:getRoleData(roleDiamond),0,'no test diamonds')
local function build(id)for _,v in ipairs(dm:getRoleData(roleBuilding))do if v[dataKeyID]==id then return v end end end
for _,id in ipairs({'1','2','53','56'})do eq(build(id)[dataKeyNum],1,'prebuilt '..id)end
for _,id in ipairs({'3','52','58'})do eq(build(id)[dataKeyNum],0,'waiting '..id)end
eq(build('57'),nil);eq(dm:getRoleData(roleLivingUnitNum),5)
for _,id in ipairs({1,2,3,5,8})do assert(GuideController:getInstance():getIsHaveStep(id))end
local store={};for _,v in ipairs(dm:getRoleData(roleStore))do store[v.sortId]=true end;assert(store['1'] and store['2'] and store['3'])
assert(A.claimStarter(dm));eq(dm:getRoleData(roleSoildierQueue)['100'][dataKeyNum],1);eq(dm:getRoleData(rolePack)['1005'],100)
assert(not A.claimStarter(dm));eq(dm:getRoleData(rolePack)['1005'],100)
assert(A.depart(dm,{['10100']=1,['1005']=12}));eq(dm:getRoleData(roleSoildierQueue)['100'],nil);eq(dm:getRoleData(roleBattleQueue)['100'],1);eq(dm:getRoleData(rolePack)['1005'],88)
assert(A.resolveEvent(dm,'rescue'));eq(dm:getRoleData(roleBattlePack)['1005'].num,9);eq(dm:getRoleData(roleBattlePack)['1008'].num,2);eq(build('57')[dataKeyNum],0)
assert(not A.resolveEvent(dm,'supply'))
local ok,awarded=A.returnVoyage(dm,nil);assert(ok and awarded);eq(dm:getRoleData(rolePack)['1008'],2);eq(dm:getRoleData(roleMoney),25);eq(dm:getRoleData(roleSoildierQueue)['100'][dataKeyNum],1)
assert(A.getHarborStatus(dm).npcRescued);eq(next(dm:getRoleData(roleBattlePack)),nil)
assert(A.returnVoyage(dm,nil));eq(dm:getRoleData(roleMoney),25)
local beforeForge=A.getHarborStatus(dm).npcText
assert(beforeForge:find('建铁匠铺',1,true) and not beforeForge:find('铁匠铺已建',1,true),'waiting forge has honest build target')
-- Spend the actual CSV recipe through the existing inventory methods, then
-- execute existing completion effects. No fabricated unlock or capacity write.
local function spend(row)
 for _,r in ipairs(row.resume)do assert(dm:addPackItemWithId(r[1],-tonumber(r[2]),false)~=false)end
end
spend(csv[csvOfBuild]['57']);assert(dm:createSuccessCheck(kUnlockBuild,'57'));eq(build('57')[dataKeyNum],1)
local afterForge=A.getHarborStatus(dm).npcText
assert(afterForge:find('铁匠铺已建，去制造货舱',1,true) and afterForge:find('消耗5木、5布',1,true),'built forge targets real cargo recipe')
assert(not afterForge:find('2铁建铁匠铺',1,true),'built forge never asks to rebuild')
local found=false;for _,v in ipairs(dm:getRoleData(roleMake))do if v.sortId=='6' then found=true end end;assert(found,'real forge cascade exposes cargo recipe')
assert(GuideController:getInstance():getIsHaveStep(10),'manufacturing entrance opens')
spend(csv[csvOfResourceInfo]['1148']);assert(dm:createSuccessCheck(kUnlockMake,'6'));eq(dm:getRoleData(rolePackSize),30);eq(dm:getRoleData(rolePack)['1008'],nil);eq(dm:getRoleData(roleMoney),0)
eq(A.availableEpisode(dm),'crew','growth opens a genuinely playable followup')
assert(A.getHarborStatus(dm).npcText:find('30格货舱已经装好',1,true),'real capacity advances harbor target')
local snapshot=disk;dm.__roleData=UserData.new();assert(dm.__roleData:loadData());eq(dm:getRoleData(rolePackSize),30);eq(dm:getRoleData(roleLivingUnitNum),5);assert(A.getState(dm).firstReturnClaimed);eq(disk,snapshot)
print('PASS real CSV bootstrap + once-only starter + atomic departure/event/return + original forge/cargo cost and cascade + JSON reload; zero diamonds')
-- Legacy ledger absence is not interpreted as a new player, even with no guide.
dm.__roleData:setRoleData(A.KEY,nil);local before=disk;assert(not A.getState(dm).enabled);assert(not A.claimStarter(dm));eq(disk,before)
print('PASS absent ledger legacy save receives no bootstrap, reward or mutation')
-- Patrol is an explicitly bounded replacement for the old forced-guide immunity.
dm.__roleData:setRoleData(A.KEY,{version=1,enabled=true,voyage=1,activeVoyage=1,tutorialPath={{x=2,y=2},{x=3,y=2},{x=4,y=2}}})
assert(A.isTutorialProtected(dm,1,{x=3,y=2}));assert(not A.isTutorialProtected(dm,1,{x=3,y=3}));assert(not A.isTutorialProtected(dm,2,{x=3,y=2}))
local s=A.getState(dm);s.voyage=2;s.activeVoyage=2;dm.__roleData:setRoleData(A.KEY,s);assert(not A.isTutorialProtected(dm,1,{x=3,y=2}))
s.voyage=1;s.activeVoyage=nil;dm.__roleData:setRoleData(A.KEY,s);assert(not A.isTutorialProtected(dm,1,{x=3,y=2}))
print('PASS tutorial patrol only covers validated first-voyage chapter-one path; leaving path, returning, or second voyage restores ordinary encounters')
-- Execute the production event gate, not only the pure protection predicate.
local eventSource=read('bin/res/scripts/LuaClass/EventManger.lua')
EventManger={}
local gate=assert(eventSource:match('(function EventManger:minesweeper%(%s*%).-)\nfunction EventManger:minesweeperFight'))
assert(loadstring(gate))()
local rolls=0;local manager=setmetatable({owner={mapIndex=1,playerTitlePosition={x=3,y=2},isNeedGuide=false},tryToMinesweeper=function()rolls=rolls+1;return false end,unreezeOwnerOperations=function()end},{__index=EventManger})
s.activeVoyage=1;dm.__roleData:setRoleData(A.KEY,s)
assert(manager:minesweeper()==false);eq(rolls,0,'patrol makes no random roll')
manager.owner.playerTitlePosition={x=3,y=3};manager:minesweeper();eq(rolls,1,'outside corridor keeps ordinary roll')
s.voyage=2;s.activeVoyage=2;dm.__roleData:setRoleData(A.KEY,s);manager.owner.playerTitlePosition={x=3,y=2};manager:minesweeper();eq(rolls,2,'second voyage restores ordinary roll')
-- Finite follow-up bundles have real recipe material IDs and actual volume.
s.firstEventReturned=true;s.firstReturnClaimed=true;dm.__roleData:setRoleData(A.KEY,s)
local expected={rescue={iron=2,leather=8,wood=0,cost=3,volume=10,value=30},supply={iron=6,leather=0,wood=6,cost=0,volume=12,value=24},sailor={iron=3,leather=12,wood=0,cost=1,volume=15,value=45},knife={iron=8,leather=0,wood=8,cost=0,volume=16,value=32}}
for _,option in ipairs(A.eventOptions(dm))do
 local e=assert(expected[option.id]);eq(option.cost,e.cost);eq(option.rewards['1008'],e.iron);eq(option.rewards['1017'] or 0,e.leather);eq(option.rewards['1007'] or 0,e.wood)
 local cargo,value={},0;for id,n in pairs(option.rewards)do cargo[id]={id=id,num=n};value=value+n*tonumber(csv[csvOfResourceInfo][id].price)end
 eq(A.capacity(dm,cargo),e.volume);eq(value,e.value);assert(e.volume+8-option.cost<=30,'fits after four outbound food steps')
end
print('PASS production random encounter gate and exact finite follow-up materials/real cubage/market-value budgets')
for _,chapter in ipairs({1,2})do
 dm.__roleData:setRoleData(roleMapInfo,{curIndex=chapter});local quote=A.quoteReturn(dm,chapter);eq(quote.kind,'free')
 dm.__roleData:setRoleData(roleMapInfo,{curIndex=chapter,fristReturnBaseByTool='1'});dm.__roleData:setRoleData(rolePack,{});dm.__roleData:setRoleData(roleBattlePack,{})
 quote=A.quoteReturn(dm,chapter);eq(quote.kind,'diamond');eq(quote.toolId,'1303');eq(quote.count,1);eq(quote.price,15,'actual shopitem12 price')
 dm.__roleData:setRoleData(rolePack,{['1303']=1});quote=A.quoteReturn(dm,chapter);eq(quote.kind,'scroll');eq(quote.count,1)
end
print('PASS actual chapter-one/two return CSV: first free, one carryType2 scroll, otherwise original 15-diamond shop quote')
