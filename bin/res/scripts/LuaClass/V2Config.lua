-- NewPirate V2 product/runtime baseline.
--
-- Keep this module independent from Cocos so its feature and save rules can be
-- validated with a standalone Lua interpreter.

V2Config = {
    VERSION = "2.0",
    CURRENT_PHASE = 0,
    CHAPTER_ID = "chapter_01",
    SAVE_SCHEMA_VERSION = 1,
    SAVE_NAMESPACE = "v2_chapter_01",
    DEFAULT_SAVE_PROFILE = "player",

    FEATURE_FLAGS = {
        ["v2.chapter_01"] = true,
        ["v2.scoped_save"] = true,

        ["legacy.achievement"] = false,
        ["legacy.ranking"] = false,
        ["legacy.diamond_store"] = false,
        ["legacy.charge"] = false,
        ["legacy.push_gift"] = false,
        ["legacy.seven_day_bonus"] = false,
        ["legacy.eternal_arena"] = false,
        ["legacy.rating_ads"] = false,
        ["legacy.paid_map_unlock"] = false,
    },
}

local validSaveProfiles = {
    player = true,
    qa_fresh = true,
    qa_explore = true,
    qa_combat = true,
}

function V2Config:isFeatureEnabled(featureName)
    return self.FEATURE_FLAGS[featureName] == true
end

function V2Config:getSaveProfile()
    local requestedProfile = rawget(_G, "zqV2SaveProfile")
    if validSaveProfiles[requestedProfile] then
        return requestedProfile
    end
    return self.DEFAULT_SAVE_PROFILE
end

function V2Config:getSavePrefix()
    return string.format("%s_%s_", self.SAVE_NAMESPACE, self:getSaveProfile())
end

function V2Config:scopedSaveName(fileName)
    if not self:isFeatureEnabled("v2.scoped_save") then
        return fileName
    end

    local prefix = self:getSavePrefix()
    if string.sub(fileName, 1, string.len(prefix)) == prefix then
        return fileName
    end
    return prefix .. fileName
end

function V2Config:scopedPreferenceKey(key)
    if not self:isFeatureEnabled("v2.scoped_save") then
        return key
    end
    return self:getSavePrefix() .. key
end

function V2Config:getFeatureUnavailableText(featureName)
    local messages = {
        ["legacy.achievement"] = "成就系统将在核心远航体验稳定后重新设计",
        ["legacy.ranking"] = "排行榜暂未开放，当前版本专注首章远航",
        ["legacy.diamond_store"] = "钻石商城已从首章流程中移除",
        ["legacy.charge"] = "首章验证阶段暂不开放充值",
        ["legacy.eternal_arena"] = "永恒竞技场暂未开放",
        ["legacy.paid_map_unlock"] = "完成当前海域目标后才能继续航行",
    }
    return messages[featureName] or "该功能暂未开放"
end

return V2Config
