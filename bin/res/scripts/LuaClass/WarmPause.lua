-- Sailing pause/checkpoint UI. No departure, reward, loss, fee or return rule is
-- implemented here; Leave always delegates to Explore's existing return button.
local W=require 'LuaClass/WarmTheme'
local P={}
local function copy(t)
 if type(t)~='table'then return t end
 local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r
end
local function finite(n)return type(n)=='number' and n==n and n>=0 and n<9007199254740991 end
function P.canOpen(owner)
 if not owner or owner.warmPauseDisposed or owner.statue~='ready' or owner.isHungry or owner.isNeedGuide then return false end
 if owner.adventureDialog or owner.warmSettingsModal then return false end
 if (tonumber(rawget(_G,'touchcount')) or 0)>0 or (owner.jointed and owner.jointed.enable==false) then return false end
 if #(owner.moveWaitingQueue or{})>0 or #(owner.moveDirectionQueue or{})>0 then return false end
 local e=owner.eventManger
 if e and (e.isMinesweeper or (e.layer and e.layer:isVisible())) then return false end
 for _,id in ipairs(e and e.eventWaitingQueue or{})do if id~=0 then return false end end
 return true
end
-- Two verified durable writes, NOT one cross-file atomic transaction. Map goes
-- first; a role failure is reported as partial and can safely be retried.
function P.checkpoint(owner,dm,storage)
 if not P.canOpen(owner) then return false,'busy' end
 local info=dm:getRoleData(roleMapInfo);local map=dm:getRoleData(mapInfo)
 local pos=owner.playerTitlePosition;local index=tonumber(owner.mapIndex)
 if tonumber(dm:getRoleData(roleStatue))~=1 or type(info)~='table' or info.willFight~=nil or type(map)~='table' or not index
  or index%1~=0 or index<1 or tonumber(info.curIndex)~=index or type(pos)~='table'
  or not finite(pos.x) or not finite(pos.y) or pos.x%1~=0 or pos.y%1~=0
  or not finite(owner.breadCostDecimal or 0) then return false,'unavailable' end
 if not dm.__roleData or type(dm.__roleData.commitAdventure)~='function' then return false,'unavailable' end
 local nextInfo=copy(info);nextInfo.playerTitlePosition={x=pos.x,y=pos.y}
 local fields={[roleMapInfo]=nextInfo,[roleBreadCostDecimal]=owner.breadCostDecimal or 0}
 local ok,saved=pcall(function()
  local json=require 'LuaClass/simplejson.lua'
  return storage:saveDataAtomic(json.encode(copy(map)),'gameMap'..index)
 end)
 if not ok or saved~=true then return false,'map_failed' end
 ok,saved=pcall(function()return dm.__roleData:commitAdventure(fields)end)
 if not ok or saved~=true then return false,'role_failed' end
 return true,'saved'
end
local statuses={
 saved='当前海图与航程已保存',
 map_failed='海图保存失败，请重试；暂勿关闭游戏',
 role_failed='海图已保存，航程保存失败；请重试',
 unavailable='当前无法确认保存，请继续航行后重试',
 busy='当前事件尚未结束，请稍后再保存'}
local function inside(node,owner)
 while node do if node==owner then return true end;node=node:getParent()end
 return false
