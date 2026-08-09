package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local State = require "LuaClass/V2ChapterState"
local Port = require "LuaClass/V2PortModel"

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function truthy(value, message)
    if not value then error(message) end
end

local data = State.getData()
local harbor = State.new("qa_harbor")
equal(#Port.sections, 4, "port exposes four focused preparation areas")
equal(Port.status(harbor, data).label, "可以出航", "harbor reports actionable readiness")

local ship = Port.ship(harbor, data)
equal(ship.selected_module, "加固船体", "ship panel reads the equipped module")
equal(ship.hull_max, 120, "ship panel reads the real calculated hull maximum")
equal(#ship.modules, 2, "first chapter keeps two legible module tendencies")
truthy(ship.modules[1].selected, "reinforced hull is selected in the default harbor profile")
equal(ship.gun_upgrade.gain, 25, "ship upgrade preview uses the authored balance table")

local crew = Port.crew(harbor, data)
equal(#crew, 4, "all authored core crew appear in preparation")
equal(crew[1].name, "罗克", "crew order follows the save roster")
equal(crew[1].role, "炮手", "crew role is presented in player language")
equal(crew[1].active_detail, "下一次甲板齐射获得额外破坏", "crew cards translate action ids into authored effects")
equal(crew[4].active_skill, "紧急包扎", "crew cards expose the real active skill")

local cargo = Port.cargo(harbor, data)
equal(#cargo, 5, "cargo uses the compressed five-resource economy")
equal(cargo[4].name, "补给", "cargo preserves authored resource order")
equal(cargo[4].value, 8, "cargo reads the current save value")

local readiness = Port.readiness(harbor, data)
equal(#readiness, 3, "chart table keeps only ship, crew and provisions readiness")
truthy(readiness[1].ready and readiness[2].ready and readiness[3].ready, "default preparation is playable without busywork")

local harborActions = Port.actions("chart", State.getActions(harbor))
equal(#harborActions, 1, "chart table exposes the real departure action")
equal(harborActions[1].id, "start_voyage", "departure remains owned by the chapter state machine")

local nextVoyage = State.new("qa_complete")
nextVoyage.profile = "player"
local nextActions = Port.actions("chart", State.getActions(nextVoyage))
equal(nextActions[1].id, "prepare_next_voyage", "chart exposes the real retained-growth transition")
truthy(not Port.returnsToVoyage("prepare_next_voyage"), "preparation remains in the port after loading growth")
State.apply(nextVoyage, "prepare_next_voyage")
truthy(string.find(Port.status(nextVoyage, data).detail, "第 2 次", 1, true), "port status identifies the prepared voyage")

local upgrade = State.new("qa_upgrade")
local upgradeActions = Port.actions("ship", State.getActions(upgrade))
equal(#upgradeActions, 2, "shipyard exposes both real first-upgrade choices")
truthy(Port.returnsToVoyage("upgrade_hull"), "committed upgrades return to the chapter result")

local settlement = State.new("qa_settlement")
local cargoActions = Port.actions("cargo", State.getActions(settlement))
equal(#cargoActions, 1, "cargo exposes the real return action after loot is counted")
equal(cargoActions[1].id, "return_to_port", "cargo never invents a second settlement authority")

equal(Port.status(State.new("qa_failed")).accent, "danger", "failed voyage is visibly cautionary")
equal(Port.status(State.new("qa_complete")).label, "首航完成", "completed voyage has a stable port state")
equal(Port.status(State.new("qa_tide_guardian")).label, "潮盾交战", "port reflects the distinct guardian encounter")
equal(Port.status(State.new("qa_tide_complete")).label, "墓场完成", "port reflects second-voyage completion")

print("V2 UI 3.4 port model OK: chart, ship, crew, cargo and real actions passed")
