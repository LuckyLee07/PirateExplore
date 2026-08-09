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

local settlement = State.new("qa_settlement")
equal(settlement.stage, "settlement", "settlement QA profile opens the loot conversion step")
equal(settlement.resources.gold, 75, "settlement shows the full battle gold reward")
equal(settlement.resources.timber, 10, "settlement shows one hull upgrade worth of timber")
equal(settlement.resources.iron, 15, "settlement shows one gun upgrade worth of iron")
equal(settlement.resources.rune_dust, 6, "settlement combines battle and rune clue dust")
local lootNarrative = State.getNarrative(settlement)
contains(lootNarrative, "金币 +35 · 木材 +10 · 铁料 +15 · 符文尘 +1", "battle loot is itemized")
contains(lootNarrative, "符文尘 +5，并指向潮汐墓场", "rune clue reward and purpose are itemized")
contains(lootNarrative, "耐久 +20，或单次齐射 +25", "loot previews both conversions")

apply(settlement, "return_to_port")
equal(settlement.stage, "upgrade", "returning to port opens the upgrade choice")
local upgradeNarrative = State.getNarrative(settlement)
contains(upgradeNarrative, "木材 -10 → 最大耐久 +20", "hull upgrade explains cost and outcome before payment")
contains(upgradeNarrative, "铁料 -15 → 单次齐射 +25", "gun upgrade explains cost and outcome before payment")
contains(actionLabel(settlement, "upgrade_hull"), "加固船体\n木材-10｜耐久+20", "hull button previews its full conversion")
contains(actionLabel(settlement, "upgrade_guns"), "强化火炮\n铁料-15｜齐射+25", "gun button previews its full conversion")

local direct = State.new("qa_upgrade")
equal(direct.stage, "upgrade", "upgrade QA profile opens the conversion choice")
equal(direct.resources.timber, 10, "upgrade QA profile has the authored timber reward")
equal(direct.resources.iron, 15, "upgrade QA profile has the authored iron reward")
contains(State.getNarrative(direct), "最大耐久 +20", "upgrade QA profile renders hull payoff")
contains(State.getNarrative(direct), "单次齐射 +25", "upgrade QA profile renders gun payoff")

local hull = State.new("qa_upgrade")
apply(hull, "upgrade_hull")
apply(hull, "promote_gunner")
equal(hull.resources.timber, 0, "hull conversion spends the previewed timber")
equal(hull.ship.hull_max, 140, "hull conversion grants the previewed durability")

local guns = State.new("qa_upgrade")
apply(guns, "upgrade_guns")
apply(guns, "promote_sailor")
equal(guns.resources.iron, 0, "gun conversion spends the previewed iron")
equal(guns.ship.gun_level, 1, "gun conversion grants the previewed gun level")
contains(State.getNarrative(guns), "单次齐射伤害 +25", "gun completion agrees with the pre-commitment preview")

print("V2 internal sample polish round 5 OK: loot is itemized and both upgrade conversions are explicit")
