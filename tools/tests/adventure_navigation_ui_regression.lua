package.path='bin/res/scripts/?.lua;'..package.path
local methods={}
local function node()return setmetatable({children={},scale=1},{__index=methods})end
function methods:addChild(n,z)self.children[#self.children+1]=n;n.parent=self;n.z=z end
function methods:setContentSize(s)self.size=s end
function methods:getContentSize()return self.size end
function methods:setPosition(p)self.position=p end
function methods:setString(s)self.text=s end
function methods:removeFromParent()
    if self.parent then for i,n in ipairs(self.parent.children)do if n==self then table.remove(self.parent.children,i);break end end end
    self.parent=nil
end
function methods:drawSegment(a,b,r,color)self.segments=self.segments or {};self.segments[#self.segments+1]={a=a,b=b,r=r}end
cc={Node={create=node},DrawNode={create=node},size=function(w,h)return {width=w,height=h}end,
    p=function(x,y)return {x=x,y=y}end,c4f=function(...)return {...}end}
SeaChartTheme={colors={ink={},white={}},panel=function(w,h)local n=node();n.size=cc.size(w,h);return n end,
    label=function(text,size,color,x,y)local n=node();n.text=text;n.fontSize=size;n.position=cc.p(x,y);return n end,
    fit=function(n,width)n.maxWidth=width end}
local V=require 'LuaClass/AdventureNavigationView'
for _,size in ipairs({{width=480,height=800},{width=540,height=900}}) do
    screenSize=size
    local u=size.width/640
    local owner={tipLayer=node(),moveLayer=node(),adventureHudBottom=222*u,
        positionForTilePosition=function(_,p)return cc.p(p.x*32+16,320-p.y*32-16)end}
    local result={status='ok',direction='北',steps=2,minimumFood=1,foodShortfall=0,
        path={{x=1,y=2},{x=1,y=1},{x=1,y=0}},nextStep={x=1,y=1},port={x=1,y=0}}
    local view=V.refresh(owner,result)
    assert(view.position.y>=owner.adventureHudBottom,'navigation does not overlap bottom controls')
    assert(view.position.y+view.size.height<size.height-124*u,'navigation does not overlap top HUD')
    assert(view.position.x+view.size.width<size.width,'right edge remains visible')
    assert(view.title.fontSize>=16 and view.detail.fontSize>=12,'phone text remains legible')
    assert(view.title.maxWidth==size.width-48*u)
    assert(#owner.tipLayer.children==1 and #owner.moveLayer.children==1)
    local overlay=owner.adventureRouteOverlay
    assert(#overlay.children[1].segments==2,'draw actual path edges')
    assert(overlay.children[2].text=='港' and overlay.children[3].text=='下一步')
    V.refresh(owner,{status='no_known_route'})
    assert(#owner.tipLayer.children==1,'reuse HUD rather than duplicate it')
    assert(#owner.moveLayer.children==0 and owner.adventureRouteOverlay==nil,'remove stale route when fog/block changed')
    assert(view.title.text=='暂无已知返港路线')
    V.refresh(owner,result)
    assert(#owner.moveLayer.children==1,'refresh exactly one route')
end
print('adventure_navigation_ui_regression: PASS (480x800 / 540x900)')

-- Execute the real chapter-rebuild prefix, with Cocos-like released-node errors.
-- The tipLayer survives while removeAllChildren destroys moveLayer children.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local S=require 'LuaClass/AdventureSea'
local source=read('bin/res/scripts/LuaClass/Explore.lua')
local prefix=assert(source:match('(function Explore:initMapByMapIndex.-)\n\tself.halos = {}'))
Explore={};assert(loadstring('local AdventureSea=...\n'..prefix..'\nend'))(S)
local oldRemove=methods.removeFromParent
local function release(n)
    for _,child in ipairs(n.children)do release(child)end
    n.released=true
end
function methods:removeFromParent()
    assert(not self.released,'invalid cobj: released child reused')
    oldRemove(self);release(self)
end
function methods:removeAllChildren()
    for _,child in ipairs(self.children)do release(child);child.parent=nil end
    self.children={}
end
local owner={tipLayer=node(),moveLayer=node(),positionForTilePosition=function(_,p)return p end,
    clearMapInfoData=function(self)self.mapDataCleared=true end}
local result={status='ok',direction='北',steps=1,minimumFood=0,path={{x=1,y=1},{x=1,y=0}},port={x=1,y=0}}
local hud=V.refresh(owner,result)
local firstRoute=owner.adventureRouteOverlay
owner.adventureWreckMarker=node();owner.moveLayer:addChild(owner.adventureWreckMarker)
local firstMarker=owner.adventureWreckMarker
Explore.initMapByMapIndex(owner,2)
assert(owner.mapDataCleared and firstRoute.released and firstMarker.released)
assert(owner.adventureRouteOverlay==nil and owner.adventureWreckMarker==nil,'both map-owned Lua references cleared before native release')
assert(owner.adventureNavigationView==hud and not hud.released,'persistent tipLayer HUD is retained')
V.refresh(owner,result)
assert(owner.adventureRouteOverlay~=firstRoute and #owner.moveLayer.children==1,'new chapter owns a fresh route')
Explore.initMapByMapIndex(owner,1)
V.refresh(owner,result)
assert(#owner.moveLayer.children==1,'repeated chapter transitions do not accumulate or reuse released overlays')
local same=owner.adventureRouteOverlay
Explore.initMapByMapIndex(owner,1,false)
assert(owner.adventureRouteOverlay==same and not same.released,'initial non-clearing map load preserves live nodes')
print('PASS real chapter rebuild clears released map decorations while preserving HUD; repeat and non-clearing lifecycle')
