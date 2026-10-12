-- Presentation and input ownership for the existing WorldMapLayer routes.
-- This is a chapter itinerary, not a new geographic map. Undiscovered names
-- remain hidden. All travel/entitlement/economy calls belong to WorldMapLayer.
local W=require 'LuaClass/WarmTheme'
local S={}
S.names={'瓶中船','皇家港','加勒比海','白帽港','深邃幽蓝','极地港','霜冻海湾','冤嚎之境','乱葬海','无尽之海','海中城堡','幽魂之域','神秘海域','远古封印','死亡之渊','世界尽头'}
function S.enabled()return W.enabled()end
local C=W.colors
local function panel(root,w,h,color,x,y,z,r)
 local n=W.panel(w,h,color,r or 7);n:setPosition(cc.p(x or 0,y or 0));root:addChild(n,z or -10);return n
end
local function text(root,value,size,color,x,y,width,anchor)
 local n=W.label(value,size,color,x,y,false,anchor or 0)
 if width then W.fit(n,width)end
 root:addChild(n,10);return n
end
local function visible(n)
 if not n or not n:getParent()then return false end
 while n do if not n:isVisible()then return false end;n=n:getParent()end
 return true
end
function S.alive(v)
 return not v.worldDisposed and not v.worldSuspended and visible(v) and v.owner~=nil and
  (not v.worldManagedOwner or v.owner.worldMapLayer==v)
end
function S.ready(v)return S.alive(v) and v.statue=='ready' and not v.worldModal end
local function contains(n,p,w,h)
 local q=n:convertToNodeSpace(p);return q.x>=0 and q.y>=0 and q.x<=w and q.y<=h
end
-- Local control: no global SDButton/Menu changes. Native cancellation and any
-- drag release state without dispatch. A retained callback cannot outlive owner.
local function button(v,root,w,h,label,primary,action,guard,scroll)
 local b=cc.Node:create();b:setContentSize(cc.size(w,h));b.worldEnabled=true
 local color=primary and C.sea or C.paper
 b.face=panel(b,w,h,color,0,0,-20)
 b.pressed=panel(b,w,h,primary and cc.c3b(19,102,116) or cc.c3b(228,230,209),0,0,-19);b.pressed:setVisible(false)
 b.label=text(b,label,20,primary and C.white or C.ink,w/2,h/2,w-20,.5)
 root:addChild(b,20)
 function b:setEnabled(value)self.worldEnabled=value;self:setOpacity(value and 255 or 130);self:setCascadeOpacityEnabled(true)end
 local listener=cc.EventListenerTouchOneByOne:create();listener:setSwallowTouches(not scroll)
 local armed,start,offset,moved,generation
 local function reset()armed=false;moved=false;generation=nil;b.pressed:setVisible(false)end
 local function allowed()
  return b.worldEnabled and visible(b) and S.alive(v) and (not guard or guard())
 end
 listener:registerScriptHandler(function(touch)
  reset();local p=touch:getLocation()
  if not allowed()or not contains(b,p,w,h)then return false end
  if scroll then local z=scroll:getViewSize();if not contains(scroll,p,z.width,z.height)then return false end end
  start=p;offset=scroll and scroll:getContentOffset().y;generation=v.worldGeneration;armed=true;b.pressed:setVisible(true);return true
 end,cc.Handler.EVENT_TOUCH_BEGAN)
 listener:registerScriptHandler(function(touch)
  local p=touch:getLocation();if start and (math.abs(p.x-start.x)>9 or math.abs(p.y-start.y)>9)then moved=true;b.pressed:setVisible(false)end
 end,cc.Handler.EVENT_TOUCH_MOVED)
 listener:registerScriptHandler(function(touch)
  local use=armed and generation==v.worldGeneration and not moved and allowed() and contains(b,touch:getLocation(),w,h)
  if scroll then use=use and math.abs(scroll:getContentOffset().y-offset)<3 end
  reset();if use then action()end
 end,cc.Handler.EVENT_TOUCH_ENDED)
 listener:registerScriptHandler(reset,cc.Handler.EVENT_TOUCH_CANCELLED)
 b:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,b)
 b.worldReset=reset;b.worldAction=function()if allowed()then action()end end
 return b
