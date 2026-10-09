-- Run from the repository root with Lua 5.1 (or build/linux/tests/lua-ui-tests).
-- Cocos rendering is mocked, but Header constants, DataManager event dispatch,
-- system-log ordering, Home, HomeTheme, MainMenu and Dispatch are production Lua.
-- These contract/lifecycle tests complement native GUI acceptance.
unpack = unpack or table.unpack
local root = 'bin/res/scripts/LuaClass/'
local originalRequire = require
require = function(name)
    if name == 'LuaClass/BTheme' then return BTheme end
    if name == 'LuaClass/HomeTheme' then return HomeTheme end
    return true
end

local function equal(actual, expected, context)
    assert(actual == expected, (context or 'value') .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end
local function snapshot(value,seen)
    if type(value) ~= 'table' then return type(value) .. ':' .. tostring(value) end
    seen=seen or {}
    if seen[value] then return 'ref:'..tostring(value) end
    seen[value]=true
    local keys, parts = {}, {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do parts[#parts + 1] = snapshot(key,seen) .. '=' .. snapshot(value[key],seen) end
    return '{' .. table.concat(parts, ',') .. '}'
end
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end

local Node = {}
local function node(kind)
    return setmetatable({kind=kind or 'Node', children={}, size={width=80,height=80},
        pos={x=0,y=0}, anchor={x=0,y=0}, visible=true, scale=1}, {__index=Node})
end
function Node:addChild(child, z)
    assert(child and not child.parent, 'Cocos child must exist and have no parent')
    self.children[#self.children + 1] = child; child.parent = self; child.z = z or 0
end
function Node:getChildren() return self.children end
function Node:getParent() return self.parent end
function Node:cleanup()
    self:stopAllActions()
    for _, child in ipairs(self.children) do child:cleanup() end
    if self.scriptHandler then self.scriptHandler('cleanup') end
    self.cleaned = true
end
function Node:removeFromParent(cleanup)
    if self.parent then
        local siblings = self.parent.children
        for i, child in ipairs(siblings) do if child == self then table.remove(siblings, i); break end end
        self.parent = nil
        if cleanup ~= false then self:cleanup() end
    end
end
function Node:removeAllChildren(cleanup)
    while #self.children > 0 do self.children[#self.children]:removeFromParent(cleanup) end
end
function Node:setContentSize(a,b) self.size=type(a)=='table' and a or {width=a,height=b} end
function Node:getContentSize()
    if self.kind == 'LabelTTF' then
        return {width=self.dimensions and self.dimensions.width > 0 and self.dimensions.width or #self.text*self.fontSize*0.45,
            height=self.dimensions and self.dimensions.height > 0 and self.dimensions.height or self.fontSize}
    end
    return self.size
end
function Node:setPosition(a,b) self.pos=type(a)=='table' and a or {x=a,y=b} end
function Node:getPosition() return self.pos.x,self.pos.y end
function Node:getPositionX() return self.pos.x end
function Node:getPositionY() return self.pos.y end
function Node:setPositionX(x) self.pos.x=x end
function Node:setPositionY(y) self.pos.y=y end
function Node:setAnchorPoint(a,b) self.anchor=type(a)=='table' and a or {x=a,y=b} end
function Node:getAnchorPoint() return self.anchor end
function Node:setString(s) self.text=tostring(s) end
function Node:setFontName(v) self.font=v end
function Node:getFontName() return self.font end
function Node:getString() return self.text end
function Node:setDimensions(v) self.dimensions=v end
function Node:setHorizontalAlignment(v) self.horizontalAlignment=v end
function Node:setVerticalAlignment(v) self.verticalAlignment=v end
function Node:setScale(x,y) self.scale=x;self.scaleX=x;self.scaleY=y or x end
function Node:setScaleX(v) self.scaleX=v end
function Node:setScaleY(v) self.scaleY=v end
function Node:getScale() return self.scale end
function Node:getScaleX() return self.scaleX or self.scale end
function Node:getScaleY() return self.scaleY or self.scale end
function Node:setColor(v) self.color=v end
function Node:setOpacity(v) self.opacity=v end
function Node:getOpacity() return self.opacity or 255 end
function Node:setVisible(v) self.visible=v end
function Node:isVisible() return self.visible end
function Node:setEnabled(v) self.enabled=v end
function Node:isEnabled() return self.enabled ~= false end
function Node:setLocalZOrder(v) self.z=v end
function Node:setCascadeOpacityEnabled(v) self.cascadeOpacity=v end
function Node:setCascadeColorEnabled(v) self.cascadeColor=v end
function Node:ignoreAnchorPointForPosition(v) self.ignoreAnchor=v end
function Node:setTextureRect(v) self.textureRect=v;self.size={width=v.width,height=v.height} end
function Node:setFlippedX(v) self.flippedX=v end
function Node:setFlippedY(v) self.flippedY=v end
function Node:registerScriptTapHandler(fn) self.callback=fn end
function Node:registerScriptHandler(fn) self.scriptHandler=fn end
function Node:runAction(a) self.actions=self.actions or {};self.actions[#self.actions+1]=a;return a end
function Node:stopAllActions() self.actions={} end
function Node:addClickArea() end
function Node:drawPolygon(points,count,fill,borderWidth,border)
    equal(#points,count,'DrawNode polygon count')
    self.draws=self.draws or {};self.draws[#self.draws+1]={points=points,fill=fill,borderWidth=borderWidth,border=border}
end
function Node:drawDot(...) self.draws=self.draws or {};self.draws[#self.draws+1]={...} end
function Node:drawSegment(...) self.draws=self.draws or {};self.draws[#self.draws+1]={...} end
function Node:clear() self.draws={} end

cc = {
    p=function(x,y)return {x=x,y=y}end,
    size=function(w,h)return {width=w,height=h}end,
    rect=function(x,y,w,h)return {x=x,y=y,width=w,height=h}end,
    c3b=function(r,g,b)return {r=r,g=g,b=b}end,
    c4b=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end,
    c4f=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end,
    TEXT_ALIGNMENT_LEFT=0,TEXT_ALIGNMENT_CENTER=1,TEXT_ALIGNMENT_RIGHT=2,
    VERTICAL_TEXT_ALIGNMENT_TOP=0,VERTICAL_TEXT_ALIGNMENT_CENTER=1,
}
for _, kind in ipairs({'Node','Layer','DrawNode'}) do
    local name=kind;cc[name]={create=function()return node(name)end}
end
local function fileExists(path)
    local f=io.open('bin/res/assets/'..path,'rb')
    if f then f:close();return true end
    return false
end
local missingArt=false
cc.FileUtils={getInstance=function()return {isFileExist=function(_,path)return not missingArt and fileExists(path)end}end}
cc.Sprite={create=function(_,path)
    if path and (missingArt or not fileExists(path)) then return nil end
    local n=node('Sprite');n.path=path
    if path then
        local f=assert(io.open('bin/res/assets/'..path,'rb'));local h=f:read(24);f:close()
        if h and h:sub(1,8)=='\137PNG\r\n\26\n' then
            local function uint32(i)local a,b,c,d=h:byte(i,i+3);return ((a*256+b)*256+c)*256+d end
            n.size={width=uint32(17),height=uint32(21)}
        end
    end
    return n
end}
cc.LayerColor={create=function(_,color,w,h)local n=node('LayerColor');n.color=color;n.size={width=w,height=h};return n end}
cc.LabelTTF={create=function(_,text,font,size)
    local n=node('LabelTTF');n.text=tostring(text or '');n.font=font;n.fontSize=size;return n
end}
cc.MenuItemSprite={create=function(_,normal,selected)
    assert(normal and selected,'MenuItemSprite requires both states')
    local n=node('MenuItemSprite');n.size=normal:getContentSize();n:addChild(normal);n:addChild(selected);return n
end}
cc.Menu={create=function(_,...)local n=node('Menu');for _,v in ipairs({...})do n:addChild(v)end;return n end}
local viewport={width=640,height=1136}
cc.Director={getInstance=function()return {getVisibleSize=function()return viewport end,getVisibleOrigin=function()return {x=0,y=0}end}end}
cc.Texture2D={setDefaultAlphaPixelFormat=function()end}
for _, name in ipairs({'FadeOut','FadeIn','FadeTo','ScaleTo','DelayTime','Sequence','CallFunc','EaseExponentialIn','EaseExponentialOut','MoveTo','MoveBy','RepeatForever'})do
    local kind=name;cc[name]={create=function(_,...)return {kind=kind,args={...}}end}
end
local dispatcher={listeners={}}
cc.EventListenerCustom={create=function(_,name,callback)return {name=name,callback=callback}end}
cc.EventCustom={new=function(_,name)return {name=name}end}
function dispatcher:addEventListenerWithFixedPriority(listener,priority)
    self.listeners[#self.listeners+1]=listener;listener.priority=priority
end
function dispatcher:removeEventListener(listener)
    for i,v in ipairs(self.listeners)do if v==listener then table.remove(self.listeners,i);return end end
end
function dispatcher:dispatchEvent(event)
    local current={};for i,v in ipairs(self.listeners)do current[i]=v end
    for _,v in ipairs(current)do if v.name==event.name then v.callback(event)end end
end
function class(name,factory)
    local cls={}
    function cls.new()local n=factory();setmetatable(n,{__index=function(_,k)return cls[k] or Node[k]end});return n end
    return cls
end

dofile(root..'Header.lua')
cclog=function()end
-- Loading definitions does not initialize real saves or static data.
dofile(root..'DataManager.lua')
local dm=DataManager.new()
DataManagerSingleton=dm
dm.__eventListener={};dm.__eventDispatcher=dispatcher
local data={}
local writes=0
local function forbidden(name)
    return function()writes=writes+1;error('Home attempted a game-state/economy write: '..name,2)end
end
for _,name in ipairs({'setRoleData','addCoin','addDiamond','addPackItemWithId','addSoilderWithId','mixPackAndSoildier','showBuyGoldBox','setMusic_off','setSound_off'})do dm[name]=forbidden(name)end
local save={saveData=forbidden('saveData')}
SaveDataManager={getInstance=function()return save end}
dm.__roleData={getRoleData=function(_,key)return data[key]end,getSound=function()return 1 end,saveData=forbidden('UserData.saveData')}
-- Rows verified against the decoded game CSVs, including the original IDs/icons.
local soldiers={
    ['107']={ID='107',name='木盾舵手',star='2',icon='j_4.png',skill='7',attack='12',hp='32',speed='4'},
    ['124']={ID='124',name='船医',star='1',icon='j_7.png',skill='24',attack='4',hp='5',speed='3.1'},
}
local resources={
    ['1005']={ID='1005',name='食物',cubage='1',carryType='1',icon='r_2.png'},
    ['1037']={ID='1037',name='简易钥匙',cubage='1',carryType='1',icon='r_16.png'},
    ['1038']={ID='1038',name='精致钥匙',cubage='1',carryType='1',icon='b_15.png'},
    ['1061']={ID='1061',name='龙纹钥匙',cubage='1',carryType='1',icon='b_16.png'},
    ['1120']={ID='1120',name='图书馆钥匙',cubage='0',carryType='0',icon='r_16.png'},
}
local csv={[csvOfSoilderAttribute]=soldiers,[csvOfResourceInfo]=resources}
local csvBaseline=snapshot(csv)
dm.__staticData={getCSVByID=function(_,id)return csv[id] or {}end}
local guideUnlocked=true
local alchemyUnlocked=true
local guide={getIsHaveStep=function(_,step)
        if step==8 then return guideUnlocked end
        if step==1 then return alchemyUnlocked end
        return true
    end,
    addStep=forbidden('GuideController.addStep'),removeRedPoint=function()end,addRedPoint=function()end}
GuideController={getInstance=function()return guide end}
ToastUtil={downString=function(_,text)_G.lastToast=text end}
AudioEngine={playEffect=function()end}
SDButton={create=function()return node('SDButton')end}
PushGiftView={create=function()return {show=function()end}end}
ChargeLayer={create=forbidden('ChargeLayer.create')}
RandomEventLayer={create=function()return node('RandomEventLayer')end}
local expeditionCreates=0
ExpeditionLayer={create=function()expeditionCreates=expeditionCreates+1;error('Home must not initialize ExpeditionLayer')end}

dofile(root..'BTheme.lua')
dofile(root..'HomeTheme.lua')
dofile(root..'Home.lua')
dofile(root..'MainMenu.lua')
dofile(root..'Dispatch.lua')
local refresh=HomeLayer.refreshSummary
function HomeLayer:refreshSummary(...)
    self.refreshCount=(self.refreshCount or 0)+1
    return refresh(self,...)
end

local function fixture()
    data={
        [roleMoney]=1250,[roleDiamond]=213,[roleCabinSize]=6,[rolePackSize]=60,
        [rolePack]={['1005']=100,['1037']=5},
        [roleSoildierQueue]={['107']={[dataKeyID]='107',[dataKeyNum]=5},['124']={[dataKeyID]='124',[dataKeyNum]=2}},
        [roleSelectUnit]={['10107']=3,['1005']=57,['1037']=3},
        [roleBattleQueue]={},[roleBattlePack]={},[roleGuideStep]={},
    }
    guideUnlocked=true;alchemyUnlocked=true;UITopHeight=100;UIBottomHeight=136
end
local function textTree(n)
    local lines={}
    local function walk(v)
        if v.kind=='LabelTTF' then lines[#lines+1]=v.text end
        for _,child in ipairs(v.children)do walk(child)end
    end
    walk(n);return table.concat(lines,'\n')
end
local function assertReadonly(before,context)
    equal(snapshot(data),before,context..' role data changed directly')
    equal(snapshot(csv),csvBaseline,context..' static CSV changed directly')
    equal(writes,0,context..' write API count')
    equal(expeditionCreates,0,context..' Expedition init count')
end
local function countListeners()return #dispatcher.listeners end
local function assertMature(home)
    assert(home.isAdventureHome,'Home marker')
    equal(home.summary.crew,3,'selected crew')
    equal(home.summary.cargo,60,'selected cargo')
    equal(home.summary.food,57,'selected food')
    equal(home.summary.keys,3,'selected keys')
    equal(home.summary.standby,4,'unselected inventory crew')
    equal(home.summary.unlocked,true,'shipyard unlocked')
    equal(#home.crewEntries,1,'only selected crew types')
    equal(tostring(home.crewEntries[1].id),'107','10107 offset decoded')
    equal(home.crewEntries[1].name,'木盾舵手','real selected crew name')
    equal(home.crewEntries[1].num,3,'real selected crew count')
    assert(textTree(home):find('木盾舵手',1,true),'actual crew name must be rendered')
end

fixture()
local routes={}
zqDispatch={mainMenu={openRoute=function(_,index)routes[#routes+1]=index end},
    moveToRepository=function()routes[#routes+1]='alchemy' end}
local before=snapshot(data)
local home=assert(HomeLayer:create())
assertMature(home)
home.departureButton.item.callback();equal(routes[#routes],1,'ready CTA opens preparation')
equal(countListeners(),6,'Home subscriptions')
assertReadonly(before,'mature Home')
-- Refresh must stay read-only and not multiply registration or panel children.
local childCount=#home.crewNode:getChildren()
for _=1,5 do home:refreshSummary();assertMature(home)end
equal(#home.crewNode:getChildren(),childCount,'crew redraw leaves no stale cards')
equal(countListeners(),6,'refresh subscription stability')
assertReadonly(before,'repeat refresh')

-- Every source event refreshes exactly once through real DataManager dispatch.
for _,key in ipairs({rolePack,roleSelectUnit,roleSoildierQueue,rolePackSize,roleCabinSize,roleGuideStep})do
    local calls=home.refreshCount;dm:postEvent(key,nil);equal(home.refreshCount,calls+1,'one refresh for '..key)
end
assertReadonly(before,'source events')
pNeedUpdateLayer=home
home:destory()
equal(countListeners(),0,'Home destroy removes native listeners')
equal(pNeedUpdateLayer,nil,'Home releases its active-log pointer')
local stopped=home.refreshCount
dm:postEvent(roleSelectUnit,nil)
equal(home.refreshCount,stopped,'destroyed Home does not receive events')
home:destory();equal(countListeners(),0,'idempotent destroy')
print('PASS Home B mature 107 x 3, real data keys, read-only refresh, six event lifecycles')

fixture();data[roleSelectUnit]={}
before=snapshot(data)
home=assert(HomeLayer:create())
equal(home.summary.crew,0,'empty selected crew')
equal(home.summary.cargo,0,'empty cargo')
equal(home.summary.food,0,'empty food')
equal(home.summary.keys,0,'empty keys')
equal(home.summary.standby,7,'empty selection keeps all stock waiting')
equal(#home.crewEntries,0,'empty formation never fabricates crew')
assertReadonly(before,'empty formation')
home:destory();equal(countListeners(),0,'empty Home cleanup')
print('PASS Home B empty formation keeps real stock and does not fabricate selected units')

fixture()
data[roleSelectUnit]={['10124']='2',['10107']='1',['1005']=7,['1037']=1,['1038']=2,['1061']=3}
data[roleSoildierQueue]['124'][dataKeyNum]='2'
before=snapshot(data)
home=assert(HomeLayer:create())
equal(home.summary.crew,3,'mixed crew count with string save values')
equal(home.summary.cargo,13,'all selected cargo')
equal(home.summary.food,7,'selected food is separate from inventory')
equal(home.summary.keys,6,'all three usable key types')
equal(home.summary.standby,4,'mixed selected crew subtracted once')
equal(#home.crewEntries,2,'two actual selected types')
equal(home.crewEntries[1].id,'107','crew sorted by real ID')
equal(home.crewEntries[2].id,'124','10124 offset decoded')
equal(home.crewEntries[2].name,'船医','CSV 124 is the ship doctor')
equal(home.crewEntries[2].num,2,'doctor selected count')
assert(textTree(home):find('船医',1,true),'real doctor name is rendered')
assertReadonly(before,'mixed formation')
home:destory();equal(countListeners(),0,'mixed Home cleanup')
print('PASS Home B real 124 doctor, mixed selection, string counts and three usable key types')

fixture();guideUnlocked=false;data[roleSelectUnit]={}
before=snapshot(data)
home=assert(HomeLayer:create())
equal(home.summary.unlocked,false,'locked shipyard state')
assert((home.readyLabel:getString()..home.hintLabel:getString()):find('船坞',1,true),'locked state explains shipyard')
home.departureButton.item.callback();equal(routes[#routes],3,'locked CTA opens construction')
assertReadonly(before,'locked shipyard')
home:destory();equal(countListeners(),0,'locked Home cleanup')
print('PASS Home B locked shipyard remains read-only')

fixture();guideUnlocked=false;alchemyUnlocked=false;data[roleSelectUnit]={}
before=snapshot(data)
home=assert(HomeLayer:create())
assert(home.departureButton.label:getString():find('炼金',1,true),'first-run CTA explains alchemy')
home.departureButton.item.callback();equal(routes[#routes],'alchemy','first-run CTA opens original alchemy page')
assertReadonly(before,'first-run alchemy guidance')
home:destory();equal(countListeners(),0,'first-run cleanup')
print('PASS Home B primary CTA routes preparation, construction and first-run alchemy')

-- The real Dispatch owns destruction, replacement, latest-log routing and tabs.
fixture();before=snapshot(data)
SystemInfoData={'更早历史','上一条港口消息','最新港口消息'}
local scene=node('Scene')
local dispatch=assert(Dispatch:create(false));scene:addChild(dispatch)
assertMature(dispatch.rightNode)
equal(UITopHeight,100,'other-page top safe area remains unchanged')
equal(UIBottomHeight,136,'other-page bottom safe area remains unchanged')
equal(countListeners(),11,'Home + MainMenu + Dispatch native subscriptions')
equal(pNeedUpdateLayer,dispatch.rightNode,'Dispatch selects current Home log receiver')
local menu=dispatch.mainMenu
assert(menu.homePresentation and menu.homeHeader:isVisible(),'Home header enabled')
assert(not menu.legacyTopBg:isVisible() and not menu.coinNode:isVisible() and not menu.diamondNode:isVisible(),'legacy header hidden on Home')
equal(snapshot(menu.navigationBg.color),snapshot(HomeTheme.colors.paper),'Home footer palette')
local homeHeader=menu.homeHeader
local headerChildren=#homeHeader:getChildren()
-- Events update both the hidden legacy labels and the visible Home labels.
data[roleMoney]=4321;data[roleDiamond]=234;before=snapshot(data)
dm:postEvent(roleMoney,nil);dm:postEvent(roleDiamond,nil)
equal(menu.homeCoinLabel:getString(),'4321','live Home coin value')
equal(menu.homeDiamondLabel:getString(),'234','live Home diamond value')
equal(menu.coinValueLabel:getString(),'4321','legacy coin stays synchronized')
equal(menu.diamondValueLabel:getString(),'234','legacy diamond stays synchronized')
assert(dispatch.rightNode.infoLabel:getString():find('最新港口消息',1,true),'newest cached message shown on entry')
assert(not dispatch.rightNode.infoLabel:getString():find('更早历史',1,true),'Home avoids rendering full history')
local sameHome=dispatch.rightNode;local sameCount=countListeners()
dispatch:moveToHome();equal(dispatch.rightNode,sameHome,'repeat Home entry reuses layer')
equal(countListeners(),sameCount,'repeat Home entry does not duplicate listeners')
local infoCalls=0;local originalUpdate=sameHome.updateInfoLabel
sameHome.updateInfoLabel=function(self,text)infoCalls=infoCalls+1;return originalUpdate(self,text)end
dm:sendSystemInfo('刚刚更新的消息')
equal(infoCalls,1,'one latest-log update from MainMenu')
assert(sameHome.infoLabel:getString():find('刚刚更新的消息',1,true),'newest incoming message visible')
assertReadonly(before,'Dispatch default Home and log updates')
-- Even a direct navigation attempt cannot bypass the original shipyard gate.
guideUnlocked=false;lastToast=nil
menu:openRoute(1)
equal(dispatch.rightNode,sameHome,'locked preparation leaves current Home in place')
assert(lastToast and lastToast:find('船坞',1,true),'original navigation gate reports the missing shipyard')
equal(expeditionCreates,0,'locked route never constructs Expedition')
guideUnlocked=true
assertReadonly(before,'locked navigation attempt')

for _=1,5 do
    local oldHome=dispatch.rightNode
    local legacy=node('LegacyPage')
    function legacy:viewWillDestory()end
    function legacy:destory()self.destroyed=true end
    function legacy:updateInfoLabel(text)self.latestInfo=text end
    dispatch:setViewWithDirection(legacy,false,1)
    equal(countListeners(),5,'leaving Home removes exactly its six listeners')
    equal(pNeedUpdateLayer,legacy,'legacy page receives log after navigation')
    assert(not menu.homePresentation and not menu.homeHeader:isVisible(),'Home header disabled off Home')
    assert(menu.legacyTopBg:isVisible() and menu.coinNode:isVisible() and menu.diamondNode:isVisible(),'legacy header restored')
    equal(snapshot(menu.navigationBg.color),snapshot(BTheme.colors.ink),'legacy footer palette restored')
    equal(menu.storeBtn.bLabel:getFontName(),BoldFont,'legacy footer font restored')
    local calls=oldHome.refreshCount;dm:postEvent(roleSelectUnit,nil)
    equal(oldHome.refreshCount,calls,'departed Home remains unsubscribed')
    dm:sendSystemInfo('其它页面新消息')
    assert(legacy.latestInfo:find('其它页面新消息',1,true),'legacy page retains full system log')
    dispatch:moveToHome()
    assertMature(dispatch.rightNode)
    equal(countListeners(),11,'return Home has exactly one listener set')
    equal(pNeedUpdateLayer,dispatch.rightNode,'return Home restores log receiver')
    assert(menu.homePresentation and menu.homeHeader:isVisible(),'Home header restored on return')
    equal(menu.homeHeader,homeHeader,'Home header is reused')
    equal(#homeHeader:getChildren(),headerChildren,'repeated entry does not duplicate header nodes')
    equal(menu.homeCoinLabel:getString(),'4321','return Home has current currency')
    assert(dispatch.rightNode.infoLabel:getString():find('其它页面新消息',1,true),'return Home uses latest log')
end
assertReadonly(before,'five page round trips')
dispatch:destory()
equal(countListeners(),0,'Dispatch destroy cleans Home, menu and Dispatch listeners')
equal(pNeedUpdateLayer,nil,'Dispatch releases info pointer')
print('PASS Home B latest log, default Home, repeated Home/legacy navigation, total event cleanup')

-- Match AppDelegate's 640-wide logical design resolution for physical windows.
-- Node tests only verify safe construction; native GUI QA owns text/art bounds.
for _,size in ipairs({{width=540,height=960},{width=480,height=800}})do
    viewport={width=640,height=size.height*(640/size.width)}
    fixture();before=snapshot(data);missingArt=true
    home=assert(HomeLayer:create());assertMature(home);assertReadonly(before,'missing-art compact Home')
    home:destory();equal(countListeners(),0,'compact cleanup')
end
print('PASS Home B compact construction and missing-art fallback (not pixel-layout acceptance)')

-- Use the real production-only toast filter and original downString queue path.
-- Do not run NotificationNode production callbacks or touch the economy.
local notification=node('NotificationLayer')
local originalDirector=cc.Director.getInstance
cc.Director.getInstance=function()
    local director=originalDirector()
    director.getNotificationNode=function()return notification end
    return director
end
dofile(root..'ToastUtil.lua')
local originalDownString=ToastUtil.downString
local downCalls=0
ToastUtil.downString=function(self,...)
    downCalls=downCalls+1
    return originalDownString(self,...)
end
fixture();missingArt=false;before=snapshot(data)
dispatch=assert(Dispatch:create(false));scene:addChild(dispatch)
local listenersBefore=countListeners()
local toastBefore=snapshot(ToastUtil)
local logsBefore=snapshot(SystemInfoData)
for _,message in ipairs({'金币+3','食物+5','木材+2'})do ToastUtil:productionString(message)end
equal(downCalls,0,'Home routine production never enters downString')
equal(#ToastUtil.infoQueue,0,'Home routine production is not queued for later replay')
equal(snapshot(ToastUtil),toastBefore,'silent production creates no toast state')
equal(#(notification.actions or {}),0,'silent production schedules no toast work')
equal(countListeners(),listenersBefore,'silent production adds no listener')
equal(snapshot(SystemInfoData),logsBefore,'presentation filter does not edit system log')
-- Important messages use downString directly and remain available on Home.
ToastUtil:downString('支付失败，请重试！',true)
ToastUtil:downString('船坞已解锁')
equal(downCalls,2,'errors and unlocks still enter original downString')
equal(ToastUtil.infoQueue[1],'支付失败，请重试！','error retained in original toast queue')
equal(ToastUtil.infoQueue[2],'船坞已解锁','unlock retained in original toast queue')
equal(#notification.actions,2,'important Home toasts keep original scheduling path')
local legacy=node('LegacyPage')
function legacy:viewWillDestory()end
function legacy:destory()end
function legacy:updateInfoLabel(text)self.latestInfo=text end
dispatch:setViewWithDirection(legacy,false,1)
ToastUtil:productionString('食物+7')
equal(downCalls,3,'leaving Home restores routine production downString')
equal(ToastUtil.infoQueue[3],'食物+7','legacy production uses the original queue')
equal(#notification.actions,3,'legacy production uses original scheduling path')
dispatch:moveToHome()
local returnToastState=snapshot(ToastUtil)
ToastUtil:productionString('金币+9')
equal(downCalls,3,'returning Home silences routine production again')
equal(snapshot(ToastUtil),returnToastState,'returning Home adds no deferred production queue')
equal(countListeners(),listenersBefore,'toast filtering adds no listener on round trip')
assertReadonly(before,'production-only toast filtering')
dispatch:destory();equal(countListeners(),0,'toast exercise leaves no listeners')
ToastUtil:productionString('木材+1')
equal(downCalls,4,'no active Home preserves original production feedback')
equal(ToastUtil.infoQueue[4],'木材+1','no-view production still uses original queue')
-- Guard the intentionally small call-site scope without executing production.
local sourceFile=assert(io.open(root..'NotificationNode.lua','rb'))
local source=sourceFile:read('*a');sourceFile:close()
local _,productionCalls=source:gsub('ToastUtil:productionString%(', '')
equal(productionCalls,3,'only the three routine production call sites use the filter')
assert(source:find('ToastUtil:downString("支付失败，请重试！")',1,true),'payment failure must retain direct error feedback')
assertReadonly(before,'toast filter final state')
cc.Director.getInstance=originalDirector
require=originalRequire
print('PASS Home B production-only toast silence, original error/unlock feedback and off-Home restoration')
