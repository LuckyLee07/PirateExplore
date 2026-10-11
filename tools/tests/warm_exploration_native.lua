-- Isolated real Cocos/EGL shell check. No map/save loaded and no desktop input.
require 'extern';require 'LuaClass/Header'
BoldFont='Noto Serif CJK SC'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('bin/res/scripts/LuaClass/Explore.lua')
local hud=assert(source:match('(function Explore:initTipLayer%(%s*%).-)\nfunction Explore:checkBread'))
local foodCode=assert(source:match('(function Explore:costbread%(%s*%).-)\nfunction Explore:updataCapacityTips'))
local extent=0;local food=20;local writes=0;local brief=0;local returned=0;local quote={kind='free'};local dialog
local state={enabled=true,voyage=1,activeVoyage=1,objective='rescue',tutorialPoint={x=9,y=7,mapIndex=1},tutorialPath={{x=10,y=10},{x=10,y=9},{x=10,y=8},{x=9,y=8},{x=9,y=7}}}
local A={getState=function()return state end,availableEpisode=function()return 'first' end,isTutorialProtected=function()return true end,
 showHarborBrief=function()brief=brief+1 end,quoteReturn=function()return quote end}
local nav={query=function()return {status='at_port',port={x=10,y=10}}end}
package.loaded['LuaClass/AdventureProgress']=A
package.loaded['LuaClass/AdventureNavigation']=nav
package.loaded['LuaClass/AdventureDialog']={show=function(title,detail,options,owner)dialog={title=title,options=options,owner=owner}end}
DataManager={getInstance=function()return {getRoleData=function(_,key)assert(key==roleExtents);return extent end,
 setRoleData=function(_,key,value)assert(key==roleBreadCostDecimal);writes=writes+1 end}end}
SeaChartTheme=require 'LuaClass/SeaChartTheme'
local W=require 'LuaClass/WarmTheme'
local V=require 'LuaClass/AdventureNavigationView'
local Sea=require 'LuaClass/AdventureSea'
Explore={};assert(loadstring('local AdventureProgress=...\n'..hud))(A);assert(loadstring(foodCode))()
topButtonOrderLevel=12;breadCoefficient=0
local function colorEqual(a,b)return a.r==b.r and a.g==b.g and a.b==b.b end
local function visit(node,fn)
 fn(node);for _,child in ipairs(node:getChildren())do visit(child,fn)end
