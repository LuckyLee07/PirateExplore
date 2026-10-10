-- Runs production icon/row/defeat/offer methods with strict Cocos node fixtures.
-- No GUI, save file, real payment, or native commerce bridge is used.
local root='bin/res/scripts/LuaClass/'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/home_master_regression.lua')
local stop=assert(source:find("\ndofile(root..'Header.lua')",1,true))
local H=assert(loadstring(source:sub(1,stop-1)..'\nreturn {node=node,methods=Node,dispatcher=dispatcher}','@item-icon-node-fixture'))()
local N=H.methods
local function equal(a,b,why)assert(a==b,(why or 'value')..': '..tostring(a)..' ~= '..tostring(b))end
local function labels(n,text)
    if n.text==text then return n end
    for _,c in ipairs(n.children)do local found=labels(c,text);if found then return found end end
end
local function collect(n,predicate,out)
    out=out or {};if predicate(n)then out[#out+1]=n end
    for _,c in ipairs(n.children)do collect(c,predicate,out)end
    return out
end
function N:getViewSize()return self.viewSize or self.size end
function N:setViewSize(s)self.viewSize=s end
function N:setContentOffset(p)self.offset=p end
function N:setFontSize(v)self.fontSize=v end
function N:disableStroke()self.strokeDisabled=true end
cc.Director={getInstance=function()return {getVisibleSize=function()return cc.size(640,1136)end,getVisibleOrigin=function()return cc.p(0,0)end,getWinSize=function()return cc.size(640,1136)end}end}
function class(_,factory)
    local cls={}
    function cls.new(...)
        local n=factory();setmetatable(n,{__index=function(_,k)return cls[k] or N[k]end})
        if cls.ctor then cls.ctor(n,...)end
        return n
    end
    return cls
end
cc.PLATFORM_OS_LINUX=3
cc.Application={getInstance=function()return {getTargetPlatform=function()return cc.PLATFORM_OS_LINUX end}end}
require=function(name)return _G[name:match('([^/]+)$')] or true end
for _,name in ipairs({'Header','DataManager','HomeTheme','MasterTheme','ManagementTheme','DialogTheme','CombatTheme','SDButton','ItemIcon','Repository','EventDetailsLayer','ResourceTheme'})do dofile(root..name..'.lua')end
cclog=function()end
local dm=DataManager.new();DataManagerSingleton=dm
dm.getSound_off=function()return 1 end
local ticks=1000;getSystemTimeMilliSecond=function()return ticks end
schedule=function(n,f)n.scheduled=f end
ToastUtil={downString=function()end, alchemyCoins=function()end}
-- Decode the packaged authoritative records using the same established decoder.
local decoderStart=assert(source:find('local function readFile(path)',1,true))
local decoderEnd=assert(source:find("\nlocal soldiers=packagedCSV('soilderAttribute')",decoderStart,true))
local packagedCSV=assert(loadstring('local equal=...\n'..source:sub(decoderStart,decoderEnd-1)..'\nreturn packagedCSV','@item-icon-csv-fixture'))(equal)
local resources=packagedCSV('resourceInfo')
equal(resources['3009'].name,'诅咒银币');equal(resources['3009'].iconName,'b_74.png');equal(resources['3009'].display,'1')
equal(resources['1299'].iconName,'c_1.png');equal(resources['1299'].display,'0')
local resourceBefore={}
for id,row in pairs(resources)do resourceBefore[id]={};for k,v in pairs(row)do resourceBefore[id][k]=v end end
assert(not ItemIcon.path('b_74.png') and not ItemIcon.path('c_1.png') and not ItemIcon.path('d_1.png'))

-- Both missing states, each one-sided failure, nil/empty paths and valid art.
local valid='Images/btn/ann03_a.png'
local validSize=cc.Sprite:create(valid):getContentSize()
for _,case in ipairs({{valid,valid,validSize.width,validSize.height,false,false},
    {'missing.png',valid,validSize.width,validSize.height,true,false},
    {valid,'missing.png',validSize.width,validSize.height,false,true},
    {'missing.png','missing-too.png',64,64,true,true},{'','',64,64,true,true}})do
    local clicks=0
    local b=SDButton:create(case[1],case[2],function()clicks=clicks+1 end)
    equal(b:getContentSize().width,case[3]);equal(b:getContentSize().height,case[4])
    equal(b.normalSpr:getContentSize().width,case[3]);equal(b.selectSpr:getContentSize().width,case[3])
    equal(b._normalImageMissing,case[5]);equal(b._selectedImageMissing,case[6])
    b:addClickArea(cc.rect(0,0,40,40));equal(b.clickArea.width,40)
    local touch={getLocation=function()return cc.p(10,10)end}
    assert(b:onTouchBegan(touch));assert(b.selectSpr:isVisible() and not b.normalSpr:isVisible())
    b:onTouchEnded(touch);equal(clicks,1);assert(b.normalSpr:isVisible() and not b.selectSpr:isVisible())
end
local empty=SDButton:create(nil,nil,function()end);equal(empty:getContentSize().width,64)
-- A listed file can still fail decoding; FileUtils alone is not sufficient.
local createSprite=cc.Sprite.create
cc.Sprite.create=function(self,path,rect)if path=='Images/Icon/r_9.png'then return nil end;return createSprite(self,path,rect)end
local failedDecode=ItemIcon.sdButton('r_9.png',function()end)
equal(failedDecode:getContentSize().width,64);assert(failedDecode._normalImageMissing)
local failedMenu=ItemIcon.menuItem('r_9.png');equal(failedMenu:getContentSize().width,64)
cc.Sprite.create=createSprite
for _,icon in ipairs({'b_74.png','c_1.png','','r_9.png','B/r_9.png'})do
    local expected=ItemIcon.path(icon) and cc.Sprite:create(ItemIcon.path(icon)):getContentSize() or cc.size(64,64)
    equal(ItemIcon.menuItem(icon):getContentSize().width,expected.width)
    equal(ItemIcon.sdButton(icon,function()end):getContentSize().height,expected.height)
end
print('PASS actual SDButton normal-only/selected-only/both/nil/empty/decode failures and valid art keep hit targets, state and callbacks')

-- Production warehouse uses real missing-art item 3009; name and tooltip stay
-- readable, and its original description/sell callbacks are still attached.
local pack={['3009']=2,['1299']=1}
local data={[rolePack]=pack}
dm.getRoleData=function(_,key)return data[key]end
dm.getCSVByID=function(_,key)equal(key,csvOfResourceInfo);return resources end
local function repository()
    local r=H.node('Repository');setmetatable(r,{__index=function(_,k)return RepositoryLayer[k] or N[k]end})
    r.produceCsv=resources;r.scrollView=H.node('ScrollView');r.scrollView:setContentSize(cc.size(610,300))
    r.scrollViewContainer=H.node('Layer');r.scrollViewContainer:setContentSize(cc.size(610,300))
    r.showInfoBox=function(self,text)self.lastDescription=text end
    return r
end
local repo=repository();repo:initBagDataWithType('0')
assert(labels(repo.scrollViewContainer,'诅咒银币'),'real missing-art name remains visible')
assert(not labels(repo.scrollViewContainer,'单人战船'),'dormant display=0 still hidden')
local buttons=collect(repo.scrollViewContainer,function(n)return n.onLongPressedActiveOnce~=nil end)
equal(#buttons,1);local icon=buttons[1]
equal(icon:getContentSize().width,64);equal(icon:getContentSize().height,64)
equal(icon.clickArea.x,0);equal(icon.clickArea.y,10);equal(icon.clickArea.width,200);equal(icon.clickArea.height,20)
equal(icon.listener.swallow,false);icon.onSingleCLick();equal(repo.lastDescription,resources['3009'].desc)
local saleAlert,coinDelta=nil,0
AlertView={create=function()local n=H.node('Alert');n.s_position=cc.p(320,500);saleAlert=n;return n end}
dm.addPackItemWithId=function(_,id,quantity)equal(id,'3009');pack[id]=pack[id]+quantity;return true end
dm.addCoin=function(_,quantity)coinDelta=coinDelta+quantity;return 1 end
icon.onLongPressedActiveOnce()
local worth=tonumber(resources['3009'].worth)
if worth then
    assert(saleAlert);labels(saleAlert,'出售1个').parent.callback()
    equal(pack['3009'],1);equal(coinDelta,worth,'missing-art sale retains authoritative worth')
else
    assert(not saleAlert);equal(pack['3009'],2);equal(coinDelta,0,'unsellable field remains unsellable')
end
repo:initBagDataWithType('0');equal(#collect(repo.scrollViewContainer,function(n)return n.onLongPressedActiveOnce~=nil end),1,'refresh replaces old missing icon')
print('PASS warehouse missing 3009 art renders bounded neutral slot, actual name, description, original hit area and sale handler; dormant 1299 stays hidden')

-- Real pub/market/cargo/cemetery cell factories retain their semantic labels and
-- callbacks for nil, empty, missing and intact icons; no runtime CSV mutation.
local event={buyHeroCallBack=function(self,d,i)self.hero={d,i}end,buyItemCallBack=function(self,d,i)self.item={d,i}end,
    reliveCallBack=function(self,d,i)self.revive={d,i}end,buryCallBack=function(self,d,i)self.bury={d,i}end}
for _,entry in ipairs({{'initPubBarCell','b_74.png','购 买','hero'},{'initBMarketCell','','购 买','item'},
    {'initPackageCell',nil,nil,nil},{'initCemeteryCell','c_1.png','复 活','revive'}})do
    local d={id='3009',name=resources['3009'].name,icon=entry[2],num=1,star=0,costType='1',costs=42,hp=3,speed=4}
    local cell=H.node('Cell');EventDetailsLayer[entry[1]](event,cell,cc.size(640,150),d,7)
    assert(labels(cell,d.name),'actual event name is visible')
    local menus=collect(cell,function(n)return n.kind=='MenuItemSprite'end)
    equal(menus[1]:getContentSize().width,64);equal(menus[1]:getContentSize().height,64)
    if entry[3]then labels(cell,entry[3]).parent.callback();equal(event[entry[4]][1],d);equal(event[entry[4]][2],7)end
end
local validCell=H.node('Cell')
EventDetailsLayer.initPackageCell(event,validCell,cc.size(640,92),{name='金币',icon='r_9.png',star=0,num=9},1)
equal(collect(validCell,function(n)return n.kind=='MenuItemSprite'end)[1]:getContentSize().width,cc.Sprite:create('Images/Icon/r_9.png'):getContentSize().width)
for id,row in pairs(resources)do for k,v in pairs(row)do equal(v,resourceBefore[id][k],'no resource field changed')end end
print('PASS real event pub/market/cargo/cemetery missing icon rows preserve actual names, icon geometry, action data/index and all CSV fields')
for _,id in ipairs({'1021','1032','1121'})do
    local row=resources[id];equal(row.iconName,'','authoritative empty icon field')
    local cell=H.node('Cell');EventDetailsLayer.initPackageCell(event,cell,cc.size(640,92),{name=row.name,icon=row.iconName,star=0,num=1},1)
    assert(labels(cell,row.name),'empty art keeps authoritative item name')
    equal(collect(cell,function(n)return n.kind=='MenuItemSprite'end)[1]:getContentSize().width,64)
end
-- Native title meanings stay cemetery/pub/black market/cargo; the real refresh
-- branch and cargo table geometry remain untouched by removal of bitmap text.
screenSize=cc.size(640,1136)
local refreshes,checks=0,0
local market={getBlackMarketRefreshTimeInterval=function()return 3600 end,
    getLastBlackMarketRefreshTime=function()return refreshes>0 and 4000 or 0 end,
    checkBlackMarketDatas=function()refreshes=refreshes+1 end,getBlackMarketDatas=function()return resources end}
ExploreDataManager={getInstance=function()return market end}
NotificationNode={getInstance=function()return {GetGameTime=function()return 4000 end}end}
for kind,text in ipairs({'墓 地','酒 馆','黑 市','货 舱'})do
    local view=H.node('Event');view.type=kind;view.areaHeight=500;view.centerPos=cc.p(320,550);view.tableview=H.node('TableView')
    view.titleLabel=cc.LabelTTF:create('未 知',MasterTheme.headingFont(false),46);view.titleLabel:setVisible(false);view:addChild(view.titleLabel)
    view.checkDatas=function()checks=checks+1 end
    EventDetailsLayer.resetTitle(view)
    equal(view.titleLabel:getString(),text);assert(view.titleLabel:isVisible());equal(view.buttonClicked,false)
    equal(#collect(view,function(n)return n.path and n.path:find('topTitle_',1,true)~=nil end),0,'no legacy title bitmap')
    if kind==3 then assert(labels(view,'距离下次刷新还有01 : 00 : 00'));equal(EventDetailsLayer.data,resources)end
    if kind==4 then equal(view.tableview:getViewSize().height,466)end
end
equal(refreshes,1);equal(checks,1)
print('PASS native cemetery/pub/black-market/cargo title meanings, market refresh boundary and cargo table geometry')

-- Execute the real defeat action sequence without changing timing definitions.
FightDataManager={getInstance=function()return {}end}
dofile(root..'FightMode.lua')
local gifts=0;PushGiftView={create=function()return {show=function()gifts=gifts+1 end}end}
local function runCallbacks(action)
    if action.kind=='CallFunc'then action.args[1]()
    elseif action.kind=='Sequence'then for _,child in ipairs(action.args)do runCallbacks(child)end end
end
local returned=0;local result={kept='original result'}
local fight=H.node('Fight');fight.fightFailType=FightScene.FightFailType.normal;fight.fightResult=result
fight.fightOverCallback=function(r)equal(r,result);returned=returned+1 end
FightScene.showFailInfoAndReturn(fight)
local layer=fight.children[1];runCallbacks(layer.actions[1]);equal(fight.maskStatue,'ready')
local controls=collect(layer,function(n)return n.onSingleCLick~=nil end)
equal(#controls,2);equal(returned,0);equal(gifts,0)
for i,button in ipairs(controls)do
    local path=i==1 and 'Images/btn/ann04_a.png' or 'Images/btn/ann03_a.png'
    local size=cc.Sprite:create(path):getContentSize();equal(button:getContentSize().width,size.width);equal(button:getContentSize().height,size.height)
    equal(button.normalSpr:getContentSize().width,size.width);equal(button.clickArea.width,40);equal(button.clickArea.height,40)
    assert(button.normalSpr.path==nil,'legacy face replaced with theme material')
    local label=labels(layer,i==1 and '回 城' or '变 强')
    equal(button:getPositionX(),label:getPositionX());equal(button:getPositionY(),label:getPositionY())
    equal(button:getScale(),label:getContentSize().width*1.6/size.width,'same scaled target')
end
controls[1].onSingleCLick();equal(returned,1);equal(gifts,0)
controls[2].onSingleCLick();equal(returned,1);equal(gifts,1)
local eternal=H.node('Fight');eternal.fightFailType=FightScene.FightFailType.eternal;eternal.fightResult=result;eternal.fightOverCallback=fight.fightOverCallback
FightScene.showFailInfoAndReturn(eternal);runCallbacks(eternal.children[1].actions[1]);equal(returned,2)
equal(#collect(eternal,function(n)return n.onSingleCLick~=nil end),0,'eternal still auto-returns with no gift buttons')
print('PASS real defeat controls retain scale, expanded hitbox, original return/gift callbacks and eternal auto-return')

-- Original coin-shop and auto-alchemy offers retain their intentionally different
-- exchange rates. Callback invocation only touches this in-memory data fixture.
local lastAlert
AlertView={create=function(_,kind,box,title,callback)
    local n=H.node('Alert');n.s_position=cc.p(320,568);n.offerCallback=callback;n.title=title;lastAlert=n
    function n:usePaperBody()self.paper=true end
    function n:setOkRemove(v)self.okRemove=v end
    return n
end}
local diamondCosts,coinAmounts={},{}
dm.addDiamond=function(_,n)diamondCosts[#diamondCosts+1]=n;return 1 end
dm.addCoin=function(_,n)coinAmounts[#coinAmounts+1]=n;return 1 end
ResourceTheme.applyIcons(resources)
DataManager.showBuyGoldBox(dm)
equal(#diamondCosts,0);equal(#coinAmounts,0)
local shop=lastAlert;assert(shop.paper);equal(#collect(shop,function(n)return n.path=='Images/Icon/B/r_9.png'end),2,'shop uses authoritative themed coin art')
for i,amount in ipairs({30,500})do
    local price=labels(shop,'x'..amount);assert(price);equal(price.font,MasterTheme.headingFont(false))
    price.parent.callback();equal(diamondCosts[i],-amount);equal(coinAmounts[i],i==1 and 5000 or 120000)
end
GuideController={getInstance=function()return {addStep=function()end,getIsHaveStep=function()return true end}end}
dm.getAchievementInfo=function()return 0 end;dm.setAchievementInfo=function()end
dm.setRoleData=function(_,k,v)data[k]=v end
local backed=0;zqDispatch={backToLastView=function()backed=backed+1 end}
data[roleAlchemyUnit]=1;data[roleAlchemyCanLongPress]=0;data[roleMoney]=0
for _,case in ipairs({{1,40,5000,'您是否花费40钻石\n购买5000金币？'},{3,398,nil,'长按炼金按钮，可持续获得金币，\n您是否花费398钻石获得此功能？'}})do
    data[roleAlchemyBtnClickCount]=100;data[roleAlchemyShowCount]=case[1]
    local before=#diamondCosts;DataManager.AlchemyButtonDidClick(dm);equal(#diamondCosts,before,'showing automatic offer does not charge')
    local caption=assert(labels(lastAlert,case[4]));equal(caption.font,MasterTheme.headingFont(false))
    lastAlert.offerCallback();equal(diamondCosts[#diamondCosts],-case[2])
    if case[3]then equal(coinAmounts[#coinAmounts],case[3])else equal(data[roleAlchemyCanLongPress],1);equal(backed,1)end
end
print('PASS real coin shop 30/5000 and 500/120000, auto offer 40/5000 and hold upgrade 398 retain all costs, outcomes and callbacks')

-- New art is resolved centrally before any screen receives the same records.
-- Render both new identities through actual warehouse and generic loot/menu
-- factories; the shared steel sword must keep its original framed icon.
pack={['1039']=1,['1049']=1,['1053']=1};data[rolePack]=pack
repo=repository();repo:initBagDataWithType('0')
for _,case in ipairs({{'1039','B/siege-ram-1039.png'},{'1049','B/iron-sword-1049.png'},{'1053','w_12.png'}})do
    equal(resources[case[1]].iconName,case[2]);assert(labels(repo.scrollViewContainer,resources[case[1]].name))
    assert(#collect(repo.scrollViewContainer,function(n)return n.path=='Images/Icon/'..case[2]end)>0)
    local sprite=ItemIcon.sprite(resources[case[1]].iconName)
    equal(sprite.path,'Images/Icon/'..case[2]);equal(sprite:getContentSize().width,64)
    equal(ItemIcon.menuItem(resources[case[1]].iconName):getContentSize().width,64)
end
print('PASS new ram and exact iron sword render in production warehouse/loot factories; steel sword retains original shared art')
