-- Actual native Cocos nodes, shipped CSVs, original cooldown actions and SDButton
-- callbacks. In-memory state spies only: no profile/save or GUI changes.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,tables=tables,csv=csv,fixture=fixture,event=event,serialize=serialize,visit=visit,realGet=realGet,
getData=function()return data end,countEvents=countEvents,
prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
finish=function()scene:cleanup();scene:release();scene=nil end}
]],'@supply-native-fixture'))()
UITopHeight=100;UIBottomHeight=136;WriteColor=cc.c3b(255,255,255);BaseColor=cc.c3b(38,65,68)
local dm=H.dm;local guide=GuideController:getInstance();local guideSteps={};local locked=false
local now=10000;local originalTime=os.time;os.time=function()return now end
package.loaded['LuaClass/NotificationNode']=true
NotificationNode={getInstance=function()return{GetGameTime=function()return now end}end}
package.loaded['LuaClass/MissionManagers']=true
MissionManagers={getInstance=function()return{getWaitingMissions=function()return{len=0}end}end}
RandomEventManager={getInstance=function()return{eventList={}}end}
guide.addRedPoint=function()end;guide.removeRedPoint=function()end
guide.getIsHaveStep=function(_,step)return not locked end
guide.addStep=function(_,step)guideSteps[#guideSteps+1]=step end
dm.isShowDiamondStoreRedPointer=function()return false end;dm.checkDiamondStoreNewGoods=function()return false end
dm.getSound_off=function()return 1 end
local writes,coins,alchemy,achievements,unlocks,toast=0,0,0,0,0,0
local changes={}
dm.setRoleData=function(_,key,value)assert(key==roleProducerQueue or key==roleAlchemyCanLongPress);H.getData()[key]=value;writes=writes+1;H.event(key)end
dm.addPackItemWithId=function(_,id,delta)
 local pack=H.getData()[rolePack];if (pack[id]or 0)+delta<0 then return false end
 pack[id]=(pack[id]or 0)+delta;changes[#changes+1]={id,delta};H.event(rolePack);return true
end
dm.addCoin=function(_,amount)coins=coins+amount end
dm.AlchemyButtonDidClick=function()alchemy=alchemy+1 end
dm.getAchievementInfo=function()return achievements end
dm.setAchievementInfo=function(_,key,value)assert(key==achievement_Collect);achievements=value end
dm.createSuccessCheck=function(_,kind,id)assert(kind==kUnlockBuild and id=='1');unlocks=unlocks+1 end
dm.sendSystemInfo=function()end
ToastUtil.downString=function()toast=toast+1 end
H.tables[csvOfWorker]=H.csv('worker')
for _,record in pairs(H.tables[csvOfWorker])do
 for _,key in ipairs({'produce','resume'})do
  local parts={};for part in tostring(record[key]or''):gmatch('[^;]+')do local id,n=part:match('^([^_]+)_([^_]+)$');if id then parts[#parts+1]={id,n}end end;record[key]=parts
 end
end
require 'LuaClass/Resource';require 'LuaClass/Repository'
-- Reload hashing is not the target here; the exact original key-based reload
-- still owns subscription refresh and is exercised with a deterministic hash.
json={encode=H.serialize};MD5=function(s)return{hexdigest=function()return s end}end
local W=require 'LuaClass/WarmTheme';local director=H.realGet(cc.Director)
local activeScene
local function nativeEnter(scene)activeScene=scene end
local function nativeExit()activeScene=nil end
local function step(dt)
 if activeScene then H.visit(activeScene,function(node)director:getActionManager():resumeTarget(node)end)end
 director:getActionManager():update(dt)
end
local assertions=0
local function check(ok,why)assertions=assertions+1;assert(ok,why)end
local function equal(a,b,why)check(a==b,why..' ['..tostring(a)..' ~= '..tostring(b)..']')end
local function fresh(w,h)
 H.fixture();local scene=H.prepare(w,h);local d=H.getData()
 d[roleAlchemyCanLongPress]=1;d[roleAlchemyUnit]=3;d[roleGatherUnit]=10;d[roleResourceCD]=30;d[roleProduceTime]=now+30;d[roleLivingUnitNum]=12
 d[roleProducerQueue]={{[dataKeyID]='1',[dataKeyNum]=2},{[dataKeyID]='2',[dataKeyNum]=1},{[dataKeyID]='3',[dataKeyNum]=0}}
 d[rolePack]={['1006']=35,['1007']=2,['1008']=10};BaseViewLastClickCDTime=0;locked=false
 return scene,d
end
local function close(view)
 view:destory();view:removeFromParent(true);view:release();equal(H.countEvents(),0,'all page observers removed')
end
local function bounds(node,w,h,why)
 local z=node:getContentSize();local a=node:convertToWorldSpace(cc.p(0,0));local b=node:convertToWorldSpace(cc.p(z.width,z.height))
 check(a.x>=-1 and b.x<=w+1 and a.y>=-1 and b.y<=h+1,why)
end
local function inspect(view,w,h)
 check(view.approvedPage and not view.keepNavigation,'coherent page owns navigation')
 check(not view.supplyLegacy:isVisible(),'legacy competing dashboard hidden')
 check(not view.setBtn.listener:isSwallowTouches(),'action keeps non-swallowing touch');bounds(view.setBtn,w,h,'action bounds');bounds(view.scrollView,w,h,'scroll bounds');bounds(view.coherentShell.back,w,h,'Back bounds')
 H.visit(view.coherentShell.canvas,function(node,visible)
  if visible and node.getString then
   local inScroll=false;local p=node:getParent()
   while p do if p==view.scrollView or p==view.resourceScrollView then inScroll=true end;p=p:getParent()end
   if not inScroll then bounds(node,w,h,'label bounds '..node:getString())end
   if node.getFontName then equal(node:getFontName(),W.font,'coherent font')end
  end
 end)
end
local function touch(button)
 local size=button:getContentSize();local point=button:convertToWorldSpace(cc.p(size.width/2,size.height/2))
 return {getLocation=function()return point end}
end
getSystemTimeMilliSecond=function()return 5000 end
-- Reproduce real non-swallowing touch delivery while the ScrollView moves
-- its row beneath the finger. The legacy listener could commit despite moved.
local function checkScrollGesture(view,button,scene,data,why)
 for _,mode in ipairs({'move_and_scroll','drag_before_hold','offset_before_hold','release_outside_clip','drag_return','touch_cancel'})do
  local originalOffset=view.scrollView:getContentOffset()
  local start=touch(button):getLocation();local point=cc.p(start.x,start.y)
  local t={getLocation=function()return point end}
  local before=H.serialize(data);local writeCount=writes;local gold=coins
  check(button:onTouchBegan(t),why..' '..mode..' begin')
  if mode=='move_and_scroll' or mode=='drag_before_hold' or mode=='drag_return'then
   point=cc.p(start.x,start.y+36);button:onTouchMoved(t)
  end
  if mode=='move_and_scroll' or mode=='offset_before_hold'then
   view.scrollView:setContentOffset(cc.p(originalOffset.x,originalOffset.y+36))
  end
  if mode=='release_outside_clip'then
   local size=view.scrollView:getViewSize()
   point=view.scrollView:convertToWorldSpace(cc.p(size.width/2,size.height+12))
  elseif mode=='drag_return'then point=cc.p(start.x,start.y)
  elseif mode=='touch_cancel'then button:onTouchCancelled(t)end
  if mode=='drag_before_hold' or mode=='offset_before_hold' or mode=='touch_cancel'then
   button:updatelongprogress()
   equal(button.normalSpr:getNumberOfRunningActions(),0,why..' '..mode..' cancels hold scheduler')
   nativeEnter(scene);step(.01);step(.8);step(.2);nativeExit()
   equal(H.serialize(data),before,why..' '..mode..' no held transaction')
   check(not view.adventureDialog,why..' '..mode..' no held sheet')
  end
  button:onTouchEnded(t)
  equal(H.serialize(data),before,why..' '..mode..' no release transaction')
  equal(writes,writeCount,why..' '..mode..' no persisted allocation')
  equal(coins,gold,why..' '..mode..' no sale proceeds')
  check(not view.adventureDialog,why..' '..mode..' no release sheet')
  check(not button.isTouch and not button.selectSpr:isVisible(),why..' '..mode..' clears pressed state')
  equal(button.normalSpr:getNumberOfRunningActions(),0,why..' '..mode..' no deferred hold')
  view.scrollView:setContentOffset(originalOffset)
 end
end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1136},{720,1280}})do
 local w,h=size[1],size[2];local scene,d=fresh(w,h)
 local before=H.serialize(d);local view=assert(ResourceLayer:create());view:retain();scene:addChild(view)
 inspect(view,w,h);equal(H.serialize(d),before,'opening resource is read-only')
 if coherentCapture and os.getenv('COHERENT_WORKYARD_CAPTURE_DIR') then assert(coherentCapture(view,w,h,os.getenv('COHERENT_WORKYARD_CAPTURE_DIR')..'/resource-'..w..'x'..h..'.png')) end
 check(view.supplyWorkyard and view.supplyWorkyard:isVisible(),'compact net production shows contextual workyard')
 check(view.supplyScrollHint:getString():find('滑动',1,true),'overflow worker list advertises scrolling')
 equal(view.workerUseNum,3,'real worker allocations')
 local pair=view.supplyWorkerButtons[1];check(not pair.add.listener:isSwallowTouches()and not pair.sub.listener:isSwallowTouches(),'worker presses do not swallow list touches');local n=writes;local t=touch(pair.add)
 check(pair.add:onTouchBegan(t),'scaled worker touch accepted');pair.add:onTouchEnded(t)
 equal(d[roleProducerQueue][1][dataKeyNum],3,'single tap allocates one');equal(writes,n+1,'one persisted queue write')
 check(pair.add:onTouchBegan(t),'held worker touch accepted');pair.add:updatelongprogress();pair.add:onTouchEnded(t)
 equal(d[roleProducerQueue][1][dataKeyNum],4,'hold allocates exactly once on first repeat');equal(writes,n+2,'repeat persists original queue')
 pair.sub.onSingleCLick();equal(d[roleProducerQueue][1][dataKeyNum],3,'minus original allocation')
 pair.info.onSingleCLick();check(view.adventureDialog and view.adventureDialog.supplyDescription,'worker info scrolls full original description');view.adventureDialog:close()
 local clipped=view.supplyWorkerButtons[3].add;check(not clipped:onTouchBegan(touch(clipped)),'clipped worker cannot accept input')
 checkScrollGesture(view,pair.add,scene,d,'worker plus drag')
 checkScrollGesture(view,pair.sub,scene,d,'worker minus drag')
 checkScrollGesture(view,pair.info,scene,d,'worker information drag')
 -- A new stationary gesture after cancellation keeps both original hold ticks.
 local allocation=d[roleProducerQueue][1][dataKeyNum];t=touch(pair.add)
 check(pair.add:onTouchBegan(t),'stationary hold accepted after drag cancellation')
 pair.add:updatelongprogress();equal(d[roleProducerQueue][1][dataKeyNum],allocation+1,'first stationary repeat after drag')
 nativeEnter(scene);step(.01);step(.12)
 equal(d[roleProducerQueue][1][dataKeyNum],allocation+2,'scheduled stationary repeat after drag')
 pair.add:onTouchEnded(t);local stopped=d[roleProducerQueue][1][dataKeyNum];step(.4)
 equal(d[roleProducerQueue][1][dataKeyNum],stopped,'stationary release stops repeat scheduler');nativeExit()
 -- Dragging after a valid first hold must stop the direct .1-second repeat.
 local p=touch(pair.sub):getLocation();local origin=cc.p(p.x,p.y);local held={getLocation=function()return p end}
 check(pair.sub:onTouchBegan(held),'hold then drag begin');pair.sub:updatelongprogress()
 stopped=d[roleProducerQueue][1][dataKeyNum];p=cc.p(origin.x,origin.y+36);pair.sub:onTouchMoved(held)
 equal(pair.sub.normalSpr:getNumberOfRunningActions(),0,'hold then drag removes active repeat scheduler')
 nativeEnter(scene);step(.01);step(.8);nativeExit();pair.sub:onTouchEnded(held)
 equal(d[roleProducerQueue][1][dataKeyNum],stopped,'hold then drag cannot allocate on repeat or release')
 -- Real action manager, with original legacy progressSetBtn/dealclick/openclick.
 nativeEnter(scene)
 local delta=#changes;local a=achievements;local savedRandom=math.random
 local sequence={100,20,99,20};local r=0;math.random=function(limit)r=r+1;return sequence[r]end
 locked=true;view.setBtn.onSingleCLick();view.setBtn.onSingleCLick();step(.01);step(.01);math.random=savedRandom;locked=false
 equal(#changes,delta+2,'one gather grants exactly two items');equal(changes[delta+1][1],'1006','stone reward ID');equal(changes[delta+1][2],10,'exact original stone random formula');equal(changes[delta+2][1],'1007','wood reward ID');equal(changes[delta+2][2],12,'exact original wood random formula');equal(achievements,a+1,'gather achievement once')
 equal(guideSteps[#guideSteps-1],3,'gather guide step 3');equal(guideSteps[#guideSteps],300,'original unlock guide step 300');check(unlocks>0,'original construction check')
 check(not view.bIsCenterBtnCanClick,'real gather cooldown starts');equal(BaseViewLastClickCDTime,now,'same cooldown deadline source')
 now=now+12;H.event('kSystemBackToForward');equal(view.setButtonProgrees:getPercentage(),40,'foreground retains elapsed 12 of 30 seconds')
 step(.01);step(17);check(not view.bIsCenterBtnCanClick,'foreground does not prematurely unlock')
 step(1.1);check(view.bIsCenterBtnCanClick,'foreground finishes remaining 18 seconds')
 nativeExit(scene);close(view);H.finish()
 scene,d=fresh(w,h);d[rolePack]={['1008']=35,['1009']=2,['1010']=10};before=H.serialize(d);view=assert(RepositoryLayer:create());view:retain();scene:addChild(view)
 inspect(view,w,h);equal(H.serialize(d),before,'opening warehouse read-only');equal(#view.supplyInventoryRows,3,'all actual positive displayed inventory')
 local row=view.supplyInventoryRows[1];check(not row.button.listener:isSwallowTouches(),'inventory press does not swallow scroll');t=touch(row.button)
 check(row.button:onTouchBegan(t),'scaled warehouse row touch accepted');row.button:onTouchEnded(t)
 check(view.adventureDialog and view.adventureDialog.supplyDescription,'single tap shows original item info');view.adventureDialog:close()
 checkScrollGesture(view,row.button,scene,d,'warehouse row drag')
 t=touch(row.button)
 local stock=d[rolePack][row.id];local price=tonumber(H.tables[csvOfResourceInfo][row.id].worth);local gold=coins
 check(row.button:onTouchBegan(t),'warehouse hold accepted');row.button:updatelongprogress();row.button:onTouchEnded(t)
 local modal=view.adventureDialog;check(modal and #modal.warmOptions==4,'hold offers 1 / 10 / all / cancel')
 local item=modal.warmOptions[1].item;item:retain();item:activate();item:activate();item:release()
 equal(d[rolePack][row.id],stock-1,'sell one exactly once');equal(coins,gold+price,'sell one proceeds exact')
 view.supplyInventoryRows[1].button.onLongPressedActiveOnce();view.adventureDialog.warmOptions[2].item:activate()
 equal(d[rolePack][row.id],stock-11,'sell ten exact');equal(coins,gold+price*11,'sell ten proceeds exact')
 view.supplyInventoryRows[1].button.onLongPressedActiveOnce();view.adventureDialog.warmOptions[3].item:activate()
 equal(d[rolePack][row.id],0,'sell all exact');equal(coins,gold+price*stock,'sell all proceeds exact')
 view:initBagDataWithType('2');H.event(rolePack);equal(view.lastSortType,'2','live stock refresh retains category')
 view:initBagDataWithType('1');equal(#view.supplyInventoryRows,0,'empty category is honest');inspect(view,w,h)
 local calls=alchemy;nativeEnter(scene);view.setBtn.onSingleCLick();view.setBtn.onSingleCLick();step(.01);equal(alchemy,calls+1,'alchemy exact original callback guarded by real cooldown')
 step(.4);view.setBtn.onLongPressed();step(.01);equal(alchemy,calls+2,'unlocked alchemy hold callback remains live')
 nativeExit(scene);close(view);H.finish()
 print('PASS coherent supply native '..w..'x'..h..': scaled SDButton/clip, original worker/gather/alchemy/sale callbacks, cooldown/foreground, guides and cleanup')
end
-- Full shipped catalog, category counts, live stock, offset retention, stale
-- actions, unsellable stock, empty gathering and the untouched legacy opt-out.
local scene,d=fresh(480,800)
d[rolePack]={};local expected={['0']=0,['1']=0,['2']=0,['3']=0,['4']=0}
for id,csv in pairs(H.tables[csvOfResourceInfo])do
 d[rolePack][id]=999999999
 if csv.display=='1'then expected['0']=expected['0']+1;expected[csv.type]=expected[csv.type]+1 end
end
local view=assert(RepositoryLayer:create());view:retain();scene:addChild(view)
for category,count in pairs(expected)do
 view:initBagDataWithType(category);equal(#view.supplyInventoryRows,count,'full shipped category '..category)
 for _,entry in ipairs(view.supplyInventoryRows)do
  H.visit(entry.row,function(node,visible)
   if visible and node.getFontSize then check(node:getFontSize()*node:getScaleX()>=16,'full stock text readability '..node:getString())end
  end)
 end
end
view:initBagDataWithType('2');view.scrollView:setContentOffset(cc.p(0,-120));local saved=view.scrollView:getContentOffset().y
local stale=view.supplyInventoryRows[1].button;stale:retain();d[rolePack]['1006']=777;H.event(rolePack)
equal(view.lastSortType,'2','late stock preserves category');equal(view.scrollView:getContentOffset().y,saved,'same-size stock refresh preserves scroll')
stale.onLongPressedActiveOnce();check(not view.adventureDialog,'stale row cannot open sale');stale:release()
view:openCoherentSale('1006','石头',nil,777);check(not view.adventureDialog,'unsellable original worth is respected')
view:openCoherentSale('1009','金',4,2);view.adventureDialog.warmOptions[2].item:activate();equal(d[rolePack]['1009'],999999997,'ten option uses original min(10, captured stock)')
local old=#changes;view:openCoherentSale('1008','铁',1,999999999);d[rolePack]['1008']=0;view.adventureDialog.warmOptions[3].item:activate();equal(#changes,old,'late insufficient stock cannot grant proceeds')
locked=true;H.event(roleGuideStep);check(not view.scrollView:isVisible()and view.supplyLocked:isVisible(),'original tutorial warehouse gate visible');equal(view.coherentShell.heading:getString(),'荒岛','original island guide title')
locked=false;H.event(roleGuideStep);check(view.scrollView:isVisible()and not view.supplyLocked:isVisible(),'guide unlock restores stock')
close(view);H.finish()
scene,d=fresh(480,800);d[roleProducerQueue]={};local before=H.serialize(d)
view=assert(ResourceLayer:create());view:retain();scene:addChild(view);equal(#view.supplyWorkerButtons,0,'zero unlocked jobs remains useful');equal(H.serialize(d),before,'empty gather page read-only');inspect(view,480,800)
d[roleProducerQueue]={{[dataKeyID]='1',[dataKeyNum]=4}};H.event(roleProducerQueue);equal(view.workerUseNum,4,'late worker queue rebuilds allocation');check(next(view.produceTable)~=nil,'late worker queue refreshes net production')
local button=view.setBtn;button:retain();close(view);old=#changes;button.onSingleCLick();equal(#changes,old,'disposed gather inert');button:release();H.finish()
scene,d=fresh(480,800);BaseViewLastClickCDTime=now-9
view=assert(ResourceLayer:create());view:retain();scene:addChild(view)
check(not view.bIsCenterBtnCanClick,'cold reopen retains gather cooldown');equal(view.setButtonProgrees:getPercentage(),30,'cold reopen retains elapsed 9 of 30 seconds')
local sameButton,sameTimer,sameListener=view.setBtn,view.setButtonProgrees,view.setBtn.listener
check(sameTimer:getParent()==sameButton and sameButton:getParent()==view.coherentShell.canvas,'same controller objects are reparented')
view.workerData={};d[roleProducerQueue]={};local workerCount=0
for id in pairs(H.tables[csvOfWorker])do workerCount=workerCount+1;d[roleProducerQueue][workerCount]={[dataKeyID]=id,[dataKeyNum]=999999999}end
H.event(roleProducerQueue);equal(#view.supplyWorkerButtons,workerCount,'every shipped worker rendered')
for _,pair in ipairs(view.supplyWorkerButtons)do
 check(pair.art~=nil,'every shipped worker has exact product identity art')
 for _,label in ipairs({pair.name,pair.note,pair.number})do check(label:getFontSize()*label:getScaleX()>=16,'full worker text readable '..label:getString())end
end
check(not view.supplyWorkyard:isVisible(),'full net ledger hides decorative workyard and retains all production space')
check(view.setBtn==sameButton and view.setButtonProgrees==sameTimer and view.setBtn.listener==sameListener,'worker refresh cannot replace cooldown identity')
close(view);H.finish()
scene,d=fresh(480,800);d[roleAlchemyCanLongPress]=0
view=assert(RepositoryLayer:create());view:retain();scene:addChild(view);check(not view.setBtn.onLongPressed,'unowned alchemy hold upgrade never granted');close(view);H.finish()
scene,d=fresh(640,1136);WARM_PIRATE_V1=false
view=assert(RepositoryLayer:create());view:retain();scene:addChild(view);check(not view.coherentShell,'explicit opt-out retains original repository');close(view)
view=assert(ResourceLayer:create());view:retain();scene:addChild(view);check(not view.coherentShell,'explicit opt-out retains original resource');close(view);H.finish();WARM_PIRATE_V1=true
print('PASS coherent supply native full stock/empty/late state, quantity snapshot, guide gates, stale input and legacy opt-out')
os.time=originalTime;cc.Director.getInstance=H.realGet
print('PASS coherent supply native assertions: '..assertions)
