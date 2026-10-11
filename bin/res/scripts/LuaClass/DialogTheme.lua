-- Shared legacy dialogs and side pages, with an opt-out warm v1 presentation.
-- Legacy assets are measured only: their geometry, touch targets and callbacks
-- remain the caller's contract. No engine APIs or game data are patched.
require 'LuaClass/MasterTheme'
DialogTheme = {}
local D = DialogTheme
local M = MasterTheme
local function warm()
    if rawget(_G,'WARM_PIRATE_V1')==false then return nil end
    local W=rawget(_G,'WarmTheme')
    if type(W)~='table' then
        local ok,value=pcall(require,'LuaClass/WarmTheme')
        if ok then W=value end
    end
    if type(W)=='table' and type(W.enabled)=='function' and W.enabled() then return W end
end
local function palette(key)
    local W=warm();return W and (key=='coral' and W.colors.sea or W.colors[key]) or M.colors[key]
end
D.colors=setmetatable({},{__index=function(_,key)return palette(key)end})
D.raised = cc.c3b(15, 61, 73)
D.line = cc.c3b(100, 126, 124)
local function lineColor()
    return warm() and cc.c3b(81,110,111) or D.line
end
local function material(name,w,h,tint)
    local W=warm()
    if not W then return M.material(name,w,h,tint) end
    local c=name=='coral-brush.png' and W.colors.sea or
        (name=='ink-brush.png' and W.colors.ink or W.colors.paper)
    if tint then c=cc.c3b(c.r*tint.r/255,c.g*tint.g/255,c.b*tint.b/255) end
    return W.panel(w,h,c,math.min(8,h/2))
end
local sizes = {}
local function cascade(node)
    node:setCascadeOpacityEnabled(true)
    for _,child in ipairs(node:getChildren()) do cascade(child) end
    return node
end

function D.legacySize(path)
    if not sizes[path] then
        local sprite = cc.Sprite:create(path)
        assert(sprite, 'Missing dialog geometry asset: '..tostring(path))
        local size = sprite:getContentSize()
        sizes[path] = {width=size.width, height=size.height}
    end
    return cc.size(sizes[path].width, sizes[path].height)
end

local function surface(w, h, tone, selected)
    local n = cc.Node:create()
    n:setContentSize(cc.size(w, h))
    n:setAnchorPoint(cc.p(.5, .5))
    n:setCascadeOpacityEnabled(true)
    local paper = tone == 'paper'
    local W=warm()
    if W then
        -- Unknown caller-owned white labels require a dark body. Only callers
        -- explicitly asking for paper receive a light surface.
        local c=paper and W.colors.paper or cc.c3b(48,78,83)
        if tone=='ink' or tone=='panel' then c=W.colors.ink end
        if selected then c=paper and cc.c3b(235,240,223) or cc.c3b(50,88,91) end
        n:addChild(W.panel(w,h,c,math.min(8,w/2,h/2)))
        if tone=='panel' and h>110 then
            HomeTheme.rule(n,24,h-77,math.max(0,w-48),lineColor())
        end
        return n
    end
    local color = paper and palette('paper') or D.raised
    if tone == 'ink' or tone == 'panel' then color = palette('ink') end
    if selected then color = paper and cc.c3b(224, 217, 194) or cc.c3b(34, 91, 102) end
    local field = HomeTheme.rounded(w, h, color, math.min(6,w*.5,h*.5))
    n:addChild(field)
    -- Paper/ink edges replace the old luminous rectangular outlines. Content
    -- geometry and all caller-owned label colors remain unchanged.
    if paper then
        n:addChild(material('crew-paper.png',w,h))
    else
        local edgeHeight=math.min(16,h*.18)
        local edge=material('ink-brush.png',w,edgeHeight)
        edge:setPosition(cc.p(0,h-edgeHeight));n:addChild(edge)
        HomeTheme.rule(n,14,5,math.max(0,w-28),cc.c3b(50,84,89))
    end
    if tone == 'panel' then
        -- A quiet opaque interior keeps all existing white caller labels legible.
        local wash = material('ink-brush.png', w-8, math.min(88, h*.22))
        wash:setPosition(cc.p(4, h-math.min(88, h*.22)-4));n:addChild(wash)
        HomeTheme.rule(n, 24, h-77, math.max(0, w-48), D.line)
    end
    return n
end

