package.path='bin/res/scripts/?.lua;'..package.path
local V=require 'LuaClass/CleanVoyageView'
for _,u in ipairs({.5,1,1.5,2}) do
 for x=-21,21 do for y=-21,21 do
  local p=V.project(x,y,u);local xx,yy=V.unproject(p.x,p.y,u)
  assert(math.abs(xx-x)<.00001 and math.abs(yy-y)<.00001)
 end end
end
assert(V.heading(1,0)=='se' and V.heading(-1,0)=='nw' and V.heading(0,1)=='sw' and V.heading(0,-1)=='ne')
local owner={map={getMapSize=function()return {width=21,height=21}end},fogManager={data={['220']=0,['221']=1,['222']='0'}}}
assert(V.isKnown(owner,10,10));assert(not V.isKnown(owner,11,10));assert(V.isKnown(owner,12,10));assert(not V.isKnown(owner,13,10));assert(not V.isKnown(owner,-1,0));assert(not V.isKnown(owner,21,20))
RightDircion=1;LeftDirction=2;BottomDirction=3;UpDiriction=4
owner.cleanVoyageView={u=1,cx=0,cy=0};owner.statue='ready';local calls={};function owner:jointedCalBack(d)calls[#calls+1]=d end
for i,p in ipairs({{1,0},{-1,0},{0,1},{0,-1}})do assert(V.touch(owner,V.project(p[1],p[2],1)));assert(calls[#calls]==i)end
owner.cleanVoyageView.animating=true;assert(not V.touch(owner,V.project(1,0,1)));assert(#calls==4)
owner.cleanVoyageView.animating=false;owner.adventureDialog={};assert(not V.touch(owner,V.project(1,0,1)));assert(#calls==4)
owner.adventureDialog=nil;owner.warmPause={};assert(not V.touch(owner,V.project(1,0,1)));assert(#calls==4)
owner.warmPause=nil;owner.statue='Triggering';assert(not V.touch(owner,V.project(1,0,1)));assert(#calls==4)
owner.statue='ready';assert(not V.touch(owner,{x=0,y=0}));assert(#calls==4)
print('PASS clean view projection, exact fog truth, four headings, production callback, input guards')
local port=require('LuaClass/CleanFirstMap').port();local logical=V.project(port.x,port.y,1);local berth=V.shipPoint(port,1)
assert(berth.x==logical.x+10 and berth.y==logical.y+30,'cosmetic berth only')
local elsewhere={x=port.x,y=port.y-1};local regular=V.shipPoint(elsewhere,1);local actual=V.project(elsewhere.x,elsewhere.y,1)
assert(regular.x==actual.x and regular.y==actual.y)
for _,u in ipairs({.5,1,1.5,2}) do
 for _,tile in ipairs({port,elsewhere}) do
  local count=0;local direction
  local o={statue='ready',playerTitlePosition=tile,cleanVoyageView={u=u,cx=173*u,cy=419*u},
   jointedCalBack=function(_,d)count=count+1;direction=d end}
  local center=V.project(tile.x,tile.y,u);local contact=V.shipPoint(tile,u)
  local visible={x=o.cleanVoyageView.cx+contact.x-center.x,y=o.cleanVoyageView.cy+contact.y-center.y}
  assert(not V.touch(o,visible) and count==0,'visible boat contact stays inert, including offset berth')
  assert(not V.touch(o,{x=o.cleanVoyageView.cx,y=o.cleanVoyageView.cy}) and count==0,'logical tile center stays inert')
  for i,p in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
   local q=V.project(p[1],p[2],u)
   assert(V.touch(o,{x=o.cleanVoyageView.cx+q.x,y=o.cleanVoyageView.cy+q.y}))
   assert(count==i and direction==i,'adjacent logical tile keeps original cardinal direction')
  end
 end
end
print('PASS visible berth contact is inert and all four adjacent logical tiles retain exact cardinal picking at four scales')
local file=assert(io.open('bin/res/scripts/LuaClass/Explore.lua'));local source=file:read('*a');file:close()
local prefix=assert(source:match('(local function onTouchesBegan.-)\nlocal function onTouchesMoved'))
local began=assert(loadstring('local AdventureSea={isHudPoint=function()error("hidden legacy HUD must not receive clean hit tests")end}\n'..prefix..'\nreturn onTouchesBegan'))()
screenSize={width=640,height=1200}
owner.adventureObjectiveItem={};owner.adventureHudTop=1076;owner.adventureHudBottom=222
function owner:convertToNodeSpace(p)return p end
local function touch(x,y)return {getLocation=function()return {x=x,y=y}end}end
assert(began(owner,touch(320,340)),'sea in old objective-strip band remains clickable')
assert(began(owner,touch(320,190)),'sea above compact footer remains clickable')
assert(not began(owner,touch(320,120)),'new goal strip reserved')
assert(not began(owner,touch(320,1150)),'new top controls reserved')
owner.adventureDialog={};assert(not began(owner,touch(320,340)))
print('PASS exact cosmetic berth offset and real Explore clean-first HUD hit-test ordering')

local visibility=true;owner.tipLayer={setVisible=function(_,v)visibility=v end}
V.keepLegacyHudHidden(owner);assert(visibility==false,'event unfreeze cannot resurrect legacy HUD')
owner.cleanVoyageView=nil;visibility=true;V.keepLegacyHudHidden(owner);assert(visibility==true,'legacy view untouched')
print('PASS original event-unfreeze HUD visibility isolation')
