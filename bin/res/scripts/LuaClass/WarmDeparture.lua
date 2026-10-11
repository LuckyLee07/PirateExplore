-- Warm v1 departure presentation. Expedition remains the owner of inventory,
-- selection, production listeners and its guarded departure transaction.
local W=require 'LuaClass/WarmTheme'
local M=require 'LuaClass/MasterTheme'
local A=require 'LuaClass/AdventureProgress'
local D={}

local function put(parent,node,x,y,z)
    node:setPosition(cc.p(x,y));parent:addChild(node,z or 0);return node
end
local function objectiveText()
    return A.getState(DataManager:getInstance()).objective=='supply' and '本航目标：补给' or '本航目标：救援'
end
function D.create(view)
    local size=cc.Director:getInstance():getVisibleSize()
    local origin=cc.Director:getInstance():getVisibleOrigin()
    local u=size.width/640;local C=W.colors
    -- This contextual sheet owns Back; suppress the shared utility footer.
    view.keepNavigation=false
    local bottom=origin.y+12*u
    view.warmOriginX=origin.x;view.warmBottom=bottom
    local hero=math.min(292*u,size.height*.26)
    local sheetTop=origin.y+size.height-hero
    view.isWarmDeparture=true;view.warmScale=u
    view.adventureScaleX=size.width/941;view.adventureScaleY=.88*u
    view.adventureWidth=size.width-40*u;view.adventureRowHeight=108*u
    view.mainBg:setVisible(false);view.titleBg:setVisible(false);view.storeMenu:setVisible(false)
    for _,child in ipairs(view.infoNode:getChildren()) do
        if child~=view.bottomInfoBox then child:setVisible(false);child:stopAllActions() end
    end
    view.setBtn:stopAllActions();view.setBtnLight:stopAllActions()
    view.infoNode:setPosition(cc.p(0,0));view.infoNode:setLocalZOrder(30)
    view.bottomInfoBox:setPosition(cc.p(origin.x+size.width/2,bottom+240*u))
    -- This is the existing dark details popup, so retain its light foreground.
    view.infoBoxLabel:setColor(M.colors.white)
    local root=cc.Node:create();view.adventureRoot=root;view:addChild(root,2)
    put(root,W.panel(size.width,size.height,C.sea,0),origin.x,origin.y)
    local art=W.cover(W.path..'sea-home.png',size.width,size.height)
        or W.cover('Images/UI/Adventure/Departure/backdrop.png',size.width,size.height)
    if art then put(root,art,origin.x,origin.y) end
    -- The same separate world/ship layers as home keep preparation in its port.
    -- The lower cream sheet naturally occludes the ship's lower deck.
    local shipArt=W.sprite(W.path..'ship-home.png',420*u,630*u)
    if shipArt then put(root,shipArt,origin.x+173*u,sheetTop+90*u) end
    local function label(text,font,color,x,y,bold,anchor)
        return put(root,W.label(text,font*u,color,0,0,bold,anchor),origin.x+x*u,y)
    end
    local function button(text,x,y,w,h,callback,opts)
        opts=opts or {};opts.size=(opts.size or 23)*u
        return put(root,W.button(text,w*u,h*u,callback,opts),origin.x+x*u,y)
    end
    local back=button('返回',73,origin.y+size.height-50*u,110,60,function()
        if not view.departureInProgress then zqDispatch:moveToHome() end
    end,{size=23})
    view.departureBackButton=back.item
    put(root,W.panel(276*u,60*u,C.paper,22*u),origin.x+140*u,origin.y+size.height-80*u)
    label('出航准备',31,C.ink,278,origin.y+size.height-50*u,true,.5)
    -- Live money is visible, but preparation has no competing shop CTA.
    put(root,W.panel(158*u,56*u,C.paper,24*u),origin.x+458*u,origin.y+size.height-78*u)
    local coin=require('LuaClass/DepartureTheme').currencyIcon('coin',34*u)
    put(root,coin,origin.x+470*u,origin.y+size.height-67*u)
    view.departureCoinLabel=label('',25,C.ink,513,origin.y+size.height-50*u,true)
    local function refreshMoney()
        local n=tonumber(DataManager:getInstance():getRoleData(roleMoney)) or 0
        view.departureCoinLabel:setString(n>=1000000 and math.floor(n/10000)..'万' or tostring(n))
        M.fit(view.departureCoinLabel,87*u)
    end
    refreshMoney();DataManager:getInstance():registerEvent(roleMoney,'approvedDeparture',refreshMoney)
    -- The actual current ship and voyage, rather than a fictional destination.
    put(root,W.panel(248*u,61*u,C.paper,22*u),origin.x+24*u,sheetTop+22*u)
    view.shipNameLabel=label('',26,C.ink,45,sheetTop+54*u,true)
    local state=A.getState(DataManager:getInstance())
    if state.enabled then
        put(root,W.panel(164*u,40*u,C.paper,18*u),origin.x+454*u,sheetTop+87*u)
        view.voyageLabel=label('第 '..((tonumber(state.voyage) or 0)+1)..' 次出航',21,C.ink,602,sheetTop+107*u,true,1)
        view.objectiveButton=button(objectiveText()..'  ›',446,sheetTop+53*u,342,61,function()
            if view.departureInProgress then return end
            require('LuaClass/AdventureDialog').show('本航目标','目标也可在沉船处改选。首航巡逻航段暂停普通随机遭遇；粮耗与主动战斗照常，离段后恢复风险。',{
                {label='救援：带人安全返港',detail='消耗额外食物，换取港口伙伴与章门方位',action=function()
                    local ok=A.setObjective(DataManager:getInstance(),'rescue')
                    if not ok then ToastUtil:toastString('目标未保存，请重试。原目标未改变。');return false end
                    view.objectiveButton.label:setString(objectiveText()..'  ›')
                end},
                {label='补给：抢救升级材料',detail='保留食物，带回更多木材；不会封锁章门',action=function()
                    local ok=A.setObjective(DataManager:getInstance(),'supply')
                    if not ok then ToastUtil:toastString('目标未保存，请重试。原目标未改变。');return false end
                    view.objectiveButton.label:setString(objectiveText()..'  ›')
                end},
                {label='暂不更改'}},view)
        end,{size=22})
    end
    put(root,W.panel(size.width,sheetTop-bottom+20*u,C.paper,30*u),origin.x,bottom-20*u)
    -- Group summaries are inserted alongside their real inventory rows.
    view.crewLabel=label('',20,C.ink,0,0,true);view.crewLabel:setVisible(false)
    view.cargoLabel=label('',20,C.ink,0,0,true);view.cargoLabel:setVisible(false)
    view.foodLabel=label('',18,C.muted,0,0,false);view.foodLabel:setVisible(false)
    view.warmDefaultLabels={crew=view.crewLabel,cargo=view.cargoLabel}
    local footer=bottom+304*u
    local viewSize=cc.size(view.adventureWidth,math.max(218*u,sheetTop-20*u-footer))
    view.warmListTop=sheetTop-20*u;view.warmListAvailableHeight=viewSize.height
    view.scrollViewContainer=cc.Layer:create();view.scrollViewContainer:setContentSize(viewSize)
    view.scrollView=cc.ScrollView:create(viewSize)
    view.scrollView:setPosition(cc.p(origin.x+20*u,footer))
    view.scrollView:setContainer(view.scrollViewContainer);view.scrollView:setViewSize(viewSize)
    view.scrollView.bIsScrollView=true;view.scrollView:setClippingToBounds(true)
    view.scrollView:setBounceable(true);view.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    view:addChild(view.scrollView,3)
    view.topMaskLabel=label('',18,C.ink,0,0);view.topMaskLabel:setVisible(false)
    -- A real cargo preview replaces the former empty spacer below the roster.
    D.cargoPreview(view,106*u)
    -- One dominant action, with the unmet requirement directly above it.
    view.readyLabel=label('',21,C.ink,320,bottom+156*u,true,.5)
    view.readinessRequirement=label('航行收获带回港口后，才会存入仓库',17,C.muted,320,bottom+129*u,false,.5)
    view.departureButton=button('准备好，出航',320,bottom+74*u,548,82,view.departureAction,{primary=true,icon='sail',size=31})
    view.warmSheetTop=sheetTop;view.warmFooterTop=footer
