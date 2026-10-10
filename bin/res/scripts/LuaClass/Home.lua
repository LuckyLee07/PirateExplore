require 'LuaClass/Header'
require 'LuaClass/DataManager'
require 'LuaClass/GuideController'
require 'LuaClass/MasterTheme'
require 'LuaClass/HarborGoals'
require 'LuaClass/CrewRecovery'
require 'LuaClass/AdventureProgress'

-- Read-only harbor. Coordinates follow the approved 941x1672 master artwork;
-- no role data, tutorial reward, or expedition initialization is performed here.
HomeLayer=class('HomeLayer',function() return cc.Layer:create() end)
HomeLayer.__index=HomeLayer
local HOME_EVENTS={rolePack,roleSelectUnit,roleSoildierQueue,rolePackSize,roleCabinSize,roleGuideStep,roleShipId,roleMake,roleBuilding,roleAlchemyUnit,roleMoney,roleStore,roleProducerQueue,roleLivingUnitNum,'adventureProgressV1'}
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
    local status=M.button('',statusW,statusH,function() self:openGoals() end,
        {fontSize=25,textColor=c.paper,bold=true})
    status:setAnchorPoint(cc.p(0,0));place(status,71,1366,308,87)
    self.goalButton=status;self.hintLabel=status.label
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
    self.recovery=CrewRecovery.next(dm,GuideController:getInstance())
    if self.recovery then
        self.hintLabel:setString('补充船员');self.departureButton.label:setString('补充船员  ›')
    end
    self:refreshRecoveryDialog()
    self.goals=HarborGoals.list(dm,GuideController:getInstance():getIsHaveStep(60))
    local canSuggest=not self.recovery and s.unlocked and s.crew>0 and s.food>0 and #self.goals>0
    self.goalButton.item:setEnabled(canSuggest)
    if canSuggest then self.hintLabel:setString('回港升级  ›') end
    MasterTheme.fit(self.hintLabel,280*self.masterScaleX)
    self:refreshGoalsDialog()
    self:refreshSourcesDialog()
    self:renderCrew()
    HomeTheme.refreshGrowth(self,dm)
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
-- The existing status plaque is the only new entry point. Details are opt-in.
function HomeLayer:openGoals()
    if self.homeDisposed or self.adventureDialog or not self.goals or #self.goals==0 or self.goalDialog or self.sourceDialog or self.recovery then return end
    require 'LuaClass/AlertView'
    local dialog=AlertView:create(1,0,'回港升级',nil,nil,nil,'关 闭')
    self.goalDialog=dialog;self.goalRows={}
    dialog:registerScriptHandler(function(event)
        if event=='exit' or event=='cleanup' then
            if self.goalDialog==dialog then self.goalDialog=nil;self.goalRows=nil end
        end
    end)
    local M=MasterTheme;local w,h=dialog.s_size.width,dialog.s_size.height
    for i=1,2 do
        local holder=cc.Node:create();dialog.s_bg:addChild(holder)
        local y=h-112-(i-1)*125
        local title=M.label('',26,M.colors.white,30,y,true)
        holder:addChild(title)
        local detail=M.label('',20,M.colors.paper,30,y-33,false)
        detail:setAnchorPoint(cc.p(0,1));detail:setDimensions(cc.size(w-206,72))
        detail:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT);holder:addChild(detail)
        local button=M.button('查看',124,43,function() self:openGoalAt(i) end,
            {material='coral-brush.png',fontSize=22,textColor=M.colors.white})
        button:setPosition(cc.p(w-92,y));holder:addChild(button)
        local sources=M.button('材料来源',124,40,function() self:openSourcesAt(i) end,
            {fontSize=21,textColor=M.colors.paper})
        sources:setPosition(cc.p(w-92,y-61));holder:addChild(sources)
        self.goalRows[i]={holder=holder,title=title,detail=detail,button=button,sources=sources}
    end
    self:refreshGoalsDialog()
