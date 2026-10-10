-- Explicit presentation helpers for the B adventure dialogs and side pages.
-- Legacy assets are measured only: their geometry, touch targets and callbacks
-- remain the caller's contract. No engine APIs or game data are patched.
require 'LuaClass/MasterTheme'
DialogTheme = {}
local D = DialogTheme
local M = MasterTheme
D.colors = M.colors
D.raised = cc.c3b(15, 61, 73)
D.line = cc.c3b(100, 126, 124)
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
    local color = paper and M.colors.paper or D.raised
    if tone == 'ink' or tone == 'panel' then color = M.colors.ink end
    if selected then color = paper and cc.c3b(224, 217, 194) or cc.c3b(34, 91, 102) end
    local field = HomeTheme.rounded(w, h, color, math.min(6,w*.5,h*.5))
    n:addChild(field)
    -- Paper/ink edges replace the old luminous rectangular outlines. Content
    -- geometry and all caller-owned label colors remain unchanged.
    if paper then
        n:addChild(M.material('crew-paper.png',w,h))
    else
        local edgeHeight=math.min(16,h*.18)
        local edge=M.material('ink-brush.png',w,edgeHeight)
        edge:setPosition(cc.p(0,h-edgeHeight));n:addChild(edge)
        HomeTheme.rule(n,14,5,math.max(0,w-28),cc.c3b(50,84,89))
    end
    if tone == 'panel' then
        -- A quiet opaque interior keeps all existing white caller labels legible.
        local wash = M.material('ink-brush.png', w-8, math.min(88, h*.22))
        wash:setPosition(cc.p(4, h-math.min(88, h*.22)-4));n:addChild(wash)
        HomeTheme.rule(n, 24, h-77, math.max(0, w-48), D.line)
    end
    return n
end

-- A single continuous parchment under a real list, not a rectangle per row.
function D.paperSheet(w,h)
    local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setAnchorPoint(cc.p(.5,.5))
    local path='Images/UI/Adventure/Talent/paper.png'
    if cc.FileUtils:getInstance():isFileExist(path) then
        local paper=cc.Sprite:create(path);local z=paper:getContentSize()
        paper:setScaleX(w/z.width);paper:setScaleY(h/z.height)
        paper:setAnchorPoint(cc.p(0,0));n:addChild(paper)
    else n:addChild(HomeTheme.rounded(w,h,M.colors.paper,5)) end
    return n
end

