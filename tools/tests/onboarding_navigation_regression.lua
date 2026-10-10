-- Reuse the native-API-shaped Home fixture, then exercise the real guide,
-- MainMenu events, alchemy threshold and build-completion message code.
-- Rendering/dispatch destinations and role storage are isolated in memory;
-- this is not GUI acceptance and never initializes a player save.
dofile('tools/tests/home_master_regression.lua')
local root='bin/res/scripts/LuaClass/'
local originalRequire=require
require=function()return true end
dofile(os.getenv('PIRATE_ONBOARDING_DATA_SOURCE') or root..'DataManager.lua')
dofile(os.getenv('PIRATE_ONBOARDING_MENU_SOURCE') or root..'MainMenu.lua')
dofile(root..'GuideController.lua')
local function equal(actual,expected,context)
    assert(actual==expected,context..': expected '..tostring(expected)..', got '..tostring(actual))
end
local function cloneTable(value)
    if type(value)~='table' then return value end
    local out={};for k,v in pairs(value)do out[k]=cloneTable(v)end;return out
end
clone=cloneTable
local role={
    [roleMoney]=0,[roleDiamond]=0,[roleGuideStep]='',[roleAlchemyUnit]=1,
    [roleAlchemyCanLongPress]=0,[roleBuilding]={{[dataKeyID]='1',[dataKeyNum]=0}},
    [roleStorageInfo]={[achievement_Alchemy]=0}
}
local roleWrites={}
local dm=DataManager.new();DataManagerSingleton=dm
dm.__eventListener={};dm.__eventDispatcher=cc.Node:create():getEventDispatcher()
dm.__roleData={
    getRoleData=function(_,key)return role[key]end,
    setRoleData=function(_,key,value)role[key]=value;roleWrites[#roleWrites+1]=key end,
    getSound=function()return 1 end,
    saveData=function()end
}
-- Achievement unlock rewards are outside this navigation regression. Its
-- existing increment still executes, but no achievement/save fixture is loaded.
function dm:unlockAchievement()end
function dm:checkAutoLearnedTallent()end
local warehouseText='你建造了仓库，现在去收集一些东西吧。'
local houseText='原民房建成提示'
local buildingCSV={['1']={successDesc=warehouseText},['2']={successDesc=houseText}}
dm.__staticData={getCSVByID=function(_,key)assert(key==csvOfBuild);return buildingCSV end}
function dm:unlockUnitWithCsvData()end
MissionManagers={getInstance=function()return{onTriggerMission=function()end}end}
ToastUtil={downString=function(_,text)_G.lastToast=text end, alchemyCoins=function()end}
pNeedUpdateLayer=nil
SystemInfoData={}
local scene=cc.Node:create()
local menu=assert(MainMenuLayer:create());scene:addChild(menu)
local guide=GuideController:getInstance()
local destinations={}
zqDispatch={gotoBuild=function()destinations[#destinations+1]='build' end,
    moveToResource=function()destinations[#destinations+1]='resource' end}
local function tapPort(key)
    menu.navigationButtons[4].callback()
    equal(menu.navigationButtons[4].bLabel:getString(),'港务','visible group label')
    local item=assert(menu.groupRouteButtons[key],'visible port entry '..key)
    item.callback()
end
local function storyCount(text)
    local n=0;for _,line in ipairs(SystemInfoData)do if line==text then n=n+1 end end;return n
end
local function finishStory()
    -- Advance only MainMenu's one-shot story sequence; visual actions on its
    -- descendants remain in the mock and are not mistaken for native timing.
    local cursor=1
    while cursor<=#(menu.actions or {})do
        local action=menu.actions[cursor];cursor=cursor+1
        if action.kind=='Sequence' then
            for _,child in ipairs(action.args)do
                if child.kind=='CallFunc' then child.args[1]() end
            end
        end
        assert(cursor<30,'story must terminate')
    end
    menu.actions={}
end
tapPort('build');equal(#destinations,0,'construction is locked before ten alchemy clicks')
for i=1,9 do dm:AlchemyButtonDidClick() end
equal(role[roleMoney],9,'nine actual alchemy callbacks retain their coin amount')
equal(guide:getIsHaveStep(1),false,'nine clicks do not unlock construction')
equal(storyCount('建设已解锁！'),0,'no early unlock story')
tapPort('build');equal(#destinations,0,'construction remains locked at nine clicks')
dm:AlchemyButtonDidClick();finishStory()
equal(role[roleMoney],10,'tenth callback retains the ten-coin total')
equal(role[roleStorageInfo][achievement_Alchemy],10,'existing achievement increment retained')
equal(guide:getIsHaveStep(1),true,'original step 1 threshold retained')
equal(guide:getIsHaveStep(101,true),true,'original one-shot story marker retained')
equal(storyCount('建设已解锁！'),1,'construction unlock is named')
equal(storyCount('点击底部“港务”，再选择“建设”。'),1,'story names the visible two-tap route')
equal(menu.MainMenuButtonGroup:isVisible(),false,'legacy strip remains hidden')
equal(#menu.navigationButtons,4,'approved four-group layout retained')
assert(menu.navigationButtons[4]:getChildByTag(9527),'port inherits construction red point')
tapPort('build');equal(destinations[1],'build','instructed route reaches existing construction dispatch')
dm:postEvent(roleGuideStep);finishStory()
equal(storyCount('点击底部“港务”，再选择“建设”。'),1,'guide refresh does not repeat completed story')
print('PASS onboarding real ten-click alchemy gate, one-shot story, visible port/construction route and unchanged layout')

tapPort('resource');equal(#destinations,1,'gathering still requires the original warehouse step')
local coins,diamonds=role[roleMoney],role[roleDiamond]
dm:createSuccessCheck(kUnlockBuild,'1')
local expected=warehouseText..'\n点击底部“港务”，再选择“采集”。'
equal(SystemInfoData[#SystemInfoData],expected,'warehouse keeps original prose plus actual navigation')
equal(guide:getIsHaveStep(2),true,'original warehouse unlock retained')
equal(role[roleBuilding][1][dataKeyNum],1,'original built flag retained')
equal(buildingCSV['1'].successDesc,warehouseText,'CSV description remains unmodified')
assert(menu.navigationButtons[4]:getChildByTag(9527),'port inherits gathering red point')
tapPort('resource');equal(destinations[2],'resource','instructed route reaches existing gathering dispatch')
dm:createSuccessCheck(kUnlockBuild,'1')
equal(storyCount(expected),1,'repeat completion does not resend first-build message')
role[roleBuilding][2]={[dataKeyID]='2',[dataKeyNum]=0}
dm:createSuccessCheck(kUnlockBuild,'2')
equal(SystemInfoData[#SystemInfoData],houseText,'other building descriptions are unchanged')
equal(role[roleMoney],coins,'completion prose adds no coin mutation')
equal(role[roleDiamond],diamonds,'completion prose adds no diamond mutation')
menu:destory()
require=originalRequire
print('PASS onboarding warehouse/gathering direction, original unlocks, duplicate-completion guard and unrelated building prose')