end
function HomeLayer:refreshGoalsDialog()
    if not self.goalDialog or not self.goalRows then return end
    if self.recovery then
        local dialog=self.goalDialog;self.goalDialog=nil;self.goalRows=nil
        dialog:removeFromParent(true);return
    end
    for i,row in ipairs(self.goalRows) do
        local goal=self.goals[i];row.holder:setVisible(goal~=nil)
        if goal then
            row.title:setString(goal.title);MasterTheme.fit(row.title,self.goalDialog.s_size.width-194)
            row.detail:setString(goal.detail)
            local sources=HarborGoals.sources(DataManager:getInstance(),GuideController:getInstance(),goal.id)
            row.sources:setVisible(#sources>0);row.sources.item:setEnabled(#sources>0)
            row.button.label:setString(goal.action);row.button.item:setEnabled(goal.route~=nil)
        end
    end
end
function HomeLayer:openGoalAt(index)
    if self.homeDisposed or self.adventureDialog or not self.goalDialog then return end
    self:refreshSummary()
    if self.recovery or not self.goalDialog then return end
    -- Re-read the state at the actual click; a stale preview cannot buy or unlock.
    local goals=HarborGoals.list(DataManager:getInstance(),GuideController:getInstance():getIsHaveStep(60))
    local shown=self.goals and self.goals[index];local goal
    for _,candidate in ipairs(goals) do if shown and candidate.id==shown.id then goal=candidate end end
    if not goal or not goal.route then self.goals=goals;self:refreshGoalsDialog();return end
    local dialog=self.goalDialog;self.goalDialog=nil;self.goalRows=nil
    if dialog then dialog:removeFromParent(true) end
    if goal.route=='make' then zqDispatch:gotoMake(goal.routeId)
    elseif goal.route=='build' then zqDispatch:gotoBuild(goal.routeId) end
end
-- One modal at a time: source details replace the choices and offer a way back.
function HomeLayer:closeSources()
    local dialog=self.sourceDialog
    self.sourceDialog=nil;self.sourceRows=nil;self.sourceGoalId=nil;self.sourceBack=nil
    if dialog then dialog:removeFromParent(true) end
end
function HomeLayer:openSourcesAt(index)
    if self.homeDisposed or self.adventureDialog or self.sourceDialog or self.recovery or not self.goalDialog then return end
    local goal=self.goals and self.goals[index]
    if not goal then return end
    local sources=HarborGoals.sources(DataManager:getInstance(),GuideController:getInstance(),goal.id)
    if #sources==0 then self:refreshSummary();return end
    local old=self.goalDialog;self.goalDialog=nil;self.goalRows=nil
    if old then old:removeFromParent(true) end
    local dialog=AlertView:create(1,0,'材料来源',nil,nil,nil,'关 闭')
    self.sourceDialog=dialog;self.sourceGoalId=goal.id;self.sourceRows={}
    dialog:registerScriptHandler(function(event)
        if (event=='exit' or event=='cleanup') and self.sourceDialog==dialog then
            self.sourceDialog=nil;self.sourceRows=nil;self.sourceGoalId=nil;self.sourceBack=nil
        end
    end)
    local M=MasterTheme;local w,h=dialog.s_size.width,dialog.s_size.height
    for i=1,3 do
        local holder=cc.Node:create();dialog.s_bg:addChild(holder)
        local y=h-106-(i-1)*78
        local title=M.label('',22,M.colors.white,30,y,true);holder:addChild(title)
        local detail=M.label('',19,M.colors.paper,30,y-24,false)
        detail:setAnchorPoint(cc.p(0,1));detail:setDimensions(cc.size(w-60,46))
        detail:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT);holder:addChild(detail)
        local row={holder=holder,title=title,detail=detail}
        row.button=M.button('',124,36,function() self:openSource(row.materialId) end,
            {material='coral-brush.png',fontSize=20,textColor=M.colors.white})
        row.button:setPosition(cc.p(w-92,y));holder:addChild(row.button)
        self.sourceRows[i]=row
    end
    local back=M.button('返回升级',132,32,function()
        if self.sourceDialog~=dialog then return end
        self:closeSources();self:refreshSummary();self:openGoals()
    end,{fontSize=20,textColor=M.colors.paper})
    -- Keep the original centered Close target untouched; the left footer
    -- action is horizontally separated from its 176x61 legacy touch bounds.
    back:setPosition(cc.p(30+132/2,50));dialog.s_bg:addChild(back);self.sourceBack=back
    self:refreshSourcesDialog()
end
function HomeLayer:refreshSourcesDialog()
    if not self.sourceDialog then return end
    local sources=HarborGoals.sources(DataManager:getInstance(),GuideController:getInstance(),self.sourceGoalId)
    if #sources==0 or self.recovery then self:closeSources();return end
    for i,row in ipairs(self.sourceRows) do
        local item=sources[i];row.holder:setVisible(item~=nil);row.materialId=item and item.id
        if item then
            row.title:setString(item.title);MasterTheme.fit(row.title,self.sourceDialog.s_size.width-194)
            row.detail:setString(item.detail);row.button.label:setString(item.action)
            row.button.item:setEnabled(item.route~=nil)
        end
    end
