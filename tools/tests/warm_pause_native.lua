-- Real Cocos action pausing, native controls, and checkpoint I/O boundaries.
-- No player profile, map or real save is opened.
require 'extern';require 'LuaClass/Header'
BoldFont='Noto Serif CJK SC';WARM_PIRATE_V1=true
local json=require 'LuaClass/simplejson.lua'
local P=require 'LuaClass/WarmPause';local W=require 'LuaClass/WarmTheme'
local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
local data,roleDisk,mapDisk,mapFail,roleFail,roleCommits,mapWrites,returnRequests
local scene,viewport
local realGet=cc.Director.getInstance;local director=realGet(cc.Director);local actions=director:getActionManager()
cc.Director.getInstance=function()return setmetatable({getVisibleSize=function()return viewport end,getVisibleOrigin=function()return cc.p(0,0)end,getRunningScene=function()return scene end},{__index=function(_,k)return function(_,...)return director[k](director,...)end end})end
local dm={getRoleData=function(_,key)return data[key]end,__roleData={commitAdventure=function(_,fields)
 if roleFail then return false end
 for key,value in pairs(fields)do assert(key==roleMapInfo or key==roleBreadCostDecimal);data[key]=copy(value)end
 roleDisk=copy(data);roleCommits=roleCommits+1;return true
end}}
DataManager={getInstance=function()return dm end}
SaveDataManager={getInstance=function(self)return self end,saveDataAtomic=function(_,bytes,name)
 assert(name=='gameMap1');if mapFail then return false end;mapDisk=json.decode(bytes);mapWrites=mapWrites+1;return true
end}
package.loaded['LuaClass/SaveDataManager']=true
ToastUtil={toastString=function(_,s)_G.toast=s end}
local function ticks()for _=1,5 do actions:update(.25)end end
local function begin(height)
 viewport=cc.size(640,height);scene=cc.Scene:create();scene:retain()
 data={[roleStatue]=1,[roleMapInfo]={curIndex=1,playerTitlePosition={x=2,y=3}},[roleBreadCostDecimal]=.2,[roleBattlePack]={['1005']={id='1005',num=27}},[roleBattleQueue]={['100']=1},[roleMoney]=13,[roleDiamond]=9,[mapInfo]={titlesInfo={['8']={fogId='0'}}}}
 roleDisk=copy(data);mapDisk={titlesInfo={}};mapFail=false;roleFail=false;roleCommits=0;mapWrites=0;returnRequests=0
 local owner=cc.Layer:create();scene:addChild(owner);owner:retain()
 owner.statue='ready';owner.mapIndex=1;owner.playerTitlePosition={x=4,y=6};owner.breadCostDecimal=.6
 owner.moveWaitingQueue={};owner.moveDirectionQueue={};owner.eventManger={eventWaitingQueue={0}}
 owner.bagController={getBreads=function()return 27 end,costSpace=27,limited=30}
 owner.adventureReturnButton=W.button('返航',100,55,function()returnRequests=returnRequests+1 end)
 owner:addChild(owner.adventureReturnButton)
 return owner
end
local function bounds(layer)
 local function walk(n)
  if n.getString and n:getString()~=''then
   local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
   assert(a.x>=-1 and b.x<=640+1 and a.y>=-1 and b.y<=viewport.height+1,'native pause label bounds: '..n:getString())
  end
  for _,child in ipairs(n:getChildren())do walk(child)end
 end;walk(layer)
