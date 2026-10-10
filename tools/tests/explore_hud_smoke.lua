-- Runtime-independent smoke tests of the live sea-chart UI and texture adapter.
local methods={}
local function node(w,h) return setmetatable({size={width=w or 0,height=h or 0},children={},visible=true,scale=1}, {__index=methods}) end
function methods:setContentSize(s) self.size=s end
function methods:getContentSize() return self.size end
function methods:setPosition(p) self.position=p end
function methods:setAnchorPoint(p) self.anchor=p end
function methods:ignoreAnchorPointForPosition(v) end
function methods:setCascadeOpacityEnabled(v) end
function methods:setColor(v) self.color=v end
function methods:setOpacity(v) self.opacity=v end
function methods:addChild(c,z) table.insert(self.children,c);c.parent=self;c.z=z or 0 end
function methods:setScale(v) self.scale=v end
function methods:setScaleX(v) self.scaleX=v end
function methods:setScaleY(v) self.scaleY=v end
function methods:setRotation(v) self.rotation=v end
function methods:registerScriptTapHandler(f) self.callback=f end
function methods:runAction(v) self.action=v end
function methods:setVisible(v) self.visible=v end
function methods:isVisible() return self.visible end
function methods:drawTriangle(...) assert(select('#',...)==4,'legacy DrawNode triangle signature') end
function methods:drawSegment(...) end
function methods:drawPolygon(...) end
function methods:setString(s) self.text=s;self.size.width=#s*(self.fontSize or 1)*.4 end
function methods:setFontName(s) self.font=s end
cc={}
cc.p=function(x,y) return {x=x,y=y} end
cc.size=function(w,h) return {width=w,height=h} end
cc.rect=function(x,y,w,h) return {x=x,y=y,width=w,height=h} end
cc.c3b=function(r,g,b) return {r=r,g=g,b=b} end
cc.c4b=function(r,g,b,a) return {r=r,g=g,b=b,a=a} end
cc.c4f=cc.c4b
cc.Layer={create=function()return node()end};cc.Node=cc.Layer;cc.DrawNode=cc.Layer
cc.LayerColor={create=function(_,color,w,h)local n=node(w,h);n.color=color;return n end}
cc.LabelTTF={create=function(_,text,font,size)local n=node(#text*size*.4,size);n.text=text;n.fontSize=size;return n end}
cc.MenuItemSprite={create=function(_,normal,selected)local n=node(normal.size.width,normal.size.height);return n end}
cc.Menu={create=function(_,item)local n=node();n:addChild(item);return n end}
cc.FadeOut={create=function()return {}end}
cc.Sprite={create=function(_,path,rect)local n=node(rect and rect.width or (path and 128 or 0),rect and rect.height or (path and 128 or 0));n.path=path;return n end}
local exists=true
cc.FileUtils={getInstance=function()return {isFileExist=function()return exists end}end}
function class(name,ctor) return {} end
dofile('bin/res/scripts/LuaClass/SeaChartWorldTheme.lua')
require=function(name) if name=='LuaClass/SeaChartWorldTheme' then return SeaChartWorldTheme end return true end
BoldFont='font';roleExtents=1;roleMapInfo=2;roleShipId=3
UpDiriction=10;LeftDirction=1;RightDircion=2;BottomDirction=20
local roleData={[1]=129,[2]={playerTitlePosition={x=12,y=8}},[3]=1158}
DataManager={getInstance=function()return {getRoleData=function(_,id)return roleData[id]end}end}
dataController={getResourceValueByIdAndKey=function()return 1 end}
Jointed={create=function(_,player,cb)return {enable=true,moveActed=cb}end}
dofile('bin/res/scripts/LuaClass/HomeTheme.lua')
dofile('bin/res/scripts/LuaClass/MasterTheme.lua')
dofile('bin/res/scripts/LuaClass/SeaChartTheme.lua')
dofile('bin/res/scripts/LuaClass/Explore.lua')
for _,height in ipairs({853,960,1136}) do
  screenSize={width=640,height=height}
  local owner=node()
  setmetatable(owner,{__index=function(_,key)return Explore[key] or methods[key]end})
  owner.bagController={costSpace=43,limited=60,getBreads=function()return 36 end}
  owner:initTipLayer()
  assert(owner.bread.text=='36' and owner.capacityTips.text=='43/60')
  assert(owner.occupationNum.text=='129' and owner.extentTip.text=='0%')
  assert(owner.adventureHudBottom==222 and owner.adventureHudTop==height-124)
  local buttons={}
  for _,n in ipairs(owner.tipLayer.children)do if n.item then table.insert(buttons,n) end end
  assert(#buttons==7,'expected return, cargo, guide and four steering buttons')
  for _,n in ipairs(buttons)do
    assert(n.position.x-n.size.width/2>=0 and n.position.x+n.size.width/2<=640)
    assert(n.position.y-n.size.height/2>=0 and n.position.y+n.size.height/2<=222)
  end
  owner.jointed={enable=true};owner.statue='ready';local seen=nil
  owner.jointedCalBack=function(_,d)seen=d end
  buttons[4].item.callback();assert(seen==UpDiriction)
  seen=nil;owner.statue='Triggering';buttons[5].item.callback();assert(not seen)
  owner.statue='ready';owner.eventManger={layer=node()};buttons[6].item.callback();assert(not seen)
  owner.eventManger.layer:setVisible(false);buttons[6].item.callback();assert(seen==RightDircion)
  owner:updataCapacityTips(480,600);assert(owner.capacityTips.text=='480/600')
  assert(owner.capacityTips.size.width*owner.capacityTips.scale<=78,'large cargo count stays within HUD')
  owner:updataCapacityTips(48,60);assert(owner.capacityTips.text=='48/60')
  local fogCount=207
  ExploreDataManager={getInstance=function()return {getFogs=function()return fogCount end}end}
  owner.map={getMapSize=function()return {width=21,height=21}end}
  owner:updataExtent(false)
  assert(owner.extent==46 and owner.extentTip.text=='46%' and owner.adventureExtentBar.scaleX==.46,
    'percentage is computed from the actual revealed tile count')
  fogCount=441;owner:updataExtent(false)
  assert(owner.extent==100 and owner.adventureExtentBar.scaleX==1)
  print('PASS HUD bounds, real data bindings and movement gates: 640x'..height)
end

-- Texture identity, rect dimensions and original TMX data are independent:
-- valid same-size art may replace rendering; absent/malformed art must fall back.
local function texture(w,h)
  return {getPixelsWide=function()return w end,getPixelsHigh=function()return h end,
    setAliasTexParameters=function(self)self.nearest=true end}
end
local originals={['dt_ludi.png']=texture(384,384),['t_00.png']=texture(512,384),
  ['dt_zhanzmw.png']=texture(384,192),['grid.png']=texture(64,64)}
local art={['dt_ludi.png']=texture(384,384),['t_00.png']=texture(256,384),
  ['grid.png']=texture(64,64)}
local cache={getTextureForKey=function(_,path)return originals[path:match('[^/]+$')]end,
  addImage=function(_,path)return art[path:match('[^/]+$')]end}
cc.FileUtils={getInstance=function()return {isFileExist=function(_,path)return art[path:match('[^/]+$')]~=nil end}end}
cc.Director={getInstance=function()return {getTextureCache=function()return cache end}end}
local layers={}
for _,info in ipairs({{'Sea','dt_ludi.png'},{'Blocks_1','dt_ludi.png'},
  {'Meta','t_00.png'},{'Fogs','dt_zhanzmw.png'},{'GridLayer','grid.png'}})do
  local layer={texture=originals[info[2]],gids={89,0,67,47,11},tileSize=64}
  layer.getTexture=function(self)return self.texture end
  layer.setTexture=function(self,value)self.texture=value end
  layer.setTileGID=function()error('theme must never change GID data')end
  layers[info[1]]=layer
end
local map={getLayer=function(_,name)return layers[name]end}
local applied=SeaChartTheme.applyTileArt(map)
assert(applied.Sea=='dt_ludi.png' and applied.Blocks_1=='dt_ludi.png' and applied.GridLayer=='grid.png')
assert(layers.Sea.texture==art['dt_ludi.png'] and layers.Blocks_1.texture==art['dt_ludi.png'])
assert(art['dt_ludi.png'].nearest and art['grid.png'].nearest,
  'replacement TMX atlases must preserve native nearest sampling instead of bleeding adjacent frames')
assert(not art['t_00.png'].nearest,'invalid-size fallback must not alter replacement sampling')
assert(not originals['dt_ludi.png'].nearest and not originals['dt_zhanzmw.png'].nearest,
  'the adapter changes only validated replacement atlases, not other cached textures')
assert(layers.Meta.texture==originals['t_00.png'],'wrong atlas dimensions must preserve event art')
assert(layers.Fogs.texture==originals['dt_zhanzmw.png'],'missing fog art must preserve original fog')
for _,layer in pairs(layers)do assert(layer.gids[1]==89 and layer.gids[4]==47 and layer.tileSize==64)end
print('PASS same-size atlas replacement, event/fog fallbacks and unchanged tile semantics')
cc.FileUtils={getInstance=function()return {isFileExist=function()return exists end}end}
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
    assert(math.abs(owner.adventureShipVisual.scale-0.875)<.0001)
  else assert(owner.player.path=='Images/Map/ship_1.png' and not owner.adventureShipVisual)end
  print('PASS saved tile position and '..(present and 'uniform transparent ship scaling' or 'missing-art fallback'))
end

local fogOriginal=texture(384,192)
local shader, compileOk, linkOk = nil, true, true
cc.GLProgram={new=function()
  shader={attributes={}}
  shader.initWithByteArrays=function(self,vertex,fragment)
    self.vertex=vertex;self.fragment=fragment;return compileOk
  end
  shader.bindAttribLocation=function(self,name,index)self.attributes[name]=index end
  shader.link=function()return linkOk end
  shader.updateUniforms=function(self)self.updated=true end
  return shader
end}
local fogLayer={texture=fogOriginal,
  setTexture=function()error('fog tint must preserve original texture and UVs')end,
  setShaderProgram=function(self,value)self.shader=value end,
  setBlendFunc=function(self,src,dst)assert(type(src)=="number" and type(dst)=="number");self.blend={src=src,dst=dst} end}
assert(SeaChartTheme.tintFog(nil,fogLayer))
assert(fogLayer.texture==fogOriginal and fogLayer.shader==shader and shader.updated)
assert(shader.attributes.a_position==0 and shader.attributes.a_color==1 and shader.attributes.a_texCoord==2)
assert(shader.fragment:find('texture2D%(CC_Texture0, v_texCoord%)%.a %* v_fragmentColor%.a'))
assert(fogLayer.blend.src==1 and fogLayer.blend.dst==771,'alpha-preserving premultiplied blend')
local previous=fogLayer.shader
compileOk=false;assert(not SeaChartTheme.tintFog(nil,fogLayer) and fogLayer.shader==previous)
compileOk=true;linkOk=false;assert(not SeaChartTheme.tintFog(nil,fogLayer) and fogLayer.shader==previous)
print('PASS native fog alpha-only shader, original atlas/UVs, blend contract and compile/link fallback')
compileOk=true;linkOk=true
local gridLayer={setShaderProgram=function(self,value)self.shader=value end,
  setBlendFunc=function(self,src,dst)assert(type(src)=="number" and type(dst)=="number");self.blend={src=src,dst=dst} end}
assert(SeaChartTheme.softenGrid({getLayer=function(_,name)if name=='GridLayer'then return gridLayer end end}))
assert(gridLayer.shader.fragment==SeaChartTheme.gridFragmentShader and gridLayer.blend.src==1)
print('PASS subtle grid shader stays isolated to the original GridLayer')
gridLayer.getTexture=function()return {hasPremultipliedAlpha=function()return true end}end
assert(SeaChartTheme.softenGrid({getLayer=function()return gridLayer end}))
assert(gridLayer.shader.fragment=='#define GRID_TEXTURE_PREMULTIPLIED\n'..SeaChartTheme.gridFragmentShader)
print('PASS grid shader follows the native texture alpha convention')

-- All-map materials, original mask/flip safety and scenery are exercised by
-- sea_chart_world_regression.lua against all sixteen decoded TMX fixtures.
