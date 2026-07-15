local config = dofile("bin/res/scripts/LuaClass/V2Config.lua")

assert(config.VERSION == "2.0")
assert(config.CURRENT_PHASE >= 0 and config.CURRENT_PHASE <= 4)
assert(config:isFeatureEnabled("v2.chapter_01"))
assert(config:isFeatureEnabled("v2.scoped_save"))

local disabledLegacyFeatures = {
    "legacy.achievement",
    "legacy.ranking",
    "legacy.diamond_store",
    "legacy.charge",
    "legacy.push_gift",
    "legacy.seven_day_bonus",
    "legacy.eternal_arena",
    "legacy.rating_ads",
    "legacy.paid_map_unlock",
    "legacy.missions",
}

for _, featureName in ipairs(disabledLegacyFeatures) do
    assert(not config:isFeatureEnabled(featureName), featureName .. " must be disabled")
end

assert(config:scopedSaveName("gameRole") == "v2_chapter_01_player_gameRole")
assert(config:scopedSaveName("v2_chapter_01_player_gameRole") == "v2_chapter_01_player_gameRole")
assert(config:scopedPreferenceKey("isFirstPlotShown") == "v2_chapter_01_player_isFirstPlotShown")

zqV2SaveProfile = "qa_combat"
assert(config:getSaveProfile() == "qa_combat")
assert(config:scopedSaveName("gameRole") == "v2_chapter_01_qa_combat_gameRole")

zqV2SaveProfile = "qa_boarding"
assert(config:getSaveProfile() == "qa_boarding")

zqV2SaveProfile = "qa_rune"
assert(config:getSaveProfile() == "qa_rune")

zqV2SaveProfile = "invalid_profile"
assert(config:getSaveProfile() == "player")

print("V2Config OK")