-- A single continuous parchment under a real list, not a rectangle per row.
function D.paperSheet(w,h)
    local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setAnchorPoint(cc.p(.5,.5))
    local W=warm()
    if W then n:addChild(W.panel(w,h,W.colors.paper,8));return n end
    local path='Images/UI/Adventure/Talent/paper.png'
    if cc.FileUtils:getInstance():isFileExist(path) then
        local paper=cc.Sprite:create(path);local z=paper:getContentSize()
        paper:setScaleX(w/z.width);paper:setScaleY(h/z.height)
        paper:setAnchorPoint(cc.p(0,0));n:addChild(paper)
    else n:addChild(HomeTheme.rounded(w,h,palette('paper'),5)) end
    return n
end

function D.ledgerRow(w,h)
    local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setAnchorPoint(cc.p(.5,.5))
    HomeTheme.rule(n,16,2,w-32,warm() and palette('line') or cc.c3b(208,196,166))
    return n
end

function D.panel(w, h) return surface(w, h, 'panel') end
function D.card(w, h, tone, selected) return surface(w, h, tone or 'card', selected) end
function D.panelFromLegacy(path)
    local z = D.legacySize(path);return D.panel(z.width, z.height)
end
function D.cardFromLegacy(path, tone, selected)
    local z = D.legacySize(path);return D.card(z.width, z.height, tone, selected)
