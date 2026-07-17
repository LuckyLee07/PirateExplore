package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local State = require "LuaClass/V2ChapterState"

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function contains(value, expected, message)
    if type(value) ~= "string" or not string.find(value, expected, 1, true) then
        error(string.format("%s: %s does not contain %s", message, tostring(value), expected))
    end
end

local function apply(state, action)
    local ok, message = State.apply(state, action)
    if not ok then error(string.format("%s failed: %s", action, tostring(message))) end
end

local function actionLabel(state, actionId)
    for _, action in ipairs(State.getActions(state)) do
        if action.id == actionId then return action.label end
    end
    return nil
end

local harbor = State.new("qa_harbor")
equal(harbor.stage, "harbor", "harbor QA profile opens the preparation decision")
contains(State.getNarrative(harbor), "默认已装配加固船体，可直接出航", "preparation explains the safe default")
contains(State.getNarrative(harbor), "耐久 +20", "preparation explains the hull gain")
contains(State.getNarrative(harbor), "齐射 +45", "preparation explains the cannon gain")
contains(State.getNarrative(harbor), "补给上限 -1", "preparation explains the heavy-gun tradeoff")
contains(actionLabel(harbor, "select_reinforced_hull"), "✓ 加固船体\n耐久+20", "selected default is explicit")
contains(actionLabel(harbor, "select_heavy_guns"), "齐射+45｜补给-1", "heavy-gun button previews its tradeoff")
contains(actionLabel(harbor, "start_voyage"), "按加固船体\n配置出航", "departure confirms the current module")

apply(harbor, "select_heavy_guns")
contains(actionLabel(harbor, "select_heavy_guns"), "✓ 重炮甲板", "new module selection is explicit")
contains(actionLabel(harbor, "start_voyage"), "按重炮甲板\n配置出航", "departure updates with the module choice")

local unknown = State.new("qa_explore")
contains(State.getNarrative(unknown), "盲选方向", "unmapped route choice names the blind-choice option")
contains(State.getNarrative(unknown), "花 1 补给测绘", "unmapped route choice explains the intel cost")
contains(actionLabel(unknown, "reveal_route_intel"), "先测绘｜花 1 补给查看后果", "mapping action is prioritized as decision support")
contains(actionLabel(unknown, "choose_safe_route"), "盲选 A", "unmapped safe direction is labeled as blind")
contains(actionLabel(unknown, "choose_risky_route"), "盲选 B", "unmapped risky direction is labeled as blind")

apply(unknown, "reveal_route_intel")
local mappedNarrative = State.getNarrative(unknown)
contains(mappedNarrative, "风险 1 · 补给 -2 · 接舷上限 +10", "safe-route consequence is explicit")
contains(mappedNarrative, "风险 3 · 补给 -1 · 船体 -10 · 获得升级资源", "risky-route consequence is explicit")
contains(actionLabel(unknown, "choose_safe_route"), "接舷+10", "safe-route button previews boarding tolerance")
contains(actionLabel(unknown, "choose_risky_route"), "船体-10\n获得升级资源", "risky-route button previews damage and payoff")

local mapped = State.new("qa_explore_intel")
equal(mapped.stage, "route_choice", "mapped-route QA profile opens the route decision")
equal(mapped.flags.route_intel, true, "mapped-route QA profile retains revealed intel")
equal(mapped.resources.provisions, 6, "mapped-route QA profile accounts for the intel cost")
equal(actionLabel(mapped, "reveal_route_intel"), nil, "mapped-route QA profile does not offer duplicate mapping")
contains(actionLabel(mapped, "choose_safe_route"), "风险1", "mapped QA profile shows safe risk")
contains(actionLabel(mapped, "choose_risky_route"), "风险3", "mapped QA profile shows risky risk")

print("V2 internal sample polish round 4 OK: module and route consequences are visible before commitment")
