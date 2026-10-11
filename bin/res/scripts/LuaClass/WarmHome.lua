-- A ship-as-home presentation over the existing native game and save model.
require 'LuaClass/Header'
require 'LuaClass/DataManager'
require 'LuaClass/GuideController'
local W=require 'LuaClass/WarmTheme'
local Progress=require 'LuaClass/AdventureProgress'
local Recovery=require 'LuaClass/CrewRecovery'
WarmHomeLayer=class('WarmHomeLayer',function()return cc.Layer:create()end)
WarmHomeLayer.__index=WarmHomeLayer
local EVENTS={rolePack,roleMoney,roleShipId,roleSelectUnit,roleSoildierQueue,rolePackSize,roleCabinSize,roleGuideStep,roleBuilding,'adventureProgressV1','warmVoyageMemoriesV1'}
function WarmHomeLayer:create()
 local n=WarmHomeLayer.new();if n and n:init() then return n end
end
function WarmHomeLayer:init()
 self.isAdventureHome=true;self.warmHomePresentation=true;self.approvedPage=true;self.keepNavigation=false;self.homeDisposed=false
 local size=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin()
 self.viewport=size;local w,h=size.width,size.height;local k=w/640;self.k=k
 local root=cc.Node:create();root:setPosition(origin);self:addChild(root);self.content=root
 -- A calm harbor scene uses the exact clean voyage world art. The boat's
 -- painted crew is scenery, not a portrait/ownership control.
 local world,harbor,boat=W.harborWorld(w,h,{boat=true});root:addChild(world)
 self.harborArt=harbor;self.boatArt=boat
 local stage=cc.Node:create();stage:setPosition(cc.p(w*.62,h*.40));root:addChild(stage,5);self.shipStage=stage
 self.shipW=w*.55;self.shipH=h*.40
 self.growth=cc.Node:create();stage:addChild(self.growth,5)
 self.exhibit=cc.Node:create();stage:addChild(self.exhibit,6)
 local titlePaper=W.panel(272*k,80*k,W.colors.paper,20*k);titlePaper:setPosition(cc.p(12*k,h-86*k));root:addChild(titlePaper)
 local title=W.label('晴湾船港',30*k,W.colors.ink,26*k,h-39*k,true);root:addChild(title)
 local sub=W.label('整备船只，再启新航',16*k,W.colors.muted,27*k,h-70*k,false);root:addChild(sub)
 local purse=W.panel(128*k,42*k,W.colors.paper,21*k);purse:setPosition(cc.p(w-208*k,h-61*k));root:addChild(purse)
 self.coinLabel=W.label('',21*k,W.colors.ink,18*k,21*k,true);purse:addChild(self.coinLabel)
 local settings=W.button('',52*k,48*k,function()self:openSettings()end,{icon='settings',size=18*k});settings:setPosition(cc.p(w-42*k,h-40*k));root:addChild(settings);self.settingsButton=settings
 local function hotspot(text,x,y,kind,icon)
  local b=W.button(text,136*k,45*k,function()self:openActivity(kind)end,{size=20*k})
  b:setPosition(cc.p(x,y));root:addChild(b,10);return b
 end
 self.logButton=hotspot('航海日志',w*.24,h*.36,'log','log')
 self.collectionButton=hotspot('船舱珍藏',w*.76,h*.36,'collection','chest')
 local status=W.panel(w-48*k,53*k,W.colors.paper,20*k);status:setPosition(cc.p(24*k,166*k));root:addChild(status,11)
 self.statusLabel=W.label('',19*k,W.colors.ink,16*k,27*k,false);status:addChild(self.statusLabel)
 self.primaryButton=W.button('准备出航',w-74*k,74*k,function()self:openPrimary()end,{primary=true,icon='sail',size=32*k});self.primaryButton:setPosition(cc.p(w/2,116*k));root:addChild(self.primaryButton,11)
 self.crewButton=W.button('船员',w*.43,57*k,function()self:openActivity('crew')end,{icon='crew',size=24*k});self.crewButton:setPosition(cc.p(w*.265,42*k));root:addChild(self.crewButton,11)
 self.shipButton=W.button('改装',w*.43,57*k,function()self:openActivity('ship')end,{icon='hammer',size=24*k});self.shipButton:setPosition(cc.p(w*.735,42*k));root:addChild(self.shipButton,11)
 -- Existing low-frequency routes live together behind the ship's small menu.
 self.portButton=W.button('船务',92*k,40*k,function()self:openPort()end,{size=18*k});self.portButton:setPosition(cc.p(w-70*k,h-105*k));root:addChild(self.portButton,11)
 self:refreshSummary()
 for _,key in ipairs(EVENTS)do DataManager:getInstance():registerEvent(key,'warmHome',function()if not self.homeDisposed then self:refreshSummary()end end)end
 self:registerScriptHandler(function(event)if event=='exit' or event=='cleanup' then self:destory()end end)
 return true
