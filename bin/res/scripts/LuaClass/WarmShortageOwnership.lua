-- Caller-owned shortage presentation, never a transaction or a global owner.
-- A private child owns the prompt, so an existing caller confirmation can
-- finish without closing the new shortage sheet or sharing its dialog slot.
local O={}
local function stop(node)
 node:stopAllActions();node:unscheduleUpdate()
 for _,child in ipairs(node:getChildren())do stop(child)end
end
local function retireGift(gift)
 if gift.warmRetired then return end
 gift.warmRetired=true
 gift.serviceClosed=true;gift:setVisible(false);stop(gift)
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
function O.retire(owner,lifecycleEvent)
 local context=owner.warmShortageContext
 if context then context.retire(lifecycleEvent)end
end
function O.forOwner(owner,generationKey,guard)
 local current=owner.warmShortageContext
 if current and current.isActive()then return current end
 if current then current.retire()end
 local scene=cc.Director:getInstance():getRunningScene()
 local generation=generationKey and owner[generationKey]
 local token=cc.Node:create();owner:addChild(token)
 local context={owner=token,sourceOwner=owner,disposed=false}
 owner.warmShortageContext=context
 function context.isActive()
  return not context.disposed and owner:getParent()~=nil
   and cc.Director:getInstance():getRunningScene()==scene
   and (not generationKey or owner[generationKey]==generation)
   and (not guard or guard())
 end
 function context.retire(lifecycleEvent)
  if context.disposed then return end
  context.disposed=true
  if owner.warmShortageContext==context then owner.warmShortageContext=nil end
  token:unscheduleUpdate()
  -- Individual parent removal also caches indices across child onExit.
  -- Every lifecycle event defers sibling erasure, even in a running scene.
  local walking=lifecycleEvent~=nil
  local prompt=token.adventureDialog
  if prompt then if walking then prompt.retire()else prompt.close()end end
  local gift=context.gift;context.gift=nil
  if gift then
   retireGift(gift)
   if not walking and gift:getParent()then gift:removeFromParent(true)end
  end
  -- An owner observer must not erase itself from the owner's exit traversal.
  if not lifecycleEvent and token:getParent()then token:removeFromParent(true)end
 end
 function context.showGift(gift,depth)
  if not gift then return end
  if not context.isActive()then gift.serviceClosed=true;stop(gift);return end
  context.gift=gift
  local request=gift.requestGiftPurchase
  function gift:requestGiftPurchase(product)
   if not context.isActive()then context.retire();return false end
   return request(self,product)
  end
  local life=cc.Node:create();gift:addChild(life)
  life:registerScriptHandler(function(event)
   if event=='exit'or event=='cleanup'then
    -- The gift may sort before its owner during the scene's exit walk.
    -- Retire locally before dropping the pointer; never remove its siblings.
    retireGift(gift)
    if context.gift==gift then context.gift=nil end
   end
  end)
  gift:show(depth)
  if not gift:getParent()then context.gift=nil end
 end
 token:registerScriptHandler(function(event)
  if event=='exit'or event=='cleanup'then context.retire(event)end
 end)
 -- The callback guard is immediate; this observer also retires presentation
 -- if external code changes a captured generation/visibility without a hook.
 token:scheduleUpdateWithPriorityLua(function()if not context.isActive()then context.retire()end end,0)
 return context
end
return O
