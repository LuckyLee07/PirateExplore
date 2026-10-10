-- Real initPlayer/startJumpAction/geometry + real AdventureSea event gating.
-- No source edits. Sprite/map/view drawing and movement dispatch are observed.
local f=assert(io.open('tools/tests/adventure_state_audit.lua'));local h=f:read('*a');f:close();h=assert(h:match('^(.-)\nfixture%(%{%[roleGuideStep%]'))
local E=assert(loadstring(h..'\nreturn {A=A,dm=dm,fixture=fixture,reload=reload,disk=function()return disk end}'))();local A,dm=E.A,E.dm
DataManager={getInstance=function()return dm end}
cc={p=function(x,y)return {x=x,y=y}end};Right={x=32,y=0}
local shown=0
package.loaded['LuaClass/AdventureDialog']={show=function(_,_,options,owner)shown=shown+1;owner.adventureDialog={};return owner.adventureDialog end}
local S=require 'LuaClass/AdventureSea'
local f=assert(io.open('bin/res/scripts/LuaClass/Explore.lua'));local source=f:read('*a');f:close();Explore={playerTitlePosition={x=0,y=0}}
for _,name in ipairs({'initPlayer','startJumpAction','tileCoordForPosition','positionForTilePosition','coordinateStandardizationByPosition'}) do
 local fn=assert(source:match('(function Explore:'..name..'%([^\n]*.-)\nend'))..'\nend'
 assert(loadstring("local AdventureSea=require 'LuaClass/AdventureSea'\n"..fn))()
end
local function owner()
 local sprite={x=0,y=0,setPosition=function(self,p)self.x=p.x;self.y=p.y end,getPosition=function(self)return self.x,self.y end}
 return setmetatable({mapIndex=1,player=sprite,map={getTileSize=function()return {width=32,height=32}end,getMapSize=function()return {width=21,height=21}end,getObjectGroup=function()return {getObject=function()return {x=336,y=336}end}end},setViewpointCenter=function(self,p)self.camera={x=p.x,y=p.y}end,moveLayer={stopAllActions=function()end},tryToMoveForDirction=function(self,d)self.reentered=(self.reentered or 0)+1;self.reentryDirection=d end},{__index=Explore})
end
local function setup(willFight,atSea)
 local map={curIndex=1,mapIndex=1,playerTitlePosition=atSea and {x=9,y=7} or nil,willFight=willFight}
 E.fixture({[roleMapInfo]=map});assert(A.depart(dm,{['1005']=10,['10100']=1}))
 local s=A.getState(dm);s.tutorialPoint={x=9,y=7,mapIndex=1};s.tutorialPath={{x=10,y=10},{x=9,y=7}};assert(A.commit(dm,{[A.KEY]=s}));E.reload()
 return dm:getRoleData(roleMapInfo)
end
local snapshot=setup(nil,true);local o=owner();o:initPlayer()
assert(o.playerTitlePosition.x==9 and o.playerTitlePosition.y==7)
assert(o:tileCoordForPosition(cc.p(o.player:getPosition())).x==9)
assert(A.isTutorialProtected(dm,1,o.playerTitlePosition))
assert(snapshot.playerTitlePosition.x==9 and snapshot.playerTitlePosition.y==7)
o:startJumpAction();assert(shown==1 and not o.reentered,'ordinary cold arrival opens exact-point wreck without fake movement')
print('PASS real normal cold init synchronizes logical/sprite9,7 and scene-enter event correctly recognizes persisted wreck tile')
local snapshot=setup(1,true);local originalGet=dm.getRoleData
-- A retained role snapshot must not be mutated when applying visual left offset.
function dm:getRoleData(k)if k==roleMapInfo then return snapshot end;return originalGet(self,k)end
local before=E.disk();local o=owner();o:initPlayer()
assert(o.playerTitlePosition.x==8 and o.playerTitlePosition.y==7,'logical point respects original battle-reentry left offset')
local visual=o:tileCoordForPosition(cc.p(o.player:getPosition()));assert(visual.x==8 and visual.y==7)
assert(snapshot.playerTitlePosition.x==9 and snapshot.playerTitlePosition.y==7,'do not alias mutate saved target')
o:startJumpAction();assert(o.reentered==1 and o.reentryDirection==Right and shown==1,'battle reentry must take original Right branch and not open wreck')
assert(E.disk()==before and snapshot.willFight==1);dm.getRoleData=originalGet;E.reload();assert(dm:getRoleData(roleMapInfo).playerTitlePosition.x==9)
print('PASS real battle cold init respects8,7 offset, retains saved9,7, reenters Right exactly once, cannot auto-open wreck or clear battle flag')
setup(nil,false);local o=owner();o:initPlayer();assert(o.playerTitlePosition.x==10 and o.playerTitlePosition.y==10 and o.bothPosition.x==10);o:startJumpAction();assert(shown==1 and not o.reentered)
print('PASS fresh port spawn synchronizes sprite/logical/start tile and does not auto-open remote wreck')