end
local function chapter(index)return '第'..tostring(index)..'章'end
function S.known(v,index)return index<=v.mapMaxIndex end
function S.title(v,index)return S.known(v,index) and S.names[index] or '未探索海域'end
function S.purchaseInfo(v,index)
 local limit=tonumber(DataManager:getInstance():getRoleData(roleTranslateDoor))or 0
 if index>limit and index<=v.mapMaxIndex then return getMapShopInfoByMapIndex(limit+1)end
end
function S.status(v,index)
 if not S.known(v,index)then return '尚未开启',C.muted end
 if index==v.curMapIndex then return '当前海域',C.sea end
 local record=S.purchaseInfo(v,index)
 if record then return '需要扩展包',C.coral end
 local info=DataManager:getInstance():getRoleData(roleMapInfo)
 if tonumber(info.tipMapIndex)==index then return '新海域 · 可以前往',C.sea end
 return '可以前往',C.sea
end
local function cost(record)
 local n=record and tonumber(record.price)
 if n and n>=0 and n==n and n<math.huge then return n end
end
local function priceText(record)
 local n=cost(record);return n and ('钻石 × '..string.format('%.0f',n))or '价格暂不可用'
end
function S.updateScroll(v)
 local sc=v.scrollview;local visibleH=sc:getViewSize().height;local contentH=sc:getContainer():getContentSize().height
 local first=math.max(1,math.min(16,math.floor((sc:getContentOffset().y-visibleH+contentH)/v.worldRowHeight)+1))
 local last=math.min(16,math.ceil((contentH+sc:getContentOffset().y)/v.worldRowHeight))
 v.worldScrollText:setString('上下滑动 · '..first..' - '..last..' / 16');W.fit(v.worldScrollText,v.worldWidth-64)
 local range=contentH-visibleH;local ratio=range>0 and (sc:getContentOffset().y+range)/range or 0
 v.worldScrollThumb:setPositionY(v.worldListY+(visibleH-32)*(1-ratio))
end
local function displaySelection(v,index)
 v.worldSelection=index
 for i,row in ipairs(v.worldRows)do row.selected:setVisible(i==index)end
 local state,color=S.status(v,index);local record=S.purchaseInfo(v,index)
 v.worldSelectedChapter:setString(chapter(index)..' · '..S.title(v,index));W.fit(v.worldSelectedChapter,v.worldWidth-44)
 v.worldSelectedState:setString(state..(record and (' · '..priceText(record))or ''));v.worldSelectedState:setColor(color);W.fit(v.worldSelectedState,v.worldWidth-44)
 local caption=not S.known(v,index)and '尚未开启' or (record and '查看扩展包' or (index==v.curMapIndex and '重新进入' or '前往此海域'))
 v.worldPrimary.label:setString(caption);W.fit(v.worldPrimary.label,v.worldPrimary:getContentSize().width-20)
 v.worldPrimary:setEnabled(S.known(v,index))
end
function S.select(v,index)
 if not S.ready(v)or not S.names[index]then return end
 displaySelection(v,index)
end
function S.closeModal(v,lifecycleEvent)
 require('LuaClass/WarmShortageOwnership').retire(v,lifecycleEvent)
 local modal=v.worldModal;v.worldModal=nil;v.worldGeneration=v.worldGeneration+1
 if modal then modal:removeFromParent(true)end