end
function HomeLayer:openSource(materialId)
    if self.homeDisposed or self.adventureDialog or not self.sourceDialog or not materialId then return end
    -- Re-read before navigating; completion, unlock and inventory may have changed.
    self:refreshSummary()
    if not self.sourceDialog then return end
    local sources=HarborGoals.sources(DataManager:getInstance(),GuideController:getInstance(),self.sourceGoalId)
    for _,item in ipairs(sources) do
        if item.id==materialId and item.route then
            self:closeSources()
            if item.route=='store' then zqDispatch:gotoStore(false,item.routeId)
            elseif item.route=='resource' then zqDispatch:moveToResource()
            elseif item.route=='alchemy' then zqDispatch:moveToRepository() end
            return
        end
    end
end
function HomeLayer:openPrimary()
    if self.homeDisposed or self.adventureDialog then return end
    self:refreshSummary()
    if self.recovery then self:openRecovery();return end
    if self.summary.unlocked then self:openRoute(1)
    elseif GuideController:getInstance():getIsHaveStep(1) then self:openRoute(3)
    else zqDispatch:moveToRepository() end
end
-- Recovery is an opt-in preview; its actions only navigate to original screens.
function HomeLayer:openRecovery()
    if self.homeDisposed or self.adventureDialog or self.recoveryDialog then return end
    self.recovery=CrewRecovery.next(DataManager:getInstance(),GuideController:getInstance())
    if not self.recovery then return end
    require 'LuaClass/AlertView'
    local dialog=AlertView:create(1,0,'补充船员',nil,nil,nil,'关 闭')
    self.recoveryDialog=dialog
    dialog:registerScriptHandler(function(event)
        if (event=='exit' or event=='cleanup') and self.recoveryDialog==dialog then
            self.recoveryDialog=nil;self.recoveryDetail=nil;self.recoveryAction=nil
        end
    end)
    local M=MasterTheme;local w,h=dialog.s_size.width,dialog.s_size.height
    self.recoveryDetail=M.label('',22,M.colors.paper,30,h-105,false)
    self.recoveryDetail:setAnchorPoint(cc.p(0,1));self.recoveryDetail:setDimensions(cc.size(w-60,160))
    self.recoveryDetail:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT);dialog.s_bg:addChild(self.recoveryDetail)
    self.recoveryAction=M.button('',190,46,function() self:openRecoveryAction() end,
        {material='coral-brush.png',fontSize=24,textColor=M.colors.white})
    self.recoveryAction:setPosition(cc.p(w/2,110));dialog.s_bg:addChild(self.recoveryAction)
    self:refreshRecoveryDialog()
end
function HomeLayer:closeRecovery()
    local dialog=self.recoveryDialog
    self.recoveryDialog=nil;self.recoveryDetail=nil;self.recoveryAction=nil
    if dialog then dialog:removeFromParent(true) end
end
function HomeLayer:refreshRecoveryDialog()
    if not self.recoveryDialog then return end
    if not self.recovery then self:closeRecovery();return end
    self.recoveryDetail:setString(self.recovery.detail)
    self.recoveryAction.label:setString(self.recovery.action)
    self.recoveryAction.item:setEnabled(self.recovery.route~=nil)
end
function HomeLayer:openRecoveryAction()
    if self.homeDisposed or self.adventureDialog then return end
    self:refreshSummary() -- Re-evaluate crew, funds and the original unlock gate.
    local recovery=self.recovery
    if not recovery or not recovery.route then return end
    self:closeRecovery()
    if recovery.route=='alchemy' then zqDispatch:moveToRepository()
    elseif recovery.route=='build' then zqDispatch:gotoBuild('58')
    elseif recovery.route=='recruit' then self:openRoute(2) end
end
function HomeLayer:openRoute(index)
    if self.homeDisposed or self.adventureDialog then return end
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
    if self.adventureDialog then self.adventureDialog:removeFromParent(true);self.adventureDialog=nil end
    self:closeRecovery()
    self:closeSources()
    if self.goalDialog then self.goalDialog:removeFromParent(true);self.goalDialog=nil;self.goalRows=nil end
    for _,key in ipairs(HOME_EVENTS) do DataManager:getInstance():unregisterEvent(key,'adventureHome') end
    if pNeedUpdateLayer==self then pNeedUpdateLayer=nil end
end