end
local function test(w,h,warm)
 WARM_PIRATE_V1=warm;screenSize=cc.size(w,h);food=20;local u=w/640
 local scene=cc.Scene:create();scene:retain()
 local owner=cc.Layer:create();scene:addChild(owner)
 owner.extent=18;owner.mapIndex=1;owner.statue='ready';owner.jointed={enable=true}
 owner.playerTitlePosition={x=10,y=10};owner.fogManager={data={}}
 owner.map={getMapSize=function()return {width=20}end}
 owner.moveLayer=cc.Node:create();owner:addChild(owner.moveLayer)
 owner.positionForTilePosition=function(_,p)return cc.p(p.x*32+16,640-p.y*32-16)end
 owner.bagController={costSpace=20,limited=20,getBreads=function()return food end,
 costGoodsByGoodsIdAndNum=function(_,id,num)assert(id==1005 and num==1);food=food-num end}
 local cargo,guide,steering=0,0,nil
 owner.goBag=function()cargo=cargo+1 end;owner.showCurMapStrategy=function()guide=guide+1 end
 owner.jointedCalBack=function(_,direction)steering=direction end
 owner.checkBread=function()end;owner.breadCostDecimal=0
 owner.returnToBase=function(_,kind,q)assert(q==quote);returned=returned+1;return false end
 Explore.initTipLayer(owner);owner.chapterTitle:setString('第一章');owner.nameTitle:setString('瓶中船')
 local C=warm and W.colors or SeaChartTheme.colors
 assert(SeaChartTheme.cargoButtonIcon()==(warm and 'cargo' or 'food'),'warm cargo icon matches chest; mode false remains barrel')
 assert(colorEqual(owner.bread:getColor(),warm and C.ink or C.white))
 assert(colorEqual(owner.nameTitle:getColor(),C.ink))
 assert(owner.adventureHudBottom==222*u and owner.adventureHudTop==h-124*u)
 local buttons={};for _,n in ipairs(owner.tipLayer:getChildren())do if n.item then buttons[#buttons+1]=n end end
 assert(#buttons==(warm and 8 or 7),'seven existing contextual controls plus warm-only pause')
 if warm then assert(owner.warmPauseButton and owner.warmPauseButton.label:getString()=='暂歇') end
 for _,n in ipairs(buttons)do local b=n:getBoundingBox();assert(b.x>=-.01 and b.x+b.width<=w+.01 and b.y>=0 and b.y+b.height<=h+.01)end
 -- Existing bottom-HUD indices exclude the separately positioned pause control.
 local original={};for _,n in ipairs(buttons)do if n~=owner.warmPauseButton then original[#original+1]=n end end;buttons=original
 buttons[2].item:activate();buttons[3].item:activate();assert(cargo==1 and guide==1)
 buttons[4].item:activate();assert(steering==UpDiriction)
 steering=nil;owner.statue='Triggering';buttons[5].item:activate();assert(not steering)
 owner.statue='ready';owner.eventManger={layer=cc.Node:create()};owner:addChild(owner.eventManger.layer)
 buttons[6].item:activate();assert(not steering);owner.eventManger.layer:setVisible(false)
 buttons[6].item:activate();assert(steering==RightDircion)
 buttons[1].item:activate();assert(dialog.title=='确认返航' and dialog.owner==owner)
 assert(dialog.options[1].action()==false);dialog=nil
 Explore.costbread(owner);assert(food==19 and owner.bread:getString()=='19' and owner.breadCostDecimal==0)
 assert(colorEqual(owner.bread:getColor(),warm and C.ink or C.white),'food refresh keeps readable warm foreground')
 food=9;Explore.costbread(owner);assert(food==8 and colorEqual(owner.bread:getColor(),C.coral))
 Sea.refresh(owner,0);assert(colorEqual(owner.adventureObjectiveLabel:getColor(),warm and C.ink or C.white))
 assert(colorEqual(owner.adventurePatrolLabel:getColor(),warm and C.ink or C.white))
 local box=owner.adventureObjectiveItem:getBoundingBox();assert(box.width==w-40*u and box.height==48*u)
 local view=owner.adventureNavigationView;assert(view:getPositionY()==230*u)
 assert(colorEqual(view.title:getColor(),warm and C.ink or C.white))
 owner.adventureObjectiveItem:activate();assert(brief>0)
 local result={status='ok',direction='北',steps=2,minimumFood=1,foodShortfall=0,
 path={{x=10,y=10},{x=10,y=9},{x=10,y=8}},port={x=10,y=8},nextStep={x=10,y=9}}
 V.refresh(owner,result);local overlay=owner.adventureRouteOverlay;assert(overlay:getChildrenCount()==3)
 for _,n in ipairs(overlay:getChildren())do if n.getString then assert(colorEqual(n:getColor(),SeaChartTheme.colors.white),'world route label preserves chart color')end end
 V.refresh(owner,{status='no_known_route'});assert(owner.adventureRouteOverlay==nil)
 V.refresh(owner,result);assert(owner.moveLayer:getChildrenCount()==1 and owner.adventureNavigationView==view)
 for _,n in ipairs({owner.bread,owner.capacityTips,owner.chapterTitle,owner.nameTitle,view.title,view.detail})do
  local sz=n:getContentSize();local x=n:convertToWorldSpace(cc.p(0,0)).x;assert(x>=-.1 and x+sz.width*n:getScale()<=w+.1,'live label bounded: '..n:getString())
 end
 scene:cleanup();scene:release()
 print('PASS native exploration '..w..'x'..h..' warm='..tostring(warm)..': real assets/font nodes, same seven callbacks/bounds, food foreground after consumption, objective hitbox, navigation route replacement and cleanup')
end
for _,sz in ipairs({{480,800},{540,900},{640,960},{640,1136}})do test(sz[1],sz[2],true);test(sz[1],sz[2],false)end
assert(returned==8 and writes==16)
print('PASS chart theme kept original map palette, shaders and world route labels; only isolated food fixture mutated')
