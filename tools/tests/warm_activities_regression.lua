-- Real CSV/read-only/lifecycle coverage for the opt-in Warm Q activity pages.
-- Uses the existing Cocos fixture. Native pixels remain a separate UI check.
local root='bin/res/scripts/LuaClass/'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local function equal(a,b,why)assert(a==b,(why or 'value')..': '..tostring(a)..' ~= '..tostring(b))end
local source=read('tools/tests/home_master_regression.lua')
local stop=assert(source:find('\nfixture()\nlocal routes={}',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..[[
fixture()
return {data=data,dm=dm,csv=csv,node=node,tap=tap,snapshot=snapshot,viewport=viewport,
    guides=guideOverrides,packagedCSV=packagedCSV,textTree=textTree,dispatcher=dispatcher}
]],'@warm-activity-fixture'))()
local fixtureRequire=require
require=function(name)
    if name=='LuaClass/WarmTheme' or name=='LuaClass/CrewSkillDetails' or name=='LuaClass/ItemIcon' or name=='LuaClass/WarmUpgrade' then
        if not package.loaded[name] then package.loaded[name]=assert(loadfile('bin/res/scripts/'..name..'.lua'))() end
        return package.loaded[name]
    end
    if name=='LuaClass/HarborGoals' then return HarborGoals end
    if name=='LuaClass/CrewRecovery' then return CrewRecovery end
    return fixtureRequire(name)
