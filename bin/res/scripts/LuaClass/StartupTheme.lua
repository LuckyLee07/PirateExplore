-- Launch/loading presentation, preserving the original progress and scene flow.
require 'LuaClass/MasterTheme'
StartupTheme={}
local S=StartupTheme
function S.background(size)
    local root=cc.Node:create();root:setContentSize(size);root:setAnchorPoint(cc.p(.5,.5))
    local art=MasterTheme.cover('Images/UI/Adventure/Master/harbor-full.png',size.width,size.height)
    if art then root:addChild(art) end
    local wash=MasterTheme.material('ink-brush.png',size.width+20,240)
    wash:setPosition(cc.p(-10,0));root:addChild(wash)
    return root
end
function S.title()
    return MasterTheme.label('海盗远航',46,MasterTheme.colors.ink,0,0,true,.5)
end
function S.ship()
    local old=cc.Sprite:create('Images/UI/fmloding_01.png');local z=old:getContentSize()
    local root=cc.Node:create();root:setContentSize(z)
    local s=cc.Sprite:create('Images/UI/Adventure/ship.png')
    if not s then return old end
    local a=s:getContentSize();s:setScale(math.min(z.width/a.width,z.height/a.height))
    s:setPosition(cc.p(z.width/2,z.height/2));root:addChild(s);return root
end
return S
