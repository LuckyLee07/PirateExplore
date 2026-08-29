package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local Frost = require "LuaClass/V2FrostVoyageModel"

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function truthy(value, message)
    if not value then error(message) end
end

local function applyRoute(state, route)
    local ok, message = Frost.chooseRoute(state, route)
    if not ok then error(message) end
end

local function applyBeacon(state, choice)
    local ok, message = Frost.chooseBeacon(state, choice)
    if not ok then error(message) end
end

local function applyHazard(state, action)
    local ok, message, outcome = Frost.applyHazardAction(state, action)
    if not ok then error(message) end
    return outcome
end

equal(Frost.MODEL_STATUS, "runtime_integrated_unexposed",
    "Frost model is integrated for QA while player entry remains closed")

local navigator = Frost.new({ hull = 140, hull_max = 140, hull_level = 1, pattern_index = 1 })
applyRoute(navigator, "frost_pack_channel")
applyBeacon(navigator, "read_ice_chart")
local forecast = Frost.currentForecast(navigator)
equal(forecast.window, "port", "pack pattern telegraphs its first left opening")
equal(forecast.correct_action, "frost_turn_port", "telegraph maps to a concrete spatial action")
truthy(forecast.exact, "navigator choice exposes exact action consequences")
local previews = Frost.getActionPreviews(navigator)
equal(previews[1].recommended, true, "left opening recommends the left spatial action")
equal(previews[1].progress, 2, "correct turn previews exact progress")
equal(previews[2].hull_damage, 14, "wrong turn previews hull-level-reduced collision")
local first = applyHazard(navigator, "frost_turn_port")
equal(first.progress, previews[1].progress, "runtime outcome matches the pre-commit preview")
equal(Frost.currentForecast(navigator).correct_action, "frost_turn_starboard",
    "the next round changes the optimal spatial action")
applyHazard(navigator, "frost_turn_starboard")
applyHazard(navigator, "frost_turn_port")
equal(navigator.phase, "complete", "three correct pack decisions cross the moving ice")
equal(navigator.hull, 140, "perfect navigation avoids collision damage")

local hidden = Frost.new({ pattern_index = 2 })
applyRoute(hidden, "frost_pack_channel")
applyBeacon(hidden, "warm_rescue_team")
equal(Frost.currentForecast(hidden).window, "starboard", "alternate sequence changes the first opening")
equal(Frost.currentForecast(hidden).exact, false, "medic choice keeps exact damage uncertain")
local hiddenPreview = Frost.getActionPreviews(hidden)[1]
equal(hiddenPreview.progress, nil, "non-navigator preview does not fake an exact value")
truthy(hiddenPreview.progress_text, "non-navigator preview provides an honest range")
local recovered = applyHazard(hidden, "frost_turn_port")
equal(recovered.hull_damage, 24, "wrong turn still computes its real collision")
equal(recovered.medic_recovery, 18, "medic choice visibly restores one mistake")
equal(hidden.hull, 114, "only the unrecovered collision remainder reaches ship state")
equal(hidden.medic_recovery_available, false, "medic recovery is explicitly one-use")

local sailor = Frost.new({ chief = "crew_upgrade_sailor", pattern_index = 1 })
applyRoute(sailor, "frost_pack_channel")
applyBeacon(sailor, "read_ice_chart")
local sailorHit = applyHazard(sailor, "frost_turn_starboard")
equal(sailorHit.hull_damage, 16, "sailor chief reduces the first wrong turn")
truthy(sailor.sailor_bonus_used, "sailor payoff is consumed once")

local gunner = Frost.new({ chief = "crew_upgrade_gunner", gun_level = 1, provisions = 8 })
applyRoute(gunner, "frost_flare_pass")
equal(gunner.provisions, 7, "flare route pays its visible opening supply cost")
applyBeacon(gunner, "read_ice_chart")
equal(Frost.currentForecast(gunner).correct_action, "frost_break_ice",
    "flare route opens with a center cannon window")
local cannon = applyHazard(gunner, "frost_break_ice")
equal(cannon.progress, 4, "gun growth and gunner chief create a visible first-window payoff")
equal(gunner.provisions, 6, "cannon action pays its exact previewed supply cost")
applyHazard(gunner, "frost_turn_port")
equal(gunner.phase, "complete", "gun-focused growth can cross the flare route in two decisions")

local gunnerMistake = Frost.new({ chief = "crew_upgrade_gunner", pattern_index = 1 })
applyRoute(gunnerMistake, "frost_pack_channel")
applyBeacon(gunnerMistake, "read_ice_chart")
local protectedShot = applyHazard(gunnerMistake, "frost_break_ice")
equal(protectedShot.hull_damage, 0, "gunner chief cancels the first off-window cannon backwash")
truthy(gunnerMistake.gunner_bonus_used, "gunner protection cannot repeat")

local failed = Frost.new({ hull = 120, provisions = 5, pattern_index = 1 })
applyRoute(failed, "frost_pack_channel")
applyBeacon(failed, "read_ice_chart")
applyHazard(failed, "frost_turn_starboard")
applyHazard(failed, "frost_turn_port")
applyHazard(failed, "frost_turn_starboard")
equal(failed.phase, "failed", "three wrong openings fail by passage progress, not a renamed shield")
equal(failed.failed_reason, "三轮冰潮结束时仍未驶出封锁", "failure explains the decision boundary")
local retryRoute = failed.route
local retryBeacon = failed.beacon_choice
local ok, retryMessage = Frost.retry(failed)
truthy(ok, retryMessage)
equal(failed.phase, "hazard", "retry restarts the three-round sequence")
equal(failed.route, retryRoute, "retry preserves the selected route")
equal(failed.beacon_choice, retryBeacon, "retry preserves the character-event result")
equal(failed.progress, 0, "retry clears temporary passage progress")
equal(failed.provisions, 4, "retry pays exactly one supply from the passage-start snapshot")

local port = Frost.new({ pattern_index = 1 })
applyRoute(port, "frost_pack_channel")
applyBeacon(port, "warm_rescue_team")
applyHazard(port, "frost_turn_starboard")
applyHazard(port, "frost_turn_port")
applyHazard(port, "frost_turn_starboard")
local portOk, portMessage = Frost.returnToPort(port)
truthy(portOk, portMessage)
equal(port.phase, "port", "failed voyage can return to preparation")
equal(port.route, nil, "port recovery clears the Frost route")
equal(port.beacon_choice, nil, "port recovery reopens the character choice")

print("V2 Frost voyage model OK: telegraph, spatial choice, six growth payoffs, failure and recovery passed")
