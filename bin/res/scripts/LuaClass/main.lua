require "LuaClass/Update"

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(msg) .. "\n")
    print(debug.traceback())
    print("----------------------------------------")
end

-- 主函数
local function main()
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    --support debug,when used on ios7.1 64bit,these codes should be commented
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or 
       (cc.PLATFORM_OS_ANDROID == targetPlatform) or (cc.PLATFORM_OS_WINDOWS == targetPlatform) or
       (cc.PLATFORM_OS_MAC == targetPlatform) then
        local host = 'localhost' -- please change localhost to your PC's IP for on-device debugging
    end

    -- 使用了CCTMXTiledMap必须开启此设置才能消除地图移动时的黑边现象
    cc.Director:getInstance():setProjection(cc.DIRECTOR_PROJECTION2_D)

    -- 添加updateLayer,不允许重复添加
    local updateScene = cc.Scene:create()
    -- -- 添加更新界面层
    updateLayer = Update:create()
    updateLayer:setPosition(cc.p(0,0))
    updateScene:addChild(updateLayer)
    cc.Director:getInstance():runWithScene(updateScene)
end

xpcall(main, __G__TRACKBACK__)
