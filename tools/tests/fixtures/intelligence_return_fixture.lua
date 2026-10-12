-- Production native intelligence rows and old-save return callbacks with
-- shipped prices, in-memory state, and a supported-platform purchase spy.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/coherent_service_support_native.lua');local stop=assert(source:find('for _,size in ipairs(',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..'\nreturn {H=H,dm=dm,fresh=fresh,director=director}','@intelligence-return-fixture'))()
local H,dm=F.H,F.dm
local finish=H.finish
H.finish=function()
 local scene=cc.Director:getInstance():getRunningScene()
 if coherentEventEnter and scene and scene:isRunning() then
  F.director:replaceScene(cc.Scene:create());for _=1,4 do F.director:drawScene()end
 end
 finish()
end
local T=dofile('tools/tests/fixtures/real_shortage_owner_fixture.lua')(H,F.director)
package.loaded['LuaClass/ToastUtil']=true
require 'LuaClass/WoWUtils'
package.loaded['LuaClass/MissionManagers']=nil;require 'LuaClass/MissionManagers'
require 'LuaClass/RandomEventMode'
RedColor=cc.c3b(255,0,0)
local function split(s,delimiter)local out={};for part in (s..delimiter):gmatch('(.-)'..delimiter)do out[#out+1]=part end;return out end
local function matrix(records,keys)for _,r in pairs(records)do for _,key in ipairs(keys)do local out={};for _,part in ipairs(split(r[key],';'))do out[#out+1]=split(part,'_')end;r[key]=out end end end
H.tables[csvOfRandomEvent]=H.csv('randomEvent');matrix(H.tables[csvOfRandomEvent],{'cost','info'})
H.tables[csvOfTalent]=H.csv('talent');for _,r in pairs(H.tables[csvOfTalent])do r.preId=split(r.preId or '0',';')end
H.tables[csvOftask]=H.csv('task');matrix(H.tables[csvOftask],{'complete','reward','killItems'})
local dataSource=read('bin/res/scripts/LuaClass/DataManager.lua')
for _,spec in ipairs({{'checkTallentPass','checkTallentPass',''}, {'unlockTallentByKey','getLockedTallent',''}})do
 local first=assert(dataSource:find('function DataManager:'..spec[1]..'(',1,true))
 local last=spec[1]=='checkTallentPass' and assert(dataSource:find('\nfunction ',first+1,true)) or assert(dataSource:find('function DataManager:'..spec[2]..'(',first+1,true))
 assert(loadstring(dataSource:sub(first,last-1),'@actual-'..spec[1]))();dm[spec[1]]=DataManager[spec[1]]
end
local effects={};dm.sendSystemInfo=function(_,text)effects[#effects+1]='info:'..text end
dm.handleTallentItemAddition=function(_,value)effects[#effects+1]='talent:'..value.ID end
dm.unlockAchievement=function()effects[#effects+1]='achievement'end
GuideController:getInstance().removeStep=function()effects[#effects+1]='guide'end
local locked;dm.__dynamicData={getLockedTallent=function()return locked end}
dm.getPackNumWithId=function()return 0 end
-- Execute the exact old-save return callback and complete returnToBase method;
-- only the surrounding HUD construction and native world teardown are fixtures.
Explore={};local exploreSource=read('bin/res/scripts/LuaClass/Explore.lua')
local fn=assert(exploreSource:match('(function Explore:returnToBase%(%s*statue.-)\nend'))..'\nend'
assert(loadstring("local AdventureProgress=require 'LuaClass/AdventureProgress'\n"..fn))()
local snippet=assert(exploreSource:match('(local backBtn = button%("返航".-)\n    self.adventureReturnButton'))
local bind=assert(loadstring("local AdventureProgress=require 'LuaClass/AdventureProgress'\nreturn function(self,button) "..snippet..' end'))()
local function item(root,label)
 local found;H.visit(root,function(n)if n.getString and n:getString()==label then local p=n:getParent();if p and p.activate then found=p end end end);return assert(found,'button '..label)
end
local function new(kind,balance)
 local scene,d=F.fresh(480,800);d[roleDiamond]=balance or 0;isEnterMap=true;effects={};d[roleRandomEvents]={};d[roleMission]={};d[roleTalent]={}
 local manager=MissionManagers:getInstance();manager:init();local random=RandomEventManager:getInstance();random.eventList={}
 local owner,trigger,target
 if kind=='return'then
  d.adventureProgressV1=nil;d[roleMapInfo]={curIndex=2,fristReturnBaseByTool='1'}
  owner=cc.Layer:create();owner:retain();scene:addChild(owner);owner.mapIndex=2
  owner.mapLayoutManagers={returnBaseTool='1303',returnBaseNum=1,checkReturnBase=function()return false end}
  dataController={getResourceValueByIdAndKey=function(id,key)return H.tables[csvOfResourceInfo][id][key]end}
  owner.moveLayer=cc.Node:create();owner:addChild(owner.moveLayer)
  owner.bagController={safeClearMissionData=function()effects[#effects+1]='clear-missions'end,safeTransformCoinToPack=function()effects[#effects+1]='cargo'end,destoryController=function()effects[#effects+1]='destroy-bag'end}
  owner.clearMapInfoData=function()effects[#effects+1]='clear-map'end;owner.getbackObjectStr=function()return 'fixture cargo'end
  owner.returnToBase=Explore.returnToBase;dm.mixPackAndSoildier=function()effects[#effects+1]='mix'end
  FightDataManager={getInstance=function()return{clearAllData=function()effects[#effects+1]='clear-fight'end}end}
  EternalArenaController={getInstance=function()return{destoryEternalArenaController=function()effects[#effects+1]='clear-arena'end}end}
  clearAllTouchArgs=function()end;gotoMainUI=function()effects[#effects+1]='home'end
  local click;bind(owner,function(_,a,b,c,d,cb)click=cb;return{}end)
  trigger=function()click();local alert;for _,child in ipairs(scene:getChildren())do if child.title=='返 航'then alert=child end end;assert(alert,'original return alert');item(alert,'确 定'):activate()end
  target={price=tonumber(H.tables[csvOfShopItem][H.tables[csvOfResourceInfo]['1303'].shop_connect].price)}
 else
  if kind=='talent'then
   target=RandomEvent:create(3,1,'2002',os.time(),3600,'学习航海天赋');random.eventList={target};locked={['2002']=H.tables[csvOfTalent]['2002']}
   assert(locked['2002'].resumeType=='2' and tonumber(locked['2002'].resumeNum)==3,'shipped three-diamond talent')
  else
   target=assert(Mission:createMissionByMissionID('1'));target:begain();manager.waitingMissions[target.id]=target;manager.missions[target.id]=target;manager.datas[target.id]=target:getSaveData()
  end
  RandomEventLayer.instance=setmetatable({},{__index=RandomEventLayer})
  owner=assert(RandomEventView:create());owner:retain();owner:show()
  trigger=function()item(owner,kind=='talent'and'钻石学习'or'一键完成'):activate()end
 end
 T.enter(scene)
 return {scene=scene,data=d,owner=owner,trigger=trigger,target=target,manager=manager,random=random,effects=effects}
end
return {F=F,H=H,dm=dm,T=T,new=new,item=item,read=read}