end
function S.modal(v,title,body,actionTitle,action)
 if not S.alive(v)or v.worldModal then return end
 require('LuaClass/WarmShortageOwnership').retire(v)
 v.worldGeneration=v.worldGeneration+1;local generation=v.worldGeneration
 local w,h=v.worldWidth,v.worldHeight
 local modal=cc.LayerColor:create(cc.c4b(23,51,53,165),w,h);v.worldModal=modal;v:addChild(modal,200)
 local ph=260;local p=panel(modal,w-32,ph,C.paper,16,(h-ph)/2,10)
 text(p,title,24,C.ink,(w-32)/2,ph-36,w-60,.5)
 local bodyH=104;local bodyRoot=cc.Layer:create()
 local detail=text(bodyRoot,body,20,C.ink,0,0);detail:setAnchorPoint(cc.p(0,1));detail:setDimensions(cc.size(w-72,0));detail:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
 local contentH=math.max(bodyH,detail:getContentSize().height);bodyRoot:setContentSize(cc.size(w-72,contentH));detail:setPositionY(contentH)
 local bodyScroll=cc.ScrollView:create();bodyScroll:setPosition(cc.p(20,80));bodyScroll:setViewSize(cc.size(w-72,bodyH))
 bodyScroll:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL);bodyScroll:setClippingToBounds(true);bodyScroll:setBounceable(false);bodyScroll:setContainer(bodyRoot);bodyScroll:updateInset();bodyScroll:setContentOffset(cc.p(0,bodyH-contentH));p:addChild(bodyScroll,15);modal.worldBody=bodyScroll
 if contentH>bodyH then text(p,'上下滑动',12,C.muted,w-54,192,w-72,1)end
 local function live()return v.worldModal==modal and v.worldGeneration==generation end
 local function accept()
  if not live()then return end
  S.closeModal(v);action()
 end
 local function cancel()
  if not live()then return end
  S.closeModal(v);v.statue='ready';S.refresh(v)
 end
 local bw=(w-84)/2
 modal.confirm=button(v,p,bw,52,actionTitle,true,accept,live);modal.confirm:setPosition(cc.p(18,18))
 modal.cancel=button(v,p,bw,52,'取消',false,cancel,live);modal.cancel:setPosition(cc.p(34+bw,18))
 local shield=cc.EventListenerTouchOneByOne:create();shield:setSwallowTouches(true)
 shield:registerScriptHandler(function()return live()end,cc.Handler.EVENT_TOUCH_BEGAN)
 modal:getEventDispatcher():addEventListenerWithSceneGraphPriority(shield,modal)
 modal.worldAccept=accept;modal.worldCancel=cancel
 return modal
end
function S.confirm(v)
 if not S.ready(v)then return end
 local index=v.worldSelection;if not S.known(v,index)then return end
 -- Paid routes use the original move/check-only/showBuyView chain directly;
 -- the diamond deduction still requires its owned exact-price confirmation.
 if S.purchaseInfo(v,index)then v:moveToMapByIndex(index);return end
 S.modal(v,'确认目的地',chapter(index)..' · '..S.title(v,index)..'\n'..(index==v.curMapIndex and '重新进入当前海域。'or '准备前往这片已经开启的海域。'),'确认前往',function()
  if S.ready(v)then v:moveToMapByIndex(index)end
 end)
end
function S.buy(v)
 if not S.alive(v)then return end
 local record=v.lockMapInfo;local amount=cost(record)
 if not record or not amount then v.statue='ready';v.worldSelectedState:setString('当前无法前往');return end
 v.statue='Buy'
 local index=v.worldSelection
 return S.modal(v,'购买扩展包',chapter(index)..' · '..S.title(v,index)..'\n消耗'..priceText(record)..'\n购买后才能继续探索。','确认购买',function()
  if not S.alive(v)or v.statue~='Buy' or v.lockMapInfo~=record then return end
  if S.purchaseInfo(v,index)~=record or cost(record)~=amount then v.statue='ready';S.refresh(v);return end
  -- Keep the original exact virtual-currency transaction and unlock method.
  local presentation=require('LuaClass/WarmShortageOwnership').forOwner(v,'worldGeneration',function()return S.alive(v)end)
  if DataManager:getInstance():addDiamond(-amount,nil,nil,presentation)==1 then v:unlockAction()
  else v.statue='ready';S.refresh(v);v.worldSelectedState:setString('钻石不足 · '..priceText(record));W.fit(v.worldSelectedState,v.worldWidth-44)end
 end)
end
function S.charge(v)
 if not S.ready(v)then return end
 require('LuaClass/WarmShortageOwnership').retire(v)
 v.statue='charging';v.worldGeneration=v.worldGeneration+1
 local generation=v.worldGeneration;local charge=ChargeLayer:create();v.worldCharge=charge
 charge:setCancelCallback(function()
  if not S.alive(v)or generation~=v.worldGeneration or v.worldCharge~=charge then return end
  v.worldCharge=nil;v.statue='ready';charge:destory()
 end)
end
function S.travel(v,index)
 local generation=v.worldGeneration;v.worldSelectedState:setString('准备前往 · '..S.names[index]);W.fit(v.worldSelectedState,v.worldWidth-44)
 v:runAction(cc.Sequence:create(cc.DelayTime:create(.45),cc.CallFunc:create(function()
  if S.alive(v) and v.worldGeneration==generation and v.statue=='moveAction'then v:enterMapByIndex(index)end
 end)))
