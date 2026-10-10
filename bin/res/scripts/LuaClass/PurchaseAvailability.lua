require "LuaClass/ToastUtil"

local PurchaseAvailability = {}

-- GameBaseUtil::purchase only has iOS and Android implementations. Use the
-- Application platform enum exposed to Lua, not the native build macros.
-- This checks bridge availability, not store configuration or purchase success.
function PurchaseAvailability.isAvailable()
    local platform = cc.Application:getInstance():getTargetPlatform()
    local mobile = platform ~= nil and
        (platform == cc.PLATFORM_OS_IPHONE or platform == cc.PLATFORM_OS_IPAD or
         platform == cc.PLATFORM_OS_ANDROID)
    return mobile and type(purchase) == "function"
end

function PurchaseAvailability.request(productId)
    if not PurchaseAvailability.isAvailable() then
        ToastUtil:downString("当前平台暂不支持充值购买")
        return false
    end

    -- Native callbacks remain responsible for rewards and navigation. A true
    -- return value means only that the original request was handed to native.
    purchase(productId)
    return true
end

return PurchaseAvailability
