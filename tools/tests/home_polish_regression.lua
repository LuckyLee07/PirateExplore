-- Run from the repository root with Lua 5.1.
-- Reuses the read-only Cocos harness, then tests native icons and optional washes.
-- This does not run the game, read a save, or establish native pixel fidelity.
dofile('tools/tests/home_master_regression.lua')

local function equal(actual, expected, context)
    assert(actual == expected, context..': expected '..tostring(expected)..', got '..tostring(actual))
end
local function near(actual, expected, context)
    assert(math.abs(actual - expected) < 0.00001, context..': expected '..tostring(expected)..', got '..tostring(actual))
end
local function snapshot(value)
    if type(value) ~= 'table' then return type(value)..':'..tostring(value) end
    local keys, parts = {}, {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do parts[#parts + 1] = snapshot(key)..'='..snapshot(value[key]) end
    return '{'..table.concat(parts, ',')..'}'
end
local function walk(node, visit)
    visit(node)
    for _, child in ipairs(node:getChildren()) do walk(child, visit) end
    if node.stencil then walk(node.stencil, visit) end
end
local function descendantWithPath(node, path)
    local found
    walk(node, function(child)
        if child.path == path then assert(not found, 'duplicate asset '..path); found = child end
    end)
    return found
end
local function checkBox(node, width, height, context)
    near(node:getContentSize().width, width, context..' width')
    near(node:getContentSize().height, height, context..' height')
end
local prefix = 'Images/UI/Adventure/Master/Polish/'
local dimensions = {
    ['coral-action.png'] = {797, 202}, ['roster-blue.png'] = {431, 363},
}
local originalFileUtils = cc.FileUtils.getInstance
local originalSprite = cc.Sprite.create
local originalDirector = cc.Director.getInstance
local dm = DataManager:getInstance()
local originalRoleRead = dm.__roleData.getRoleData
local originalBuy, originalCharge = dm.showBuyGoldBox, ChargeLayer.create
local originalApplication = cc.Application
local originalLinux = cc.PLATFORM_OS_LINUX
local originalClippingNode = cc.ClippingNode
cc.ClippingNode = {create = function()
    local clip = cc.Node:create(); clip.kind = 'ClippingNode'
    clip.setStencil = function(self, stencil) self.stencil = stencil end
    clip.setAlphaThreshold = function(self, threshold) self.alphaThreshold = threshold end
    return clip
end}
cc.PLATFORM_OS_LINUX = 'home-polish-test-linux'
cc.Application = {getInstance = function()
    return {getTargetPlatform = function() return cc.PLATFORM_OS_LINUX end}
end}

local modes = {'missing', 'synthetic', 'decode-failure', 'zero-width', 'zero-height'}
local allPackaged = true
for name in pairs(dimensions) do
    if not originalFileUtils():isFileExist(prefix..name) then allPackaged = false end
end
if allPackaged then modes[#modes + 1] = 'packaged' end
local function polishName(path)
    if path and path:sub(1, #prefix) == prefix then return path:sub(#prefix + 1) end
end
local selected, capacity, money, diamond
dm.__roleData.getRoleData = function(self, key)
    if key == roleSelectUnit then return selected end
    if key == roleCabinSize then return capacity end
    if key == roleMoney then return money end
    if key == roleDiamond then return diamond end
    return originalRoleRead(self, key)
end
local function dataSnapshot()
    local data = {}
    for _, key in ipairs({roleMoney, roleDiamond, roleCabinSize, rolePackSize,
        rolePack, roleShipId, roleSoildierQueue, roleSelectUnit, roleGuideStep,
        roleBattleQueue, roleBattlePack}) do data[key] = dm:getRoleData(key) end
    data.soldierCSV = dm:getCSVByID(csvOfSoilderAttribute)
    data.resourceCSV = dm:getCSVByID(csvOfResourceInfo)
    return snapshot(data)
end

for _, mode in ipairs(modes) do
    local fileQueries, spriteQueries = 0, 0
    cc.FileUtils.getInstance = function()
        return {isFileExist = function(_, path)
            fileQueries = fileQueries + 1
            if polishName(path) then
                if mode == 'missing' then return false end
                if mode ~= 'packaged' then return true end
            end
            return originalFileUtils():isFileExist(path)
        end}
    end
    cc.Sprite.create = function(self, path, rect)
        spriteQueries = spriteQueries + 1
        local name = polishName(path)
        if name and mode == 'decode-failure' then return nil end
        if name and mode ~= 'packaged' and mode ~= 'missing' then
            local size = assert(dimensions[name], 'unexpected optional asset '..name)
            local sprite = cc.Node:create(); sprite.kind = 'Sprite'; sprite.path = path
            sprite:setContentSize(cc.size(mode == 'zero-width' and 0 or size[1],
                mode == 'zero-height' and 0 or size[2]))
            sprite.getTexture = function()
                return {setAntiAliasTexParameters = function() sprite.filtered = true end}
            end
            return sprite
        end
        return originalSprite(self, path, rect)
    end
    local painted = mode == 'synthetic' or mode == 'packaged'
    for _, kind in ipairs({'anchor', 'sail', 'ship', 'crew', 'port', 'food', 'key'}) do
        for _, color in ipairs({MasterTheme.colors.paper, MasterTheme.colors.ink}) do
            local filesBefore, spritesBefore = fileQueries, spriteQueries
            local icon = assert(MasterTheme.icon(kind, 43, color))
            checkBox(icon, 43, 43, mode..' '..kind..' icon container')
            equal(fileQueries, filesBefore, mode..' '..kind..' no icon file dependency')
            equal(spriteQueries, spritesBefore, mode..' '..kind..' no raster icon dependency')
            equal(icon:getChildren()[1].kind, 'DrawNode', mode..' '..kind..' native vector')
            assert(#icon:getChildren()[1].draws > 0, mode..' '..kind..' native vector is visible')
            walk(icon, function(child) assert(not child.path, mode..' '..kind..' native tree has no image') end)
            if color == MasterTheme.colors.paper and kind ~= 'crew' then
                local cutout = false
                for _, draw in ipairs(icon:getChildren()[1].draws) do
                    local paint = draw.fill or draw[4] or draw[3]
                    if paint and paint.r == MasterTheme.colors.ink.r/255
                        and paint.g == MasterTheme.colors.ink.g/255
                        and paint.b == MasterTheme.colors.ink.b/255 then cutout = true end
                end
                assert(cutout, mode..' '..kind..' preserves a key inset/cutout')
            end
            -- All geometry, including line widths and dot radii, must scale
            -- uniformly with the native icon's square logical size.
            local large = assert(MasterTheme.icon(kind, 86, color))
            local smallDraws, largeDraws = icon:getChildren()[1].draws, large:getChildren()[1].draws
            equal(#smallDraws, #largeDraws, mode..' '..kind..' stable vector primitive count')
            local function pointTwice(a,b)
                near(b.x,a.x*2,mode..' '..kind..' uniform vector X')
                near(b.y,a.y*2,mode..' '..kind..' uniform vector Y')
            end
            for i,draw in ipairs(smallDraws) do
                local other = largeDraws[i]
                if draw.points then
                    for j,point in ipairs(draw.points) do pointTwice(point,other.points[j]) end
                else
                    pointTwice(draw[1],other[1])
                    if type(draw[2]) == 'table' then
                        pointTwice(draw[2],other[2]);near(other[3],draw[3]*2,mode..' '..kind..' stroke scale')
                    else near(other[2],draw[2]*2,mode..' '..kind..' dot radius scale') end
                end
            end
        end
    end
    -- The image may change, but the native material and menu-item bounds may not.
    for _, spec in ipairs({
        {file='coral-action.png', width=338.7, height=84.9,
            create=function(w,h) return MasterTheme.material('coral-brush.png',w,h) end},
        {file='roster-blue.png', width=185, height=155.6,
            create=function(w,h) return MasterTheme.portraitBrush(w,h) end},
    }) do
        local material = assert(spec.create(spec.width, spec.height))
        checkBox(material, spec.width, spec.height, mode..' '..spec.file..' container')
        local sprite = descendantWithPath(material, prefix..spec.file)
        equal(sprite ~= nil, painted, mode..' '..spec.file..' source/fallback')
        if spec.file == 'coral-action.png' and material.kind == 'ClippingNode' then
            equal(material.alphaThreshold,.5,mode..' CTA alpha edge threshold')
            assert(material.stencil,mode..' CTA uses an image stencil')
            equal(#material:getChildren(),1,mode..' CTA only displays its native fill')
            local fill = material:getChildren()[1]
            equal(fill.kind,'LayerColor',mode..' CTA uses a native solid field')
            equal(fill.color.r,235,mode..' CTA coral red')
            equal(fill.color.g,94,mode..' CTA coral green')
            equal(fill.color.b,62,mode..' CTA coral blue')
            equal(fill.color.a,255,mode..' CTA solid opacity')
            checkBox(fill,spec.width,spec.height,mode..' CTA fill bounds')
            if painted then equal(material.stencil,sprite,mode..' new PNG used only as stencil') end
        elseif spec.file == 'roster-blue.png' and not painted then
            local fallback = material:getChildren()[1]
            local color = fallback.color or fallback.draws[1].fill
            assert(color.b > color.r and color.g > color.r,mode..' failed/missing roster wash remains blue')
        end
        if sprite then
            -- These are unlettered paint washes, intentionally fitted to the
            -- unchanged material box. Unlike portraits/icons, they may stretch.
            local size = sprite:getContentSize()
            near(sprite:getScaleX(),spec.width/size.width,mode..' '..spec.file..' brush fit X')
            near(sprite:getScaleY(),spec.height/size.height,mode..' '..spec.file..' brush fit Y')
        end
    end

    for _, height in ipairs({1136, 1066.6666666667}) do
        cc.Director.getInstance = function()
            local director = originalDirector()
            director.getVisibleSize = function() return {width=640, height=height} end
            director.getNotificationNode = function() return nil end
            return director
        end
        for _, formation in ipairs({
            {selected={['10107']=3,['1005']=40,['1037']=3},capacity=3,count=3},
            {selected={},capacity=3,count=0},
            {selected={},capacity=1,count=0},
        }) do
            selected, capacity, money, diamond = formation.selected, formation.capacity, 4321, 234
            local context = mode..' at 640x'..height..' crew '..formation.count..' capacity '..capacity
            local before = dataSnapshot()
            local scene = cc.Node:create()
            local dispatch = assert(Dispatch:create(false)); scene:addChild(dispatch)
            local home, menu = dispatch.rightNode, dispatch.mainMenu
            equal(home.summary.crew, formation.count, context..' real selected count')
            equal(#home.crewSlots, 3, context..' three native roster slots')
            for i, slot in ipairs(home.crewSlots) do
                if formation.count == 0 then
                    equal(slot.empty, true, context..' genuine empty slot')
                    equal(slot.neutral, true, context..' neutral empty art')
                    equal(slot.locked, i > capacity, context..' real capacity gate')
                    equal(slot.name, i > capacity and '未解锁' or '待编入', context..' real empty label')
                else
                    equal(slot.id, '107', context..' real 107 portrait')
                    equal(slot.num, 1, context..' one member per occupied slot')
                    equal(slot.name, '木盾舵手', context..' real packaged label')
                end
            end
            if formation.count == 0 then
                walk(home.crewNode, function(node)
                    assert(not (node.path and (node.path:find('crew-trio.png',1,true)
                        or node.path:find('roster-blue.png',1,true))), context..' empty slot must not imply an occupied profession')
                end)
            else
                walk(home.crewNode, function(node)
                    if node.path and node.path:find('crew-trio.png',1,true) then
                        local size = node:getContentSize()
                        near(node:getScaleX(),node:getScaleY(),context..' real portrait uniform scale')
                        near(node:getScaleX(),math.min(home.slotWidth/size.width,
                            home.slotPortraitHeight/size.height),context..' real portrait fit')
                    end
                end)
            end
            local ux, uy = 640/941, height/1672
            checkBox(home.departureButton, 498*ux, 125*uy, context..' CTA container')
            checkBox(home.departureButton.item, 498*ux, 125*uy, context..' CTA native hitbox')
            near(home.departureButton:getPositionX(), 672*ux, context..' unchanged CTA X')
            near(home.departureButton:getPositionY(), height-1407.5*uy, context..' unchanged CTA Y')
            equal(home.cargoLabel.fontSize, 27, context..' cargo type size')
            equal(home.foodLabel.fontSize, 21, context..' food type size')
            equal(home.keyLabel.fontSize, 21, context..' key type size')
            for _, label in ipairs({home.cargoLabel,home.foodLabel,home.keyLabel,
                menu.homeCoinLabel,menu.homeDiamondLabel}) do
                equal(label:getFontName(), MasterTheme.headingFont(true), context..' dynamic bold face')
            end
            for i, title in ipairs({'基地','航行','船员','港务'}) do
                local button = menu.navigationButtons[i]
                equal(button.bLabel:getString(), title, context..' navigation label')
                equal(button.bLabel:getFontName(), MasterTheme.headingFont(true), context..' navigation bold face')
                checkBox(button, 160, 118, context..' original navigation hitbox')
                near(button:getPositionX(),160*(i-.5),context..' original navigation X')
                near(button:getPositionY(),59,context..' original navigation Y')
            end
            for _, currency in ipairs({{menu.homeCoinAddButton,199},{menu.homeDiamondAddButton,382}}) do
                checkBox(currency[1],59,59,context..' original currency hitbox')
                near(currency[1]:getPositionX(),currency[2],context..' original currency X')
                near(currency[1]:getPositionY(),height-121,context..' original currency Y')
            end
            local goldCalls, chargeCalls, routeCalls = 0, 0, 0
            dm.showBuyGoldBox = function() goldCalls = goldCalls + 1 end
            ChargeLayer.create = function() chargeCalls = chargeCalls + 1 end
            dispatch.moveToExpedition = function() routeCalls = routeCalls + 1 end
            menu.homeCoinAddButton.callback(); menu.homeDiamondAddButton.callback()
            equal(goldCalls,1,context..' original gold route')
            equal(chargeCalls,1,context..' original recharge route')
            dm.showBuyGoldBox, ChargeLayer.create = originalBuy, originalCharge
            home.departureButton.item.callback()
            equal(routeCalls,1,context..' original preparation CTA route')
            menu:activeButtonWithIndex(0); menu.navigationButtons[2].callback()
            equal(routeCalls,2,context..' original sailing-tab route')
            menu.navigationButtons[3].callback()
            assert(menu.groupRouteButtons.recruit,context..' original crew navigation group')
            menu.navigationButtons[4].callback()
            assert(menu.groupRouteButtons.build,context..' original port navigation group')
            menu:closeNavigationGroup()
            local children = #home.crewNode:getChildren()
            for _=1,3 do home:refreshSummary() end
            equal(#home.crewNode:getChildren(),children,context..' repeat refresh no duplicate roster')
            equal(dataSnapshot(),before,context..' no direct data or CSV mutation')
            dispatch:destory()
            equal(#dispatch:getEventDispatcher().listeners,0,context..' complete listener cleanup')
        end
    end
    print('PASS Home polish '..mode..': resource-free uniform vectors, brush fallback, real empty/locked roster, native type, unchanged routes/hitboxes and read-only lifecycle')
end

cc.FileUtils.getInstance, cc.Sprite.create, cc.Director.getInstance = originalFileUtils, originalSprite, originalDirector
dm.__roleData.getRoleData = originalRoleRead
dm.showBuyGoldBox, ChargeLayer.create = originalBuy, originalCharge
cc.Application, cc.PLATFORM_OS_LINUX = originalApplication, originalLinux
cc.ClippingNode = originalClippingNode
if not allPackaged then
    print('SKIP actual Polish PNG headers/loading: awaiting both packaged brush assets')
else
    for name in pairs(dimensions) do
        local file = assert(io.open('bin/res/assets/'..prefix..name,'rb'))
        local header = file:read(26); file:close()
        equal(header:sub(1,8),'\137PNG\r\n\26\n',name..' PNG signature')
        equal(header:sub(13,16),'IHDR',name..' PNG header chunk')
        equal(header:byte(25),8,name..' eight-bit channel depth')
        equal(header:byte(26),6,name..' RGBA color type')
    end
    print('PASS both packaged brush assets preserve RGBA PNG format (not native pixel acceptance)')
end
