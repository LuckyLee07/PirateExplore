-- Defeat/revive presentation only. The original 50-diamond transaction, safe
-- event return and loss callback remain the only owners of gameplay changes.
local W=require 'LuaClass/WarmTheme'
local R={}
local C=W.colors
local function notify(text)if ToastUtil then ToastUtil:toastString(text)end end
local function stopActions(node)
 node:stopAllActions();node:unscheduleUpdate()
 for _,child in ipairs(node:getChildren())do stopActions(child)end
end
local function retireGift(gift)
 if gift.warmRetired then return end
 gift.warmRetired=true
 gift.serviceClosed=true;gift:setVisible(false);stopActions(gift)
 gift:getEventDispatcher():removeEventListenersForTarget(gift,true)
 -- removeView only updates Lua entries and hides an empty mask; unlike
 -- releaseEmptyMask it never erases a scene sibling during native traversal.
 if gift._dialogueEntry then DialogueViewManager:sharedInstance():removeView(gift)end
 if not gift.warmRetirementQueued then
  gift.warmRetirementQueued=true
  gift:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function()
   if gift:getParent()then gift:removeFromParent(true)end
  end)))
 end
end
local function showGift(state,gift,depth)
 if not gift then return end
 state.gift=gift
 local token=cc.Node:create();gift:addChild(token)
 token:registerScriptHandler(function(event)
  if event=='exit'or event=='cleanup'then
   -- A gift may exit before its owner when the scene is merely suspended.
   retireGift(gift)
   if state.gift==gift then state.gift=nil end
  end
 end)
 gift:show(depth)
 if not gift:getParent()then state.gift=nil end
end
local function stateFor(owner)
 if owner.warmRecoveryState then return owner.warmRecoveryState end
 local state={scene=cc.Director:getInstance():getRunningScene(),mode='choice',disposed=false,done=false,busy=false}
 owner.warmRecoveryState=state
 -- Per-call presentation ownership only; ordinary DataManager callers retain
 -- their scene-owned shortage UI. Busy is expected during the debit attempt.
 local function active()
  return not state.disposed and not state.done and owner:getParent()~=nil
   and cc.Director:getInstance():getRunningScene()==state.scene
 end
 state.shortagePresentation={owner=owner,isActive=active,showGift=function(gift,depth)
  if active()then showGift(state,gift,depth)end
 end}
 local token=cc.Node:create();owner:addChild(token)
 token:registerScriptHandler(function(event)
  if event~='exit'and event~='cleanup'then return end
  state.disposed=true
  -- A running parent also caches child indices during individual removal.
  -- Retire siblings immediately, but defer physical removal to a safe tick.
  if state.gift then
   local gift=state.gift;state.gift=nil;retireGift(gift)
  end
 end)
 return state
end
local function live(owner,state)
 return not state.disposed and not state.done and not state.busy
  and owner:getParent()~=nil and cc.Director:getInstance():getRunningScene()==state.scene
end
local function blocked(state)
 if state.scene.adventureDialog then return true end
 local dialogs=state.scene._dialogueViewState
 if dialogs and #dialogs.entries>0 then return true end
 if state.gift and state.gift:getParent()then return true end
 for _,child in ipairs(state.scene:getChildren())do
  if child.isAdventureModal or child.s_bg then return true end
 end
 return false
end
local function makeLayer(owner,state,modal)
 local size=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin()
 local k=math.min(size.width/480,size.height/800)
 local layer=cc.LayerColor:create(modal and cc.c4b(25,49,52,100)or cc.c4b(110,203,201,255),size.width,size.height)
 layer.isAdventureModal=true;layer.closed=false;layer.buttons={};state.ui=layer
 owner:addChild(layer,2000)
 local canvas=cc.Node:create();canvas:setContentSize(cc.size(480,800));canvas:setScale(k)
 canvas:setPosition(cc.p(origin.x+(size.width-480*k)/2,origin.y+(size.height-800*k)/2));layer:addChild(canvas);layer.canvas=canvas
 local touch=cc.EventListenerTouchOneByOne:create();touch:setSwallowTouches(true)
 touch:registerScriptHandler(function()return not layer.closed end,cc.Handler.EVENT_TOUCH_BEGAN)
 layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(touch,layer)
 local function dispose()
  if layer.closed then return end
  layer.closed=true;layer:unscheduleUpdate()
  if state.ui==layer then state.ui=nil end
  layer:getEventDispatcher():removeEventListener(touch)
 end
 function layer:close()if not self.closed then dispose();self:removeFromParent(true)end end
 layer:registerScriptHandler(function(event)if event=='exit'or event=='cleanup'then dispose()end end)
 local function add(node,x,y)node:setPosition(cc.p(x,y));canvas:addChild(node);return node end
 local function text(value,size,x,y,width,color)
  local n=W.label(value,size,color or C.ink,x,y,false,0)
  n:setDimensions(cc.size(width,0));n:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT);canvas:addChild(n);return n
 end
 local function button(key,title,x,y,width,height,action,primary)
  local b=W.button(title,width,height,function()
   if layer.closed or state.ui~=layer or not live(owner,state)or blocked(state)then return end
   action()
  end,{size=21,primary=primary});layer.buttons[key]=add(b,x,y);return b
 end
 return layer,add,text,button
