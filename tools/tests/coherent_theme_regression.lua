-- Focused geometry/asset contract; actual pixels are independently inspected.
package.path='bin/res/scripts/?.lua;'..package.path
local polygons={}
cc={c3b=function(r,g,b)return{r=r,g=g,b=b}end,c4f=function(r,g,b,a)return{r=r,g=g,b=b,a=a}end,
 p=function(x,y)return{x=x,y=y}end,size=function(w,h)return{width=w,height=h}end}
local function node()return setmetatable({},{__index=function()return function()end end})end
cc.Node={create=node};cc.DrawNode={create=function()local n=node();n.drawPolygon=function(_,points,count)polygons[#polygons+1]={points=points,count=count}end;return n end}
package.loaded['LuaClass/MasterTheme']=true;MasterTheme={}
local W=require 'LuaClass/WarmTheme'
for _,radius in ipairs({0,8,20,28}) do
 W.panel(640,960,W.colors.paper,radius)
 local p=polygons[#polygons];local area=0
 for i=1,#p.points do local a,b=p.points[i],p.points[i%#p.points+1]
  assert(a.x~=b.x or a.y~=b.y,'consecutive duplicate polygon vertices cause native black panels')
  area=area+a.x*b.y-b.x*a.y
 end
 assert(area>0,'panel polygon must have counterclockwise positive area')
 if radius==0 then assert(p.count==4,'square panel uses exactly four distinct corners')end
end
assert(W.font=='fonts/CleanVoyageSans-Regular.ttf')
assert(W.colors.ink.r==38 and W.colors.sea.g==126 and W.colors.paper.r==255)
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local home=read('bin/res/scripts/LuaClass/WarmHome.lua')
assert(home:find('W.harborWorld',1,true));assert(not home:find('W.crewArt',1,true),'no giant actor layer over clean home world')
assert(not home:find('ship-home.png',1,true),'home uses voyage asset family')
local startup=read('bin/res/scripts/LuaClass/StartupTheme.lua')
assert(startup:find('local world=W.harborWorld',1,true),'bind first result before native addChild call')
print('PASS coherent panel geometry, palette/font, world reuse and no oversized actor layer')
