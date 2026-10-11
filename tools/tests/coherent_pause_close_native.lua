-- Real running-scene regression for closing/replacing the game while paused.
-- Uses native Cocos nodes/actions and disposable in-memory checkpoint storage.
-- No player profile, filesystem save, map, network, or desktop window is used.
require 'extern';require 'LuaClass/Header'
BoldFont='Noto Serif CJK SC';WARM_PIRATE_V1=true
local override=os.getenv('COHERENT_PAUSE_SOURCE')
local P=override and assert(loadfile(override))() or require 'LuaClass/WarmPause'
local realGet=cc.Director.getInstance;local director=realGet(cc.Director)
cc.Director.getInstance=function()return setmetatable({
 getVisibleSize=function()return cc.size(640,960)end,getVisibleOrigin=function()return cc.p(0,0)end},
 {__index=function(_,key)return function(_,...)return director[key](director,...)end end})end
local writes,continued,work,exits=0,0,0,0
local data={[roleStatue]=1,[roleMapInfo]={curIndex=1,playerTitlePosition={x=7,y=7}},
 [roleBreadCostDecimal]=.25,[mapInfo]={titlesInfo={['154']={fogId='0'}}},
 [roleBattlePack]={['1005']={id='1005',num=13}},[roleBattleQueue]={['100']=1},
 adventureProgressV1={version=1,enabled=true,activeVoyage=1,pending={episode='crew',action='rescue',choice='chart'}}}
local dm={getRoleData=function(_,key)return data[key]end,__roleData={commitAdventure=function(_,fields)
 writes=writes+1;for key,value in pairs(fields)do data[key]=value end;return true
end}}
DataManager={getInstance=function()return dm end}
SaveDataManager={getInstance=function(self)return self end,saveDataAtomic=function()writes=writes+1;return true end}
package.loaded['LuaClass/SaveDataManager']=true
local function frames()
 for _=1,5 do local deadline=os.clock()+.002;while os.clock()<deadline do end;director:mainLoop()end
end
local function begin()
 local scene=cc.Scene:create()
 if director:getRunningScene()then director:replaceScene(scene)else director:runWithScene(scene)end
 frames()
 local owner=cc.Layer:create();owner:retain();scene:addChild(owner)
 owner.statue='ready';owner.mapIndex=1;owner.playerTitlePosition={x=7,y=7};owner.breadCostDecimal=.75
 owner.moveWaitingQueue={};owner.moveDirectionQueue={};owner.eventManger={eventWaitingQueue={0}}
 owner.bagController={getBreads=function()return 13 end,costSpace=15,limited=30}
 local target=cc.Node:create();owner:addChild(target)
 target:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(.001),cc.CallFunc:create(function()work=work+1 end))))
 local modal=assert(P.open(owner,false,function()continued=continued+1 end));modal:retain()
 local witness=cc.Node:create();modal:addChild(witness)
 witness:registerScriptHandler(function(event)if event=='exit'then exits=exits+1 end end)
 assert(owner:isRunning() and modal:isRunning(),'fixture must enter real native scene')
 return scene,owner,modal
end
local function exited(node)
 assert(not node:isRunning(),'all pause descendants must receive native onExit before destruction')
 for _,child in ipairs(node:getChildren())do exited(child)end
end
-- User Continue remains immediate and resumes only the original voyage.
local scene,owner,modal=begin();local before=work;frames();assert(work==before,'sailing remains frozen while paused')
modal.continueButton:activate();frames();assert(continued==1 and work>before and not owner.warmPause)
modal:close();assert(continued==1,'stale close cannot repeat continuation')
modal:release();owner:removeFromParent(true);owner:release()
print('PASS native pause Continue remains immediate, frozen work resumes once')
-- A complete scene exit is the onExit/cleanup order used by desktop X and
-- Director::purgeDirector. Replacement lets the harness inspect survivors.
for _,saveFirst in ipairs({false,true})do
 for _,modalFirst in ipairs({false,true})do
  scene,owner,modal=begin();frames();local beforeWork,beforeContinue,beforeExits=work,continued,exits
  if saveFirst then modal.saveButton:activate();assert(modal.saveResult=='saved')end
  local beforeWrites=writes
  local staleContinue,staleSave=modal.continueButton,modal.saveButton
  staleContinue:retain();staleSave:retain()
  -- Exercise either sibling order; production uses owner-before-modal.
  if modalFirst then modal:setLocalZOrder(-1);scene:sortAllChildren()end
  -- Production does not retain its modal. Retaining it hides the destruction
  -- bug by keeping the removed sibling alive until the old traversal visits it.
  modal:release()
  director:replaceScene(cc.Scene:create());frames()
  assert(not owner.warmPause,'scene teardown clears pause ownership')
  assert(director:getRunningScene():getChildrenCount()==0,'no pause in replacement scene')
  exited(owner)
  assert(exits==beforeExits+1,'pause descendants exit exactly once')
  assert(not staleContinue:isRunning() and not staleSave:isRunning(),'retained controls also exit')
  staleContinue:activate();staleSave:activate()
  staleContinue:release();staleSave:release()
  assert(continued==beforeContinue and work==beforeWork,'teardown cannot continue or thaw a voyage')
  assert(writes==beforeWrites,'teardown and stale callbacks cannot create a checkpoint')
  assert(data[roleBattlePack]['1005'].num==13 and data.adventureProgressV1.pending.action=='rescue','cargo and pending outcome remain unchanged')
  owner:release();frames()
  print('PASS native whole-scene pause teardown: saved='..tostring(saveFirst)..', modalFirst='..tostring(modalFirst))
 end
