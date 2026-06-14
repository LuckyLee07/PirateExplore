require "AudioEngine"
require "LuaClass/Header"
require "LuaClass/DataManager"
require "LuaClass/ToastUtil"
require "LuaClass/NotificationNode"
require "LuaClass/MissionManagers"
local mapLayer = nil


function cleanUpController()
    cclog("清理所有的层，走析构")
    -- 如果主界面层存在，那么先卸载他~
    if zqDispatch ~= nil then
        zqDispatch:destory()
        zqDispatch = nil
    end
    -- 如果在地图层，那么卸载他
    if mapLayer ~= nil then
        mapLayer:destory()
        mapLayer = nil
    end
end

gotoMainUI = function(isFromExp)
    if isFromExp == nil then
        isFromExp = false
    end

    cclog("初始化游戏主UI界面")
    cleanUpController()
    require "LuaClass/Dispatch"
    -- 添加主界面层,不允许重复添加
    if zqDispatch == nil then
        local gameScene = cc.Scene:create()
        zqDispatch = Dispatch:create()
        zqDispatch:setPosition(cc.p(0, 0))
        gameScene:addChild(zqDispatch)

        if cc.UserDefault:getInstance():getBoolForKey("musicTuranOff") == true then
            local _type = cc.UserDefault:getInstance():getBoolForKey("musicType")
            if _type == true then
                DataManager:getInstance():setMusic_off(0)
                DataManager:getInstance():setSound_off(0)
            else
                DataManager:getInstance():setMusic_off(1)
                DataManager:getInstance():setSound_off(1)
            end
            cc.UserDefault:getInstance():setBoolForKey("musicTuranOff",false)
        end

        if DataManager:getInstance():getMusic_off() == 0 then
            AudioEngine.playMusic(MUSIC_Main, true)
            HAS_MUSIC_FILE = 1
        else
            -- 不播放
        end

        if cc.Director:getInstance():getRunningScene() ~= nil then
            cc.Director:getInstance():replaceScene(gameScene)
        else
            cc.Director:getInstance():runWithScene(gameScene)
        end

    end

    --从map回来弹广告评论
    if isFromExp == true then
        showRateOrAdScene()
    end
end

gotoMap = function ()
    cclog("gotoMap++++++++++++++")
    local statue = DataManager:getInstance():getRoleData(roleStatue)
    DataManager:getInstance():setRoleData(roleStatue,1)
    cleanUpController()
    require "LuaClass/Explore"
    if mapLayer == nil then
        local exploreScene = cc.Scene:create()
      
        if DataManager:getInstance():getMusic_off() == 0 then
            AudioEngine.playMusic(MUSIC_Map, true)
            HAS_MUSIC_FILE = 1
        else
            -- 不播放
        end
        --设置玩家状态为1(探索状态)
        print("状态222222",statue)

        if cc.Director:getInstance():getRunningScene() ~= nil then
            print("enter12")
            local index = 1
            local roleMapInfo = DataManager:getInstance():getRoleData(roleMapInfo)
            --读取上次地图的索引点...
            if roleMapInfo ~= nil and roleMapInfo.curIndex ~= nil then
                print("index",index,roleMapInfo,roleMapInfo.curIndex)
                index = roleMapInfo.curIndex
            else
                
            end
            print("index",index)
            --直接进入
            if index < 5 or statue == 1 then
                mapLayer = Explore:create()
                mapLayer:setPosition(cc.p(0, 0))
                exploreScene:addChild(mapLayer)
                cc.Director:getInstance():replaceScene(exploreScene)
                mapLayer:startJumpAction()
            --需要loading
            else
                mapLayer = cc.Layer:create()
                require "LuaClass/LoadingScene"
                local loadingScence = LoadingScene:create()
                cc.Director:getInstance():replaceScene(loadingScence)
                loadingScence:begainMoveAction(0.25,function (  )
                    loadingScence:update()
                    
                end)
                loadingScence:setLoadedFunc(function (  )
                    local exploreScene = cc.Scene:create()
                    mapLayer = Explore:create()
                    mapLayer:setPosition(cc.p(0, 0))
                    exploreScene:addChild(mapLayer)
                    cc.Director:getInstance():replaceScene(exploreScene)
                end)

                local co = coroutine.create(function ( )
                    
                        -- local index = 1
                        -- local roleMapInfo = DataManager:getInstance():getRoleData(roleMapInfo)
                        -- --读取上次地图的索引点...
                        -- if roleMapInfo ~= nil and roleMapInfo.curIndex ~= nil then
                        --     print("roleInfo0",index,roleMapInfo,roleMapInfo.curIndex)
                        --     index = roleMapInfo.curIndex
                        -- end
                        print("roleInfo",index)
                        DataManager:getInstance():loadMapDataByID(index)
                        loadingScence.addNum = 0.5
                    end)
                loadingScence.co = co
            end
        else
            mapLayer = Explore:create()
            mapLayer:setPosition(cc.p(0, 0))
            exploreScene:addChild(mapLayer)
            cc.Director:getInstance():runWithScene(exploreScene)
            mapLayer:startJumpAction()
        end
    end
