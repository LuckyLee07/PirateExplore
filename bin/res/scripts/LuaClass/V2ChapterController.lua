require "json"
require "LuaClass/SaveDataManager"
require "LuaClass/V2Config"

local V2ChapterState = require "LuaClass/V2ChapterState"
local V2Telemetry = require "LuaClass/V2Telemetry"

V2ChapterController = {}
V2ChapterController.__index = V2ChapterController

local singleton = nil
local SAVE_FILE = "v2ChapterState"

function V2ChapterController:getInstance()
    if singleton == nil then
        singleton = setmetatable({ state = nil }, V2ChapterController)
    end
    return singleton
end

function V2ChapterController:load()
    if self.state ~= nil then
        return self.state
    end

    local profile = V2Config:getSaveProfile()
    local content = SaveDataManager:getInstance():loadData(SAVE_FILE)
    local decoded = nil
    if content ~= nil and content ~= "" then
        local ok, result = pcall(json.decode, content)
        if ok and type(result) == "table" then
            decoded = result
        else
            cclog("V2 chapter save decode failed; creating a fresh profile")
        end
    end
    self.state = V2ChapterState.normalize(decoded, profile)
    V2Telemetry.ensureSession(self.state)
    self:save()
    return self.state
end

function V2ChapterController:save()
    if self.state == nil then
        return false
    end
    SaveDataManager:getInstance():SaveData(json.encode(self.state), SAVE_FILE)
    return true
end

function V2ChapterController:dispatch(action)
    local state = self:load()
    local before = V2Telemetry.snapshot(state)
    local ok, message = V2ChapterState.apply(state, action)
    V2Telemetry.record(state, action, before, ok, message)
    self:save()
    return ok, message, state
end

function V2ChapterController:reset(profile)
    self.state = V2ChapterState.new(profile or V2Config:getSaveProfile())
    V2Telemetry.ensureSession(self.state)
    self:save()
    return self.state
end

function V2ChapterController:getActions()
    return V2ChapterState.getActions(self:load())
end

function V2ChapterController:getStageTitle()
    return V2ChapterState.getStageTitle(self:load())
end

function V2ChapterController:getNarrative()
    return V2ChapterState.getNarrative(self:load())
end

function V2ChapterController:getPresentation()
    return V2ChapterState.getPresentation(self:load())
end

function V2ChapterController:getTelemetrySummary()
    return V2Telemetry.getSummary(self:load())
end

function V2ChapterController:getChapterData()
    return V2ChapterState.getData()
end

return V2ChapterController
