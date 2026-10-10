-- Native presentation helpers for the approved 941 x 1672 departure sheet.
-- Artwork contains no inventory, labels, buttons, or other game state.
local M = require 'LuaClass/MasterTheme'
local D = {colors=M.colors, path='Images/UI/Adventure/Departure/'}

function D.label(text,size,color,x,y,anchor)
    return M.label(text,size,color,x,y,true,anchor or 0)
end
function D.image(path,w,h)
    if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
    local s=cc.Sprite:create(path)
    if not s then return nil end
    local z=s:getContentSize()
    s:setScale(math.min(w/z.width,h/z.height));s:setAnchorPoint(cc.p(.5,.5))
    s:setPosition(cc.p(w/2,h/2));return s
end
function D.material(name,w,h)
    local path=D.path..name
    if cc.FileUtils:getInstance():isFileExist(path) then
        local n=cc.Node:create();n:setContentSize(cc.size(w,h))
        local s=cc.Sprite:create(path);local z=s:getContentSize()
        s:setAnchorPoint(cc.p(0,0));s:setScaleX(w/z.width);s:setScaleY(h/z.height);n:addChild(s);return n
    end
    return M.material(name=='manifest-paper.png' and 'crew-paper.png' or name,w,h)
end
function D.menuItem(text,w,h,callback,opts)
    opts=opts or {}
    local function background(selected)
        if opts.clear then
            return cc.LayerColor:create(cc.c4b(8,53,68,selected and 18 or 0),w,h)
        end
        return M.material(opts.material or 'ink-brush.png',w,h,selected and cc.c3b(205,219,211) or nil)
    end
    local item=cc.MenuItemSprite:create(background(false),background(true))
    item.bLabel=D.label(text,opts.fontSize or 26,opts.textColor or M.colors.white,w/2,h/2,.5)
    item:addChild(item.bLabel,3)
    if callback then item:registerScriptTapHandler(callback) end
    return item
end
function D.quantity(button,text,w,h,fontSize)
    -- SDButton reads its invisible sprite bounds for taps and long-press.
    -- Keep the painted control unchanged, with a centered minimum 59-point
    -- target (44.25 pixels when the 640-point canvas is shown at 480 pixels).
    local targetW,targetH=math.max(59,w),math.max(59,h)
    for _,s in ipairs({button.normalSpr,button.selectSpr}) do
        local z=s:getContentSize()
        s:setScaleX(targetW/z.width);s:setScaleY(targetH/z.height)
        s:setPosition(cc.p((w-targetW)/2,(h-targetH)/2));s:setOpacity(0)
    end
    button:setContentSize(cc.size(w,h))
    button:addChild(M.material('ink-brush.png',w,h))
    button:addChild(D.label(text,fontSize,M.colors.white,w/2,h/2,.5))
