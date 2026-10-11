-- Isolated actual DataManager/UserData methods and decrypted shipped CSV.
-- Only Record persistence/observers and automatic-talent candidates are fixtures.
package.path='bin/res/scripts/?.lua;'..package.path
local F={atomic=0,normal=0,events={},logs={},toasts={},checks=0}
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
function F.equal(a,b,why)assert(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
function F.copy(t)if type(t)~='table' then return t end;local r={};for k,v in pairs(t)do r[k]=F.copy(v)end;return r end
function F.snapshot(t)if type(t)~='table' then return type(t)..':'..tostring(t)end;local out={};for k,v in pairs(t)do out[#out+1]=F.snapshot(k)..'='..F.snapshot(v)end;table.sort(out);return '{'..table.concat(out,'|')..'}'end
if not cc then
 cc={c3b=function(...)return {...}end,Node={create=function()return {}end}}
 class=function()local c={};c.__index=c;c.new=function()return setmetatable({retain=function()end},c)end;return c end
 package.loaded.Cocos2d={};package.loaded.Cocos2dConstants={}
end
cclog=function()end;clone=F.copy
require 'LuaClass/Header'
local source=read('tools/tests/home_master_regression.lua');local first=assert(source:find('local function readFile(path)',1,true));local last=assert(source:find("\nlocal soldiers=packagedCSV('soilderAttribute')",first,true))
local csvRead=assert(loadstring('local equal=...\n'..source:sub(first,last-1)..'\nreturn packagedCSV'))(F.equal)
F.csv={}
for key,name in pairs({[csvOfBuild]='build',[csvOfStore]='store',[csvOfProduce]='produce',[csvOfResourceInfo]='resourceInfo',[csvOfSoilderAttribute]='soilderAttribute',[csvOfTalent]='talent',[csvOfAchievement]='achievement'})do
 F.csv[key]=csvRead(name)
 for _,row in pairs(F.csv[key])do for _,field in ipairs({'activateID','raiseType','resume','activeInfo'})do
  if row[field] then local rr={};for part in row[field]:gmatch('[^;]+')do local r={};for value in part:gmatch('[^_]+')do r[#r+1]=value end;rr[#rr+1]=r end;row[field]=rr end
 end end
end
for _,row in pairs(F.csv[csvOfTalent])do for _,field in ipairs({'preID','increaseAttrs','increaseTypes','increaseNums'})do
 local list={};for value in row[field]:gmatch('[^;]+')do list[#list+1]=value end;row[field]=list
end end
for _,m in ipairs({'Utils','CSVParser','StaticData','DynamicData','AlertView','simplejson.lua'})do package.loaded['LuaClass/'..m]={}end
json=dofile('bin/res/scripts/LuaClass/simplejson.lua');package.loaded.json=json
Record={GetInstance=function(self)return self end,loadData=function()return F.disk end,
 saveData=function(_,s)F.normal=F.normal+1;F.disk=s end,
 saveDataAtomic=function(_,s)F.attempts=(F.attempts or 0)+1;if F.throw then error('injected disk failure')end;if F.fail then return false end;F.disk=s;F.atomic=F.atomic+1;return true end}
require 'LuaClass/UserData';require 'LuaClass/DataManager';require 'LuaClass/GuideController'
F.dm=DataManager.new();DataManagerSingleton=F.dm
function F.dm:getCSVByID(id)return F.csv[id] or {}end
function F.dm:postEvent(key,event)
 F.events[#F.events+1]=key
 for _,fn in pairs((self.__eventListener or {})[key] or {})do fn(event)end
end
function F.dm:registerEvent(key,name,fn)self.__eventListener=self.__eventListener or {};self.__eventListener[key]=self.__eventListener[key] or {};self.__eventListener[key][name]=fn end
function F.dm:unregisterEvent(key,name)if self.__eventListener and self.__eventListener[key]then self.__eventListener[key][name]=nil end end
function F.dm:sendSystemInfo(text)F.logs[#F.logs+1]=text end
function F.dm:checkAutoLearnedTallent()F.checks=F.checks+1;return {}end
F.dm.__dynamicData={getLockedTallent=function()return F.locked end,loadLockedTallent=function(_,v)F.locked=v end}
getTableRowNum=function(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
MissionManagers={getInstance=function(self)return self end,onTriggerMission=function(_,taskID,taskOk)assert(not taskID and not taskOk,'unexpected packaged mission hook')end}
ToastUtil={downString=function(_,value)F.toasts[#F.toasts+1]=value end,toastString=function(_,value)F.toasts[#F.toasts+1]=value end}
function F.reset(options)
 options=options or {};F.disk=nil;F.fail=false;F.throw=false;F.locked={};F.events={};F.logs={};F.toasts={};F.atomic=0;F.normal=0;F.attempts=0;F.checks=0
 F.dm.__eventListener={};F.dm.__roleData=UserData.new();assert(not F.dm.__roleData:loadData())
 local data={[rolePackSize]=20,[roleAlchemyUnit]=1,[roleMoney]=25,[roleDiamond]=0,[roleGuideStep]='s001_s010_s060_r102_r002',
  [rolePack]={['1007']=10,['1018']=10,['1008']=8,['1006']=15,['1005']=20},
  [roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=1}},
  [roleMake]={{[dataKeyID]='1148',[dataKeyNum]='-1',sortId='6'},{[dataKeyID]='1176',[dataKeyNum]='-1',sortId='30'}},
  [roleStatue]=0,[roleShipId]='1299',[roleTalent]={},[roleMission]={}}
 for k,v in pairs(options)do data[k]=v end
 for k,v in pairs(data)do F.dm.__roleData:setRoleData(k,v)end
 F.dm.__roleData:saveData();GuideController.instance=nil;GuideController:getInstance()
 F.normal=0;return F.dm
end
function F.capture()
 local keys={rolePackSize,roleAlchemyUnit,roleMoney,roleDiamond,roleGuideStep,rolePack,roleBuilding,roleMake,roleStatue,roleShipId,roleTalent,roleMission,roleBonusAttribute,roleAchievement,roleAchievementPoint}
 local data={};for _,key in ipairs(keys)do data[key]=F.copy(F.dm:getRoleData(key))end;return F.snapshot(data)
end
F.reset();return F
