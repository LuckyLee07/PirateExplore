-- Production sea UI geometry and chapter scoping; Cocos nodes mocked, not pixels.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/home_master_regression.lua');local stop=assert(source:find("\ndofile(root..'Header.lua')",1,true))
local H=assert(loadstring(source:sub(1,stop-1)..'\nreturn {node=node,methods=Node}'))()
local A=dofile('bin/res/scripts/LuaClass/AdventureProgress.lua')
rolePackSize='capacity';roleBattleQueue='party';dataKeyID='id';dataKeyNum='num'
local state={version=1,enabled=true,voyage=1,activeVoyage=1,objective='rescue',tutorialPoint={x=9,y=7,mapIndex=1},tutorialPath={{x=10,y=10},{x=10,y=9},{x=10,y=8},{x=9,y=8},{x=9,y=7}}}
local data={[A.KEY]=state,capacity=20,party={['100']=1}}
local dm={getRoleData=function(_,k)return data[k]end}
DataManager={getInstance=function()return dm end}
local nav={query=function()return {port={x=10,y=10}}end,supplyClue=function()return {text='已探铁矿：东'}end,gateClue=function()return {status='ok',text='章门在东'}end}
local opened=0
require=function(name)
 if name=='LuaClass/AdventureProgress' then return A end
 if name=='LuaClass/AdventureNavigation' then return nav end
 if name=='LuaClass/AdventureNavigationView' then return {refresh=function()end} end
 if name=='LuaClass/KnownRoute' then return dofile('bin/res/scripts/LuaClass/KnownRoute.lua') end
 if name=='LuaClass/AdventureDialog' then return {show=function(_,_,_,owner)opened=opened+1;owner.adventureDialog=H.node()end}end
 return true
end
-- Model native MenuItemLabel::setLabel: child bottom-left, captured content size.
cc.MenuItemLabel={create=function(_,label)local n=H.node('MenuItemLabel');label:setAnchorPoint(cc.p(0,0));n:addChild(label);n:setContentSize(label:getContentSize());n:setAnchorPoint(cc.p(.5,.5));return n end}
SeaChartTheme={colors={white=cc.c3b(255,255,255),ink=cc.c3b(0,20,30)},panel=function(w,h)local n=H.node();n:setContentSize(cc.size(w,h));return n end,fit=function()end}
local S=dofile('bin/res/scripts/LuaClass/AdventureSea.lua')
for _,width in ipairs({480,540})do
 screenSize={width=width,height=width*5/3};local u=width/640
 local owner={mapIndex=1,tipLayer=H.node(),playerTitlePosition={x=9,y=7},adventureHudBottom=222*u,fogManager={data={}},map={getMapSize=function()return {width=20}end}}
 S.refresh(owner,0)
 local item=owner.adventureObjectiveItem;local box=item:getBoundingBox()
 assert(box.width>0 and box.height>0 and box.x>=0 and box.x+box.width<=width,'fixed nonzero centered real hit rectangle')
 assert(owner.adventureObjectiveLabel:getPositionX()==0,'child stays in item-local coordinates')
 assert(owner.adventureObjectiveLabel:getContentSize().width==box.width)
 local patrol=owner.adventurePatrolLabel;assert(patrol:getPositionY()-patrol:getContentSize().height/2>box.y+box.height,'patrol and objective rows do not overlap')
 assert(S.tryEvent(owner,true));assert(opened>0 and owner.adventureDialog)
 owner.adventureDialog=nil;state.firstEventReturned=true;state.firstReturnClaimed=true;data.capacity=30;owner.mapIndex=2
 S.refresh(owner,0);assert(not S.wreckAvailableHere(dm,2));assert(not S.tryEvent(owner,true))
 local text=owner.adventureObjectiveLabel:getString();assert(text:find('第一章',1,true) and not text:find('港口北',1,true),'chapter two cannot inherit first-chapter wreck bearing')
 state.firstEventReturned=nil;state.firstReturnClaimed=nil;data.capacity=20
