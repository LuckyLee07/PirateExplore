-- Real store constructor -> original virtual confirmation -> actual addDiamond.
-- Existing service fixture is in-memory; no profile, real billing or network.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/coherent_service_support_native.lua')
local stop=assert(source:find('for _,size in ipairs(',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {base=H,dm=dm,fresh=fresh,getWrites=function()return writes end,getGrants=function()return grants end,
 resetCounters=function()writes=0;grants=0 end}
]],'@actual-store-shortage-fixture'))()
local function eq(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local source=read('bin/res/scripts/LuaClass/DataManager.lua');local a=assert(source:find('function DataManager:addDiamond(',1,true));local b=assert(source:find('function DataManager:unlockTallentByKey(',a,true))
assert(loadstring(source:sub(a,b-1),'@actual-store-diamond-method'))();H.dm.addDiamond=DataManager.addDiamond
local errors={};local originalTraceback=__G__TRACKBACK__;__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
local oldApp=cc.Application.getInstance;cc.Application.getInstance=function()return{getTargetPlatform=function()return cc.PLATFORM_OS_LINUX end}end
local oldPurchase=purchase;purchase=function()error('native payment must never run')end
H.dm.buyGoodsInDiamondStore=function()error('shortage must never apply an item')end
H.dm.checkAndstepNextGift=function()error('shortage must never advance a gift')end
for _,size in ipairs({{480,800},{540,900}})do
 local w,h=size[1],size[2];local scene,d=H.fresh(w,h);d[roleDiamond]=0
 local store=assert(DiamondStore:create());store:retain();scene:addChild(store);H.resetCounters()
 local before=H.base.serialize(d);local confirm=assert(store:openCoherentGood(1));confirm:retain()
 local buy=confirm.serviceConfirm.item;buy:retain();buy:activate();buy:activate();buy:release()
 eq(confirm:getParent(),nil,'original virtual confirm closes after failed payment');eq(store.serviceAlert,nil,'old confirmation ownership cleared')
 local shortage=assert(store.warmShortageContext.owner.adventureDialog);shortage:retain();eq(#shortage.warmOptions,1,'real Linux store shortage has dismiss only')
 local found={};H.base.visit(shortage,function(n)if n.getString then found[n:getString()]=true end end)
 assert(found['钻石不足，当前平台暂不支持充值购买。'],'real store shows truthful unavailable explanation')
 eq(H.getWrites(),0,'real store shortage writes nothing');eq(H.getGrants(),0,'real store shortage grants nothing');eq(H.base.serialize(d),before,'real store profile fixture unchanged')
 if coherentCapture and os.getenv('COHERENT_LOOT_CAPTURE_DIR')then assert(coherentCapture(scene,w,h,os.getenv('COHERENT_LOOT_CAPTURE_DIR')..'/diamond-store-zero-shortage-'..w..'x'..h..'.png'))end
 local dismiss=shortage.warmOptions[1].item;dismiss:retain();dismiss:activate();dismiss:activate();dismiss:release();eq(store.warmShortageContext.owner.adventureDialog,nil,'dismiss returns to actual store')
 local again=assert(store:openCoherentGood(1));again:retain();again.serviceCancel.item:activate();eq(store.serviceAlert,nil,'store can reopen and cancel after shortage')
 eq(H.getWrites(),0,'reopen/cancel writes nothing');eq(H.base.serialize(d),before,'reopen/cancel unchanged')
 again:release();shortage:release();confirm:release();store:destory();store:removeFromParent(true);store:release();H.base.finish()
 print('PASS actual zero-diamond store '..w..'x'..h..': original purchase confirmation, truthful shortage, dismiss, reopen/cancel, rapid callbacks, zero grants/writes')
end
cc.Application.getInstance=oldApp;purchase=oldPurchase;cc.Director.getInstance=H.base.realGet
assert(#errors==0,table.concat(errors,'\n'));__G__TRACKBACK__=originalTraceback