function D.ledgerRow(w,h)
    local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setAnchorPoint(cc.p(.5,.5))
    HomeTheme.rule(n,16,2,w-32,cc.c3b(208,196,166))
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
    d:drawPolygon(p,#p,cc.c4f(0,0,0,0),1.5,HomeTheme.rgba(M.colors.coral));n:addChild(d)
    return n
end
function D.badgeFromLegacy(path, text, color)
    local z=D.legacySize(path);local n=cc.Node:create();n:setContentSize(z);n:setAnchorPoint(cc.p(.5,.5))
    local label=D.label(text,math.min(24,z.height*.58),color or M.colors.paper)
    D.fit(label,z.width-8);label:setPosition(cc.p(z.width*.5,z.height*.5));n:addChild(label)
    return n
end

function D.buttonFace(path, tone, selected)
    local z = D.legacySize(path)
    local n = cc.Node:create();n:setContentSize(z);n:setAnchorPoint(cc.p(.5,.5))
    n:setCascadeOpacityEnabled(true)
    local material = tone == 'secondary' and 'ink-brush.png' or 'coral-brush.png'
    local paint = M.material(material, z.width, z.height, selected and cc.c3b(196,210,205) or nil)
    n:addChild(cascade(paint))
    if tone == 'secondary' then
        HomeTheme.rule(n, 12, 5, math.max(0,z.width-24), D.line)
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
    local z=D.legacySize(path);local n=D.card(z.width,z.height,'ink',selected)
    local d=cc.DrawNode:create();local color=HomeTheme.rgba(M.colors.paper)
    d:drawSegment(cc.p(z.width*.34,z.height*.34),cc.p(z.width*.66,z.height*.66),1.5,color)
    d:drawSegment(cc.p(z.width*.34,z.height*.66),cc.p(z.width*.66,z.height*.34),1.5,color)
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

function D.label(text, size, color)
    local n=M.label(text,size,color or M.colors.white,0,0,true,.5)
    return n
end
function D.fit(label, width) return M.fit(label, width) end

function D.screen(parent, size)
    local field=cc.LayerColor:create(cc.c4b(8,53,68,255),size.width,size.height)
    parent:addChild(field,-20)
    local art=M.cover(M.path..'harbor-full.png',size.width,size.height)
    if art then art:setOpacity(38);parent:addChild(art,-19) end
    return field
end

function D.rule(parent, x, y, width) return HomeTheme.rule(parent,x,y,width,D.line) end

function D.skinMenuItem(item, tone)
    local z=item:getContentSize()
    local function face(selected)
        local n=cc.Node:create();n:setContentSize(z);n:setCascadeOpacityEnabled(true)
        n:addChild(cascade(M.material(tone=='secondary' and 'ink-brush.png' or 'coral-brush.png',z.width,z.height,
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
    view.titleLabel=D.label(title,38,M.colors.ink)
    view.titleLabel:setPosition(cc.p(z.width*.5,view.titleHeight*.5))
    view.titleBg:addChild(view.titleLabel)
    -- Empty native placeholders retain the title layout/visibility contract.
    view.LeftBg=cc.Node:create();view.RightBg=cc.Node:create()
    view.LeftBg:setContentSize(cc.size(34,2));view.RightBg:setContentSize(cc.size(34,2))
    view.LeftBg:setPosition(cc.p(z.width*.28,view.titleHeight*.5))
    view.RightBg:setPosition(cc.p(z.width*.72,view.titleHeight*.5))
    view.titleBg:addChild(view.LeftBg);view.titleBg:addChild(view.RightBg)
    D.skinMenuItem(view.topLeftBtn,'secondary');D.skinMenuItem(view.topRightBtn,'secondary')
    view.topLeftBtnLabel:setFontName(M.headingFont(true))
    view.topRightBtnLabel:setFontName(M.headingFont(true))
    view.topLeftBtnLabel:setColor(M.colors.white);view.topRightBtnLabel:setColor(M.colors.white)
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
            label:setFontName(M.headingFont(false));label:setFontSize(22)
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
                local visual=cascade(M.material(i==1 and 'coral-brush.png' or 'ink-brush.png',92,92))
                visual:setPosition(cc.p((b.width-92)*.5,(b.height-92)*.5));face:addChild(visual)
                local icon=M.icon('anchor',50)
                icon:setPosition(cc.p((b.width-icon:getContentSize().width)*.5,(b.height-icon:getContentSize().height)*.5))
                face:addChild(icon);button:addChild(face)
            end
            button.normalSpr:setVisible(normalVisible);button.selectSpr:setVisible(selectedVisible)
        end
        skinSD(view.setBtn)
        view.setButtonProgrees:setLocalZOrder(1);view.setButtonProgrees:setColor(M.colors.coral)
        view.setButtonProgrees:setOpacity(105)
        view.setButtonProgrees:setScale(92/view.setBtn:getContentSize().width)
        view.setBtnText:setPositionY(view.setBtn:getPositionY()-60)
        view.leftBtnText:setPositionY(view.leftBtn:getPositionY()-56)
        view.rightBtnText:setPositionY(view.rightBtn:getPositionY()-56)
        D.skinMenuItem(view.leftBtn,'secondary');D.skinMenuItem(view.rightBtn,'secondary')
        for _,entry in ipairs({{view.leftBtn,'key'},{view.rightBtn,'sail'}}) do
            local b=entry[1]:getContentSize();local icon=M.icon(entry[2],math.min(b.width,b.height)*.5)
            icon:setPosition(cc.p((b.width-icon:getContentSize().width)*.5,(b.height-icon:getContentSize().height)*.5))
            entry[1]:addChild(icon)
        end
        D.surfaceAfterSizing(view.bottomInfoBox,'ink')
        view.infoBoxLabel:setColor(M.colors.white);view.infoLabel:setColor(M.colors.white)
        view.infoBoxLabel:setFontName(M.headingFont(false));view.infoLabel:setFontName(M.headingFont(false))
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
    local price=D.label(tostring(offer.money)..' 元',30,M.colors.paper)
    price:setPosition(cc.p(z.width-80,z.height*.72));item:addChild(price)
    local action=M.material('coral-brush.png',128,51)
    action:setPosition(cc.p(z.width-144,24));item:addChild(action)
    local caption=D.label('购 买',26);caption:setPosition(cc.p(z.width-80,49));item:addChild(caption)
    if offer.bg=='Images/charging/cz_03.png' then
        local recommended=D.label('推荐',20,M.colors.coral)
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
