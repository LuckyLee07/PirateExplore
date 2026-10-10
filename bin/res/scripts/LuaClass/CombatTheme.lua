-- Presentation-only battle chrome. Actors, timing, damage and controls stay owned
-- by FightMode; these helpers never read or write player state.
require 'LuaClass/MasterTheme'
CombatTheme = {}
local C = CombatTheme
function C.deckPath(boarding)
    local path = 'Images/UI/Adventure/Combat/' .. (boarding and 'boarding-deck-b.png' or 'ship-deck-b.png')
    if cc.FileUtils:getInstance():isFileExist(path) then return path end
    return boarding and 'Images/Fight/chuan_01.png' or 'Images/Fight/chuan_04.png'
end
function C.chestPath(open)
    local path = 'Images/UI/Adventure/Combat/' .. (open and 'chest-open-b.png' or 'chest-closed-b.png')
    if cc.FileUtils:getInstance():isFileExist(path) then return path end
    return open and 'Images/Fight/baoxiang02.png' or 'Images/Fight/baoxiang01.png'
end
function C.captionPlate(parent, size, z)
    -- The ship deck reaches the top edge; put the existing white encounter
    -- sentence on ink while staying above the stars, HP plate and cannons.
    local plate = MasterTheme.material('ink-brush.png', size.width+20, 62)
    plate:setPosition(cc.p(-10, size.height-62))
    parent:addChild(plate, z or 0)
    return plate
end
function C.label(text, _, size)
    local label=cc.LabelTTF:create(text,MasterTheme.headingFont(size>=30),size)
    label:setColor(MasterTheme.colors.white)
    return label
end
function C.background(size)
    local root=cc.Node:create();root:setContentSize(size);root:setAnchorPoint(cc.p(0,0))
    local water=MasterTheme.cover('Images/UI/Adventure/SeaChart/Tiles/sea-water-repeat.png',size.width,size.height)
    root:addChild(water)
    local shade=cc.LayerColor:create(cc.c4b(3,35,48,85),size.width,size.height);root:addChild(shade)
    local top=MasterTheme.material('ink-brush.png',size.width+20,220)
    top:setPosition(cc.p(-10,size.height-220));root:addChild(top)
    local bottom=MasterTheme.material('ink-brush.png',size.width+20,105)
    bottom:setPosition(cc.p(-10,-10));root:addChild(bottom)
    return root
end
function C.bar(filled, width, height, side)
    width,height=width or 313,height or 23
    local color=filled and (side=='player' and cc.c3b(61,178,170) or MasterTheme.colors.coral) or cc.c3b(3,35,47)
    local bar=cc.Node:create();bar:setContentSize(cc.size(width,height))
    local face=HomeTheme.rounded(width,20,color,10)
    face:setPosition(cc.p(0,(height-20)*.5));bar:addChild(face)
    return bar
end
function C.statusPlate(parent,x,barY,z)
    local plate=MasterTheme.material('ink-brush.png',390,98)
    plate:setPosition(cc.p(x-195,barY-37));parent:addChild(plate,z or 0)
    return plate
end
return C
