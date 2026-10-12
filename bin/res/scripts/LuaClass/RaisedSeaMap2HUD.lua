-- Compact map2 presentation over existing actions and read-only route queries.
-- No gameplay rules or saved state are owned here.
local W=require 'LuaClass/WarmTheme'
local H={font=W.font}
local ink=cc.c3b(38,65,68);local warning=cc.c3b(187,85,58)
local hitOwners=setmetatable({},{__mode='k'});local hitOriginal,hitWrapper
local function hook(target,name,make)
 local peer=tolua.getpeer(target);local saved=peer and rawget(peer,name)
 local replacement=make(target[name]);target[name]=replacement
 return function()if target[name]==replacement then target[name]=saved end end
end
local function active(h)
 return h and not h.disposed and h.owner.raisedMap2Live==h.state and h.root:isRunning()
end
local function blocked(owner)
 return owner.adventureDialog or owner.warmPause or owner.warmSettingsModal or owner.warmCollection or owner.warmActivity
  or (owner.eventManger and (owner.eventManger.isMinesweeper or (owner.eventManger.layer and owner.eventManger.layer:isVisible())))
end
function H.canAct(h)
 return active(h) and h.root:isVisible() and h.owner:isVisible() and h.requestedVisible and not blocked(h.owner) and require('LuaClass/CleanVoyageHUD').canAct(h.owner)
end
-- A gesture belongs to the uninterrupted HUD generation that accepted BEGIN.
-- Native cc.Menu retains its selected item across hide/show, so readiness at
-- END alone is insufficient. Only these new HUD controls use this local lease.
function H.invalidate(h)
 if not h or h.disposed then return end
 h.generation=(h.generation or 0)+1
 for _,b in pairs(h.buttons or{})do if b.cancelGesture then b.cancelGesture()end end
 h.held=nil
end
local function touchButton(h,b)
 b.menu:setEnabled(false)
 local held
 local function cancel()
  if h.held==held then h.held=nil end
  held=nil;b.item:unselected()
 end
 local function inside(touch)
  local p=b.item:convertToNodeSpace(touch:getLocation());local size=b.item:getContentSize()
  return p.x>=0 and p.y>=0 and p.x<=size.width and p.y<=size.height
 end
 local listener=cc.EventListenerTouchOneByOne:create();listener:setSwallowTouches(true)
 listener:registerScriptHandler(function(touch)
  if h.held or not H.canAct(h)or not b.item:isEnabled()or not inside(touch)then return false end
  held={generation=h.generation,touch=touch,start=touch:getLocation()};h.held=held;b.item:selected();return true
 end,cc.Handler.EVENT_TOUCH_BEGAN)
 listener:registerScriptHandler(function(touch)
  if not held or held.touch~=touch then return end
  local p=touch:getLocation()
  if not inside(touch)or math.abs(p.x-held.start.x)>=20 or math.abs(p.y-held.start.y)>=20 then cancel()end
 end,cc.Handler.EVENT_TOUCH_MOVED)
 listener:registerScriptHandler(function(touch)
  if not held or held.touch~=touch then return end
  local p=touch:getLocation()
  local accepted=held.generation==h.generation and H.canAct(h)and inside(touch)
   and math.abs(p.x-held.start.x)<20 and math.abs(p.y-held.start.y)<20
  cancel();if accepted then b.item:activate()end
 end,cc.Handler.EVENT_TOUCH_ENDED)
 listener:registerScriptHandler(function(touch)if held and held.touch==touch then cancel()end end,cc.Handler.EVENT_TOUCH_CANCELLED)
 b.node:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,b.node)
 b.listener,b.cancelGesture=listener,cancel
end
local function guard(h,callback)
 return function(...)if H.canAct(h)then return callback(...)end;return false end
end
local function panel(parent,x,y,w,h)
 local n=W.panel(w,h,W.colors.paper,8);n:setPosition(cc.p(x,y));parent:addChild(n);return n
end
local function label(parent,value,size,x,y)
 local n=W.label(value,size,ink,x,y,false,.5);parent:addChild(n,2);return n
end
local function fit(n,width)
 n:setScale(math.min(1,width/math.max(1,n:getContentSize().width)))
end
local function button(h,key,value,x,y,w,height,size,callback)
 local u=h.u;local b=W.button(value,w*u,height*u,guard(h,callback),{size=size*u})
 b:setPosition(cc.p(x*u,y*u));h.root:addChild(b,3)
 h.buttons[key]={item=b.item,label=b.label,backing=b.item,node=b,menu=b.menu};touchButton(h,h.buttons[key]);return h.buttons[key]
