-- Run from the repository root with Lua 5.1. Reuse the production-logic
-- harness, then exercise only the newly optional MainMenu detail sprites.
-- These mocked-node checks do not constitute native pixel acceptance.
dofile('tools/tests/home_master_regression.lua')

local function equal(actual, expected, context)
    assert(actual == expected, context..': expected '..tostring(expected)..', got '..tostring(actual))
end
local function near(actual, expected, context)
    assert(math.abs(actual - expected) < 0.00001, context..': expected '..tostring(expected)..', got '..tostring(actual))
end
local prefix = 'Images/UI/Adventure/Master/Details/'
local dimensions = {
    ['coin-detail.png'] = {256, 256}, ['gem-detail.png'] = {256, 256},
    ['home-title-art.png'] = {1200, 290}, ['nav-selected-stroke.png'] = {1000, 140},
}
local originalFileUtils = cc.FileUtils.getInstance
local originalSprite = cc.Sprite.create
local originalDirector = cc.Director.getInstance
local dm = DataManager:getInstance()
local originalRoleRead = dm.__roleData.getRoleData
local originalBuy, originalCharge = dm.showBuyGoldBox, ChargeLayer.create
local money, diamond = 4321, 234
dm.__roleData.getRoleData = function(self, key)
    if key == roleMoney then return money end
    if key == roleDiamond then return diamond end
    return originalRoleRead(self, key)
end
local modes = {'missing', 'synthetic', 'decode-failure'}
local allPackaged = true
for name in pairs(dimensions) do
    if not originalFileUtils():isFileExist(prefix..name) then allPackaged = false end
