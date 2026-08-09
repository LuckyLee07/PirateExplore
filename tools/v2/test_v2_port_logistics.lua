package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local State = require "LuaClass/V2ChapterState"
local Port = require "LuaClass/V2PortModel"
local Telemetry = require "LuaClass/V2Telemetry"

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function truthy(value, message)
    if not value then error(message) end
end

local function actionById(state, actionId)
    for _, action in ipairs(State.getActions(state)) do
        if action.id == actionId then return action end
    end
    return nil
end

local function apply(state, action)
    local ok, message = State.apply(state, action)
    truthy(ok, message or (action .. " failed"))
    return message
end

local data = State.getData()

local low = State.new("qa_port_low_supply")
local logistics = Port.logistics(low, data)
equal(logistics.status, "low", "two provisions remain a valid but low departure reserve")
equal(logistics.capacity, 8, "reinforced hull uses the authored supply capacity")
equal(logistics.departure_cost, 1, "first-voyage departure cost comes from the map edge")
truthy(logistics.can_resupply, "affordable low supply exposes normal port service")
truthy(actionById(low, "start_voyage"), "low supply does not block a valid departure")
truthy(actionById(low, "port_resupply"), "low supply exposes the normal resupply action")
truthy(string.find(actionById(low, "port_resupply").label, "金币-4｜补给+3", 1, true),
    "resupply previews its exact source-driven exchange")

local goldBefore = low.resources.gold
apply(low, "port_resupply")
equal(low.resources.gold, goldBefore - 4, "normal resupply charges the authored gold cost")
equal(low.resources.provisions, 5, "normal resupply adds the authored supply gain")

local nearCapacity = State.new("qa_harbor")
nearCapacity.resources.provisions = 7
truthy(string.find(actionById(nearCapacity, "port_resupply").label, "补给+1", 1, true),
    "near-capacity resupply previews the capped gain")
apply(nearCapacity, "port_resupply")
equal(nearCapacity.resources.provisions, 8, "resupply never exceeds the selected module capacity")
truthy(actionById(nearCapacity, "port_resupply") == nil, "full supply hides redundant service")
local fullGold = nearCapacity.resources.gold
local ok, message = State.apply(nearCapacity, "port_resupply")
truthy(not ok and string.find(message, "补给舱", 1, true), "direct full-capacity dispatch is rejected")
equal(nearCapacity.resources.gold, fullGold, "rejected resupply never charges gold")

local heavy = State.new("qa_harbor")
apply(heavy, "select_heavy_guns")
equal(Port.logistics(heavy, data).loaded, 7, "heavy guns present their lower loaded capacity without an 8/7 ratio")
truthy(string.find(State.getNarrative(heavy), "当前可装载 7/7", 1, true),
    "harbor narrative distinguishes inventory from the selected module capacity")

local blocked = State.new("qa_port_blocked")
logistics = Port.logistics(blocked, data)
equal(logistics.status, "blocked", "zero supply visibly blocks departure")
truthy(logistics.can_claim_relief, "insolvent blocked harbor state exposes emergency relief")
equal(Port.status(blocked, data).label, "航程受阻", "port header surfaces the actual blocker")
truthy(actionById(blocked, "start_voyage") == nil, "blocked departure is not presented as actionable")
truthy(actionById(blocked, "port_resupply") == nil, "unaffordable normal service is hidden")
truthy(actionById(blocked, "claim_harbor_relief"), "emergency relief replaces an impossible purchase")

apply(blocked, "claim_harbor_relief")
equal(blocked.resources.provisions, 1, "relief grants only the minimum departure supply")
truthy(blocked.flags.harbor_relief_used, "relief is marked used for this harbor visit")
truthy(actionById(blocked, "claim_harbor_relief") == nil, "relief cannot be farmed during one harbor visit")
truthy(actionById(blocked, "start_voyage"), "relief immediately restores a valid departure")
ok, message = State.apply(blocked, "claim_harbor_relief")
truthy(not ok and string.find(message, "已经足够离港", 1, true), "repeat relief dispatch is safely rejected")
apply(blocked, "start_voyage")
equal(blocked.resources.provisions, 0, "emergency supply is consumed by departure")
truthy(blocked.flags.harbor_relief_used == nil, "departure resets relief for a future harbor visit")

local recovered = State.new("qa_failed")
recovered.resources.gold = 5
recovered.resources.provisions = 0
apply(recovered, "recover_at_port")
equal(recovered.stage, "harbor", "paid recovery still returns to the shared harbor")
equal(recovered.voyage_hull_damage, 0, "existing paid port recovery remains the real hull-damage repair path")
truthy(actionById(recovered, "claim_harbor_relief"), "zero-resource recovery receives a non-farmable exit path")

local cargoActions = Port.actions("cargo", State.getActions(low))
equal(#cargoActions, 1, "cargo focuses on the one available logistics service")
equal(cargoActions[1].id, "port_resupply", "cargo service remains owned by the chapter state machine")
local chartActions = Port.actions("chart", State.getActions(low))
equal(#chartActions, 1, "chart remains focused on departure when supply is valid")
equal(chartActions[1].id, "start_voyage", "chart does not duplicate the cargo service")
equal(#Port.actions("chart", State.getActions(State.new("qa_port_blocked"))), 0,
    "blocked chart directs attention to cargo instead of exposing an invalid departure")
equal(#State.getActions(State.new("qa_tide_complete")), 0,
    "port logistics does not fabricate a third voyage after the content boundary")

local restored, recovery = State.normalize(State.new("qa_port_blocked"), "qa_port_blocked")
truthy(recovery == nil and restored.stage == "harbor", "new logistics QA state is restorable without a schema bump")

local tracked = State.new("qa_port_low_supply")
local before = Telemetry.snapshot(tracked)
apply(tracked, "port_resupply")
local event = Telemetry.record(tracked, "port_resupply", before, true, tracked.last_result)
equal(event.event_id, "port_logistics_used", "normal and emergency services share a focused telemetry event")
equal(Telemetry.getSummary(tracked).port_logistics_actions, 1, "telemetry summary counts logistics usage")

print("V2 port logistics OK: normal resupply, capped gain, emergency relief, recovery, port focus and telemetry")