end
-- An unmistakable shaft and narrow, forward head. Coordinates are authored in
-- the actual projected direction, not a rotated near-equilateral triangle.
function H.arrowPoints(dx,dy,u)
 local len=math.sqrt(dx*dx+dy*dy);dx,dy=dx/len,dy/len
 local points={};for _,p in ipairs({{-16,-4},{3,-4},{3,-10},{18,0},{3,10},{3,4},{-16,4}})do
  points[#points+1]=cc.p((p[1]*dx-p[2]*dy)*u,(p[1]*dy+p[2]*dx)*u)
 end;return points
end
local function arrow(h,key,direction,x,y,dx,dy)
 local source
 for _,entry in ipairs(h.owner.raisedMap2Arrows or{})do if entry.direction==direction then source=entry.button;break end end
 if not source then return end
 local b=button(h,key,'',x,y,58,52,18,function()source:activate()end)
 local d=cc.DrawNode:create();local p=H.arrowPoints(dx,dy,h.u);local c=cc.c4f(38/255,65/255,68/255,1)
 d:drawTriangle(p[1],p[2],p[6],c);d:drawTriangle(p[1],p[6],p[7],c)
 d:drawTriangle(p[3],p[4],p[5],c);d:setPosition(cc.p(29*h.u,26*h.u));b.backing:addChild(d,3);b.arrow=d;b.direction=direction
 local dispatcher=d:getEventDispatcher();d:registerScriptHandler(function(event)if event=='exit'then dispatcher:resumeEventListenersForTarget(d)end end)
end
function H.contains(h,p)
 if not active(h)or not h.requestedVisible then return false end
 return p.x>=0 and p.x<=h.width and (p.y<=204*h.u or p.y>=h.height-92*h.u)
end
local function installHit(h)
 local sea=require('LuaClass/AdventureSea');hitOwners[h.owner]=h
 if not hitWrapper then
  hitOriginal=sea.isHudPoint;local previous=hitOriginal
  hitWrapper=function(owner,p)
   local leased=hitOwners[owner]
   if leased and active(leased)then return H.contains(leased,p)end
   return previous(owner,p)
  end
  sea.isHudPoint=hitWrapper
 end
end
local function releaseHit(h)
 if hitOwners[h.owner]==h then hitOwners[h.owner]=nil end
 if next(hitOwners)==nil and hitWrapper then
  local sea=require('LuaClass/AdventureSea')
  if sea.isHudPoint==hitWrapper then sea.isHudPoint=hitOriginal;hitWrapper=nil;hitOriginal=nil end
 end
end
local function later(h,callback)
 h.owner:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function()
  if H.canAct(h)then callback()end
 end)))
end
function H.details(h)
 if not H.canAct(h)then return end
 local owner=h.owner;local route=require('LuaClass/AdventureNavigation').query(owner,{breadCoefficient=owner.adventureBreadCoefficient or 0})
 local title,detail=require('LuaClass/AdventureNavigationView').lines(route)
 local objective=owner.adventureObjectiveLabel and owner.adventureObjectiveLabel:getString()or '继续揭雾，确认本章航路。'
 local patrol=owner.adventurePatrolLabel and owner.adventurePatrolLabel:getString()or '随机遭遇、粮耗和据点战斗按原规则进行。'
 return require('LuaClass/AdventureDialog').show('海图 '..tostring(owner.mapIndex)..' · 已探索'..tostring(owner.extent or 0)..'%',
  title..'\n'..detail..'\n'..objective..'\n'..patrol,{
   {label='查看本航目标',action=function()later(h,function()require('LuaClass/AdventureProgress').showHarborBrief(DataManager:getInstance(),owner)end)end},
   {label='查看地图攻略',action=function()later(h,function()owner:showCurMapStrategy()end)end},
   {label='继续航行'}},owner)
end
function H.sync(h)
 if not h or h.disposed then return end
 local owner=h.owner;local visible=h.requestedVisible and not blocked(owner)or false
 if h.root:isVisible()~=visible or not H.canAct(h)then H.invalidate(h)end
 h.root:setVisible(visible)
 local bag=owner.bagController;if not bag then return end
 local name=owner.mapName or (owner.nameTitle and owner.nameTitle:getString())or ''
 h.statusLabel:setString('第'..tostring(owner.mapIndex)..'章'..(name~='' and ' · '..name or '')..' · 探索'..tostring(owner.extent or 0)..'%');fit(h.statusLabel,330*h.u)
 local food=bag:getBreads();h.foodLabel:setString('口粮 '..tostring(food));h.foodLabel:setColor(food<=10 and warning or ink)
 h.cargoLabel:setString('货舱'..tostring(bag.costSpace or 0)..'/'..tostring(bag.limited or 0));fit(h.cargoLabel,152*h.u)
 local position=owner.playerTitlePosition or{}
 local key=table.concat({tostring(position.x),tostring(position.y),tostring(food),tostring(owner.extent),tostring(owner.adventureBreadCoefficient)},':')
 -- Discovery and event updates can change a route without moving the ship.
 local objective=owner.adventureObjectiveLabel and owner.adventureObjectiveLabel:getString()or''
 if key~=h.readKey or objective~=h.objective or h.state.dirty then
  h.readKey,h.objective=key,objective
  h.route=require('LuaClass/AdventureNavigation').query(owner,{breadCoefficient=owner.adventureBreadCoefficient or 0})
 end
 local route=h.route or{}
 local goal='点击海面或方向，继续探索'
 local s=require('LuaClass/AdventureProgress').getState(DataManager:getInstance())
 if s.pending then goal='成果已装船 · 安全带回港口'end
 if food<=10 then goal='口粮偏少 · 优先返港补给'end
 if route.foodShortfall and route.foodShortfall>0 then goal='返港口粮不足 · 查看航图详情'end
 local hint
 if route.status=='at_port'then hint='已在出发港 · 再次抵达可返航'
 elseif route.status=='ok'then hint='返港 '..route.direction..' · '..route.steps..'步 · 航行最低'..route.minimumFood..'粮'
 else hint='返港路线未明 · 查看航图详情'end
 h.goalLabel:setString(goal);h.goalLabel:setColor(food<=10 and warning or ink);h.routeLabel:setString(hint)
 fit(h.goalLabel,424*h.u);fit(h.routeLabel,424*h.u)
