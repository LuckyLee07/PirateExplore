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
-- Sources use actual packaged market/worker/build data, never the generic obtain
-- text ("go to sea") or a price field as an unlock guarantee.
local store,workers=packagedCSV('store'),packagedCSV('worker')
for _,id in ipairs({'1018','1008'})do
 equal(resources[id].limits,'-1','early materials are unlimited market goods')
 equal(resources[id].onlyProduce,'0','early materials are not production-only')
 equal(resources[id].diamond,'','early materials have no diamond price')
end
local allCsv={[csvOfResourceInfo]=resources,[csvOfBuild]=builds,[csvOfStore]=store,[csvOfWorker]=workers}
dm.getCSVByID=function(_,key)return allCsv[key] or {}end
local gates={[60]=true,[104]=true,[2]=true}
local guide={getIsHaveStep=function(_,step,flag)if step==104 then equal(flag,true,'market guide namespace')end;return gates[step]end}
data[roleMake]={{[dataKeyID]='1148',[dataKeyNum]=-1},{[dataKeyID]='1176',[dataKeyNum]=-1}}
data[rolePack]={['1007']=5};data[roleStore]={{[dataKeyID]='1018',sortId='4'},{[dataKeyID]='1008',sortId='6'}}
data[roleProducerQueue]={};data[roleBuilding]={}
local before=snapshot({data,allCsv})
local sources=G.sources(dm,guide,'1148');equal(#sources,1);equal(sources[1].id,'1018');equal(sources[1].route,'store')
equal(sources[1].detail,'市场 2金币/个；补齐需 10金币','actual cloth cost')
sources=G.sources(dm,guide,'1176');equal(sources[1].detail,'市场 3金币/个；补齐需 15金币','actual iron cost')
equal(snapshot({data,allCsv}),before,'reading sources spends and writes nothing')
gates[104]=false;sources=G.sources(dm,guide,'1148');equal(sources[1].route,nil);assert(sources[1].detail:find('市场尚未开放',1,true))
gates[104]=true;data[roleStore][1].sortId='6';equal(G.sources(dm,guide,'1148')[1].route,nil,'mismatched offer cannot navigate')
data[roleStore]={};equal(G.sources(dm,guide,'1176')[1].route,nil,'price alone is not a market offer')
data[roleProducerQueue]={{[dataKeyID]='5',[dataKeyNum]=0}}
equal(G.sources(dm,guide,'1176')[1].route,nil,'worker alone cannot promise an unbuilt mine')
data[roleBuilding]={{[dataKeyID]='61',[dataKeyNum]=1}}
sources=G.sources(dm,guide,'1176');equal(sources[1].route,'resource');assert(sources[1].detail:find('铁矿已建',1,true));assert(sources[1].detail:find('食物-2',1,true));assert(sources[1].detail:find('0人',1,true))
equal(G.sources(dm,guide,'1148')[1].route,nil,'no invented cloth production')
local old=resources['1148'].resume;resources['1148'].resume={{'999999','2'}}
sources=G.sources(dm,guide,'1148');equal(sources[1].route,nil);equal(sources[1].detail,'暂未找到已解锁的获取途径','unknown source is honest');resources['1148'].resume=old
data[roleMake]={};data[roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=0}};data[roleMoney]=0
sources=G.sources(dm,guide,'1148');equal(#sources,3);equal(sources[1].route,'alchemy');equal(sources[2].route,'resource');equal(sources[2].detail,'资源页手动采集，冷却结束后可再次采集','gather source explains player action rather than implementation history')
gates[60]=false;equal(#G.sources(dm,guide,'1148'),0,'no pre-return source bypass');gates[60]=true
print('PASS material source exact CSV prices, market/worker/building gates, forge ingredients and unknown sources')
-- Store optional focus preserves data and the existing bottom-entry argument.
dofile(root..'StoreMode.lua')
local market=setmetatable({roleStoreData=rows,areaHeight=448,cellhight=112,tableview=tableview},{__index=StoreLayer})
equal(market:focusEntry(nil),false);equal(market:focusEntry('missing'),false)
assert(market:focusEntry('7'));equal(tableviewOffset,-1120);assert(market:focusEntry('20'));equal(tableviewOffset,0)
local dispatch=read(root..'Dispatch.lua');assert(dispatch:find('StoreLayer:create(bIsMoveToBottom, focusResourceId)',1,true))
-- Production Home callbacks: opt-in swap/back/close, current state at click,
-- live route changes and no material purchase, crafting or guide reward.
F.csv[csvOfStore]=store;F.csv[csvOfWorker]=workers
F.data[rolePackSize]=20;F.data[roleAlchemyUnit]=1;F.data[rolePack]={['1007']=5};F.data[roleMoney]=0
F.data[roleMake]={{[dataKeyID]='1148',[dataKeyNum]=-1},{[dataKeyID]='1176',[dataKeyNum]=-1}}
F.data[roleStore]={{[dataKeyID]='1018',sortId='4'},{[dataKeyID]='1008',sortId='6'}}
F.data[roleProducerQueue]={};F.data[roleBuilding]={}
zqDispatch.gotoStore=function(_,bottom,id)equal(bottom,false);routes[#routes+1]={'store',id}end
zqDispatch.moveToResource=function()routes[#routes+1]={'resource'}end
zqDispatch.moveToRepository=function()routes[#routes+1]={'alchemy'}end
local before=F.snapshot(F.data);local page=assert(HomeLayer:create())
F.tap(page.goalButton);F.tap(page.goalRows[1].sources);assert(page.sourceDialog and not page.goalDialog);equal(#scene.children,1)
local first=page.sourceDialog;page:openSourcesAt(1);equal(page.sourceDialog,first,'repeated open ignored')
F.tap(page.sourceBack);assert(page.goalDialog and not page.sourceDialog);equal(#scene.children,1,'back replaces modal')
F.tap(page.goalRows[1].sources);local count=#routes
F.guides['104:true']=false;F.tap(page.sourceRows[1].button);equal(#routes,count,'gate changes at click block stale link');assert(not page.sourceRows[1].button.item:isEnabled())
F.guides['104:true']=true;F.dm:postEvent(roleGuideStep)
F.data[roleStore][1].sortId='6';page:openSource('1018');equal(#routes,count,'wrong saved sortId blocks click-time navigation')
F.data[roleStore][1].sortId='4';F.dm:postEvent(roleStore);F.tap(page.sourceRows[1].button)
equal(routes[#routes][1],'store');equal(routes[#routes][2],'1018');equal(page.sourceDialog,nil);equal(#scene.children,0)
equal(F.snapshot(F.data),before,'source navigation does not buy or manufacture')
F.tap(page.goalButton);F.tap(page.goalRows[2].sources);local count=#routes
F.data[rolePack]['1008']=5;page:openSource('1008');equal(#routes,count,'fulfilled shortage does not follow stale link');equal(page.sourceDialog,nil)
F.tap(page.goalButton);F.tap(page.goalRows[1].sources);page.sourceDialog:removeFromParent(true);equal(page.sourceDialog,nil,'close clears source ownership')
F.tap(page.goalButton);F.tap(page.goalRows[1].sources);page:destory();equal(#scene.children,0,'leaving closes sources')
-- Read actual PNG geometry through the production legacySize helper. This
-- catches footer touch overlap that a text-only or mock 32px button misses.
local originalSprite=cc.Sprite.create
cc.Sprite.create=function(_,path)
 local bytes=read('bin/res/assets/'..path)
 local function u32(i)local a,b,c,d=bytes:byte(i,i+3);return ((a*256+b)*256+c)*256+d end
 local n=F.node('Sprite');n:setContentSize(cc.size(u32(17),u32(21)));return n
end
dofile(root..'DialogTheme.lua')
local closeSize=DialogTheme.legacySize('Images/btn/ann03_a.png')
local panelSize=DialogTheme.legacySize('Images/UI/tankuang_01.png')
equal(closeSize.width,176);equal(closeSize.height,61);equal(panelSize.width,572);equal(panelSize.height,437)
cc.Sprite.create=originalSprite
-- Maximum three prerequisite rows stay above both footer controls. The native
-- owner still verifies glyph wrapping and actual portrait output.
for _,size in ipairs({{width=480,height=800},{width=540,height=900}})do
 F.viewport.width=size.width;F.viewport.height=size.height
 F.data[roleMake]={};F.data[roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=0}};F.data[rolePack]={}
 local home=assert(HomeLayer:create());F.tap(home.goalButton)
 for _,row in ipairs(home.goalRows)do
  assert(row.detail.dimensions.width==home.goalDialog.s_size.width-206)
  assert(row.sources:getPositionY()-20>80,'goal source action above footer')
 end
 F.tap(home.goalRows[1].sources);equal(#scene.children,1)
 equal(home.sourceDialog.s_size.width,panelSize.width);equal(home.sourceDialog.s_size.height,panelSize.height)
 local back=home.sourceBack;local backSize=back:getContentSize()
 local backLeft=back:getPositionX()-backSize.width/2
 local backRight=back:getPositionX()+backSize.width/2
 local closeLeft=panelSize.width/2-closeSize.width/2
 equal(backLeft,30,'back footer left margin');equal(back:getPositionY(),50,'footer shared baseline')
 assert(closeLeft-backRight>=36,'Back and real legacy Close touch bounds have at least 36px horizontal clearance')
 assert(back:getPositionY()-backSize.height/2>=0,'back stays inside panel')
 assert(back:getPositionY()+backSize.height/2<105,'back stays below third source description')
 for _,row in ipairs(home.sourceRows)do
  assert(row.detail:getPositionY()-row.detail.dimensions.height>=105,'source text above footer')
  assert(row.detail.dimensions.width==home.sourceDialog.s_size.width-60)
 end
 home:destory();equal(#scene.children,0)
end
print('PASS source modal lifecycle, live and click-time gates, exact market focus, zero purchases and portrait bounds')
-- Exercise the real Dispatch function with old and new call signatures.
local oldCreate=StoreLayer.create;local received={}
StoreLayer.create=function(_,bottom,id)received={bottom,id};return 'store-view'end
local dispatcher={setViewWithDirection=function(_,view,direction,index)equal(view,'store-view');equal(direction,true);equal(index,1)end,
 mainMenu={activeButtonWithIndex=function(_,index)equal(index,7)end}}
Dispatch.gotoStore(dispatcher);equal(received[1],false);equal(received[2],nil)
Dispatch.gotoStore(dispatcher,true);equal(received[1],true);equal(received[2],nil)
Dispatch.gotoStore(dispatcher,false);equal(received[1],false);equal(received[2],nil)
Dispatch.gotoStore(dispatcher,false,'1018');equal(received[1],false);equal(received[2],'1018')
StoreLayer.create=oldCreate
print('PASS original no-argument and boolean market Dispatch calls plus optional target')
