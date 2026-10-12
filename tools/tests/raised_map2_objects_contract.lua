-- Independent shipped CSV verification of semantic object IDs; no engine/saves.
package.path='bin/res/scripts/?.lua;'..package.path
local O=require('LuaClass/RaisedSeaObjectPresentation')
local file=assert(io.open('tools/tests/home_master_regression.lua'));local source=file:read('*a');file:close()
local a=assert(source:find('local function readFile',1,true));local b=assert(source:find('local soldiers=packagedCSV',a,true))
local decode=assert(loadstring('local equal=function(a,b)assert(a==b)end\n'..source:sub(a,b-1)..'\nreturn packagedCSV'))()
local data=decode('strongholdAttribute')
local covered,checks=0,0
for id,info in pairs(data)do
 local e={id=id,gid=tonumber(info.gid),callback=info.eventFucString,identitySource='live-layout',state='00'}
 local p=O.resolve(e)
 if p then
  covered=covered+1;assert(p.siteId==id and p.callback==info.eventFucString and p.gid==e.gid and p.state=='00')
  for _,state in ipairs({'00','10','11','-1'})do
   e.state=state;local originalGid=e.gid
   for _,gid in ipairs({10,32,45,46,47,48,49,50,51,52})do
    e.gid=gid;local q=assert(O.resolve(e));assert(q.family==p.family and q.siteId==id and q.state==state)
    assert(e.gid==gid and e.state==state and e.id==id);checks=checks+1
   end
   e.gid=originalGid
  end
  e.callback='unrelated';assert(O.resolve(e)==nil,'callback disagreement must not invent an object')
 end
end
assert(covered==36,'port/chart/revive, 16 pubs, 16 arenas and gateway')
local expected={['3001']='port',['3002']='world-chart',['3003']='resurrection',['3052']='gateway'}
for id,family in pairs(expected)do assert(O.resolve({id=id,gid=48}).family==family)end
for _,e in ipairs({{gid=51},{id='10',gid=51},{id='3053',gid=48},{id='3067',gid=48},{id='3074',gid=55},{id='-3052',gid=50},{id='3002.5',gid=46}})do
 assert(O.resolve(e)==nil,'unknown/overloaded/signed generic state must retain original drawing')
end
cc={p=function(x,y)return{x=x,y=y}end}
DataManager=setmetatable({},{__index=function()error('save access forbidden')end})
local R=require('LuaClass/RaisedSeaMap2')
local p=R.project(640,640);local east=R.project(704,640);local north=R.project(640,704)
assert(east.x>p.x and east.y<p.y and north.x>p.x and north.y>p.y,'cardinal projection altered')
print('PASS semantic objects: '..covered..' actual CSV IDs; '..checks..' GID/state independence cases; callback mismatch; ambiguous fallback; cardinal directions; no save access')
