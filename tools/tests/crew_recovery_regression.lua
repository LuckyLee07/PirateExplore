-- Production Home callbacks + shipped CSV; controlled states, no player save/GUI.
local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/home_master_regression.lua')
local stop=assert(source:find('\nfixture()\nlocal routes={}',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..[[
fixture()
return {data=data,dm=dm,csv=csv,node=node,tap=tap,snapshot=snapshot,viewport=viewport,
        guides=guideOverrides,packagedCSV=packagedCSV}
]],'@recovery-home-fixture'))()
local function eq(a,b,label)assert(a==b,(label or 'value')..': '..tostring(a)..' ~= '..tostring(b))end
F.csv[csvOfBuild]=F.packagedCSV('build')
local data=F.data
local function state(camp,money,gate)
 data[roleSelectUnit]={};data[roleSoildierQueue]={};data[roleMoney]=money or 0
 data[roleBuilding]=camp and {{[dataKeyID]='58',[dataKeyNum]=camp}} or {}
 F.guides['8:false']=true;F.guides['30:true']=true;F.guides['1:false']=true;F.guides['103:true']=gate or false
end
local function nextStep()return CrewRecovery.next(F.dm,GuideController:getInstance())end
state(0,0);local r=nextStep();eq(r.route,'alchemy');assert(r.detail:find('30金币',1,true));assert(r.detail:find('3金币',1,true));assert(r.detail:find('还缺 30金币',1,true))
state(0,30);eq(nextStep().route,'build')
state(1,0,true);eq(nextStep().route,'alchemy');assert(nextStep().detail:find('还缺 3金币',1,true))
state(1,3,true);eq(nextStep().route,'recruit')
for _,v in ipairs({{nil,false},{0,true},{1,false},{nil,true},{-1,false}}) do state(v[1],50,v[2]);eq(nextStep().route,nil,'unknown/inconsistent gate blocked') end
state(0,0);F.guides['1:false']=false;eq(nextStep().route,nil,'construction gate kept')
state(0,0);F.guides['8:false']=false;eq(nextStep(),nil,'dock tutorial priority')
state(0,0);F.guides['30:true']=false;eq(nextStep(),nil,'original starter crew award entry priority')
state(0,0);data[roleSoildierQueue]={['100']={[dataKeyNum]=1}};eq(nextStep(),nil,'reserve crew use preparation')
state(0,0);data[roleSelectUnit]={['10100']=1};eq(nextStep(),nil,'selected crew use preparation')
-- Runtime CSV matrices must use the same values, not hard-coded costs.
state(0,2);local b=F.csv[csvOfBuild]['58'];local c=F.csv[csvOfSoilderAttribute]['100']
local oldB,oldC=b.resume,c.produceResume
b.resume={{'1001','41'}};c.produceResume={{'2','1001','7'}}
r=nextStep();assert(r.detail:find('41金币',1,true));assert(r.detail:find('7金币',1,true));assert(r.detail:find('还缺 39金币',1,true))
b.resume={{'1007','1'}};eq(nextStep().route,nil,'unknown cost cannot advertise gold route')
b.resume=oldB;c.produceResume=oldC
local scene=F.node('Scene');local created=0
AlertView={create=function()
 created=created+1;local d=F.node('Alert');d.s_size={width=572,height=437};d.s_bg=F.node('Background');d:addChild(d.s_bg);scene:addChild(d);return d
end}
local routes={}
zqDispatch={gotoBuild=function(_,id)routes[#routes+1]={'build',id}end,
 moveToRepository=function()routes[#routes+1]={'alchemy'}end,
 mainMenu={openRoute=function(_,id)routes[#routes+1]={'guarded',id}end}}
local function tap(n)F.tap(n,'recovery')end
state(0,0);local before=F.snapshot({data,F.csv});local home=assert(HomeLayer:create())
eq(home.hintLabel:getString(),'补充船员');eq(home.departureButton.label:getString(),'补充船员  ›')
tap(home.departureButton);eq(created,1);home:openRecovery();eq(created,1,'one dialog')
local dialog=home.recoveryDialog;dialog:removeFromParent(true);eq(home.recoveryDialog,nil,'dismiss releases dialog');eq(#routes,0)
tap(home.departureButton);tap(home.recoveryAction);eq(routes[#routes][1],'alchemy');eq(home.recoveryDialog,nil)
eq(F.snapshot({data,F.csv}),before,'preview and navigation write no role/CSV data')
tap(home.departureButton);data[roleMoney]=30 -- No event: click must re-read current money.
tap(home.recoveryAction);eq(routes[#routes][1],'build');eq(routes[#routes][2],'58')
state(1,3,true);tap(home.departureButton);tap(home.recoveryAction);eq(routes[#routes][1],'guarded');eq(routes[#routes][2],2,'never call unguarded gotoTrain')
tap(home.departureButton);F.guides['103:true']=false;local count=#routes;tap(home.recoveryAction);eq(#routes,count,'stale gate cannot navigate');assert(not home.recoveryAction.item:isEnabled())
state(1,3,true);home:refreshSummary();data[roleSoildierQueue]={['100']={[dataKeyNum]=1}};home:openRecoveryAction();eq(home.recoveryDialog,nil,'crew acquired closes recovery');eq(#routes,count)
home:refreshSummary();eq(home.hintLabel:getString(),'请编入船员');tap(home.departureButton);eq(routes[#routes][2],1)
state(0,0);tap(home.departureButton);home:destory();eq(home.recoveryDialog,nil);eq(#scene.children,0,'leaving Home closes dialog')
for _,size in ipairs({{width=480,height=800},{width=540,height=900}}) do
 F.viewport.width=size.width;F.viewport.height=size.height;state(0,0)
 local page=assert(HomeLayer:create());tap(page.departureButton);assert(page.recoveryDetail:getString():find('编入船员与食物',1,true));page:destory()
end
print('PASS recovery actual CSV costs, prerequisite branches, tutorial/standby priority, fresh-click guards, no spending, dialog lifecycle and portrait construction (not native visual acceptance)')
