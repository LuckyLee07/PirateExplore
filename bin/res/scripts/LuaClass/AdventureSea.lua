local A=require 'LuaClass/AdventureProgress'
local N=require 'LuaClass/AdventureNavigation'
local V=require 'LuaClass/AdventureNavigationView'
local S={}
-- These nodes belong to moveLayer, which is destroyed in-place on chapter
-- changes while Explore and its tipLayer HUD survive. Release their Lua owners
-- before Cocos releases the old map's children; never call a stale userdata.
function S.clearMapDecorations(owner)
    for _,key in ipairs({'adventureRouteOverlay','adventureWreckMarker'}) do
        local node=owner[key]
        owner[key]=nil
        if node then node:removeFromParent(true) end
    end
end
local function atPoint(owner,s)
    local p=s.tutorialPoint;local here=owner.playerTitlePosition
    return p and here and tonumber(owner.mapIndex)==1 and p.x==here.x and p.y==here.y
end
function S.isHudPoint(owner,point)
    if not point then return false end
    local size=screenSize or cc.Director:getInstance():getVisibleSize();local u=size.width/640
    local bottom=owner.adventureHudBottom or 222*u
    return point.x>=12*u and point.x<=size.width-12*u and point.y>=bottom+74*u and point.y<=bottom+168*u
end
function S.wreckAvailableHere(dm,mapIndex)
    local state=A.getState(dm)
    return A.availableEpisode(dm)~=nil and state.tutorialPoint~=nil and tonumber(mapIndex)==tonumber(state.tutorialPoint.mapIndex)
end
function S.refresh(owner,coefficient)
    local dm=DataManager:getInstance();local s=A.getState(dm)
    V.refresh(owner,N.query(owner,{breadCoefficient=coefficient}))
    if not s.enabled then return end
    if tonumber(owner.mapIndex)==1 and not s.tutorialPoint and not s.firstEventReturned then
        local p=N.tutorialPoint(owner)
        if p then A.setTutorialPoint(dm,p);s=A.getState(dm) end
    end
    if s.npcRescued or s.chartRecovered or (s.pending and (s.pending.choice=='rescue' or s.pending.choice=='chart')) then
        local clue=N.gateClue(owner,{origin='port'})
        if clue and clue.status=='ok' then A.setGateClue(dm,clue.text) end
    end
    if not owner.tipLayer then return end
    local size=screenSize or cc.Director:getInstance():getVisibleSize();local u=size.width/640
    if not owner.adventureObjectiveLabel then
        local label=cc.LabelTTF:create('',BoldFont,18*u)
        label:setDimensions(cc.size(size.width-40*u,48*u))
        label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        label:setColor(SeaChartTheme.colors.white)
        local item=cc.MenuItemLabel:create(label)
        item:setPosition(cc.p(size.width/2,(owner.adventureHudBottom or 222*u)+103*u))
        item:registerScriptTapHandler(function()
            if not S.tryEvent(owner,true) then A.showHarborBrief(dm,owner) end
        end)
        local menu=cc.Menu:create(item);menu:setPosition(cc.p(0,0));owner.tipLayer:addChild(menu,4)
        owner.adventureObjectiveLabel=label
        owner.adventureObjectiveItem=item
        local backing=SeaChartTheme.panel(size.width-24*u,94*u,SeaChartTheme.colors.ink,0,0)
        backing:setPosition(cc.p(12*u,(owner.adventureHudBottom or 222*u)+74*u));owner.tipLayer:addChild(backing,3)
    end
    local text
    if not S.wreckAvailableHere(dm,owner.mapIndex) and not s.pending then
        if s.objective=='supply' then text=N.supplyClue(owner).text
        elseif (s.npcRescued or s.chartRecovered) then
            local clue=N.gateClue(owner);text=clue.status=='ok' and clue.text or '探索航次 · 继续揭雾确认章节航路'
        else text='探索航次 · 继续揭雾寻找章节航路' end
        if A.availableEpisode(dm) and s.tutorialPoint and tonumber(owner.mapIndex)~=tonumber(s.tutorialPoint.mapIndex) then text=text..' · 残骸回收位于第一章' end
    elseif s.pending then
        text=s.pending.episode=='crew' and '后续成果已装船 · 安全返港结算材料与所选线索' or '首航成果已装船 · 安全带回2铁后领取一次补助'
    elseif s.tutorialPoint then
        local p=s.tutorialPoint;local port=N.query(owner,{breadCoefficient=coefficient}).port
        local direction='近港'
        if port then local dx,dy=p.x-port.x,p.y-port.y;direction=(dy<0 and '北' or dy>0 and '南' or '')..(dx<0 and '西' or dx>0 and '东' or '') end
        text=atPoint(owner,s) and '已到沉船 · 点击选择救援或取货' or ('目标：港口'..direction..'方近海的沉船 · 到场再决定')
    else text='正在确认近港沉船位置 · 可继续正常探索' end
    owner.adventureObjectiveLabel:setString(text)
    -- MenuItemLabel captured the original empty label size. Keep a fixed real
    -- hit rectangle and recenter the child; setLabel(sameNode) is unsafe here.
    owner.adventureObjectiveItem:setContentSize(cc.size(size.width-40*u,48*u))
    owner.adventureObjectiveLabel:setPosition(cc.p(0,0))
    if not owner.adventurePatrolLabel then
        local label=cc.LabelTTF:create('',BoldFont,16*u);label:setDimensions(cc.size(size.width-40*u,32*u));label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER);label:setColor(SeaChartTheme.colors.white)
        label:setPosition(cc.p(size.width/2,(owner.adventureHudBottom or 222*u)+147*u));owner.tipLayer:addChild(label,4)
        owner.adventurePatrolLabel=label
    end
    local patrol='普通航次：随机遭遇、粮耗、主动据点战斗照常'
    if s.voyage==1 and s.activeVoyage==1 then
        if A.isTutorialProtected(dm,owner.mapIndex,owner.playerTitlePosition) then
            patrol='首航巡逻航段：随机遭遇暂停；粮耗和主动据点战斗照常'
            for i,p in ipairs(s.tutorialPath or {}) do
                if owner.playerTitlePosition and p.x==owner.playerTitlePosition.x and p.y==owner.playerTitlePosition.y then
                    local nextPoint=s.pending and s.tutorialPath[i-1] or s.tutorialPath[i+1]
                    if nextPoint then patrol='巡逻航段下一步：'..require('LuaClass/KnownRoute').direction(p,nextPoint)..' · 随机遭遇暂停，粮耗/主动战斗照常' end
                end
            end
        else patrol='已离开首航巡逻航段：普通随机遭遇已恢复，粮耗照常' end
    end
    owner.adventurePatrolLabel:setString(patrol)
    if owner.adventureWreckMarker then owner.adventureWreckMarker:removeFromParent(true);owner.adventureWreckMarker=nil end
    if s.tutorialPoint and not s.pending and A.availableEpisode(dm) and tonumber(owner.mapIndex)==1 then
        local p=s.tutorialPoint;local fog=owner.fogManager and owner.fogManager.data or {}
        local known=tonumber(fog[tostring(p.x+p.y*owner.map:getMapSize().width)])==0
        -- Marker appears only after actual fog revelation, never through fog.
        if known and owner.moveLayer then
            local marker=cc.LabelTTF:create('沉船',BoldFont,24);marker:setColor(SeaChartTheme.colors.white)
            local pos=owner:positionForTilePosition(p);marker:setPosition(cc.p(pos.x,pos.y+25));owner.moveLayer:addChild(marker,10);owner.adventureWreckMarker=marker
        end
    end
