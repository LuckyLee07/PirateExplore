package.path = 'bin/res/scripts/?.lua;' .. package.path
package.loaded['LuaClass/Header'] = true
package.loaded['LuaClass/BaseView'] = true
package.loaded['LuaClass/UIKit'] = true
BoldFont='test'; WriteColor={r=255,g=255,b=255}; BaseColor={r=0,g=0,b=0}
UITopHeight=100; UIBottomHeight=136
rolePackSize='capacity'; roleCabinSize='cabin'; rolePack='pack'; roleSoildierQueue='crew'; roleSelectUnit='selection'; roleBattleQueue='battle'; roleBattlePack='battlepack'; roleGuideStep='guide'
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
function methods:setContainer(n) self.container=n end
function methods:removeAllChildren() self.children={} end
function methods:registerScriptTapHandler(f) self.callback=f end
function methods:registerLongPressed(f) self.longpress=f end
function methods:setContentOffset(p) self.offset=p end
cc={p=function(x,y)return {x=x,y=y}end,size=function(w,h)return {width=w,height=h}end,c3b=function(r,g,b)return {r=r,g=g,b=b}end,c4b=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end,rect=function(x,y,w,h)return {x=x,y=y,width=w,height=h}end}
cc.Node={create=function() return node() end}; cc.Layer=cc.Node
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
local csv={resources={['1005']={carryType='1',name='食物',desc='航行补给',cubage='1',starNum='1'},['1006']={carryType='1',name='道具',desc='道具说明',cubage='1',starNum='2'}},soldiers={['100']={name='水手',skill='1',hp='10',attack='2',speed='1',star='1'}},skills={['1']={name='攻击',buffID='0'}},buffs={}}
local manager={}
function manager:getRoleData(key)return state[key]end
function manager:getCSVByID(key)return csv[key]end
function manager:setRoleData(key,val)state[key]=val;saves=saves+1 end
function manager:addPackItemWithId(id,num)state.pack[id]=state.pack[id]+num;debits=debits+1 end
function manager:addSoilderWithId(id,num)state.crew[id].num=state.crew[id].num+num;debits=debits+1 end
function manager:registerEvent()end
function manager:unregisterEvent()end
DataManager={getInstance=function()return manager end}
GuideController={getInstance=function()return {getIsHaveStep=function()return true end,addStep=function()end,removeRedPoint=function()end,addRedPoint=function()end}end}
ToastUtil={downString=function(_,s)toast=s end}
zqDispatch={moveToFightLayer=function()transitions=transitions+1 end}
require 'LuaClass/Expedition'
local function newView(height, selection)
 screenHeight=height;debits=0;saves=0;transitions=0;toast=nil
 state={capacity=60,cabin=3,pack={['1005']=100,['1006']=2},crew={['100']={num=3}},selection=selection or {}}
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
local v=newView(1136)
assert(v.scrollView:getViewSize().height>=200, 'tall viewport list too short')
v.departureAction();assert(debits==0 and transitions==0 and not v.departureInProgress and toast:find('食物'), 'no food validation')
local food=controls(rowFor(v,'1005'));local crew=controls(rowFor(v,'10100'))
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
v=newView(960,{['1005']=2,['10100']=1});assert(v.useBoatNum==2 and v.useSoldierNum==1,'selection restores')
assert(v.scrollView:getViewSize().height>=150,'short viewport list too short')
state.selection['1005']=0;v:setResourceUIWithData();assert(v.readyLabel.text=='船员已就位，请装入航行食物','food-only missing readiness')
assert(v.scrollView.pos.y>UIBottomHeight and v.scrollView.pos.y+v.scrollView:getViewSize().height<960-UITopHeight,'viewport bounds')
state.pack={};state.crew={};state.selection={};v:setResourceUIWithData();assert(#v.expeditionData==0 and #v.scrollViewContainer.children==1,'empty inventory message')
v:destory();assert(v.departureInProgress and v.departureAction==nil,'cleanup')
print('PASS: 1136/960 layout, food/crew validation, quantities/long press/fill, inventory limits, details, restored selection, empty list, departure save payload, repeat-tap guard, cleanup')
