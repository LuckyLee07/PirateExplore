-- Production EventLayer callbacks with actual packaged enemies, no GUI/save.
local Node={}
local function node()return setmetatable({children={},visible=true,text='',scale=1,pos={x=0,y=0}}, {__index=Node})end
function Node:addChild(child)self.children[#self.children+1]=child end
function Node:setString(text)self.text=text end
function Node:getString()return self.text end
function Node:setVisible(value)self.visible=value end
function Node:isVisible()return self.visible end
function Node:setFontSize(size)self.fontSize=size end
function Node:setColor(color)self.color=color end
function Node:setPosition(pos)self.pos=pos end
function Node:setScale(scale)self.scale=scale end
function Node:setDimensions(size)self.dimensions=size end
function Node:registerSingleCLick(callback)self.callback=callback end
function Node:getContentSize()
 local _,characters=self.text:gsub('[^\128-\191]','')
 local width=characters*(self.fontSize or 22)
 local lines=1
 if self.dimensions then lines=math.max(1,math.ceil(width/self.dimensions.width));width=math.min(width,self.dimensions.width)end
 return{width=width,height=lines*(self.fontSize or 22)}
end
MasterTheme={colors={paper={}},label=function(text,size)local n=node();n.text=text;n.fontSize=size;return n end}
local viewport={width=480,height=800}
cc={c4b=function(...)return{...}end,c3b=function(...)return{...}end,p=function(x,y)return{x=x,y=y}end,
 LayerColor={create=node},Layer={create=node},Node={create=node},
 Director={getInstance=function()return{getVisibleSize=function()return viewport end}end}}
dofile('src/engine/cocos2d-x/cocos/scripting/lua-bindings/script/extern.lua')
local originalRequire=require;require=function()return true end
dofile('bin/res/scripts/LuaClass/EventLayer.lua');require=originalRequire
local fixture=dofile(assert(os.getenv('PIRATE_ENEMY_PREVIEW_FIXTURE')))
local function equal(actual,expected,why)assert(actual==expected,why..': '..tostring(actual)..' ~= '..tostring(expected))end
roleMapInfo='map';DataManager={getInstance=function(self)return self end,getRoleData=function()return{curIndex=1}end}
FightFighterData={new=function()return{}end};FightCannonData={new=function()return{}end}
FightDataManager={getInstance=function(self)return self end,enemyFighters={},
 clearEnemyData=function(self)self.enemyFighters={}end,
 addEnemyFighterData=function(self,data)self.enemyFighters[#self.enemyFighters+1]=data end}
local reads,rolls=0,0
dataController={getSoilderInfoById=function(id)reads=reads+1;return assert(fixture.soldiers[tostring(id)])end,
 getResourceValueByIdAndKey=function()return'original reward'end}
getRandomNumByRange=function(range)rolls=rolls+1;return range.min end
local view=EventLayer.new()
view.title=node();view.description=node();view.midTip=node()
view.buttons={node(),node()};view.buttonTips={node(),node()}
view.controller={};view.buttonController=node()
view.description:setDimensions({width=432});view.midTip:setDimensions({width=432})
view:refreshLayerByInfo(fixture.reef,false)
assert(not view.enemyPreview,'entry does not pre-roll or expose a future enemy')
equal(reads,0,'entry has no soldier lookup');equal(rolls,0,'entry has no drop RNG')
for floor,id in ipairs({'10002','10098'})do
 local row=fixture.soldiers[id];local beforeReads,beforeRolls=reads,rolls
 view.enemysIndex=floor;view:getsAndSetsEnemyLayerInfoByEnemy({id})
 local data=FightDataManager.enemyFighters[1]
 equal(view.enemyNameLabel:getString(),'当前敌人 · '..data.name,'current prepared name')
 equal(view.enemyStatsLabel:getString(),'开战生命 '..data.hp..' · 攻击 '..data.power,'current prepared stats')
 equal(view.description:getString(),row.description,'current narrative retained')
 equal(data.hp,tonumber(row.hp),'combat HP unchanged')
 equal(data.power,tonumber(row.attack),'combat attack unchanged')
 equal(reads-beforeReads,1,'one preparation lookup only')
 equal(rolls-beforeRolls,#row.dropitems,'original drop rolls only')
 local drop=FightDataManager.dropData
 view:refreshEnemyPreview(data)
 equal(FightDataManager.dropData,drop,'presentation retains exact drop data')
 equal(reads-beforeReads,1,'redraw has no lookup')
 equal(rolls-beforeRolls,#row.dropitems,'redraw has no RNG')
end
view:getsAndSetsEnemyLayerInfoByEnemy({'10098',coefficient='1.25'})
equal(FightDataManager.enemyFighters[1].hp,8,'HP coefficient is rounded up')
equal(FightDataManager.enemyFighters[1].power,3,'attack coefficient is rounded up')
equal(view.enemyStatsLabel:getString(),'开战生命 8 · 攻击 3','shows effective, not CSV values')
local prepared=FightDataManager.enemyFighters[1]
for _,width in ipairs({480,540})do
 viewport.width=width;viewport.height=width==480 and 800 or 900
 view.midTip:setDimensions({width=width-48});view.description:setDimensions({width=width-48})
 view.midTip:setString(string.rep('很长的现场说明',20));view.description:setString(string.rep('很长的当前敌人说明',20))
 local data={name=string.rep('很长的敌人名称',10),hp=999999999999,power=999999999999}
 view:refreshEnemyPreview(data)
 for _,label in ipairs({view.enemyNameLabel,view.enemyStatsLabel})do
  assert(label:getContentSize().width*label.scale<=width-48,'long name/stats fit viewport')
  equal(label.color,nil,'paper default is not replaced by low-contrast rank hue')
 end
 assert(view.midTip:getContentSize().height*view.midTip.scale<=72,'context has reserved height')
 assert(view.description:getContentSize().height*view.description.scale<=60,'enemy prose has reserved height')
 local nameBottom=view.enemyNameLabel.pos.y-view.enemyNameLabel:getContentSize().height*view.enemyNameLabel.scale/2
 local statsTop=view.enemyStatsLabel.pos.y+view.enemyStatsLabel:getContentSize().height*view.enemyStatsLabel.scale/2
 assert(nameBottom>statsTop,'name and stats do not overlap')
 local statsBottom=view.enemyStatsLabel.pos.y-view.enemyStatsLabel:getContentSize().height*view.enemyStatsLabel.scale/2
 local proseTop=view.description.pos.y+view.description:getContentSize().height*view.description.scale/2
 assert(statsBottom>proseTop,'stats and bounded prose do not overlap')
 local proseBottom=view.description.pos.y-view.description:getContentSize().height*view.description.scale/2
 assert(proseBottom>viewport.height*.6-50,'prose stays above original battle button')
end
for _,bad in ipairs({{}, {name='unknown',hp=3}, {name='unknown',hp=0,power=1},
 {name='unknown',hp=0/0,power=1},{name='unknown',hp=3,power=math.huge}})do
 view:refreshEnemyPreview(bad);equal(view.enemyPreview:isVisible(),false,'invalid preview hidden, no guessed data')
end
view:refreshEnemyPreview(prepared);view:hide()
equal(view.enemyPreview:isVisible(),false,'hide clears preview')
equal(view.description.scale,1,'hide resets prose scale');equal(view.midTip.scale,1,'hide resets context scale')
view:refreshEnemyPreview(prepared);view:showTipOccupiedLayer(fixture.reef)
equal(view.enemyPreview:isVisible(),false,'completion clears preview')
view:refreshEnemyPreview(prepared);view:refreshLayerByInfo(fixture.reef,true)
equal(view.enemyPreview:isVisible(),false,'occupied revisit clears preview')
view:refreshEnemyPreview(prepared);view:refreshLayerByInfo(fixture.pub,false)
equal(view.enemyPreview:isVisible(),false,'noncombat reuse clears preview')
-- Ship route prepares a later boarding foe too; never leak it into a preview.
view:refreshEnemyPreview(prepared);view:getsAndSetsEnemyLayerInfoByEnemy({'21008','10002'})
equal(view.enemyPreview:isVisible(),false,'ship route suppresses stale boarding preview')
equal(FightDataManager.enemyCanoon.name,fixture.soldiers['11005'].name,'original ship replacement retained')
print('PASS current prepared enemy preview: packaged floors, coefficient/rounding, RNG preservation, ship suppression, viewport bands and lifecycle cleanup')