end

function D.update(view)
    local C=W.colors;local u=view.warmScale
    local food=tonumber(view.selectedData['1005']) or 0
    local ship=view.produceCsv[tostring(DataManager:getInstance():getRoleData(roleShipId) or '')] or {}
    view.shipNameLabel:setString(ship.name or '当前战船');M.fit(view.shipNameLabel,208*u)
    view.crewLabel:setString('已登船 '..view.useSoldierNum..' / '..view.soldierNum)
    view.cargoLabel:setString('货舱  '..view.useBoatNum..' / '..view.boatNum)
    M.fit(view.crewLabel,256*u);M.fit(view.cargoLabel,256*u)
    view.foodLabel:setString('已备食物 '..food);M.fit(view.foodLabel,256*u)
    local remaining=math.max(0,view.boatNum-view.useBoatNum)
    view.cargoRemainingLabel:setString('空余货舱 '..remaining..' / '..view.boatNum..' 格')
    view.cargoHintLabel:setString(remaining>0 and '留些位置，装下海上的新发现' or '货舱已满，可减去物品腾出位置')
    if view.cargoCompositionLabel then
        local foodSlots=food*(tonumber((view.produceCsv['1005'] or {}).cubage) or 1)
        view.cargoCompositionLabel:setString('食物 '..foodSlots..' 格 · 其他物品 '..math.max(0,view.useBoatNum-foodSlots)..' 格')
        M.fit(view.cargoCompositionLabel,420*u)
    end
    M.fit(view.cargoRemainingLabel,450*u);M.fit(view.cargoHintLabel,450*u)
    view.cargoCapacityBar:setScaleX(math.min(1,remaining/math.max(1,view.boatNum)))
    local ready=food>0 and view.useSoldierNum>0
    if ready and view.useBoatNum>=view.boatNum then
        view.readyLabel:setString('货舱已满 · 可减去物品腾出空位')
    elseif ready then view.readyLabel:setString('伙伴与补给已登船，可以出发了')
    elseif food<=0 and view.useSoldierNum>0 then view.readyLabel:setString('伙伴已就位，请装入航行食物')
    elseif food<=0 then view.readyLabel:setString('先带上食物，再安排一位伙伴')
    else view.readyLabel:setString('补给已就位，请安排至少一位伙伴') end
    view.readyLabel:setColor(ready and C.sea or C.ink);M.fit(view.readyLabel,574*u)
    view.departureButton.label:setString(ready and '准备好，出航' or '出航')
