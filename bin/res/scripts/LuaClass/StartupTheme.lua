-- Launch/loading presentation, preserving the original progress and scene flow.
require 'LuaClass/MasterTheme'
StartupTheme={}
local S=StartupTheme
local function warm()
    if rawget(_G,'WARM_PIRATE_V1')==false then return nil end
    local W=rawget(_G,'WarmTheme')
    if type(W)~='table' then
        local ok,value=pcall(require,'LuaClass/WarmTheme')
        if ok then W=value end
    end
    if type(W)=='table' and type(W.enabled)=='function' and W.enabled() then return W end
end
function S.background(size)
    local root=cc.Node:create();root:setContentSize(size);root:setAnchorPoint(cc.p(.5,.5))
    local W=warm()
    if W then
        root:addChild(W.panel(size.width,size.height,W.colors.sea,0))
        local art=W.cover(W.path..'sea-home.png',size.width,size.height)
        if art then root:addChild(art) end
        local ship=W.sprite(W.path..'ship-home.png',size.width*.8,size.height*.58)
        if ship then ship:setPosition(cc.p(size.width*.5,size.height*.54));root:addChild(ship) end
        -- The caller owns white loading tips/progress labels in the lower
        -- 240 pixels; retain an opaque warm backing at exactly that boundary.
        local wash=W.panel(size.width+20,240,W.colors.ink,24)
        wash:setPosition(cc.p(-10,0));root:addChild(wash)
        return root
    end
    local art=MasterTheme.cover('Images/UI/Adventure/Master/harbor-full.png',size.width,size.height)
    if art then root:addChild(art) end
    local wash=MasterTheme.material('ink-brush.png',size.width+20,240)
    wash:setPosition(cc.p(-10,0));root:addChild(wash)
    return root
end
function S.title()
    local W=warm()
    if W then return W.label('海盗远航',46,W.colors.ink,0,0,true,.5) end
    return MasterTheme.label('海盗远航',46,MasterTheme.colors.ink,0,0,true,.5)
end
function S.ship()
    local old=cc.Sprite:create('Images/UI/fmloding_01.png');local z=old:getContentSize()
    local root=cc.Node:create();root:setContentSize(z)
    local W=warm()
    if W then
        local icon=W.icon('sail',math.min(z.width,z.height))
        local a=icon:getContentSize();icon:setPosition(cc.p((z.width-a.width)/2,(z.height-a.height)/2))
        root:addChild(icon);return root
    end
    local s=cc.Sprite:create('Images/UI/Adventure/ship.png')
    if not s then return old end
    local a=s:getContentSize();s:setScale(math.min(z.width/a.width,z.height/a.height))
    s:setPosition(cc.p(z.width/2,z.height/2));root:addChild(s);return root
end
return S