end
function S.afterBlockedEntry(v,index,tipBefore)
 if not S.alive(v)then return end
 local info=DataManager:getInstance():getRoleData(roleMapInfo)
 -- The original new-chapter story returns false after consuming tipMapIndex.
 -- That handoff still owns the transition. A late readiness denial consumes
 -- nothing; release only this presentation lock so Back/retry remains usable.
 if tipBefore==index and info.tipMapIndex~=index then return end
 v.statue='ready';S.refresh(v);v.worldSelectedState:setString('当前无法前往')
end
function S.unlock(v)
 if not S.alive(v)or v.statue~='Buy'then return end
 v:unlockMapDatas() -- unchanged authoritative save/economy semantics
 v.statue='ready';S.refresh(v)
end
function S.tip(v,index)
 local info=DataManager:getInstance():getRoleData(roleMapInfo)
 local faded=info.fadeMapFogIndex or 1
 if faded<index then info.fadeMapFogIndex=index;DataManager:getInstance():setRoleData(roleMapInfo,info)end
 v.tipMapIndex=index
end
function S.center(v)
 local sc=v.scrollview;local vh=sc:getViewSize().height;local ch=sc:getContainer():getContentSize().height
 local center=ch-(v.curMapIndex-.5)*v.worldRowHeight
 sc:setContentOffset(cc.p(0,math.max(vh-ch,math.min(0,vh*.5-center))))
 S.updateScroll(v)
end
function S.refresh(v)
 local info=DataManager:getInstance():getRoleData(roleMapInfo)
 v.mapMaxIndex=tonumber(info.mapIndex)or 0;v.curMapIndex=tonumber(info.curIndex)or 1
 v.willTipLock=false;local tip=tonumber(info.tipMapIndex)
 if tip and tip<=v.mapMaxIndex and DataManager:getInstance():getRoleData(roleTranslateDoor)+1==tip then
  v.willTipLock=true;v.lockMapInfo=getMapShopInfoByMapIndex(tip)
 end
 for i,row in ipairs(v.worldRows)do
  row.title:setString(S.title(v,i));W.fit(row.title,v.worldWidth-144)
  local status,color=S.status(v,i);row.status:setString(status);row.status:setColor(color)
  row.current:setVisible(i==v.curMapIndex);row.number:setVisible(i~=v.curMapIndex)
  row.title:setColor(S.known(v,i)and C.ink or C.muted)
 end
 v.worldCurrent:setString('当前 · '..S.names[v.curMapIndex]);W.fit(v.worldCurrent,v.worldWidth-48)
 displaySelection(v,v.worldSelection or v.curMapIndex)
end
function S.clear(v)
 S.refresh(v)
 local info=DataManager:getInstance():getRoleData(roleMapInfo)
 if info.tipMapIndex then S.tip(v,info.tipMapIndex)end
 S.center(v)