end

gotoFight = function ()
    require "LuaClass/FightMode"
    local fightScene = FightScene:create(FightScene.FightType.shipWar)
    fightScene:setFightOverCallback(function(result)
--        cclog("return from fight, fight result is "..tostring(result))
    end)
    
    if DataManager:getInstance():getMusic_off() == 0 then
        AudioEngine.playMusic(MUSIC_PK, true)
    else
        -- 不播放
    end
    local scene = cc.Scene:create()
    scene:addChild(fightScene)
    cc.Director:getInstance():pushScene(scene)
end

-- 主函数
function startGame()
    
    require "LuaClass/NotificationNode"
    cc.Director:getInstance():setNotificationNode(NotificationNode:getInstance())
    NotificationNode:getInstance():registeventDispatcher()
    
    -- 随机数种子
    math.randomseed(os.time())
    math.random();math.random();math.random()
    -- 设置监听节点
    
    --requestLastTime()
    
    --print("------- 0000000 parser")
    DataManager:getInstance()
    DataManager:getInstance():postEvent(1, "eventData111111")
    --初始化任务管理者
    MissionManagers:getInstance()

    local cur_time = os.time()
    if not DataManager:getInstance():getRoleData(roleFristLoginTime) then
        DataManager:getInstance():setRoleData(roleFristLoginTime, cur_time)
    else
        local targetTime = DataManager:getInstance():getRoleData(roleFristLoginTime)
        local disTime = cur_time - targetTime
        local disDay = math.floor(disTime / 3600 / 24)
        local recordDays = DataManager:getInstance():getRoleData(roleLoginDayTime)

        if recordDays == nil then
            recordDays = {}
            DataManager:getInstance():setRoleData(roleLoginDayTime,recordDays)
        end

        if disDay < 7 and not recordDays[disDay] then
            recordDays[disDay] = 1
            DataManager:getInstance():setRoleData(roleLoginDayTime,recordDays)
        end
    end

    -- DataManager:getInstance():addDiamond(100000)
    -- 开始计算资源获取
    NotificationNode:getInstance():getResource()
    --print("------- 1111111 parser")

    -- 注册支付成功的回调事件（必须这么做，否则会导致界面出问题）
    NotificationNode:getInstance():registerChargeCallBack()


    if cc.UserDefault:getInstance():getBoolForKey("isFirtPlotShown", false) then
        local statue = DataManager:getInstance():getRoleData(roleStatue)
        --若没有状态，则是第一次进入游戏，将状态置为0
        if statue == nil then
            DataManager:getInstance():setRoleData(roleStatue, 0)
        end
        --若状态为1则为地图探索状态，加载地图
        if statue == 1 then
            gotoMap()
        else
            gotoMainUI()
        end
    else
        cc.UserDefault:getInstance():setBoolForKey("isFirtPlotShown", true)
        require "LuaClass/PlotMode"
        local plotScene = PlotScene:create({1, 2, 3, 4, 5, 6, 7}, function()
            gotoMainUI()
        end)
        cclog("初始化updateLayer界面")
        cleanUpController()
        if cc.Director:getInstance():getRunningScene() ~= nil then
            cc.Director:getInstance():replaceScene(plotScene)
        else
            cc.Director:getInstance():runWithScene(plotScene)
        end
    end
    -- gotoUpdate()
end