end

function D.failure(view,reason)
    local messages={insufficient='库存已变化，请重新调整伙伴与补给',
        cargo_full='货舱装不下了，请减去一些物品',
        invalid_selection='请检查食物和伙伴的装载数量',
        voyage_active='已有一段航行，请返回航海图继续'}
    local text=messages[reason] or '出航未能保存，请稍后重试'
    view.readyLabel:setString(text);view.readyLabel:setColor(W.colors.coral)
    M.fit(view.readyLabel,574*view.warmScale)
    ToastUtil:toastString(text)
end

-- A compact preview for long lists; a more visual cargo card uses the room
-- beneath a small starter party. Every number comes from the current loadout.
function D.cargoPreview(view,height)
    if view.warmCargoCard then view.warmCargoCard:removeFromParent(true) end
    local u=view.warmScale;local C=W.colors;local expanded=height>140*u
    local card=W.panel(570*u,height,C.white,20*u)
    put(view.adventureRoot,card,view.warmOriginX+35*u,view.warmBottom+184*u)
    view.warmCargoCard=card
    local iconSize=(expanded and 84 or 58)*u
    put(card,W.icon('chest',iconSize),14*u,(height-iconSize)/2)
    local left=(expanded and 112 or 86)*u
    view.cargoRemainingLabel=put(card,W.label('',25*u,C.ink,0,0,true),left,height-30*u)
    view.cargoHintLabel=put(card,W.label('',18*u,C.muted,0,0,false),left,height-63*u)
    view.cargoCompositionLabel=nil
    if expanded then view.cargoCompositionLabel=put(card,W.label('',19*u,C.muted,0,0,false),left,64*u) end
    local function bar(color)
        local n=cc.LayerColor:create(cc.c4b(color.r,color.g,color.b,255),(expanded and 426 or 450)*u,7*u)
        n:setAnchorPoint(cc.p(0,0));return n
    end
    put(card,bar(C.line),left,(expanded and 27 or 18)*u)
    view.cargoCapacityBar=put(card,bar(C.sea),left,(expanded and 27 or 18)*u)
end

