-- Real Cocos nodes, MenuItem activation, font metrics and cleanup through the
-- existing tutorial-log-native EGL/LuaEngine harness. No game or save is opened.
local originalRequire=require
local theme
require=function(name) if name=='LuaClass/WarmTheme' then return theme end;return true end
BoldFont='Noto Serif CJK SC'
dofile('bin/res/scripts/LuaClass/HomeTheme.lua')
dofile('bin/res/scripts/LuaClass/MasterTheme.lua')
theme=dofile('bin/res/scripts/LuaClass/WarmTheme.lua')
local settings=dofile('bin/res/scripts/LuaClass/WarmSettings.lua')
local flags={sound=0,music=0,effect=0};local writes=0
DataManager={getInstance=function(self)return self end,
 getSound_off=function()return flags.sound end,setSound_off=function(_,v)flags.sound=v;writes=writes+1 end,
 getMusic_off=function()return flags.music end,setMusic_off=function(_,v)flags.music=v;writes=writes+1 end,
 getEffect_off=function()return flags.effect end,setEffect_off=function(_,v)flags.effect=v;writes=writes+1 end}
AudioEngine={pauseMusic=function()end,resumeMusic=function()end,playMusic=function()end}
local scene,viewport
local originalDirector=cc.Director.getInstance
cc.Director.getInstance=function() return {
 getRunningScene=function()return scene end,
 getVisibleSize=function()return viewport end,
 getVisibleOrigin=function()return cc.p(0,0)end
} end
local function fresh()
 scene=cc.Scene:create();scene:retain()
 local owner=cc.Node:create();scene:addChild(owner);return owner
end
local function dispose()
 scene:cleanup();scene:release();scene=nil
end
for _,height in ipairs({960,1067,1136}) do
 viewport=cc.size(640,height)
 local owner=fresh();local modal=assert(settings.open(owner));modal:retain()
 assert(modal==settings.open(owner),'reopen must not duplicate a live sheet')
 local panel=modal.panel;local sz=panel:getContentSize()
 assert(panel:getPositionY()>=0 and panel:getPositionY()+sz.height<=height,'settings within viewport')
 for _,child in ipairs(panel:getChildren()) do
  if child.getString and child:getString()~='' then
   local actual=child:getContentSize()
   assert(child:getPositionX()-actual.width*child:getAnchorPoint().x>=-1,'text stays within left edge')
   assert(child:getPositionX()+actual.width*(1-child:getAnchorPoint().x)<=sz.width+1,'text stays within right edge')
  end
 end
 modal.soundToggle:activate();assert(flags.sound==1,'native sound activation')
 modal.soundToggle:activate();assert(flags.sound==0,'native sound reactivation')
 modal.musicToggle:activate();assert(flags.music==1,'native music activation')
 modal.musicToggle:activate();assert(flags.music==0,'native music reactivation')
 modal.effectToggle:activate();assert(flags.effect==1,'native effect activation')
 modal.effectToggle:activate();assert(flags.effect==0,'native effect reactivation')
 modal.doneButton:activate();assert(owner.warmSettingsModal==nil and modal:getParent()==nil)
 modal:close();modal:release()
 local reopened=assert(settings.open(owner));reopened:retain()
 owner:removeFromParent(true)
 assert(reopened:getParent()==nil,'owner removal detaches scene-owned sheet')
 reopened:close();reopened:release();dispose()
 print('PASS native WarmSettings '..height..'pt viewport: label bounds, toggles, duplicate open, Done, owner removal')
end
viewport=cc.size(640,960)
local owner=fresh();local modal=assert(settings.open(owner));modal:retain()
dispose();assert(modal:getParent()==nil,'scene teardown detaches settings sheet')
modal:close();modal:release()
assert(writes==18,'only requested native control activations write preferences')
cc.Director.getInstance=originalDirector;require=originalRequire
print('PASS native WarmSettings scene teardown, idempotent close, no navigation/save writes')
