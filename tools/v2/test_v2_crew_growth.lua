package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local State = require "LuaClass/V2ChapterState"
local Port = require "LuaClass/V2PortModel"
local Telemetry = require "LuaClass/V2Telemetry"
local Theme = require "LuaClass/V2UITheme"

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function truthy(value, message)
    if not value then error(message) end
end

local function contains(text, expected, message)
    truthy(string.find(text or "", expected, 1, true), message)
end

local function actionLabel(state, actionId)
    for _, action in ipairs(State.getActions(state)) do
        if action.id == actionId then return action.label end
    end
    return nil
end

local function apply(state, action)
    local ok, message = State.apply(state, action)
    truthy(ok, message or (action .. " failed"))
    return message
end

local data = State.getData()
equal(#data.crew_upgrade, 2, "first crew-growth slice exposes exactly two legible appointments")
equal(data.by_id.crew_upgrade.crew_upgrade_gunner.crew_id, "crew_gunner", "gunner appointment maps to Rock")
equal(data.by_id.crew_upgrade.crew_upgrade_sailor.crew_id, "crew_sailor", "sailor appointment maps to Mick")

local choice = State.new("qa_upgrade")
choice.profile = "player"
apply(choice, "upgrade_hull")
equal(choice.stage, "crew_growth", "ship upgrade now opens the one-time crew appointment")
equal(State.getStageTitle(choice), "皇家港 · 首席任命", "crew growth has a player-facing stage title")
contains(State.getNarrative(choice), "只能任命一名", "appointment narrative states the permanent exclusivity")
contains(actionLabel(choice, "promote_gunner"), "远距齐射潮盾伤害 +20", "gunner button previews its guardian result")
contains(actionLabel(choice, "promote_sailor"), "撞锚船体代价 -10", "sailor button previews its guardian result")

equal(Port.status(choice, data).label, "等待任命", "port header exposes the pending growth decision")
local candidates = Port.crewUpgrades(choice, data)
equal(#candidates, 2, "crew page reads both authored candidates")
equal(candidates[1].name, "罗克", "first candidate preserves the core crew identity")
equal(candidates[1].title, "炮术长", "candidate card exposes the proposed position")
local crewActions = Port.actions("crew", State.getActions(choice))
equal(#crewActions, 2, "crew page filters the two real appointment actions")
truthy(not Port.returnsToVoyage("promote_gunner"), "appointment refreshes the crew page in place")

local before = Telemetry.snapshot(choice)
apply(choice, "promote_gunner")
equal(choice.stage, "complete", "appointment completes the first-voyage growth sequence")
equal(choice.upgrades.crew, "crew_upgrade_gunner", "gunner appointment is retained in the growth container")
contains(State.getNarrative(choice), "罗克 · 炮术长", "completion names the retained crew appointment")
contains(State.getNarrative(choice), "远距齐射潮盾伤害 +20", "completion restates its next-voyage payoff")
truthy(actionLabel(choice, "prepare_next_voyage"), "next voyage opens only after the appointment")
local ok, message = State.apply(choice, "promote_sailor")
truthy(not ok and string.find(message, "已经任命", 1, true), "a second appointment cannot overwrite the retained choice")

local event = Telemetry.record(choice, "promote_gunner", before, true, choice.last_result)
equal(event.event_id, "crew_upgrade_selected", "appointment has a distinct telemetry event")
equal(event.crew_upgrade, "crew_upgrade_gunner", "telemetry records the retained appointment id")
equal(Telemetry.getSummary(choice).crew_growth_decisions, 1, "summary counts one crew-growth decision")

apply(choice, "prepare_next_voyage")
equal(choice.upgrades.crew, "crew_upgrade_gunner", "crew appointment survives repeat-voyage preparation")

local legacy = State.new("qa_complete")
legacy.profile = "player"
legacy.upgrades.crew = nil
truthy(actionLabel(legacy, "promote_gunner"), "compatible old completion saves are routed into the new appointment")
ok, message = State.apply(legacy, "prepare_next_voyage")
truthy(not ok and string.find(message, "首席船员", 1, true), "direct preparation cannot bypass missing crew growth")

local baseGuardian = State.new("qa_tide_guardian")
contains(actionLabel(baseGuardian, "tide_barrage"), "潮盾-60", "guardian baseline remains visible without a crew appointment")
contains(actionLabel(baseGuardian, "tide_ram"), "船体-10", "hull-growth baseline ram cost remains visible")

local gunner = State.new("qa_tide_guardian_gunner")
contains(actionLabel(gunner, "tide_barrage"), "潮盾-80", "Rock adds twenty real ranged shield damage")
apply(gunner, "tide_barrage")
equal(gunner.battle.tide_shield, 20, "gunner bonus changes the real first barrage result")
equal(gunner.battle.player_hull, 118, "non-terminal ranged barrage still pays the authored retaliation")
apply(gunner, "tide_barrage")
equal(gunner.stage, "tide_rune_clue", "gunner route resolves the guardian in two ranged actions")
contains(gunner.battle_report, "罗克 · 炮术长", "guardian report attributes the retained crew contribution")

local overkill = State.new("qa_upgrade")
overkill.profile = "player"
apply(overkill, "upgrade_guns")
apply(overkill, "promote_gunner")
apply(overkill, "prepare_next_voyage")
apply(overkill, "start_voyage")
apply(overkill, "choose_tide_cannon")
apply(overkill, "rescue_anchor_keeper")
contains(actionLabel(overkill, "tide_barrage"), "潮盾-100（火力120）",
    "stacked ship and crew growth separates actual shield loss from potential firepower")
contains(State.getNarrative(overkill), "潮盾 -100（火力120）",
    "guardian briefing uses the same exact-over-potential damage semantics")
apply(overkill, "tide_barrage")
equal(overkill.stage, "tide_rune_clue", "stacked gunner barrage resolves the guardian")
contains(overkill.battle_report, "最终破盾 100（方案火力 120）",
    "guardian report preserves exact damage while explaining the overkill build")

local sailor = State.new("qa_tide_guardian_sailor")
contains(actionLabel(sailor, "tide_ram"), "潮盾-100｜船体-0", "Mick removes ten real ram hull cost")
local hullBefore = sailor.battle.player_hull
apply(sailor, "tide_ram")
equal(sailor.stage, "tide_rune_clue", "sailor route still resolves the decisive hull-growth ram")
equal(sailor.battle.player_hull, hullBefore, "Mick's appointment prevents the remaining ram hull loss")
contains(sailor.battle_report, "米克 · 大副", "guardian report attributes the sailor contribution")

local crew = Port.crew(State.new("qa_complete"), data)
truthy(crew[1].promoted, "normal crew roster highlights the appointed officer")
equal(crew[1].promotion_effect, "远距齐射潮盾伤害 +20", "appointed card exposes its persistent effect")
local groups = Theme.outcomeGroups(State.new("qa_crew_growth"), data)
equal(groups[2].value, "远距破盾 +20\n稳定齐射方案", "chapter result group uses authored gunner tuning")
equal(groups[3].value, "撞锚自损 -10\n稳定近身方案", "chapter result group uses authored sailor tuning")

for _, profile in ipairs({
    "qa_crew_growth", "qa_tide_signal_gunner", "qa_tide_signal_sailor",
    "qa_tide_guardian_gunner", "qa_tide_guardian_sailor",
}) do
    local restored, recovery = State.normalize(State.new(profile), profile)
    truthy(recovery == nil and State.STAGES[restored.stage], profile .. " remains restorable")
end

print("V2 crew growth OK: exclusive appointment, retained choice, Port interaction, guardian effects and telemetry")
