-- Explicitly opted-in legacy management screens. Presentation only.
require 'LuaClass/MasterTheme'

ManagementTheme = {}
local T = ManagementTheme
-- Resolve at use time: MasterTheme/HomeTheme can still be loading, and legacy
-- logic fixtures intentionally replace require with a non-table sentinel.
local function warm()
    if rawget(_G,'WARM_PIRATE_V1')==false then return nil end
    local W=rawget(_G,'WarmTheme')
    if type(W)~='table' then
        local ok,value=pcall(require,'LuaClass/WarmTheme')
        if ok then W=value end
    end
    if type(W)=='table' and type(W.enabled)=='function' and W.enabled() then return W end
end
local originalColors = {
    ink=MasterTheme.colors.ink, paper=cc.c3b(246,237,216), light=cc.c3b(255,249,232),
    muted=cc.c3b(79,104,107), line=cc.c3b(211,198,168), sea=cc.c3b(45,126,142),
    coral=MasterTheme.colors.coral, white=MasterTheme.colors.white, danger=cc.c3b(170,61,45)
}
local warmColors={light=cc.c3b(255,252,242),section=cc.c3b(240,243,226),danger=cc.c3b(178,57,40)}
T.colors=setmetatable({},{__index=function(_,key)
    local W=warm()
    if W then return key=='coral' and W.colors.sea or warmColors[key] or W.colors[key] end
    return originalColors[key]
end})

local function icon(glyph,size,color)
    local W=warm()
    local aliases={build='hammer',cargo='chest',wheel='settings'}
    local name=aliases[glyph] or glyph
    if W then return W.icon(name,size,color) end
    return MasterTheme.icon(glyph,size,color)
end

function T.bodyFont()
    local W=warm();return W and W.font or MasterTheme.headingFont(false)
end

function T.styleLabel(label, role, width)
    role=role or 'body'
    local W=warm()
    label:setFontName(W and W.font or (role=='heading' and MasterTheme.headingFont(true) or T.bodyFont()))
    label:setColor(T.colors[role] or (role=='action' and T.colors.white) or T.colors.ink)
    if width then MasterTheme.fit(label,width) end
    return label
end

function T.label(text,size,role,x,y,anchorX)
    local n=MasterTheme.label(text,size,T.colors.ink,x,y,false,anchorX)
    return T.styleLabel(n,role)
end

-- Native paper rows, with a restrained material edge and real text on top.
-- Like legacy sprites these have a central anchor; button faces reset it to 0.
function T.panel(w,h,style)
    style=style or 'paper'
    local W=warm()
    if W then
        local color=T.colors[style] or T.colors.light
        local n=W.panel(w,h,color,math.min(8,w/2,h/2))
        n:setAnchorPoint(cc.p(.5,.5))
        return n
    end
    local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setAnchorPoint(cc.p(.5,.5))
    n:setCascadeOpacityEnabled(true)
    if style=='ink' or style=='coral' then
        n:addChild(MasterTheme.material(style..'-brush.png',w,h))
    else
        local color=style=='section' and T.colors.paper or (T.colors[style] or T.colors.light)
        n:addChild(HomeTheme.rounded(w,h,color,math.min(7,h/2)))
        if h>35 then
            local edge=MasterTheme.material('currency-paper.png',w,math.min(12,h*.12))
            edge:setOpacity(110);n:addChild(edge)
        end
        if h>45 then HomeTheme.rule(n,12,1,w-24,T.colors.line) end
    end
    return n
end

function T.surfaceLike(path,style)
    local spr=cc.Sprite:create(path);local z=spr:getContentSize()
    return T.panel(z.width,z.height,style)
end

function T.face(w,h,style,glyph)
    local n=T.panel(w,h,style);n:setAnchorPoint(cc.p(0,0))
    if glyph then
        local color=(style=='ink' or style=='coral') and T.colors.white or T.colors.ink
        local art=icon(glyph,math.min(w,h)*.54,color)
        art:setPosition(cc.p((w-art:getContentSize().width)/2,(h-art:getContentSize().height)/2))
        n:addChild(art,2)
    end
    return n