end
if allPackaged then modes[#modes + 1] = 'packaged' end

local function detailName(path)
    if path and path:sub(1, #prefix) == prefix then return path:sub(#prefix + 1) end
end
local function findChild(parent, predicate)
    local found
    for _, child in ipairs(parent:getChildren()) do
        if predicate(child) then assert(not found, 'unexpected duplicate detail node'); found = child end
    end
    return found
end
local function hasPath(parent, name)
    return findChild(parent, function(child) return child.path == prefix..name end)
end
local function fitted(sprite, width, height, context)
    local size = sprite:getContentSize()
    near(sprite:getScaleX(), sprite:getScaleY(), context..' uniform scale')
    near(sprite:getScale(), math.min(width / size.width, height / size.height), context..' scale-to-fit')
    equal(sprite.anchor.x, 0.5, context..' centered X anchor')
    equal(sprite.anchor.y, 0.5, context..' centered Y anchor')
end

for _, mode in ipairs(modes) do
    cc.FileUtils.getInstance = function()
        return {isFileExist = function(_, path)
            if detailName(path) then
                if mode == 'missing' then return false end
                if mode ~= 'packaged' then return true end
            end
            return originalFileUtils():isFileExist(path)
        end}
    end
    cc.Sprite.create = function(self, path, rect)
        local name = detailName(path)
        if name and mode == 'decode-failure' then return nil end
        if name and mode == 'synthetic' then
            local node = cc.Node:create(); node.kind = 'Sprite'; node.path = path
            node:setContentSize(cc.size(unpack(assert(dimensions[name])))); return node
        end
        return originalSprite(self, path, rect)
    end
    for _, height in ipairs({1136, 1066.6666666667}) do
        cc.Director.getInstance = function()
            local director = originalDirector()
            director.getVisibleSize = function() return {width = 640, height = height} end
            director.getNotificationNode = function() return nil end
            return director
        end
        local context = mode..' at 640x'..height
        local scene = cc.Node:create()
        local dispatch = assert(Dispatch:create(false)); scene:addChild(dispatch)
        local menu, painted = dispatch.mainMenu, mode == 'synthetic' or mode == 'packaged'
        local title = assert(findChild(menu.homeHeader, function(child)
            return child.kind == 'LabelTTF' and child:getString() == '海盗基地'
        end))
        equal(title:isVisible(), not painted, context..' native title fallback')
        local titleArt = hasPath(menu.homeHeader, 'home-title-art.png')
        equal(titleArt ~= nil, painted, context..' title sprite availability')
        if titleArt then
            fitted(titleArt, 240, 58, context..' title')
            near(titleArt:getPositionX(), 162, context..' title X')
            near(titleArt:getPositionY(), height - 55, context..' title Y')
        end
        local compass = assert(findChild(menu.homeHeader, function(child)
            return child.kind == 'DrawNode' and child:getPositionX() == 262
        end))
        equal(compass:isVisible(), not painted, context..' no duplicate native compass')

        for _, currency in ipairs({
            {name='coin-detail.png', x=63, number=menu.homeCoinLabel, add=menu.homeCoinAddButton, plusX=199},
            {name='gem-detail.png', x=258, number=menu.homeDiamondLabel, add=menu.homeDiamondAddButton, plusX=382},
        }) do
            local icon = assert(findChild(menu.homeHeader, function(child)
                return child:getPositionX() == currency.x and child:getPositionY() == height - 121
            end))
            equal(icon.kind, painted and 'Sprite' or 'DrawNode', context..' '..currency.name..' fallback kind')
            if painted then fitted(icon, 34, 34, context..' '..currency.name) end
            equal(currency.number.kind, 'LabelTTF', context..' live amount remains native label')
            equal(currency.add.kind, 'MenuItemSprite', context..' add remains native menu item')
            equal(currency.add:getContentSize().width, 59, context..' plus width')
            equal(currency.add:getContentSize().height, 59, context..' plus height')
            equal(currency.add:getPositionX(), currency.plusX, context..' plus X')
            near(currency.add:getPositionY(), height - 121, context..' plus Y')
        end
        money, diamond = money + 7, diamond + 3
        dm:postEvent(roleMoney, nil); dm:postEvent(roleDiamond, nil)
        equal(menu.homeCoinLabel:getString(), tostring(money), context..' live coin update')
        equal(menu.homeDiamondLabel:getString(), tostring(diamond), context..' live gem update')
        local goldCalls, chargeCalls = 0, 0
        dm.showBuyGoldBox = function() goldCalls = goldCalls + 1 end
        ChargeLayer.create = function() chargeCalls = chargeCalls + 1 end
        menu.homeCoinAddButton.callback(); menu.homeDiamondAddButton.callback()
        equal(goldCalls, 1, context..' original gold entry')
        equal(chargeCalls, 1, context..' original recharge entry')
        dm.showBuyGoldBox, ChargeLayer.create = originalBuy, originalCharge

        equal(#menu.navigationButtons, 4, context..' four groups')
        for i, name in ipairs({'基地', '航行', '船员', '港务'}) do
            local button, brush = menu.navigationButtons[i], menu.navigationBrushes[i]
            equal(button.bLabel:getString(), name, context..' group label')
            equal(button:getContentSize().width, 160, context..' group hitbox width')
            equal(button:getContentSize().height, 118, context..' group hitbox height')
            equal(button:getPositionX(), 160 * (i - 0.5), context..' group hitbox X')
            equal(button:getPositionY(), 59, context..' group hitbox Y')
            equal(brush:getPositionX(), 55, context..' brush X')
            equal(brush:getPositionY(), 54, context..' brush Y')
            equal(brush:getContentSize().width, 50, context..' brush container width')
            equal(brush:getContentSize().height, 7, context..' brush container height')
            local sprite = hasPath(brush, 'nav-selected-stroke.png')
            equal(sprite ~= nil, painted, context..' brush sprite availability')
            if sprite then fitted(sprite, 50, 7, context..' brush') end
        end
        for index = 0, 7 do
            menu:activeButtonWithIndex(index)
            local group = index == 0 and 1 or (index == 1 and 2 or (index == 2 and 3 or 4))
            for i, brush in ipairs(menu.navigationBrushes) do
                equal(brush:isVisible(), i == group, context..' legacy-to-group selected brush')
            end
        end
        local header = menu.homeHeader; local children = #header:getChildren()
        menu:setHomePresentation(false); menu:setHomePresentation(true)
        equal(menu.homeHeader, header, context..' header reused')
        equal(#header:getChildren(), children, context..' no duplicated ornaments')
        dispatch:destory()
    end
    print('PASS static Home detail '..mode..': native money/actions, exact hitboxes, title fallback and selected brushes')
end
cc.FileUtils.getInstance, cc.Sprite.create, cc.Director.getInstance = originalFileUtils, originalSprite, originalDirector
dm.__roleData.getRoleData = originalRoleRead
dm.showBuyGoldBox, ChargeLayer.create = originalBuy, originalCharge
if not allPackaged then print('SKIP actual detail PNG loading: awaiting all four packaged assets') end
