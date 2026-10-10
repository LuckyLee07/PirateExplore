-- Real packaged CSV, production dialog callbacks and modal lifecycle in memory.
-- No player save, GUI input, altered recipe, reward, or transaction policy.
local root='bin/res/scripts/LuaClass/'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local function eq(a,b,why)assert(a==b,(why or 'value')..': '..tostring(a)..' ~= '..tostring(b))end
local home=read('tools/tests/home_master_regression.lua')
local stop=assert(home:find("\ndofile(root..'Header.lua')",1,true))
local H=assert(loadstring(home:sub(1,stop-1)..'\nreturn {node=node,methods=Node,snapshot=snapshot,copy=copy,viewport=viewport}','@sailor-node-fixture'))()
local N=H.methods
function N:getLocalZOrder()return self.z or 0 end
function N:isRunning()return true end
function N:setFontSize(v)self.fontSize=v end
function N:getTag()return self.tag end
function N:removeChildByTag(tag)local child=self:getChildByTag(tag);if child then child:removeFromParent()end end
cc.MenuItemImage={create=function(_,path)local n=H.node('MenuItemImage');n:setContentSize(cc.Sprite:create(path):getContentSize());return n end}
local scene=H.node('Scene')
cc.Director={getInstance=function()return {getVisibleSize=function()return H.viewport end,getRunningScene=function()return scene end}end}
dofile('src/engine/cocos2d-x/cocos/scripting/lua-bindings/script/extern.lua')
dofile(root..'Header.lua')
local start=assert(home:find('local function readFile(path)',1,true))
stop=assert(home:find("\nlocal soldiers=packagedCSV('soilderAttribute')",start,true))
local packagedCSV=assert(loadstring('local equal=...\n'..home:sub(start,stop-1)..'\nreturn packagedCSV','@sailor-packaged-csv'))(eq)
local resources,workers,builds,soldiers=packagedCSV('resourceInfo'),packagedCSV('worker'),packagedCSV('build'),packagedCSV('soilderAttribute')
local areas=packagedCSV('strongholdDistribution')
local csv={[csvOfResourceInfo]=resources,[csvOfWorker]=workers,[csvOfBuild]=builds,[csvOfSoilderAttribute]=soldiers}
local data,gate,toast,routes,writes={},true,nil,0,0
local dm={getCSVByID=function(_,key)return csv[key] or {}end,getRoleData=function(_,key)return data[key]end,
    getSound_off=function()return 1 end,getStoreUnlockTable=function()return {['1017']='3',['1008']='3',['1007']='1'}end,
    addCoin=function(_,amount)
        if data[roleMoney]+amount<0 then return 0,-data[roleMoney]-amount end
        data[roleMoney]=data[roleMoney]+amount;writes=writes+1;return 1
    end,
    addPackItemWithId=function(_,id,n)data[rolePack][id]=(data[rolePack][id] or 0)+n;writes=writes+1 end,
    setRoleData=function(_,key,value)data[key]=value;writes=writes+1 end,
    setAchievementInfo=function()end}
DataManager={getInstance=function()return dm end}
local guide={getIsHaveStep=function(_,id)return id~=2 or gate end}
GuideController={getInstance=function()return guide end}
ToastUtil={toastString=function(_,s)toast=s end}
zqDispatch={moveToResource=function()routes=routes+1 end,moveToExpedition=function()error('unexpected exploration route')end}
cclog=function()end
for _,name in ipairs({'HomeTheme','MasterTheme','ManagementTheme','DialogTheme','BaseView','DialogueView','ProductionSources','TrainMode','Lackmaterial'})do dofile(root..name..'.lua')end
local P=ProductionSources
local function state(queue)
    data={[roleProducerQueue]=queue or {},[rolePack]={},[roleMoney]=100,[roleBuilding]={}}
    gate=true;toast=nil;routes=0;writes=0