end
function P.open(owner,resumeNotice,onContinue)
 if owner and owner.warmPause then return owner.warmPause end
 if not P.canOpen(owner) then if ToastUtil then ToastUtil:toastString('请等移动或当前事件结束，再暂歇。')end;return nil end
 local dm=DataManager:getInstance();local info=dm:getRoleData(roleMapInfo)
 if info and info.willFight~=nil then return nil end
 local director=cc.Director:getInstance();local scene=director:getRunningScene()
 if not scene or owner:getScene()~=scene then return nil end
 local size,origin=director:getVisibleSize(),director:getVisibleOrigin()
 local k=math.min(size.width/640,size.height/860)
 local layer=cc.LayerColor:create(cc.c4b(25,49,52,160),size.width,size.height)
 layer:setPosition(origin);layer.isAdventureModal=true;owner.warmPause=layer
 scene:addChild(layer,100000)
 local actions=director:getActionManager();local frozen={}
 -- The returned targets were running. Already-paused targets are excluded by
 -- the engine, so Continue cannot accidentally wake another component's pause.
 for _,node in ipairs(actions:pauseAllRunningActions())do
  if inside(node,owner)then node:retain();frozen[#frozen+1]=node else actions:resumeTarget(node)end
 end
 local closed=false;local observer;local listener
 local function dispose(resume)
  if closed then return end;closed=true
  if owner.warmPause==layer then owner.warmPause=nil end
  if listener then layer:getEventDispatcher():removeEventListener(listener);listener=nil end
  local token=observer;observer=nil;if token then token:removeFromParent(true)end
  for _,node in ipairs(frozen)do
   if resume and inside(node,owner)then actions:resumeTarget(node)end
   node:release()
  end
  frozen={}
 end
 function layer:close(continueVoyage)
  if closed then return end
  dispose(continueVoyage~=false);self:removeFromParent(true)
  if continueVoyage~=false and onContinue then local callback=onContinue;onContinue=nil;callback()end
 end
 observer=cc.Node:create();owner:addChild(observer)
 observer:registerScriptHandler(function(event)
  if event=='exit' or event=='cleanup'then
   observer=nil
   -- Scene::onExit marks the scene non-running before walking its children.
   -- Its still-running pause sibling must remain in that walk: removing it
   -- here skips native onExit and can destroy a running subtree (desktop X).
   -- Dispose ownership/retains now; the scene exits and removes the UI itself.
   if not scene:isRunning() and layer:isRunning() then dispose(false)
   else layer:close(false)end
  end
 end)
 layer:registerScriptHandler(function(event)if event=='exit' or event=='cleanup'then dispose(false)end end)
 local pw,ph=574*k,650*k
 local panel=W.panel(pw,ph,W.colors.paper,28*k);panel:setPosition(cc.p((size.width-pw)/2,(size.height-ph)/2));layer:addChild(panel)
 local function label(text,font,y,color)
  local n=W.label(text,font*k,color or W.colors.ink,pw/2,y*k,true,.5);W.fit(n,pw-50*k);panel:addChild(n);return n
 end
 label(resumeNotice and '接着上次的航程' or '航行暂停',35,599)
 label(resumeNotice and '已载入原有航程，尚未开启新航次' or '船只与海上事件已暂停',20,554,W.colors.muted)
 local pos=owner.playerTitlePosition or{}
 label('海图 '..tostring(owner.mapIndex or'?')..' · 位置 '..tostring(pos.x or'?')..','..tostring(pos.y or'?'),22,497)
 local bag=owner.bagController
 label('食物 '..tostring(bag and bag:getBreads()or 0)..' · 货舱 '..tostring(bag and bag.costSpace or 0)..'/'..tostring(bag and bag.limited or 0),22,462)
 layer.statusLabel=label('本次尚未执行手动保存',19,410,W.colors.muted)
 local function button(text,y,callback,primary)
  local b=W.button(text,pw-64*k,62*k,callback,{primary=primary,size=25*k});b:setPosition(cc.p(pw/2,y*k));panel:addChild(b);return b.item
 end
 layer.continueButton=button('继续航程',346,function()if not closed then layer:close(true)end end,true)
 layer.saveButton=button('保存当前航程',268,function()
  if closed then return end
  require 'LuaClass/SaveDataManager'
  local ok,reason=P.checkpoint(owner,dm,SaveDataManager:getInstance())
  layer.saveResult=reason;layer.statusLabel:setString(statuses[reason]or statuses.unavailable)
  W.fit(layer.statusLabel,pw-50*k)
 end)
 layer.leaveButton=button('查看返航条件',190,function()
  if closed then return end
  -- Resume the existing scene before opening its existing quote/confirmation.
  -- No fee/loss/return action is performed by this sheet itself.
  onContinue=nil;layer:close(true)
  if owner.adventureReturnButton and owner.adventureReturnButton.item then owner.adventureReturnButton.item:activate()end
 end)
 label('只想休息？保存成功后再关闭游戏。',17,122,W.colors.muted)
 label('返航按原有卷轴或钻石规则确认。',17,92,W.colors.muted)
 listener=cc.EventListenerTouchOneByOne:create();listener:setSwallowTouches(true)
 listener:registerScriptHandler(function()return true end,cc.Handler.EVENT_TOUCH_BEGAN)
 layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,layer)
 return layer
end
function P.resumeNotice(owner,onContinue)
 if owner.warmResumePending then return true end
 if owner.warmResumeShown then return false end
 local dm=DataManager:getInstance();local info=dm:getRoleData(roleMapInfo)
 if type(info)~='table' or info.willFight~=nil or not info.playerTitlePosition or tonumber(dm:getRoleData(roleStatue))~=1 then return false end
 -- controller calls startJumpAction immediately after replaceScene, while the
 -- Director still reports the outgoing scene. Owner actions only start after
 -- onEnter; defer until then so the sheet belongs to the new scene and sees all
 -- running sailing actions. Cleanup cancels this action with its owner.
 owner.warmResumePending=true
 owner:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function()
  owner.warmResumePending=nil
  if P.open(owner,true,onContinue) then
   owner.warmResumeShown=true
  elseif onContinue then
   -- Busy/tutorial states retain the original scene-entry event continuation.
   onContinue()
  end
 end)))
 return true
end
return P
