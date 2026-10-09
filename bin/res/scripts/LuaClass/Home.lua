require 'LuaClass/Header'
require 'LuaClass/DataManager'
require 'LuaClass/GuideController'
require 'LuaClass/MasterTheme'

-- Read-only harbor. Coordinates follow the approved 941x1672 master artwork;
-- no role data, tutorial reward, or expedition initialization is performed here.
HomeLayer=class('HomeLayer',function() return cc.Layer:create() end)
HomeLayer.__index=HomeLayer
local HOME_EVENTS={rolePack,roleSelectUnit,roleSoildierQueue,rolePackSize,roleCabinSize,roleGuideStep,roleShipId}
function HomeLayer:create()
    local view=HomeLayer.new();if view and view:init() then return view end
end
function HomeLayer:init()
    self.isAdventureHome=true;self.homeDisposed=false
    local M=MasterTheme;local c=M.colors
    local size=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin()
    self.viewport=size
    local root=cc.Node:create();root:setPosition(origin);self:addChild(root);self.content=root
    local bg=M.cover(M.path..'harbor-full.png',size.width,size.height)
    if bg then root:addChild(bg) else
        local sky=cc.LayerColor:create(cc.c4b(68,151,181,255),size.width,size.height);root:addChild(sky)
    end
    -- x and widths follow the 941px master; y and heights follow its 1672px
    -- portrait. On the shorter target, type remains legible at native size.
    local ux=size.width/941;local uy=size.height/1672
    local function place(n,x,top,w,h)
        n:setPosition(cc.p(x*ux,size.height-(top+h)*uy));root:addChild(n);return n
    end
    self.masterScaleX=ux;self.masterScaleY=uy
    local plaqueW,plaqueH=399*ux,264*uy
    local plaque=place(M.material('ink-brush.png',plaqueW,plaqueH),36,541,399,264)
    local shipIcon=M.icon('sail',34,c.paper);shipIcon:setPosition(cc.p(31*ux,plaqueH-83*uy));plaque:addChild(shipIcon)
    self.shipTitleWidth=plaqueW-86
    self.shipLabel=M.label('',28,c.paper,106*ux,plaqueH-55*uy,true);plaque:addChild(self.shipLabel)
    plaque:addChild(M.label('货舱',25,c.paper,47*ux,plaqueH-117*uy,true))
    self.cargoLabel=M.label('',27,c.white,139*ux,plaqueH-117*uy,true);plaque:addChild(self.cargoLabel)
    local barW=324*ux;local barH=15*uy;local barX=46*ux;local barY=plaqueH-162*uy
    local frame=HomeTheme.rounded(barW+2,barH+2,c.sea,5);frame:setPosition(cc.p(barX-1,barY-1));plaque:addChild(frame)
    local track=HomeTheme.rounded(barW,barH,c.ink,4);track:setPosition(cc.p(barX,barY));plaque:addChild(track)
    self.cargoBar=HomeTheme.rounded(barW,barH,c.sea,4);self.cargoBar:setPosition(cc.p(barX,barY));plaque:addChild(self.cargoBar)
    local rule=cc.DrawNode:create();rule:drawSegment(cc.p(46*ux,plaqueH-180*uy),cc.p(369*ux,plaqueH-180*uy),.65,HomeTheme.rgba(c.paper,.9));plaque:addChild(rule)
    local foodIcon=M.icon('food',29,c.paper);foodIcon:setPosition(cc.p(43*ux,plaqueH-237*uy));plaque:addChild(foodIcon)
    self.foodLabel=M.label('',21,c.white,96*ux,plaqueH-217*uy,true);plaque:addChild(self.foodLabel)
    local keyIcon=M.icon('key',31,c.paper);keyIcon:setPosition(cc.p(240*ux,plaqueH-239*uy));plaque:addChild(keyIcon)
    self.keyLabel=M.label('',21,c.white,287*ux,plaqueH-217*uy,true);plaque:addChild(self.keyLabel)

    rule:drawSegment(cc.p(221*ux,plaqueH-198*uy),cc.p(221*ux,plaqueH-240*uy),.65,HomeTheme.rgba(c.paper,.9))

    -- The roster is one paper object over the dock, with three genuine unit
    -- positions. No additional white cards, legacy shortcuts or feature tiles.
    self.rosterWidth=900*ux;self.rosterHeight=370*uy
    self.roster=place(M.material('crew-paper.png',self.rosterWidth,self.rosterHeight),20,975,900,370)
    local people=M.icon('crew',36,c.ink);people:setPosition(cc.p(42*ux,self.rosterHeight-61*uy));self.roster:addChild(people)
    self.crewLabel=M.label('',26,c.ink,112*ux,self.rosterHeight-46*uy,true);self.roster:addChild(self.crewLabel)
    self.crewNode=cc.Node:create();self.roster:addChild(self.crewNode)
    self.slotWidth=272*ux;self.slotPortraitHeight=229*uy;self.slotBaseY=70*uy
    self.slotStartX=38*ux;self.slotStep=292*ux

    local statusW,statusH=308*ux,87*uy
    local status=place(M.material('ink-brush.png',statusW,statusH),71,1366,308,87)
    self.hintLabel=M.label('',25,c.paper,statusW/2,statusH/2,true,.5);status:addChild(self.hintLabel)
    self.readyLabel=self.hintLabel
    local actionW,actionH=498*ux,125*uy
    self.departureButton=M.button('整备出航  ›',actionW,actionH,function() self:openPrimary() end,
        {material='coral-brush.png',fontSize=38,textColor=c.white,bold=true})
    self.departureButton:setPosition(cc.p((423+249)*ux,size.height-(1345+62.5)*uy));root:addChild(self.departureButton)
    local actionSail=M.icon('sail',57,c.paper);actionSail:setPosition(cc.p(39*ux,actionH/2-28));self.departureButton.item:addChild(actionSail,4)
    self.departureButton.label:setPositionX(actionW*.61)
    self.infoLabel=M.label('',20,c.paper,0,0);self.infoLabel:setVisible(false);root:addChild(self.infoLabel)
    self:refreshSummary()
    for _,key in ipairs(HOME_EVENTS) do
        DataManager:getInstance():registerEvent(key,'adventureHome',function() if not self.homeDisposed then self:refreshSummary() end end)
    end
    return true
