-- Real EventLayer methods and GuideController step logic; real persisted ledger.
-- Only engine nodes and downstream controller notifications are observation doubles.
local f=assert(io.open('tools/tests/adventure_state_audit.lua'));local h=f:read('*a');f:close();h=assert(h:match('^(.-)\nfixture%(%{%[roleGuideStep%]'))
local E=assert(loadstring(h..'\nreturn {A=A,dm=dm,fixture=fixture}'))();local A,dm=E.A,E.dm
function dm:setRoleData(k,v)self.__roleData:setRoleData(k,v);self.__roleData:saveData()end
DataManager={getInstance=function()return dm end};roleTranslateDoor='chapterLimit'
local function methods(path,class,names,prefix)
 local f=assert(io.open(path));local s=f:read('*a');f:close()
 for _,name in ipairs(names)do local fn=assert(s:match('(function '..class..':'..name..'%([^\n]*.-)\nend'),name)..'\nend';assert(loadstring((prefix or '')..'\n'..fn))()end
end
GuideController={step='',getInstance=function(self)return self end}
methods('bin/res/scripts/LuaClass/GuideController.lua','GuideController',{'fixStep','getIsHaveStep','addStep'})
EventLayer={};local function node()return {setString=function()end,setPosition=function()end,setOwner=function()end,setVisible=function()end,setDimensions=function()end,setHorizontalAlignment=function()end,setVerticalAlignment=function()end,getPosition=function()return 0,0 end,getParent=function(self)return self end,addChild=function()end,registerSingleCLick=function(self,f)self.callback=f end}end
local scene=node();cc={p=function(x,y)return {x=x,y=y}end,size=function(w,h)return {width=w,height=h}end,Director={getInstance=function()return {getVisibleSize=function()return {width=640,height=960}end,getRunningScene=function()return scene end}end}}
local worldCreated=0;WorldMapLayer={create=function()worldCreated=worldCreated+1;return node()end}
_G.auditEventLabel=node
methods('bin/res/scripts/LuaClass/EventLayer.lua','EventLayer',{'changeToMaterialsLayer','changeToTeleportLayer','leaveToExploreMap','enterNextLayer','enterTeleport','enterNextMapEnter'},"local AdventureProgress=require 'LuaClass/AdventureProgress';local eventLabel=auditEventLabel")
-- Keep the actual entry-cost predicate in the path; no unlocking/step predicates are replaced.
EventManger={};methods('bin/res/scripts/LuaClass/EventManger.lua','EventManger',{'checkEnterNext'})
local completed,abandoned,triggered,chapter=0,0,0,nil
local owner={mapIndex=1,mapGuideComponent=nil,initMapByMapIndex=function(_,index)chapter=index end}
getExplor=function()return owner end
local controller=setmetatable({owner=owner,allEventsHasTriggered=function()completed=completed+1 end,anEventHasToGiveUp=function()abandoned=abandoned+1 end,anEventHasTriggered=function()triggered=triggered+1 end},{__index=EventManger})
local layer=setmetatable({controller=controller,buttons={node()},buttonTips={node()},description=node()},{__index=EventLayer})
E.fixture({[roleMapInfo]={mapIndex=1,curIndex=1},[roleTranslateDoor]=3});GuideController.step='s001_s002_s008'
layer:changeToMaterialsLayer({},false);layer.buttons[1].callback();assert(triggered==1 and owner.mapGuideComponent==nil)
layer:leaveToExploreMap();layer:leaveToExploreMap(true);assert(completed==1 and abandoned==1)
layer:changeToTeleportLayer({});assert(not GuideController:getIsHaveStep(71),'new game must not forge tutorial completion')
assert(layer:enterNextMapEnter(false,2,true));assert(not layer:enterNextMapEnter(false,4,true),'existing paid chapter boundary remains')
assert(layer:enterNextMapEnter(false,2,false));assert(chapter==2)
dm:setRoleData(roleMapInfo,{mapIndex=2,curIndex=2});layer:changeToTeleportLayer({});layer.buttons[1].callback();assert(worldCreated==1)
print('PASS real new-game material open/occupy callback, leave/give-up, teleport and chapter entry with nil tutorial component and no forged step71')
-- Existing profiles retain their incomplete tutorial behavior and learn 71 only via old UI.
dm:setRoleData(A.KEY,nil);GuideController.step='s001';local hidden,finger=0,0
owner.mapGuideComponent={hideAllComponents=function()hidden=hidden+1 end,changeFingerParent=function()finger=finger+1 end,showFingerActionByPosition=function()finger=finger+1 end}
local before=completed;layer:leaveToExploreMap();assert(completed==before)
layer:changeToMaterialsLayer({},false);assert(finger==2);layer.buttons[1].callback();assert(hidden==1 and GuideController:getIsHaveStep(71))
GuideController.step='s001';dm:setRoleData(roleMapInfo,{mapIndex=1});layer:changeToTeleportLayer({});assert(hidden==2 and GuideController:getIsHaveStep(71))
print('PASS legacy incomplete step71 still blocks leave and retains actual material/teleport teaching transitions')
