-- Native management callbacks with strict Cocos-node fixtures. No GUI or saves.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/home_master_regression.lua')
local stop=assert(source:find("\ndofile(root..'Header.lua')",1,true))
local H=assert(loadstring(source:sub(1,stop-1)..'\nreturn {node=node,methods=Node,dispatcher=dispatcher}','@management-node-fixture'))()
local N=H.methods
function N:setFontSize(v)self.fontSize=v end
function N:getViewSize()return self.viewSize or self.size end
function N:setContentOffset(v)self.offset=v end
function N:getContentOffset()return self.offset or cc.p(0,0) end
function N:reloadData()self.reloads=(self.reloads or 0)+1 end
function N:setNormalImage(v)if self.normal then self.normal:removeFromParent()end;self.normal=v;self:addChild(v);self.size=v:getContentSize()end
function N:setSelectedImage(v)if self.selected then self.selected:removeFromParent()end;self.selected=v;self:addChild(v)end
cc.MenuItemImage={create=function(_,a,b)local n=H.node('MenuItemImage');n:setNormalImage(cc.Sprite:create(a));n:setSelectedImage(cc.Sprite:create(b));return n end}
cc.Director={getInstance=function()return {getVisibleSize=function()return cc.size(640,1136)end,getWinSize=function()return cc.size(640,1136)end,getVisibleOrigin=function()return cc.p(0,0)end}end}
cc.RotateBy={create=function()return {}end}
local originalRequire=require
require=function()return true end
function class(name,factory)
 local cls={}
 function cls.new(...)
  local n=factory();setmetatable(n,{__index=function(_,k)return cls[k] or N[k]end})
  if cls.ctor then cls.ctor(n,...)end
  return n
 end
 return cls