end
function HomeLayer:refreshSummary()
    if self.homeDisposed then return end
    local dm=DataManager:getInstance();local T=MasterTheme;local c=T.colors
    local selected=dm:getRoleData(roleSelectUnit) or {};local resources=dm:getCSVByID(csvOfResourceInfo) or {}
    local soldiers=dm:getCSVByID(csvOfSoilderAttribute) or {};local stock=dm:getRoleData(roleSoildierQueue) or {}
    local s={crew=0,cargo=0,food=0,keys=0,standby=0,unlocked=GuideController:getInstance():getIsHaveStep(8)}
    local entries={}
    for key,count in pairs(selected) do
        local id,num=tonumber(key) or 0,math.max(0,tonumber(count) or 0)
        if id>=10000 and num>0 then
            local realId=tostring(id-10000);local data=soldiers[realId] or {}
            entries[#entries+1]={id=realId,name=data.name or ('船员 '..realId),num=num}
            s.crew=s.crew+num
        elseif id<10000 then
            s.cargo=s.cargo+num*(tonumber((resources[tostring(key)] or {}).cubage) or 1)
            if tostring(key)=='1005' then s.food=num end
            if tostring(key)=='1037' or tostring(key)=='1038' or tostring(key)=='1061' then s.keys=s.keys+num end
        end
    end
    table.sort(entries,function(a,b) return tonumber(a.id)<tonumber(b.id) end)
    for id,unit in pairs(stock) do
        if type(unit)=='table' then s.standby=s.standby+math.max(0,(tonumber(unit[dataKeyNum]) or 0)-(tonumber(selected[tostring((tonumber(id) or 0)+10000)]) or 0)) end
    end
    s.cabinCapacity=tonumber(dm:getRoleData(roleCabinSize)) or 0
    self.summary=s;self.crewEntries=entries
    self.crewLabel:setString(string.format('船员  %d/%s',s.crew,tostring(dm:getRoleData(roleCabinSize) or 0)))
    local ship=resources[tostring(dm:getRoleData(roleShipId) or '')] or {}
    self.shipLabel:setString(ship.name or '战船');MasterTheme.fit(self.shipLabel,self.shipTitleWidth)
    local capacity=tonumber(dm:getRoleData(rolePackSize)) or 0
    self.cargoLabel:setString(string.format('%d / %d',s.cargo,capacity));self.cargoBar:setScaleX(capacity>0 and math.min(1,s.cargo/capacity) or 0)
    self.foodLabel:setString('食物 '..s.food);self.keyLabel:setString('钥匙 '..s.keys)
    if not s.unlocked then
        self.hintLabel:setString('先建设船坞')
        self.departureButton.label:setString('前往建设  ›')
        if not GuideController:getInstance():getIsHaveStep(1) then
            self.hintLabel:setString('先炼金，再建港')
            self.departureButton.label:setString('前往炼金  ›')
        end
    elseif s.crew==0 then self.hintLabel:setString(s.standby>0 and '请编入船员' or '请招募船员');self.departureButton.label:setString('整备出航  ›')
    elseif s.food==0 then self.hintLabel:setString('请装入食物');self.departureButton.label:setString('整备出航  ›')
    else self.hintLabel:setString('补给已备妥');self.departureButton.label:setString('整备出航  ›') end
    self:renderCrew()
end
function HomeLayer:renderCrew()
    self.crewNode:removeAllChildren();local M=MasterTheme;local c=M.colors
    local slots={};local total=self.summary.crew
    -- Expand actual unit counts for the master's three-person roster. Large
    -- formations use per-type quantities, without inventing additional people.
    if total<=3 then
        for _,e in ipairs(self.crewEntries) do
            for i=1,e.num do slots[#slots+1]={id=e.id,name=e.name,num=1,empty=false} end
        end
    else
        for i=1,math.min(3,#self.crewEntries) do
            local e=self.crewEntries[i];slots[#slots+1]={id=e.id,name=e.name,num=e.num,empty=false}
        end
    end
    for i=#slots+1,3 do
        local locked=i>self.summary.cabinCapacity
        slots[i]={empty=true,locked=locked,name=locked and '未解锁' or (total>3 and '更多船员' or '待编入'),num=0}
    end
    self.crewSlots=slots
    for i=1,3 do
        local slot=slots[i];local x=self.slotStartX+(i-1)*self.slotStep
        local art=not slot.empty and M.portrait(slot.id,self.slotWidth,self.slotPortraitHeight) or nil
        slot.neutral=not art
        if not art then art=M.silhouette(self.slotWidth*.75,self.slotPortraitHeight*.88,slot.locked);art:setPositionX(self.slotWidth*.125) end
        local holder=cc.Node:create();holder:setPosition(cc.p(x,self.slotBaseY))
        if not slot.empty then holder:addChild(M.portraitBrush(self.slotWidth,self.slotPortraitHeight)) end
        holder:addChild(art)
        if slot.locked then holder:setCascadeOpacityEnabled(true);holder:setOpacity(95) end
        self.crewNode:addChild(holder)
        local text=slot.name..(slot.num>1 and (' ×'..slot.num) or '')
        local label=M.label(text,22,slot.empty and c.muted or c.ink,x+self.slotWidth/2,39*self.masterScaleY,true,.5)
        M.fit(label,self.slotWidth+6);self.crewNode:addChild(label)
    end
end
function HomeLayer:openPrimary()
    if self.summary.unlocked then self:openRoute(1)
    elseif GuideController:getInstance():getIsHaveStep(1) then self:openRoute(3)
    else zqDispatch:moveToRepository() end
end
function HomeLayer:openRoute(index)
    if zqDispatch and zqDispatch.mainMenu then zqDispatch.mainMenu:openRoute(index) end
end
function HomeLayer:updateInfoLabel(text)
    self.latestInfo=tostring(text or ''):match('[^\r\n]+') or ''
    if self.infoLabel then self.infoLabel:setString(self.latestInfo) end
end
function HomeLayer:viewWillDestory() end
function HomeLayer:destory()
    if self.homeDisposed then return end
    self.homeDisposed=true
    for _,key in ipairs(HOME_EVENTS) do DataManager:getInstance():unregisterEvent(key,'adventureHome') end
    if pNeedUpdateLayer==self then pNeedUpdateLayer=nil end
end