-- Inventory types only alter presentation order and grouping, never selection.
function D.prepareRows(view)
    local u=view.warmScale;local cursor=0;local group
    view.warmRowLayout={};view.warmGroups={}
    view.crewLabel=view.warmDefaultLabels.crew;view.cargoLabel=view.warmDefaultLabels.cargo
    for _,data in ipairs(view.expeditionData)do
        local id=tostring(data[dataKeyID]);local n=tonumber(id)
        local kind=n>=10000 and 'crew' or (id=='1005' and 'food' or 'cargo')
        if kind~=group then
            group=kind
            view.warmGroups[#view.warmGroups+1]={kind=kind,top=cursor}
            cursor=cursor+(kind=='cargo' and 28 or 40)*u
        end
        local height=(kind=='crew' and 126 or kind=='food' and 108 or 94)*u
        view.warmRowLayout[id]={top=cursor,height=height,kind=kind}
        cursor=cursor+height+6*u
    end
    view.warmRawRowsHeight=cursor
    local height=math.min(view.warmListAvailableHeight,math.max(120*u,cursor))
    view.scrollView:setViewSize(cc.size(view.adventureWidth,height))
    view.scrollView:setPosition(cc.p(view.warmOriginX+20*u,view.warmListTop-height))
    view.scrollView:setBounceable(cursor>height)
    view.warmRowsHeight=math.max(cursor,height)
    return view.warmRowsHeight
end
function D.decorateGroups(view,allHeight)
    local spare=math.max(0,view.warmListAvailableHeight-view.warmRawRowsHeight)
    D.cargoPreview(view,math.min(224*view.warmScale,106*view.warmScale+spare))
    local u=view.warmScale;local width=view.adventureWidth
    local function heading(text,size,color,x,y,bold,anchor)
        return put(view.scrollViewContainer,W.label(text,size*u,color,0,0,bold,anchor),x*u,y)
    end
    for _,group in ipairs(view.warmGroups)do
        local y=allHeight-group.top-(group.kind=='cargo' and 13 or 20)*u
        if group.kind=='crew' then
            heading('同行伙伴',25,W.colors.ink,15,y,true)
            view.crewLabel=heading('',20,W.colors.sea,width/u-14,y,true,1)
        elseif group.kind=='food' then
            heading('本航补给',25,W.colors.ink,15,y,true)
            view.cargoLabel=heading('',20,W.colors.muted,width/u-14,y,false,1)
        else
            heading('随身物品 · 可选',19,W.colors.muted,15,y,false)
            heading('长按 + / − 连续调整',17,W.colors.muted,width/u-14,y,false,1)
        end
    end
end
-- Keep the same callbacks and remaining-stock upvalues throughout production.
function D.styleRow(view,row)
    local u=view.warmScale;local controls=row.controls;local C=W.colors
    local layout=view.warmRowLayout[row.itemId];local food=row.itemId=='1005'
    row:setPosition(cc.p(view.adventureWidth/2,view.warmRowsHeight-layout.top-layout.height/2))
    row.divider:setVisible(false)
    local card=W.panel(view.adventureWidth-12*u,layout.height,C.white,20*u)
    card:setPosition(cc.p(-view.adventureWidth/2+6*u,-layout.height/2));row:addChild(card,-1)
    controls.full:setVisible(food);controls.full:setEnabled(food)
    controls.details:setPosition(cc.p((food and -168 or -128)*u,0))
    controls.minus:setPosition(cc.p((food and 10 or 94)*u,0))
    controls.plus:setPosition(cc.p((food and 114 or 230)*u,0))
    controls.full:setPosition(cc.p(232*u,0));controls.full.bLabel:setColor(C.sea)
    row.quantityLabel:setPosition(cc.p((food and 62 or 162)*u,0));row.quantityLabel:setColor(C.ink)
    local x=row.isCrew and 125 or 94
    row.nameLabel:setPosition(cc.p(x*u,row.isCrew and 88*u or 70*u));row.nameLabel:setColor(C.ink)
    M.fit(row.nameLabel,(food and 156 or row.isCrew and 188 or 225)*u)
    row.portrait:setScale(row.isCrew and 1 or .8);row.portrait:setPosition(cc.p(6*u,row.isCrew and 0 or 10*u))
    row.remainingLabel:setPosition(cc.p(x*u,row.isCrew and 29*u or 34*u));row.remainingLabel:setColor(C.muted)
    M.fit(row.remainingLabel,(food and 156 or 200)*u)
    for i,star in ipairs(row.stars or {}) do star:setPosition(cc.p((x+(i-1)*18)*u,59*u));star:setColor(C.gold) end
end
return D
