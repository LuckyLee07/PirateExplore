-- Runtime-independent API smoke tests; production functions and BTheme are real.
local methods={}
local function node(w,h) return setmetatable({size={width=w or 0,height=h or 0},children={},visible=true,scale=1}, {__index=methods}) end
function methods:setContentSize(s) self.size=s end
function methods:getContentSize() return self.size end
function methods:setPosition(p) self.position=p end
function methods:setAnchorPoint(p) self.anchor=p end
function methods:ignoreAnchorPointForPosition(v) end
function methods:setCascadeOpacityEnabled(v) end
function methods:setColor(v) self.color=v end
function methods:addChild(c,z) table.insert(self.children,c);c.parent=self end
function methods:setScale(v) self.scale=v end
function methods:setScaleX(v) self.scaleX=v end
function methods:setRotation(v) self.rotation=v end
function methods:registerScriptTapHandler(f) self.callback=f end
function methods:runAction(v) self.action=v end
function methods:setVisible(v) self.visible=v end
function methods:isVisible() return self.visible end
function methods:drawTriangle(...) end
function methods:drawSegment(...) end
function methods:setString(s) self.text=s end
cc={}
cc.p=function(x,y) return {x=x,y=y} end
cc.size=function(w,h) return {width=w,height=h} end
cc.c3b=function(r,g,b) return {r=r,g=g,b=b} end
cc.c4b=function(r,g,b,a) return {r=r,g=g,b=b,a=a} end
cc.c4f=cc.c4b
cc.Layer={create=function()return node()end};cc.Node=cc.Layer;cc.DrawNode=cc.Layer
cc.LayerColor={create=function(_,color,w,h)local n=node(w,h);n.color=color;return n end}
cc.LabelTTF={create=function(_,text,font,size)local n=node(#text*size*.4,size);n.text=text;return n end}
cc.MenuItemSprite={create=function(_,normal,selected)local n=node(normal.size.width,normal.size.height);return n end}
cc.Menu={create=function(_,item)local n=node();n:addChild(item);return n end}
cc.FadeOut={create=function()return {}end}
cc.Sprite={create=function(_,path)local n=node(path and 128 or 0,path and 128 or 0);n.path=path;return n end}
local exists=true
cc.FileUtils={getInstance=function()return {isFileExist=function()return exists end}end}
function class(name,ctor) return {} end
require=function()return true end
BoldFont='font';roleExtents=1;roleMapInfo=2;roleShipId=3
UpDiriction=10;LeftDirction=1;RightDircion=2;BottomDirction=20
local roleData={[1]=129,[2]={playerTitlePosition={x=12,y=8}},[3]=1158}
DataManager={getInstance=function()return {getRoleData=function(_,id)return roleData[id]end}end}
dataController={getResourceValueByIdAndKey=function()return 1 end}
Jointed={create=function(_,player,cb)return {enable=true,moveActed=cb}end}
dofile('bin/res/scripts/LuaClass/BTheme.lua')
dofile('bin/res/scripts/LuaClass/Explore.lua')
for _,height in ipairs({853,960,1136}) do
  screenSize={width=640,height=height}
  local owner=node()
  setmetatable(owner,{__index=function(_,key)return Explore[key] or methods[key]end})
  owner.bagController={costSpace=43,limited=60,getBreads=function()return 36 end}
  owner:initTipLayer()
  assert(owner.bread.text=='36' and owner.capacityTips.text=='43/60')
  assert(owner.occupationNum.text=='129' and owner.extentTip.text=='0%')
  assert(owner.adventureHudBottom==160 and owner.adventureHudTop==height-110)
  local buttons={}
  for _,n in ipairs(owner.tipLayer.children)do if n.item then table.insert(buttons,n) end end
  assert(#buttons==7,'expected return, cargo, guide and four steering buttons')
  for _,n in ipairs(buttons)do
    assert(n.position.x-n.size.width/2>=0 and n.position.x+n.size.width/2<=640)
    assert(n.position.y-n.size.height/2>=0 and n.position.y+n.size.height/2<=160)
  end
  owner.jointed={enable=true};owner.statue='ready';local seen=nil
  owner.jointedCalBack=function(_,d)seen=d end
  buttons[4].item.callback();assert(seen==UpDiriction)
  seen=nil;owner.statue='Triggering';buttons[5].item.callback();assert(not seen)
  owner.statue='ready';owner.eventManger={layer=node()};buttons[6].item.callback();assert(not seen)
  owner.eventManger.layer:setVisible(false);buttons[6].item.callback();assert(seen==RightDircion)
  owner:updataCapacityTips(48,60);assert(owner.capacityTips.text=='48/60')
  print('PASS HUD bounds, real data bindings and movement gates: 640x'..height)
end
for _,present in ipairs({true,false})do
  exists=present
  local owner=node()
  setmetatable(owner,{__index=function(_,key)return Explore[key] or methods[key]end})
  owner.map=node();owner.map.getTileSize=function()return {width=64,height=64}end
  owner.map.getMapSize=function()return {width=21,height=21}end
  owner.setViewpointCenter=function(_,p)owner.center=p end
  owner:initPlayer()
  assert(owner.player.position.x==800 and owner.player.position.y==800)
  if present then
    assert(owner.player.size.width==64 and owner.player.size.height==64)
    assert(math.abs(owner.adventureShipVisual.scale-0.675)<.0001)
  else assert(owner.player.path=='Images/Map/ship_1.png' and not owner.adventureShipVisual)end
  print('PASS saved tile position and '..(present and 'uniform transparent ship scaling' or 'missing-art fallback'))
end
