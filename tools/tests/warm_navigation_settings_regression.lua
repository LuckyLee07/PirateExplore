-- Native-API-shaped contract test. The legacy suite supplies its Cocos fixture;
-- it is also run first to assert mode-off behavior was not regressed.
dofile('tools/tests/home_master_regression.lua')
-- This fixture models a running scene; full native exit-order coverage lives
-- in coherent_pause_close_native.lua, not this API-shaped navigation fixture.
local NavigationNode=getmetatable(cc.Node:create()).__index
function NavigationNode:isRunning() return not self.cleaned end
local root = 'bin/res/scripts/LuaClass/'
local originalRequire = require
local function equal(actual, expected, context)
    assert(actual == expected, context .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end
local modules = {}
require = function(name)
    if name == 'LuaClass/WarmTheme' or name == 'LuaClass/WarmSettings' then
        if not modules[name] then modules[name] = assert(loadfile('bin/res/scripts/' .. name .. '.lua'))() end
        return modules[name]
    end
    return true
end
local theme = require('LuaClass/WarmTheme')
local settings = require('LuaClass/WarmSettings')
WARM_PIRATE_V1 = nil
equal(theme.enabled(), true, 'isolated warm branch defaults on')
local scene = cc.Node:create()
local size, origin = {width=640,height=960}, {x=0,y=0}
cc.Director.getInstance = function() return {
    getVisibleSize=function() return size end,
    getVisibleOrigin=function() return origin end,
    getRunningScene=function() return scene end
} end
local dm = DataManager:getInstance()
local data = {[roleMoney]=100, [roleDiamond]=5}
local flags, saves = {sound=0,music=0,effect=0}, 0
local ledger = {}
dm.__roleData = {
    getRoleData=function(_,key) return data[key] end,
    getSound=function() return flags.sound end, setSound=function(_,v) flags.sound=v end,
    getMusic=function() return flags.music end, setMusic=function(_,v) flags.music=v end,
    getEffect=function() return flags.effect end, setEffect=function(_,v) flags.effect=v end,
    saveData=function() saves=saves+1 end
}
dm.setSound_off=DataManager.setSound_off; dm.setMusic_off=DataManager.setMusic_off
dm.setEffect_off=DataManager.setEffect_off
local audio = {}
AudioEngine = {
    playEffect=function() end,
    pauseMusic=function() audio[#audio+1]='pause' end,
    resumeMusic=function() audio[#audio+1]='resume' end,
    playMusic=function(path,loop) audio[#audio+1]='play';equal(loop,true,'music loops') end
}
local unlocked = true
local guide = {
    getIsHaveStep=function(_,step) if step==8 then return unlocked end; return true end,
    addStep=function(_,step,flag) ledger[#ledger+1]={step,flag} end,
    addRedPoint=function() end, removeRedPoint=function() end
}
GuideController = {getInstance=function() return guide end}
ToastUtil = {quietHomeProductionToasts=function() end, downString=function(_,text) _G.lastToast=text end}
RandomEventLayer = {create=function() return cc.Node:create() end}
local warmCreates, legacyCreates, destroyed = 0, 0, 0
local function page(kind, home)
    local n = cc.Node:create();n.kind=kind;n.isAdventureHome=home
    function n:refreshSummary() self.refreshes=(self.refreshes or 0)+1 end
    function n:updateInfoLabel(text) self.info=text end
    function n:viewWillDestory() self.willDestroy=(self.willDestroy or 0)+1 end
    function n:destory() self.destroyed=(self.destroyed or 0)+1;destroyed=destroyed+1 end
    return n
end
WarmHomeLayer={create=function() warmCreates=warmCreates+1;return page('warmHome',true) end}
HomeLayer={create=function() legacyCreates=legacyCreates+1;return page('legacyHome',true) end}
ExpeditionLayer={create=function() local n=page('expedition');n.approvedPage=true;n.keepNavigation=true;return n end}
SettingLayer={create=function() return page('legacySettings') end}
dofile(root .. 'MainMenu.lua')
dofile(root .. 'Dispatch.lua')
local dispatch=assert(Dispatch:create(false));scene:addChild(dispatch)
local menu=dispatch.mainMenu
local home=dispatch.rightNode
equal(home.kind,'warmHome','default warm home dispatched')
equal(menu.groupNavigation:isVisible(),false,'no warm global footer groups')
equal(menu.navigationBg:isVisible(),false,'legacy footer strip hidden')
equal(menu.MainMenuButtonGroup:isVisible(),false,'hidden guide targets retained')
equal(menu.warmReturnButton:isVisible(),false,'home has no global back')
equal(menu.legacyTopBg:isVisible(),false,'home owns its header')
equal(menu.coinNode:isVisible(),false,'home suppresses global currency')
equal(menu.boatSpr:isVisible(),false,'no roaming paid decoration over home')
equal(menu.homeHeader,nil,'legacy home header never created in warm mode')
assert(menu.expeditionBtn and menu.buildBtn and menu.storeBtn,'guide targets still exist')
equal(saves,0,'opening warm UI never writes a save')
dispatch:moveToHome();equal(warmCreates,1,'same home refreshes without reconstruction')
unlocked=false;menu:openRoute(1);equal(dispatch.rightNode,home,'original dock gate remains enforced')
unlocked=true;menu:openRoute(1)
local expedition=dispatch.rightNode
equal(expedition.kind,'expedition','original route still reached')
equal(home.destroyed,1,'leaving home destroys once')
equal(home.willDestroy,1,'leaving home cleanup once')
equal(menu.warmReturnButton:isVisible(),true,'business page shows return to ship')
equal(menu.groupNavigation:isVisible(),false,'business page keeps grouped footer hidden')
equal(menu.legacyTopBg:isVisible(),false,'approved page keeps its own header')
local selected=menu:getSelectedIndex()
local modal=dispatch:gotoSetting()
equal(dispatch.rightNode,expedition,'settings keeps exact underlying page')
equal(dispatch:gotoSetting(),modal,'repeated settings returns same modal')
equal(expedition.destroyed,nil,'settings does not destroy a route')
equal(menu:getSelectedIndex(),selected,'settings keeps selected route')
equal(modal:getParent(),scene,'modal is above the complete dispatch chrome')
equal(modal.isAdventureModal,true,'production-only toast suppression marker')
local listeners=modal:getEventDispatcher().listeners
local function touchCount()
    local count=0;for _,entry in ipairs(listeners) do if entry.owner and entry.swallow then count=count+1 end end;return count
end
equal(touchCount(),1,'one touch-swallowing settings listener')
modal.soundToggle.callback();equal(flags.sound,1,'sound preference off');equal(saves,1,'sound persisted once')
modal.soundToggle.callback();equal(flags.sound,0,'sound preference on');equal(saves,2,'sound persisted again')
modal.musicToggle.callback();equal(flags.music,1,'music off');equal(audio[#audio],'pause','live music paused')
HAS_MUSIC_FILE=1;modal.musicToggle.callback();equal(flags.music,0,'music on');equal(audio[#audio],'resume','live music resumed')
modal.musicToggle.callback();HAS_MUSIC_FILE=0;modal.musicToggle.callback();equal(audio[#audio],'play','missing music restarts actual music')
modal.effectToggle.callback();equal(flags.effect,1,'battle effects off');equal(saves,7,'all controls use existing persisted setters')
modal.doneButton.callback();equal(expedition.warmSettingsModal,nil,'done clears ownership')
equal(dispatch.rightNode,expedition,'done restores same route');equal(touchCount(),0,'done removes touch listener')
modal:close();equal(touchCount(),0,'double close is harmless')
modal=dispatch:gotoSetting();equal(modal.effectToggleLabel:getString(),'关闭','reopen reads persisted preference')
dispatch:backToLastView();equal(dispatch.rightNode,expedition,'back closes settings without route replacement')
equal(expedition.warmSettingsModal,nil,'back clears sheet')
modal=dispatch:gotoSetting();menu.warmReturnButton.item.callback()
equal(expedition.destroyed,1,'route change destroys old page once')
equal(expedition.warmSettingsModal,nil,'route change closes old sheet')
equal(touchCount(),0,'route change removes sheet listener')
equal(dispatch.rightNode.kind,'warmHome','native return reaches ship')
local utility=page('utility');dispatch:setViewWithDirection(utility,false,1)
equal(menu.legacyTopBg:isVisible(),true,'legacy business header remains available')
equal(menu.warmReturnButton:isVisible(),true,'legacy business return remains visible')
dispatch:backToLastView();equal(dispatch.rightNode.kind,'warmHome','utility back cannot strand selected route')
equal(utility.destroyed,1,'utility leaves exactly once')
local talent=page('talent');talent.approvedPage=true;talent.keepNavigation=false
dispatch:setViewWithDirection(talent,false,1)
equal(menu.warmReturnButton:isVisible(),false,'page-owned Talent footer is not doubled')
dispatch:backToLastView();equal(dispatch.rightNode.kind,'warmHome','Talent back returns to warm home')
modal=dispatch:gotoSetting();dispatch:destory()
equal(modal:getParent(),nil,'dispatch removal closes scene-owned settings')
equal(touchCount(),0,'dispatch removal leaves no settings touches')
local cleanupCount=destroyed;dispatch:destory();equal(destroyed,cleanupCount,'dispatch destroy is idempotent')

-- Owner exit without Dispatch must also detach the scene-owned modal.
local owner=page('owner');scene:addChild(owner);modal=settings.open(owner)
owner:removeFromParent(true);equal(modal:getParent(),nil,'external owner cleanup closes modal')
equal(owner.warmSettingsModal,nil,'external owner cleanup clears reference');equal(touchCount(),0,'owner cleanup removes listener')

WARM_PIRATE_V1=false
dispatch=assert(Dispatch:create(false));scene:addChild(dispatch)
equal(dispatch.rightNode.kind,'legacyHome','explicit mode false dispatches original home')
equal(dispatch.mainMenu.groupNavigation:isVisible(),true,'mode false retains original four groups')
assert(dispatch.mainMenu.homeHeader:isVisible(),'mode false retains original home header')
dispatch:gotoSetting();equal(dispatch.rightNode.kind,'legacySettings','mode false keeps original settings route')
dispatch:destory()
equal(saves,7,'navigation and cleanup did not change gameplay or saved preferences')
require=originalRequire
print('PASS Warm navigation: native home/default opt-out, original gates, business return, modal audio persistence, exact-page restoration, and cleanup')
