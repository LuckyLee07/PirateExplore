local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/coherent_service_support_native.lua');local stop=assert(source:find('for _,size in ipairs(',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,dm=dm,fresh=fresh,director=director}
]],'@store-owner-fixture'))()
local H,dm=F.H,F.dm;local T=dofile('tools/tests/fixtures/real_shortage_owner_fixture.lua')(H,F.director)
local errors={};__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
for _,order in ipairs({'owner-first','presentation-first'})do
for _,how in ipairs({'remove','destory','reload','generation','scene','push'})do
 for _,phase in ipairs({'prompt','gift'})do
  if (how~='scene'and how~='push')or coherentEventEnter then
   local scene,d=F.fresh(480,800);d[roleDiamond]=0;isEnterMap=true
   local store=assert(DiamondStore:create());store:retain();scene:addChild(store);T.enter(scene)
   local writes=T.writes;local confirmation=assert(store:openCoherentGood(1));confirmation.serviceConfirm.item:activate()
   local prompt,context=T.prompt(store);local gift=phase=='gift'and T.gift(prompt,context)or nil
   T.eq(T.writes,writes,'real failed store confirmation never debits')
   local surface=gift or prompt
   if order=='presentation-first'then surface:setLocalZOrder(-1)end
   local sentinel=cc.Node:create();sentinel:retain();scene:addChild(sentinel,5000)
   scene:sortAllChildren()
   local ownerIndex,surfaceIndex
   for index,child in ipairs(scene:getChildren())do if child==store then ownerIndex=index elseif child==surface then surfaceIndex=index end end
   T.eq(ownerIndex<surfaceIndex,order=='owner-first','actual native sibling sort order')
   T.expired(scene,store,prompt,context,gift,function()
    if how=='remove'then store:removeFromParent(true)
    elseif how=='destory'then store:destory()
    elseif how=='reload'then store:loadData(nil)
    elseif how=='generation'then
     -- Even before the observer's next frame, Buy rejects a changed generation.
     store.serviceGeneration=store.serviceGeneration+1
     if gift then T.step(gift,0);T.step(gift,gift.timeLine+1);gift.giftBuyButton.item:activate()else context.retire()end
    elseif how=='push'then F.director:pushScene(cc.Scene:create());for _=1,4 do F.director:drawScene()end
    else F.director:replaceScene(cc.Scene:create());for _=1,4 do F.director:drawScene()end end
   end)
   if how~='scene'and how~='push'then
    T.eq(sentinel:getParent(),scene,'following scene sibling retains parent')
    local hasSentinel,hasOwner=false,false
    for _,child in ipairs(scene:getChildren())do if child==sentinel then hasSentinel=true elseif child==store then hasOwner=true end end
    T.eq(hasSentinel,true,'following scene sibling remains in actual child vector')
    if how=='remove'then T.eq(hasOwner,false,'removed owner leaves actual child vector')end
    T.step(scene,0);T.step(scene,.01);T.eq(prompt:getParent(),nil,'exact retired prompt removed on safe tick')
    if gift then T.eq(gift:getParent(),nil,'exact retired gift removed on safe tick')end
   end
   if how=='push'then
    F.director:popScene();for _=1,4 do F.director:drawScene()end
    T.eq(prompt:isVisible(),false,'pop does not redisplay shortage');if gift then T.eq(gift:isVisible(),false,'pop does not redisplay gift')end
   end
   H.finish();if gift then gift:release()end;prompt:release();store:release();sentinel:release()
   print('PASS actual store '..phase..' '..how..' '..order)
  end
 end
end
end
-- A fresh store can cancel, retry, open/close the real offer, then purchase the
-- original virtual item at its exact price; no prior owner's context is reused.
local scene,d=F.fresh(480,800);d[roleDiamond]=0;isEnterMap=true
local store=DiamondStore:create();store:retain();scene:addChild(store);T.enter(scene)
local c=store:openCoherentGood(1);c.serviceConfirm.item:activate();local prompt,context=T.prompt(store)
prompt.warmOptions[2].item:activate();prompt:release();T.eq(context.owner.adventureDialog,nil,'cancel clears shortage')
c=store:openCoherentGood(1);c.serviceConfirm.item:activate();prompt,context=T.prompt(store);local gift=T.gift(prompt,context)
T.step(scene,0);T.step(scene,gift.timeLine+.1);local before=T.requests;gift.giftBuyButton.item:activate();T.eq(T.requests,before+1,'live explicit Buy reaches spy');T.eq(T.product,H.tables[csvOfPushGift]['2'].payType,'original product')
gift.serviceClose.item:activate();T.step(scene,0);T.step(scene,.3);T.eq(context.gift,nil,'gift close clears context');gift:release();prompt:release()
local slot=store.goodsShowData[1];local id=store.goodsData[slot][1];local price=tonumber(H.tables[csvOfShopItem][id].price)
d[roleDiamond]=price;local paid=T.writes;c=store:openCoherentGood(1);c.serviceConfirm.item:activate()
T.eq(d[roleDiamond],0,'fresh retry debits exact original virtual price');T.eq(T.writes,paid+1,'one original virtual diamond write')
store:destory();H.finish();store:release();assert(#errors==0,table.concat(errors,'\n'));T.finish('actual store shortage owner/destroy/reload/scene lifecycle')
