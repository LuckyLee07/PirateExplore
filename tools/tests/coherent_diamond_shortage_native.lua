-- Actual addDiamond + PurchaseAvailability + WarmDialog; no billing/profile/network.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua');local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,fixture=fixture,getData=function()return data end,visit=visit,
 prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
 finish=function()scene:cleanup();scene:release();scene=nil end,realGet=realGet}
]],'@diamond-shortage-native-fixture'))()
local function eq(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local errors={};local originalTraceback=__G__TRACKBACK__;__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
local dm=H.dm;local W=require 'LuaClass/WarmTheme';local D=require 'LuaClass/WarmDialog'
package.loaded['LuaClass/ToastUtil']=true
local PA=require 'LuaClass/PurchaseAvailability'
local source=read('bin/res/scripts/LuaClass/DataManager.lua');local a=assert(source:find('function DataManager:addDiamond(',1,true));local b=assert(source:find('function DataManager:unlockTallentByKey(',a,true))
assert(loadstring(source:sub(a,b-1),'@actual-diamond-shortage-method'))();dm.addDiamond=DataManager.addDiamond
local oldApplication=cc.Application.getInstance;local platform=cc.PLATFORM_OS_LINUX
cc.Application.getInstance=function()return{getTargetPlatform=function()return platform end}end
local writes,legacyAlerts,created,routes,toasts=0,0,0,{},{}
local originalPurchase=purchase;local purchaseTrap=function()error('billing forbidden in this test')end;purchase=purchaseTrap
local originalPushGift=PushGiftView;local reenter,current
PushGiftView={create=function()
 created=created+1
 return{show=function(_,depth)
  if rawget(_G,'WARM_PIRATE_V1')~=false then assert(current and current:getParent(),'original route runs before shortage sheet closes')end
  routes[#routes+1]=depth or 'default'
  if reenter then reenter()end
  if rawget(_G,'WARM_PIRATE_V1')~=false then assert(current:getParent(),'reentrant click must not close during original gift callback')end
 end}
end}
dm.setRoleData=function(_,key,value)writes=writes+1;H.getData()[key]=value end
ToastUtil.downString=function(_,message)toasts[#toasts+1]=message end
ToastUtil.toastString=ToastUtil.downString
WriteColor=cc.c3b(255,255,255)
local legacyCallback
AlertView={create=function(_,kind,style,title,callback)
 legacyAlerts=legacyAlerts+1;eq(title,'购买失败','legacy title');legacyCallback=callback
 local n=cc.Node:create();n.s_position=cc.p(240,400);cc.Director:getInstance():getRunningScene():addChild(n);return n
end}
local function text(layer,w,h)
 local messages={};H.visit(layer,function(n,visible)
  if visible and n.getString and n:getString()~='' then
   local s=n:getString();messages[s]=true
   if n.getFontName then eq(n:getFontName(),W.font,'coherent shortage font')end
   local z=n:getContentSize();local p=n:convertToWorldSpace(cc.p(0,0));local q=n:convertToWorldSpace(cc.p(z.width,z.height))
   assert(p.x>=-1 and q.x<=w+1 and p.y>=-1 and q.y<=h+1,'shortage text fits: '..s)
  end
 end);return messages
end
local function capture(layer,w,h,name)
 if coherentCapture and os.getenv('COHERENT_LOOT_CAPTURE_DIR')then assert(coherentCapture(layer,w,h,os.getenv('COHERENT_LOOT_CAPTURE_DIR')..'/diamond-shortage-'..name..'-'..w..'x'..h..'.png'))end
end
local function reset(scene)
 if scene.adventureDialog then scene.adventureDialog.close()end
 H.fixture();H.getData()[roleDiamond]=0;writes=0;legacyAlerts=0;created=0;routes={};toasts={};reenter=nil;current=nil
end
for _,size in ipairs({{480,800},{540,900},{640,1136},{720,1280}})do
 local w,h=size[1],size[2];local scene=H.prepare(w,h);WARM_PIRATE_V1=true
 for _,case in ipairs({{'linux',cc.PLATFORM_OS_LINUX,true},{'missing-bridge',cc.PLATFORM_OS_ANDROID,false}})do
  reset(scene);platform=case[2];purchase=case[3]and purchaseTrap or nil
  assert(not PA.isAvailable());eq(dm:addDiamond(-1),0,'unsupported shortage fails');local sheet=assert(scene.adventureDialog);sheet:retain();current=sheet
  local messages=text(sheet,w,h);assert(messages['钻石不足，当前平台暂不支持充值购买。']);eq(#sheet.warmOptions,1,'unsupported is dismiss-only');eq(sheet.warmOptions[1].label:getString(),'知道了','honest dismiss label')
  eq(dm:addDiamond(-1),0,'repeated shortage still fails');eq(scene.adventureDialog,sheet,'repeated shortage reuses sheet')
  capture(sheet,w,h,case[1]);local button=sheet.warmOptions[1].item;button:retain();button:activate();button:activate();button:release();eq(scene.adventureDialog,nil,'dismiss clears sheet')
  eq(created,0,'unsupported never opens gift');eq(writes,0,'unsupported shortage/cancel never writes');eq(H.getData()[roleDiamond],0,'unsupported balance unchanged');eq(#toasts,0,'single shortage sheet only');sheet:release()
 end
 for _,inMap in ipairs({false,true})do
  reset(scene);platform=cc.PLATFORM_OS_IPHONE;purchase=purchaseTrap;isEnterMap=inMap;assert(PA.isAvailable())
  eq(dm:addDiamond(-1),0,'supported shortage fails');local sheet=assert(scene.adventureDialog);sheet:retain();current=sheet
  local messages=text(sheet,w,h);assert(messages['钻石不足，可查看充值选项。购买结果由平台确认。']);eq(#sheet.warmOptions,2,'supported offers explicit route and cancel')
  eq(sheet.warmOptions[1].label:getString(),'查看充值选项','does not imply purchase completion');eq(sheet.warmOptions[2].label:getString(),'取消','cancel available')
  capture(sheet,w,h,inMap and 'mobile-in-map' or 'mobile-home')
  local cancel=sheet.warmOptions[2].item;cancel:retain();cancel:activate();cancel:activate();cancel:release();eq(scene.adventureDialog,nil,'cancel closes');eq(created,0,'cancel never opens gift');eq(writes,0,'cancel never writes');sheet:release()
  dm:addDiamond(-1);sheet=assert(scene.adventureDialog);sheet:retain();current=sheet
  local action=sheet.warmOptions[1].item;action:retain();local nested=false
  reenter=function()if not nested then nested=true;action:activate()end end
  action:activate();action:activate();action:release();eq(created,1,'rapid and synchronous reentry route once');eq(#routes,1,'show once');eq(routes[1],inMap and 999 or 'default','original map-depth route preserved')
  eq(scene.adventureDialog,nil,'route then close');eq(writes,0,'viewing options never writes');eq(H.getData()[roleDiamond],0,'no credit or charge');sheet:release()
 end
 -- Existing false suppression short-circuits before availability or presentation.
 reset(scene);purchase=purchaseTrap;platform=cc.PLATFORM_OS_LINUX
 eq(dm:addDiamond(-1,false,false),0,'silent shortage result');eq(scene.adventureDialog,nil,'false suppresses every shortage surface');eq(writes,0,'silent shortage never writes')
 -- Success, zero and ordinary spending still use the original arithmetic/write path.
 eq(dm:addDiamond(5,false,false),1,'positive exact credit');eq(H.getData()[roleDiamond],5,'same balance');eq(#toasts,0,'explicit success opt-out')
 eq(dm:addDiamond(-3),1,'affordable exact cost');eq(H.getData()[roleDiamond],2,'same cost');eq(dm:addDiamond(0),1,'zero unchanged');eq(writes,3,'one original write per success');eq(scene.adventureDialog,nil,'success never opens shortage')
 H.finish();print('PASS native shortage '..w..'x'..h..': unsupported/missing bridge, mobile routes, cancel, rapid/reentrant clicks, silent shortage, zero writes on failure and original success arithmetic')
end
-- Opt-out retains its original dark AlertView text and original callback.
local scene=H.prepare(640,1136);reset(scene);WARM_PIRATE_V1=false;platform=cc.PLATFORM_OS_LINUX;purchase=purchaseTrap
isEnterMap=true;eq(dm:addDiamond(-1),0,'legacy failure');eq(legacyAlerts,1,'legacy AlertView preserved');eq(scene.adventureDialog,nil,'legacy does not use WarmDialog');eq(writes,0,'legacy shortage no writes')
local found={};H.visit(scene,function(n)if n.getString then found[n:getString()]=true end end)
assert(found['钻石不足!']and found['你可以通过充值获得更多钻石。'],'legacy strings untouched')
current=scene;legacyCallback();eq(routes[1],999,'legacy route unchanged');H.finish()
cc.Application.getInstance=oldApplication;purchase=originalPurchase;PushGiftView=originalPushGift;cc.Director.getInstance=H.realGet
assert(#errors==0,table.concat(errors,'\n'));__G__TRACKBACK__=originalTraceback
print('PASS native legacy opt-out and all callback order/count checks; no billing or persistent profile used')
