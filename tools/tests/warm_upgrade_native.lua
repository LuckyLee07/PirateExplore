-- Real Cocos/EGL nodes, shipped artwork/fonts, native menu activation, and the
-- actual original craft transaction. Isolated fixture storage; no player save.
require 'extern'
local F=dofile('tools/tests/fixtures/warm_upgrade_fixture.lua')
BoldFont='Noto Serif CJK SC';WARM_PIRATE_V1=true
local dm=F.dm;local U=require 'LuaClass/WarmUpgrade';local eq=F.equal
local scene,viewport
local realGet=cc.Director.getInstance;local director=realGet(cc.Director)
cc.Director.getInstance=function()return setmetatable({getVisibleSize=function()return viewport end,
 getVisibleOrigin=function()return cc.p(0,0)end,getRunningScene=function()return scene end},
 {__index=function(_,key)return function(_,...)return director[key](director,...)end end})end
local function bounds(page)
 for _,child in ipairs(page.canvas:getChildren())do
  if child.getString and child:getString()~='' then
   local z=child:getContentSize();local a=child:getAnchorPoint();local x,y=child:getPosition()
   assert(x-z.width*a.x>=0 and x+z.width*(1-a.x)<=480,'native label horizontal bounds: '..child:getString())
   assert(y-z.height*a.y>=28 and y+z.height*(1-a.y)<=772,'native label vertical bounds: '..child:getString())
  end
 end
 local b=page.buttons
 if b.cancel and b.confirm then
  local a,c=b.cancel,b.confirm;assert(a:getPositionX()+a:getContentSize().width/2<c:getPositionX()-c:getContentSize().width/2,'distinct cancel/confirm touch targets')
 end
end
local function emptyEvents()for _,bucket in pairs(dm.__eventListener)do assert(next(bucket)==nil,'native close unregisters events')end end
local routed=0;zqDispatch={gotoBuild=function(_,id)eq(id,'57');routed=routed+1 end}
for _,height in ipairs({960,1067,1136})do
 viewport=cc.size(640,height);scene=cc.Scene:create();scene:retain()
 F.reset();local owner=cc.Node:create();scene:addChild(owner)
 local page=U.open(owner,'1148');page:retain();bounds(page);eq(U.open(owner,'1148'),page,'duplicate open')
 local cancelled=page.quote;local before=F.capture();page.buttons.cancel.item:activate();eq(F.capture(),before,'cancel no writes');eq(owner.warmUpgrade,nil);emptyEvents()
 local ok,status=U.confirm(dm,cancelled);eq(ok,false);eq(status,'cancelled');page:release()
 page=U.open(owner,'1148');page:retain();page.buttons.confirm.item:activate();bounds(page)
 eq(dm:getRoleData(rolePackSize),30,'real upgrade from native confirm');eq(F.atomic,1);eq(F.normal,0);assert(page.success and page.buttons.close)
 page.buttons.close.item:activate();eq(owner.warmUpgrade,nil);emptyEvents();page:release()
 page=U.open(owner,'1148');page:retain();assert(page.buttons.close and not page.buttons.confirm,'owned upgrade cannot reconfirm');bounds(page);page:close();page:release()
 -- The actual live stock event refreshes an open preview. A retained native
 -- button from an older generation cannot perform an outdated confirmation.
 F.reset();page=U.open(owner,'1148');page:retain();local stale=page.buttons.confirm.item;stale:retain()
 dm.__roleData:setRoleData(rolePack,{['1007']=0,['1018']=5});dm:postEvent(rolePack)
 assert(not page.buttons.confirm.item:isEnabled());stale:activate();eq(F.atomic,0);stale:release();bounds(page);page:close();page:release()
 F.reset();page=U.open(owner,'1176');page:retain();F.fail=true;page.buttons.confirm.item:activate();eq(F.atomic,0);eq(dm:getRoleData(roleAlchemyUnit),1)
 bounds(page);F.fail=false;page.buttons.confirm.item:activate();eq(dm:getRoleData(roleAlchemyUnit),2);eq(F.atomic,1);bounds(page);page:close();page:release()
 F.reset({[roleMake]={},[roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=0}}});page=U.open(owner,'1148');page:retain();bounds(page)
 before=F.capture();page.buttons.confirm.item:activate();eq(F.capture(),before,'prerequisite route only');eq(owner.warmUpgrade,nil);emptyEvents();page:release()
 F.reset();page=U.open(owner,'1148');page:retain();local old=page.quote;owner:removeFromParent(true)
 assert(page.disposed and owner.warmUpgrade==nil,'ancestor cleanup');emptyEvents();eq(select(2,U.confirm(dm,old)),'cancelled');page:release()
 scene:cleanup();scene:release();scene=nil
 print('PASS native WarmUpgrade '..height..'pt: labels, disjoint controls, cancel/reopen, actual atomic craft, stale native action, save retry, forge route and owner cleanup')
end
eq(routed,3);cc.Director.getInstance=realGet
