-- Read-only presentation: soldier.skill identifies a skill, never a buff.
-- Buff descriptions describe only additional effects, not the whole skill.
CrewSkillDetails = {}
local D = CrewSkillDetails
local unavailable = "暂不可用"
local function row(csv, id)
    if type(csv) ~= "table" or id == nil then return nil end
    return csv[tostring(id)] or csv[tonumber(id)] or csv[id]
end
local function text(value)
    return type(value) == "string" and value ~= "" and value or nil
end
function D.describe(skillId, skills, buffs)
    local skill = row(skills, skillId)
    if not skill then return unavailable, unavailable end
    local name = text(skill.name) or unavailable
    local buffId = tonumber(skill.buffID)
    if buffId == 0 then return name, "无额外附加效果" end
    if not buffId or buffId < 0 then return name, unavailable end
    local buff = row(buffs, skill.buffID)
    return name, buff and text(buff.description) or unavailable
end
return D
