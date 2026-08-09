package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local Theme = require "LuaClass/V2UITheme"
local State = require "LuaClass/V2ChapterState"

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

equal(Theme.progressIndex("opening"), 1, "opening starts at the harbor milestone")
equal(Theme.progressIndex("route_choice"), 2, "route choice advances to the route milestone")
equal(Theme.progressIndex("whisper"), 3, "curse encounter advances to the anomaly milestone")
equal(Theme.progressIndex("naval"), 4, "naval combat advances to the hunter milestone")
equal(Theme.progressIndex("complete"), 5, "completion reaches the rune milestone")
equal(Theme.progressIndex("tide_guardian"), 4, "Tide Guardian occupies the encounter milestone")
equal(Theme.progressLabels("tide_guardian")[4], "沉锚守卫", "second voyage uses distinct wayfinding labels")

equal(Theme.accentName("route_choice"), "sea", "exploration uses the sea accent")
equal(Theme.accentName("naval"), "danger", "combat uses the danger accent")
equal(Theme.accentName("rune_clue"), "purple", "rune discovery uses the curse accent")
equal(Theme.accentName("complete"), "success", "completion uses the success accent")
equal(Theme.accentName("tide_rune_clue"), "purple", "second rune retains the rune accent")

equal(Theme.actionRole("opening", "accept_call", 1, 1), "primary", "single forward action is primary")
equal(Theme.actionRole("route_choice", "reveal_route_intel", 1, 3), "utility", "route intel is utility")
equal(Theme.actionRole("naval", "retreat", 5, 5), "danger", "retreat is visually cautionary")
equal(Theme.actionRole("harbor", "select_reinforced_hull", 1, 3, "module_reinforced_hull"), "selected", "equipped module is selected")
equal(Theme.actionRole("failed", "retry_battle", 1, 2), "primary", "retry is the forward recovery action")
equal(Theme.actionRole("complete", "prepare_next_voyage", 1, 1), "primary", "retained-growth preparation is the completion action")
equal(Theme.actionRole("tide_route_choice", "choose_tide_breaker", 1, 2), "choice", "growth routes remain equal choices")
equal(Theme.actionRole("tide_guardian", "tide_ram", 2, 2), "danger", "ram communicates its hull cost")

local resources = Theme.resourceItems({ gold = 40, timber = 2, iron = 3, provisions = 6, rune_dust = 1 })
equal(#resources, 5, "resource HUD stays compact")
equal(resources[1].value, 40, "gold value is forwarded")
equal(resources[1].name, "金币", "resource HUD exposes a readable semantic label")
equal(resources[1].icon, "Images/V2/Icons/resource-gold.png", "resource HUD exposes its dedicated instrument icon")
equal(resources[5].accent, "purple", "rune resource keeps its semantic accent")
equal(Theme.battleIcon("cannon"), "Images/V2/Icons/battle-cannon.png", "battle meters expose a semantic cannon icon")
equal(Theme.actionFeedbackTitle("fire_at_deck", "naval"), "齐射命中甲板", "combat feedback names the completed action")
equal(Theme.actionFeedbackTitle("unknown_action", "boarding"), "甲板接舷已更新", "unknown actions fall back to the next stage")
equal(Theme.actionFeedbackTitle("prepare_next_voyage", "harbor"), "成长已装载", "repeat preparation confirms persistence")
local changes = Theme.feedbackChanges(
    { provisions = 5, enemy_ship_hp = 500, player_hull = 110, deck_damage = 0 },
    { provisions = 5, enemy_ship_hp = 325, player_hull = 96, deck_damage = 175 }
)
equal(#changes, 3, "one cannon action exposes all causal state changes")
equal(changes[1], "敌舰 -175", "enemy damage is reported as an immediate loss")
equal(changes[2], "船体 -14", "retaliation is reported alongside outgoing damage")
equal(changes[3], "甲板破坏 +175", "part damage progress remains explicit")
local upgradeChanges = Theme.feedbackChanges(
    { timber = 10, ship_hull_max = 120 },
    { timber = 0, ship_hull_max = 140 }
)
equal(upgradeChanges[1], "木材 -10", "upgrade feedback exposes its resource cost")
equal(upgradeChanges[2], "最大耐久 +20", "upgrade feedback exposes its persistent payoff")

local cannonItems = Theme.sceneFeedbackItems(
    "fire_at_guns",
    { enemy_ship_hp = 500, player_hull = 110, gun_damage = 0 },
    { enemy_ship_hp = 370, player_hull = 96, gun_damage = 130 }
)
equal(#cannonItems, 3, "cannon action creates target, part and retaliation scene feedback")
equal(cannonItems[1].value, "-130", "enemy scene feedback uses the real ship loss")
equal(cannonItems[2].label, "火炮压制", "part feedback names the affected subsystem")
equal(cannonItems[3].target, "player", "retaliation feedback returns to the player side")

local boardingItems = Theme.sceneFeedbackItems(
    "boarding_attack",
    { enemy_boarding_hp = 65, crew_hp = 100 },
    { enemy_boarding_hp = 35, crew_hp = 82 }
)
equal(boardingItems[1].value, "-30", "boarding feedback exposes enemy loss")
equal(boardingItems[2].value, "-18", "boarding feedback exposes crew loss")

local tideItems = Theme.sceneFeedbackItems(
    "tide_ram",
    { tide_shield = 100, player_hull = 130 },
    { tide_shield = 0, player_hull = 120 }
)
equal(tideItems[1].value, "-100", "guardian feedback exposes shield loss")
equal(tideItems[2].value, "-10", "guardian feedback exposes ram hull cost")

local settlementGroups = Theme.outcomeGroups(State.new("qa_settlement"), State.getData())
equal(#settlementGroups, 3, "settlement is grouped into three scan targets")
equal(settlementGroups[1].value, "金币 +35\n木材 +10", "settlement reward group uses authored values")
equal(settlementGroups[2].value, "铁料 +15\n符文 +6", "battle and rune rewards stay causally combined")

local upgradeGroups = Theme.outcomeGroups(State.new("qa_upgrade"), State.getData())
equal(upgradeGroups[2].value, "木材 -10\n耐久 +20", "hull choice shows cost and payoff together")
equal(upgradeGroups[3].value, "铁料 -15\n齐射 +25", "gun choice shows cost and payoff together")

local failedGroups = Theme.outcomeGroups(State.new("qa_failed"), State.getData())
equal(failedGroups[2].value, "补给 -1\n保留航线", "retry group explains cost and retention")
equal(failedGroups[3].value, "金币 -5\n清除损伤", "port recovery group explains cost and reset")

local tideGroups = Theme.outcomeGroups(State.new("qa_tide_settlement"), State.getData())
equal(#tideGroups, 3, "second settlement exposes three result groups")
equal(tideGroups[3].label, "第二符文", "second settlement gives the new rune its own group")

equal(Theme.colors.separator[1], 76, "UI 3.0 keeps a dedicated quiet separator tone")

print("V2 UI 3.3 theme OK: scene feedback, result groups and hierarchy passed")