end
state();local before=H.snapshot({data,csv})
eq(P.find(dm,guide,'1017'),nil,'leather has no worker recipe')
eq(P.find(dm,guide,'1008'),nil,'recipe alone does not unlock iron')
data[roleBuilding]={{[dataKeyID]='61',[dataKeyNum]=1}}
eq(P.find(dm,guide,'1008'),nil,'built mine alone does not grant a missing queue entry')
data[roleBuilding]={};data[roleProducerQueue]={{[dataKeyID]='5',[dataKeyNum]=0}}
eq(P.find(dm,guide,'1008').id,'5','unlocked zero-worker entry can be arranged without inventing a building gate')
gate=false;eq(P.find(dm,guide,'1008'),nil,'resource-page gate retained');gate=true
data[roleProducerQueue]={{[dataKeyID]='missing',[dataKeyNum]=4}};eq(P.find(dm,guide,'1008'),nil,'unknown worker cannot grant route')
for _,case in ipairs({{'1','1004'},{'2','1005'},{'15','1022'},{'16','1076'}})do
    data[roleProducerQueue]={{[dataKeyID]=case[1],[dataKeyNum]=0}}
    eq(P.find(dm,guide,case[2]).id,case[1],'saved worker, including non-building unlocks, is authority')
end
assert(areas['7'].activateID:find('4_15',1,true) and areas['9'].activateID:find('4_16',1,true),'real sea-area worker unlocks')
for _,building in pairs(builds)do assert(not building.activateID:find('4_15',1,true) and not building.activateID:find('4_16',1,true),'no building requirement for sea workers')end
data[roleProducerQueue]={{[dataKeyID]='5',[dataKeyNum]=0}}
local resume=workers['5'].resume;workers['5'].resume=nil;eq(P.find(dm,guide,'1008'),nil,'missing input recipe is not runtime production');workers['5'].resume=resume
local produce=workers['5'].produce;workers['5'].produce={{'1008','0'}};eq(P.find(dm,guide,'1008'),nil,'zero output is not a source');workers['5'].produce=produce
before=H.snapshot({data,csv});for _=1,3 do P.find(dm,guide,'1008');P.first(dm,guide,{{mtId='1017'},{mtId='1008'}})end
eq(H.snapshot({data,csv}),before,'source queries write neither save nor CSV');eq(writes,0)
eq(resources['1017'].price,'3');eq(resources['1008'].price,'3')
eq(resources['1040'].resume,'1017_22');eq(resources['1049'].resume,'1008_12;1007_10')
eq(soldiers['101'].produceResume,'2_1040_1;2_1049_1')
-- The UI receives parsed matrices, while the pure source query also accepts
-- raw packaged cells above. Keep the authoritative values unchanged.
local function matrix(value)
    local result={};for row in tostring(value):gmatch('[^;]+')do local fields={};for part in row:gmatch('[^_]+')do fields[#fields+1]=part end;result[#result+1]=fields end;return result
end
for _,r in pairs(resources)do r.resume=matrix(r.resume)end
for _,r in pairs(workers)do r.resume=matrix(r.resume);r.produce=matrix(r.produce)end
eq(P.find(dm,guide,'1008').id,'5','runtime matrices work too')
print('PASS actual CSV requirements/prices and read-only production source gates, zero workers, missing recipe and sea-area unlocks')

local allItems={};local originalItem=ManagementTheme.menuItem
ManagementTheme.menuItem=function(...)local item=originalItem(...);allItems[#allItems+1]=item;return item end
local function create(fn)
    local first=#allItems+1;local view=assert(fn());local items={};for i=first,#allItems do items[#items+1]=allItems[i]end
    view:show();return view,items
end
local manager=DialogueViewManager:sharedInstance()
local function clear()manager:removeAllView();eq(manager:Count(),0,'all modal owners removed')end
local function finish(view)
    local action=view.actions[#view.actions];eq(action.kind,'Sequence','close sequence');local call=action.args[#action.args];eq(call.kind,'CallFunc');call.args[1]()
end
local function tap(item)assert(item:isEnabled() and item:isVisible(),'only enabled visible controls accept player input');item.callback()end
local function texts(view)
    local out={};local function visit(n)if n.text and n:isVisible()then out[#out+1]=n.text end;for _,child in ipairs(n.children)do visit(child)end end;visit(view);return table.concat(out,'|')
end
local function inline(id,missing,cost,total)
    return create(function()return MaterialView:create(2,resources[id].name,missing,cost,total,1,id,0)end)
end
local function lack(id,missing)
    local r=resources[id];return {mtId=id,mtname=r.name,mtprice=r.price,mtnum=tostring(missing),mtStar=r.starNum,mtonlyProduce=r.onlyProduce}
end
local function regular(rows)return create(function()return Lackmaterial:create(rows,function()end)end)end
local function unavailable(view,items)
    assert(texts(view):find('暂无已解锁的生产途径',1,true),'honest unavailable copy')
    local button=items[#items];assert(not button:isVisible() and not button:isEnabled(),'no false production action')
end
for _,size in ipairs({{width=480,height=800},{width=540,height=900}})do
    H.viewport.width=size.width;H.viewport.height=size.height
    state({{[dataKeyID]='1',[dataKeyNum]=2},{[dataKeyID]='2',[dataKeyNum]=1}})
    before=H.snapshot(data)
    local view,items=inline('1017',22,66,22);unavailable(view,items)
    eq(manager:Count(),1);view:show();eq(manager:Count(),1,'repeat show does not stack')
    tap(items[1]);finish(view);eq(manager:Count(),0);eq(H.snapshot(data),before,'close changes no economy')
    view,items=regular({lack('1017',22)});unavailable(view,items);clear()
    -- All new hint rectangles fit the original 530x108 row, and production
    -- text ends before its 128x59 action. This is layout geometry, not pixels.
    state({{[dataKeyID]='5',[dataKeyNum]=0}})
    for _,make in ipairs({function()return inline('1008',7,21,12)end,function()return regular({lack('1008',7)})end})do
        view,items=make();local button=items[#items];assert(button:isVisible())
        local label
        for _,child in ipairs(view.children)do if child.text and child.text:find('需安排工人并备齐原料',1,true)then label=child end end
        assert(label and label.dimensions.height<=108,'production hint bounded to existing row')
        assert(label:getPositionX()+label.dimensions.width < button:getPositionX()-64,'hint does not overlap action')
        assert(math.abs(label:getPositionY()-button:getPositionY())<1,'hint stays in production row')
        clear()
    end
end
print('PASS both real dialogs hide leather production, preserve purchase controls, close/reopen lifecycle and portrait hint geometry')

-- Clicking a production shortcut re-reads both unlock authority and page gate.
state({{[dataKeyID]='5',[dataKeyNum]=0}})
local view,items=inline('1008',7,21,12);data[roleProducerQueue]={};tap(items[3])
eq(routes,0);eq(manager:Count(),1);unavailable(view,items);clear()
state({{[dataKeyID]='5',[dataKeyNum]=0}})
view,items=inline('1008',7,21,12);gate=false;tap(items[3]);eq(routes,0);unavailable(view,items);clear()
state({{[dataKeyID]='5',[dataKeyNum]=0}})
view,items=inline('1008',7,21,12);before=H.snapshot(data);tap(items[3]);eq(routes,1);eq(manager:Count(),0);eq(H.snapshot(data),before)
state({{[dataKeyID]='5',[dataKeyNum]=0}})
view,items=regular({lack('1017',22),lack('1008',7)});local owner=view._dialogueLifecycle
assert(texts(view):find('铁可生产',1,true),'mixed missing list identifies only producible iron')
data[roleProducerQueue]={};tap(items[#items]);eq(routes,0);eq(manager:Count(),1);eq(view._dialogueLifecycle,owner,'rebuild preserves modal owner')
assert(texts(view):find('暂无已解锁的生产途径',1,true));view:close();finish(view);eq(manager:Count(),0)
state({{[dataKeyID]='2',[dataKeyNum]=0}})
view,items=regular({lack('1005',2)});gate=false;tap(items[2]);eq(routes,0);eq(manager:Count(),1)
assert(texts(view):find('暂无已解锁的生产途径',1,true));clear()
state({{[dataKeyID]='15',[dataKeyNum]=0}})
view,items=regular({lack('1022',1)});before=H.snapshot(data);tap(items[#items]);eq(routes,1);eq(manager:Count(),0);eq(H.snapshot(data),before)
print('PASS stale queue/gate checks, mixed-resource captions, production-only row, non-building worker navigation and modal rebuild/teardown')

-- Invoke original payment/grant callbacks. Only the receipt wording changes.
for _,case in ipairs({{'1017',22,66,0},{'1008',7,21,5}})do
    local id,quantity,cost,owned=unpack(case);state();data[rolePack][id]=owned
    MaterialView.instance=nil
    view,items=inline(id,quantity,cost,quantity+owned);tap(items[2]);finish(view)
    eq(data[roleMoney],100-cost,'unchanged exact price');eq(data[rolePack][id],owned+quantity,'unchanged exact grant')
    eq(toast,'购买成功！'..resources[id].name..'+'..quantity,'receipt uses granted quantity, not spent gold');eq(manager:Count(),0)
end
state();data[roleMoney]=11;view,items=inline('1017',22,66,22);before=H.snapshot(data);tap(items[2]);finish(view)
eq(H.snapshot(data),before,'failed buy has no debit/grant');eq(toast,'缺少金币X55');eq(manager:Count(),0)
-- Existing ordinary multi-material purchase still reflushes and keeps its gate.
state();local rows={lack('1008',7),lack('1017',22)}
view,items=regular(rows);owner=view._dialogueLifecycle;tap(items[2]);eq(data[roleMoney],79);eq(data[rolePack]['1008'],7)
eq(#rows,1);eq(rows[1].mtId,'1017');eq(view._dialogueLifecycle,owner);eq(manager:Count(),1);clear()
print('PASS unchanged successful/failed purchase accounting and ordinary partial purchase; inline receipts show 22 leather / 7 iron')

-- Original nested crafting callbacks still charge only their original inputs.
local currentDetail={isHaveInfo=true,bottomInfoBox=H.node('Tooltip'),infoBoxLabel=cc.LabelTTF:create('',BoldFont,26)}
BaseView.showInfoBox(currentDetail,'still valid starter details')
state();view,items=create(function()return MaterialView:create(1,'1049',0,1,dm:getStoreUnlockTable(),1,H.node('Cell'),1)end)
tap(items[#items]);eq(toast,'还缺铁，点击材料查看获取方式','missing raw material explains acquisition');eq(writes,0)
tap(items[#items-1]);finish(view)
assert(currentDetail.bottomInfoBox:isVisible());eq(currentDetail.infoBoxLabel:getString(),'still valid starter details','failed or cancelled materials do not clear valid crew detail')
state();data[rolePack]={['1008']=12,['1007']=10};ChangeJobView.instance=nil
view,items=create(function()return MaterialView:create(1,'1049',0,1,dm:getStoreUnlockTable(),1,H.node('Cell'),1)end)
tap(items[#items]);finish(view);eq(data[rolePack]['1049'],1);eq(data[rolePack]['1008'],0);eq(data[rolePack]['1007'],0);eq(manager:Count(),0)
-- Execute the real row-touch closure, so a retained cell tag resolves the
-- current row rather than replaying a copied tooltip after promotion.
local train=read(root..'TrainMode.lua')
local touchStart=assert(train:find('self.tableview:registerScriptHandler(function(view, cell)',1,true))
touchStart=assert(train:find('\n',touchStart,true))+1
local touchEnd=assert(train:find('    end, cc.TABLECELL_TOUCHED)',touchStart,true))
local touchFor=assert(loadstring('return function(self,SkillData,CrewSkillDetails) return function(view,cell)\n'..train:sub(touchStart,touchEnd-1)..'\nend end','@real-train-row-touch'))()
local details=dofile(root..'CrewSkillDetails.lua')
local skillCSV,buffCSV=packagedCSV('skillAttribute'),packagedCSV('buff')
for _,count in ipairs({1,2})do
    state();local crew={['100']={[dataKeyID]='100',[dataKeyNum]=count}};data[roleSoildierQueue]=crew
    data[roleSelectUnit]={['10100']=count,['10124']=1,['1005']=22}
    crew['124']={[dataKeyID]='124',[dataKeyNum]=1}
    local page=setmetatable({data=crew,csvData=soldiers,bufData=buffCSV,tableview={reloadData=function()end},
        isHaveInfo=true,showInfoBox=BaseView.showInfoBox,bottomInfoBox=H.node('Tooltip'),
        infoBoxLabel=cc.LabelTTF:create('',BoldFont,26)},{__index=TrainLayer})
    page:setDataKey();local index;for i=1,#page.dataIndex do if page:getDataKeyByIndex(i)=='100'then index=i end end
    local cell=H.node('Cell');cell:setTag(index);local touch=touchFor(page,skillCSV,details);touch(nil,cell)
    assert(page.bottomInfoBox:isVisible() and page.infoBoxLabel:getString():find('生命：5 威力：1 速度：4.3',1,true),'starter details initially accurate')
    local otherTooltip=H.node('OtherTooltip');local otherText=cc.LabelTTF:create('unrelated',BoldFont,26)
    page:changeJobCallBack(soldiers['101'],index)
    assert(not page.bottomInfoBox:isVisible());eq(page.infoBoxLabel:getString(),'','promotion clears only stale page detail');eq(page.bIsFirstClick,false)
    cell:setTag(#page.dataIndex+1);touch(nil,cell)
    assert(not page.bottomInfoBox:isVisible());eq(page.infoBoxLabel:getString(),'','stale removed row tag cannot revive old detail')
    assert(otherTooltip:isVisible());eq(otherText:getString(),'unrelated','unrelated UI is untouched')
    eq(crew['101'][dataKeyNum],1);eq(data[roleSelectUnit]['10101'],nil,'no automatic embark')
    if count==1 then eq(data[roleSelectUnit]['10100'],nil)else eq(data[roleSelectUnit]['10100'],1)end
    eq(data[roleSelectUnit]['10124'],1,'other selected profession preserved');eq(data[roleSelectUnit]['1005'],22,'selected food preserved')
    eq(toast,'水手进阶成功！\n请在出航整备中重新编入','specific profession and manual re-embark explained')
    local sailorIndex
    for i=1,#page.dataIndex do if page:getDataKeyByIndex(i)=='101'then sailorIndex=i end end
    cell:setTag(sailorIndex);touch(nil,cell)
    assert(page.bottomInfoBox:isVisible() and page.infoBoxLabel:getString():find('生命：6 威力：3 速度：3.8',1,true),'new row touch shows actual sailor properties')
    if count==2 then
        for i=1,#page.dataIndex do if page:getDataKeyByIndex(i)=='100'then cell:setTag(i)end end
        touch(nil,cell);assert(page.infoBoxLabel:getString():find('生命：5 威力：1 速度：4.3',1,true),'remaining starter row still shows its own actual properties')
    end
end
state();local noTooltipCrew={['100']={[dataKeyID]='100',[dataKeyNum]=1}}
data[roleSoildierQueue]=noTooltipCrew;data[roleSelectUnit]={['10100']=1}
local noTooltip=setmetatable({data=noTooltipCrew,csvData=soldiers,tableview={reloadData=function()end}},{__index=TrainLayer})
noTooltip:setDataKey();noTooltip:changeJobCallBack(soldiers['101'],1)
eq(noTooltipCrew['101'][dataKeyNum],1,'promotion tolerates absent initial tooltip nodes')
eq(manager:Count(),0,'promotion creates no extra dialog')
print('PASS original crafting costs, clear raw-material feedback and one/two-starter promotion selection invariants without added modal/navigation')
print('PASS promotion clears only its stale tooltip, and real row-touch callbacks reopen accurate sailor / remaining starter details')
