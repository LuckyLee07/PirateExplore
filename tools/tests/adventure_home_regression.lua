unpack=unpack or table.unpack
local root='bin/res/scripts/LuaClass/'
local originalRequire=require
require=function(name) if name=='LuaClass/BTheme' then return BTheme end return true end
local Node={}
function Node:setContentSize(v) self.size=v end
function Node:getContentSize() return self.size or {width=80,height=80} end
function Node:setPosition(a,b) self.pos=type(a)=='table' and a or {x=a,y=b} end
function Node:getPositionX() return (self.pos or {}).x or 0 end
function Node:getPositionY() return (self.pos or {}).y or 0 end
function Node:setPositionY(y) self.pos=self.pos or {x=0}; self.pos.y=y end
function Node:setAnchorPoint(v) self.anchor=v end
function Node:setString(s) self.text=s end
function Node:setScale(v) self.scale=v end
function Node:setScaleX(v) self.scaleX=v end
function Node:setScaleY(v) self.scaleY=v end
function Node:getScale() return self.scale or 1 end
function Node:setColor(v) self.color=v end
function Node:setVisible(v) self.visible=v end
function Node:addChild(v) self.children=self.children or {}; table.insert(self.children,v); v.parent=self end
function Node:getParent() return self.parent end
function Node:removeFromParent() self.parent=nil end
function Node:registerScriptTapHandler(cb) self.callback=cb end
function Node:setDimensions(v) self.dimensions=v end
function Node:runAction(a) self.action=a end
for _,m in ipairs({'ignoreAnchorPointForPosition','setCascadeOpacityEnabled','setOpacity','stopAllActions','setFlippedX','addClickArea','setLocalZOrder'}) do Node[m]=function() end end
local function node() return setmetatable({size={width=80,height=80}},{__index=Node}) end
cc={}
cc.p=function(x,y) return {x=x,y=y} end
cc.size=function(w,h) return {width=w,height=h} end
cc.c3b=function(r,g,b) return {r=r,g=g,b=b} end
cc.c4b=function(r,g,b,a) return {r=r,g=g,b=b,a=a} end
cc.rect=function(x,y,w,h) return {x=x,y=y,width=w,height=h} end
cc.Node={create=node};cc.Layer={create=node};cc.Sprite={create=node}
cc.LayerColor={create=function(_,color,w,h) local n=node();n.size={width=w,height=h};n.color=color;return n end}
cc.LabelTTF={create=function(_,text,font,size) local n=node();n.text=text;n.size={width=#text*size*0.4,height=size};return n end}
cc.MenuItemSprite={create=function(_,a,b) local n=node();n.size=a.size;return n end}
cc.Menu={create=function(_,...) local n=node();for _,c in ipairs({...}) do n:addChild(c) end;return n end}
cc.Director={getInstance=function() return {getVisibleSize=function() return {width=640,height=1136} end,getVisibleOrigin=function() return {x=0,y=0} end} end}
cc.FileUtils={getInstance=function() return {isFileExist=function() return false end} end}
cc.Texture2D={setDefaultAlphaPixelFormat=function() end}
for _,name in ipairs({'FadeOut','FadeIn','FadeTo','ScaleTo','DelayTime','Sequence','CallFunc','EaseExponentialIn','MoveTo','RepeatForever'}) do cc[name]={create=function(_,...) return {...} end} end
function class(name,factory)
 local cls={};function cls.new() local n=factory();setmetatable(n,{__index=function(_,k) return cls[k] or Node[k] end});return n end;return cls
end
BoldFont='stub';cclog=function() end
for _,k in ipairs({'rolePack','roleSelectUnit','roleSoildierQueue','rolePackSize','roleCabinSize','roleGuideStep','roleMoney','roleDiamond','roleMapInfo','csvOfResourceInfo','dataKeyNum'}) do _G[k]=k end
local data={rolePack={},roleSelectUnit={['12']=2,['10001']=3},roleSoildierQueue={['1']={dataKeyNum=5}},rolePackSize=40,roleCabinSize=6,roleMoney=1250,roleDiamond=20}
local events={};local writes=0;local guideUnlocked=true
local dm={getRoleData=function(_,k)return data[k]end,getCSVByID=function()return {['12']={cubage='4'}}end,registerEvent=function(_,k,id,fn)events[k..id]=fn end,unregisterEvent=function(_,k,id)events[k..id]=nil end,getSound_off=function()return 1 end,sendSystemInfo=function()end,setRoleData=function()writes=writes+1 end}
DataManager={getInstance=function()return dm end}
local guide={getIsHaveStep=function()return guideUnlocked end,addStep=function()end,removeRedPoint=function()end,addRedPoint=function()end}
GuideController={getInstance=function()return guide end}
ToastUtil={downString=function(_,text) _G.toast=text end}
AudioEngine={playEffect=function()end}
SDButton={create=node}
PushGiftView={create=function() return {show=function()end} end}
ChargeLayer={create=function()end}
dofile(root..'BTheme.lua')
dofile(root..'Home.lua')
UITopHeight=100;UIBottomHeight=136
local home=HomeLayer:create()
assert(home.crewLabel.text=='3 / 6',home.crewLabel.text)
assert(home.cargoLabel.text=='8 / 40',home.cargoLabel.text)
assert(home.stockLabel.text=='5 人',home.stockLabel.text)
assert(writes==0,'home wrote game state')
assert(home.isAdventureHome)
local count=0;for _ in pairs(events)do count=count+1 end;assert(count==6)
home:destory();for _ in pairs(events)do error('home left subscriptions')end
print('PASS home read-only summary, layout construction, event cleanup')
dofile(root..'MainMenu.lua')
local menu=MainMenuLayer:create()
assert(UITopHeight==100 and UIBottomHeight==136)
assert(menu.homeBtn and menu.expeditionBtn and menu.storeBtn)
assert(menu.selectedIndex==0)
local calls={}
zqDispatch={mainMenu=menu,rightNode={}}
for _,name in ipairs({'moveToHome','moveToExpedition','gotoTrain','gotoBuild','moveToRepository','gotoMake','moveToResource','gotoStore'})do zqDispatch[name]=function()table.insert(calls,name)end end
for i=1,7 do menu:openRoute(i);assert(menu.selectedIndex==i) end
assert(#calls==7)
menu:openRoute(0);assert(calls[8]=='moveToHome')
-- Selected home tab must still return from a growth/details subpage.
menu:openRoute(0);assert(#calls==9)
zqDispatch.rightNode.isAdventureHome=true;menu:openRoute(0);assert(#calls==9)
guideUnlocked=false;menu:openRoute(1);assert(#calls==9 and toast)
print('PASS 8 navigation routes, unlock gate, home return, legacy safe areas')
guideUnlocked=true
dm.getSystemInfoString=function()return '最新故事\n上一条故事\n更早历史\n'end
RandomEventLayer={create=node}
local expeditionCreates=0
ExpeditionLayer={create=function() expeditionCreates=expeditionCreates+1;return node()end}
dofile(root..'Dispatch.lua')
local dispatch=Dispatch:create(false)
assert(dispatch.rightNode.isAdventureHome and expeditionCreates==0)
local sameHome=dispatch.rightNode
dispatch:moveToHome();assert(dispatch.rightNode==sameHome)
assert(dispatch.rightNode.infoLabel.text=='最新故事\n上一条故事')
print('PASS dispatch defaults to home, reuses home, never initializes expedition, clips latest story log')
