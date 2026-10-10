package.path = 'bin/res/scripts/?.lua;' .. package.path
package.loaded['LuaClass/Header'] = true
package.loaded['LuaClass/BaseView'] = true
package.loaded['LuaClass/UIKit'] = true
BoldFont='test'; WriteColor={r=255,g=255,b=255}; BaseColor={r=0,g=0,b=0}
UITopHeight=100; UIBottomHeight=136
roleMoney='money';roleDiamond='diamond';roleShipId='ship';rolePackSize='capacity'; roleCabinSize='cabin'; rolePack='pack'; roleSoildierQueue='crew'; roleSelectUnit='selection'; roleBattleQueue='battle'; roleBattlePack='battlepack'; roleGuideStep='guide'
csvOfResourceInfo='resources'; csvOfSkillAttribute='skills'; csvOfSoilderAttribute='soldiers'; csvOfBuff='buffs'; dataKeyID='id'; dataKeyNum='num'
local methods={}
local function node(w,h) return setmetatable({children={},size={width=w or 128,height=h or 59},pos={x=0,y=0},visible=true,scale=1}, {__index=function(t,k) return methods[k] or function() end end}) end
function methods:addChild(n) self.children[#self.children+1]=n; n.parent=self end
function methods:getChildren() return self.children end
function methods:getParent() return self.parent end
function methods:setPosition(x,y) self.pos=type(x)=='table' and x or {x=x,y=y} end
function methods:getPosition() return self.pos end
function methods:getPositionX() return self.pos.x end
function methods:getPositionY() return self.pos.y end
function methods:setContentSize(s) self.size=s end
function methods:getContentSize() return self.size end
function methods:setViewSize(s) self.viewSize=s end
function methods:getViewSize() return self.viewSize or self.size end
function methods:setString(s) self.text=s end
function methods:getString() return self.text end
function methods:setColor(c) self.color=c end
function methods:setVisible(v) self.visible=v end
function methods:isVisible() return self.visible end
function methods:setScale(s) self.scale=s end
function methods:getScale() return self.scale end
function methods:setScaleX(s) self.scaleX=s end
function methods:setPositionX(x) self.pos.x=x end
function methods:setScaleY(s) self.scaleY=s end
function methods:setContainer(n) self.container=n end
function methods:removeAllChildren() self.children={} end
function methods:registerScriptTapHandler(f) self.callback=f end
function methods:registerLongPressed(f) self.longpress=f end
function methods:setContentOffset(p) self.offset=p end
cc={p=function(x,y)return {x=x,y=y}end,size=function(w,h)return {width=w,height=h}end,c3b=function(r,g,b)return {r=r,g=g,b=b}end,c4b=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end,rect=function(x,y,w,h)return {x=x,y=y,width=w,height=h}end}
cc.c4f=cc.c4b
cc.Node={create=function() return node() end}; cc.Layer=cc.Node;cc.DrawNode=cc.Node
cc.LayerColor={create=function(_,c,w,h) local n=node(w,h);n.color=c; return n end}
cc.LabelTTF={create=function(_,s,font,size) local n=node(#s*size/3,size);n.text=s;return n end}
cc.Sprite={create=function(_,path) local n=node(path:find('Circle') and 50 or 128,path:find('Circle') and 50 or 59);n.path=path;return n end}
cc.MenuItemSprite={create=function(_,a,b) local n=node(a.size.width,a.size.height);n.normal=a;n.selected=b;return n end}
cc.MenuItemImage={create=function(_,a,b) return node() end}
cc.Menu={create=function(_,...) local n=node();for _,v in ipairs({...})do n:addChild(v)end;return n end}
cc.ScrollView={create=function(_,s) local n=node(s.width,s.height);n.viewSize=s;return n end}
local screenHeight=1136
cc.Director={getInstance=function()return {getVisibleSize=function()return {width=640,height=screenHeight}end,getVisibleOrigin=function()return {x=0,y=0}end}end}
cc.FileUtils={getInstance=function()return {isFileExist=function()return false end}end}
SDButton={create=function(_,a,b,f)local n=node(50,50);n.path=a;n.callback=f;n.normalSpr=node(50,50);n.selectSpr=node(50,50);return n end}
BaseView={}
function class(name,ctor) local t={};t.new=function() return setmetatable({}, {__index=t})end;return t end
function cclog()end
local state, debits, saves, transitions, toast, details
local events={};local purchases=0;local charges=0;local homes=0;local talents=0;local warehouses=0
local csv={resources={['1005']={carryType='1',name='食物',desc='航行补给',cubage='1',starNum='1'},['1006']={carryType='1',name='道具',desc='道具说明',cubage='2',starNum='2'},['1299']={name='当前战船',carryType='0'}},soldiers={['100']={name='水手',skill='1',hp='10',attack='2',speed='1',star='1'}},skills={['1']={name='攻击',buffID='0'}},buffs={}}
local manager={}
function manager:getRoleData(key)return state[key]end
function manager:getCSVByID(key)return csv[key]end
function manager:setRoleData(key,val)state[key]=val;saves=saves+1 end
function manager:addPackItemWithId(id,num)state.pack[id]=state.pack[id]+num;debits=debits+1 end
function manager:addSoilderWithId(id,num)state.crew[id].num=state.crew[id].num+num;debits=debits+1 end
function manager:registerEvent(key,owner,callback)events[key..':'..owner]=callback end
function manager:unregisterEvent(key,owner)events[key..':'..owner]=nil end
function manager:showBuyGoldBox()purchases=purchases+1 end
ChargeLayer={create=function()charges=charges+1 end}
DataManager={getInstance=function()return manager end}
GuideController={getInstance=function()return {getIsHaveStep=function()return true end,addStep=function()end,removeRedPoint=function()end,addRedPoint=function()end}end}
ToastUtil={downString=function(_,s)toast=s end}
zqDispatch={moveToFightLayer=function()transitions=transitions+1 end,moveToHome=function()homes=homes+1 end,moveToTalent=function()talents=talents+1 end,moveToRepository=function()warehouses=warehouses+1 end}
require 'LuaClass/Expedition'
local function newView(height, selection)
 screenHeight=height;debits=0;saves=0;transitions=0;toast=nil
 state={money=4651,diamond=213,ship='1299',capacity=60,cabin=3,pack={['1005']=100,['1006']=2},crew={['100']={num=3}},selection=selection or {}}
 local v=ExpeditionLayer.new()
 v.children={};v.addChild=methods.addChild
 for _,k in ipairs({'titleLabel','mainBg','titleBg','storeMenu','topLeftBtn','topRightBtn'})do v[k]=node()end
 v.setBackgroundIcon=function()end;v.resetTopRightButtonToRank=function()end
 v.addInfoNode=function(self)
  self.infoNode=node();self.setBtn=node();self.setBtnLight=node();self.bottomInfoBox=node();self.infoBoxLabel=node()
  self.infoNode:addChild(self.setBtn);self.infoNode:addChild(self.setBtnLight);self.infoNode:addChild(self.bottomInfoBox)
 end
 v.showInfoBox=function(_,s) details=s end;v.superDestory=function()end
 assert(v:init())
 local color=v.infoBoxLabel.color
 assert(color.r==255 and color.g==248 and color.b==224,'legacy dark tooltip retains readable warm-white text')
 return v
end
local function rowFor(v,id)
 for i,data in ipairs(v.expeditionData)do if data.id==id then return v.scrollViewContainer.children[i]end end
end
local function controls(row)
 local out={}
 for _,n in ipairs(row.children)do
  if type(n.path)=='string' then if n.path:find('SubCircle')then out.minus=n elseif n.path:find('AddCircle')then out.plus=n end end
  if type(n.children)=='table' then for _,c in ipairs(n.children)do if type(c.bLabel)=='table' then if c.bLabel.text=='装满'then out.full=c elseif c.bLabel.text==''then out.info=c end end end end
 end
 return out
end
local function verifyQuantityTargets(v)
 local food=controls(rowFor(v,'1005'))
 local function bounds(button)
  local size=button:getContentSize()
  local result
  for _,sprite in ipairs({button.normalSpr,button.selectSpr})do
   local z=sprite:getContentSize()
   local width=z.width*sprite.scaleX;local height=z.height*sprite.scaleY
   assert(width>=59-1e-6 and height>=59-1e-6,'quantity sprite target minimum 59 logical points')
   assert(width*480/640>=44 and height*480/640>=44,'quantity target reaches 44 pixels at 480')
   assert(math.abs(sprite.pos.x+width/2-size.width/2)<1e-6 and math.abs(sprite.pos.y+height/2-size.height/2)<1e-6,'expanded transparent target stays centered')
   result={left=button.pos.x-size.width/2+sprite.pos.x,right=button.pos.x-size.width/2+sprite.pos.x+width,height=height}
  end
  assert(math.abs(size.width-78*v.adventureScaleX)<1e-6 and math.abs(size.height-68*v.adventureScaleY)<1e-6,'visible quantity skin dimensions unchanged')
  return result
 end
 local minus,plus=bounds(food.minus),bounds(food.plus)
 assert(minus.right<plus.left,'quantity targets do not overlap each other')
 assert(food.info.pos.x+food.info.size.width/2<minus.left,'minus target clears details column')
 assert(plus.right<food.full.pos.x-food.full.size.width/2,'plus target clears fill column')
 assert(math.max(minus.height,plus.height)<v.adventureRowHeight,'quantity targets clear neighboring rows')
end
local v=newView(1136)
verifyQuantityTargets(v)
assert(v.isApprovedDeparture and v.approvedPage and v.keepNavigation,'shared header/navigation contract')
assert(v.shipNameLabel.text=='当前战船','ship name from current CSV')
assert(v.departureCoinLabel.text=='4651' and v.departureDiamondLabel.text=='213','live currency initial values')
state.money=7320;state.diamond=67;events['money:approvedDeparture']();events['diamond:approvedDeparture']()
assert(v.departureCoinLabel.text=='7320' and v.departureDiamondLabel.text=='67','live currency event updates')
v.departureCoinAdd.callback();v.departureDiamondAdd.callback();v.departureBackButton.callback();v.talentShortcut.item.callback();v.warehouseShortcut.item.callback()
assert(purchases==1 and charges==1 and homes==1 and talents==1 and warehouses==1,'real route and purchase callbacks')
assert(v.scrollView:getViewSize().height>=200, 'tall viewport list too short')
v.departureAction();assert(debits==0 and transitions==0 and not v.departureInProgress and toast:find('食物'), 'no food validation')
local food=controls(rowFor(v,'1005'));local crew=controls(rowFor(v,'10100'))
local other=controls(rowFor(v,'1006'));other.plus.callback();assert(v.useBoatNum==2 and state.selection['1006']==1,'multi-slot cargo addition')
other.minus.callback();assert(v.useBoatNum==0 and state.selection['1006']==0,'single item with multi-slot cubage can be removed')
food.plus.callback();assert(state.selection['1005']==1 and v.useBoatNum==1 and v.foodLabel.text=='已备食物 1')
v.departureAction();assert(debits==0 and transitions==0 and not v.departureInProgress and toast:find('士兵'), 'no crew validation')
food.plus.longpress();food.minus.callback();assert(state.selection['1005']==1, 'long press and subtract')
food.full.callback();assert(state.selection['1005']==60 and v.useBoatNum==60, 'fill respects capacity')
food.plus.callback();assert(state.selection['1005']==60,'capacity guard')
crew.full.callback();assert(state.selection['10100']==3 and v.useSoldierNum==3,'crew fill')
food.info.callback();assert(details:find('航行补给'),'item details')
crew.info.callback();assert(details:find('生命：10') and details:find('攻击'),'crew details')
assert(v.readyLabel.text:find('整备就绪'),'readiness')
v.departureAction();assert(debits==2 and transitions==1 and state.pack['1005']==40 and state.crew['100'].num==0,'departure inventory')
assert(state.battle['100']==3 and state.battlepack['1005'].num==60 and next(state.selection)==nil,'departure save payload')
v.departureAction();assert(debits==2 and transitions==1,'repeated departure must be inert')
v=newView(960,{['1005']=2,['10100']=1});verifyQuantityTargets(v);assert(v.useBoatNum==2 and v.useSoldierNum==1,'selection restores')
assert(v.scrollView:getViewSize().height>=150,'short viewport list too short')
state.selection['1005']=0;v:setResourceUIWithData();assert(v.readyLabel.text=='船员已就位，请装入航行食物','food-only missing readiness')
assert(v.scrollView.pos.y>UIBottomHeight and v.scrollView.pos.y+v.scrollView:getViewSize().height<960-UITopHeight,'viewport bounds')
assert(v.warehouseShortcut.pos.y-v.warehouseShortcut.size.height/2>=118,'short-screen shortcut clears shared nav')
csv.resources['1037']={carryType='1',name='钥匙',desc='开箱',cubage='1',starNum='1'}
state.pack['1037']=3;v:setResourceUIWithData();assert(#v.expeditionData==4 and v.adventureRowHeight*4<=v.scrollView:getViewSize().height,'four inventory rows fit without clipping')
csv.resources['1007']={carryType='1',name='额外补给',desc='道具',cubage='1',starNum='1'}
state.pack['1007']=2;v:setResourceUIWithData();assert(#v.expeditionData==5 and v.scrollView.offset.y<0,'additional inventory remains scrollable')
-- Production must keep both the pressed instance and its stock closure live.
state.pack={['1005']=4};state.crew={['100']={num=3}};state.selection={['1005']=2,['10100']=1};v:setResourceUIWithData()
local foodRow=rowFor(v,'1005');local held=controls(foodRow);local savesBeforeTick=saves
state.pack['1005']=9;events['breadBirth:expedition']()
assert(rowFor(v,'1005')==foodRow and controls(rowFor(v,'1005')).minus==held.minus and controls(rowFor(v,'1005')).plus==held.plus,'production retains row and long-press buttons')
assert(foodRow.remainingLabel.text=='余 7' and state.selection['1005']==2 and saves==savesBeforeTick,'production only refreshes stock presentation')
held.minus.longpress();assert(state.selection['1005']==1 and foodRow.remainingLabel.text=='余 8','held minus continues after production')
held.plus.longpress();assert(state.selection['1005']==2 and foodRow.remainingLabel.text=='余 7','held plus continues after production')
held.full.callback();assert(state.selection['1005']==9 and foodRow.remainingLabel.text=='余 0','fill consumes new stock rather than stale closure')
state.pack['1005']=12;events['breadBirth:expedition']();held.plus.longpress()
assert(state.selection['1005']==10 and foodRow.remainingLabel.text=='余 2','repeated production refreshes same stock upvalue')
held.full.callback();assert(state.selection['1005']==12 and foodRow.remainingLabel.text=='余 0','fill stays accurate after repeated tick and selection changes')
local debitsBefore,switchesBefore=debits,transitions
v.departureAction();v.departureAction()
assert(debits==debitsBefore+2 and transitions==switchesBefore+1 and state.pack['1005']==0 and state.crew['100'].num==2,'post-production departure debits once')
v:destory();assert(not events['breadBirth:expedition'] and v.foodStockUpdater==nil,'leaving clears food listener and row closure')
-- When food first arrives there is no existing control to retain.
v=newView(960);state.pack={};state.crew={['100']={num=1}};state.selection={};v:setResourceUIWithData()
assert(not rowFor(v,'1005'),'food absent before production')
state.pack['1005']=3;events['breadBirth:expedition']()
local newFood=controls(rowFor(v,'1005'));newFood.full.callback()
assert(state.selection['1005']==3,'first food production builds an operable row')
state.pack={};state.crew={};state.selection={};v:setResourceUIWithData();assert(#v.expeditionData==0 and #v.scrollViewContainer.children==1,'empty inventory message')
v:destory();assert(v.departureInProgress and v.departureAction==nil,'cleanup')
assert(not events['money:approvedDeparture'] and not events['diamond:approvedDeparture'],'currency listeners removed on destroy')
print('PASS: production retains controls and refreshes closure stock, 44px minimum quantity targets without overlap, approved departure header/currencies/routes, CSV ship name, multi-slot cargo, 1136/960 layout, food/crew validation, quantities/long press/fill, inventory limits, details, restored selection, empty list, departure save payload, repeat-tap guard, cleanup')
