-- Optional execution in the existing chart-lifecycle-native LuaEngine harness.
-- Real Cocos nodes/actions/cleanup; scene selection is supplied locally, so this
-- is not GUI or full Director push/pop integration acceptance. No game/save.
require('extern')
local originalRequire=require
local originalDirector=cc.Director.getInstance
local director=originalDirector(cc.Director)
local scene
cc.Director.getInstance=function()return{getRunningScene=function()return scene end,getVisibleSize=function()return cc.size(640,1136)end}end
require=function()return true end
dofile(os.getenv('PIRATE_DIALOGUE_SOURCE') or 'bin/res/scripts/LuaClass/DialogueView.lua')
require=originalRequire
local manager=DialogueViewManager:sharedInstance()
local function fresh()
    local s=cc.Scene:create();s:retain();nativeEnter(s);return s
end
local function finishActions()
    for i=1,5 do director:getActionManager():update(.1)end
end
local function dispose(s)
    nativeExit(s);s:cleanup();s:release();nativeDrain()
end
scene=fresh()
local oldScene=scene
local stale=DialogueView:create();stale:show()
assert(manager:Count()==1)
dispose(oldScene)
scene=fresh()
local replacement=DialogueView:create();replacement:show()
assert(manager:Count()==1 and replacement:getParent()==scene)
replacement:close();replacement:close();finishActions();assert(manager:Count()==0)
print('PASS native DialogueView scene destruction/replacement and repeated close')

local lowerScene=scene
local lower=DialogueView:create();lower:show();lower:show()
assert(manager:Count()==1)
nativeExit(lowerScene)
scene=fresh()
local upper=DialogueView:create();upper:show();upper:close();finishActions()
assert(manager:Count()==0)
dispose(scene);scene=lowerScene;nativeEnter(scene)
assert(manager:Count()==1 and lower:getParent()==scene)
lower:close();finishActions();assert(manager:Count()==0)
print('PASS native DialogueView independent paused/reentered scene stacks')

local callbackEvents=0
local view=DialogueView:create()
view:registerScriptHandler(function(event)if event=='cleanup'then callbackEvents=callbackEvents+1 end end)
view:show();view:removeFromParent();assert(manager:Count()==0 and callbackEvents==1)
local first=DialogueView:create();first:show();first:close()
local second=DialogueView:create();second:show()
manager:removeAllView();manager:removeAllView();finishActions()
assert(manager:Count()==0)

-- Real Lackmaterial UI and native MenuItem::activate execute the partial-buy
-- handler, its reflush, and its rebuilt close button. Only economy/guide/toast
-- boundaries are in memory; no DataManager initialization or save is loaded.
require=function()return true end
for _,name in ipairs({'HomeTheme','MasterTheme','ManagementTheme','ProductionSources','Lackmaterial'})do
    dofile('bin/res/scripts/LuaClass/'..name..'.lua')
end
require=originalRequire
local items={};local originalItem=ManagementTheme.menuItem
ManagementTheme.menuItem=function(...)
    local item=originalItem(...);items[#items+1]=item;return item
end
local charged,granted,callbacks=0,0,0
DataManager={getInstance=function(self)return self end,
    getCSVByID=function()return {}end,getRoleData=function()return {}end,
    getSound_off=function()return 1 end,getStoreUnlockTable=function()return{['1007']=true,['1008']=true}end,
    addCoin=function(_,value)charged=charged+value;return 1 end,
    addPackItemWithId=function(_,id,n)assert(id=='1007' and n==2);granted=granted+n end}
GuideController={getInstance=function(self)return self end,getIsHaveStep=function(_,id)assert(id==2 or id==5);return true end}
ToastUtil={toastString=function()end}
local rows={{mtId='1007',mtname='wood',mtprice='3',mtnum='2',mtStar='1',mtonlyProduce='0'},
    {mtId='1008',mtname='iron',mtprice='4',mtnum='1',mtStar='1',mtonlyProduce='0'}}
local materials=assert(Lackmaterial:create(rows,function()callbacks=callbacks+1 end));materials:show()
local observer=materials._dialogueLifecycle
assert(#items==4);items[2]:activate()
assert(#rows==1 and rows[1].mtId=='1008' and charged==-6 and granted==2 and callbacks==1)
assert(manager:Count()==1 and materials:getParent()==scene and observer:getParent()==materials)
assert(#items==7);items[5]:activate();finishActions()
assert(manager:Count()==0 and materials:getParent()==nil)
ManagementTheme.menuItem=originalItem
print('PASS native actual Lackmaterial partial purchase, remaining-row reflush, rebuilt native-menu close')

dispose(scene)
scene=fresh();DialogueView:create():show();assert(manager:Count()==1)
dispose(scene);scene=nil
cc.Director.getInstance=originalDirector
print('PASS native DialogueView external removal, subclass handler, pending-close bulk teardown, fresh reopen')
