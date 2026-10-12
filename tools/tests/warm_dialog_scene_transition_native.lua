-- Real running-scene regression for Pause -> original quoted-return button ->
-- WarmDialog confirmation -> original Explore destruction. No player save/map.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_exploration_native.lua')
local stop=assert(source:find('local function test(w,h,warm)',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..'\nreturn {quote=quote}\n','@native-quote-fixture'))()
WARM_PIRATE_V1=true;screenSize=cc.size(640,960)
local realGet=cc.Director.getInstance;local director=realGet(cc.Director)
cc.Director.getInstance=function()return setmetatable({
 getVisibleSize=function()return screenSize end,getVisibleOrigin=function()return cc.p(0,0)end},
 {__index=function(_,key)return function(_,...)return director[key](director,...)end end})end
local dm={getRoleData=function(_,key)
 if key==roleExtents then return 0 end
 if key==roleMapInfo then return {curIndex=1,playerTitlePosition={x=7,y=9}}end
 if key==roleStatue then return 1 end
 error('Unexpected role read '..tostring(key))
end}
DataManager={getInstance=function()return dm end}
ToastUtil={toastString=function()end}
local P=require 'LuaClass/WarmPause'
package.loaded['LuaClass/AdventureDialog']=nil
local D=require 'LuaClass/AdventureDialog'
local exploreSource=read('bin/res/scripts/LuaClass/Explore.lua')
local destroy=assert(exploreSource:match('(function Explore:destory%([^\n]*.-)\nend'))..'\nend'
assert(loadstring(destroy,'@actual-Explore-destory'))()
local function frames()
 -- mainLoop also drains autoreleased nodes for realistic disposal coverage.
 -- Fixture retention still differs from the desktop application loop.
 for _=1,5 do local untilTime=os.clock()+.002;while os.clock()<untilTime do end;director:mainLoop()end
end
local attempts,completed=0,0
local function runningOwner()
 local scene=cc.Scene:create()
 if director:getRunningScene()then director:replaceScene(scene)else director:runWithScene(scene)end
 frames()
 local owner=cc.Layer:create();owner:retain();scene:addChild(owner)
 owner.extent=18;owner.mapIndex=1;owner.statue='ready';owner.jointed={enable=true}
 owner.playerTitlePosition={x=7,y=9};owner.moveWaitingQueue={};owner.moveDirectionQueue={}
 owner.fogManager={data={}};owner.map={getMapSize=function()return {width=20}end}
 owner.moveLayer=cc.Node:create();owner:addChild(owner.moveLayer)
 owner.positionForTilePosition=function(_,p)return cc.p(p.x*32+16,640-p.y*32-16)end
 owner.bagController={costSpace=14,limited=30,getBreads=function()return 12 end}
 owner.goBag=function()end;owner.showCurMapStrategy=function()end
 owner.jointedCalBack=function()end;owner.checkBread=function()end;owner.breadCostDecimal=.25
 owner.destory=Explore.destory
 owner.returnToBase=function(self,kind,quote)
  assert(quote==H.quote,'original HUD forwards its real current quote object')
  attempts=attempts+1
  if not self.allowReturn then return false end
  completed=completed+1
  self:destory() -- Actual production removeFromParent path, while running.
  director:replaceScene(cc.Scene:create())
  return true
 end
 Explore.initTipLayer(owner)
 assert(owner:isRunning(),'fixture owner entered an actual running scene')
 return owner
end
local owner=runningOwner()
local pause=assert(P.open(owner));pause.leaveButton:activate()
local modal=assert(owner.adventureDialog,'original return button opens real WarmDialog')
modal:retain();frames();modal.warmOptions[1].item:activate()
assert(attempts==1 and completed==0 and owner.adventureDialog==modal,'rejected return keeps live confirmation without destroying owner')
local staleCancel=modal.warmOptions[2].item;staleCancel:retain();staleCancel:activate();staleCancel:activate()
assert(not owner.adventureDialog and owner:isRunning() and completed==0,'cancel and stale cancel preserve live voyage')
staleCancel:release();modal:release()
owner.allowReturn=true
pause=assert(P.open(owner));pause.leaveButton:activate();modal=assert(owner.adventureDialog);modal:retain()
local confirm=modal.warmOptions[1].item;confirm:retain()
frames()
confirm:activate()
assert(completed==1 and attempts==2,'native quoted confirmation invokes return exactly once')
assert(not owner.adventureDialog and not modal:isVisible() and not owner:isRunning(),'running owner exit immediately retires its bound scene modal')
local function exited(node)
 assert(not node:isRunning(),'all surviving descendants must exit before owner destruction')
 for _,child in ipairs(node:getChildren())do exited(child)end
end
exited(owner)
confirm:activate();modal:close();assert(completed==1 and attempts==2,'retained confirmation cannot repeat after owner destruction')
frames();assert(modal:getParent()==nil,'retired modal removed after native exit unwinds');assert(director:getRunningScene():getChildrenCount()==0,'new scene has no orphan confirmation')
confirm:release();modal:release();owner:release()
print('PASS real running Pause -> original HUD quote -> WarmDialog: rejection, cancel, confirmation, original Explore destruction and stale activation')
-- External owner teardown and complete scene teardown are separate exit orders.
for _,replaceWholeScene in ipairs({false,true})do
 owner=runningOwner();modal=D.show('离开页面','只检查生命周期。',{{label='关闭'}},owner);modal:retain()
 frames()
 if replaceWholeScene then director:replaceScene(cc.Scene:create());frames()else owner:destory()end
 assert(not owner.adventureDialog and not modal:isVisible(),'running ancestor/scene exit immediately clears visible ownership')
 frames();assert(modal:getParent()==nil,'safe later tick removes retired modal')
 modal:close();modal:release();owner:release()
end
cc.Director.getInstance=realGet
print('PASS running owner and whole-scene disposal; no real transaction/profile/network access')
