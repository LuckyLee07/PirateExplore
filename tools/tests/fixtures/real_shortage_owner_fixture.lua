-- Add real shortage/gift components to an existing isolated native fixture.
return function(H,director)
 local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
 local source=read('bin/res/scripts/LuaClass/DataManager.lua')
 local a=assert(source:find('function DataManager:addDiamond(',1,true));local b=assert(source:find('function DataManager:unlockTallentByKey(',a,true))
 assert(loadstring(source:sub(a,b-1),'@real-shortage-addDiamond'))();H.dm.addDiamond=DataManager.addDiamond
 package.loaded['LuaClass/CCall']=true;package.loaded['LuaClass/NotificationNode']=true;package.loaded['LuaClass/MissionManagers']=true;require 'LuaClass/SDButton';require 'LuaClass/DiamondStore'
 local function split(s,delimiter)local out={};for part in (s..delimiter):gmatch('(.-)'..delimiter)do out[#out+1]=part end;return out end
 H.tables[csvOfShopGift]=H.csv('shopgift1');H.tables[csvOfPushGift]=H.csv('giftPush')
 for _,record in pairs(H.tables[csvOfShopGift])do record.desc=split(record.desc,';');local out={};for _,part in ipairs(split(record.item,';'))do out[#out+1]=split(part,'_')end;record.item=out end
 for _,record in pairs(H.tables[csvOfPushGift])do for _,key in ipairs({'title','star','price','desc'})do local out={};for _,part in ipairs(split(record[key],';'))do out[#out+1]=split(part,'_')end;record[key]=out end end
 H.dm.getCurDiamondStoreGoods=function()return '2'end
 local T={requests=0,created=0,writes=0,assertions=0,platform=cc.PLATFORM_OS_IPHONE}
 local app=cc.Application.getInstance
 cc.Application.getInstance=function()return{getTargetPlatform=function()return T.platform end}end
 purchase=function(product)T.requests=T.requests+1;T.product=product end
 local original=PushGiftView.create;PushGiftView.create=function(self)T.created=T.created+1;return original(self)end
 local write=H.dm.setRoleData;H.dm.setRoleData=function(self,key,value,...)if key==roleDiamond then T.writes=T.writes+1 end;return write(self,key,value,...)end
 ToastUtil.downString=function()end;ToastUtil.toastString=function()end
 function T.eq(a,b,why)T.assertions=T.assertions+1;assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
 function T.ok(value,why)T.assertions=T.assertions+1;assert(value,why)end
 function T.step(root,dt)H.visit(root,function(n)director:getActionManager():resumeTarget(n)end);director:getActionManager():update(dt)end
 function T.enter(scene)
  if coherentEventEnter then coherentEventEnter(scene,480,800);T.ok(scene:isRunning(),'genuine running scene')end
 end
 function T.prompt(owner)
  local context=assert(owner.warmShortageContext,'caller opts into shortage ownership')
  local prompt=assert(context.owner.adventureDialog,'actual owned WarmDialog');prompt:retain()
  T.eq(prompt.warmOptions[1].label:getString(),'查看充值选项','truthful view-only option')
  T.eq(context.sourceOwner,owner,'exact originating owner')
  return prompt,context
 end
 function T.gift(prompt,context)
  prompt.warmOptions[1].item:activate();local gift=assert(context.gift,'actual tracked PushGiftView');gift:retain()
  T.ok(gift.giftBuyButton and gift._dialogueEntry,'real gift and modal-stack registration')
  T.eq(gift._dialogueEntry.zOrder,999,'original map depth')
  return gift
 end
 function T.expired(scene,owner,prompt,context,gift,invalidate)
  local requests,created,writes=T.requests,T.created,T.writes
  invalidate()
  T.ok(context.disposed,'context retired immediately');T.eq(owner.warmShortageContext,nil,'owner context pointer cleared')
  T.eq(context.owner.adventureDialog,nil,'owned shortage cleared');T.eq(context.gift,nil,'gift pointer cleared')
  T.eq(prompt:isVisible(),false,'retired prompt is hidden even in retained scene')
  prompt.warmOptions[1].item:activate()
  if gift then
   T.eq(gift._dialogueEntry,nil,'retired gift leaves scene modal stack')
   T.ok(gift.serviceClosed,'gift service closed');T.eq(gift:isVisible(),false,'gift hidden')
   T.eq(gift.giftBuyButton:getNumberOfRunningActions(),0,'delayed Buy stopped')
   T.step(gift,0);T.step(gift,gift.timeLine+1);gift.giftBuyButton.item:activate()
  end
  T.eq(T.requests,requests,'retained stale Buy never reaches supported spy')
  T.eq(T.created,created,'retained stale prompt never creates gift');T.eq(T.writes,writes,'disposal never debits')
 end
 function T.finish(label)
  cc.Application.getInstance=app;PushGiftView.create=original
  print('PASS '..label..': '..T.assertions..' real-component assertions'..(coherentEventEnter and ' in running native scenes' or ' (running scenes checked by render runner)'))
 end
 return T
end
