require "LuaClass/Header"
require "LuaClass/DataManager"
require "LuaClass/GuideController"
require "LuaClass/BTheme"

-- The harbor is a read-only dashboard. Only explicit navigation opens gameplay
-- layers, particularly ExpeditionLayer whose initialization awards supplies.
HomeLayer = class("HomeLayer", function() return cc.Layer:create() end)
HomeLayer.__index = HomeLayer

function HomeLayer:create()
    local view = HomeLayer.new()
    if view and view:init() then return view end
    return nil
end

function HomeLayer:init()
    self.isAdventureHome = true
    local size = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()
    local c = BTheme.colors
    self:addChild(BTheme.panel(size.width, size.height, c.sand, origin.x, origin.y))
    local content = cc.Node:create()
    local height = size.height - UITopHeight - UIBottomHeight
    local scale = math.min(size.width / 640, height / 900)
    content:setScale(scale)
    content:setPosition(cc.p(origin.x + (size.width - 640 * scale) * 0.5,
        origin.y + UIBottomHeight + (height - 900 * scale) * 0.5))
    self:addChild(content)

    content:addChild(BTheme.label("海盗基地", 38, c.ink, 24, 866))
    content:addChild(BTheme.label("港口 · 冒险从这里启程", 19, c.muted, 616, 862, 1))

    content:addChild(BTheme.panel(592, 320, c.sea, 24, 520))
    local harborPath = "Images/UI/Adventure/harbor.png"
    if cc.FileUtils:getInstance():isFileExist(harborPath) then
        local harbor = cc.Sprite:create(harborPath)
        harbor:setAnchorPoint(cc.p(0, 0))
        harbor:setPosition(cc.p(24, 520))
        harbor:setScaleX(592 / harbor:getContentSize().width)
        harbor:setScaleY(320 / harbor:getContentSize().height)
        content:addChild(harbor)
    else
        -- Native sea and sail shapes keep the screen usable while art loads.
        content:addChild(BTheme.panel(592, 126, cc.c3b(125, 190, 195), 24, 714))
        content:addChild(BTheme.panel(270, 10, c.white, 210, 615))
        content:addChild(BTheme.panel(8, 172, c.ink, 331, 600))
        content:addChild(BTheme.panel(100, 130, c.sand, 345, 636))
        content:addChild(BTheme.panel(72, 108, c.white, 251, 644))
        content:addChild(BTheme.panel(236, 28, c.ink, 222, 590))
    end
    content:addChild(BTheme.panel(592, 40, cc.c4b(22, 53, 62, 220), 24, 520))
    content:addChild(BTheme.label("停泊港湾", 21, c.white, 42, 540))
    content:addChild(BTheme.label("准备船员与补给，驶向未知海域", 18, c.white, 598, 540, 1))

    content:addChild(BTheme.label("出航准备", 30, c.ink, 24, 484))
    self.readyLabel = BTheme.label("", 19, c.muted, 616, 482, 1)
    content:addChild(self.readyLabel)
    self.crewLabel = self:addStat(content, 24, "船员", c.ink)
    self.cargoLabel = self:addStat(content, 226, "货舱", c.sea)
    self.stockLabel = self:addStat(content, 428, "待命成员", c.ink)
    self.hintLabel = BTheme.label("", 19, c.muted, 24, 344)
    content:addChild(self.hintLabel)

    local sail = BTheme.button("整备出航  ›", 592, 68, function()
        self:openRoute(1)
    end, {color = c.coral, selectedColor = cc.c3b(194, 85, 57), fontSize = 31})
    sail:setPosition(cc.p(320, 292))
    content:addChild(sail)

    self:addFeature(content, "成长", "提升天赋与战力", 24, function()
        zqDispatch:gotoTalent()
    end, c.sea)
    self:addFeature(content, "建设", "扩建你的海盗基地", 328, function()
        self:openRoute(3)
    end, c.ink)

    local shortcuts = {
        {"仓库", function() self:openRoute(4) end},
        {"采集", function() self:openRoute(6) end},
        {"炼金", function() zqDispatch:moveToRepository() end}
    }
    for i, entry in ipairs(shortcuts) do
        local button = BTheme.button(entry[1] .. "  ›", 188, 44, entry[2],
            {color = c.pale, selectedColor = c.line, textColor = c.ink, fontSize = 22})
        button:setPosition(cc.p(118 + (i - 1) * 202, 80))
        content:addChild(button)
    end

    self.infoLabel = BTheme.label("", 17, c.muted, 24, 28)
    self.infoLabel:setDimensions(cc.size(592, 46))
    content:addChild(self.infoLabel)
    self:refreshSummary()
    for _, key in ipairs({rolePack, roleSelectUnit, roleSoildierQueue, rolePackSize, roleCabinSize, roleGuideStep}) do
        DataManager:getInstance():registerEvent(key, "adventureHome", function() self:refreshSummary() end)
    end
    return true
