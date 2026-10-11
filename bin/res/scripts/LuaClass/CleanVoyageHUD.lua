-- Compact map-one chrome. Buttons delegate to the original production actions.
local H={font='fonts/CleanVoyageSans-Regular.ttf'}
function H.canAct(owner,view)
 if not owner or owner.statue~='ready' or owner.adventureDialog or owner.warmPause or owner.warmSettingsModal
  or (view and view.animating) or (owner.jointed and owner.jointed.enable==false) then return false end
 if #(owner.moveWaitingQueue or {})>0 or #(owner.moveDirectionQueue or {})>0 then return false end
 local events=owner.eventManger
 if events and (events.isMinesweeper or (events.layer and events.layer:isVisible())) then return false end
 return true
end
function H.guarded(owner,view,callback)
 return function(...)
  if not H.canAct(owner,view) then return false end
  return callback(...)
 end
end
local function text(value,size,parent,x,y)
 local n=cc.LabelTTF:create(value,H.font,size);n:setPosition(cc.p(x,y));n:setColor(cc.c3b(38,65,68));parent:addChild(n,2);return n
end
local function panel(parent,x,y,w,h)
 local n=cc.LayerColor:create(cc.c4b(255,247,229,244),w,h);n:setPosition(cc.p(x,y));parent:addChild(n);return n
end
local function button(parent,value,x,y,w,h,size,callback)
 local bg=panel(parent,x-w/2,y-h/2,w,h)
 local label=text(value,size,bg,w/2,h/2)
 local item=cc.MenuItemLabel:create(cc.LabelTTF:create('',H.font,size));item:setContentSize(cc.size(w,h));item:setPosition(cc.p(x,y));item:registerScriptTapHandler(callback)
 local menu=cc.Menu:create(item);menu:setPosition(cc.p(0,0));parent:addChild(menu,3)
 return label,item
end
function H.mount(owner,view)
 local size=screenSize or cc.Director:getInstance():getVisibleSize();local u=view.u
 local node=cc.Node:create();view.node:addChild(node,20);view.hud=node
 local top=size.height-48*u
 local food=panel(node,20*u,top-28*u,160*u,56*u);view.foodLabel=text('',25*u,food,80*u,28*u)
 local cargo=panel(node,194*u,top-28*u,172*u,56*u);view.cargoLabel=text('',21*u,cargo,86*u,28*u)
 button(node,'暂歇',size.width-65*u,top,90*u,56*u,21*u,H.guarded(owner,view,function()require('LuaClass/WarmPause').open(owner)end))
 local hint=panel(node,20*u,87*u,size.width-40*u,66*u)
 view.goalLabel=text('',21*u,hint,(size.width-40*u)/2,41*u)
 view.routeLabel=text('',17*u,hint,(size.width-40*u)/2,16*u)
 local hintItem=cc.MenuItemLabel:create(cc.LabelTTF:create('',H.font,20*u));hintItem:setContentSize(cc.size(size.width-40*u,66*u));hintItem:setPosition(cc.p(size.width/2,120*u))
 hintItem:registerScriptTapHandler(H.guarded(owner,view,function()
  if not require('LuaClass/AdventureSea').tryEvent(owner,true) then require('LuaClass/AdventureProgress').showHarborBrief(DataManager:getInstance(),owner) end
 end))
 local hintMenu=cc.Menu:create(hintItem);hintMenu:setPosition(cc.p(0,0));node:addChild(hintMenu,3)
 button(node,'货舱',80*u,40*u,120*u,54*u,22*u,H.guarded(owner,view,function()owner:goBag()end))
 button(node,'航图',224*u,40*u,120*u,54*u,22*u,H.guarded(owner,view,function()
  local title='海图 '..tostring(owner.mapIndex)..' · 已探索'..tostring(owner.extent or 0)..'%'
  require('LuaClass/AdventureDialog').show(title,'逐格航行，沿已探明的海路返港。',{
   {label='查看本航目标',action=function()owner:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function()require('LuaClass/AdventureProgress').showHarborBrief(DataManager:getInstance(),owner)end)))end},
   {label='查看地图攻略',action=function()owner:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function()owner:showCurMapStrategy()end)))end},
   {label='继续航行'}},owner)
 end))
 button(node,'返航',size.width-90*u,40*u,140*u,54*u,22*u,H.guarded(owner,view,function()
  if owner.adventureReturnButton and owner.adventureReturnButton.item then owner.adventureReturnButton.item:activate() end
 end))
 owner.tipLayer:setVisible(false)
end
function H.refresh(owner,view)
 if not view.foodLabel then return end
 local dm=DataManager:getInstance();local A=require('LuaClass/AdventureProgress');local s=A.getState(dm)
 local route=require('LuaClass/AdventureNavigation').query(owner,{breadCoefficient=owner.adventureBreadCoefficient or 0})
 local food=owner.bagController:getBreads()
 view.hudFood=food;view.hudCost=owner.bagController.costSpace;view.hudLimit=owner.bagController.limited
 view.foodLabel:setString('口粮 '..tostring(food))
 view.foodLabel:setColor(food<10 and cc.c3b(187,85,58) or cc.c3b(38,65,68))
 view.cargoLabel:setString('货舱 '..tostring(owner.bagController.costSpace or 0)..'/'..tostring(owner.bagController.limited or 0))
 local goal='点击相邻海格，向迷雾前进'
 if s.pending then goal='成果已装船 · 安全带回港口'
 elseif s.tutorialPoint and A.availableEpisode(dm) then
  local p=owner.playerTitlePosition;local target=s.tutorialPoint
  if p.x==target.x and p.y==target.y then goal='已到沉船 · 点击这里选择行动'
  else goal='探索近港沉船 · 点击相邻海格航行' end
 end
 local hint
 if route.status=='at_port' then hint='港口入格免费 · 再次抵达即安全返港'
 elseif route.status=='ok' then hint='返港 '..route.direction..' · '..route.steps..'步 · 航行最低'..route.minimumFood..'粮'
 else hint='返港仅沿已探明的可通行海路' end
 view.goalLabel:setString(goal);view.routeLabel:setString(hint)
 for _,l in ipairs({view.goalLabel,view.routeLabel}) do local w=l:getContentSize().width;l:setScale(math.min(1,(screenSize.width-68*view.u)/math.max(1,w))) end
end
return H
