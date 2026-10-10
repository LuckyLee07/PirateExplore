-- Called by occupied_event_copy_regression.py, which supplies actual packaged
-- stronghold copy. Also supports the existing real Cocos/LuaEngine harness.
local native=type(nativeEnter)=='function'
if native then require('extern') else
    local Node={}
    local function node()return setmetatable({children={},visible=true,text=''}, {__index=Node})end
    function Node:addChild(child)self.children[#self.children+1]=child end
    function Node:setString(text)self.text=text end
    function Node:getString()return self.text end
    function Node:setVisible(visible)self.visible=visible end
    function Node:isVisible()return self.visible end
    function Node:setFontSize(size)self.fontSize=size end
    function Node:setColor(color)self.color=color end
    function Node:setPosition(pos)self.pos=pos end
    function Node:setScale(scale)self.scale=scale end
    function Node:getContentSize()return{width=#self.text*(self.fontSize or 22)/3,height=self.fontSize or 22}end
    MasterTheme={colors={paper={}},label=function(text,size)local n=node();n.text=text;n.fontSize=size;return n end}
    viewport={width=540,height=900}
    cc={c4b=function(r,g,b,a)return{r=r,g=g,b=b,a=a}end,LayerColor={create=function()return node()end},c3b=function(r,g,b)return{r=r,g=g,b=b}end,p=function(x,y)return{x=x,y=y}end,Layer={create=node},Node={create=node},
        LabelTTF={create=node},Director={getInstance=function()return{getVisibleSize=function()return viewport end}end}}
    dofile('src/engine/cocos2d-x/cocos/scripting/lua-bindings/script/extern.lua')
end
local originalRequire=require
require=function()return true end
dofile(os.getenv('PIRATE_EVENT_LAYER_SOURCE') or 'bin/res/scripts/LuaClass/EventLayer.lua')
dofile('bin/res/scripts/LuaClass/EventManger.lua')
require=originalRequire
local fixture=dofile(assert(os.getenv('PIRATE_EVENT_COPY_FIXTURE')))
local function equal(actual,expected,why)assert(actual==expected,why..': '..tostring(actual)..' ~= '..tostring(expected))end
local function label()return cc.LabelTTF:create('', 'Arial', 24)end
local function button()
    local n=cc.Node:create()
    function n:registerSingleCLick(callback)self.callback=callback end
    return n
end
local scene=cc.Node:create()
if native then scene:retain();nativeEnter(scene)end
local status='00'
ExploreDataManager={getInstance=function(self)return self end,
    getPosKeyByPosition=function()return '_12_8' end,
    getValueByKeys=function(_,group,key,field)
        assert(group=='titlesInfo' and key=='_12_8' and field=='statues');return status
    end}
roleMapInfo='map';DataManager={getInstance=function(self)return self end,
    getRoleData=function(_,key)assert(key==roleMapInfo);return{curIndex=1}end,
    setRoleData=function()error('copy regression must not mutate persisted state')end}
GuideController={getInstance=function(self)return self end,getIsHaveStep=function()return true end}
getExplor=function()return{}end
FightFighterData={new=function()return{}end}
FightDataManager={getInstance=function(self)return self end,
    clearEnemyData=function()end,addEnemyFighterData=function()end}
dataController={getSoilderInfoById=function()return{attack='1',hp='3',name='fixture enemy',
    attackSpeed='2',dodge='0',description='fixture combat description',dropitems={{'0'}}}end}
local function fresh(info)
    local view=EventLayer.new();scene:addChild(view)
    view.title=label();view.description=label();view.midTip=label();view.midTip:setVisible(false)
    view.buttons={button(),button()};view.buttonTips={label(),label()}
    view.buttonController=cc.Node:create()
    for _,n in ipairs({view.title,view.description,view.midTip,view.buttons[1],view.buttons[2],
        view.buttonTips[1],view.buttonTips[2],view.buttonController})do view:addChild(n)end
    local controller=EventManger.new();scene:addChild(controller)
    controller.layer=view;controller.owner={playerTitlePosition=cc.p(12,8),mapIndex=1}
    controller.curStrongholdData=info;controller.eventWaitingQueue={};controller.enemys={}
    controller.willTip=false;controller.isBoss=false;controller.isMapEnter=false;controller.isMinesweeper=false
    view:setController(controller)
    info.requiredtool={{'0'}};info.dropitems={{'0'}}
    return view,controller
end
for _,info in ipairs(fixture.materials)do
    status='00'
    local view,controller=fresh(info)
    view:refreshLayerByInfo(info,controller:checkOccupiedByPosition(controller.owner.playerTitlePosition))
    equal(view.description:getString(),info.description..' ','unoccupied description '..info.name)
    equal(view.buttonTips[1]:getString(),'占领','unoccupied action '..info.name)
    controller.enemys={{'fixture enemy'},{'fixture enemy'}}
    controller:anEventHasTriggered()
    equal(view.midTip:isVisible(),true,'first enemy retains its context')
    equal(view.midTip:getString(),info.description,'combat uses original unoccupied prose')
    equal(view.description:getString(),'fixture combat description','combat description retained')
    controller:anEventHasTriggered()
    equal(view.midTip:isVisible(),true,'last enemy still retains context')
    equal(#controller.enemys,0,'real controller consumes both enemy entries')
    equal(controller.willTip,true,'real last-enemy gate requests completion')
    controller:anEventHasTriggered()
    equal(view.midTip:isVisible(),false,'completed '..info.name..' must hide stale monster occupation')
    equal(view.description:getString(),info.occupationdescription,'original completed prose '..info.name)
    equal(view.buttonTips[1]:getString(),'离 开','original leave label')
    equal(view.buttons[2]:isVisible(),false,'completion keeps one action')
    equal(status,'00','presentation does not prematurely commit occupation')
    local leave=0;controller.anEventHasTriggered=function()leave=leave+1 end
    view.buttons[1].callback();equal(leave,1,'leave still invokes the original controller transition')
    status='11';view:hide()
    view:refreshLayerByInfo(info,controller:checkOccupiedByPosition(controller.owner.playerTitlePosition))
    equal(view.description:getString(),info.occupationdescription..' ','owned revisit prose')
    equal(view.buttonTips[1]:getString(),'进入','owned revisit action')
    equal(view.midTip:isVisible(),false,'owned revisit has no stale combat context')
    status='00';view:hide();view:refreshLayerByInfo(info,false)
    equal(view.description:getString(),info.description..' ','next unowned event restores original prose')
end
print('PASS all nine packaged material sites: unoccupied combat, actual two-enemy completion, owned revisit and next unowned event')

local pub=fresh(fixture.pub);pub:refreshLayerByInfo(fixture.pub,false)
equal(pub.description:getString(),fixture.pub.description..' ','tavern non-combat description unchanged')
equal(pub.buttonTips[1]:getString(),'进入酒馆','tavern action unchanged')
equal(pub.midTip:isVisible(),false,'tavern does not acquire combat subtitle')
local boss=fresh(fixture.boss)
boss.midTip:setString(fixture.boss.description);boss.midTip:setVisible(true)
boss:showTipOccupiedLayer(fixture.boss)
equal(boss.description:getString(),fixture.boss.occupationdescription,'boss completion retains original prose')
equal(boss.midTip:isVisible(),false,'shared boss completion also clears stale combat subtitle')
print('PASS non-material tavern route and shared boss completion retain their original descriptions/actions')
-- Real reef 3106 used a skeleton scene description with octopus/strongman
-- enemies. Correct only that exact obsolete copy, never combat or history.
local reef=fixture.reef
local original=reef.description
local history={'unchanged previous skeleton battle'};SystemInfoData=history
local view=fresh(reef)
view:refreshLayerByInfo(reef,false)
local corrected='礁石间潜伏着危险的敌人，挡住了前路。'
equal(view.description:getString(),corrected..' ','reef entry has truthful scene copy')
equal(view.midTip:getString(),corrected,'reef combat context matches entry')
equal(view.difficultyLabel:getString(),'绿色 · 中级据点','real reef rank visible before first fight')
equal(reef.description,original,'display does not mutate source record')
local enemyData
FightDataManager.addEnemyFighterData=function(_,data)enemyData=data end
local function matrix(value)
    local result={};for row in value:gmatch('[^;]+')do
        local cells={};for cell in row:gmatch('[^_]+')do cells[#cells+1]=cell end
        result[#result+1]=cells
    end;return result
end
dataController.getSoilderInfoById=function(id)
    local source=assert(fixture.reefEnemies[id]);local copy={}
    for k,v in pairs(source)do copy[k]=v end
    copy.dropitems=matrix(source.dropitems);return copy
end
dataController.getResourceValueByIdAndKey=function()return 'original drop resource' end
getRandomNumByRange=function(range)return range.min end
for level,id in ipairs({'10002','10098'})do
    view.enemysIndex=level
    view:getsAndSetsEnemyLayerInfoByEnemy({id})
    local row=fixture.reefEnemies[id]
    equal(enemyData.soilderId,id,'actual enemy ID preserved')
    equal(enemyData.hp,tonumber(row.hp),'actual enemy HP preserved')
    equal(enemyData.power,tonumber(row.attack),'actual attack preserved')
    equal(view.description:getString(),row.description,'actual current enemy description preserved')
    equal(view.midTip:getString(),corrected,'both floors retain truthful context')
    equal(view.difficultyLabel:isVisible(),true,'rank stays visible on both floors')
    local drops=matrix(row.dropitems)
    for i,drop in ipairs(drops)do
        equal(FightDataManager.dropData[i].id,drop[1],'original reward identity')
        equal(FightDataManager.dropData[i].num,tonumber(drop[2]),'original reward range minimum')
    end
end
view:refreshLayerByInfo(reef,true)
equal(view.description:getString(),reef.occupationdescription..' ','occupied reef untouched')
equal(view.difficultyLabel:isVisible(),false,'occupied rank hidden')
equal(view.difficultyGroup:isVisible(),false,'occupied complete group hidden')
local other=fresh(fixture.otherReef);other:refreshLayerByInfo(fixture.otherReef,false)
equal(other.description:getString(),fixture.otherReef.description..' ','other reef untouched')
reef.description='An intentionally revised future scene description'
view:refreshLayerByInfo(reef,false)
equal(view.description:getString(),reef.description..' ','exact-copy guard does not override future data')
reef.description=original
equal(SystemInfoData,history,'history table unchanged');equal(#history,1,'history retained')
local rankLabels={'白色 · 低级据点','绿色 · 中级据点','蓝色 · 高级据点','紫色 · 精英据点','橙色 · boss据点及特殊据点'}
if not native then
 for _,w in ipairs({480,540})do
  viewport.width=w;viewport.height=w==480 and 800 or 900
  for rank=1,5 do
   for _,name in ipairs({'礁石','一个非常非常长的据点名称用于验证开战前标题和难度提示'})do
    view.title:setString(name..'(第2层)')
    view:refreshDifficulty({especial=tostring(rank),eventFucString='changeToEnemyLayer'},false)
    local label=view.difficultyLabel
    equal(label:getString(),rankLabels[rank],'exact existing rank and color name')
    equal(label.color,MasterTheme.colors.paper,'rank text uses readable paper color')
    equal(view.difficultyGroup:isVisible(),true,'complete group is visible')
    assert((label:getContentSize().width+22)*view.difficultyGroup.scale<=w-48,'marker and text fit together')
    equal(label.pos.x,11,'text and marker group is centered')
    equal(view.difficultyMarker.pos.x,-(label:getContentSize().width+22)/2,'marker precedes text without overlap')
    assert(view.title:getContentSize().width*view.title.scale<=w-48,'long title stays in viewport')
    assert(view.difficultyGroup.pos.y+label:getContentSize().height/2<viewport.height-50-36/2,'rank remains below title')
   end
  end
 end
end
for _,info in ipairs({{especial='6',eventFucString='changeToEnemyLayer'},{especial='0',eventFucString='changeToEnemyLayer'},
 {especial='2',eventFucString='changeToMaterialsLayer'},{eventFucString='changeToEnemyLayer'}})do
 view:refreshDifficulty(info,false);equal(view.difficultyLabel:isVisible(),false,'unknown and non-enemy sites do not invent a rank')
end
view:refreshDifficulty(reef,false);view:showTipOccupiedLayer(reef)
equal(view.difficultyLabel:isVisible(),false,'completion clears difficulty')
equal(view.difficultyGroup:isVisible(),false,'completion hides marker and text together')
print('PASS five original ranks, narrow/wide viewports, long titles, unknown/non-combat and completion hiding')
print('PASS actual reef 3106 scene correction, both real enemies/HP/rewards, other reef, future copy and history preservation')
if native then nativeExit(scene);scene:cleanup();scene:release();nativeDrain()end
