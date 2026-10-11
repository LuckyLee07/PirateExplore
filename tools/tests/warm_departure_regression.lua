WARM_PIRATE_V1=true
package.path = 'bin/res/scripts/?.lua;' .. package.path
package.loaded['LuaClass/Header'] = true
package.loaded['LuaClass/BaseView'] = true
package.loaded['LuaClass/UIKit'] = true
BoldFont='test'; WriteColor={r=255,g=255,b=255}; BaseColor={r=0,g=0,b=0}
UITopHeight=100; UIBottomHeight=136
roleStatue='status';roleMoney='money';roleDiamond='diamond';roleShipId='ship';rolePackSize='capacity'; roleCabinSize='cabin'; rolePack='pack'; roleSoildierQueue='crew'; roleSelectUnit='selection'; roleBattleQueue='battle'; roleBattlePack='battlepack'; roleGuideStep='guide'
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
manager.__roleData={commitAdventure=function(_,fields) for k,v in pairs(fields)do state[k]=v end;saves=saves+1;return true end}
function manager:postEvent()end
function manager:registerEvent(key,owner,callback)events[key..':'..owner]=callback end
function manager:unregisterEvent(key,owner)events[key..':'..owner]=nil end
function manager:showBuyGoldBox()purchases=purchases+1 end
ChargeLayer={create=function()charges=charges+1 end}
DataManager={getInstance=function()return manager end}
GuideController={getInstance=function()return {getIsHaveStep=function()return true end,addStep=function()end,removeRedPoint=function()end,addRedPoint=function()end}end}
ToastUtil={downString=function(_,s)toast=s end,toastString=function(_,s)toast=s end}
zqDispatch={moveToFightLayer=function()transitions=transitions+1 end,moveToHome=function()homes=homes+1 end,moveToTalent=function()talents=talents+1 end,moveToRepository=function()warehouses=warehouses+1 end}
require 'LuaClass/Expedition'
local function newView(height, selection, adventure)
 screenHeight=height;debits=0;saves=0;transitions=0;toast=nil
 state={money=4651,diamond=213,ship='1299',capacity=60,cabin=3,pack={['1005']=100,['1006']=2},crew={['100']={num=3}},selection=selection or {}}
 state.adventureProgressV1=adventure and {version=1,enabled=true,objective='rescue',voyage=2} or nil
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

local function warmTargets(v)
 assert(v.expeditionData[1].id=='10100' and v.warmGroups[1].kind=='crew' and v.warmGroups[2].kind=='food','crew and supplies are distinct context groups')
 assert(not rowFor(v,'10100').controls.full.visible and not rowFor(v,'1006').controls.full.visible and rowFor(v,'1005').controls.full.visible,'only food exposes fill-to-capacity')
 assert(v.cargoRemainingLabel.text=='空余货舱 60 / 60 格','cargo preview is backed by actual remaining capacity')
 local row=rowFor(v,'1005');local c=row.controls
 local function bounds(button)
  local size=button:getContentSize();local s=button.normalSpr;local z=s:getContentSize()
  local w,h=z.width*s.scaleX,z.height*s.scaleY
  assert(w>=59 and h>=59,'44px minimum quantity targets at 480px viewport')
  return button.pos.x-size.width/2+s.pos.x,button.pos.x-size.width/2+s.pos.x+w
 end
 local ml,mr=bounds(c.minus);local pl,pr=bounds(c.plus)
 assert(c.details.pos.x+c.details.size.width/2<ml and mr<pl and pr<c.full.pos.x-c.full.size.width/2,'real details/quantity/fill targets never overlap')
 assert(v.scrollView.pos.y>=v.warmFooterTop and v.scrollView.pos.y+v.scrollView:getViewSize().height<=v.warmSheetTop-20,'scroll controls stay between header and footer')
 assert(v.departureButton.pos.y-v.departureButton.size.height/2>=20,'primary clears bottom safe inset')
 assert(not v.talentShortcut and not v.warehouseShortcut and not v.departureCoinAdd,'preparation retains one dominant action without management/shop shortcuts')
end
for _,height in ipairs({1136,960})do
 local v=newView(height)
 assert(v.isWarmDeparture and not v.keepNavigation and v.shipNameLabel.text=='当前战船','warm page uses existing route and CSV ship')
 warmTargets(v)
 assert(v.departureCoinLabel.text=='4651','actual money shown')
 state.money=7000;events['money:approvedDeparture']();assert(v.departureCoinLabel.text=='7000','live money refresh')
 v.departureAction();assert(debits==0 and transitions==0 and toast:find('食物'),'no-food condition preserved')
 local food=rowFor(v,'1005').controls;local crew=rowFor(v,'10100').controls
 food.plus.callback();v.departureAction();assert(debits==0 and transitions==0 and toast:find('士兵'),'crew is still mandatory')
 crew.plus.callback();food.details.callback();assert(details:find('航行补给'),'resource details remain real')
 crew.details.callback();assert(details:find('生命：10'),'crew details retain attributes')
 local saved=state.selection;local before=saves
 v.departureBackButton.callback();assert(homes>0 and state.selection==saved and saves==before and debits==0,'cancel returns home without spending or erasing loadout')
 local other=rowFor(v,'1006').controls;other.plus.callback();assert(v.useBoatNum==3,'actual cubage is charged')
 other.minus.callback();assert(v.useBoatNum==1,'multi-slot item removal is accurate')
 food.full.callback();assert(state.selection['1005']==60 and v.readyLabel.text:find('货舱已满'),'full cargo displays actionable state')
 local beforeFull=saves;food.plus.callback();assert(state.selection['1005']==60 and saves==beforeFull,'capacity guard preserved')
 food.minus.longpress();assert(state.selection['1005']==59,'quantity long press remains functional')
 v.departureAction();v.departureAction();assert(debits==2 and transitions==1 and state.pack['1005']==41,'single debit on repeated departure')
 food.plus.callback();food.minus.longpress();food.full.callback();assert(next(state.selection)==nil,'stale quantity controls are inert during transition')
 v:destory();assert(not events['breadBirth:expedition'] and not events['money:approvedDeparture'],'listeners cleaned up')