end
function S.build(v)
 local z=cc.Director:getInstance():getVisibleSize();local w,h=z.width,z.height
 v.coherentWorldSelector=true;v.worldWidth=w;v.worldHeight=h;v.worldGeneration=1;v.worldDisposed=false;v.statue='ready'
 v.buttons={};v.buttonTips={};v.buttonSprs={};v.ships={};v.fogs={};v.worldRows={}
 local data=DataManager:getInstance():getRoleData(roleMapInfo)
 v.mapMaxIndex=tonumber(data.mapIndex)or 0;v.curMapIndex=tonumber(data.curIndex)or 1;v.worldSelection=v.curMapIndex
 panel(v,w,h,cc.c3b(218,239,233),0,0,-100,0)
 text(v,'世界海图',28,C.ink,22,h-36,w-44)
 text(v,'选择已经开启的海域',15,C.muted,24,h-64,w-48)
 local heroH=math.min(208,math.max(152,h*.235));local heroY=h-88-heroH
 local prop=W.sprite(W.worldPath..'Events/worldchart-table-clean-v2.png',w*.88,heroH)
 if prop then prop:setPosition(cc.p(w*.52,heroY+heroH*.53));v:addChild(prop,-10)end
 v.worldProp=prop
 v.worldCurrent=text(v,'',17,C.ink,w/2,heroY+4,w-48,.5)
 local listY=174;local listTop=heroY-42;local listH=math.max(120,listTop-listY)
 v.worldListY=listY;v.worldRowHeight=68
 -- A single folded chart sheet and numbered itinerary, rather than a card grid.
 panel(v,w-28,listH+14,cc.c3b(144,180,169),16,listY-7,-32)
 panel(v,w-28,listH+14,C.paper,12,listY-3,-30)
 local container=cc.Layer:create();container:setContentSize(cc.size(w-40,16*v.worldRowHeight))
 local scroll=cc.ScrollView:create();v.scrollview=scroll;scroll:setPosition(cc.p(20,listY));scroll:setViewSize(cc.size(w-46,listH))
 scroll:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL);scroll:setClippingToBounds(true);scroll:setBounceable(false);scroll:setContainer(container);scroll:setDelegate();scroll:updateInset();v:addChild(scroll,10)
 panel(container,2,16*v.worldRowHeight-40,cc.c3b(215,199,154),27,20,-20,0)
 for i=1,16 do
  local row=button(v,container,w-48,v.worldRowHeight,'',false,function()S.select(v,i)end,function()return S.ready(v)end,scroll)
  row.face:setVisible(false);row.pressed:setVisible(false);row:setPosition(cc.p(0,(16-i)*v.worldRowHeight))
  row.selected=panel(row,w-54,v.worldRowHeight-6,cc.c3b(230,237,212),0,3,-18);row.selected:setVisible(false)
  panel(row,36,36,S.known(v,i)and cc.c3b(243,210,134)or cc.c3b(229,227,210),10,16,-16)
  row.number=text(row,tostring(i),18,C.ink,28,34,30,.5)
  row.current=W.icon('sail',29,C.sea);row.current:setPosition(cc.p(13,20));row:addChild(row.current,12)
  row.title=text(row,S.title(v,i),21,C.ink,60,43,w-144)
  row.status=text(row,'',14,C.muted,60,19,w-116)
  panel(row,w-120,1,C.line,60,1,-17,0)
  v.worldRows[i]=row
 end
 v.worldScrollText=text(v,'',14,C.muted,w/2,listTop+24,w-64,.5)
 panel(v,3,listH,C.line,w-22,listY,15,0)
 v.worldScrollThumb=panel(v,3,32,C.gold,w-22,listY,16,0)
 scroll:registerScriptHandler(function()S.updateScroll(v)end,cc.SCROLLVIEW_SCRIPT_SCROLL)
 panel(v,w,158,C.paper,0,0,25,0)
 v.worldSelectedChapter=text(v,'',20,C.ink,22,132,w-44)
 v.worldSelectedChapter:setLocalZOrder(30)
 v.worldSelectedState=text(v,'',15,C.muted,22,105,w-44);v.worldSelectedState:setLocalZOrder(30)
 local dock=cc.Node:create();v:addChild(dock,40);v.worldDock=dock
 local backW=math.max(100,w*.32)
 v.worldBack=button(v,dock,backW,54,'返回海域',false,function()v:backToCurMap()end,function()return S.ready(v)end);v.worldBack:setPosition(cc.p(18,22))
 v.worldPrimary=button(v,dock,w-backW-48,54,'前往此海域',true,function()S.confirm(v)end,function()return S.ready(v)end);v.worldPrimary:setPosition(cc.p(backW+30,22))
 local shield=cc.EventListenerTouchOneByOne:create();shield:setSwallowTouches(true)
 shield:registerScriptHandler(function()return visible(v)end,cc.Handler.EVENT_TOUCH_BEGAN);v:getEventDispatcher():addEventListenerWithSceneGraphPriority(shield,v)
 v:registerScriptHandler(function(event)
  if event=='cleanup' and v.owner and v.owner.worldMapLayer==v then v.owner.worldMapLayer=nil end
  if event=='enter'then v.worldSuspended=false;v.worldManagedOwner=v.worldManagedOwner or (v.owner and v.owner.worldMapLayer==v);S.refresh(v)end
  if event=='exit' or event=='cleanup'then
   v.worldSuspended=true;v.worldDisposed=event=='cleanup';v.worldGeneration=v.worldGeneration+1;v:stopAllActions();S.closeModal(v,event)
   if v.worldCharge then local charge=v.worldCharge;v.worldCharge=nil;charge:destory()end
   if not v.worldDisposed and (v.statue=='Buy' or v.statue=='charging' or v.statue=='moveAction')then v.statue='ready'end
  end
 end)
 S.clear(v);return true
end
return S
