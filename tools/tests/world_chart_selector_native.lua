-- Real reachable EventLayer -> WorldMapLayer -> original route methods. Native
-- EGL pixels and GLView touch dispatcher; only decoded CSV/in-memory role data.
local f=assert(io.open('tools/tests/coherent_event_pages_native.lua','rb'));local source=f:read('*a');f:close()
local stop=assert(source:find('local families={}',1,true))
local T=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,W=W,sites=sites,controller=controller,
 reset=function(info,limit,currency)roles={[roleMapInfo]=info,[roleTranslateDoor]=limit};diamond=currency or 100000;writes=0 end,
 roles=function()return roles end,writes=function()return writes end,diamonds=function()return diamond end}
]],'@world-selector-fixture'))()
local H,W=T.H,T.W
H.tables[csvOfWorldMapCoordinates]=H.csv('WorldMapCoordinates');H.tables[csvOfShopItem]=H.csv('shopitem')
for _,r in pairs(H.tables[csvOfShopItem])do local fields={};for part in r.resume:gmatch('[^_]+')do fields[#fields+1]=part end;r.resume=fields end
package.loaded['LuaClass/WorldMapLayer']=nil;require 'LuaClass/WorldMapLayer'
local S=require 'LuaClass/WorldChartSelector'
getChineseCharactersByNum=function(index)return tostring(index)end
local out=os.getenv('COHERENT_WORLD_CAPTURE_DIR')or'/workspace/shared/pirate-audit/world-chart-selector'
local count=0
local function check(ok,why)count=count+1;assert(ok,why)end
local function eq(a,b,why)check(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function point(n)local z=n:getContentSize();return n:convertToWorldSpace(cc.p(z.width/2,z.height/2))end
local function gesture(phase,p)coherentEventGesture(phase,p.x,p.y)end
local function tap(n)local p=point(n);gesture(0,p);gesture(2,p)end
local function cancelled(n)local p=point(n);gesture(0,p);gesture(3,p)end
local function dragged(n)local p=point(n);gesture(0,p);p=cc.p(p.x+24,p.y);gesture(1,p);gesture(2,p)end
local function bounds(n,w,h,why)
 local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
 check(a.x>=-1 and a.y>=-1 and b.x<=w+1 and b.y<=h+1,why..' '..a.x..','..a.y..' '..b.x..','..b.y)
end
local function inspect(v,w,h)
 bounds(v.worldBack,w,h,'Back in viewport');bounds(v.worldPrimary,w,h,'primary in viewport')
 H.visit(v,function(n,visible)
  if visible and n.getString and n:getString()~=''then
   local p=n:getParent();local clipped=false
   while p and p~=v do if p.getViewSize then clipped=true end;p=p:getParent()end
   if not clipped then bounds(n,w,h,'label '..n:getString())end
   if n.getFontName then eq(n:getFontName(),W.font,'shared font unchanged')end
  end
 end)
end
local function capture(v,w,h,name)
 inspect(v,w,h);local base=out..'/'..name..'-'..w..'x'..h
 check(coherentCapture(v,w,h,base..'.png'),'native capture')
 local nodes={};local roots={v,v:getParent(),v.worldDock,v.scrollview:getContainer(),v.worldPrimary,v.worldRows[1]}
 if v.worldModal then roots[#roots+1]=v.worldModal;roots[#roots+1]=v.worldModal.confirm end
 for _,root in ipairs(roots)do for i=1,28 do local n=cc.Node:create();root:addChild(n);nodes[#nodes+1]=n end end
 check(coherentCapture(v,w,h,base..'-dynamic-add.png'),'native dynamic insertion')
 for _,n in ipairs(nodes)do n:removeFromParent(true)end
 check(coherentCapture(v,w,h,base..'-dynamic-remove.png'),'native dynamic removal')
end
local scene,event,view,controller,routeCalls,unlocks
local function remove()
 if view then view:removeFromParent(true);view:release();view=nil end
 if event then event:removeFromParent(true);event=nil end
end
local function fresh(w,h,max,current,limit,currency,tip)
 remove();H.fixture();T.reset({mapIndex=max or 2,curIndex=current or 2,fadeMapFogIndex=tip or max or 2,tipMapIndex=tip},limit or 3,currency)
 screenSize=cc.size(w,h);scene=H.prepare(w,h);event=assert(EventLayer:create());scene:addChild(event)
 controller=T.controller();controller.owner.mapIndex=current or 2
 controller.owner.initMapByMapIndex=function(self,index)self.lastMap=index;self.mapCalls=(self.mapCalls or 0)+1 end
 event:setController(controller);event:refreshLayerByInfo(T.sites['3002'],false);event:show()
 routeCalls={};local enter=EventLayer.enterNextMapEnter
 event.enterNextMapEnter=function(self,need,index,only)routeCalls[#routeCalls+1]={need,index,only};return enter(self,need,index,only)end
 event:enterTeleport();view=assert(event.worldMapLayer);view:retain();event:enterTeleport();eq(event.worldMapLayer,view,'actual entry duplicate guard')
 eq(view.owner,event,'actual owner identity');eq(view.worldSelectedChapter:getString(),'第'..(current or 2)..'章 · '..S.names[current or 2],'actual pre-attachment setOwner initializes summary')
 coherentEventEnter(scene,w,h);return view
end
local function select(index)
 local sc=view.scrollview;local ch=sc:getContainer():getContentSize().height;local vh=sc:getViewSize().height
 sc:setContentOffset(cc.p(0,math.max(vh-ch,math.min(0,vh/2-(ch-(index-.5)*view.worldRowHeight)))))
 tap(view.worldRows[index]);eq(view.worldSelection,index,'native exact row selection '..index)
end
for _,size in ipairs({{360,640},{480,800},{640,960},{720,1280}})do
 local w,h=unpack(size);fresh(w,h)
 eq(T.writes(),0,'opening uses no persistent writes');eq(#routeCalls,0,'opening never checks/travels')
 eq(view.worldRows[1].title:getString(),'瓶中船','original unlocked chapter title')
 eq(view.worldRows[2].status:getString(),'当前海域','current chapter state')
 eq(view.worldRows[3].title:getString(),'未探索海域','undiscovered names never exposed')
 capture(view,w,h,'selector-current-unlocked-locked')
 cancelled(view.worldPrimary);check(not view.worldModal,'cancelled primary gesture is inert');check(not view.worldPrimary.pressed:isVisible(),'cancelled primary paint released')
 dragged(view.worldPrimary);check(not view.worldModal,'dragged primary gesture is inert')
 local interrupted=point(view.worldPrimary)
 gesture(0,interrupted);view:removeFromParent(false);scene:addChild(view);gesture(2,interrupted)
 check(view.worldModal==nil,'unfinished gesture must not survive native detach/reentry')
 check(not view.worldPrimary.pressed:isVisible(),'stale detached gesture releases painted state')
 tap(view.worldPrimary);check(view.worldModal~=nil,'fresh gesture works after rejected detached release')
 tap(view.worldModal.cancel)

 select(1);eq(#routeCalls,0,'selection is read only');eq(T.writes(),0,'selection never saves')
 tap(view.worldPrimary);local modal=assert(view.worldModal);local stale=modal.worldAccept
 tap(view.worldPrimary);eq(view.worldModal,modal,'rapid primary preserves single confirmation')
 capture(view,w,h,'destination-confirmation')
 cancelled(modal.confirm);eq(view.worldModal,modal,'cancelled confirm does not commit');dragged(modal.confirm);eq(view.worldModal,modal,'dragged confirm does not commit')
 tap(modal.cancel);eq(view.worldModal,nil,'real cancel closes');stale();eq(#routeCalls,0,'retained cancel-generation callback cannot travel')
 select(3);check(not view.worldPrimary.worldEnabled,'unopened primary disabled')
 tap(view.worldPrimary);eq(view.worldModal,nil,'disabled native action inert');view:moveToMapByIndex(3);eq(#routeCalls,0,'original mapMax gate unchanged')
 capture(view,w,h,'unknown-selected')
 local selection=view.worldSelection;local before=view.scrollview:getContentOffset().y
 coherentDescriptionDrag(view.scrollview,0);check(view.scrollview:getContentOffset().y~=before,'native GLView drag scrolls chapter sheet');eq(view.worldSelection,selection,'native row drag does not select')
 select(1);local p=point(view.worldPrimary);gesture(0,p);view:setVisible(false);gesture(2,p);view:setVisible(true);eq(view.worldModal,nil,'hide during gesture blocks stale click')
 tap(view.worldPrimary);modal=assert(view.worldModal);tap(modal.confirm)
 eq(#routeCalls,1,'confirmed travel starts one check-only gate');eq(routeCalls[1][1],false,'original check-only needEnter');eq(routeCalls[1][2],1,'exact chosen chapter');eq(routeCalls[1][3],true,'original isCheck true')
 eq(view.statue,'moveAction','original travel state');tap(view.worldPrimary);tap(view.worldBack);eq(#routeCalls,1,'repeat/back cannot race travel')
 coherentWorldStep(60);eq(#routeCalls,2,'one actual final route');eq(routeCalls[2][1],true,'actual enterMapByIndex dispatch');eq(routeCalls[2][2],1,'actual destination identity');eq(routeCalls[2][3],nil,'final route not check-only')
 eq(controller.owner.lastMap,1,'original owner receives map1');eq(controller.owner.mapCalls,1,'travel exactly once');eq(controller.triggered,1,'original event completion exactly once');eq(view:getParent(),nil,'successful route removes selector')
 H.finish();fresh(w,h)
 tap(view.worldPrimary);tap(assert(view.worldModal).confirm);eq(controller.owner.lastMap,2,'current-map confirmation original route');eq(controller.triggered,1,'current completion once');H.finish()
 fresh(w,h);tap(view.worldBack);tap(view.worldBack);eq(controller.triggered,1,'Back original completion once');eq(controller.owner.mapCalls,nil,'Back does not reinitialize map');eq(T.writes(),0,'Back has no state write');H.finish()
 fresh(w,h);select(1);tap(view.worldPrimary);stale=view.worldModal.worldAccept
 view:removeFromParent(true);stale();eq(#routeCalls,0,'late confirmation after departure inert');eq(view.worldModal,nil,'departure closes owned modal');H.finish()
 fresh(w,h);select(1);tap(view.worldPrimary);tap(view.worldModal.confirm);view:removeFromParent(true);coherentWorldStep(60);eq(#routeCalls,1,'departure cancels pending travel');eq(controller.owner.mapCalls,nil,'departed animation never travels');H.finish()
 print('PASS native selector pixels, GLView input, original selection/cancel/back/travel '..w..'x'..h)
end
-- Every original expansion record, with exact virtual price/delta and original
-- unlockMapDatas. Never load a native billing library or a persistent save.
local records={};for _,r in pairs(H.tables[csvOfShopItem])do local index=tonumber(r.unlock);if index and index>0 then records[#records+1]=r end end
table.sort(records,function(a,b)return tonumber(a.unlock)<tonumber(b.unlock)end)
check(#records>0,'decoded actual expansion records exist')
for _,record in ipairs(records)do
 local index=tonumber(record.unlock);local price=tonumber(record.price);local w,h=360,640
 print('WORLD_ROUTE_EXPANSION '..record.ID..' unlock='..index..' price='..price..' next='..record.resume[2])
 fresh(w,h,index,1,index-1,price+7,index);unlocks={}
 H.dm.buyGoodsInDiamondStore=function(_,kind,limit,achievement)unlocks[#unlocks+1]={kind,limit,achievement}end
 select(index);eq(view.worldSelectedState:getString(),'需要扩展包 · 钻石 × '..string.format('%.0f',price),'original visible exact expansion cost')
 tap(view.worldPrimary);eq(#routeCalls,1,'purchase starts original entitlement gate');eq(routeCalls[1][2],index,'paid selected chapter identity');eq(view.statue,'Buy','original Buy state')
 local modal=assert(view.worldModal);local stale=modal.worldAccept
 capture(view,w,h,'expansion-'..record.ID)
 tap(modal.cancel);eq(T.diamonds(),price+7,'cancel never spends');eq(#unlocks,0,'cancel never unlocks');stale();eq(#unlocks,0,'stale purchase confirmation inert')
 tap(view.worldPrimary);modal=assert(view.worldModal);stale=modal.worldAccept;tap(modal.confirm);stale()
 eq(T.diamonds(),7,'exact original diamond delta once');eq(#unlocks,1,'original purchase grant once');eq(unlocks[1][1],record.resume[1],'original resume category');eq(unlocks[1][2],tonumber(record.resume[2]),'original next limit');eq(unlocks[1][3],record.achievement,'original achievement identity')
 eq(T.roles()[roleTranslateDoor],tonumber(record.resume[2]),'original entitlement write');eq(T.roles()[roleMapBuyItems][1],record.ID,'original purchased ID');eq(view.statue,'ready','unlock presentation ready');eq(controller.owner.mapCalls,nil,'purchase never travels automatically')
 capture(view,w,h,'newly-unlocked-'..record.ID);H.finish()
 fresh(w,h,index,1,index-1,price-1,index);select(index);tap(view.worldPrimary);tap(view.worldModal.confirm)
 eq(T.diamonds(),price-1,'shortage cannot spend');eq(T.roles()[roleTranslateDoor],index-1,'shortage cannot unlock');check(view.worldSelectedState:getString():find('钻石不足',1,true),'shortage readable');capture(view,w,h,'shortage-'..record.ID);H.finish()
end
-- Service ownership and platform gating stay in their existing module.
fresh(360,640);local destroyed=0;local cancel
ChargeLayer={create=function()return{setCancelCallback=function(_,fn)cancel=fn end,destory=function()destroyed=destroyed+1 end}end}
view:showChargeView();eq(view.statue,'charging','original charging state');cancel();eq(view.statue,'ready','active service cancellation ready');eq(destroyed,1,'active service close once')
view:showChargeView();local late=cancel;view:removeFromParent(true);eq(destroyed,2,'departed selector closes owned service');late();eq(destroyed,2,'late service callback inert');H.finish()
-- Gate failure unrelated to a purchase must not fabricate a charge offer.
fresh(360,640);controller.checkEnterNext=function()return false end;select(1);tap(view.worldPrimary);tap(view.worldModal.confirm);eq(view.worldModal,nil,'failed readiness is not a fabricated purchase');eq(view.statue,'ready','failed readiness leaves Back usable');eq(controller.owner.mapCalls,nil,'readiness failure does not travel');H.finish()
-- Readiness can change during the presentation delay. The final original gate
-- denies travel; its failed attempt must not strand the selector in moveAction.
fresh(360,640);select(1);tap(view.worldPrimary);tap(view.worldModal.confirm);controller.checkEnterNext=function()return false end
coherentWorldStep(60);eq(controller.owner.mapCalls,nil,'late original gate denies travel');eq(view.statue,'ready','late denial releases only the presentation lock');tap(view.worldBack);eq(controller.triggered,1,'Back remains usable after late denial');H.finish()
-- Preserve the real new-chapter false-return story handoff and its owner.
local distribution=H.csv('strongholdDistribution');local plotIndex,actualPlots
for i=2,16 do local raw=distribution[tostring(i)].plots;if raw and raw~='0' then
 local rows={};for part in raw:gmatch('[^;]+')do local r={};for field in part:gmatch('[^_]+')do r[#r+1]=field end;rows[#rows+1]=r end
 if rows[1] and rows[1][1]~='0'then plotIndex=i;actualPlots=rows;break end
end end
check(plotIndex~=nil,'actual chapter story fixture exists')
fresh(360,640,plotIndex,1,16,nil,plotIndex);local plotPlayed,plotCallback
controller.owner.setVisible=function(self,value)self.visible=value end
controller.runAction=function(_,action)event:runAction(action)end
dataController.getStrongholdDistributionValueByIdAndKey=function(id,key)eq(id,tostring(plotIndex),'original story chapter lookup');eq(key,'plots','original story field');return actualPlots end
PlotLayer={create=function(_,unused,plots)eq(H.serialize(plots),H.serialize(actualPlots),'actual chapter plots identity');return {setStayCallback=function(_,fn)plotCallback=fn end,play=function()plotPlayed=true end}end}
select(plotIndex);tap(view.worldPrimary);tap(view.worldModal.confirm);coherentWorldStep(60)
eq(view.statue,'moveAction','original story retains transition state');eq(controller.owner.mapCalls,nil,'map waits for original story completion');eq(T.roles()[roleMapInfo].tipMapIndex,nil,'original story consumes original tip')
coherentWorldStep(105);check(plotPlayed and plotCallback,'original story handoff reached');eq(view:getParent(),nil,'original owner removes selector before story')
plotCallback();eq(controller.owner.lastMap,plotIndex,'story callback initializes exact original destination');eq(controller.triggered,1,'story completion original event once');coherentWorldStep(105);eq(controller.owner.statue,'ready','original story restores owner ready');H.finish()
-- Exact long title/cost layout remains bounded without changing global fonts.
fresh(360,640);local original=S.names[1];S.names[1]=string.rep(original,12);S.refresh(view);select(1);capture(view,360,640,'long-title');tap(view.worldPrimary);capture(view,360,640,'long-title-confirmation');local body=view.worldModal.worldBody;check(body:getContainer():getContentSize().height>body:getViewSize().height,'long exact destination prose scrolls');local before=body:getContentOffset().y;coherentDescriptionDrag(body,0);check(body:getContentOffset().y~=before,'native long confirmation drag');capture(view,360,640,'long-title-confirmation-scrolled');S.names[1]=original;H.finish()
-- Actual native detach/re-entry cancels owned work without leaving a busy view.
fresh(360,640);tap(view.worldPrimary);local late=view.worldModal.worldAccept
view:removeFromParent(false);scene:addChild(view);late();eq(view.worldModal,nil,'native exit closes confirmation');eq(view.statue,'ready','native re-entry is usable');tap(view.worldPrimary);check(view.worldModal~=nil,'native resumed primary usable');tap(view.worldModal.cancel);H.finish()
fresh(360,640);select(1);tap(view.worldPrimary);tap(view.worldModal.confirm);view:removeFromParent(false);scene:addChild(view);coherentWorldStep(60);eq(#routeCalls,1,'resumed selector cannot run departed travel');eq(view.statue,'ready','cancelled travel can be retried');H.finish()
-- All sixteen exact original callback destinations, no chapter reorder.
for index=1,16 do
 fresh(360,640,16,1,16);select(index);tap(view.worldPrimary);tap(view.worldModal.confirm)
 coherentWorldStep(52);eq(controller.owner.lastMap,index,'all sixteen actual original destinations');eq(controller.owner.mapCalls,1,'exact one destination callback');H.finish()
end
fresh(360,640,3,2,3,nil,3);eq(view.worldRows[3].status:getString(),'新海域 · 可以前往','original newly opened tip is explicit');capture(view,360,640,'newly-opened-chapter');H.finish()
-- Changed live entitlement or price invalidates an old purchase offer.
local record=records[1];local index=tonumber(record.unlock);local price=tonumber(record.price)
fresh(360,640,index,1,index-1,price+7,index);select(index);tap(view.worldPrimary);T.roles()[roleTranslateDoor]=tonumber(record.resume[2]);tap(view.worldModal.confirm);eq(T.diamonds(),price+7,'late entitlement update cannot cause duplicate charge');H.finish()
fresh(360,640,index,1,index-1,price+7,index);select(index);tap(view.worldPrimary);record.price=tostring(price+1);tap(view.worldModal.confirm);eq(T.diamonds(),price+7,'changed price requires a new confirmation');record.price=tostring(price);H.finish()
fresh(360,640,index,1,index-1,price+7,index);record.price='123456789012';S.refresh(view);select(index);capture(view,360,640,'long-price');tap(view.worldPrimary);capture(view,360,640,'long-price-confirmation');tap(view.worldModal.cancel);record.price=tostring(price);H.finish()
-- A retained selector cannot keep acting after its real EventLayer relinquishes it.
fresh(360,640);event.worldMapLayer=nil;tap(view.worldPrimary);eq(view.worldModal,nil,'owner identity loss disables native input');view:backToCurMap();eq(controller.triggered,nil,'retained Back cannot finish a different owner');H.finish()
-- Real Linux Application enum still makes native billing unavailable.
local availability=require 'LuaClass/PurchaseAvailability';local requests=0;purchase=function()requests=requests+1 end
local notice;ToastUtil.downString=function(_,value)notice=value end
check(not availability.isAvailable(),'actual Linux native billing unsupported');check(not availability.request('2'),'unsupported original product request rejected');eq(requests,0,'native billing bridge never invoked');eq(notice,'当前平台暂不支持充值购买','original unsupported platform feedback')
purchase=nil
-- Explicit opt-out still constructs the unchanged legacy scroll/map path.
remove();H.fixture();T.reset({mapIndex=3,curIndex=2,fadeMapFogIndex=3},3);WARM_PIRATE_V1=false;screenSize=cc.size(360,640);scene=H.prepare(360,640)
view=assert(WorldMapLayer:create());view:retain();scene:addChild(view);check(not view.coherentWorldSelector,'opt-out remains legacy');check(view.fogs[16]~=nil and view.ships[2]~=nil,'legacy map nodes retained');check(coherentCapture(view,360,640,out..'/legacy-optout-360x640.png'),'opt-out native pixels');WARM_PIRATE_V1=nil;H.finish();remove()
print('PASS '..count..' world selector native assertions; no player save, live service or real purchase')