end
function D.currencyIcon(kind,size)
    local n=cc.Node:create();n:setContentSize(cc.size(size,size))
    local asset=kind=='coin' and 'coin-detail.png' or 'gem-detail.png'
    local art=D.image(M.path..'Details/'..asset,size,size)
    if art then n:addChild(art);return n end
    local d=cc.DrawNode:create();n:addChild(d)
    local function p(x,y)return cc.p(x*size,y*size)end
    if kind=='coin' then
        local gold=HomeTheme.rgba(cc.c3b(211,144,37));local light=HomeTheme.rgba(cc.c3b(255,220,115))
        d:drawDot(p(.5,.5),size*.48,gold);d:drawDot(p(.5,.5),size*.39,light)
        d:drawDot(p(.5,.54),size*.23,gold)
        d:drawDot(p(.41,.57),size*.038,light);d:drawDot(p(.59,.57),size*.038,light)
        d:drawSegment(p(.4,.30),p(.6,.30),size*.055,gold)
    else
        local blue=HomeTheme.rgba(cc.c3b(15,158,217));local light=HomeTheme.rgba(cc.c3b(143,238,255))
        local points={p(.05,.67),p(.25,.95),p(.75,.95),p(.95,.67),p(.5,.04)}
        d:drawPolygon(points,#points,blue,0,blue)
        d:drawSegment(p(.05,.67),p(.95,.67),size*.018,light)
        d:drawSegment(p(.30,.95),p(.5,.04),size*.018,light)
        d:drawSegment(p(.70,.95),p(.5,.04),size*.018,light)
    end
    return n
end
function D.compass(size)
    local n=cc.Node:create();local d=cc.DrawNode:create();n:addChild(d)
    local ink=HomeTheme.rgba(M.colors.ink)
    for i=0,31 do
        local a=i*math.pi/16;local b=(i+1)*math.pi/16
        d:drawSegment(cc.p(math.cos(a)*size*.22,math.sin(a)*size*.22),cc.p(math.cos(b)*size*.22,math.sin(b)*size*.22),size*.012,ink)
    end
    d:drawSegment(cc.p(-size*.48,0),cc.p(size*.48,0),size*.012,ink)
    d:drawSegment(cc.p(0,-size*.48),cc.p(0,size*.48),size*.012,ink)
    d:drawTriangle(cc.p(0,size*.4),cc.p(-size*.065,0),cc.p(size*.065,0),ink)
    d:drawTriangle(cc.p(0,-size*.4),cc.p(-size*.065,0),cc.p(size*.065,0),ink)
    return n
end
-- Keep the enlarged painted item intact while breaking its crop's straight
-- blue border. The shallow native brush edge only removes the outer margin.
local function itemBrushStencil(w,h)
    local d=cc.DrawNode:create();local c=HomeTheme.rgba(cc.c3b(255,255,255))
    local points={{0,.09},{.02,.15},{0,.22},{.025,.29},{.006,.41},{.027,.51},
        {.008,.62},{.03,.72},{.013,.84},{.04,.93},{.12,.96},{.18,.99},
        {.26,.965},{.36,1},{.44,.975},{.52,.994},{.63,.978},{.71,1},
        {.80,.971},{.90,.989},{.97,.94},{.956,.87},{.995,.79},{.977,.70},
        {1,.61},{.978,.51},{.996,.40},{.97,.30},{.988,.22},{.96,.12},
        {.90,.046},{.82,.028},{.75,.05},{.67,.014},{.59,.035},{.49,.013},
        {.42,.037},{.32,.014},{.24,.039},{.16,.01},{.09,.046}}
    -- A triangle fan handles this star-shaped stencil without concave polygon
    -- triangulation differences between the desktop and mobile renderers.
    for i,a in ipairs(points) do
        local b=points[i%#points+1]
        d:drawTriangle(cc.p(w/2,h/2),cc.p(a[1]*w,a[2]*h),cc.p(b[1]*w,b[2]*h),c)
    end
    return d
end

function D.portrait(data,w,h)
    local n=cc.Node:create();n:setContentSize(cc.size(w,h))
    local id=tostring(data[dataKeyID]);local realId=tonumber(id)
    local art,hasBrush
    if realId and realId>=10000 then
        art=M.portrait(tostring(realId-10000),w,h)
    elseif id=='1005' or id=='1037' or id=='1038' or id=='1061' then
        local atlas='Images/UI/Adventure/Pages/icons.png'
        if cc.FileUtils:getInstance():isFileExist(atlas) then
            -- Tight native crop keeps the item itself comparable to crew portraits.
            -- The source's wide transparent/brush margin is not part of the hit area.
            local r=id=='1005' and {120,140,308,294} or {614,139,316,292}
            art=cc.Sprite:create(atlas,cc.rect(unpack(r)))
            local z=art:getContentSize();art:setScale(math.min(w/z.width,h/z.height))
            art:setAnchorPoint(cc.p(.5,.5));art:setPosition(cc.p(w/2,h/2));hasBrush=true
            if cc.ClippingNode then
                local paintW,paintH=z.width*art:getScale(),z.height*art:getScale()
                local stencil=itemBrushStencil(paintW,paintH)
                stencil:setPosition(cc.p((w-paintW)/2,(h-paintH)/2))
                local clip=cc.ClippingNode:create();clip:setContentSize(cc.size(w,h))
                clip:setStencil(stencil);clip:setAlphaThreshold(.1);clip:addChild(art);art=clip
            end
        else art=D.image(D.path..(id=='1005' and 'food.png' or 'key.png'),w,h) end
    end
    if not art and data.icon and data.icon~='' then art=D.image('Images/Icon/'..data.icon,w*.88,h*.88)
        if art then art:setPosition(cc.p(w/2,h/2)) end
    end
    if not art then
        local kind=(realId and realId>=10000) and 'crew' or (id=='1005' and 'food' or 'key')
        art=M.icon(kind,math.min(w,h)*.75,M.colors.paper);art:setPosition(cc.p(w*.125,h*.125))
    end
    if not hasBrush then n:addChild(M.portraitBrush(w,h)) end
    n:addChild(art);return n
end

function D.readinessIcon(size)
    local n=cc.Node:create();n:setContentSize(cc.size(size,size));local d=cc.DrawNode:create();n:addChild(d)
    local function draw(ready)
        d:clear();local c=HomeTheme.rgba(ready and cc.c3b(100,138,66) or cc.c3b(152,131,81))
        d:drawDot(cc.p(size/2,size/2),size*.45,c)
        local white=HomeTheme.rgba(M.colors.white)
        if ready then
            d:drawSegment(cc.p(size*.25,size*.5),cc.p(size*.44,size*.31),size*.055,white)
            d:drawSegment(cc.p(size*.44,size*.31),cc.p(size*.76,size*.72),size*.055,white)
        else
            d:drawSegment(cc.p(size*.5,size*.72),cc.p(size*.5,size*.43),size*.045,white)
            d:drawDot(cc.p(size*.5,size*.25),size*.045,white)
        end
    end
    n.update=draw;draw(false);return n
end
return D
