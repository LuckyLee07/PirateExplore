-- Harbor-only presentation. Do not use this to change legacy gameplay pages.
HomeTheme = {}
local T = HomeTheme
local AdventureProgress = require 'LuaClass/AdventureProgress'
T.colors = {
    paper=cc.c3b(241,230,206), ink=cc.c3b(23,59,68), sea=cc.c3b(39,136,154),
    coral=cc.c3b(228,120,84), muted=cc.c3b(83,105,106), line=cc.c3b(211,197,169),
    light=cc.c3b(248,240,222), white=cc.c3b(255,249,231), pale=cc.c3b(220,225,211)
}
function T.rgba(c, alpha) return cc.c4f(c.r/255,c.g/255,c.b/255,alpha or 1) end
function T.label(text,size,color,x,y,bold,anchorX)
    local n=cc.LabelTTF:create(tostring(text or ''),bold and BoldFont or 'Arial',size or 22)
    n:setColor(color or T.colors.ink); n:setAnchorPoint(cc.p(anchorX or 0,0.5))
    n:setPosition(cc.p(x or 0,y or 0)); return n
end
function T.rounded(w,h,color,radius,border)
    local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setCascadeOpacityEnabled(true)
    local d=cc.DrawNode:create();local p={};local r=radius or 5
    local centers={{w-r,h-r,0},{r,h-r,90},{r,r,180},{w-r,r,270}}
    for _,a in ipairs(centers) do
        for i=0,4 do local angle=math.rad(a[3]+i*22.5);p[#p+1]=cc.p(a[1]+r*math.cos(angle),a[2]+r*math.sin(angle)) end
    end
    d:drawPolygon(p,#p,T.rgba(color),border and 0.7 or 0,T.rgba(border or color))
    n:addChild(d);return n
end
function T.button(text,w,h,callback,opts)
    opts=opts or {};local c=T.colors
    local normal=T.rounded(w,h,opts.color or c.paper,5,opts.border)
    local selected=T.rounded(w,h,opts.selectedColor or c.pale,5,opts.border)
    local item=cc.MenuItemSprite:create(normal,selected)
    local label=T.label(text,opts.size or 24,opts.textColor or c.ink,w/2,h/2,opts.bold,0.5)
    item:addChild(label);item:registerScriptTapHandler(callback)
    local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setAnchorPoint(cc.p(0.5,0.5))
    item:setPosition(cc.p(w/2,h/2));local menu=cc.Menu:create(item);menu:setPosition(cc.p(0,0));n:addChild(menu)
    n.item=item;n.label=label;return n
end
function T.cover(path,w,h)
    if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
    local s=cc.Sprite:create(path);if not s then return nil end
    local z=s:getContentSize();local scale=math.max(w/z.width,h/z.height)
    s:setTextureRect(cc.rect((z.width-w/scale)/2,(z.height-h/scale)/2,w/scale,h/scale))
    s:setScale(scale);s:setAnchorPoint(cc.p(0,0));return s
end
function T.rule(parent,x,y,w,color)
    local d=cc.DrawNode:create();d:drawSegment(cc.p(x,y),cc.p(x+w,y),0.45,T.rgba(color or T.colors.line))
    parent:addChild(d);return d
end
function T.silhouette(w,h)
    local n=T.rounded(w,h,T.colors.pale,4)
    local d=cc.DrawNode:create();local c=T.rgba(cc.c3b(126,148,144))
    d:drawDot(cc.p(w/2,h*0.66),w*0.15,c)
    local p={cc.p(w*.18,h*.15),cc.p(w*.23,h*.39),cc.p(w*.4,h*.49),cc.p(w*.6,h*.49),cc.p(w*.77,h*.39),cc.p(w*.82,h*.15)}
    d:drawPolygon(p,#p,c,0,c);n:addChild(d);return n
end
-- Finite, read-only harbor growth. Capacity is authoritative even for old saves;
-- rescue decoration is shown only for a successfully persisted return.
function T.harborGrowthState(dm)
    local progress=AdventureProgress.getHarborStatus(dm)
    local capacity=tonumber(dm:getRoleData(rolePackSize)) or 0
    return {capacity=capacity,cargoUpgraded=capacity>=30,npcRescued=progress.npcRescued==true,
        enabled=progress.enabled==true,firstReturnClaimed=progress.firstReturnClaimed==true,
        choice=progress.choice,objective=progress.objective,npcName=progress.npcName or '林恩'}
end
-- Reuse the wooden crate painted into the approved harbor. The stencil follows
-- the crate silhouette, excluding its original dock background. No new bitmap,
-- treasure/reward chest, or role portrait is substituted for freight.
function T.harborCrate(width)
    if not cc.ClippingNode then return nil end
    local path='Images/UI/Adventure/Master/harbor-full.png'
    if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
    local sprite=cc.Sprite:create(path,cc.rect(786,1030,140,117))
    if not sprite then return nil end
    sprite:setAnchorPoint(cc.p(0,0))
    local clip=cc.ClippingNode:create();clip:setContentSize(cc.size(140,117))
    local stencil=cc.DrawNode:create()
    local points={cc.p(14,101),cc.p(56,115),cc.p(123,102),cc.p(134,20),cc.p(79,3),cc.p(4,23)}
    stencil:drawPolygon(points,#points,cc.c4f(1,1,1,1),0,cc.c4f(1,1,1,1))
    clip:setStencil(stencil);clip:setAlphaThreshold(.5);clip:addChild(sprite);clip:setScale(width/140)
    return clip
end
function T.harborSignal()
    local n=cc.Node:create();n:setContentSize(cc.size(104,180))
    local d=cc.DrawNode:create();n:addChild(d)
    local ink=T.rgba(cc.c3b(61,51,39));local wood=T.rgba(cc.c3b(191,138,73))
    d:drawSegment(cc.p(12,1),cc.p(12,179),3,ink)
    d:drawSegment(cc.p(11,3),cc.p(11,176),1.1,wood)
    -- Swallowtail signal, drawn as convex triangles to avoid polygon miters.
    local cream=T.rgba(cc.c3b(246,230,190));local coral=T.rgba(cc.c3b(204,91,58))
    d:drawTriangle(cc.p(15,170),cc.p(100,161),cc.p(67,143),cream)
    d:drawTriangle(cc.p(15,170),cc.p(67,143),cc.p(16,119),cream)
    d:drawTriangle(cc.p(16,119),cc.p(67,143),cc.p(101,126),coral)
    d:drawSegment(cc.p(24,162),cc.p(25,132),1.1,wood)
    return n
end
function T.refreshGrowth(home,dm)
    if home.homeDisposed or not home.content or not home.viewport then return end
    local s=T.harborGrowthState(dm)
    local key=table.concat({s.capacity,s.cargoUpgraded and 1 or 0,s.npcRescued and 1 or 0,
        s.enabled and 1 or 0,s.firstReturnClaimed and 1 or 0,s.choice or '',s.objective or ''},':')
    if home.harborGrowthKey==key then return end
    home.harborGrowthKey=key;home.harborGrowthStatus=s
    if home.harborGrowthLayer then home.harborGrowthLayer:removeFromParent(true) end
    local layer=cc.Node:create();home.content:addChild(layer,1);home.harborGrowthLayer=layer
    local ux,uy=home.masterScaleX,home.masterScaleY;local height=home.viewport.height
    local function at(node,x,top,w,h)
        node:setPosition(cc.p(x*ux,height-(top+h)*uy));layer:addChild(node);return node
    end
    if s.cargoUpgraded then
        local cargo=cc.Node:create();cargo:setScale(math.min(ux,uy))
        local back=T.harborCrate(130);local front=T.harborCrate(154)
        if back then back:setPosition(cc.p(110,24));cargo:addChild(back) end
        if front then cargo:addChild(front) end
        at(cargo,485,817,264,144)
        local label=MasterTheme.label('扩建货舱 · '..s.capacity,21,MasterTheme.colors.paper,0,0,true,.5)
        local paper=MasterTheme.material('ink-brush.png',250*ux,42*uy)
        at(paper,482,931,250,42);label:setPosition(cc.p(125*ux,22*uy));paper:addChild(label)
        MasterTheme.fit(label,220*ux)
    end
    if s.npcRescued then
        local signal=T.harborSignal();signal:setScale(math.min(ux,uy));at(signal,811,770,104,180)
    end
    if s.enabled then
        local text=s.npcRescued and (s.npcName..' · 航图线索  ›') or '本航目标  ›'
        if s.firstReturnClaimed and not s.npcRescued then text='港务记录 · 下一航  ›' end
        local button=MasterTheme.button(text,350*ux,72*uy,function()
            if home.homeDisposed or home.adventureDialog or home.goalDialog or home.sourceDialog or home.recoveryDialog then return end
            AdventureProgress.showHarborBrief(dm,home)
        end,{fontSize=24,textColor=MasterTheme.colors.paper,bold=true})
        button:setAnchorPoint(cc.p(0,0));at(button,61,849,350,72)
        MasterTheme.fit(button.label,320*ux);home.harborBriefButton=button
    else home.harborBriefButton=nil end
end
return T