end

function HomeLayer:addStat(parent, x, title, accent)
    local c = BTheme.colors
    parent:addChild(BTheme.panel(188, 82, c.white, x, 374))
    parent:addChild(BTheme.panel(4, 82, accent, x, 374))
    parent:addChild(BTheme.label(title, 19, c.muted, x + 16, 435))
    local value = BTheme.label("0", 28, c.ink, x + 16, 401)
    parent:addChild(value)
    return value
end

function HomeLayer:addFeature(parent, title, subtitle, x, callback, color)
    local button = BTheme.button("", 288, 112, callback,
        {color = color, selectedColor = BTheme.colors.coral})
    button:setPosition(cc.p(x + 144, 184))
    button.item:addChild(BTheme.label(title, 31, BTheme.colors.white, 20, 75))
    button.item:addChild(BTheme.label(subtitle, 19, BTheme.colors.white, 20, 33))
    button.item:addChild(BTheme.label("›", 39, BTheme.colors.white, 263, 61, 0.5))
    parent:addChild(button)
end

function HomeLayer:refreshSummary()
    local dm = DataManager:getInstance()
    local selected = dm:getRoleData(roleSelectUnit) or {}
    local resources = dm:getCSVByID(csvOfResourceInfo) or {}
    local crew, cargo, available = 0, 0, 0
    for key, count in pairs(selected) do
        local id, num = tonumber(key) or 0, tonumber(count) or 0
        if id >= 10000 then
            crew = crew + num
        else
            local resource = resources[tostring(key)] or {}
            cargo = cargo + num * (tonumber(resource.cubage) or 1)
        end
    end
    for _, unit in pairs(dm:getRoleData(roleSoildierQueue) or {}) do
        if type(unit) == "table" then available = available + (tonumber(unit[dataKeyNum]) or 0) end
    end
    self.crewLabel:setString(crew .. " / " .. tostring(dm:getRoleData(roleCabinSize) or 0))
    self.cargoLabel:setString(cargo .. " / " .. tostring(dm:getRoleData(rolePackSize) or 0))
    self.stockLabel:setString(tostring(available) .. " 人")
    local ready = GuideController:getInstance():getIsHaveStep(8)
    self.readyLabel:setString(ready and "船坞已就绪" or "等待建设船坞")
    self.hintLabel:setString(ready and "已选物资与成员可在整备页调整" or "从建设开始，解锁船坞后即可整备出航")
    if not GuideController:getInstance():getIsHaveStep(1) then
        self.hintLabel:setString("先前往炼金，使用神秘法阵制造 10 枚金币")
    end
end

function HomeLayer:openRoute(index)
    if zqDispatch and zqDispatch.mainMenu then zqDispatch.mainMenu:openRoute(index) end
end

function HomeLayer:updateInfoLabel(text)
    if not self.infoLabel then return end
    -- DataManager supplies the entire newest-first log. Keep the latest two
    -- entries readable here; existing gameplay pages retain the full history.
    local lines = {}
    for line in tostring(text or ""):gmatch("[^\r\n]+") do
        table.insert(lines, line)
        if #lines == 2 then break end
    end
    self.infoLabel:setString(table.concat(lines, "\n"))
end

function HomeLayer:viewWillDestory() end

function HomeLayer:destory()
    for _, key in ipairs({rolePack, roleSelectUnit, roleSoildierQueue, rolePackSize, roleCabinSize, roleGuideStep}) do
        DataManager:getInstance():unregisterEvent(key, "adventureHome")
    end
    if pNeedUpdateLayer == self then pNeedUpdateLayer = nil end
end
