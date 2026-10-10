package.path='bin/res/scripts/?.lua;'..package.path
local K=require 'LuaClass/KnownRoute'
local N=require 'LuaClass/AdventureNavigation'
local V=require 'LuaClass/AdventureNavigationView'
local function eq(a,b,why)assert(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function graph(w,h)
    local g={width=w,height=h,cells={}}
    for y=0,h-1 do for x=0,w-1 do g.cells[K.key({x=x,y=y},w)]={known=true,costed=true} end end
    return g
end
local g=graph(5,5)
for y=0,3 do g.cells[K.key({x=2,y=y},5)].blocked=true end
local a,b={x=0,y=0},{x=4,y=0}
local r=K.find(g,a,b,{})
eq(r.status,'ok');eq(r.steps,12,'routes around island, not Manhattan four');eq(r.minimumFood,12)
eq(r.direction,'东')
for i=2,#r.path do local p,q=r.path[i-1],r.path[i];eq(math.abs(p.x-q.x)+math.abs(p.y-q.y),1)end
g.cells['22'].known=false
eq(K.find(g,a,b,{}).status,'no_known_route','unknown chokepoint cannot be crossed')
g.cells['22'].known=true;g.cells['22'].event=true
eq(K.find(g,a,b,{}).status,'no_known_route','active event is not a transit shortcut')
g.cells['22'].event=false
for _,p in ipairs({{x=-1,y=0},{x=5,y=0},{x=0,y=-1},{x=0,y=5}}) do eq(K.find(g,a,p,{}).status,'out_of_bounds')end
for _,p in ipairs({{x=0,y=0},{x=4,y=0},{x=0,y=4},{x=4,y=4}}) do eq(K.find(g,p,p,{}).status,'at_port')end
local line=graph(5,1);line.cells['4'].event=true;line.cells['4'].costed=false
r=K.find(line,{x=0,y=0},{x=4,y=0},{breadCoefficient=.25,breadCostDecimal=.5,food=1})
eq(r.steps,4);eq(r.costCalls,3);eq(r.minimumFood,2);eq(r.foodShortfall,1)
-- Exact floating arithmetic: deliberately no epsilon/ceil shortcuts.
for _,coefficient in ipairs({0,.1,.2,.25,.5,1}) do for _,decimal in ipairs({0,.3,.9,2.5}) do
    local debt,spent=decimal,0
    for calls=1,20 do
        debt=debt+(1-coefficient)
        if debt>=1 then debt=debt-1;spent=spent+1 end
        local estimate,remainder=K.foodCost(calls,coefficient,decimal)
        eq(estimate,spent,'talent/debt debit exact');eq(remainder,debt)
    end
end end
r=K.find(line,{x=0,y=0},{x=4,y=0},{food=0})
eq(r.minimumFood,3);eq(r.foodShortfall,3,'zero food is not free travel')
local before=line.cells['0'].known
K.find(line,{x=0,y=0},{x=4,y=0},{})
eq(line.cells['0'].known,before,'query has no fog writes')
-- Adapter uses live TMX layers and live fog. Every mutation API would fail.
local raw=graph(5,3);local properties={ [9]={obstacle=1}, [8]={eventid='42'},[7]={} }
local layers={Blocks_1={},Blocks_2={},Meta={}}
for _,layer in pairs(layers) do function layer:getTileGIDAt(p)return self[K.key(p,5)] or 0 end end
local map={getMapSize=function()return {width=5,height=3}end,
    getLayer=function(_,name)return layers[name]end,
    getPropertiesForGID=function(_,gid)return properties[gid]end,
    getObjectGroup=function()return {getObject=function()return {x=0,y=0}end}end}
local food=10
local owner={map=map,meta=layers.Meta,playerTitlePosition={x=4,y=0},
    breadNum=10,breadCostDecimal=.5,
    tileCoordForPosition=function(_,p)return {x=p.x,y=p.y}end,
    fogManager={data={}},bagController={getBreads=function()return food end},
    mapLayoutManagers={data={['12']={id='400'}}},
    eventManger={csvData={['400']={name='传送点'}}}}
for key in pairs(raw.cells) do owner.fogManager.data[key]='0' end
layers.Blocks_1['2']=9;layers.Blocks_2['7']=9
r=N.query(owner,{breadCoefficient=.25});eq(r.steps,8);eq(r.minimumFood,6)
local clue=N.gateClue(owner);eq(clue.direction,'西南');eq(clue.target.x,2);eq(clue.target.y,2)
owner.mapLayoutManagers.data['13']={id='400'};eq(N.gateClue(owner).status,'ambiguous_gate');owner.mapLayoutManagers.data['13']=nil
local point=N.tutorialPoint(owner);assert(point and point.steps>=2 and point.minFood<=8)
eq(layers.Meta[K.key(point,5)],nil,'tutorial point does not paint events')
owner.fogManager.data['1']='3';owner.fogManager.data['5']=nil
assert(N.tutorialPoint(owner),'generation may validate actual unknown terrain without revealing it')
eq(owner.fogManager.data['1'],'3','generation never reveals partial fog')
eq(owner.fogManager.data['5'],nil,'generation never reveals unknown fog')
eq(N.query(owner,{}).status,'no_known_route')
owner.fogManager.data['1']='0';owner.fogManager.data['5']='0'
food=5;owner.breadNum=0;owner.breadCostDecimal=2.9
r=N.query(owner,{breadCoefficient=.5});eq(r.minimumFood,4,'refilled food resets hunger debt')
-- Text is explicit about uncertainty, no-route, and no auto-return.
assert(V.lines({status='no_known_route'}):find('暂无已知'))
local title,detail=V.lines({status='ok',direction='北',steps=4,minimumFood=3,foodShortfall=1})
assert(title:find('4步') and detail:find('非安全保证') and detail:find('不足'))
print('known_route_regression: PASS')
-- Supply clues join real layout IDs to material-event CSV and positive drops.
owner.mapLayoutManagers.data={['6']={id='3068'},['10']={id='3067'},['14']={id='3070'}}
owner.eventManger.csvData={
 ['3068']={name='铁矿',eventFucString='changeToMaterialsLayer',dropitems={{'1008','5'}}},
 ['3067']={name='石矿',eventFucString='changeToMaterialsLayer',dropitems={{'1006','5'}}},
 ['3070']={name='伐木场',eventFucString='changeToMaterialsLayer',dropitems={{'1007','5'}}}}
layers.Meta['6']=8;layers.Meta['10']=8;layers.Meta['14']=8
owner.fogManager.data['14']=nil -- Hidden closer wood is never disclosed.
local supply=N.supplyClue(owner)
eq(supply.status,'ok');eq(supply.id,'3068');eq(supply.materialId,'1008');eq(supply.name,'铁矿')
eq(supply.target.x,1);eq(supply.target.y,1);eq(supply.direction,'西南')
assert(supply.text:find('另需成本'))
owner.fogManager.data['6']='3';owner.fogManager.data['10']=nil
supply=N.supplyClue(owner);eq(supply.status,'not_found');eq(supply.target,nil,'unknown target coordinate never exposed')
owner.fogManager.data['14']='0';owner.eventManger.csvData['3070'].dropitems={{'0'}}
eq(N.supplyClue(owner).status,'not_found','no fictional yield for empty drop table')
owner.eventManger.csvData['3070'].dropitems={{'1007','5'}}
layers.Blocks_2['14']=9
eq(N.supplyClue(owner).status,'not_found','blocked material target not recommended')
layers.Blocks_2['14']=nil;layers.Meta['14']=0
eq(N.supplyClue(owner).status,'not_found','consumed/non-event tile not recommended')
print('supply_clue_regression: PASS')