end
-- Removing just Explore also tears down its scene-owned pause without leaving
-- sailing actions, event listeners, or callbacks active.
scene,owner,modal=begin();frames();local beforeWrites,beforeContinue=writes,continued
owner:removeFromParent(true);frames();assert(not owner.warmPause and not modal:getParent())
exited(owner);exited(modal);modal:close();assert(writes==beforeWrites and continued==beforeContinue)
modal:release();owner:release();frames()
-- Shared scene-owned sheets must also survive unretained native destruction,
-- including their default owner=scene path (the observer is then a sibling).
local actionCalls,preferenceWrites=0,0
local flags={sound=0,music=0,effect=0}
for _,key in ipairs({'sound','music','effect'})do
 dm['get'..key:sub(1,1):upper()..key:sub(2)..'_off']=function()return flags[key]end
 dm['set'..key:sub(1,1):upper()..key:sub(2)..'_off']=function(_,value)flags[key]=value;preferenceWrites=preferenceWrites+1 end
end
AudioEngine={pauseMusic=function()end,resumeMusic=function()end,playMusic=function()end}
package.loaded['AudioEngine']=true;package.loaded['LuaClass/DataManager']=true
local dialogOverride=os.getenv('COHERENT_PAUSE_DIALOG_SOURCE')
local settingsOverride=os.getenv('COHERENT_PAUSE_SETTINGS_SOURCE')
local D=dialogOverride and assert(loadfile(dialogOverride))() or require 'LuaClass/WarmDialog'
local S=settingsOverride and assert(loadfile(settingsOverride))() or require 'LuaClass/WarmSettings'
local function overlay(kind,sceneOwner)
 local live=cc.Scene:create();director:replaceScene(live);frames()
 local bound=sceneOwner and live or cc.Node:create();bound:retain()
 if not sceneOwner then live:addChild(bound)end
 local sheet;local argument=bound;if sceneOwner then argument=nil end
 if kind=='dialog' then
  sheet=D.show('离开页面','只检查原生关闭生命周期。',{{label='确认',action=function()actionCalls=actionCalls+1 end},{label='取消'}},argument)
 else sheet=S.open(argument)end
 sheet:retain()
 local witness=cc.Node:create();sheet:addChild(witness)
 witness:registerScriptHandler(function(event)if event=='exit'then exits=exits+1 end end)
 local controls=kind=='dialog' and {sheet.warmOptions[1].item,sheet.warmOptions[2].item}
  or {sheet.soundToggle,sheet.musicToggle,sheet.effectToggle,sheet.doneButton}
 for _,item in ipairs(controls)do item:retain()end
 assert(sheet:isRunning() and bound:isRunning(),'shared sheet enters actual native scene')
 return live,bound,sheet,controls
end
for _,kind in ipairs({'dialog','settings'})do
 for _,sceneOwner in ipairs({false,true})do
  for _,path in ipairs({'close','owner','scene','scene_modal_first'})do
   if not (sceneOwner and path=='owner')then
    local live,bound,sheet,controls=overlay(kind,sceneOwner);frames()
    local beforeActions,beforePreferences,beforeExits=actionCalls,preferenceWrites,exits
    if path=='close'then sheet:close();sheet:release()
    elseif path=='owner'then bound:removeFromParent(true);sheet:release()
    else
     if path=='scene_modal_first'then sheet:setLocalZOrder(-1);live:sortAllChildren()end
     sheet:release();director:replaceScene(cc.Scene:create())
    end
    frames()
    assert(not bound.adventureDialog and not bound.warmSettingsModal,'shared modal ownership cleared')
    assert(exits==beforeExits+1,'shared sheet descendants exit exactly once')
    if path=='scene' or path=='scene_modal_first'then exited(bound);assert(director:getRunningScene():getChildrenCount()==0)end
    for _,item in ipairs(controls)do assert(not item:isRunning());item:activate();item:release()end
    assert(actionCalls==beforeActions and preferenceWrites==beforePreferences,'disposed controls never invoke actions or change preferences')
    if not sceneOwner and bound:getParent()then bound:removeFromParent(true)end
    bound:release();frames()
    print('PASS native '..kind..' teardown: sceneOwner='..tostring(sceneOwner)..', path='..path)
   end
  end
 end
end
if COHERENT_PAUSE_CLOSE_ENGINE_END then
 -- The dedicated C++ runner invokes real Director::end/purgeDirector only
 -- after Lua returns, matching the desktop loop without deleting Director
 -- from inside a Lua binding callback. No artificial modal retention remains.
 scene,owner,modal=begin();modal.saveButton:activate();assert(modal.saveResult=='saved')
 COHERENT_PAUSE_CLOSE_EXITED=0
 local function closingWitness(sheet)
  local witness=cc.Node:create();sheet:addChild(witness)
  witness:registerScriptHandler(function(event)if event=='exit'then COHERENT_PAUSE_CLOSE_EXITED=COHERENT_PAUSE_CLOSE_EXITED+1 end end)
 end
 closingWitness(modal)
 closingWitness(D.show('离开页面','原生关闭检查。',{{label='取消'}},owner))
 closingWitness(S.open(owner))
 local sceneDialog=D.show('离开页面','场景所有者关闭检查。',{{label='取消'}})
 local sceneSettings=S.open()
 -- Also exercise layer-before-observer with a direct scene owner at purge.
 sceneDialog:setLocalZOrder(-2);sceneSettings:setLocalZOrder(-1)
 closingWitness(sceneDialog);closingWitness(sceneSettings)
 frames();modal:release();owner:release()
end
cc.Director.getInstance=realGet
print('PASS native pause owner teardown; all checks isolated from player saves')
