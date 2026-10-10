-- Real Talent page/data/event functions with mocked Cocos nodes and BaseView UI.
-- No game launch or player-save access. This does not prove native rendering or
-- the original BaseView/SDButton cooldown implementation (accepted separately).
local function read(path)
    local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s
end
-- Reuse the established read-only harness without changing its source. Export
-- only fixture helpers from the same chunk, so packaged CSV decoding and real
-- DataManager event semantics remain identical to the Home regression.
local exports=[[
return {fixture=fixture, node=node, methods=Node, dm=dm, csv=csv,
    packagedCSV=packagedCSV, snapshot=snapshot, textTree=textTree,
    setData=function(key,value)data[key]=value end,
    roleSnapshot=function()return snapshot(data)end,
    listeners=countListeners, dispatcher=dispatcher}
]]
local H=assert(loadstring(read('tools/tests/home_master_regression.lua')..exports,'@talent-readonly-harness'))()
local originalRequire=require
require=function(name)if name=='LuaClass/MasterTheme' then return MasterTheme end;return true end
local N=H.methods
function N:getTexture()return {setAntiAliasTexParameters=function()end}end
function N:setContainer(n)self.container=n;self:addChild(n)end
function N:setClippingToBounds(v)self.clipping=v end
function N:setBounceable(v)self.bounce=v end
function N:setDirection(v)self.direction=v end
function N:setContentOffset(v)self.offset=v end
function N:getViewSize()return self.viewSize or self.size end
cc.ScrollView={create=function(_,size)local n=H.node('ScrollView');n:setContentSize(size);n.viewSize=size;return n end}
local oldBaseView=BaseView
BaseView={create=function()
    local v=H.node('TalentBase')
    for _,field in ipairs({'mainBg','titleBg','storeMenu'})do v[field]=H.node();v:addChild(v[field])end
    function v:addInfoNode(...)
        local a={...};self.baseInfoArguments=a
        self.infoNode=H.node();self:addChild(self.infoNode)
        self.setBtn=H.node('OriginalAlchemyButton');self.setBtn.normalSpr=H.node('NormalSprite');self.setBtn.selectSpr=H.node('SelectedSprite')
        self.setBtn:addChild(self.setBtn.normalSpr);self.setBtn:addChild(self.setBtn.selectSpr)
        self.setButtonProgrees=H.node('OriginalCooldown');self.setBtn:addChild(self.setButtonProgrees)
        self.setBtn.callback=a[7];self.infoNode:addChild(self.setBtn)
        self.oldInfoMenu=H.node('LegacyInfoMenu');self.infoNode:addChild(self.oldInfoMenu)
    end
    return v
end}
dofile('bin/res/scripts/LuaClass/Talent.lua')
local talentCSV=H.packagedCSV('talent');H.csv[csvOfTalent]=talentCSV
local ids={};for id in pairs(talentCSV)do ids[#ids+1]=id end;table.sort(ids);assert(#ids>1)
local csvBefore=H.snapshot(H.csv)
local oldDirector=cc.Director.getInstance
local oldAlchemy=H.dm.AlchemyButtonDidClick
local oldToast,oldRandom,oldDispatch=ToastUtil,RandomEventView,zqDispatch
local oldIsEnterMap=isEnterMap
local toast,alchemyCalls,intelligenceCalls,backCalls=nil,0,0,0
ToastUtil={downString=function(_,text)toast=text end}
RandomEventView={create=function()intelligenceCalls=intelligenceCalls+1;return {show=function()end}end}
H.dm.AlchemyButtonDidClick=function()alchemyCalls=alchemyCalls+1 end
zqDispatch={backToLastView=function()backCalls=backCalls+1 end,moveToExpedition=function()end}
local function equal(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
for _,height in ipairs({1136,1066.6666666667})do
    cc.Director.getInstance=function()local d=oldDirector();d.getVisibleSize=function()return {width=640,height=height}end;return d end
    for _,selection in ipairs({{}, {['1']=ids[1]}, {['2']=ids[1],['8']=ids[2]}, {['1']='999999'}})do
        H.fixture();H.setData(roleTalent,selection);H.setData(roleMapInfo,{curIndex=6});isEnterMap=false
        local before=H.roleSnapshot();local baseline=H.listeners()
        local v=assert(TalentLayer:create())
        equal(H.listeners(),baseline+5,'five real subscriptions')
        assert(v.approvedPage and v.keepNavigation==false,'own page chrome')
        equal(v.baseInfoArguments[9],true,'original alchemy progress enabled')
        equal(v.baseInfoArguments[10],zqAlchemyTime,'original alchemy cooldown value')
        equal(v.baseInfoArguments[11],false,'original alchemy light option')
        assert(not v.oldInfoMenu:isVisible() and not v.storeMenu:isVisible(),'old controls hidden')
        equal(v.alchemyButton,v.setBtn,'reuse original alchemy button')
        assert(not v.setButtonProgrees:isVisible(),'restyle hides progress presentation only')
        local expected=0;for _ in pairs(selection)do expected=expected+1 end
        equal(#v.talentEntries,expected,'only real acquired entries')
        equal(#v.scrollViewContainer.children,expected,'one node per acquired entry')
        equal(v.alertLabel:isVisible(),expected==0,'empty message')
        for _,entry in ipairs(v.talentEntries)do
            equal(selection[tostring(entry.index)],entry.id,'actual selected ID')
            local record=talentCSV[entry.id]
            assert(H.textTree(v):find(record and record[dataKeyName] or ('天赋 '..entry.id),1,true),'actual name or neutral unknown ID')
        end
        if expected==2 then equal(v.talentEntries[1].index,8,'newest sparse index first')end
        for _=1,4 do v:loadTalentData()end
        equal(#v.scrollViewContainer.children,expected,'refresh removes previous rows')
        assert(v.talentChapter:getString():find('第六章',1,true),'real map chapter')
        equal(H.roleSnapshot(),before,'init and refresh never mutate role data')
        equal(H.snapshot(H.csv),csvBefore,'static CSV unchanged')
        H.setData(roleTalent,{['3']=ids[1]});H.dm:postEvent(roleTalent,nil)
        equal(#v.talentEntries,1,'acquired talent event refresh')
        equal(v.talentEntries[1].index,3,'event uses latest data')
        H.setData(roleMoney,9876);H.dm:postEvent(roleMoney,nil);equal(v.talentCoin:getString(),'9876','live coin')
        H.setData(roleDiamond,345);H.dm:postEvent(roleDiamond,nil);equal(v.talentDiamond:getString(),'345','live diamond')
        H.setData(roleMapInfo,nil);H.dm:postEvent(roleMapInfo,nil);equal(v.talentChapter:getString(),'冒险天赋','no-map chapter fallback')
        local opened=intelligenceCalls;toast=nil;v.talentIntelligence.item.callback()
        equal(intelligenceCalls,opened,'intelligence blocked before map');assert(toast and toast:find('船坞',1,true))
        H.setData(roleMapInfo,{curIndex=2});isEnterMap=true;v.talentIntelligence.item.callback();equal(intelligenceCalls,opened,'intelligence blocked at sea')
        isEnterMap=false;v.talentIntelligence.item.callback();equal(intelligenceCalls,opened+1,'original intelligence entry')
        local called=alchemyCalls;v.alchemyButton.callback();equal(alchemyCalls,called+1,'original alchemy callback')
        local backed=backCalls;v.talentBackButton.item.callback();equal(backCalls,backed+1,'original Back route')
        local frozen=H.roleSnapshot();v.setBtn.normalSpr:runAction({kind='pending-hold'})
        v:destory();equal(H.listeners(),baseline,'five event subscriptions removed')
        equal(#v.setBtn.normalSpr.actions,0,'old long-press actions stopped')
        local current=v.talentCoin:getString();H.dm:postEvent(roleMoney,nil);equal(v.talentCoin:getString(),current,'disposed view stays unsubscribed')
        v:destory();equal(H.listeners(),baseline,'idempotent cleanup');equal(H.roleSnapshot(),frozen,'cleanup read-only')
    end
    print('PASS Talent '..height..': real CSV, empty/sparse/unknown/refresh, original action contracts, gates, five-event cleanup and read-only rendering')
end
cc.Director.getInstance=oldDirector;BaseView=oldBaseView;require=originalRequire
H.dm.AlchemyButtonDidClick=oldAlchemy;ToastUtil=oldToast;RandomEventView=oldRandom;zqDispatch=oldDispatch;isEnterMap=oldIsEnterMap