end
local v=newView(960,{['1005']=2,['10100']=1})
local row=rowFor(v,'1005');local held=row.controls
state.pack['1005']=9;local before=saves;events['breadBirth:expedition']()
assert(rowFor(v,'1005')==row and row.controls.plus==held.plus and saves==before,'production keeps real pressed instances and selection')
held.minus.longpress();held.plus.longpress();held.full.callback()
assert(state.selection['1005']==9 and row.remainingLabel.text=='余 0','stock closures refresh across production and held gestures')
state.pack['1005']=12;events['breadBirth:expedition']();held.plus.longpress()
assert(state.selection['1005']==10 and row.remainingLabel.text=='余 2','repeated production remains live')
-- Abundant inventory scrolls, and initial empty state can receive new food.
for i=1007,1012 do csv.resources[tostring(i)]={carryType='1',name='补给',desc='物品',cubage='1'};state.pack[tostring(i)]=3 end
v:setResourceUIWithData();assert(v.scrollView.offset.y<0,'all actual cargo remains scrollable')
state.pack={};state.crew={};state.selection={};v:setResourceUIWithData()
assert(#v.expeditionData==0 and #v.scrollViewContainer.children==1,'empty inventory remains explained')
state.pack['1005']=3;events['breadBirth:expedition']();rowFor(v,'1005').controls.full.callback()
assert(state.selection['1005']==3,'first production creates an operable food row')
v:destory()
-- Warm objective controls keep the v1 transaction and cancel/failure outcomes.
local dialog
package.loaded['LuaClass/AdventureDialog']={show=function(title,body,options,owner)dialog={title=title,body=body,options=options};return dialog end}
v=newView(1136,{['1005']=2,['10100']=1},true)
assert(v.voyageLabel.text=='第 3 次出航' and v.objectiveButton.label.text:find('救援'),'context is real voyage and objective')
v.objectiveButton.item.callback();assert(dialog.options[3].action==nil,'objective cancel has no write')
local before=saves;local result=dialog.options[2].action()
assert(result~=false and state.adventureProgressV1.objective=='supply' and saves==before+1 and v.objectiveButton.label.text:find('补给'),'objective saves once through AdventureProgress')
local commit=manager.__roleData.commitAdventure;manager.__roleData.commitAdventure=function()return false end
assert(dialog.options[1].action()==false and state.adventureProgressV1.objective=='supply','failed objective leaves selected objective unchanged')
v.departureAction();assert(not v.departureInProgress and transitions==0 and state.pack['1005']==100,'save failure leaves inventory and departure intact')
manager.__roleData.commitAdventure=commit
v.departureAction();v.departureAction()
assert(state.adventureProgressV1.activeVoyage==3 and transitions==1 and state.pack['1005']==98 and state.crew['100'].num==2,'real v1 atomic departure commits once')
assert(next(state.selection)==nil and state.battlepack['1005'].num==2 and state.battle['100']==1,'real selection and battle payload preserved')
v:destory()
v=newView(960,{['1005']=2,['10100']=1},true)
state.pack['1005']=1
v.departureAction();assert(not v.departureInProgress and transitions==0 and state.pack['1005']==1 and toast:find('库存已变化'),'insufficient current stock gives specific feedback without debit')
rowFor(v,'1005').controls.minus.callback();v.departureAction()
assert(transitions==1 and state.pack['1005']==0,'corrected insufficient loadout can depart normally')
v:destory()
-- A long real roster remains scrollable without changing its selection model.
v=newView(1067)
for id=101,112 do
 csv.soldiers[tostring(id)]={name='测试伙伴 '..id,skill='1',hp='10',attack='2',speed='1',star='1'}
 state.crew[tostring(id)]={num=2}
end
v:setResourceUIWithData()
assert(v.scrollView.offset.y<0 and #v.expeditionData==15,'long roster and supplies remain present in one scrollable loadout')
assert(rowFor(v,'1005').pos.y<rowFor(v,'10112').pos.y,'supplies follow the actual crew roster')
for _,node in ipairs(v.scrollViewContainer.children)do
 if type(node.itemId)=='string' and node.itemId~='1005' then assert(not node.controls.full.visible,'long roster never adds redundant fill actions')end
end
local chosen=rowFor(v,'10112').controls;chosen.plus.longpress();rowFor(v,'1005').controls.plus.callback()
assert(state.selection['10112']==1 and state.selection['1005']==1,'far-down roster and food retain real callbacks')
assert(v.cargoRemainingLabel.text=='空余货舱 59 / 60 格' and math.abs(v.cargoCapacityBar.scaleX-59/60)<1e-6,'remaining-capacity text and visualization agree')
v:destory()
print('PASS: warm departure 1136/960 layout, one primary action, real ship/voyage/goal, cancel, economy, crew/food/cargo, details, quantity/fill/long press, production retention, empty inventory, overflow scrolling, atomic goal/departure failure and success, repeated/stale controls, cleanup')
