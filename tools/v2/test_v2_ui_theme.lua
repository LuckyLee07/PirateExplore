package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local Theme = require "LuaClass/V2UITheme"

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

equal(Theme.accentName("route_choice"), "sea", "exploration uses the sea accent")
equal(Theme.accentName("naval"), "danger", "combat uses the danger accent")
equal(Theme.accentName("rune_clue"), "purple", "rune discovery uses the curse accent")
equal(Theme.accentName("complete"), "success", "completion uses the success accent")

equal(Theme.actionRole("opening", "accept_call", 1, 1), "primary", "single forward action is primary")
equal(Theme.actionRole("route_choice", "reveal_route_intel", 1, 3), "utility", "route intel is utility")
equal(Theme.actionRole("naval", "retreat", 5, 5), "danger", "retreat is visually cautionary")
equal(Theme.actionRole("harbor", "select_reinforced_hull", 1, 3, "module_reinforced_hull"), "selected", "equipped module is selected")
equal(Theme.actionRole("failed", "retry_battle", 1, 2), "primary", "retry is the forward recovery action")

local resources = Theme.resourceItems({ gold = 40, timber = 2, iron = 3, provisions = 6, rune_dust = 1 })
equal(#resources, 5, "resource HUD stays compact")
equal(resources[1].value, 40, "gold value is forwarded")
equal(resources[5].accent, "purple", "rune resource keeps its semantic accent")

print("V2 UI 2.0 theme OK: stage accents, progress, resources and action hierarchy passed")
