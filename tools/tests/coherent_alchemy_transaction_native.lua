-- Production Cocos, BaseView/SDButton cooldowns, shipped CSVs and native
-- DataManager register/unregister/postEvent methods. No GUI or player profile.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,tables=tables,csv=csv,fixture=fixture,serialize=serialize,visit=visit,realGet=realGet,
getData=function()return data end,prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
finish=function()scene:cleanup();scene:release();scene=nil end}
]],'@progress-support-native-fixture'))()
local dm=H.dm;local director=H.realGet(cc.Director)
-- Execute the actual production listener functions, including its alias-retention
-- behavior. This deliberately does not use the fixture's listener substitutes.
local manager=read('bin/res/scripts/LuaClass/DataManager.lua')
local start=assert(manager:find('function DataManager:registerEvent',1,true))
local finish=assert(manager:find('function DataManager:getCSVByID',start,true))
assert(loadstring(manager:sub(start,finish-1),'@production-datamanager-listeners'))()
for _,key in ipairs({'registerEvent','unregisterEvent','postEvent'})do dm[key]=DataManager[key]end
dm.__eventListener={};dm.__eventDispatcher=cc.Node:create():getEventDispatcher()
local function event(key)dm:postEvent(key)end
local function listeners()local n=0;for _,bucket in pairs(dm.__eventListener)do for _,value in pairs(bucket)do if type(value)=='function'then n=n+1 end end end;return n end
local function aliasesEmpty()for _,bucket in pairs(dm.__eventListener)do assert(next(bucket)==nil,'no native handle or closure alias retained')end end
UITopHeight=100;UIBottomHeight=136;WriteColor=cc.c3b(255,255,255);BaseColor=cc.c3b(38,65,68)
package.loaded['LuaClass/NotificationNode']=true;NotificationNode={getInstance=function()return{GetGameTime=function()return 10000 end}end}
package.loaded['LuaClass/MissionManagers']=true;MissionManagers={getInstance=function()return{getWaitingMissions=function()return{len=0}end}end}
RandomEventManager={getInstance=function()return{eventList={}}end}
local guide=GuideController:getInstance();local steps={};local unlocked=true
local locked={};dm.getLockedTallent=function()return locked end
guide.getIsHaveStep=function()return unlocked end;guide.addRedPoint=function()end;guide.removeRedPoint=function()end
guide.addStep=function(_,step,red)steps[#steps+1]={step,red}end
dm.isShowDiamondStoreRedPointer=function()return false end;dm.checkDiamondStoreNewGoods=function()return false end;dm.getSound_off=function()return 1 end
local alchemy,backs,intelligence,talent,toasts=0,0,0,0,0
dm.AlchemyButtonDidClick=function()alchemy=alchemy+1 end
ToastUtil.downString=function()toasts=toasts+1 end
zqDispatch={backToLastView=function()backs=backs+1 end,moveToTalent=function()talent=talent+1 end,moveToExpedition=function()end}
H.tables[csvOfTalent]=H.csv('talent');H.tables[csvOfAchievement]=H.csv('achievement')
require 'LuaClass/Talent';require 'LuaClass/Achievement'
RandomEventView={create=function()intelligence=intelligence+1;return{show=function()end}end}
local W=require 'LuaClass/WarmTheme'
local function capture(view,w,h,name)
 if coherentCapture and os.getenv('COHERENT_SUPPORT_CAPTURE_DIR') then assert(coherentCapture(view,w,h,os.getenv('COHERENT_SUPPORT_CAPTURE_DIR')..'/'..name..'-'..w..'x'..h..'.png'))end
end
local assertions=0
local function check(value,why)assertions=assertions+1;assert(value,why)end
local function equal(a,b,why)check(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function bounds(node,w,h,why)
 local s=node.getViewSize and node:getViewSize()or node:getContentSize();local a=node:convertToWorldSpace(cc.p(0,0));local b=node:convertToWorldSpace(cc.p(s.width,s.height))
 check(a.x>=-1 and a.y>=-1 and b.x<=w+1 and b.y<=h+1,why..' '..a.x..','..a.y..' '..b.x..','..b.y)
end
local function inspect(v,w,h)
 check(v.approvedPage and not v.keepNavigation,'single-page navigation opt-in');check(not v.supportLegacy:isVisible(),'legacy geometry hidden')
 bounds(v.coherentShell.back,w,h,'Back bounds');bounds(v.setBtn,w,h,'alchemy bounds');bounds(v.scrollView,w,h,'list bounds')
 local backCount=0
 H.visit(v.coherentShell.canvas,function(n,visible)
  if visible and n.getString then
   local inScroll=false;local p=n:getParent();while p do if p==v.scrollView then inScroll=true end;p=p:getParent()end
   if not inScroll then bounds(n,w,h,'label bounds '..n:getString())end
   if n.getFontName and n:getString()=='返回'then backCount=backCount+1 end
   if n.getFontName then equal(n:getFontName(),W.font,'clean font')end
   if n.getFontSize then check(n:getFontSize()*n:getScaleX()>=15,'readable label '..n:getString())end
  end
 end)
 equal(backCount,1,'exactly one visible Back')
end
local function fresh(w,h)
 H.fixture();local scene=H.prepare(w,h);local d=H.getData()
 d[roleAlchemyCanLongPress]=1;d[roleAlchemyUnit]=3;d[roleTalent]={};d[roleAchievement]={};d[roleAchievementPoint]=0;d[roleStorageInfo]={}
 d[roleMapInfo]={curIndex=6};d[roleDiamond]=123;d[roleMoney]=9876
 locked={};for id,v in pairs(H.tables[csvOfTalent])do locked[id]=v end
 BaseViewLastClickCDTime=0;isEnterMap=false;unlocked=true
 return scene,d
end
local function close(view)
 view:destory();view:destory();view:removeFromParent(true);view:release()
end
local function step(scene,dt)
 H.visit(scene,function(n)director:getActionManager():resumeTarget(n)end);director:getActionManager():update(dt)
end
getSystemTimeMilliSecond=function()return 10000 end
local function touch(button)
 local z=button:getContentSize();local p=button:convertToWorldSpace(cc.p(z.width/2,z.height/2));return{getLocation=function()return p end}
end

local src=read('bin/res/scripts/LuaClass/DataManager.lua')
for _,name in ipairs({'AlchemyButtonDidClick','addCoin','getAchievementInfo','setAchievementInfo'})do
 local first=assert(src:find('function DataManager:'..name..'(',1,true));local last=assert(src:find('\nfunction DataManager:',first+1,true));assert(loadstring(src:sub(first,last-1)))();dm[name]=DataManager[name]
end
local writes,awards=0,0
dm.setRoleData=function(_,key,value)writes=writes+1;H.getData()[key]=value;event(key)end
dm.unlockAchievement=function()awards=awards+1 end
local function visible(node)while node do if not node:isVisible()then return false end;node=node:getParent()end;return true end
local function receipt(v)local found;for _,n in ipairs(v.alchemyReceiptHost:getChildren())do if n.isAlchemyToast then found=n end end;return assert(found)end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 for _,class in ipairs({TalentLayer,AchievementLayer})do
  local scene,d=fresh(size[1],size[2]);d[roleStorageInfo][achievement_Alchemy]=0
  local v=class:create();v:retain();scene:addChild(v);pNeedUpdateLayer=v;dofile('bin/res/scripts/LuaClass/ToastUtil.lua')
  local before=d[roleMoney];local n=awards;v.setBtn.onSingleCLick();v.setBtn.onSingleCLick();step(scene,.01);step(scene,.01)
  equal(d[roleMoney],before+3,'original real addCoin exactly once');equal(d[roleStorageInfo][achievement_Alchemy],1,'original achievement counter exactly once');equal(awards,n+1,'original automatic award hook exactly once')
  local r=receipt(v);check(visible(r),'receipt effective native visibility');bounds(r.alchemyBackdrop,size[1],size[2],'real action receipt viewport bounds');equal(r.alchemyAmount,3,'original grant receipt exact')
  step(scene,2);check(not r:isVisible(),'idle action expires receipt');equal(r.alchemyAmount,0,'idle resets accumulated receipt')
  local money=d[roleMoney];v.adventureDialog={close=function()end};v.setBtn.onSingleCLick();step(scene,.1);equal(d[roleMoney],money,'open modal blocks action');v.adventureDialog=nil
  v.setBtn.onSingleCLick();r:retain();close(v);step(scene,1);equal(d[roleMoney],money,'dispose cancels deferred original transaction');check(not r:isVisible() and r.alchemyAmount==0,'native receipt cleanup clears pending state');r:release();H.finish()
 end
end
print('PASS independent actual AlchemyButtonDidClick/addCoin/achievement methods with real native page buttons, exact grants, receipt bounds, expiration, modal and disposal at five sizes')
