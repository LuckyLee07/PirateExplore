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
    cc={p=function(x,y)return{x=x,y=y}end,Layer={create=node},Node={create=node},
        LabelTTF={create=node},Director={getInstance=function()return{getVisibleSize=function()return{height=1136}end}end}}
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
if native then nativeExit(scene);scene:cleanup();scene:release();nativeDrain()end
