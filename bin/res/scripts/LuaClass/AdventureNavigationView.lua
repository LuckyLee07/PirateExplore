-- Display only. No buttons/listeners: movement remains a deliberate player tap.
local V={}
function V.lines(result)
    if result.status=='at_port' then
        return '出发港口','离港后回到此格即返航；港口入格不耗粮'
    elseif result.status=='ok' then
        return string.format('返港 %s · %d步 · 最低%d粮',result.direction,result.steps,result.minimumFood),
            (result.foodShortfall and result.foodShortfall>0 and '粮食不足 · ' or '')..'仅计航行；事件/治疗另耗，非安全保证'
    elseif result.status=='out_of_bounds' then
        return '已到海图边界','请换个方向；返港路线未改变'
    elseif result.status=='unavailable' then
        return '返港路线暂不可用','等待本航次海图与港口信息'
    end
    return '暂无已知返港路线','仅沿已探空海寻路；障碍/事件须先处理'
end
function V.routeOverlay(owner,result)
    if owner.adventureRouteOverlay then
        owner.adventureRouteOverlay:removeFromParent(true)
        owner.adventureRouteOverlay=nil
    end
    if not owner.moveLayer or not owner.positionForTilePosition or not result.path then return end
    local overlay=cc.Node:create();owner.adventureRouteOverlay=overlay
    owner.moveLayer:addChild(overlay,8)
    local draw=cc.DrawNode:create();overlay:addChild(draw)
    local color=cc.c4f(.98,.90,.59,.8)
    for i=2,#result.path do
        draw:drawSegment(owner:positionForTilePosition(result.path[i-1]),
            owner:positionForTilePosition(result.path[i]),1.5,color)
    end
    local function mark(tile,text)
        if not tile then return end
        local p=owner:positionForTilePosition(tile)
        local label=SeaChartTheme.label(text,19,SeaChartTheme.colors.white,p.x,p.y+12,.5)
        overlay:addChild(label)
    end
    mark(result.port,'港')
    mark(result.nextStep,'下一步')
end
function V.refresh(owner,result)
    if not owner.tipLayer then return end
    local size=screenSize or cc.Director:getInstance():getVisibleSize()
    local u=size.width/640
    local view=owner.adventureNavigationView
    if not view then
        local theme=SeaChartTheme or require 'LuaClass/SeaChartTheme'
        view=cc.Node:create();owner.adventureNavigationView=view
        view:setContentSize(cc.size(size.width-24*u,60*u))
        view:setPosition(cc.p(12*u,(owner.adventureHudBottom or 222*u)+8*u))
        view:addChild(theme.panel(size.width-24*u,60*u,theme.colors.ink,0,0))
        view.title=theme.label('',22*u,theme.colors.white,12*u,40*u,0)
        view.detail=theme.label('',17*u,theme.colors.white,12*u,16*u,0)
        view:addChild(view.title);view:addChild(view.detail)
        owner.tipLayer:addChild(view,2)
    end
    V.routeOverlay(owner,result)
    local title,detail=V.lines(result)
    view.title:setString(title);view.detail:setString(detail)
    SeaChartTheme.fit(view.title,size.width-48*u)
    SeaChartTheme.fit(view.detail,size.width-48*u)
    return view
end
return V