end
function WarmHomeLayer:refreshSummary()
 if self.homeDisposed then return end
 local dm=DataManager:getInstance();local guide=GuideController:getInstance();local c=0;local food=0;local held=0
 for id,num in pairs(dm:getRoleData(roleSelectUnit) or {})do
  if (tonumber(id)or 0)>=10000 then c=c+(tonumber(num)or 0) elseif tostring(id)=='1005' then food=tonumber(num)or 0 end
 end
 for _,row in pairs(dm:getRoleData(roleSoildierQueue)or{})do if type(row)=='table' then held=held+(tonumber(row[dataKeyNum])or 0)end end
 self.summary={crew=c,food=food,standby=held,unlocked=guide:getIsHaveStep(8)}
 local capacity=tonumber(dm:getRoleData(rolePackSize))or 0
 self.coinLabel:setString('金币 '..tostring(dm:getRoleData(roleMoney)or 0));W.fit(self.coinLabel,102*self.k)
 self.recovery=Recovery.next(dm,guide)
 local s=Progress.getHarborStatus(dm);self.harborState=s
 local hint=string.format('货舱 %d  ·  同行 %d  ·  食物 %d',capacity,c,food)
 if self.recovery then hint='先补充船员，再去看看新的海域'
 elseif not self.summary.unlocked then hint='准备好我们的船，再一起出发'
 elseif c==0 then hint=held>0 and '船员在等你：出航前编入同行队伍' or '第一段冒险，从准备船员开始'
 elseif food==0 then hint='给货舱装些食物，就可以去探索了' end
 self.statusLabel:setString(hint);W.fit(self.statusLabel,self.viewport.width-80*self.k)
 self.primaryButton.label:setString(self.recovery and '补充船员' or (self.summary.unlocked and '准备出航' or '准备我们的船'))
 self.crewButton.label:setString(c>0 and ('船员 · 已选 '..c) or ('船员 · '..held..' 人'));W.fit(self.crewButton.label,self.viewport.width*.43-62*self.k)
 local memories=require('LuaClass/WarmMemories').get(dm)
 self.exhibit:removeAllChildren()
 if memories.displayId and memories.items and memories.items[memories.displayId] then
  local token=W.icon('map',self.shipW*.13);token:setPosition(cc.p(self.shipW*.125,self.shipH*.32));self.exhibit:addChild(token)
 end
 local key=tostring(capacity)..':'..tostring(s.npcRescued)
 if key~=self.growthKey then
  self.growthKey=key;self.growth:removeAllChildren()
  if capacity>=30 then
   local crate=W.icon('chest',self.shipW*.14);crate:setPosition(cc.p(-self.shipW*.22,self.shipH*.21));self.growth:addChild(crate)
   local badge=W.panel(114*self.k,27*self.k,W.colors.paper,12*self.k);badge:setPosition(cc.p(-self.shipW*.28,self.shipH*.20));self.growth:addChild(badge,2)
   badge:addChild(W.label('货舱 '..capacity,16*self.k,W.colors.ink,57*self.k,13.5*self.k,true,.5))
  end
 end
