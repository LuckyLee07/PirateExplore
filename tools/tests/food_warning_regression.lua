-- Actual ExploreBagController initialization, Explore HUD/checkBread/warning
-- methods and lazy font layout, with role storage isolated in memory.
-- Also runs in the existing headless real Cocos/action harness.
-- No Explore:init, map creation, movement, reward or player-save initialization.
local native=type(nativeEnter)=='function'
if native then require('extern') else
    dofile('tools/tests/home_master_regression.lua')
    local methods=getmetatable(cc.Node:create()).__index
    function methods:getNumberOfRunningActions()return #(self.actions or {})end
    function methods:setRotation(value)self.rotation=value end
end
local originalRequire=require
require=function(name)
    if name=='LuaClass/SeaChartWorldTheme' then return SeaChartWorldTheme end
    return true
end
for _,name in ipairs({'Header','HomeTheme','MasterTheme','SeaChartWorldTheme','SeaChartTheme','ExploreBagController'})do
    dofile('bin/res/scripts/LuaClass/'..name..'.lua')
end
dofile(os.getenv('PIRATE_FOOD_WARNING_SOURCE') or 'bin/res/scripts/LuaClass/Explore.lua')
require=originalRequire
screenSize=cc.size(640,1136);BoldFont='Arial'
local food=30
local role={[rolePack]={},[roleBattlePack]={['1005']={id='1005',num=food}},
    [roleBattleQueue]={},[rolePackSize]=30,[roleMapCoin]=0,[roleExtents]=0}
DataManager={getInstance=function(self)return self end,
    getRoleData=function(_,key)return role[key]end,
    setRoleData=function(_,key,value)
        assert(key==roleBattlePack,'only the real bag normalizer may update the in-memory pack')
        role[key]=value
    end}
local foodInfo={ID='1005',carryType='1',cubage='1',taskID='0',taskOk='0'}
dataController={resourceInfo={original={['1005']=foodInfo}},
    getResourceInfoById=function(id)assert(tostring(id)=='1005');return foodInfo end}
MissionManagers={getInstance=function(self)return self end,onTriggerMission=function()end}
local scene=cc.Node:create()
if native then scene:retain()end
local function fresh()
    local owner=Explore.new()
    role[roleBattlePack]={['1005']={id='1005',num=food}}
    -- Explore:init constructs the real controller before HUD; controller's
    -- initial capacity refresh must work while the HUD is not attached yet.
    owner.bagController=ExploreBagController:getBagController(owner)
    owner:initTipLayer();owner:checkBread();scene:addChild(owner)
    return owner
end
local function setFood(owner,count)
    food=count;role[roleBattlePack]['1005'].num=count
    owner.bagController:refreshBattlePack()
    owner:checkBread()
end
local function equal(actual,expected,why)assert(actual==expected,why..': '..tostring(actual)..' ~= '..tostring(expected))end
local function tick(seconds)
    if native then cc.Director:getInstance():getActionManager():update(seconds)end
end
local function visibleInk(node,parentsVisible)
    local visible=parentsVisible~=false and node:isVisible()
    local count=visible and node:getDescription():find('<Sprite |',1,true)
        and node:getDisplayedOpacity()>0 and 1 or 0
    for _,child in ipairs(node:getChildren())do count=count+visibleInk(child,visible)end
    return count
end
local function realizeWarning(owner)
    if native then
        -- LabelTTF creates its internal text Sprite lazily. Its outer opacity
        -- can be 0 while the newly created Sprite is still fully opaque.
        owner.warnningTips:getContentSize()
        owner.warnningTips:visit()
    end
end
local function high(owner,why)
    equal(owner.warnningTips:getOpacity(),0,why..' central warning transparent')
    equal(owner.warnningTips:getNumberOfRunningActions(),0,why..' no central warning action')
    realizeWarning(owner)
    if native then equal(visibleInk(owner.warnningTips),0,why..' no visible internal text Sprite after first visit')end
    equal(owner.warnningTips:isVisible(),false,why..' lazy text rendering is gated by visibility')
    equal(owner.warnningBox:isVisible(),false,why..' border hidden')
    equal(owner.warnningBox:getNumberOfRunningActions(),0,why..' no border action')
    for _,node in ipairs({owner.bread,owner.breadtitile})do
        equal(node:getOpacity(),255,why..' food HUD stays readable')
        equal(node:getNumberOfRunningActions(),0,why..' food HUD no longer flashes')
    end
end
local owner=fresh()
equal(owner.bread:getString(),'30','HUD uses supplied full food count')
equal(owner.warnningTips:getOpacity(),0,'full-food HUD hidden before any action tick')
owner:checkBread();high(owner,'initial full food')
if native then nativeEnter(scene)end
tick(.016);high(owner,'first native action tick')
tick(.016);high(owner,'second native action tick')
print('PASS real bag-before-HUD initialization, full-food warning first lazy font layout/visit and first two action ticks')

for _,count in ipairs({10,0,5})do
    setFood(owner,count)
    equal(owner.warnningTips:isVisible(),true,'low-food warning becomes visible again')
    equal(owner.warnningBox:isVisible(),true,'original <=10 threshold remains active at '..count)
    for _,node in ipairs({owner.warnningTips,owner.warnningBox,owner.bread,owner.breadtitile})do
        equal(node:getNumberOfRunningActions(),1,'one original warning animation at '..count)
    end
    owner:checkBread()
    equal(owner.warnningTips:getNumberOfRunningActions(),1,'repeat low check does not duplicate animation')
    for _=1,8 do tick(.05)end
    if native then
        assert(owner.warnningTips:getOpacity()>0,'real warning still fades into view')
        equal(visibleInk(owner.warnningTips),1,'low-food warning has one visible native text Sprite')
    end
    -- Reward scenes pause the existing Explore; cancellation must survive its
    -- later re-entry. These native hooks exercise Node exit/entry, not Director.
    if native and count==10 then nativeExit(scene)end
    setFood(owner,count==10 and 11 or 30)
    high(owner,'refilled to '..food)
    if native and count==10 then nativeEnter(scene)end
    for _=1,30 do tick(.05)end
    high(owner,'refilled warning cannot reappear on later action ticks')
    equal(food,count==10 and 11 or 30,'warning does not change food')
end
print('PASS original 0/5/10 low-food threshold, 11/30 refill cancellation, no duplicate or surviving central animation')

setFood(owner,5)
if native then nativeExit(scene)end
owner.bagController:destoryController()
owner:removeFromParent()
if native then nativeEnter(scene);nativeDrain()end
food=30;local nextVoyage=fresh();nextVoyage:checkBread()
high(nextVoyage,'fresh HUD after low-food page disposal')
tick(.016);tick(.016);high(nextVoyage,'fresh voyage after ticks')
if native then nativeExit(scene);scene:cleanup();scene:release();nativeDrain()end
print('PASS fresh full-food HUD after disposed low-food HUD; no original save, map, hunger or consumption rule touched')
