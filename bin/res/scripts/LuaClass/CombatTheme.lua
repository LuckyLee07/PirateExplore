-- Presentation-only battle chrome. Actors, timing, damage and controls stay owned
-- by FightMode; these helpers never read or write player state.
require 'LuaClass/MasterTheme'
CombatTheme = {}
local C = CombatTheme
local function warm()
    if rawget(_G,'WARM_PIRATE_V1')==false then return nil end
    local W=rawget(_G,'WarmTheme')
    if type(W)~='table' then
        local ok,value=pcall(require,'LuaClass/WarmTheme');if ok then W=value end
    end
    if type(W)=='table' and type(W.enabled)=='function' and W.enabled() then return W end
end
local function inkPlate(w,h)
    local W=warm()
    return W and W.panel(w,h,W.colors.ink,8) or MasterTheme.material('ink-brush.png',w,h)
end
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
    local plate = inkPlate(size.width+20,62)
    plate:setPosition(cc.p(-10, size.height-62))
    parent:addChild(plate, z or 0)
    return plate
end
function C.label(text, _, size)
    local W=warm()
    local label=cc.LabelTTF:create(text,W and W.font or MasterTheme.headingFont(size>=30),size)
    label:setColor(W and W.colors.white or MasterTheme.colors.white)
    return label
end
function C.background(size)
    local root=cc.Node:create();root:setContentSize(size);root:setAnchorPoint(cc.p(0,0))
    local W=warm()
    if W then
        local sea=cc.LayerColor:create(cc.c4b(58,176,181,255),size.width,size.height)
        root:addChild(sea)
        local path='Images/UI/CleanVoyage/sea-turquoise-caustics.png'
        local water=W.cover(path,size.width,size.height)
        if water then root:addChild(water) end
        -- Existing bottom action captions stay white. Keep their original safe
        -- strip, without darkening the sunny water or framing it with brushes.
        local bottom=inkPlate(size.width+20,105)
        bottom:setPosition(cc.p(-10,-10));root:addChild(bottom)
        return root
    end
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
    local W=warm()
    local color=filled and (side=='player' and (W and W.colors.sea or cc.c3b(61,178,170)) or
        (W and W.colors.coral or MasterTheme.colors.coral)) or (W and cc.c3b(24,46,50) or cc.c3b(3,35,47))
    local bar=cc.Node:create();bar:setContentSize(cc.size(width,height))
    local face=W and W.panel(width,20,color,4) or HomeTheme.rounded(width,20,color,10)
    face:setPosition(cc.p(0,(height-20)*.5));bar:addChild(face)
    return bar
end
function C.statusPlate(parent,x,barY,z)
    local plate=inkPlate(390,98)
    plate:setPosition(cc.p(x-195,barY-37));parent:addChild(plate,z or 0)
    return plate
end
return C