end
print('PASS production Sea fixed-width menu hitbox/child anchors/separate patrol rows at 480 and 540; manual wreck reopen; first-chapter event never targeted as a chapter-two point')
-- Real completion callback: event comes after the move/food operation, only
-- when ready and outside battle/hunger; no per-frame trigger is introduced.
local exploreSource=read('bin/res/scripts/LuaClass/Explore.lua')
Explore={}
local fn=assert(exploreSource:match('(function Explore:moveEnd%(%s*%).-)\nfunction Explore:tileCoordForTilePosition'))
assert(loadstring("local AdventureSea=...\n"..fn))(S)
local owner={mapIndex=1,playerTitlePosition={x=9,y=7},statue='ready',moveWaitingQueue={},moveDirectionQueue={},getNumberOfRunningActions=function()return 0 end,eventManger={isMinesweeper=false}}
local before=opened;Explore.moveEnd(owner);assert(opened==before+1,'completed movement auto-opens wreck')
for _,case in ipairs({{statue='Triggering'},{statue='ready',isHungry=true},{statue='ready',isMinesweeper=true}})do
 owner.adventureDialog=nil;owner.statue=case.statue;owner.isHungry=case.isHungry;owner.eventManger.isMinesweeper=case.isMinesweeper;local count=opened
 Explore.moveEnd(owner);assert(opened==count,'no event over battle/hunger')
end
assert(S.isHudPoint({adventureHudBottom=200},{x=100,y=300}));assert(not S.isHudPoint({adventureHudBottom=200},{x=100,y=600}))
-- Real leave action and all four legacy-only guide gates remain bypassable on
-- new saves without inventing guide step 71 or dereferencing a missing guide.
local eventSource=read('bin/res/scripts/LuaClass/EventLayer.lua');EventLayer={}
local leave=assert(eventSource:match('(function EventLayer:leaveToExploreMap%(%s*arg%s*%).-)\nend'))..'\nend'
GuideController={getInstance=function()return {getIsHaveStep=function()return false end}end};getExplor=function()return {}end
assert(loadstring('local AdventureProgress=...\n'..leave))(A)
local left=0;local layer={controller={allEventsHasTriggered=function()left=left+1 end,anEventHasToGiveUp=function()left=left+1 end}}
EventLayer.leaveToExploreMap(layer);assert(left==1)
data[A.KEY]=nil;EventLayer.leaveToExploreMap(layer);assert(left==1,'legacy guide gate unchanged');data[A.KEY]=state
local _,gates=eventSource:gsub('not AdventureProgress.getState%(DataManager:getInstance%(%)%).enabled and not GuideController:getInstance%(%):getIsHaveStep%(71%)','')
assert(gates==4,'all four old guide branches scoped to legacy')
print('PASS real moveEnd event timing and battle/hunger exclusion; new HUD region excluded from map touches; real EventLayer leave plus four legacy-guide guards')
-- Use the complete production initPlayer saved-position branch. Its legacy
-- battle-reentry offset belongs to the live sprite, never the saved table.
roleMapInfo='map'
local init=assert(exploreSource:match('(function Explore:initPlayer%(%s*%).-)\n%-%- function Explore:initStrongHold'))
assert(loadstring(init))()
for _,battle in ipairs({false,true})do
 local saved={x=9,y=7};data.map={playerTitlePosition=saved,willFight=battle and 1 or nil}
 local owner={player=H.node(),playerTitlePosition={x=0,y=0},positionForTilePosition=function(_,p)return {x=p.x*64,y=p.y*64}end,tileCoordForPosition=function(_,p)return {x=p.x/64,y=p.y/64}end,setViewpointCenter=function()end}
 Explore.initPlayer(owner)
 assert(owner.playerTitlePosition.x==(battle and 8 or 9) and owner.playerTitlePosition.y==7,'live logical position synchronized on cold load')
 assert(saved.x==9 and saved.y==7,'saved position table is never offset in place')
end
print('PASS real initPlayer cold-position synchronization, including existing battle-reentry offset without mutating saved coordinates')