end
for _,height in ipairs({960,1067,1136})do
 local owner=begin(height);local work,prePausedWork,unrelatedWork=0,0,0
 local running=cc.Node:create();owner:addChild(running)
 running:runAction(cc.Sequence:create(cc.DelayTime:create(.1),cc.CallFunc:create(function()work=work+1 end)));actions:resumeTarget(running)
 local prePaused=cc.Node:create();owner:addChild(prePaused)
 prePaused:runAction(cc.Sequence:create(cc.DelayTime:create(.1),cc.CallFunc:create(function()prePausedWork=prePausedWork+1 end)));actions:pauseTarget(prePaused)
 local other=cc.Node:create();scene:addChild(other)
 other:runAction(cc.Sequence:create(cc.DelayTime:create(.1),cc.CallFunc:create(function()unrelatedWork=unrelatedWork+1 end)));actions:resumeTarget(other)
 local modal=assert(P.open(owner));modal:retain();assert(P.open(owner)==modal);bounds(modal)
 ticks();assert(work==0 and prePausedWork==0 and unrelatedWork==1,'pause affects only previously running Explore actions')
 assert(roleCommits==0 and mapWrites==0,'opening pause does not claim or perform a save')
 mapFail=true;modal.saveButton:activate();assert(modal.saveResult=='map_failed' and roleCommits==0 and mapWrites==0)
 mapFail=false;roleFail=true;modal.saveButton:activate()
 assert(modal.saveResult=='role_failed' and mapWrites==1 and roleCommits==0,'partial pair explicitly reported')
 assert(mapDisk.titlesInfo['8'].fogId=='0' and roleDisk[roleMapInfo].playerTitlePosition.x==2,'partial disk pair keeps old role tile and newly saved map')
 assert(data[roleBattlePack]['1005'].num==27 and data[roleMoney]==13 and data[roleDiamond]==9,'checkpoint never changes cargo or economy')
 roleFail=false;modal.saveButton:activate();assert(modal.saveResult=='saved' and roleCommits==1)
 assert(roleDisk[roleMapInfo].playerTitlePosition.x==4 and roleDisk[roleBreadCostDecimal]==.6,'retry saves actual tile/fraction')
 assert(roleDisk[roleBattlePack]['1005'].num==27 and roleDisk[roleBattleQueue]['100']==1,'full role snapshot retains cargo and crew')
 modal.continueButton:activate();assert(owner.warmPause==nil);modal:close();modal:release()
 ticks();assert(work==1 and prePausedWork==0,'continue resumes same running target and preserves pre-existing pause')
 modal=assert(P.open(owner));modal:retain();modal.leaveButton:activate();assert(returnRequests==1,'leave delegates exactly once to existing confirmation')
 assert(roleCommits==1 and data[roleDiamond]==9,'leave request itself does not debit/reset');modal:release()
 owner.warmResumeShown=nil;local continued=0
 assert(P.resumeNotice(owner,function()continued=continued+1 end))
 assert(owner.warmPause==nil and owner.warmResumePending and P.resumeNotice(owner),'queued restore is deduplicated before scene entry')
 actions:resumeTarget(owner);ticks();modal=assert(owner.warmPause);modal:retain();bounds(modal)
 assert(roleCommits==1 and returnRequests==1,'resume notice is read-only')
 modal.continueButton:activate();assert(continued==1 and owner.warmPause==nil);modal:release()
 assert(not P.resumeNotice(owner),'resume notice once per restored Explore')
 owner.warmResumeShown=nil;data[roleMapInfo].willFight='battle'
 assert(not P.resumeNotice(owner),'pending fight is not intercepted')
 local ok,reason=P.checkpoint(owner,dm,SaveDataManager);assert(not ok and reason=='unavailable' and data[roleMapInfo].willFight=='battle')
 data[roleMapInfo].willFight=nil
 owner.statue='Triggering';assert(P.open(owner)==nil);owner.statue='ready'
 owner.moveWaitingQueue={1};assert(P.open(owner)==nil);owner.moveWaitingQueue={}
 modal=assert(P.open(owner));modal:retain();owner:removeFromParent(true)
 assert(owner.warmPause==nil and modal:getParent()==nil,'owner teardown disposes scene-owned pause')
 modal:close();modal:release();owner:release();scene:cleanup();scene:release();scene=nil
 print('PASS native WarmPause '..height..': prior-pause preservation, frozen sailing actions, same-scene continue, partial/save retry, no fee/reset, cold notice/pending-fight gate, bounds and cleanup')
end
cc.Director.getInstance=realGet
