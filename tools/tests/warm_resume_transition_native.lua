-- Real Director scene replacement + production controller sequencing. This is
-- an isolated lifecycle fixture, not a real map or player-save acceptance run.
require 'extern'
require 'LuaClass/Header'
WARM_PIRATE_V1=true
BoldFont='Noto Serif CJK SC'
cclog=function()end
local function read(path)
 local f=assert(io.open(path,'rb'));local text=f:read('*a');f:close();return text
end
local realGet=cc.Director.getInstance
local director=realGet(cc.Director)
local proxy=setmetatable({getVisibleSize=function()return cc.size(640,960)end,
 getVisibleOrigin=function()return cc.p(0,0)end},
 {__index=function(_,key)return function(_,...)return director[key](director,...)end end})
cc.Director.getInstance=function()return proxy end
local data,created,eventCalls,writes,returned
local dm={getRoleData=function(_,key)return data[key]end,
 setRoleData=function(_,key,value)assert(key==roleStatue);data[key]=value;writes=writes+1 end,
 getMusic_off=function()return 1 end}
DataManager={getInstance=function()return dm end}
AudioEngine={}
ToastUtil={toastString=function()end}
for _,name in ipairs({'AudioEngine','LuaClass/DataManager','LuaClass/ToastUtil',
 'LuaClass/NotificationNode','LuaClass/MissionManagers','LuaClass/Explore'})do package.loaded[name]=true end
local Sea={tryEvent=function(owner,manual,source)
 eventCalls[#eventCalls+1]={owner=owner,source=source};return false
end}
local exploreSource=read('bin/res/scripts/LuaClass/Explore.lua')
local start=assert(exploreSource:match('(function Explore:startJumpAction%([^\n]*.-)\nend'))..'\nend'
Explore={}
assert(loadstring('local AdventureSea=...\n'..start,'@actual-startJumpAction'))(Sea)
local W=require 'LuaClass/WarmTheme'
function Explore:create()
 local node=cc.Layer:create();node:retain();created=node
 node.statue='ready';node.mapIndex=data[roleMapInfo].curIndex
 node.playerTitlePosition={x=7,y=9};node.breadCostDecimal=.25
 node.moveWaitingQueue={};node.moveDirectionQueue={};node.eventManger={eventWaitingQueue={0}}
 node.bagController={getBreads=function()return 12 end,costSpace=14,limited=30}
 node.adventureReturnButton=W.button('返航',100,55,function()returned=returned+1 end)
 node:addChild(node.adventureReturnButton)
 node.startJumpAction=Explore.startJumpAction
 node.tryToMoveForDirction=function(self,direction)self.replays=(self.replays or 0)+1;self.replayDirection=direction end
 node.destory=function(self)self:removeFromParent(true)end
 return node
end
-- This is the actual controller, including its private mapLayer and branching
-- on the stored roleStatue. Only expensive Explore construction is isolated.
dofile('bin/res/scripts/LuaClass/controller.lua')
local function frames()
 for _=1,5 do
  local untilTime=os.clock()+.002;while os.clock()<untilTime do end
  director:drawScene()
 end
end
local function reset(chapter,willFight,tile)
 data={[roleStatue]=1,[roleMapInfo]={curIndex=chapter,
  playerTitlePosition=tile and {x=7,y=9}or nil,willFight=willFight},
  [roleBreadCostDecimal]=.25,[roleMoney]=17,[roleDiamond]=9,
  [roleBattlePack]={['1005']={id='1005',num=12}},
  adventureProgressV1={version=1,enabled=true,voyage=2,activeVoyage=2}}
 eventCalls={};writes=0;returned=0
end
local function releaseOwner()
 local owner=created;cleanUpController();owner:release();created=nil
end
local function verifyPending(oldScene)
 local owner=created
 assert(director:getRunningScene()==oldScene,'replaceScene is pending until drawScene')
 assert(owner:getScene()~=oldScene,'new Explore already belongs to intended replacement scene')
 assert(not owner.warmPause and not owner.warmResumeShown,'no notice is attached or marked before new scene enters')
 owner:startJumpAction() -- duplicate pre-entry invocation must not queue twice
 frames()
 assert(director:getRunningScene()==owner:getScene(),'actual Director activated the intended scene')
 local modal=assert(owner.warmPause,'cold resume notice survives real pending-scene replacement')
 assert(modal:getScene()==owner:getScene(),'notice belongs to live Explore scene')
 assert(owner.warmResumeShown and #eventCalls==0,'resume gate precedes original arrival event')
 assert(data[roleStatue]==1 and data.adventureProgressV1.activeVoyage==2,'no new or completed voyage')
 assert(data[roleBattlePack]['1005'].num==12 and data[roleDiamond]==9 and writes==1,'notice adds no save, cost or cargo change')
 modal.continueButton:activate();frames()
 assert(not owner.warmPause and #eventCalls==1 and eventCalls[1].source=='resume_continue','continue resumes original event exactly once')
 releaseOwner()
end
-- Actual runWithScene path has no running scene yet, not an entered fixture.
reset(1,nil,true);assert(director:getRunningScene()==nil)
gotoMap();verifyPending(nil)
print('PASS actual controller runWithScene -> immediate startJumpAction -> real scene entry keeps cold-resume notice')
-- Both early and late restored chapters use the original direct restore path.
for _,chapter in ipairs({1,5,7})do
 local old=cc.Scene:create();director:replaceScene(old);frames()
 reset(chapter,nil,true);gotoMap();verifyPending(old)
 print('PASS actual controller replaceScene pending window, chapter '..chapter..', duplicate pre-entry guard and once-only continuation')
end
-- Abandoning construction before the scene enters cancels owner-owned work;
-- no orphan resume notice should appear on the replacement or outgoing scene.
local cancelledScene=cc.Scene:create();director:replaceScene(cancelledScene);frames()
reset(1,nil,true);gotoMap();local cancelledOwner=created;cancelledOwner:retain()
releaseOwner();frames()
assert(not cancelledOwner.warmPause and #eventCalls==0,'pre-entry owner cleanup cancels queued notice and continuation')
assert(director:getRunningScene():getChildrenCount()==0,'no orphan modal remains after pre-entry owner cleanup')
cancelledOwner:release()
local old=cc.Scene:create();director:replaceScene(old);frames()
reset(7,'pending-battle',true);gotoMap();local owner=created
assert(owner.replays==1 and owner.replayDirection==Right,'original pending-fight replay remains immediate and exactly once')
frames();assert(not owner.warmPause and not owner.warmResumeShown and #eventCalls==0,'pending fight is never intercepted by notice')
assert(data[roleMapInfo].willFight=='pending-battle','pending fight marker is unchanged')
releaseOwner()
old=cc.Scene:create();director:replaceScene(old);frames()
reset(1,nil,false);gotoMap();owner=created;frames()
assert(not owner.warmPause and #eventCalls==1 and eventCalls[1].source=='scene_enter','fresh unsaved tile retains original arrival flow')
releaseOwner()
cc.Director.getInstance=realGet
print('PASS original pending-fight and fresh-arrival branches; no user save/map/profile loaded')
