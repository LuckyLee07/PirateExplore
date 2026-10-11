-- Run in tutorial-log-native: real nodes, LabelTTF, assets and menu callbacks.
-- No game initialization, profile or user save. State is isolated in memory.
require 'extern'
require 'LuaClass/Header'
BoldFont='Noto Serif CJK SC'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/home_master_regression.lua')
local start=assert(source:find('local function readFile(path)',1,true))
local stop=assert(source:find("\nlocal soldiers=packagedCSV('soilderAttribute')",start,true))
local csv=assert(loadstring('local equal=function(a,b)assert(a==b)end\n'..source:sub(start,stop-1)..'\nreturn packagedCSV','@native-warm-csv'))()
local tables={[csvOfResourceInfo]=csv('resourceInfo'),[csvOfSoilderAttribute]=csv('soilderAttribute'),
 [csvOfBuild]=csv('build'),[csvOfStore]=csv('store'),[csvOfWorker]=csv('worker'),[csvOfSkillAttribute]=csv('skillAttribute'),[csvOfBuff]=csv('buff')}
local data={[roleMoney]=30,[rolePackSize]=20,[roleCabinSize]=1,[roleShipId]='1299',[roleShipHp]=100,
 [roleSoildierQueue]={['100']={[dataKeyID]='100',[dataKeyNum]=1}},[roleSelectUnit]={},
 [rolePack]={['1005']=100},[roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=0}},[roleMake]={},
 adventureProgressV1={version=1,enabled=true,voyage=0}}
local events={}
local dm={getRoleData=function(_,key)return data[key]end,getCSVByID=function(_,key)return tables[key]or{}end,
 registerEvent=function(_,key,name,fn)events[key..name]=fn end,
 unregisterEvent=function(_,key,name)events[key..name]=nil end}
DataManager={getInstance=function()return dm end}
GuideController={getInstance=function()return{getIsHaveStep=function()return true end}end}
local scene,viewport
local realGet=cc.Director.getInstance;local director=realGet(cc.Director)
cc.Director.getInstance=function()return setmetatable({getVisibleSize=function()return viewport end,
 getVisibleOrigin=function()return cc.p(0,0)end,getRunningScene=function()return scene end},
 {__index=function(_,key)return function(_,...)return director[key](director,...)end end})end
local A=require 'LuaClass/WarmActivities'
local dispatches=0
zqDispatch={gotoTrain=function()dispatches=dispatches+1 end,moveToExpedition=function()dispatches=dispatches+1 end,
 gotoBuild=function()dispatches=dispatches+1 end,gotoMake=function()dispatches=dispatches+1 end,
 moveToRepository=function()dispatches=dispatches+1 end,gotoAchievement=function()dispatches=dispatches+1 end}
local function labelsWithin(page)
 for _,child in ipairs(page.canvas:getChildren())do
  if child.getString and child:getString()~='' then
   local size=child:getContentSize();local anchor=child:getAnchorPoint();local x,y=child:getPosition()
   assert(x-size.width*anchor.x>=-.1 and x+size.width*(1-anchor.x)<=480.1,'label horizontal bounds: '..child:getString())
   assert(y-size.height*anchor.y>=-.1 and y+size.height*(1-anchor.y)<=800.1,'label vertical bounds: '..child:getString())
  end
 end
end
local baseline={}
for k,v in pairs(data)do baseline[k]=v end
for _,height in ipairs({960,1067,1136})do
 viewport=cc.size(640,height);scene=cc.Scene:create();scene:retain()
 local owner=cc.Node:create();scene:addChild(owner)
 local retained=cc.Node:create();owner:addChild(retained)
 for _,kind in ipairs({'crew','ship','collection','log'})do
  local page=A.open(kind,owner);page:retain();labelsWithin(page)
  assert(A.open(kind,owner)==page,'no duplicate page')
  if kind=='crew' then
   page.buttons['crew:100'].item:activate();assert(page.detailId=='100');labelsWithin(page)
   page.buttons.back.item:activate();assert(page.detailId==nil)
  elseif kind=='ship' then
   page.buttons['sources:1148'].item:activate();assert(page.sourceGoalId=='1148');labelsWithin(page)
   page.buttons.sourceBack.item:activate();assert(page.sourceGoalId==nil)
  elseif kind=='log' then
   page.buttons.brief.item:activate();assert(page.harborBrief);labelsWithin(page)
   page.buttons.briefBack.item:activate();assert(not page.harborBrief and page.buttons.collection and page.buttons.primary)
  elseif kind=='collection' then
   page.buttons['item:1005'].item:activate();assert(page.detailId=='1005');labelsWithin(page)
   page.buttons.back.item:activate();assert(page.detailId==nil)
  end
  page.buttons.back.item:activate();assert(page:getParent()==nil and owner.warmActivity==nil)
  assert(retained:getParent()==owner,'owner survives Close')
  page:close();page:release();assert(next(events)==nil,'all subscriptions removed')
 end
 local page=A.open('crew',owner);page:retain();page.buttons.primary.item:activate()
 assert(owner.warmActivity==nil);page:release()
 page=A.open('collection',owner);page:retain();owner:removeFromParent(true)
 assert(page.disposed and owner.warmActivity==nil and next(events)==nil,'native ancestor cleanup')
 page:release();scene:cleanup();scene:release();scene=nil
 print('PASS native WarmActivities '..height..'pt: real art/fonts, label bounds, crew/item details, native menus, owner preservation, cleanup')
end
local W=require 'LuaClass/WarmTheme'
local long=string.rep('下一程保留线索。\n',80)
local pages=A.textPages(long,19,394,365);assert(#pages>1 and table.concat(pages)==long,'measured pagination preserves full Unicode body')
for _,page in ipairs(pages)do
 local measure=W.label(page,19,W.colors.ink,0,0,false);measure:setDimensions(cc.size(394,0))
 assert(measure:getContentSize().height<=365,'every long brief page fits measured native box')
end
assert(dispatches==3,'one existing assignment dispatch per viewport')
for key,value in pairs(baseline)do assert(data[key]==value,'read-only data')end
cc.Director.getInstance=realGet
