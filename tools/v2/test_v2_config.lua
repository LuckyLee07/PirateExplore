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
assert(not config:isQAProfile("player"))
assert(config:getPresentationMode("player") == "player")
assert(not config:isQAProfile("invalid_profile"))

zqV2SaveProfile = "qa_combat"
assert(config:getSaveProfile() == "qa_combat")
assert(config:scopedSaveName("gameRole") == "v2_chapter_01_qa_combat_gameRole")
assert(config:isQAProfile())
assert(config:isQAProfile("qa_fresh"))
assert(config:getPresentationMode() == "qa")

zqV2SaveProfile = "qa_boarding"
assert(config:getSaveProfile() == "qa_boarding")

zqV2SaveProfile = "qa_failed"
assert(config:getSaveProfile() == "qa_failed")

zqV2SaveProfile = "qa_harbor"
assert(config:getSaveProfile() == "qa_harbor")

for _, profile in ipairs({ "qa_port_low_supply", "qa_port_blocked" }) do
    zqV2SaveProfile = profile
    assert(config:getSaveProfile() == profile)
    assert(config:isQAProfile())
end

zqV2SaveProfile = "qa_explore_intel"
assert(config:getSaveProfile() == "qa_explore_intel")

for _, profile in ipairs({ "qa_route_event", "qa_black_tide", "qa_whisper", "qa_curse" }) do
    zqV2SaveProfile = profile
    assert(config:getSaveProfile() == profile)
    assert(config:isQAProfile())
end

zqV2SaveProfile = "qa_rune"
assert(config:getSaveProfile() == "qa_rune")

zqV2SaveProfile = "qa_complete"
assert(config:getSaveProfile() == "qa_complete")
assert(config:isQAProfile())

zqV2SaveProfile = "qa_upgrade"
assert(config:getSaveProfile() == "qa_upgrade")

zqV2SaveProfile = "qa_crew_growth"
assert(config:getSaveProfile() == "qa_crew_growth")

for _, profile in ipairs({
    "qa_tide_route", "qa_tide_guardian", "qa_tide_guardian_gunner",
    "qa_tide_guardian_sailor", "qa_tide_rune",
    "qa_tide_settlement", "qa_tide_complete",
}) do
    zqV2SaveProfile = profile
    assert(config:getSaveProfile() == profile)
    assert(config:isQAProfile())
end

zqV2SaveProfile = "invalid_profile"
assert(config:getSaveProfile() == "player")
assert(not config:isQAProfile())
assert(config:getPresentationMode() == "player")

print("V2Config OK")
