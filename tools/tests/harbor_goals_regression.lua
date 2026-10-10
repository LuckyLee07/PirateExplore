-- Source contracts and real shipped CSV. Does not simulate natural player input.
local root='bin/res/scripts/LuaClass/'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local function equal(a,b,why)assert(a==b,(why or 'value')..': '..tostring(a)..' ~= '..tostring(b))end
local source=read('tools/tests/home_master_regression.lua')
local start=assert(source:find('local function readFile(path)',1,true))
local stop=assert(source:find("\nlocal soldiers=packagedCSV('soilderAttribute')",start,true))
local packagedCSV=assert(loadstring('local equal=...\n'..source:sub(start,stop-1)..'\nreturn packagedCSV','@goals-real-csv'))(equal)
local resources,builds=packagedCSV('resourceInfo'),packagedCSV('build')
local function snapshot(t)
 local parts={};for k,v in pairs(t)do parts[#parts+1]=tostring(k)..'='..(type(v)=='table' and snapshot(v) or tostring(v))end
 table.sort(parts);return table.concat(parts,'|')
end
local fixtureStop=assert(source:find("\ndofile(root..'Header.lua')",1,true))
local H=assert(loadstring(source:sub(1,fixtureStop-1)..'\nreturn {node=node,methods=Node}','@goals-node-fixture'))()
dofile(root..'Header.lua')
local G=dofile(root..'HarborGoals.lua')
local data={[rolePackSize]=20,[roleAlchemyUnit]=1,[roleMoney]=3,[rolePack]={['1006']=5,['1007']=11,['1008']=3},
 [roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=0}},[roleMake]={}}