end
function S.tryEvent(owner,manual,source)
    local dm=DataManager:getInstance();local s=A.getState(dm)
    local onPoint=atPoint(owner,s)
    local reason
    if not s.enabled then reason='disabled'
    elseif s.pending then reason='already_selected'
    elseif not A.availableEpisode(dm) then reason='no_episode'
    elseif not onPoint then reason='not_at_point'
    elseif owner.isHungry then reason='hungry'
    elseif owner.adventureDialog then reason='dialog_open'
    elseif owner.adventureWreckDeferred and not manual then reason='deferred' end
    if onPoint and not owner.adventureWreckDiagnostic then
        owner.adventureWreckDiagnostic=true
        local manager=owner.eventManger or {};local queued=(manager.eventWaitingQueue or {})[1]
        print('ADVENTURE_WRECK',source or (manual and 'manual' or 'event_queue'),
            'map='..tostring(owner.mapIndex),'point='..tostring(s.tutorialPoint.x)..','..tostring(s.tutorialPoint.y),
            'queue='..type(queued)..':'..tostring(queued),'battle='..tostring(manager.isMinesweeper),
            'hungry='..tostring(owner.isHungry),'status='..tostring(owner.statue),'result='..(reason or 'open'))
    end
    if reason then return reason=='dialog_open' end
    local options={}
    for _,o in ipairs(A.eventOptions(dm)) do
        local option=o
        options[#options+1]={label=o.label,detail=o.detail,disabled=o.requires and not o.enabled,
            reason='当前出航队伍没有所需兵种；基础救援和取货始终可选',action=function()
                local ok,reason=A.resolveEvent(dm,option.id)
                if not ok then
                    local reasons={cargo_full='货舱空间不足。先暂离，打开背包手动腾位，再点沉船。',food_required='食物不足，暂离补给或选择取货。',save_failed='本次没有保存，请重试。'}
                    ToastUtil:toastString(reasons[reason] or ('无法结算：'..tostring(reason)));return false
                end
                owner.bagController:refreshBattlePack(true)
                owner.breadNum=owner.bagController:getBreads();owner.bread:setString(tostring(owner.breadNum))
                owner.adventureWreckDeferred=true;owner.statue='ready'
                S.refresh(owner,owner.adventureBreadCoefficient or 0)
                if s.firstEventReturned then ToastUtil:toastString('后续材料已装入货舱。安全返港后记录本次行动，不重复发建设补助。')
                else ToastUtil:toastString('成果已装入货舱，铁匠铺待建已开放。安全带回2铁才领取建设补助。') end
            end}
    end
    options[#options+1]={label='暂离，整理货舱后再来',action=function()owner.adventureWreckDeferred=true;owner.statue='ready' end}
    owner.moveWaitingQueue={};owner.moveDirectionQueue={};owner.statue='ready'
    local followup=A.availableEpisode(dm)=='crew'
    local dialog=require('LuaClass/AdventureDialog')
    dialog.show(followup and '后续：沉船残骸回收' or '搁浅的沉船',followup and '残骸里还有受潮航图与加固货箱，只能抢救其中一类。这次有限后续成功返港后结束，不重复发建设补助。水手辨识航图，刀手拆箱；基础行动仍可选。' or '幸存者林恩困在舷梯，散落货物正在下沉。只可选一个分支。2铁占2格，木材按实际体积入舱；不会替你丢粮。',options,owner)
    return true
end
return S