end
dofile('bin/res/scripts/LuaClass/Header.lua')
UITopHeight=100;UIBottomHeight=136
dofile('bin/res/scripts/LuaClass/HomeTheme.lua')
dofile('bin/res/scripts/LuaClass/MasterTheme.lua')
dofile('bin/res/scripts/LuaClass/ManagementTheme.lua')
dofile('bin/res/scripts/LuaClass/SDButton.lua')
dofile('bin/res/scripts/LuaClass/BaseView.lua')
dofile('bin/res/scripts/LuaClass/Resource.lua')
dofile('bin/res/scripts/LuaClass/ItemIcon.lua')
dofile('bin/res/scripts/LuaClass/Repository.lua')
dofile('bin/res/scripts/LuaClass/StoreMode.lua')
dofile('bin/res/scripts/LuaClass/BuildMode.lua')
dofile('bin/res/scripts/LuaClass/MakeMode.lua')
local function eq(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local clock=1000;getSystemTimeMilliSecond=function()return clock end
schedule=function(n,fn) n.scheduled=fn end
local data,pack,saves,toast,info,unlocks={},{},0,nil,nil,0
local dm={getRoleData=function(_,k)return data[k]end,getSound_off=function()return 1 end,
 setRoleData=function(_,k,v)data[k]=v;saves=saves+1 end,
 getPackNumWithId=function(_,id)return pack[id] or 0 end,
 addPackItemWithId=function(_,id,n)pack[id]=(pack[id] or 0)+n;return true end,
 sendSystemInfo=function(_,s)info=s end,
 createSuccessCheck=function()unlocks=unlocks+1 end}
DataManager={getInstance=function()return dm end}
ToastUtil={downString=function(_,s)toast=s end}
-- Real SDButton callbacks and geometry survive the material replacement.
local clicks,long=0,0
local b=SDButton:create('Images/UI/AddCircleBtn.png','Images/UI/AddCircleBtn1.png',function()clicks=clicks+1 end)
b:registerLongPressed(function()long=long+1 end)
local size=b:getContentSize();local listener=b.listener;local callback=b.onSingleCLick;local longCallback=b.onLongPressed
b:setEnabled(false);ManagementTheme.skinSDButton(b,'coral')
eq(b.listener,listener,'listener identity');eq(b.onSingleCLick,callback,'tap identity');eq(b.onLongPressed,longCallback,'hold identity');eq(b.bIsEnable,false,'disabled retained')
eq(b.normalSpr:getBoundingBox().width,size.width,'hitbox width');eq(b.normalSpr:getBoundingBox().height,size.height,'hitbox height')
local touch={getLocation=function()return cc.p(25,25)end}
eq(b:onTouchBegan(touch),false,'disabled cannot press')
b:setEnabled(true);assert(b:onTouchBegan(touch));assert(b.selectSpr:isVisible() and not b.normalSpr:isVisible(),'selected material')
b:onTouchEnded(touch);eq(clicks,1,'tap dispatch');assert(b.normalSpr:isVisible(),'normal restored')
assert(b:onTouchBegan(touch));b:updatelongprogress();eq(long,1,'hold dispatch');b:onTouchEnded(touch);eq(clicks,1,'hold does not also tap')
print('PASS management SDButton listener, hitbox, disabled, tap and long-press behavior')
-- The horizontal primary action adds horizontal reach without reducing the
-- original target or moving the neighboring legacy footer buttons.
local primary=SDButton:create('Images/MainMenu/an_lianj_a.png','Images/MainMenu/an_lianj_b.png',callback)
primary:registerLongPressed(longCallback)
local primarySize=primary:getContentSize();local primaryListener=primary.listener
ManagementTheme.skinSDButton(primary,'coral','anchor',{width=208,height=67,text='炼金'})
eq(primary:getContentSize().width,primarySize.width,'primary node geometry retained')
eq(primary.normalSpr:getBoundingBox().height,primarySize.height,'primary vertical target retained')
eq(primary.listener,primaryListener,'primary listener retained');eq(primary.onLongPressed,longCallback,'primary hold retained')
eq(primary.normalSpr:getBoundingBox().width+primary.clickArea.width,208,'full horizontal face is tappable')
local expandedTouch={getLocation=function()return cc.p(-20,67)end}
assert(primary:onTouchBegan(expandedTouch),'wide visible edge accepts tap');primary:onTouchEnded(expandedTouch)
local hitLeft=320-primarySize.width/2+primary.clickArea.x
local hitRight=hitLeft+primarySize.width+primary.clickArea.width
assert(hitLeft>67+82/2 and hitRight<573-82/2,'expanded target does not reach either side button')
local side=cc.MenuItemImage:create('Images/MainMenu/tianf_a.png','Images/MainMenu/tianf_b.png')
side:registerScriptTapHandler(callback);side:setOpacity(51)
local redDot=H.node('RedDot');redDot:setTag(9527);side:addChild(redDot)
ManagementTheme.skinMenuItem(side,'light','key',64)
eq(side:getContentSize().width,82,'side target width retained');eq(side:getOpacity(),51,'side lock opacity retained')
eq(side:getChildByTag(9527),redDot,'side red dot retained');eq(side.callback,callback,'side route callback retained')
print('PASS management horizontal primary target, side separation, lock opacity and red dots')
-- Base opt-in is isolated and preserves existing menu callbacks/visibility.
local v=H.node('BaseFixture');v.titleHeight=67
v.mainBg=H.node();v:addChild(v.mainBg);v.titleBg=H.node();v.titleBg:setPosition(320,999);v:addChild(v.titleBg)
v.titleLabel=cc.LabelTTF:create('仓库',BoldFont,46)
v.topLeftBtn=cc.MenuItemImage:create('Images/btn/ann02_a.png','Images/btn/ann02_b.png');v.topLeftBtn:setVisible(false)
v.topRightBtn=cc.MenuItemImage:create('Images/DiamondStore/ann05_a.png','Images/DiamondStore/ann05_b.png')
v.topLeftBtnLabel=cc.LabelTTF:create('设置',BoldFont,24);v.topRightBtnLabel=cc.LabelTTF:create('钻石商城',BoldFont,24)
v.topLeftBtn:registerScriptTapHandler(callback);v.topRightBtn:registerScriptTapHandler(longCallback)
BaseView.applyManagementTheme(v);eq(v.topLeftBtn.callback,callback,'settings callback');eq(v.topRightBtn.callback,longCallback,'store callback');eq(v.topLeftBtn:isVisible(),false,'hidden settings remain hidden');eq(v.titleHeight,67,'legacy geometry retained')
assert(not v.bgIcon:isVisible(),'no watermark under real content')
local bg=v.mainBg;BaseView.applyManagementTheme(v);eq(v.mainBg,bg,'idempotent opt-in')
local sourceBase=read('bin/res/scripts/LuaClass/BaseView.lua');local init=sourceBase:match('function BaseView:init%(%)%s*(.-)\nend')
assert(not init:find('applyManagementTheme',1,true),'base init does not opt in other pages')
for _,name in ipairs({'Home','Expedition','Talent'})do assert(not read('bin/res/scripts/LuaClass/'..name..'.lua'):find('applyManagementTheme',1,true),'accepted page untouched: '..name)end
print('PASS management BaseView opt-in isolation, geometry and existing menu callbacks')
-- Build the production footer, including its actual cooldown callback chain.
function N:setSprite(s)self.sprite=s;self:setContentSize(s:getContentSize())end
function N:setPercentage(v)self.percentage=v end
function N:setType(v)self.progressType=v end
function N:setMidpoint(v)self.midpoint=v end
function N:setBarChangeRate(v)self.barChange=v end
function N:setContainer(v)self.container=v;self:addChild(v)end
function N:setViewSize(v)self.viewSize=v end
function N:setClippingToBounds(v)self.clipping=v end
function N:setBounceable(v)self.bounce=v end
function N:setDirection(v)self.direction=v end
function N:setDelegate()end
local lastProgress
cc.ProgressTimer={create=function(_,s)local n=H.node('ProgressTimer');n:setSprite(s);lastProgress=n;return n end}
cc.ScrollView={create=function(_,s)local n=H.node('ScrollView');n:setContentSize(s);n.viewSize=s;return n end}
cc.Scale9Sprite={create=function()return H.node('Scale9Sprite')end}
cc.PROGRESS_TIMER_TYPE_RADIAL=0;cc.PROGRESS_TIMER_TYPE_BAR=1
for _,name in ipairs({'ProgressTo','EaseElasticOut','Spawn'})do
 local kind=name;cc[name]={create=function(_,...)return {kind=kind,args={...}}end}
end
GuideController={getInstance=function()return {
 getIsHaveStep=function()return true end,
 addRedPoint=function(_,n)local point=H.node('RedPoint');point:setTag(9527);n:addChild(point)end,
 removeRedPoint=function()end}end}
MissionManagers={getInstance=function()return {getWaitingMissions=function()return {len=1}end}end}
RandomEventManager={getInstance=function()return {eventList={}}end}
data[roleAlchemyCanLongPress]=1;data[roleMapInfo]={};isEnterMap=false
setmetatable(v,{__index=function(_,k)return BaseView[k] or N[k]end})
v.areaWidth=610;v.centerPos=cc.p(320,500);v.originPos=cc.p(15,136)
local actionCalls=0;local writesBeforeFooter=saves
v:addInfoNode(nil,nil,nil,nil,'Images/MainMenu/an_caiji_a.png','Images/MainMenu/an_caiji_b.png',function()actionCalls=actionCalls+1 end,nil,true,30,true)
eq(v.setButtonProgrees,lastProgress,'original timer object retained')
eq(v.setButtonProgrees.progressType,cc.PROGRESS_TIMER_TYPE_BAR,'cooldown uses native bar presentation')
eq(v.setButtonProgrees.sprite.path,'Images/UI/hengt_01.png','cooldown drops original circular artwork')
eq(v.setBtnLight:getOpacity(),0,'legacy halo remains transparent');eq(#v.setBtnLight.actions,0,'halo animation is stopped')
eq(v.areaHeight,603,'footer keeps content geometry');eq(v.originPos.y,366,'footer keeps original list origin')
eq(v.setBtn.onSingleCLick,v.setBtn.onLongPressed,'cooldown and long press share original callback')
v.setBtn.onSingleCLick();assert(not v.bIsCenterBtnCanClick,'press locks cooldown')
local cycle=v.setButtonProgrees.actions[1]
eq(cycle.args[2].args[1],30,'original cooldown duration');cycle.args[1].args[1]()
eq(actionCalls,1,'original collect callback runs once')
v.setBtn.onLongPressed();eq(#v.setButtonProgrees.actions,1,'hold cannot bypass active cooldown')
cycle.args[3].args[1]();assert(v.bIsCenterBtnCanClick,'completion unlocks next press')
eq(v.setButtonProgrees.percentage,0,'completion resets original timer')
eq(v.setBtnLight:getOpacity(),0,'completion cannot restore the removed glow')
eq(saves,writesBeforeFooter,'footer presentation does not save gameplay state')
print('PASS management real footer geometry, original cooldown duration, repeat guard, long press and completion')
-- Real resource row controls keep worker caps, quantity updates and save calls.
local r=H.node('ResourceFixture');setmetatable(r,{__index=function(_,k)return ResourceLayer[k] or N[k]end})
r.areaWidth=610;r.workerNum=2;r.workerCsv={['w1']={name='采集者',produceDesc='木材',resumeDesc='食物'}}
r.scrollView=H.node('ScrollView');r.scrollView:setContentSize(cc.size(610,300));r.scrollViewContainer=H.node();r.scrollViewContainer:setContentSize(cc.size(610,300))
r.topMaskLabel=cc.LabelTTF:create('',BoldFont,28);r.setResourceUIWithData=function()end;r.showInfoBox=function(_,s)info=s end
data[roleProducerQueue]={{[dataKeyID]='w1',[dataKeyNum]=0}};data[roleLivingUnitNum]=2
r:setWorkerUIWithData();local row=r.scrollViewContainer.children[1];local minus,plus
for _,n in ipairs(row.children)do if n.onLongPressed then if n:getPositionX()<0 then minus=n else plus=n end end end
assert(minus and plus,'both real long-press controls exist')
minus.onSingleCLick();eq(saves,0,'no underflow save')
plus.onSingleCLick();plus.onLongPressed();plus.onSingleCLick();eq(data[roleProducerQueue][1][dataKeyNum],2,'worker cap');eq(r.workerUseNum,2,'used count');eq(saves,2,'only effective changes save');assert(toast:find('游民数量不足',1,true),'original cap feedback')
minus.onLongPressed();eq(data[roleProducerQueue][1][dataKeyNum],1,'hold decrements');eq(saves,3,'hold saves once');eq(r.scrollView:getContentOffset().y,0,'short-list scroll offset')
r:setWorkerUIWithData();eq(#r.scrollViewContainer.children,1,'refresh replaces rows')
print('PASS management worker count boundaries, save cadence, long press and scroll rebuild')
-- A long worker list reaches the entire last button at its bottom limit; a
-- short list stays at zero offset. Refreshes do not leave stale container size.
r.scrollView.viewSize=cc.size(610,300)
data[roleProducerQueue]={}
for i=1,9 do data[roleProducerQueue][i]={[dataKeyID]='w1',[dataKeyNum]=0} end
r:setWorkerUIWithData()
local workerHeight=r.scrollViewContainer:getContentSize().height
eq(workerHeight,9*68+16,'long list includes both edge gutters')
eq(r.scrollView:getContentOffset().y,300-workerHeight,'long list starts at top limit')
local finalRow=r.scrollViewContainer.children[9]
assert(finalRow:getPositionY()-27>=8 and finalRow:getPositionY()+27<300,'final row fully visible at bottom limit')
data[roleProducerQueue]={{[dataKeyID]='w1',[dataKeyNum]=0}}
r:setWorkerUIWithData();eq(r.scrollViewContainer:getContentSize().height,300,'short list shrinks after long list')
eq(r.scrollView:getContentOffset().y,0,'short list remains at zero offset')
-- Resource totals are keyed tables: count visible totals, not Lua array length.
local summary=H.node('SummaryFixture');setmetatable(summary,{__index=function(_,k)return ResourceLayer[k] or N[k]end})
summary.workerData={{[dataKeyID]='w1',[dataKeyNum]=2}}
summary.workerCsv={w1={produce={},resume={{'p1','3'}}}};summary.produceCsv={}
for i=1,17 do
 local id='p'..i;summary.workerCsv.w1.produce[i]={id,'1'};summary.produceCsv[id]={name='资源'..i}
end
summary.resourceScrollView=H.node('ScrollView');summary.resourceScrollView.viewSize=cc.size(610,52)
summary.resourceScrollViewContainer=H.node();summary.resourceScrollViewContainer:setContentSize(cc.size(610,52))
clone=clone or function(t)local c={};for k,v in pairs(t)do c[k]=v end;return c end
local writesBefore=saves
summary:setResourceUIWithData()
eq(summary.produceTable.p1[1],-4,'resource consumption total unchanged')
eq(summary.produceTable.p17[1],2,'resource production total unchanged')
eq(#summary.resourceScrollViewContainer.children,17,'all nonzero resource totals displayed')
eq(summary.resourceScrollViewContainer:getContentSize().height,192,'overflowing summary is scrollable')
eq(summary.resourceScrollView:getContentOffset().y,52-192,'summary starts at top limit')
summary.workerData[1][dataKeyNum]=0;summary:setResourceUIWithData()
eq(summary.resourceScrollViewContainer:getContentSize().height,52,'empty summary shrinks to viewport')
eq(saves,writesBefore,'summary rendering does not save gameplay state')
print('PASS management worker bottom reachability, scroll rebuild and keyed harvest summary overflow')
-- Real repository filters and long-press sales still resolve the correct item.
local repo=H.node('RepositoryFixture');setmetatable(repo,{__index=function(_,k)return RepositoryLayer[k] or N[k]end})
repo.scrollView=H.node('ScrollView');repo.scrollView:setContentSize(cc.size(610,300))
repo.scrollViewContainer=H.node();repo.scrollViewContainer:setContentSize(cc.size(610,300))
repo.produceCsv={wood={name='木材',display='1',type='2',worth='3',iconName='r_1.png',desc='真实木材'},sword={name='短剑',display='1',type='1',worth='7',iconName='r_1.png',desc='真实短剑'}}
repo.showInfoBox=function(_,s)info=s end
pack.wood=5;pack.sword=1;data[rolePack]=pack
local lastAlert
AlertView={create=function()local n=H.node('Alert');n.s_position=cc.p(320,500);lastAlert=n;return n end}
dm.addCoin=function(_,value)pack['1001']=(pack['1001'] or 0)+value;return 1 end
repo:initBagDataWithType('2');eq(#repo.scrollViewContainer.children,4,'filter builds only resource entry')
local icon
for _,n in ipairs(repo.scrollViewContainer.children)do if n.onLongPressedActiveOnce then icon=n end end
assert(icon,'resource retains original long-press sale');icon.onSingleCLick();eq(info,'真实木材','correct details')
icon.onLongPressedActiveOnce();local sell
for _,menu in ipairs(lastAlert.children)do for _,item in ipairs(menu.children)do for _,label in ipairs(item.children)do if label.text=='出售1个' then sell=item end end end end
assert(sell,'real one-item sale callback present');local before=pack['1001'] or 0
sell.callback();eq(pack.wood,4,'sell only selected item');eq(pack.sword,1,'other item unchanged');eq(pack['1001'],before+3,'original sale value')
repo:initBagDataWithType('1');eq(#repo.scrollViewContainer.children,4,'filter refresh replaces previous row')
assert(not read('bin/res/scripts/LuaClass/Repository.lua'):find('setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGB565)',1,true),'paper-era TTF retains alpha')
print('PASS management repository filters, details, long-press sale, exact item/value and alpha safety')

-- Real shop quantities and construction/crafting material accounting remain intact.
local store=setmetatable({ResoucecsvData={['item']={name='木材',price='3'}},csvData={},roleStoreData={},showline=4,cellhight=112,tableview=H.node('Table')},{__index=StoreLayer})
data[roleStore]={};pack['1001']=100;pack.item=0
store:buy('item','sort',10,nil);eq(pack['1001'],70,'10-item cost');eq(pack.item,10,'10-item grant');eq(unlocks,1,'original unlock check');eq(store.tableview.reloads,1,'table refreshed')
for _,pair in ipairs({{BuildLayer,'csvData'},{MakeLayer,'ResoucecsvData'}})do
 local page=setmetatable({},{__index=pair[1]});page[pair[2]]={['recipe']={resume={{'wood','2'}}}};page.ResoucecsvData=page.ResoucecsvData or {};page.ResoucecsvData.wood={name='木材',price='3',starNum='1',onlyProduce='0'}
 pack.wood=5;page:useResouces('recipe');eq(pack.wood,3,'original recipe cost')
end
print('PASS management purchase quantities, unlock refresh and build/craft resource costs')
-- Execute the actual bulk-popup builder: the old SDButton one-shot callback
-- can still be invoked repeatedly by its original 0.6-second action timer.
local modalScene=H.node('Scene')
local oldDirector=cc.Director.getInstance
cc.Director.getInstance=function()local d=oldDirector();d.getRunningScene=function()return modalScene end;return d end
AlertView.create=function()local n=H.node('Alert');n.s_position=cc.p(320,500);function n:usePaperBody()end;modalScene:addChild(n);return n end
local storeSource=read('bin/res/scripts/LuaClass/StoreMode.lua')
local begin=assert(storeSource:find('function showmorebuy()',1,true))
local finish=assert(storeSource:find('local _menuButton = SDButton:create',begin,true))
local build=assert(loadstring('return function(self,_csvID,_sortID) '..storeSource:sub(begin,finish-1)..' return showmorebuy end'))()
local requests={};local owner={buy=function(_,id,sort,num,alert)requests[#requests+1]={id,sort,num,alert}end}
local open=build(owner,'item','sort')
for i=1,5 do open()end
eq(#modalScene.children,1,'long hold creates exactly one native bulk dialog')
local dialog=modalScene.children[1]
local quantities={10,100,1000}
for i,button in ipairs(dialog.children[1].children)do button.callback();eq(requests[i][3],quantities[i],'bulk callback quantity retained')end
dialog:removeFromParent();open();eq(#modalScene.children,1,'one close permits a fresh dialog');assert(modalScene.children[1]~=dialog)
cc.Director.getInstance=oldDirector
print('PASS repeated bulk hold creates one modal, single close reopens cleanly, real 10/100/1000 handlers retained')
require=originalRequire