end
function H.create(owner,state)
 if not owner.tipLayer then return nil end
 local size=screenSize or cc.Director:getInstance():getVisibleSize();local u=size.width/640
 local h={owner=owner,state=state,u=u,width=size.width,height=size.height,buttons={},generation=0,requestedVisible=owner.tipLayer:isVisible()}
 local root=cc.Node:create();h.root=root;root:retain();owner:addChild(root,21)
 local top=size.height/u-48
 local food=panel(root,20*u,(top-28)*u,160*u,56*u);h.foodLabel=label(food,'',25*u,80*u,28*u)
 local cargo=panel(root,194*u,(top-28)*u,172*u,56*u);h.cargoLabel=label(cargo,'',21*u,86*u,28*u)
 button(h,'pause','暂歇',575,top,90,56,21,function()require('LuaClass/WarmPause').open(owner)end)
 local status=panel(root,20*u,(top-76)*u,346*u,31*u);h.statusLabel=label(status,'',17*u,173*u,15.5*u)
 local hint=panel(root,20*u,88*u,450*u,106*u)
 h.goalLabel=label(hint,'',21*u,225*u,70*u);h.routeLabel=label(hint,'',18*u,225*u,32*u)
 button(h,'cargo','货舱',84,40,128,54,22,function()owner:goBag()end)
 button(h,'chart','航图',236,40,128,54,22,function()H.details(h)end)
 button(h,'log','日志',388,40,128,54,22,function()require('LuaClass/WarmCollection').open(owner,'log')end)
 button(h,'return','返航',552,40,136,54,22,function()
  if owner.adventureReturnButton and owner.adventureReturnButton.item then owner.adventureReturnButton.item:activate()end
 end)
 arrow(h,'nw',LeftDirction,519,170,-1,.56);arrow(h,'ne',UpDiriction,585,170,1,.56)
 arrow(h,'sw',BottomDirction,519,110,-1,-.56);arrow(h,'se',RightDircion,585,110,1,-.56)
 h.nativeVisible=owner.tipLayer.setVisible
 h.restoreVisibility=hook(owner.tipLayer,'setVisible',function(native)return function(target,visible,...)
  if h.disposed then return native(target,visible,...)end
  if h.requestedVisible~=visible then H.invalidate(h)end
  h.requestedVisible=visible;h.root:setVisible(visible and not blocked(owner));return native(target,false,...)
 end end)
 -- Modal families attach their overlay or lifecycle observer to the owner.
 -- Observe that synchronous boundary so even open/close between updates retires
 -- a held gesture. This changes no native child, callback or ownership field.
 h.restoreOwnerAdd=hook(owner,'addChild',function(native)return function(target,...)
  if h.held then H.invalidate(h)end;return native(target,...)
 end end)
 h.restoreOwnerVisibility=hook(owner,'setVisible',function(native)return function(target,visible,...)
  if target:isVisible()~=visible then H.invalidate(h)end;return native(target,visible,...)
 end end)
 local events=owner.eventManger and owner.eventManger.layer
 if events then h.restoreEventVisibility=hook(events,'setVisible',function(native)return function(target,visible,...)
  if target:isVisible()~=visible then H.invalidate(h)end;return native(target,visible,...)
 end end)end
 root:registerScriptHandler(function(event)if event=='exit'or event=='cleanup'then H.invalidate(h)end end)
 local function restoreDrawListeners(n)
  if tolua.type(n)=='cc.DrawNode'then
   local dispatcher=n:getEventDispatcher();n:registerScriptHandler(function(event)if event=='exit'then dispatcher:resumeEventListenersForTarget(n)end end)
  end
  for _,child in ipairs(n:getChildren())do restoreDrawListeners(child)end
 end
 restoreDrawListeners(root)
 h.nativeVisible(owner.tipLayer,false);installHit(h);H.sync(h)
 return h
end
function H.dispose(h,cleanup)
 if not h or h.disposed then return end;H.invalidate(h);h.disposed=true
 for _,b in pairs(h.buttons)do b.node:getEventDispatcher():removeEventListener(b.listener)end
 h.restoreOwnerAdd();h.restoreOwnerVisibility();if h.restoreEventVisibility then h.restoreEventVisibility()end
 releaseHit(h);h.restoreVisibility();h.nativeVisible(h.owner.tipLayer,h.requestedVisible)
 if not cleanup then h.root:removeFromParent(true)end;h.root:release()
 h.owner=nil;h.state=nil;h.buttons=nil;h.root=nil
end
return H
