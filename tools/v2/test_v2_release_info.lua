package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local info = require "LuaClass/V2ReleaseInfo"

local function assertContains(text, marker)
    assert(string.find(text, marker, 1, true) ~= nil, "missing release-info marker: " .. marker)
end

assert(info.APP_VERSION == "2.0.0")
assertContains(info.PRIVACY_TEXT, "不收集或向服务器传输个人数据")
assertContains(info.PRIVACY_TEXT, "只保存在本机")
assertContains(info.PRIVACY_TEXT, "卸载应用会删除这些本地数据")
assertContains(info.PRIVACY_TEXT, "不使用第三方数据处理 SDK")
assertContains(info.SUPPORT_TEXT, "删除并重装应用会清除章节存档")
assertContains(info.SUPPORT_TEXT, "App Store 产品页")

for _, forbidden in ipairs({
    "探险科技有限公司",
    "106134362",
    "1976428305@qq.com",
    "example.com",
    "{{",
}) do
    assert(string.find(info:getCombinedText(), forbidden, 1, true) == nil, "legacy or placeholder release content leaked: " .. forbidden)
end

assert(info:isPublishableHttpsUrl(nil) == false)
for _, invalid in ipairs({
    "",
    "http://pirate.test/privacy/",
    "https://localhost/privacy/",
    "https://example.com/privacy/",
    "https://release.invalid/privacy/",
    "{{PRIVACY_POLICY_URL}}",
}) do
    assert(info:isPublishableHttpsUrl(invalid) == false)
end

assert(info:isPublishableHttpsUrl("https://pirate-studio.cn/privacy/") == true)
assert(info.PRIVACY_POLICY_URL == nil or info:isPublishableHttpsUrl(info.PRIVACY_POLICY_URL))
assert(info.SUPPORT_URL == nil or info:isPublishableHttpsUrl(info.SUPPORT_URL))
assert(info:getPublicUrl("privacy") == info.PRIVACY_POLICY_URL)
assert(info:getPublicUrl("support") == info.SUPPORT_URL)
assert(info:hasConfiguredPublicLinks() == (info.PRIVACY_POLICY_URL ~= nil and info.SUPPORT_URL ~= nil))

if info:hasConfiguredPublicLinks() then
    print("V2 release information validation passed; public URLs are configured")
else
    print("V2 release information validation passed; public URLs remain an external release gate")
end
