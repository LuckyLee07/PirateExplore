-- Integration check with the truthful shortage successor. Set
-- PIRATE_RECOVERY_DATA_MANAGER to its reviewed DataManager.lua when running
-- the recovery-only branch; after integration, use this checkout by default.
-- Reads only in-memory fixture state; no profile, billing or GUI.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,fixture=fixture,getData=function()return data end,visit=visit,
 prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
 finish=function()scene:cleanup();scene:release();scene=nil end,realGet=realGet}
]],'@recovery-shortage-integration'))()
local function eq(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local dm=H.dm;local R=require 'LuaClass/WarmBattleRecovery';local PA=require 'LuaClass/PurchaseAvailability'
local manager=read(os.getenv('PIRATE_RECOVERY_DATA_MANAGER')or'bin/res/scripts/LuaClass/DataManager.lua')
local a=assert(manager:find('function DataManager:addDiamond(',1,true));local b=assert(manager:find('function DataManager:unlockTallentByKey(',a,true))
assert(manager:sub(a,b):find("require('LuaClass/WarmDialog')",1,true),'requires truthful diamond shortage successor; set PIRATE_RECOVERY_DATA_MANAGER or integrate it')
assert(loadstring(manager:sub(a,b-1),'@actual-reviewed-addDiamond'))();dm.addDiamond=DataManager.addDiamond
FightScene={FightFailType={normal=1,eternal=2}}
local application=cc.Application.getInstance;local platform=cc.PLATFORM_OS_LINUX
cc.Application.getInstance=function()return{getTargetPlatform=function()return platform end}end
local writes,calls,gifts,depth,onWrite=0,0,0,nil,nil
purchase=function()error('No platform purchases are allowed in this fixture')end
ToastUtil.downString=function()end;ToastUtil.toastString=function()end
dm.setRoleData=function(_,key,value)writes=writes+1;H.getData()[key]=value;if onWrite then onWrite()end end
PushGiftView={create=function()gifts=gifts+1;local gift=cc.Layer:create();function gift:show(d)depth=d or 'default'end;return gift end}
getExplor=function()return{eventManger={layer={safeBackToLayer=function()calls=calls+1 end}}}end
local errors={};local traceback=__G__TRACKBACK__;__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
for _,size in ipairs({{360,640},{480,800}})do
 for _,case in ipairs({{'linux',cc.PLATFORM_OS_LINUX,true},{'mobile-no-bridge',cc.PLATFORM_OS_ANDROID,false},{'mobile',cc.PLATFORM_OS_IPHONE,true}})do
  H.fixture();local scene=H.prepare(size[1],size[2]);platform=case[2]
  purchase=case[3]and function()error('Billing is forbidden')end or nil
  writes=0;calls=0;gifts=0;depth=nil;H.getData()[roleDiamond]=49
  local owner=cc.Layer:create();scene:addChild(owner);owner.fightFailType=1;owner.fightResult=false
  owner.showFailInfoAndReturn=function(self)return R.result(self)end
  owner.fightOverCallback=function(result)eq(result,false,'original result');calls=calls+1 end
  local choice=R.choice(owner);assert(not choice.reviveAffordable)
  choice.buttons.revive.item:activate();local shortage=assert(owner.adventureDialog);shortage:retain()
  eq(writes,0,'49 no debit');eq(calls,0,'49 no revive');eq(H.getData()[roleDiamond],49,'49 unchanged')
  choice.buttons.revive.item:activate();choice.buttons['return'].item:activate();eq(owner.adventureDialog,shortage,'underlying clicks preserve shortage');eq(calls,0,'no return beneath modal')
  if case[1]=='mobile'then
   eq(#shortage.warmOptions,2,'supported original options');eq(shortage.warmOptions[1].label:getString(),'查看充值选项','truthful view-only CTA')
   shortage.warmOptions[2].item:activate();eq(gifts,0,'cancel no gift')
   isEnterMap=true;choice.buttons.revive.item:activate();shortage:release();shortage=assert(owner.adventureDialog);shortage:retain()
   local option=shortage.warmOptions[1].item;option:retain();option:activate();option:activate();option:release()
   eq(gifts,1,'supported original gift route once');eq(depth,999,'original in-map depth');eq(writes,0,'viewing options does not pay');eq(calls,0,'viewing options does not revive')
  else
   eq(#shortage.warmOptions,1,'unsupported is dismiss-only');eq(shortage.warmOptions[1].label:getString(),'知道了','unsupported honest dismissal')
   shortage.warmOptions[1].item:activate();eq(gifts,0,'unsupported cannot route to purchase')
  end
  shortage:release();eq(owner.adventureDialog,nil,'explanation closed');choice:refreshAffordance();assert(not choice.reviveAffordable,'49 still visibly short')
  H.getData()[roleDiamond]=50;choice:refreshAffordance();assert(choice.reviveAffordable,'50 becomes affordable without reopening')
  H.getData()[roleDiamond]=49;choice.buttons.revive.item:activate();eq(writes,0,'actual debit rejects stale affordable display');assert(not choice.reviveAffordable)
  local changed=assert(owner.adventureDialog);changed.warmOptions[#changed.warmOptions].item:activate()
  H.getData()[roleDiamond]=50;choice:refreshAffordance()
  choice:retain();local paid=choice.buttons.revive.item;paid:retain();onWrite=function()paid:activate()end;paid:activate();onWrite=nil;paid:activate()
  eq(writes,1,'one exact production diamond write');eq(H.getData()[roleDiamond],0,'original 50 debit');eq(calls,1,'safeBackToLayer exactly once');assert(choice.closed)
  H.finish();paid:activate();eq(writes,1,'disposed stale paid input cannot debit');paid:release();choice:release()
  print('PASS actual addDiamond recovery '..case[1]..' '..size[1]..'x'..size[2]..': 49 explanation/cancel, modal blocking, 50 exact debit and one original navigation')
 end
end
cc.Application.getInstance=application;cc.Director.getInstance=H.realGet;__G__TRACKBACK__=traceback
assert(#errors==0,table.concat(errors,'\n'))
print('PASS original 50-diamond transaction with truthful supported, unsupported and missing-bridge shortage; no billing/profile access')