end
function WarmHomeLayer:blocked()return self.homeDisposed or self.warmActivity or self.warmCollection or self.warmReturnResult or self.warmSettingsModal or self.warmPort or self.adventureDialog end
function WarmHomeLayer:openActivity(kind)
 if self:blocked()then return end
 if kind=='collection' or kind=='log' then require('LuaClass/WarmCollection').open(self,kind=='log' and 'log' or nil) else require('LuaClass/WarmActivities').open(kind,self)end
end
function WarmHomeLayer:openSettings()
 if self:blocked()then return end
 require('LuaClass/WarmSettings').open(self)
end
function WarmHomeLayer:openPrimary()
 if self:blocked()then return end
 self:refreshSummary()
 if self.recovery then self:openActivity('crew');return end
 if self.summary.unlocked then self:openRoute(1)
 elseif GuideController:getInstance():getIsHaveStep(1)then self:openRoute(3)
 else zqDispatch:moveToRepository()end
end
function WarmHomeLayer:openRoute(index)
 if self.homeDisposed then return end
 if zqDispatch and zqDispatch.mainMenu then zqDispatch.mainMenu:openRoute(index)end
end
function WarmHomeLayer:openPort(page)
 if self:blocked()then return end
 local w,h=self.viewport.width,self.viewport.height;local k=self.k
 local layer=cc.LayerColor:create(cc.c4b(25,49,52,115),w,h);self.warmPort=layer;self:addChild(layer,20000)
 local pw,ph=w-64*k,596*k;local p=W.panel(pw,ph,W.colors.paper,28*k);p:setPosition(cc.p(32*k,(h-ph)/2));layer:addChild(p)
 p:addChild(W.label('船上的事务',30*k,W.colors.ink,28*k,ph-44*k,true))
 p:addChild(W.label('补给、制造与日常事务',18*k,W.colors.muted,28*k,ph-78*k))
 local function close()if self.warmPort==layer then self.warmPort=nil;layer:removeFromParent(true)end end
 page=page or 1
 local entries=page==1 and {{'建设船港',3},{'制造与改装',5},{'采集补给',6},{'炼金与仓库',4},{'商店',7}} or {{'船员成长 / 天赋','growth'},{'成就记录','achievement'},{'航海榜单','ranking'},{'钻石商城','diamondStore'},{'礼包（付费）','gift'}}
 for i,e in ipairs(entries)do local b=W.button(e[1],pw-48*k,53*k,function()close();if type(e[2])=='number' then self:openRoute(e[2]) elseif zqDispatch and zqDispatch.mainMenu then zqDispatch.mainMenu:openUtilityRoute(e[2])end end,{size=23*k});b:setPosition(cc.p(pw/2,ph-(123+(i-1)*65)*k));p:addChild(b)end
 local more=W.button(page==1 and '其他事务  ›' or '‹  日常船务',pw-48*k,44*k,function()close();self:openPort(page==1 and 2 or 1)end,{size=21*k});more:setPosition(cc.p(pw/2,133*k));p:addChild(more)
 local back=W.button('回到甲板',pw-48*k,55*k,close,{primary=true,size=24*k});back:setPosition(cc.p(pw/2,59*k));p:addChild(back)
 local l=cc.EventListenerTouchOneByOne:create();l:setSwallowTouches(true);l:registerScriptHandler(function()return true end,cc.Handler.EVENT_TOUCH_BEGAN);layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(l,layer)
 layer:registerScriptHandler(function(e)if (e=='exit' or e=='cleanup')and self.warmPort==layer then self.warmPort=nil end end)
end
function WarmHomeLayer:updateInfoLabel(text)self.latestInfo=tostring(text or '')end
function WarmHomeLayer:viewWillDestory()end
function WarmHomeLayer:destory()
 if self.homeDisposed then return end
 self.homeDisposed=true
 for _,key in ipairs(EVENTS)do DataManager:getInstance():unregisterEvent(key,'warmHome')end
 if self.adventureDialog then self.adventureDialog:removeFromParent(true);self.adventureDialog=nil end
 if pNeedUpdateLayer==self then pNeedUpdateLayer=nil end
end
return WarmHomeLayer