end

function T.menuItem(w,h,style,glyph)
    local normal=T.face(w,h,style or 'coral',glyph)
    local selected=T.face(w,h,'ink',glyph)
    local item=cc.MenuItemSprite:create(normal,selected)
    item:setCascadeOpacityEnabled(true)
    return item
end

-- Smaller visible faces keep the original menu/SDButton bounds. The wrapper
-- is also the sprite whose bounds the SDButton touch listener reads.
function T.insetFace(w,h,style,glyph,visualSize)
    if not visualSize then return T.face(w,h,style,glyph) end
    local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setCascadeOpacityEnabled(true)
    local wide=type(visualSize)=='table'
    local vw,vh=wide and visualSize.width or visualSize,wide and visualSize.height or visualSize
    local visual=T.face(vw,vh,style,not wide and glyph or nil)
    if wide then
        local art=icon(glyph,36,T.colors.white)
        art:setPosition(cc.p(28,(vh-36)/2));visual:addChild(art,2)
        visual:addChild(T.label(visualSize.text,30,'action',vw*.61,vh*.5,.5),2)
    end
    visual:setPosition(cc.p((w-vw)/2,(h-vh)/2));n:addChild(visual)
    return n
end

function T.skinMenuItem(item,style,glyph,visualSize)
    local z=item:getContentSize()
    local selected=(style=='paper' or style=='light') and 'section' or 'ink'
    item:setNormalImage(T.insetFace(z.width,z.height,style or 'coral',glyph,visualSize))
    item:setSelectedImage(T.insetFace(z.width,z.height,selected,glyph,visualSize))
    return item
end

-- Keep the SDButton object, listener, callbacks and original-size hitbox.
-- Install before interactions start; its existing scheduler uses normalSpr.
function T.skinSDButton(button,style,glyph,visualSize)
    if button.managementSkinned then return button end
    local function face(sprite,selected)
        local z=sprite:getContentSize();local visible=sprite:isVisible()
        sprite:removeFromParent()
        local n=T.insetFace(z.width,z.height,selected and 'ink' or (style or 'coral'),glyph,visualSize)
        n:setVisible(visible);button:addChild(n)
        return n
    end
    button.normalSpr=face(button.normalSpr,false);button.selectSpr=face(button.selectSpr,true)
    if type(visualSize)=='table' then
        local extra=math.max(0,visualSize.width-button:getContentSize().width)
        local area=button.clickArea
        button:addClickArea(cc.rect(area.x-extra/2,area.y,area.width+extra,area.height))
    end
    button.managementSkinned=true
    return button
end

-- A light sheet frames real page contents without competing with item icons or
-- changing the legacy table, title, or footer safe areas.
function T.pagePaper(w,h,bottom,top)
    local n=T.panel(w,h,'paper');n:setAnchorPoint(cc.p(0,0))
    -- The entire legacy content area uses the same quiet cream surface as
    -- the clean voyage. Item illustrations provide the visual detail.
    local sheet=T.panel(w-16,h-bottom-top,'light')
    sheet:setPosition(cc.p(w/2,bottom+(h-bottom-top)/2));n:addChild(sheet)
    return n
end

function T.actionDock(w,h)
    local n=T.panel(w,h,'paper')
    HomeTheme.rule(n,16,h-1,w-32,T.colors.line)
    return n
end

function T.tab(text,selected,w,h)
    local item=T.menuItem(w or 104,h or 45,selected and 'ink' or 'section')
    item:addChild(T.label(text,24,selected and 'action' or 'body',(w or 104)/2,(h or 45)/2,.5),2)
    return item
end

function T.caption(sprite,text)
    local p=cc.p(sprite:getPositionX(),sprite:getPositionY());local opacity=sprite:getOpacity()
    local parent=sprite:getParent();sprite:removeFromParent()
    local n=T.label(text,24,'body',p.x,p.y,.5);n:setOpacity(opacity);parent:addChild(n,2)
    return n
end

return T
