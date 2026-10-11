-- Real Cocos nodes, fonts, MenuItem activation and SDButton quantity closures.
-- Run in the existing tutorial-log-native EGL/LuaEngine harness; no save opened.
require 'extern'
require 'Cocos2d'
require 'Cocos2dConstants'
WARM_PIRATE_V1=true;BoldFont='Noto Sans CJK SC'
package.loaded['LuaClass/Header']=true;package.loaded['LuaClass/BaseView']=true
package.loaded['LuaClass/UIKit']=true;package.loaded['LuaClass/DataManager']=true
BaseView={};function cclog()end
roleMoney='money';roleDiamond='diamond';roleShipId='ship';rolePackSize='capacity';roleCabinSize='cabin'
rolePack='pack';roleSoildierQueue='crew';roleSelectUnit='selection'
csvOfResourceInfo='resources';csvOfSkillAttribute='skills';csvOfSoilderAttribute='soldiers';csvOfBuff='buffs'
dataKeyID='id';dataKeyNum='num'
local state,viewport,scene
local events={};local saves=0;local homes=0;local departures=0
local csv={resources={['1005']={carryType='1',name='食物',desc='航行补给',cubage='1',starNum='1',icon='B/resource-1005.png'},
 ['1006']={carryType='1',name='多格物品',desc='测试补给',cubage='2',starNum='2'},['1299']={name='当前战船'}},
 soldiers={['100']={name='初级船员',skill='1',hp='10',attack='2',speed='1',star='1',icon='B/crew-100.png'}},skills={['1']={name='攻击',buffID='0'}},buffs={}}
local dm={getRoleData=function(_,k)return state[k]end,getCSVByID=function(_,k)return csv[k]end,
 setRoleData=function(_,k,v)state[k]=v;saves=saves+1 end,registerEvent=function(_,k,owner,fn)events[k..owner]=fn end}
DataManager={getInstance=function()return dm end}
ToastUtil={downString=function()end,toastString=function()end}
zqDispatch={mainMenu={navigationHeight=118},moveToHome=function()homes=homes+1 end}
local oldDirector=cc.Director.getInstance
local director=oldDirector(cc.Director)
cc.Director.getInstance=function()return setmetatable({
 getVisibleSize=function()return viewport end,getWinSize=function()return viewport end,
 getVisibleOrigin=function()return cc.p(0,0)end,getRunningScene=function()return scene end},
 {__index=function(_,k)return function(_,...)return director[k](director,...)end end})end
require 'LuaClass/SDButton'
require 'LuaClass/Expedition'
local WarmDeparture=require 'LuaClass/WarmDeparture'
local function close()
 scene:cleanup();scene:release();scene=nil
end
local function row(view,id)
 for _,node in ipairs(view.scrollViewContainer:getChildren())do if node.itemId==id then return node end end
end
for _,height in ipairs({960,1067,1136})do
 viewport=cc.size(640,height);scene=cc.Scene:create();scene:retain()
 state={money=4651,diamond=213,ship='1299',capacity=60,cabin=3,pack={['1005']=100,['1006']=2},crew={['100']={num=3}},selection={}}
 local view=cc.Layer:create();scene:addChild(view)
 for _,key in ipairs({'mainBg','titleBg','storeMenu','infoNode','setBtn','setBtnLight','bottomInfoBox'})do view[key]=cc.Node:create();view:addChild(view[key])end
 view.infoBoxLabel=cc.LabelTTF:create('',BoldFont,20);view.infoNode:addChild(view.infoBoxLabel)
 view.departureAction=function()departures=departures+1 end
 view.produceCsv=csv.resources;view.updateAdventureReadiness=ExpeditionLayer.updateAdventureReadiness
 view.showInfoBox=function(_,text)assert(text:find('航行补给') or text:find('生命'))end
 WarmDeparture.create(view)
 ExpeditionLayer.setResourceUIWithData(view)
 local food=row(view,'1005');local crew=row(view,'10100')
 assert(food and crew and view.isWarmDeparture)
 assert(not crew.controls.full:isVisible() and food.controls.full:isVisible(),'only food shows fill')
 assert(crew:getPositionY()>food:getPositionY(),'crew group precedes supplies')
 local function within(node,left,right)
  local sz=node:getContentSize();local a=node:getAnchorPoint();local x=node:getPositionX();local scale=node:getScale()
  assert(x-sz.width*a.x*scale>=left-1 and x+sz.width*(1-a.x)*scale<=right+1,'native label width in bounds')
 end
 within(view.readyLabel,20,620);within(view.shipNameLabel,24,272)
 within(food.nameLabel,90,258);within(crew.nameLabel,125,313)
 assert(view.scrollView:getPositionY()+view.scrollView:getViewSize().height<=view.warmSheetTop-20)
 food.controls.plus.onSingleCLick();assert(state.selection['1005']==1)
 crew.controls.plus.onLongPressed();assert(state.selection['10100']==1)
 food.controls.full:activate();assert(state.selection['1005']==60)
 food.controls.minus.onLongPressed();assert(state.selection['1005']==59)
 food.controls.details:activate();crew.controls.details:activate()
 local stockUpdater=view.foodStockUpdater;state.pack['1005']=108;stockUpdater(108)
 assert(row(view,'1005')==food and food.remainingLabel:getString()=='余 49')
 view.departureBackButton:activate();assert(homes>0)
 view.departureButton.item:activate();assert(departures>0)
 view.departureInProgress=true;local before=saves
 food.controls.plus.onLongPressed();food.controls.full:activate();food.controls.minus.onSingleCLick()
 assert(saves==before,'native quantity controls inert after departure')
 close()
 print('PASS native warm departure '..height..': actual art/fonts/row and footer bounds, real SDButton/Menu activation, retained production closure, guarded stale controls, teardown')
end
cc.Director.getInstance=oldDirector
