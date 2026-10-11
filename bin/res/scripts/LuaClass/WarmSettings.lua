-- A native, owner-bound settings sheet. Only existing persisted preferences are
-- changed; this sheet does not pause a voyage, save a run, or offer a restart.
require 'AudioEngine'
require 'LuaClass/Header'
require 'LuaClass/DataManager'
local T = require 'LuaClass/WarmTheme'
local S = {}

-- Shared with the focused regression: these are the existing game's controls,
-- not the concept board's unimplemented large-text/reduced-motion preferences.
function S.preferences(manager)
    return {
        {key='soundToggle', title='音效', detail='按钮与游戏声音',
            get=function() return manager:getSound_off() end,
            set=function(value) manager:setSound_off(value) end},
        {key='musicToggle', title='音乐', detail='背景音乐',
            get=function() return manager:getMusic_off() end,
            set=function(value)
                if value == 1 then AudioEngine.pauseMusic()
                elseif HAS_MUSIC_FILE == 1 then AudioEngine.resumeMusic()
                else AudioEngine.playMusic(MUSIC_Main, true) end
                manager:setMusic_off(value)
            end},
        {key='effectToggle', title='战斗特效', detail='下场战斗生效',
            get=function() return manager:getEffect_off() end,
            set=function(value) manager:setEffect_off(value) end}
    }
end

function S.open(owner)
    local director = cc.Director:getInstance()
    local scene = director:getRunningScene()
    owner = owner or scene
    if not owner or not scene then return nil end
    if owner.warmSettingsModal then return owner.warmSettingsModal end
    local size, origin = director:getVisibleSize(), director:getVisibleOrigin()
    local scale = math.min(1, size.width / 640, size.height / 860)
    local width, height = 570 * scale, 770 * scale
    local layer = cc.LayerColor:create(cc.c4b(45, 32, 25, 150), size.width, size.height)
    layer:setPosition(origin)
    layer.isAdventureModal = true
    layer.isWarmSettings = true
    owner.warmSettingsModal = layer
    scene:addChild(layer, 100000)
    local state = {closed=false}

    local function clearOwnership()
        if owner.warmSettingsModal == layer then owner.warmSettingsModal = nil end
    end
    local function close()
        if state.closed then return end
        state.closed = true
        clearOwnership()
        if state.listener then
            layer:getEventDispatcher():removeEventListener(state.listener)
            state.listener = nil
        end
        local observer = state.observer
        state.observer = nil
        if observer then observer:removeFromParent(true) end
        layer:removeFromParent(true)
    end
    layer.close = close
    local observer = cc.Node:create()
    state.observer = observer
    observer:registerScriptHandler(function(event)
        if event == 'exit' or event == 'cleanup' then
            state.observer = nil
            close()
        end
    end)
    owner:addChild(observer)
    layer:registerScriptHandler(function(event)
        if event == 'exit' or event == 'cleanup' then
            state.closed = true
            clearOwnership()
            if state.listener then
                layer:getEventDispatcher():removeEventListener(state.listener)
                state.listener = nil
            end
            local bound = state.observer
            state.observer = nil
            if bound then bound:removeFromParent(true) end
        end
    end)

    local left, bottom = (size.width - width) / 2, (size.height - height) / 2
    local panel = T.panel(width, height, T.colors.paper, 30 * scale)
    panel:setPosition(cc.p(left, bottom))
    layer:addChild(panel, 1)
    layer.panel = panel
    local function text(value, fontSize, x, y, color, bold, anchor)
        local label = T.label(value, fontSize * scale, color or T.colors.ink,
            x * scale, y * scale, bold, anchor)
        panel:addChild(label, 2)
        return label
    end
    text('设置', 38, 285, 715, T.colors.ink, true, .5)
    text('按自己的节奏，继续冒险', 22, 285, 671, T.colors.muted, false, .5)
    for index, spec in ipairs(S.preferences(DataManager:getInstance())) do
        local rowY = 554 - (index - 1) * 104
        local row = T.panel(506 * scale, 90 * scale, T.colors.white, 16 * scale)
        row:setPosition(cc.p(32 * scale, rowY * scale))
        panel:addChild(row)
        text(spec.title, 28, 54, rowY + 58, T.colors.ink, true)
        text(spec.detail, 20, 54, rowY + 26, T.colors.muted)
        local toggle
        local function refresh()
            local enabled = spec.get() ~= 1
            toggle.label:setString(enabled and '开启' or '关闭')
            toggle.label:setColor(enabled and T.colors.sea or T.colors.muted)
        end
        toggle = T.button('', 120 * scale, 58 * scale, function()
            spec.set(spec.get() == 1 and 0 or 1)
            refresh()
        end, {size=25 * scale})
        toggle:setPosition(cc.p(454 * scale, (rowY + 45) * scale))
        panel:addChild(toggle, 3)
        refresh()
        layer[spec.key] = toggle.item
        layer[spec.key .. 'Label'] = toggle.label
    end
    text('航行小提示', 25, 40, 306, T.colors.ink, true)
    local rules = {
        '食物随航行消耗，耗尽会危及船员与战利品。',
        '食物和物品占用货舱，装船时留好余量。',
        '移动可揭开迷雾，探索中留意补给与返航。'
    }
    for index, rule in ipairs(rules) do
        local label = text(rule, 21, 40, 267 - (index - 1) * 37, T.colors.muted)
        label:setDimensions(cc.size(490 * scale, 31 * scale))
        label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    end
    local done = T.button('完成', 386 * scale, 72 * scale, close,
        {primary=true, size=30 * scale})
    done:setPosition(cc.p(width / 2, 95 * scale))
    panel:addChild(done, 3)
    layer.doneButton = done.item

    -- Scene-graph priority gives the menu first refusal, then swallows the
    -- remaining touches before they reach any route, deck, or map underneath.
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(function() return true end, cc.Handler.EVENT_TOUCH_BEGAN)
    layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, layer)
    state.listener = listener
    return layer
end

return S
