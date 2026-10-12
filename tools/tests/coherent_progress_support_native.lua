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
local csvBefore=H.serialize(H.tables)
local talentIds={};for id in pairs(H.tables[csvOfTalent])do talentIds[#talentIds+1]=id end;table.sort(talentIds)
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 local w,h=size[1],size[2]
 for _,mode in ipairs({'empty','sparse','full'})do
  local scene,d=fresh(w,h)
  if mode=='sparse'then d[roleTalent]={['2']=talentIds[1],['8']=talentIds[2]}
  elseif mode=='full'then for i,id in ipairs(talentIds)do d[roleTalent][tostring(i)]=id end end
  local before=H.serialize(d);local v=assert(TalentLayer:create());v:retain();scene:addChild(v)
  inspect(v,w,h);capture(v,w,h,'talent-'..mode);equal(listeners(),5,'Talent five native subscriptions');equal(H.serialize(d),before,'Talent opening is read-only')
  equal(v.alertLabel:isVisible(),mode=='empty','honest empty Talent')
  if mode=='sparse'then equal(v.talentEntries[1].index,8,'original reverse-earned ordering')end
  local originalNormal=v.setBtn.normalSpr;local originalListener=v.setBtn.listener
  local count=#v.talentEntries;for _=1,3 do v:loadTalentData()end;equal(#v.talentEntries,count,'repeat render entries')
  check(originalNormal==v.setBtn.normalSpr and originalListener==v.setBtn.listener,'original alchemy sprite and listener preserved')
  if mode=='full'then
   v.scrollView:setContentOffset(cc.p(0,-100));v:loadTalentData();equal(v.scrollView:getContentOffset().y,-100,'same-size refresh keeps scroll position')
  end
  d[roleMoney]=6543;event(roleMoney);equal(v.talentCoin:getString(),'金币 6543','live currency native event')
  d[roleTalent]={['3']=talentIds[1]};event(roleTalent);equal(#v.talentEntries,1,'live earned list')
  local n=intelligence;d[roleMapInfo]=nil;event(roleMapInfo);v.talentIntelligence.item:activate();equal(intelligence,n,'map-less intelligence gate')
  d[roleMapInfo]={curIndex=2};isEnterMap=true;v.talentIntelligence.item:activate();equal(intelligence,n,'at-sea intelligence gate')
  isEnterMap=false;v.talentIntelligence.item:activate();equal(intelligence,n+1,'original intelligence route')
  n=alchemy;v.setBtn.onSingleCLick();v.setBtn.onSingleCLick();step(scene,.01);equal(alchemy,n+1,'original cooldown coalesces repeated taps')
  check(not v.bIsCenterBtnCanClick,'alchemy native cooldown active');step(scene,zqAlchemyTime+.1);check(v.bIsCenterBtnCanClick,'native cooldown reopens controller')
  local held=touch(v.setBtn);check(v.setBtn:onTouchBegan(held),'original stationary alchemy hold touch')
  v.setBtn:updatelongprogress();step(scene,.01);equal(alchemy,n+2,'original entitled long-press callback')
  v.setBtn:onTouchEnded(held);local stopped=alchemy;step(scene,zqAlchemyTime+.3);equal(alchemy,stopped,'hold release stops original repeating scheduler')
  local stale=v.setBtn;stale:retain();local b=backs;v.coherentShell.back.item:activate();v.coherentShell.back.item:activate();equal(backs,b+1,'Back is guarded')
  close(v);equal(listeners(),0,'Talent unregister removes native handles and owned aliases')
  aliasesEmpty();n=alchemy;stale.onSingleCLick();step(scene,1);equal(alchemy,n,'disposed Talent callback cannot grant');stale:release()
  H.finish()
 end
 for _,mode in ipairs({'empty','full','max'})do
  local scene,d=fresh(w,h)
  if mode~='empty'then for id,record in pairs(H.tables[csvOfAchievement])do d[roleAchievement][id]=mode=='max'and 1 or 0 end end
  d[roleAchievementPoint]=mode=='max'and 999999999 or 10
  for i=1,20 do d[roleStorageInfo][i]=mode=='max'and 999999999 or 17 end
  if mode=='max'then locked={}end
  local before=H.serialize(d);local v=assert(AchievementLayer:create());v:retain();scene:addChild(v)
  inspect(v,w,h);capture(v,w,h,'achievement-'..mode);equal(listeners(),6,'Achievement native subscriptions');equal(H.serialize(d),before,'Achievement opening is read-only')
  check(v.achievementEmpty:isVisible()==(mode=='empty'),'honest achievement empty')
  if mode=='max'then equal(v.achievementNextThreshold,nil,'all point talents unlocked clears threshold')else check(v.achievementNextThreshold~=nil,'actual locked threshold')end
  if mode~='empty'then
   local row=v.achievementRows[1];local saved=v.scrollView:getContentOffset();local t=touch(row.button)
   check(row.button:onTouchBegan(t),'native scaled row hitbox');row.button:onTouchEnded(t)
   check(v.adventureDialog and v.adventureDialog.supportDescription,'achievement opens original details in scrollable sheet')
   equal(v.adventureDialog.supportDetailText,v:getAchievementInformation(H.tables[csvOfAchievement][row.id]),'all original informational detail text retained')
   equal(H.serialize(d),before,'detail click never claims reward');v.adventureDialog:close()
   local p=t:getLocation();local point=cc.p(p.x,p.y);local drag={getLocation=function()return point end}
   check(row.button:onTouchBegan(drag),'scroll gesture begins');point=cc.p(p.x,p.y+40);row.button:onTouchMoved(drag)
   v.scrollView:setContentOffset(cc.p(saved.x,saved.y+40));row.button:onTouchEnded(drag);check(not v.adventureDialog,'scroll gesture never opens detail')
   v.scrollView:setContentOffset(saved)
   for _,gesture in ipairs({'offset_only','release_outside','drag_return','cancel'})do
    local start=touch(row.button):getLocation();local point=cc.p(start.x,start.y);local input={getLocation=function()return point end}
    check(row.button:onTouchBegan(input),'row gesture '..gesture..' begins')
    if gesture=='offset_only'then v.scrollView:setContentOffset(cc.p(saved.x,saved.y+24))
    elseif gesture=='release_outside'then point=v.scrollView:convertToWorldSpace(cc.p(208,v.supportListHeight+12))
    elseif gesture=='drag_return'then point=cc.p(start.x,start.y+24);row.button:onTouchMoved(input);point=cc.p(start.x,start.y)
    else row.button:onTouchCancelled(input)end
    row.button:onTouchEnded(input);check(not v.adventureDialog,'row '..gesture..' cannot open details')
    equal(row.button.normalSpr:getNumberOfRunningActions(),0,'row '..gesture..' stops pending hold')
    v.scrollView:setContentOffset(saved)
   end
   local stale=row.button;stale:retain();event(roleStorageInfo);stale.onSingleCLick();check(not v.adventureDialog,'refresh invalidates stale row callback');stale:release()
   row=v.achievementRows[1];check(row.button:onTouchBegan(touch(row.button)),'next stationary tap works');row.button:onTouchEnded(touch(row.button));check(v.adventureDialog,'valid detail remains reachable');v.adventureDialog:close()
   v.scrollView:setContentOffset(cc.p(0,0));local clipped=v.achievementRows[1].button
   check(not clipped:onTouchBegan(touch(clipped)),'offscreen row cannot accept tap')
  end
  d[roleAchievementPoint]=123;event(roleAchievementPoint);equal(v.achievementPointsLabel:getString(),'成就点数 123','live point event')
  locked={};event(roleTalent);equal(v.achievementNextThreshold,nil,'live final unlock removes old threshold')
  local n=talent;unlocked=false;event(roleGuideStep);v.achievementTalent.item:activate();equal(talent,n,'Talent guide gate retained')
  unlocked=true;v.achievementTalent.item:activate();equal(talent,n+1,'original Talent entry reachable')
  local stepCount=#steps;close(v);equal(#steps,stepCount+1,'guide clear exactly once');equal(steps[#steps][1],402,'original achievement guide402');equal(steps[#steps][2],true,'redpoint guide flag')
  equal(listeners(),0,'Achievement unregister removes handles and aliases');aliasesEmpty();H.finish()
 end
 print('PASS coherent progress/support '..w..'x'..h..': empty/sparse/full/max, clean geometry, live native listeners, original actions/cooldowns, scrolling, gates, guide402 and read-only rendering')
end
-- Two pages can coexist without replacing each other's Talent subscriptions.
local scene,d=fresh(480,800);local a=TalentLayer:create();local b=AchievementLayer:create();a:retain();b:retain();scene:addChild(a);scene:addChild(b)
equal(listeners(),11,'coexisting pages own unique aliases');close(a);equal(listeners(),6,'closing Talent leaves Achievement subscribed')
d[roleTalent]={['1']=talentIds[1]};event(roleTalent);check(not b.achievementDisposed,'remaining page stays live');close(b);equal(listeners(),0,'coexisting page cleanup');H.finish()
-- No entitlement is invented; the controller still handles remaining cooldown.
scene,d=fresh(480,800);d[roleAlchemyCanLongPress]=0;BaseViewLastClickCDTime=os.time();local v=TalentLayer:create();v:retain();scene:addChild(v)
equal(v.setBtn.onLongPressed,nil,'unearned long-press stays unavailable');check(not v.bIsCenterBtnCanClick,'original reopen cooldown active');step(scene,.01);step(scene,zqAlchemyTime+.1);check(v.bIsCenterBtnCanClick,'remaining native cooldown finishes');close(v);H.finish()
-- Dispatch still owns clearing guide401 when opening Talent.
scene,d=fresh(480,800);local dispatchSource=read('bin/res/scripts/LuaClass/Dispatch.lua')
local first=assert(dispatchSource:find('function Dispatch:moveToTalent()',1,true))
local after=assert(dispatchSource:find('\nfunction Dispatch:',first+1,true))
Dispatch={};assert(loadstring(dispatchSource:sub(first,after-1),'@production-dispatch-talent'))()
local entered;local target={setViewWithDirection=function(_,view,animated,direction)entered=view;view:retain();scene:addChild(view);check(animated and direction==1,'original Talent dispatch direction')end}
local stepCount=#steps;Dispatch.moveToTalent(target);equal(#steps,stepCount+1,'original route clears guide401');equal(steps[#steps][1],401,'Talent guide401');close(entered);H.finish()
-- Full legacy geometry remains available with Warm explicitly disabled.
WARM_PIRATE_V1=false
scene,d=fresh(640,1067);d[roleTalent]={['1']=talentIds[1]};local legacy=TalentLayer:create();legacy:retain();scene:addChild(legacy)
check(not legacy.coherentShell and legacy.talentRoot,'Talent opt-out uses original illustrated page');close(legacy);aliasesEmpty();H.finish()
scene,d=fresh(640,1067);d[roleAchievement]={['1']=0};legacy=AchievementLayer:create();legacy:retain();scene:addChild(legacy)
check(not legacy.coherentShell and legacy.scrollView,'Achievement opt-out uses original grid');close(legacy);aliasesEmpty();H.finish()
WARM_PIRATE_V1=true
-- Unknown IDs retain an honest fallback, and unrelated subscribers survive.
scene,d=fresh(480,800);d[roleTalent]={['9']='999999'};d[roleMoney]=999999999;d[roleDiamond]=999999999
local foreignCalls=0;local foreign=function()foreignCalls=foreignCalls+1 end;dm:registerEvent(roleTalent,'foreignSupportTest',foreign)
v=TalentLayer:create();v:retain();scene:addChild(v);inspect(v,480,800);equal(v.talentEntries[1].id,'999999','unknown earned ID retained')
close(v);event(roleTalent);equal(foreignCalls,1,'closing page never removes unrelated observer')
dm:unregisterEvent(roleTalent,'foreignSupportTest');dm.__eventListener[roleTalent].foreignSupportTest=nil;aliasesEmpty();H.finish()
if coherentDescriptionDrag then
 -- Actual Cocos dispatcher delivery, including scene onEnter, scroll threshold,
 -- row SDButton listener and native ScrollView content motion. No GUI window.
 scene,d=fresh(480,800);for id in pairs(H.tables[csvOfAchievement])do d[roleAchievement][id]=0 end
 v=AchievementLayer:create();v:retain();scene:addChild(v)
 local path=(os.getenv('COHERENT_SUPPORT_CAPTURE_DIR')or'/tmp')..'/achievement-dispatched-scroll.png'
 check(coherentCapture(scene,480,800,path),'prepare native offscreen GL view')
 local visible,moved=coherentDescriptionDrag(v.scrollView)
 check(visible and moved,'real dispatched achievement scroll remains visible and moves')
 check(not v.adventureDialog,'real dispatched row drag never opens details')
 check(coherentCapture(scene,480,800,path),'capture after real native scroll')
 close(v);aliasesEmpty();H.finish()
end
equal(H.serialize(H.tables),csvBefore,'all packaged data unchanged')
cc.Director.getInstance=H.realGet
print('PASS progress/support native assertions '..assertions)