end
function R.choice(owner)
 if rawget(_G,'WARM_PIRATE_V1')==false then return nil end
 local state=stateFor(owner)
 if state.disposed or state.done or state.mode~='choice'then return nil end
 if state.ui then return state.ui end
 local layer,add,text,button=makeLayer(owner,state,true)
 local eternal=owner.fightFailType==FightScene.FightFailType.eternal
 add(W.panel(432,488,C.paper,8),24,156)
 text('这次交锋失利',28,48,602,384)
 text('船员已无法继续战斗。',20,48,562,384,C.muted)
 local body=eternal and '结束挑战后，本次挑战奖励将被收回。'
  or '结束航程后：\n战败船员可在复活据点查看；\n普通货舱物资和海上金币不带回。\n任务物品例外按原规则处理。'
 local description=text(body,19,48,522,384);description:setAnchorPoint(cc.p(0,1))
 text('复活返回当前据点，需 50 钻石。',19,48,392,384,C.muted)
 local balanceText=text('',19,48,360,384,C.muted)
 local function decline()
  state.busy=true;layer:close();state.busy=false
  owner:showFailInfoAndReturn()
 end
 button('return',eternal and '结束挑战' or '结束航程',240,296,384,64,decline,true)
 local revive=button('revive','50 钻石复活',240,219,384,60,function()
  layer:refreshAffordance()
  local explor=getExplor and getExplor()
  local target=explor and explor.eventManger and explor.eventManger.layer
  if not target or type(target.safeBackToLayer)~='function'then notify('当前战斗已结束，请选择结束航程。');return end
  state.busy=true
  -- Exact existing debit and shortage route; failure leaves this choice open.
  if DataManager:getInstance():addDiamond(-50,true,nil,state.shortagePresentation)~=1 then state.busy=false;return end
  state.done=true;layer:close()
  target:safeBackToLayer()
 end,false)
 local lastBalance
 function layer:refreshAffordance()
  if self.closed then return end
  local balance=math.max(0,tonumber(DataManager:getInstance():getRoleData(roleDiamond))or 0)
  if balance==lastBalance then return end
  lastBalance=balance;self.reviveAffordable=balance>=50
  balanceText:setString('现有 '..balance..' 钻石'..(balance<50 and ('，还差 '..(50-balance)..' 钻石。')or '。'))
  revive.label:setString(balance>=50 and '50 钻石复活'or '钻石不足 · 查看说明')
  revive.label:setColor(balance>=50 and C.ink or C.muted)
  revive.item:setNormalImage(W.panel(384,60,balance>=50 and C.paper or C.line,8))
 end
 layer:refreshAffordance()
 layer:scheduleUpdateWithPriorityLua(function()layer:refreshAffordance()end,0)
 return layer
end
function R.result(owner)
 if rawget(_G,'WARM_PIRATE_V1')==false then return nil end
 local state=stateFor(owner)
 if state.disposed or state.done then return nil end
 if state.mode=='result'and state.ui then return state.ui end
 if state.ui then state.ui:close()end
 state.mode='result'
 local layer,add,text,button=makeLayer(owner,state,false)
 local size=cc.Director:getInstance():getVisibleSize()
 local sea=W.cover(W.worldPath..'sea-turquoise-caustics.png',size.width,size.height)
 if sea then layer:addChild(sea);layer.canvas:setLocalZOrder(1)end
 add(W.panel(432,122,C.paper,8),24,650)
 local eternal=owner.fightFailType==FightScene.FightFailType.eternal
 text(eternal and '挑战失利' or '本次航程失利',31,48,730,384)
 text(eternal and '本次挑战奖励将被收回。'or '战斗已结束，准备回港结算。',20,48,687,384,C.muted)
 -- Reuse the battle's empty clean deck. The map boat contains two painted
 -- people, so it would falsely depict surviving crew after this loss.
 local deck=W.sprite(W.worldPath..'Combat/boarding-deck-clean-v1.png',432,384)
 if deck then add(deck,240,452)end
 add(W.panel(432,386,C.paper,8),24,28)
 text(eternal and '收整行装，稍后再战' or '先回港，重新整备',25,48,379,384)
 local consequence=eternal and '本次挑战未能完成。\n即将按原规则返回。'
  or '战败船员可在复活据点查看；\n普通货舱物资和海上金币不带回。\n任务物品例外按原规则处理。'
 local detail=text(consequence,19,48,339,384);detail:setAnchorPoint(cc.p(0,1))
 local advice=text(eternal and '提升船员与战船后，再来挑战。'or '回港后可招募船员、补装食物。\n再次出航前，先查看据点难度。',19,48,242,384,C.muted);advice:setAnchorPoint(cc.p(0,1))
 local callback=owner.fightOverCallback;local result=owner.fightResult
 local function complete()
  if layer.closed or state.done or state.disposed then return end
  state.done=true;state.busy=true
  if callback then callback(result)end
 end
 if eternal then
  text('即将返回…',22,48,144,384,C.sea)
  -- Original eternal loss: one-second fade then one-second hold, then callback.
  layer:runAction(cc.Sequence:create(cc.DelayTime:create(2),cc.CallFunc:create(complete)))
 else
  button('return','回港整备',240,150,384,64,complete,true)
  button('gift','查看付费礼包（可选）',240,76,384,60,function()
   state.busy=true
   showGift(state,PushGiftView:create())
   state.busy=false
  end,false)
 end
 return layer
end
return R
