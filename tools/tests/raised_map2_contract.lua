-- Pure model contracts. No engine, gameplay singleton, profile or writes.
package.path='bin/res/scripts/?.lua;'..package.path
cc={p=function(x,y)return {x=x,y=y}end}
DataManager=setmetatable({},{__index=function()error('DataManager access forbidden')end})
ExploreDataManager=setmetatable({},{__index=function()error('save access forbidden')end})
local R=require('LuaClass/RaisedSeaMap2')
local function near(a,b)assert(math.abs(a-b)<1e-8,tostring(a)..' != '..tostring(b))end
local n=0
for y=0,30 do for x=0,30 do for _,z in ipairs({0,30})do
 local a,b=(x+.5)*64,(30-y+.5)*64;local p=R.project(a,b,z);local u,v=R.inverse(p.x,p.y,z);near(u,a);near(v,b);n=n+1
end end end
for _,h in ipairs({0,2147483648})do for _,v in ipairs({0,1073741824})do for _,d in ipairs({0,536870912})do
 for _,a in ipairs({.5,12.5,63.5})do for _,b in ipairs({.5,27.5,63.5})do
  local x,y=R.transform(a,b,h+v+d);local u,w=R.transform(x,y,h+v+d,true);near(u,a);near(w,b)
 end end
end end end
local gid=48;local meta={getTileGIDAt=function()return gid end}
local map={getMapSize=function()return {width=31,height=31}end,getLayer=function()return meta end,
 getPropertiesForGID=function()return {eventid='3053'}end}
local owner={map=map,meta=meta,mapLayoutManagers={data={}},eventManger={csvData={['3067']={name='quarry',eventFucString='gather'}}}}
local event=R.eventAt(owner,2,3);assert(event.id=='3053' and event.triggerId=='3053' and event.state==nil)
for _,state in ipairs({'00','10','11','-1'})do
 local record={id='3067',gid='48',statues=state};owner.mapLayoutManagers.data['95']=record
 event=R.eventAt(owner,2,3)
 assert(event.id=='3067' and event.triggerId=='3053' and event.gid==48 and event.layoutGid=='48' and event.state==state and event.callback=='gather')
 assert(owner.mapLayoutManagers.data['95']==record and record.statues==state)
end
gid=0;assert(R.eventAt(owner,2,3)==nil)
assert(select(2,R.build({map=map,mapIndex=1}))=='map2-only')
assert(select(2,R.build({map=map,mapIndex=16}))=='map2-only')
print('PASS raised projection '..n..' centers; all 8 flip inverses; overloaded GID48 identity/state; no save access; map1/16 fallback')