end
F.csv[csvOfBuild]=F.packagedCSV('build')
F.csv[csvOfProduce]=F.packagedCSV('produce')
F.csv[csvOfStore]=F.packagedCSV('store');F.csv[csvOfWorker]=F.packagedCSV('worker')
F.csv[csvOfSkillAttribute]=F.packagedCSV('skillAttribute')
F.csv[csvOfBuff]=F.packagedCSV('buff')
local A=assert(loadfile(root..'WarmActivities.lua'))()
local guide=GuideController:getInstance()
local state=A.snapshot(F.dm,guide)
equal(state.crewCount,7,'real stock total');equal(state.assigned,3,'selected counts are a subset, not duplicate inventory')
equal(#state.crew,2,'actual owned professions only')
equal(state.crew[1].name,'木盾舵手','real CSV profession name')
equal(state.inventory[1].num,100,'actual inventory, not selected cargo')
equal(state.progress.enabled,false,'legacy saves do not invent a voyage ledger')
local original=F.snapshot(F.data);local csvOriginal=F.snapshot(F.csv)
local owner=F.node('WarmHome');local persistent=F.node('owner-content');owner:addChild(persistent)
local scene=F.node('Scene');scene:addChild(owner)
local routes={}
zqDispatch={}
for _,method in ipairs({'gotoTrain','moveToExpedition','gotoBuild','gotoMake','moveToRepository','gotoAchievement','moveToResource','gotoStore'}) do
    local name=method;zqDispatch[name]=function(_,id,extra)routes[#routes+1]={method=name,id=id,extra=extra}end
end
local function tap(button)F.tap(button,'warm activity tap')end
local function listeners()return #F.dispatcher.listeners end
local baseline=listeners()
local panel=assert(A.open('crew',owner))
equal(owner.warmActivity,panel,'owner reference');equal(#owner.children,2,'owner content preserved')
assert(F.textTree(panel):find('已有船员 7 人',1,true),'stock count does not claim everyone is assigned')
equal(A.open('crew',owner),panel,'repeat open cannot stack')
equal(#owner.children,2,'repeat open creates no node')
assert(panel.buttons['crew:107'],'owned crew opens detail')
local staleCrewButton=panel.buttons['crew:107'];tap(staleCrewButton)
equal(panel.detailId,'107','real crew detail')
assert(F.textTree(panel):find('技能',1,true),'skill shown')
tap(panel.buttons.back);equal(panel.detailId,nil,'detail back returns to roster')
local currentGeneration=panel.generation;tap(staleCrewButton)
equal(panel.generation,currentGeneration,'removed callback is inert')
F.data[roleSoildierQueue]['107'][dataKeyNum]=0;F.dm:postEvent(roleSoildierQueue)
equal(#panel.snapshot.crew,1,'open panel refreshes after live inventory changes')
panel:showDetail('124');F.data[roleSoildierQueue]['124'][dataKeyNum]=0;F.dm:postEvent(roleSoildierQueue)
equal(panel.detailId,nil,'removed crew closes stale detail')
assert(F.textTree(panel):find('名册还是空',1,true),'empty roster is honest')
panel:close();equal(owner.warmActivity,nil);equal(#owner.children,1,'close preserves owner');equal(owner.children[1],persistent)
equal(listeners(),baseline,'event and touch listeners removed on close')
for _,entries in pairs(F.dm.__eventListener)do for key in pairs(entries)do assert(not tostring(key):find('warmActivities',1,true),'no stale callback ownership')end end
local routeCount=#routes;panel:route('assign');equal(#routes,routeCount,'closed panel cannot navigate')
-- Restore exact fixture for no-write comparisons after the intentional updates.
F.data[roleSoildierQueue]['107'][dataKeyNum]=5;F.data[roleSoildierQueue]['124'][dataKeyNum]=2
equal(F.snapshot(F.data),original,'opening, rendering and dismissing writes no role data')
equal(F.snapshot(F.csv),csvOriginal,'static tables remain unchanged')
-- Gates are rechecked at the moment of action, and locked pages cannot be entered.
for _,pair in ipairs({{'train','103:true'},{'assign','8:false'},{'build','1:false'},{'make','102:true'},{'repository','2:false'},{'records','8:false'}})do
 local p=A.open('crew',owner);F.guides[pair[2]]=false
 local count=#routes;equal(p:route(pair[1]),false,'late lock rejected');equal(#routes,count)
 F.guides[pair[2]]=true;equal(p:route(pair[1]),true,'restored route');equal(owner.warmActivity,nil)
 equal(#routes,count+1,'exactly one dispatch');p:route(pair[1]);equal(#routes,count+1,'repeat click is inert')
end
-- Log records retain the original shipyard gate and real utility-route path.
F.guides['8:false']=false
panel=A.open('log',owner);assert(not panel.buttons.primary.item:isEnabled(),'locked records button disabled')
local beforeRecords=#routes;tap(panel.buttons.primary);equal(#routes,beforeRecords,'locked records tap cannot bypass gate')
F.guides['8:false']=true;panel:refresh();local formerlyUnlocked=panel.buttons.primary
F.guides['8:false']=false;tap(formerlyUnlocked);equal(#routes,beforeRecords,'records rechecks late gate change')
F.guides['8:false']=true;panel:refresh()
local utilityCalls=0
zqDispatch.mainMenu={openUtilityRoute=function(_,key)
 equal(key,'achievement');assert(owner.warmActivity==nil,'close before utility route');utilityCalls=utilityCalls+1
end}
tap(panel.buttons.primary);equal(utilityCalls,1,'existing MainMenu utility route preferred')
equal(#routes,beforeRecords,'no second direct dispatch');tap(formerlyUnlocked);equal(utilityCalls,1,'stale record callback inert')
zqDispatch.mainMenu=nil
-- Generic pages keep MainMenu visit side effects; focused goals stay direct.
local menuRoutes={};zqDispatch.mainMenu={openRoute=function(_,index)menuRoutes[#menuRoutes+1]=index end}
for _,entry in ipairs({{'train',2},{'assign',1},{'build',3},{'make',5},{'repository',4}})do
 panel=A.open('crew',owner);assert(panel:route(entry[1]));equal(menuRoutes[#menuRoutes],entry[2])
end
zqDispatch.mainMenu=nil
-- A wiped crew has a real recovery path, including missing-funds and locked camp.
local savedCrew=F.data[roleSoildierQueue];local savedSelection=F.data[roleSelectUnit]
local savedBuilding=F.data[roleBuilding];local savedMoney=F.data[roleMoney]
F.data[roleSoildierQueue]={};F.data[roleSelectUnit]={}
F.data[roleBuilding]={{[dataKeyID]='58',[dataKeyNum]=0}};F.guides['103:true']=false;F.data[roleMoney]=0
panel=A.open('crew',owner);equal(panel.snapshot.recovery.route,'alchemy');tap(panel.buttons.primary)
equal(routes[#routes].method,'moveToRepository','recovery respects missing funds')
F.data[roleMoney]=1000;panel=A.open('crew',owner);equal(panel.snapshot.recovery.route,'build');tap(panel.buttons.primary)
equal(routes[#routes].method,'gotoBuild');equal(routes[#routes].id,'58','actual training camp construction')
F.data[roleBuilding][1][dataKeyNum]=1;F.guides['103:true']=true
panel=A.open('crew',owner);equal(panel.snapshot.recovery.route,'recruit');tap(panel.buttons.primary)
equal(routes[#routes].method,'gotoTrain','built camp enters existing recruitment')
F.data[roleSoildierQueue]=savedCrew;F.data[roleSelectUnit]=savedSelection
F.data[roleBuilding]=savedBuilding;F.data[roleMoney]=savedMoney
-- Held inventory is paginated, inspected with real descriptions, and removed live.
for i=1006,1022 do F.data[rolePack][tostring(i)]=i-1000 end
panel=A.open('collection',owner);assert(panel.buttons.next,'large stock has next page')
local function hasPath(node,path)
 if node.path==path then return true end
 for _,child in ipairs(node:getChildren())do if hasPath(child,path)then return true end end
 return false
end
assert(hasPath(panel,'Images/Icon/'..F.csv[csvOfResourceInfo]['1005'].iconName),'resource art uses authoritative iconName field')
local seen={};local pages=math.ceil(#panel.snapshot.inventory/6)
for page=1,pages do
 for key in pairs(panel.buttons)do if key:sub(1,5)=='item:' then seen[key:sub(6)]=true end end
 if page<pages then tap(panel.buttons.next)end
end
for _,entry in ipairs(panel.snapshot.inventory)do assert(seen[entry.id],'every held item is accessible')end
panel:showDetail('1006');assert(F.textTree(panel):find('仓库 6',1,true),'detail quantity is truthful')
F.data[rolePack]['1006']=0;F.dm:postEvent(rolePack);equal(panel.detailId,nil,'consumed item removed from detail')
assert(F.textTree(panel):find('当前库存',1,true),'inventory explicitly labeled')
tap(panel.buttons.log);equal(panel.kind,'log');assert(F.textTree(panel):find('没有逐次航程记录',1,true))
tap(panel.buttons.primary);equal(routes[#routes].method,'gotoAchievement','real records route')
-- Read-only goals quote actual costs and resolve the live recipe/prerequisite.
F.data[rolePackSize]=20;F.data[roleAlchemyUnit]=1;F.data[roleMoney]=3
F.data[roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=0}};F.data[roleMake]={}
F.data[rolePack]={['1007']=5,['1008']=3}
F.data[roleGuideStep]='s001_r102'
local previewRoutes=#routes;local previewState=F.snapshot(F.data)
panel=A.open('ship',owner);assert(panel.buttons['goal:1148']);tap(panel.buttons['goal:1148'])
local preview=assert(panel.warmUpgrade,'goal opens actual WarmUpgrade child preview')
equal(preview.goalId,'1148','cargo goal identity passed to preview')
equal(preview.quote.status,'prerequisite','real preview recognizes missing forge')
equal(owner.warmActivity,panel,'preview preserves the underlying ship activity')
equal(#routes,previewRoutes,'preview does not prematurely dispatch to construction')
equal(F.snapshot(F.data),previewState,'opening actual upgrade preview leaves role data unchanged')
tap(preview.buttons.cancel);equal(panel.warmUpgrade,nil,'preview cancellation returns to same ship activity')
equal(owner.warmActivity,panel);equal(F.snapshot(F.data),previewState,'cancelling preview is read-only')
panel:close()
local cargoSort
for id,row in pairs(F.csv[csvOfProduce])do if row.resourceInfoID=='1148' then cargoSort=id;break end end
assert(cargoSort,'packaged cargo recipe exists')
F.data[roleMake]={{[dataKeyID]='1148',[dataKeyNum]=-1,sortId=cargoSort}}
previewState=F.snapshot(F.data)
panel=A.open('ship',owner);tap(panel.buttons['goal:1148'])
preview=assert(panel.warmUpgrade);equal(preview.goalId,'1148','available recipe still opens contextual preview')
equal(preview.quote.status,'insufficient','real preview quotes missing cloth')
equal(#routes,previewRoutes,'preview never dispatches directly to old manufacture page')
equal(F.snapshot(F.data),previewState,'recipe preview never consumes materials')
tap(preview.buttons.cancel);panel:close()
panel=A.open('ship',owner);local stale=panel.buttons['goal:1148'];F.data[rolePackSize]=30;F.dm:postEvent(rolePackSize)
local beforeRoutes=#routes;tap(stale);equal(#routes,beforeRoutes,'completed goal cannot navigate via old callback')
equal(panel.warmUpgrade,nil,'stale goal callback cannot reopen a completed upgrade preview')
panel:close()
-- Material sources are contextual, live, gated and retain original target focus.
F.data[rolePackSize]=20;F.data[rolePack]={['1007']=5};F.data[roleMake]={{[dataKeyID]='1148',[dataKeyNum]=-1}}
F.data[roleStore]={{[dataKeyID]='1018',sortId='4'}};F.data[roleProducerQueue]={}
F.guides['104:true']=true
panel=A.open('ship',owner);tap(panel.buttons['sources:1148']);equal(panel.sourceGoalId,'1148')
equal(panel.sourceEntries[1].id,'1018');assert(panel.buttons['source:1018'])
tap(panel.buttons.sourceBack);equal(panel.sourceGoalId,nil);equal(panel.kind,'ship','source Back preserves ship')
tap(panel.buttons['sources:1148']);tap(panel.buttons['source:1018'])
equal(routes[#routes].method,'gotoStore');equal(routes[#routes].id,false);equal(routes[#routes].extra,'1018','market keeps real resource focus')
F.guides['104:true']=false;panel=A.open('ship',owner);tap(panel.buttons['sources:1148'])
assert(not panel.buttons['source:1018'].item:isEnabled(),'locked market cannot be reached')
local noRoute=#routes;equal(panel:route('source','1018'),false);equal(#routes,noRoute)
F.guides['104:true']=true;panel:refresh();local oldSource=panel.buttons['source:1018']
F.data[rolePack]['1018']=5;F.dm:postEvent(rolePack);equal(#panel.sourceEntries,0,'resolved shortage disappears live')
tap(oldSource);equal(#routes,noRoute,'stale shortage callback inert')
F.data[rolePackSize]=30;F.dm:postEvent(rolePackSize);equal(panel.sourceGoalId,nil,'completed upgrade returns to overview');panel:close()
F.data[rolePackSize]=20;F.data[roleMake]={};F.data[roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=0}}
F.data[roleMoney]=0;F.data[rolePack]={}
for _,entry in ipairs({{'1001','moveToRepository'},{'1006','moveToResource'}})do
 panel=A.open('ship',owner);panel:showSources('1148');assert(panel.buttons['source:'..entry[1]])
 tap(panel.buttons['source:'..entry[1]]);equal(routes[#routes].method,entry[2],'real shortage route')
end
F.data[rolePack]={['1008']=3}
-- Full harbor advice is preserved, read-only, and returns to the log controls.
F.data.adventureProgressV1={version=1,enabled=true,voyage=1,firstEventReturned=true,npcRescued=true,firstReturnClaimed=true}
panel=A.open('log',owner);tap(panel.buttons.brief);assert(panel.harborBrief)
local expected=require('LuaClass/AdventureProgress').getHarborStatus(F.dm).npcText
equal(table.concat(panel.briefPages),expected,'full harbor prerequisites preserved without truncation')
tap(panel.buttons.briefBack);assert(not panel.harborBrief and panel.buttons.collection and panel.buttons.primary,'brief Back restores inventory/records')
panel:close()
-- Adventure facts are shown only after persistence, and pending is not success.
F.data.adventureProgressV1={version=1,enabled=true,voyage=1,activeVoyage=1,pending={choice='rescue'}}
F.data[roleStatue]=1;F.data[roleBattleQueue]={['101']=1};F.data[roleBattlePack]={['1008']={num=2}}
state=A.snapshot(F.dm,guide);equal(state.assigned,1);equal(state.canAssign,false,'cannot reassign active voyage')
local iron;for _,item in ipairs(state.inventory)do if item.id=='1008' then iron=item end end
equal(iron.stock,3);equal(iron.aboard,2,'sea cargo displayed separately');equal(iron.num,5)
panel=A.open('log',owner);assert(F.textTree(panel):find('尚未结算',1,true));assert(not F.textTree(panel):find('林恩在港口安顿',1,true))
F.data.adventureProgressV1={version=1,enabled=true,voyage=1,firstEventReturned=true,npcRescued=true,firstReturnClaimed=true}
F.dm:postEvent('adventureProgressV1');assert(F.textTree(panel):find('林恩在港口安顿',1,true));assert(F.textTree(panel):find('不代表材料仍在仓库',1,true))
-- Changing tab reuses one layer; ancestor removal cleans subscriptions/ownership.
equal(A.open('collection',owner),panel);equal(panel.kind,'collection')
owner:removeFromParent(true);equal(owner.warmActivity,nil);equal(listeners(),baseline)
-- All pages fit the actual logical viewport through a bounded 480 x 800 canvas.
for _,viewport in ipairs({{width=480,height=800},{width=640,height=1066},{width=540,height=900}})do
 F.viewport.width=viewport.width;F.viewport.height=viewport.height
 for _,kind in ipairs({'crew','ship','collection','log'})do
  local page=A.open(kind,F.node('WarmHome'));local z=page.canvas:getContentSize();local scale=page.canvas:getScale()
  assert(z.width*scale<=viewport.width+.01 and z.height*scale<=viewport.height+.01,'bounded '..kind)
  page:close()
 end
end
print('PASS WarmActivities real data, zero writes, repeat/stale actions, gates, pagination, live updates, cleanup and viewport bounds')
