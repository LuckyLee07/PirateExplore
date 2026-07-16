-- Player-facing privacy and support information for the V2 iOS release.
--
-- Public URLs deliberately remain nil until the product owner supplies and
-- verifies the real HTTPS pages. Never ship placeholder or example domains.

local V2ReleaseInfo = {
    APP_VERSION = "2.0.0",
    PRIVACY_POLICY_URL = nil,
    SUPPORT_URL = nil,
}

V2ReleaseInfo.PRIVACY_TEXT = table.concat({
    "适用版本｜海上探险家 2.0.0（iOS）",
    "",
    "数据处理｜当前版本无需注册或登录，不收集或向服务器传输个人数据，不包含广告、分析、跨应用跟踪或应用内购买。",
    "",
    "本地数据｜章节进度、资源、船只状态、设置和本地游玩记录只保存在本机，用于恢复游戏和呈现本地进度。卸载应用会删除这些本地数据；本版本没有云端账号或服务器数据删除流程。",
    "",
    "权限与第三方｜当前版本不请求定位、通讯录、相机、麦克风或照片权限，也不使用第三方数据处理 SDK。",
    "",
    "政策更新｜若后续版本新增账号、联网、统计、广告、内购或其他数据能力，将在发布前更新本说明、公开隐私政策和 App Store 隐私信息。",
}, "\n")

V2ReleaseInfo.SUPPORT_TEXT = table.concat({
    "支持范围｜海上探险家 2.0.0（iOS）",
    "",
    "启动问题｜先彻底退出应用后重新打开；若仍停留在加载页，请记录设备型号、系统版本和复现步骤。",
    "",
    "进度说明｜进度只保存在本机。删除并重装应用会清除章节存档；章节完成页的“重新开始第一章”只重置当前章节进度。",
    "",
    "声音问题｜请同时检查设备音量、静音状态以及应用内声音设置。",
    "",
    "联系支持｜正式发布后请从 App Store 产品页的“App 支持”进入已验证的公开支持页面。反馈时请勿提交密码、身份证件或其他无关敏感信息。",
}, "\n")

local function isPublishableHttpsUrl(url)
    if type(url) ~= "string" then
        return false
    end
    local normalized = string.lower(url)
    if string.match(normalized, "^https://[%w]") == nil then
        return false
    end
    for _, forbidden in ipairs({ "localhost", "127.0.0.1", "example.", ".invalid", "{{", "}}" }) do
        if string.find(normalized, forbidden, 1, true) ~= nil then
            return false
        end
    end
    return true
end

function V2ReleaseInfo:isPublishableHttpsUrl(url)
    return isPublishableHttpsUrl(url)
end

function V2ReleaseInfo:getPublicUrl(kind)
    local url = nil
    if kind == "privacy" then
        url = self.PRIVACY_POLICY_URL
    elseif kind == "support" then
        url = self.SUPPORT_URL
    end
    if isPublishableHttpsUrl(url) then
        return url
    end
    return nil
end

function V2ReleaseInfo:hasConfiguredPublicLinks()
    return self:getPublicUrl("privacy") ~= nil and self:getPublicUrl("support") ~= nil
end

function V2ReleaseInfo:getCombinedText()
    return self.PRIVACY_TEXT .. "\n\n————————\n\n" .. self.SUPPORT_TEXT
end

return V2ReleaseInfo