local dm={getRoleData=function(_,key)return data[key]end,getCSVByID=function(_,key)return key==csvOfResourceInfo and resources or builds end}
local baseline=snapshot({data,resources,builds})
equal(#G.list(dm,false),0,'no goals before first return')
local goals=G.list(dm,true);equal(#goals,2,'two real choices')
equal(goals[1].title,'货舱 20 → 30','real cargo target')
equal(goals[2].title,'炼金 1 → 2金币/次','real furnace target')
for _,g in ipairs(goals)do equal(g.route,'build');equal(g.routeId,'57');assert(g.detail:find('金币 22',1,true) and g.detail:find('石头 10',1,true),'real forge shortfall');assert(not g.detail:find('铁 2',1,true),'already owned iron not missing')end
equal(snapshot({data,resources,builds}),baseline,'read-only suggestions')
data[roleMake]={{[dataKeyID]='1148',[dataKeyNum]=-1},{[dataKeyID]='1176',[dataKeyNum]=-1}}
goals=G.list(dm,true);equal(goals[1].route,'make');equal(goals[1].detail,'还缺 布料 5');equal(goals[2].detail,'还缺 铁 2')
data[rolePack]['1018']=5;data[rolePack]['1008']=5
goals=G.list(dm,true);equal(goals[1].detail,'材料已备齐');equal(goals[2].detail,'材料已备齐')
data[rolePackSize]=30;goals=G.list(dm,true);equal(#goals,1);equal(goals[1].id,'1176')
data[roleAlchemyUnit]=2;equal(#G.list(dm,true),0,'completed goals disappear')
data[rolePackSize]=80;data[roleAlchemyUnit]=8;equal(#G.list(dm,true),0,'advanced saves never downgrade')
data[rolePackSize]=20;data[roleAlchemyUnit]=1;data[roleMake]={};data[roleBuilding]={}
goals=G.list(dm,true);equal(goals[1].route,nil,'locked forge is not a fake construction link')
-- The runtime parser supplies matrices; the decoder fixture supplies raw text.
local old=resources['1148'].raiseType;resources['1148'].raiseType={{'1','35'}}
equal(G.list(dm,true)[1].target,35,'effect comes from CSV rather than magic 30');resources['1148'].raiseType=old
equal(G.shortfall({resume={{'1001','5'},{'1007','3'}}},resources,{['1007']=1},2),'还缺 金币 3 · 木头 2','runtime matrix costs')
print('PASS harbor goals real CSV costs, prerequisite gates, shortages, completed/advanced saves and zero state writes')
-- Focus navigation does not reorder saved rows, manufacture, or purchase.
class=function()return {}end
BaseView={};dofile(root..'MakeMode.lua');dofile(root..'BuildMode.lua')
local rows={};for i=1,20 do rows[i]={[dataKeyID]=tostring(i)}end
local offsetCalls=0;local tableview={setContentOffset=function(_,p,animated)offsetCalls=offsetCalls+1;equal(animated,false);tableviewOffset=p.y end}
local make=setmetatable({workerData=rows,areaHeight=448,cellhight=112,tableview=tableview},{__index=MakeLayer})
local build=setmetatable({roleBuildingData=rows,areaHeight=448,cellhight=112,tableview=tableview},{__index=BuildLayer})
local before=snapshot(rows)
for _,page in ipairs({make,build})do
 equal(page:focusEntry(nil),false,'default entry unchanged');equal(page:focusEntry('missing'),false)
 assert(page:focusEntry('1'));equal(tableviewOffset,-1792,'first row top')
 assert(page:focusEntry('7'));equal(tableviewOffset,-1120,'middle row top')
 assert(page:focusEntry('20'));equal(tableviewOffset,0,'last row clamped')
end
equal(snapshot(rows),before,'focus cannot reorder saved lists')
equal(G.focusOffset(2,2,448,112),0,'short list has no overscroll')
print('PASS harbor target navigation selects original rows with clamped offsets and unchanged default routes')
-- Render the production Home and exercise its actual navigation callbacks.
local homeEnd=assert(source:find('\nfixture()\nlocal routes={}',1,true))
local F=assert(loadstring(source:sub(1,homeEnd-1)..[[
fixture()
return {data=data,dm=dm,csv=csv,node=node,tap=tap,snapshot=snapshot,viewport=viewport,
        guides=guideOverrides,packagedCSV=packagedCSV}
]],'@goals-home-fixture'))()
local rawTap=F.tap;F.tap=function(n)return rawTap(n,'goal click')end
F.csv[csvOfBuild]=F.packagedCSV('build')
F.data[rolePackSize]=20;F.data[roleAlchemyUnit]=1
F.data[roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=0}}
F.data[roleMake]={};F.data[rolePack]={['1007']=5,['1008']=3};F.data[roleMoney]=3
local scene=F.node('Scene');local created=0
AlertView={create=function()
 created=created+1;local d=F.node('Alert');d.s_size={width=572,height=437};d.s_bg=F.node('Background');d:addChild(d.s_bg);scene:addChild(d);return d
end}
local routes={}
zqDispatch={gotoBuild=function(_,id)routes[#routes+1]={'build',id}end,gotoMake=function(_,id)routes[#routes+1]={'make',id}end}
local before=F.snapshot(F.data)
local home=assert(HomeLayer:create());equal(home.hintLabel:getString(),'回港升级  ›')
F.tap(home.goalButton);equal(created,1);home:openGoals();equal(created,1,'repeated click cannot stack dialogs')
equal(#home.goalRows,2);assert(home.goalRows[1].detail:getString():find('需先建铁匠铺',1,true))
local dialog=home.goalDialog;dialog:removeFromParent(true);equal(home.goalDialog,nil,'close clears ownership')
equal(#routes,0,'dismiss has no navigation');equal(F.snapshot(F.data),before,'viewing and dismissal write nothing')
F.tap(home.goalButton);F.tap(home.goalRows[1].button);equal(routes[1][1],'build');equal(routes[1][2],'57');equal(home.goalDialog,nil)
F.data[roleMake]={{[dataKeyID]='1148',[dataKeyNum]=-1},{[dataKeyID]='1176',[dataKeyNum]=-1}}
F.dm:postEvent(roleMake);F.tap(home.goalButton);F.tap(home.goalRows[2].button)
equal(routes[2][1],'make');equal(routes[2][2],'1176','furnace opens the actual recipe')
F.tap(home.goalButton);F.data[rolePack]['1018']=5;F.dm:postEvent(rolePack)
equal(home.goalRows[1].detail:getString(),'材料已备齐','open preview updates with actual inventory')
F.data[rolePackSize]=30;F.dm:postEvent(rolePackSize);equal(home.goals[1].id,'1176');assert(not home.goalRows[2].holder:isVisible(),'completed choice removed live')
F.data[roleAlchemyUnit]=2;F.dm:postEvent(roleAlchemyUnit);equal(home.hintLabel:getString(),'补给已备妥');assert(not home.goalButton.item:isEnabled())
home:destory();equal(home.goalDialog,nil,'leaving Home dismisses its dialog');equal(#scene.children,0)
-- Same approved plaque dimensions at both supported viewport classes.
for _,size in ipairs({{width=480,height=800},{width=540,height=900}})do
 F.viewport.width=size.width;F.viewport.height=size.height
 local page=assert(HomeLayer:create());assert(math.abs(page.goalButton:getContentSize().width-308*size.width/941)<0.00001)
 assert(math.abs(page.goalButton:getContentSize().height-87*size.height/1672)<0.00001);page:destory()
end
print('PASS harbor Home opt-in dialog, live shortages, dismiss/reopen, prerequisite/recipe routes and original-size plaque')
