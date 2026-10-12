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
YellowColor=cc.c3b(255,255,0);GreenColor=cc.c3b(95,255,51)
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
H.tables[csvOfLogingReward]=H.csv('logingReward')
local function split(s,delimiter)local out={};for part in (s..delimiter):gmatch('(.-)'..delimiter)do out[#out+1]=part end;return out end
for _,record in pairs(H.tables[csvOfLogingReward])do
 for _,key in ipairs({'Tips','reward'})do local out={};for _,part in ipairs(split(record[key],';'))do out[#out+1]=split(part,'_')end;record[key]=out end
end

package.loaded['LuaClass/CCall']=true
require 'LuaClass/SDButton';require 'LuaClass/DiamondStore';require 'LuaClass/Ranking';require 'LuaClass/SevenDayBonus';require 'LuaClass/CDKView'
H.tables[csvOfShopGift]=H.csv('shopgift1');H.tables[csvOfShopItem]=H.csv('shopitem');H.tables[csvOfPushGift]=H.csv('giftPush')
local function matrix(records,key)for _,record in pairs(records)do local out={};for _,part in ipairs(split(record[key],';'))do out[#out+1]=split(part,'_')end;record[key]=out end end
matrix(H.tables[csvOfShopGift],'item');for _,r in pairs(H.tables[csvOfShopGift])do r.desc=split(r.desc,';')end
for _,r in pairs(H.tables[csvOfShopItem])do r.resume=split(r.resume,'_')end
for _,key in ipairs({'title','star','price','desc'})do matrix(H.tables[csvOfPushGift],key)end
local callbacks={};dm.addDiamond=function(_,delta)
 local d=H.getData();callbacks[#callbacks+1]='spend:'..delta;if d[roleDiamond]+delta<0 then return 0 end;d[roleDiamond]=d[roleDiamond]+delta;return 1
end
dm.buyGoodsInDiamondStore=function(_,kind,value,achievement)callbacks[#callbacks+1]='grant:'..kind..':'..value..':'..achievement;return true end
dm.checkAndstepNextGift=function()callbacks[#callbacks+1]='nextGift'end
dm.getCurDiamondStoreGoods=function()return '2'end
getTableRowNum=function(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
getTimeStr=function(n)return tostring(n)..'秒'end
printn=function()end
local W=require 'LuaClass/WarmTheme'
local out=os.getenv('COHERENT_SERVICE_CAPTURE_DIR')or'/tmp/coherent-service-support'
local function capture(v,w,h,name)
 H.visit(v,function(n,visible)
  if visible and n.getString and n:getString()~=''then
   local scrolling=false;local parent=n:getParent()
   while parent do if tolua.type(parent)=='cc.ScrollView'then scrolling=true;break end;parent=parent:getParent()end
   if not scrolling then
    local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
    assert(a.x>=-1 and a.y>=-1 and b.x<=w+1 and b.y<=h+1,'visible text bounds '..name..': '..n:getString())
   end
   if n.getFontSize then assert(n:getFontSize()*n:getScaleX()>=15,'readable type '..name..': '..n:getString())end
  end
 end)
 if coherentCapture then
  local file=out..'/'..name..'-'..w..'x'..h
  assert(coherentCapture(v,w,h,file..'.png'))
  if v.serviceCanvas then
   -- Rendering resets equal-z arrival order in this engine. Re-sort a live
   -- sheet repeatedly, then verify its exact pixels in the Python harness.
   local root=v.serviceCanvas;local nodes={}
   for i=1,28 do local n=cc.Node:create();root:addChild(n);nodes[i]=n end
   assert(coherentCapture(v,w,h,file..'-dynamic-add.png'))
   for _,n in ipairs(nodes)do n:removeFromParent(true)end
   assert(coherentCapture(v,w,h,file..'-dynamic-remove.png'))
  end
 end
end
local now=86400*20000
NotificationNode.getInstance=function()return {GetGameTime=function()return now end}end
local writes,grants=0,0
dm.setRoleData=function(_,key,value)H.getData()[key]=value;writes=writes+1 end
dm.addPackItemWithId=function()grants=grants+1 end;dm.addSoilderWithId=dm.addPackItemWithId
dm.setAchievementInfo=function()end
local function fresh(w,h)
 H.fixture();local scene=H.prepare(w,h);local d=H.getData();d[roleAlchemyCanLongPress]=0;d[roleAlchemyUnit]=3
 d[roleDiamond]=500;d[roleMoney]=2000;d[roleArenaMaxRecord]=31;d[roleExtents]=250;d[roleSevenDayBonus]=0
 return scene,d
end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 local w,h=unpack(size);local scene,d=fresh(w,h)
 local rank=assert(RankingLayer:create());rank:retain();scene:addChild(rank)
 capture(rank,w,h,'ranking-offline')
 rank.rankData={{rank=1,nickname='乘风破浪的船长',amount=12345},{rank=2,nickname='小海盗',amount=1200}};rank:reload();rank:setRequestState(false,'');capture(rank,w,h,'ranking-loaded')
 local name=assert(InputNameView:create(rank));name:retain();scene:addChild(name);capture(name,w,h,'ranking-nickname');name:removeFromParent(true);name:release()
 rank:destory();rank:removeFromParent(true);rank:release()
 local reward=assert(SevenDayBonusLayer:create());reward:retain();capture(reward,w,h,'seven-day-first')
 reward:destory();reward:removeFromParent(true);reward:release()
 local code=assert(CDKView:create());code:retain();scene:addChild(code);capture(code,w,h,'cdk-entry');code:removeFromParent(true);code:release()
 local store=assert(DiamondStore:create());store:retain();scene:addChild(store);capture(store,w,h,'diamond-store')
 local confirmation=store:openCoherentGood(1);assert(confirmation);capture(confirmation,w,h,'diamond-confirm');confirmation.serviceCancel.item:activate();assert(not store.serviceAlert)
 local gift=store:openCoherentGift(1);assert(gift);capture(gift,w,h,'gift-confirm');gift.serviceCancel.item:activate()
 store:destory();store:removeFromParent(true);store:release()
 local offer=assert(PushGiftView:create());offer:retain();scene:addChild(offer);capture(offer,w,h,'gift-offer');offer:removeFromParent(true);offer:release()
 H.finish();print('PASS service visual '..w..'x'..h)
end

local assertions=0
local function eq(a,b,why)assertions=assertions+1;assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function ok(v,why)assertions=assertions+1;assert(v,why)end
local function dispose(v)
 if v.destory then v:destory()end;v:removeFromParent(true);v:release()
end
local function step(scene,dt)
 H.visit(scene,function(n)director:getActionManager():resumeTarget(n)end);director:getActionManager():update(dt)
end
local function text(v,s)v.textField:setText(s)end
local function touch(button)
 local z=button:getContentSize();local p=button:convertToWorldSpace(cc.p(z.width/2,z.height/2));return{getLocation=function()return p end}
end
local requests={};local http=HttpSingleton:getInstance()
http.send=function(_,method,url,body,callback)requests[#requests+1]={callback=callback,url=url}end
getonlyID=function()return 'native-fixture'end
json=require 'json'
local function deliver(payload,status,index)
 local request=requests[index or #requests];assert(request,'request exists');request.callback({status=status or 200,response=type(payload)=='string'and payload or json.encode(payload)})
end
local scene,d=fresh(480,800)
local before=H.serialize(d);local rank=RankingLayer:create();rank:retain();scene:addChild(rank)
eq(H.serialize(d),before,'ranking offline open is read-only');eq(rank.statusLabel:getString(),'排行榜服务暂未配置','truthful offline rank state')
rank.serviceURL='https://service-fixture.invalid/?';rank:httpConnection(1,31,nil)
ok(rank._requestPending,'real request pending');local count=#requests;rank:changeRankType();eq(#requests,count,'pending rank switch blocked')
capture(rank,480,800,'ranking-pending');deliver({top100={}});eq(rank.statusLabel:getString(),'暂无排名数据','honest empty response')
capture(rank,480,800,'ranking-empty')
rank:httpConnection(1,31,nil);deliver('bad response',503);ok(not rank._requestPending,'failure releases pending');capture(rank,480,800,'ranking-failure')
rank:httpConnection(1,31,nil);deliver({top100={{rank=1,nickname=string.rep('乘风破浪',8),amount=999},{rank=2,nickname='船长',amount=31}},mine={nickname='船长'}})
eq(d[roleNickname],'船长','server-confirmed nickname saved');eq(#rank.rankData,2,'loaded rows');capture(rank,480,800,'ranking-long-name')
local name=InputNameView:create(rank);name:retain();name:show();step(scene,.3)
text(name,'　 ');count=#requests;name:submitName();eq(#requests,count,'empty nickname blocked')
text(name,'新船长');name:submitName();eq(#requests,count+1,'nickname submits original request');name:submitName();eq(#requests,count+1,'duplicate nickname pending blocked')
deliver({top100={},mine={nickname='新船长'}});eq(d[roleNickname],'新船长','nickname stores server result');ok(name._closed,'successful nickname closes');step(scene,.3);name:removeFromParent(true);name:release()
rank:httpConnection(1,31,nil);local pending=#requests;dispose(rank);before=H.serialize(d);deliver({top100={},mine={nickname='过期回调'}},200,pending);eq(H.serialize(d),before,'disposed rank ignores late reply')
H.finish()

-- Exact once-only original reward callback, including claim-time date changes.
for _,day in ipairs({1,2,3,6,7})do
 scene,d=fresh(480,800);d[roleSevenDayBonus]=(day-1)*1000000+19999
 local reward=assert(SevenDayBonusLayer:create());reward:retain();local count=grants;local saves=writes
 eq(SevenDayBonusLayer:create(),nil,'reward singleton');capture(reward,480,800,'seven-day-'..day)
 reward.claimButton.item:activate();local expected=#H.tables[csvOfLogingReward][tostring(day)].reward
 eq(grants,count+expected,'exact shipped day reward items');eq(writes,saves+1,'one original reward date save')
 eq(d[roleSevenDayBonus],day*1000000+20000,'date/count encoding unchanged')
 reward.claimButton.item:activate();eq(grants,count+expected,'repeat retained claim cannot grant');eq(writes,saves+1,'repeat claim cannot save')
 eq(SevenDayBonusLayer:create(),nil,'same-day reopen ineligible');dispose(reward);H.finish()
end
scene,d=fresh(480,800);local reward=SevenDayBonusLayer:create();reward:retain();local count=grants;local saves=writes
d[roleSevenDayBonus]=1000000+20000;reward.claimButton.item:activate();eq(grants,count,'claim-time date recheck');eq(writes,saves,'stale claim cannot save');dispose(reward)
d[roleSevenDayBonus]=1000000+20001;eq(SevenDayBonusLayer:create(),nil,'clock rollback ineligible')
d[roleSevenDayBonus]=7000000+100;eq(SevenDayBonusLayer:create(),nil,'completed seven days ineligible');H.finish()

scene,d=fresh(480,800);local code=CDKView:create();code:retain();code:show();step(scene,.3)
text(code,' ');count=#requests;code:requestNetwork(code.textField:getStringValue());eq(#requests,count,'blank code no HTTP')
text(code,'A1B2');before=H.serialize(d);eq(code:requestNetwork('A1B2'),false,'Linux native redemption unavailable');eq(H.serialize(d),before,'unavailable redemption no grant')
eq(code.textField:getStringValue(),'A1B2','offline keeps editable code');capture(code,480,800,'cdk-unavailable')
code.serviceURL='https://service-fixture.invalid/?';code:httpConnection('A1B2');ok(code._requestPending,'HTTP pending state');count=#requests;code:httpConnection('A1B2');eq(#requests,count,'CDK pending duplicate blocked')
H.tables[csvOfGift]={test={items={{'1','1005','3'}}}};local redemptions=0
dm.cdkExchangeGoods=function(_,kind,id,amount)redemptions=redemptions+1;eq(id,'1005','CDK original item ID');eq(amount,'3','CDK original quantity')end
code:close();code:close();deliver({dropId='test'});deliver({dropId='test'});eq(redemptions,1,'late submitted success grants exactly once after close');step(scene,.3);dispose(code);H.finish()

local function makeStore(items,gifts)
 local scene,d=fresh(480,800);d[roleMapInfo]={mapIndex=16};d[roleDiamondStoreData]={['1']=gifts or {{'2',-1,0}},['2']=items or {{'4',0},{'6',0},{'12',0},{'16',0}}}
 d[roleMapBuyItems]={'19'}
 local v=assert(DiamondStore:create());v:retain();scene:addChild(v);return scene,d,v
end
scene,d,store=makeStore();eq(d[roleMapBuyItems],nil,'existing normalized map-buy bookkeeping retained')
local original=d[roleDiamond];callbacks={};local modal=store:openCoherentGood(1);modal:retain()
modal.serviceConfirm.item:activate();eq(d[roleDiamond],original-150,'exact virtual diamond cost');eq(table.concat(callbacks,','),'spend:-150,grant:2:15:0,nextGift','original transaction callback order')
eq(store.goodsData[1][2],1,'non-repeat item bought flag');modal.serviceConfirm.item:activate();eq(d[roleDiamond],original-150,'repeated retained modal cannot spend twice');modal:release()
modal=store:openCoherentGood(2);modal.serviceConfirm.item:activate();eq(store.goodsData[2][1],'7','original next-item progression');eq(d[roleDiamond],original-200,'next-item exact cost')
modal=store:openCoherentGood(4);modal.serviceConfirm.item:activate();eq(store.goodsData[4][2],0,'repeat item remains purchasable');eq(d[roleDiamond],original-230,'repeat-item exact cost')
original=d[roleDiamond];modal=store:openCoherentGood(3);modal:retain();store.goodsData[3][2]=1;modal.serviceConfirm.item:activate();eq(d[roleDiamond],original,'late buyState recheck before spending');ok(store.serviceAlert==modal,'original late buyState early-return keeps modal');modal.serviceCancel.item:activate();modal:release()
d[roleDiamond]=0;modal=store:openCoherentGood(2);callbacks={};modal.serviceConfirm.item:activate();eq(table.concat(callbacks,','),'spend:-80','shortage never invokes grant');eq(d[roleDiamond],0,'shortage cannot spend')
local old=store.storeRows[2].button;old:retain();store:loadData(nil);old.onSingleCLick();eq(store.serviceAlert,nil,'stale list callback rejected');old:release()
local row=store.storeRows[1].button;store.storeScroll:setContentOffset(cc.p(0,0));ok(not row:onTouchBegan(touch(row)),'clipped store row cannot accept touch')
store.storeScroll:setContentOffset(cc.p(0,235-store.storeContainer:getContentSize().height))
row=store.storeRows[2].button;local p=touch(row):getLocation();local point=cc.p(p.x,p.y);local drag={getLocation=function()return point end}
ok(row:onTouchBegan(drag),'native store row accepts visible press');point=cc.p(p.x,p.y+32);row:onTouchMoved(drag);row:onTouchEnded(drag);eq(store.serviceAlert,nil,'store drag does not buy')
local PA=require 'LuaClass/PurchaseAvailability';local originalRequest=PA.request;local giftPayType
PA.request=function(id)giftPayType=id;return originalRequest(id)end
local requestsBefore=#requests;modal=store:openCoherentGift(1);modal:retain();local beforeState=H.serialize(d);modal.serviceConfirm.item:activate();modal.serviceConfirm.item:activate();eq(H.serialize(d),beforeState,'Linux gift confirm never invents grant');eq(#requests,requestsBefore,'no billing fallback HTTP');eq(giftPayType,H.tables[csvOfShopGift]['2'].payType,'store gift exact payType');PA.request=originalRequest;modal:release()
local stale=store.storeRows[2].button;stale:retain();dispose(store);stale.onSingleCLick();eq(store.serviceAlert,nil,'disposed store callback rejected');stale:release();eq(next(dm.__eventListener.DiamondStoreUIReload),nil,'store leaves no retained listener alias');H.finish()

scene,d,store=makeStore({{'4',0}},{});local grant=dm.buyGoodsInDiamondStore;dm.buyGoodsInDiamondStore=function()return false end
modal=store:openCoherentGood(1);modal:retain();original=d[roleDiamond];modal.serviceConfirm.item:activate()
eq(d[roleDiamond],original-150,'existing callback-failure spend ordering preserved');ok(store.serviceAlert==modal,'original grant-failure early return keeps modal')
modal.serviceConfirm.item:activate();eq(d[roleDiamond],original-150,'failed attempted modal cannot charge twice');modal.serviceCancel.item:activate();modal.serviceCancel.item:activate();eq(store.serviceAlert,nil,'repeated cancellation clears exactly the owner');modal:release();dm.buyGoodsInDiamondStore=grant;dispose(store);H.finish()
scene,d,store=makeStore({},{});eq(#store.storeRows,0,'empty goods supports empty state');capture(store,480,800,'diamond-empty');dispose(store);H.finish()
local all={};for id,record in pairs(H.tables[csvOfShopItem])do all[#all+1]={id,0}end
table.sort(all,function(a,b)return tonumber(a[1])<tonumber(b[1])end)
scene,d,store=makeStore(all,{{'2',os.time()+10,0},{'7',-1,0}});eq(#store.storeRows,29,'full shipped shop fixture');capture(store,480,800,'diamond-full');store:moveToPoint(2);eq(store.pageIndex,2,'gift page selection')
d[roleDiamondStoreData]['1'][1][2]=os.time()-1;store:updateCountdown(1);eq(d[roleDiamondStoreData]['1'][1][1],'6','original expiration advances gift');eq(d[roleDiamondStoreData]['1'][1][2],-1,'original next duration preserved');dispose(store);H.finish()

scene,d=fresh(480,800);local offer=PushGiftView:create();offer:retain();offer:show();step(scene,.3)
local PA=require 'LuaClass/PurchaseAvailability';local request=PA.request;local offered={}
PA.request=function(id)offered[#offered+1]=id;return request(id)end
before=H.serialize(d);offer.giftBuyButton.item:activate();eq(#offered,0,'push gift delayed buy remains gated')
step(scene,offer.timeLine+.1);ok(offer.giftBuyButton:isVisible(),'delayed original offer becomes available');capture(offer,480,800,'gift-offer-ready')
offer.giftBuyButton.item:activate();eq(offered[1],H.tables[csvOfPushGift]['2'].payType,'push gift exact payType');eq(H.serialize(d),before,'unsupported push gift no grant')
offer:close();offer:close();offer.giftBuyButton.item:activate();eq(#offered,1,'closing offer cannot buy');step(scene,.3);dispose(offer);PA.request=request;H.finish()
print('PASS '..assertions..' native service/reward assertions: real request callbacks, offline/pending/failure/stale states, nickname saving, CDK late exactly-once grant, seven-day/date guards, virtual costs and order, repeat/next/shortage, full/empty stores, clipping/drag, original gift payType/delay, no live services or profiles')

-- Dispatch creates the incoming store before destroying the outgoing store.
-- Exercise real Cocos listener handles, not just DataManager's Lua aliases.
local lifecycleAssertions=assertions
local function storeSubscriptions()
 local handles,closures=0,0
 for _,value in pairs(dm.__eventListener.DiamondStoreUIReload or {})do
  if type(value)=='function'then closures=closures+1 else handles=handles+1 end
 end
 return handles,closures
end
local function subscriptionCount(expected,why)
 local handles,closures=storeSubscriptions();eq(handles,expected,why..' native handles');eq(closures,expected,why..' closure aliases')
end
local function dispatchNative(name)
 dm.__eventDispatcher:dispatchEvent(cc.EventCustom:new('DiamondStoreUIReload'..name))
end
scene,d,store=makeStore()
local previous=store;local incoming=assert(DiamondStore:create());incoming:retain();scene:addChild(incoming)
local previousName,incomingName=previous.serviceReloadListenerName,incoming.serviceReloadListenerName
ok(previousName~=incomingName,'overlapping stores own distinct subscriptions');subscriptionCount(2,'overlap')
local previousEvents,incomingEvents,previousLoads,incomingLoads=0,0,0,0
local previousCallback=previous.serviceReloadCallback
previous.buyGigtUIRefresh=function(self,e)previousEvents=previousEvents+1;DiamondStore.buyGigtUIRefresh(self,e)end
incoming.buyGigtUIRefresh=function(self,e)incomingEvents=incomingEvents+1;DiamondStore.buyGigtUIRefresh(self,e)end
previous.loadData=function(self,value)previousLoads=previousLoads+1;DiamondStore.loadData(self,value)end
incoming.loadData=function(self,value)incomingLoads=incomingLoads+1;DiamondStore.loadData(self,value)end
event('DiamondStoreUIReload');eq(previousEvents,1,'old live store receives reload');eq(incomingEvents,1,'new live store receives reload')
previous:destory();previous:destory();subscriptionCount(1,'old disposed')
eq(previous.serviceReloadCallback,nil,'old drops its callback');eq(previous.serviceReloadListenerName,nil,'old drops its subscription name')
previousCallback();eq(previousEvents,1,'retained old closure rejects disposal')
-- Clear only the guard in this probe: an orphaned native handle must not be
-- masked by the production disposed check. The retained node is still alive.
previous.serviceDisposed=false;dispatchNative(previousName);previous.serviceDisposed=true
eq(previousEvents,1,'old native callback physically removed')
event('DiamondStoreUIReload');eq(previousEvents,1,'disposed store no longer receives broadcast');eq(incomingEvents,2,'old disposal preserves new native callback')
step(scene,.01);step(scene,.2);eq(previousLoads,0,'queued old refresh canceled');eq(incomingLoads,2,'new refresh actions still execute')
incoming:destory();subscriptionCount(0,'both disposed')
incoming.serviceDisposed=false;dispatchNative(incomingName);incoming.serviceDisposed=true
eq(incomingEvents,2,'new native callback physically removed')
dispose(previous);dispose(incoming);H.finish()

local usedNames={}
for cycle=1,20 do
 scene,d,store=makeStore()
 local name=store.serviceReloadListenerName
 ok(not usedNames[name],'reopen never reuses a listener name');usedNames[name]=true
 local calls=0;store.buyGigtUIRefresh=function(self)calls=calls+1;self:destory()end
 event('DiamondStoreUIReload');eq(calls,1,'callback may dispose its own store');subscriptionCount(0,'callback disposal')
 store.serviceDisposed=false;dispatchNative(name);store.serviceDisposed=true
eq(calls,1,'callback disposal unregisters native handle')
 store:destory();dispose(store);H.finish();subscriptionCount(0,'repeated open/close')
end

-- Native scene cleanup walks a live child vector. Owner disposal must neither
-- remove the modal sibling nor let an intervening retained callback do so.
local PA=require 'LuaClass/PurchaseAvailability';local originalRequest=PA.request
for _,kind in ipairs({'virtual','gift'})do
 scene,d,store=makeStore()
 local modal;local sentinels={0,0,0};local attemptedPayments=0
 PA.request=function()attemptedPayments=attemptedPayments+1;return false end
 local leading=cc.Node:create();scene:addChild(leading)
 leading:registerScriptHandler(function(e)
  if e=='cleanup'then
   sentinels[1]=sentinels[1]+1
   modal.serviceConfirm.item:activate();modal.serviceCancel.item:activate();modal:close()
   if type(modal.callbackfunc)=='function'then modal.callbackfunc()end
  end
 end)
 modal=kind=='virtual'and store:openCoherentGood(1)or store:openCoherentGift(1);modal:retain()
 for i=2,3 do
  local n=cc.Node:create();scene:addChild(n)
  n:registerScriptHandler(function(e)if e=='cleanup'then sentinels[i]=sentinels[i]+1 end end)
 end
 local state=H.serialize(d);local count=#callbacks;local children=#scene:getChildren()
 scene:cleanup()
 for i=1,3 do eq(sentinels[i],1,kind..' scene child cleanup exactly once')end
 eq(#scene:getChildren(),children,kind..' scene traversal keeps its child vector')
 ok(store.serviceDisposed,kind..' scene cleanup disposes store');eq(store.serviceAlert,nil,kind..' owner releases confirmation')
 eq(modal:getNumberOfRunningActions(),0,kind..' scene cleanup cancels deferred retirement')
 ok(not modal:isVisible(),kind..' retired confirmation is hidden')
 modal.serviceConfirm.item:activate();modal.serviceCancel.item:activate();modal:close()
 if type(modal.callbackfunc)=='function'then modal.callbackfunc()end
 eq(H.serialize(d),state,kind..' stale confirmation cannot alter profile');eq(#callbacks,count,kind..' stale confirmation cannot spend or grant')
 eq(attemptedPayments,0,kind..' stale confirmation cannot request payment');subscriptionCount(0,kind..' scene cleanup')
 modal:release();store:release();H.finish()
end

-- Standalone owner removal leaves the scene alive. The inert sibling retires
-- on its own action, without a global scheduled closure retaining the scene.
for _,kind in ipairs({'virtual','gift'})do
 scene,d,store=makeStore()
 local modal=kind=='virtual'and store:openCoherentGood(1)or store:openCoherentGift(1);modal:retain()
 local count=#callbacks;local state=H.serialize(d);local attemptedPayments=0
 PA.request=function()attemptedPayments=attemptedPayments+1;return false end
 store:removeFromParent(true)
 ok(store.serviceDisposed,kind..' direct removal disposes owner');eq(store.serviceAlert,nil,kind..' direct removal drops modal ownership')
 ok(not modal:isVisible(),kind..' direct removal immediately hides sibling')
 modal.serviceConfirm.item:activate();modal.serviceCancel.item:activate();modal:close()
 step(scene,.01);step(scene,.01)
 eq(modal:getParent(),nil,kind..' direct removal leaves no orphan modal');eq(modal:getNumberOfRunningActions(),0,kind..' retirement leaves no actions')
 eq(H.serialize(d),state,kind..' direct removal callback cannot mutate profile');eq(#callbacks,count,kind..' direct removal callback cannot spend or grant')
 eq(attemptedPayments,0,kind..' direct removal cannot request payment');subscriptionCount(0,kind..' direct removal')
 modal:release();store:release();H.finish()
end
PA.request=originalRequest

-- Manual Dispatch disposal still removes both original modal types at once.
for _,kind in ipairs({'virtual','gift'})do
 scene,d,store=makeStore()
 local modal=kind=='virtual'and store:openCoherentGood(1)or store:openCoherentGift(1);modal:retain()
 local state=H.serialize(d)
 store:destory();eq(modal:getParent(),nil,kind..' manual disposal closes immediately')
 eq(store.serviceAlert,nil,kind..' manual disposal clears ownership');eq(H.serialize(d),state,kind..' manual disposal preserves role data')
 modal.serviceConfirm.item:activate();eq(H.serialize(d),state,kind..' retained manual-close callback cannot mutate role data')
 modal:release();dispose(store);H.finish();subscriptionCount(0,kind..' manual disposal')
end
print('PASS '..(assertions-lifecycleAssertions)..' native store lifecycle assertions: overlapping subscriptions, queued/stale callbacks, physical listener removal, 20 reopen cycles, scene traversal, deferred direct removal, manual close and no late spends/grants/payment requests')

if coherentCapture then
 -- The render harness supplies a real offscreen GLView. Drive the actual
 -- Director scene lifecycle; no desktop window or player save is opened.
 local liveAssertions=assertions
 local function frames()
  for _=1,5 do local deadline=os.clock()+.002;while os.clock()<deadline do end;director:mainLoop()end
 end
 local function enter(scene)
  if director:getRunningScene()then director:replaceScene(scene)else director:runWithScene(scene)end
  frames();ok(scene:isRunning(),'store fixture enters real native scene')
 end
 local function exited(node,why)
  ok(not node:isRunning(),why..' exits')
  for _,child in ipairs(node:getChildren())do exited(child,why)end
 end
 for _,kind in ipairs({'virtual','gift'})do
  for _,path in ipairs({'manual','owner','scene','scene_modal_first'})do
   scene,d,store=makeStore();enter(scene)
   local modal=kind=='virtual'and store:openCoherentGood(1)or store:openCoherentGift(1)
   local confirm,cancel=modal.serviceConfirm.item,modal.serviceCancel.item;confirm:retain();cancel:retain()
   local exits,cleanups=0,0;local witness=cc.Node:create();modal:addChild(witness)
   witness:registerScriptHandler(function(e)if e=='exit'then exits=exits+1 elseif e=='cleanup'then cleanups=cleanups+1 end end)
   ok(modal:isRunning(),kind..' confirmation enters running scene')
   if path=='scene_modal_first'then modal:setLocalZOrder(-1);scene:sortAllChildren()end
   frames();local state=H.serialize(d);local count=#callbacks;local attemptedPayments=0
   PA.request=function()attemptedPayments=attemptedPayments+1;return false end
   if path=='manual'then
    store:destory();eq(store.serviceAlert,nil,kind..' live manual disposal clears ownership')
   elseif path=='owner'then
    store:removeFromParent(true);eq(store.serviceAlert,nil,kind..' live direct removal clears ownership')
    ok(not modal:isVisible(),kind..' live direct removal hides modal immediately')
   else
    director:replaceScene(cc.Scene:create())
   end
   -- No artificial modal retain: scene teardown must safely release it while
   -- the two retained controls remain available to probe stale callbacks.
   frames();eq(exits,1,kind..' '..path..' modal descendants exit exactly once')
   eq(cleanups,1,kind..' '..path..' modal descendants clean exactly once')
   ok(not confirm:isRunning() and not cancel:isRunning(),kind..' '..path..' retained controls exited')
   confirm:activate();cancel:activate();confirm:release();cancel:release()
   eq(H.serialize(d),state,kind..' '..path..' callbacks preserve profile');eq(#callbacks,count,kind..' '..path..' callbacks cannot spend/grant')
   eq(attemptedPayments,0,kind..' '..path..' callbacks cannot request payment');subscriptionCount(0,kind..' '..path..' live disposal')
   eq(store.serviceAlert,nil,kind..' '..path..' ownership cleared')
   if path=='owner'then eq(scene:getChildrenCount(),0,kind..' live direct removal leaves no orphan shield')end
   if path=='manual'then store:removeFromParent(true)end
   if path=='scene' or path=='scene_modal_first'then
    exited(store,kind..' '..path..' store');eq(director:getRunningScene():getChildrenCount(),0,'replacement scene has no stale UI')
   else
    director:replaceScene(cc.Scene:create());frames()
   end
   store:release();H.finish()
  end
 end
 PA.request=originalRequest
 print('PASS '..(assertions-liveAssertions)..' running-scene store assertions: native onExit/cleanup in both sibling orders, unretained modal destruction, live direct removal, immediate manual disposal and retained stale controls')
end

-- The event fix also preserves the opt-out renderer and its explicit disposal.
local warmFlag=rawget(_G,'WARM_PIRATE_V1');WARM_PIRATE_V1=false
scene,d,store=makeStore()
local legacyIncoming=assert(DiamondStore:create());legacyIncoming:retain();scene:addChild(legacyIncoming)
ok(not store.serviceWarm and not legacyIncoming.serviceWarm,'legacy store renderer remains selectable')
local legacyCalls=0;legacyIncoming.buyGigtUIRefresh=function()legacyCalls=legacyCalls+1 end
store:destory();event('DiamondStoreUIReload');eq(legacyCalls,1,'legacy incoming store keeps its reload listener')
dispose(store);dispose(legacyIncoming);H.finish();subscriptionCount(0,'legacy store disposal')
WARM_PIRATE_V1=warmFlag
print('PASS legacy store opt-out, overlapping reload ownership and complete listener cleanup')