end
function D.outlineFromLegacy(path)
    local z=D.legacySize(path);local n=cc.Node:create();n:setContentSize(z);n:setAnchorPoint(cc.p(.5,.5))
    local d=cc.DrawNode:create();local p={cc.p(2,2),cc.p(z.width-2,2),cc.p(z.width-2,z.height-2),cc.p(2,z.height-2)}
    d:drawPolygon(p,#p,cc.c4f(0,0,0,0),1.5,HomeTheme.rgba(palette('coral')));n:addChild(d)
    return n
end
function D.badgeFromLegacy(path, text, color)
    local z=D.legacySize(path);local n=cc.Node:create();n:setContentSize(z);n:setAnchorPoint(cc.p(.5,.5))
    local label=D.label(text,math.min(24,z.height*.58),color or palette('paper'))
    D.fit(label,z.width-8);label:setPosition(cc.p(z.width*.5,z.height*.5));n:addChild(label)
    return n
end

function D.buttonFace(path, tone, selected)
    local z = D.legacySize(path)
    local n = cc.Node:create();n:setContentSize(z);n:setAnchorPoint(cc.p(.5,.5))
    n:setCascadeOpacityEnabled(true)
    local paintName = tone == 'secondary' and 'ink-brush.png' or 'coral-brush.png'
    local paint = material(paintName, z.width, z.height, selected and cc.c3b(196,210,205) or nil)
    n:addChild(cascade(paint))
    if tone == 'secondary' then
        HomeTheme.rule(n, 12, 5, math.max(0,z.width-24), lineColor())
    end
    return n
end

function D.menuItem(normal, selected, tone)
    return cc.MenuItemSprite:create(D.buttonFace(normal, tone),
        D.buttonFace(selected or normal, tone, true), D.cardFromLegacy(normal, 'ink', true))
end

function D.sdButton(normal, selected, callback, tone)
    -- Keep SDButton's custom hit area, scroll handling, long presses and state.
    local button = SDButton:create(normal, selected or normal, callback)
    button.normalSpr:removeFromParent(true)
    button.selectSpr:removeFromParent(true)
    button.normalSpr = D.buttonFace(normal, tone)
    button.selectSpr = D.buttonFace(selected or normal, tone, true)
    button.normalSpr:setAnchorPoint(cc.p(0,0));button.selectSpr:setAnchorPoint(cc.p(0,0))
    button:addChild(button.normalSpr);button:addChild(button.selectSpr)
    button:setActive(false)
    return button
end

function D.closeFace(path, selected)
    local W=warm()
    local z=D.legacySize(path);local n=D.card(z.width,z.height,W and 'paper' or 'ink',selected)
    local d=cc.DrawNode:create();local stroke=HomeTheme.rgba(W and W.colors.ink or palette('paper'))
    d:drawSegment(cc.p(z.width*.34,z.height*.34),cc.p(z.width*.66,z.height*.66),1.5,stroke)
    d:drawSegment(cc.p(z.width*.34,z.height*.66),cc.p(z.width*.66,z.height*.34),1.5,stroke)
    n:addChild(d);return n
end
function D.closeItem(path)
    path=path or 'Images/UI/cancel_button.png'
    return cc.MenuItemSprite:create(D.closeFace(path),D.closeFace(path,true))
end
function D.closeSD(callback)
    local path='Images/UI/cancel_button.png'
    local button=SDButton:create(path,path,callback)
    button.normalSpr:removeFromParent(true);button.selectSpr:removeFromParent(true)
    button.normalSpr=D.closeFace(path);button.selectSpr=D.closeFace(path,true)
    button.normalSpr:setAnchorPoint(cc.p(0,0));button.selectSpr:setAnchorPoint(cc.p(0,0))
    button:addChild(button.normalSpr);button:addChild(button.selectSpr);button:setActive(false)
    return button
end

local function font(strong)
    local W=warm();return W and W.font or M.headingFont(strong)
end
local function icon(name,size)
    local W=warm();return W and W.icon(name,size,W.colors.white) or M.icon(name,size)
end
function D.label(text, size, color)
    local n=M.label(text,size,color or palette('white'),0,0,true,.5)
    n:setFontName(font(true))
    return n
end
function D.fit(label, width) return M.fit(label, width) end

function D.screen(parent, size)
    local W=warm();local ink=palette('ink')
    local field=cc.LayerColor:create(cc.c4b(ink.r,ink.g,ink.b,255),size.width,size.height)
    parent:addChild(field,-20)
    if not W then
        local art=M.cover(M.path..'harbor-full.png',size.width,size.height)
        if art then art:setOpacity(38);parent:addChild(art,-19) end
    end
    return field
end

function D.rule(parent, x, y, width) return HomeTheme.rule(parent,x,y,width,lineColor()) end

function D.skinMenuItem(item, tone)
    local z=item:getContentSize()
    local function face(selected)
        local n=cc.Node:create();n:setContentSize(z);n:setCascadeOpacityEnabled(true)
        n:addChild(cascade(material(tone=='secondary' and 'ink-brush.png' or 'coral-brush.png',z.width,z.height,
            selected and cc.c3b(196,210,205) or nil)))
        return n
    end
    item:setNormalImage(face(false));item:setSelectedImage(face(true))
end

function D.applyBase(view)
    if view.dialogTheme then return end
    view.dialogTheme=true
    local z=cc.Director:getInstance():getVisibleSize()
    -- Preserve the original sprite references used by BaseView's public API.
    view.mainBg:setVisible(false)
    D.screen(view,z)
    local title=view.titleLabel:getString()
    local x,y=view.titleBg:getPosition()
    view.titleBg:removeFromParent(true)
    view.titleBg=D.card(z.width,view.titleHeight,'paper')
    view.titleBg:setPosition(cc.p(x,y));view:addChild(view.titleBg)
    view.titleLabel=D.label(title,38,palette('ink'))
    view.titleLabel:setPosition(cc.p(z.width*.5,view.titleHeight*.5))
    view.titleBg:addChild(view.titleLabel)
    -- Empty native placeholders retain the title layout/visibility contract.
    view.LeftBg=cc.Node:create();view.RightBg=cc.Node:create()
    view.LeftBg:setContentSize(cc.size(34,2));view.RightBg:setContentSize(cc.size(34,2))
    view.LeftBg:setPosition(cc.p(z.width*.28,view.titleHeight*.5))
    view.RightBg:setPosition(cc.p(z.width*.72,view.titleHeight*.5))
    view.titleBg:addChild(view.LeftBg);view.titleBg:addChild(view.RightBg)
    D.skinMenuItem(view.topLeftBtn,'secondary');D.skinMenuItem(view.topRightBtn,'secondary')
    view.topLeftBtnLabel:setFontName(font(true))
    view.topRightBtnLabel:setFontName(font(true))
    view.topLeftBtnLabel:setColor(palette('white'));view.topRightBtnLabel:setColor(palette('white'))
    D.fit(view.titleLabel,z.width*.40)
    if view.infoNode then
        -- This opt-in page has the original alchemy footer. Cover decorative
        -- chrome, raise the same interactive nodes, and retain their lock alpha.
        local h=view.infoNode:getContentSize().height
        local footer=D.card(z.width,h,'ink');footer:setPosition(cc.p(z.width*.5,h*.5))
        view.infoNode:addChild(footer,1)
        view.setBtn:setLocalZOrder(2);view.leftBtn:getParent():setLocalZOrder(2)
        view.infoScrollView:setLocalZOrder(2)
        for _,entry in ipairs({{'setBtnText','炼金'},{'leftBtnText','天赋'},{'rightBtnText','情报'}}) do
            local old=view[entry[1]];local label=D.label(entry[2],24)
            label:setPosition(old:getPosition());label:setOpacity(old:getOpacity())
            label:setFontName(font(false));label:setFontSize(22)
            old:removeFromParent(true);view.infoNode:addChild(label,3);view[entry[1]]=label
        end
        local function skinSD(button)
            local normal,selected=button.normalSpr,button.selectSpr
            local normalVisible,selectedVisible=normal:isVisible(),selected:isVisible()
            local b=button:getContentSize()
            normal:removeFromParent(true);selected:removeFromParent(true)
            button.normalSpr=cc.Node:create();button.selectSpr=cc.Node:create()
            for i,face in ipairs({button.normalSpr,button.selectSpr}) do
                face:setContentSize(b);face:setCascadeOpacityEnabled(true)
                face:setAnchorPoint(cc.p(0,0))
                local visual=cascade(material(i==1 and 'coral-brush.png' or 'ink-brush.png',92,92))
                visual:setPosition(cc.p((b.width-92)*.5,(b.height-92)*.5));face:addChild(visual)
                local glyph=icon('anchor',50)
                glyph:setPosition(cc.p((b.width-glyph:getContentSize().width)*.5,(b.height-glyph:getContentSize().height)*.5))
                face:addChild(glyph);button:addChild(face)
            end
            button.normalSpr:setVisible(normalVisible);button.selectSpr:setVisible(selectedVisible)
        end
        skinSD(view.setBtn)
        view.setButtonProgrees:setLocalZOrder(1);view.setButtonProgrees:setColor(palette('coral'))
        view.setButtonProgrees:setOpacity(105)
        view.setButtonProgrees:setScale(92/view.setBtn:getContentSize().width)
        view.setBtnText:setPositionY(view.setBtn:getPositionY()-60)
        view.leftBtnText:setPositionY(view.leftBtn:getPositionY()-56)
        view.rightBtnText:setPositionY(view.rightBtn:getPositionY()-56)
        D.skinMenuItem(view.leftBtn,'secondary');D.skinMenuItem(view.rightBtn,'secondary')
        for _,entry in ipairs({{view.leftBtn,'key'},{view.rightBtn,'sail'}}) do
            local b=entry[1]:getContentSize();local glyph=icon(entry[2],math.min(b.width,b.height)*.5)
            glyph:setPosition(cc.p((b.width-glyph:getContentSize().width)*.5,(b.height-glyph:getContentSize().height)*.5))
            entry[1]:addChild(glyph)
        end
        D.surfaceAfterSizing(view.bottomInfoBox,'ink')
        view.infoBoxLabel:setColor(palette('white'));view.infoLabel:setColor(palette('white'))
        view.infoBoxLabel:setFontName(font(false));view.infoLabel:setFontName(font(false))
        view.infoBoxLabel:disableStroke();view.infoLabel:disableStroke()
        view.infoLabel:setFontSize(22)
    end
end

function D.chargeOffer(offer)
    local z=D.legacySize(offer.bg)
    local item=cc.MenuItemSprite:create(D.card(z.width,z.height),D.card(z.width,z.height,'card',true))
    local icon=cc.Sprite:create('Images/UI/DiamondBg.png')
    icon:setPosition(cc.p(68,z.height*.56));item:addChild(icon)
    local quantity=D.label(tostring(offer.diamond)..' 钻石',36)
    quantity:setAnchorPoint(cc.p(0,.5));quantity:setPosition(cc.p(118,z.height*.61));item:addChild(quantity)
    local price=D.label(tostring(offer.money)..' 元',30,palette('paper'))
    price:setPosition(cc.p(z.width-80,z.height*.72));item:addChild(price)
    local action=material('coral-brush.png',128,51)
    action:setPosition(cc.p(z.width-144,24));item:addChild(action)
    local caption=D.label('购 买',26);caption:setPosition(cc.p(z.width-80,49));item:addChild(caption)
    if offer.bg=='Images/charging/cz_03.png' then
        local recommended=D.label('推荐',20,palette('coral'))
        recommended:setPosition(cc.p(68,26));item:addChild(recommended)
    end
    return item
end

-- Used only after a legacy Scale9Sprite has reached its final dimensions.
-- Keep the actual Scale9Sprite contract where callers need its resize methods.
function D.surfaceAfterSizing(node, tone)
    local z=node:getContentSize()
    node:setCascadeOpacityEnabled(false);node:setOpacity(0)
    local face=tone=='ledger' and D.ledgerRow(z.width,z.height) or D.card(z.width,z.height,tone)
    face:setAnchorPoint(cc.p(0,0));node:addChild(face,-1)
    return node
end

return D
