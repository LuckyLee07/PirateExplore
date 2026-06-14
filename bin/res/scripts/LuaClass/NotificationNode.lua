--
-- Created by IntelliJ IDEA.
-- User: sunxy
-- Date: 15/1/12
-- Time: 下午2:45
-- To change this template use File | Settings | File Templates.
--

require "LuaClass/Header"
require "LuaClass/SDButton"
require "LuaClass/HttpSingleton"
require "LuaClass/SevenDayBonus"

NotificationNode = class("NotificationNode", function ()
    return cc.Layer:create()
end)
NotificationNode.__index = NotificationNode
NotificationNode.instance = nil 
-- lastUpdateTime
NotificationNode.lastUpdateTime = 0
NotificationNode.schduler = nil
NotificationNode.lasttime = 0
NotificationNode.diamondStroeGiftType = 0
NotificationNode.buyStatus = 0

local co = nil

function NotificationNode:getInstance()  
    if nil == NotificationNode.instance then  
        NotificationNode.instance = NotificationNode:create()  
        
    end  
    return NotificationNode.instance  
end  



-- 网络测试函数
function requestLastTime()

    local tmp = HttpSingleton:getInstance()

    local function callback(xhr)
        
        if xhr.response == "" then
            --ToastUtil:downString("网络连接失败，无法领取离线资源")
            bIsTimeUpdateSuccess = false
        else
            local event = cc.EventCustom:new("getLasttime")
            event._usedata = xhr.response
            local  temp = cc.Director:getInstance():getNotificationNode():getEventDispatcher()
            temp:dispatchEvent(event)
            print("post callback code = "..xhr.statusText)
            bIsTimeUpdateSuccess = true
        end
        
    end

    local type = tmp.POST
    local url = ""--""http://113.31.128.35:11200/pirate/common/getTime.jsp"
    local dataPost = {}
    dataPost.type = "local"
    tmp:send(type, url, dataPost, callback)

end

----------------------- 创建自定义事件 Http返回最新的网络时间
local function HTTPCallback_getLasttime(event)
    cclog("response: "..event._usedata)

    local basestr = (tonumber(event._usedata))/1000

    local LastTime = DataManager:getInstance():getRoleData(roleLastTime)

    if LastTime ~= nil then
        if basestr - LastTime > 480 then
            -- 发放离线资源
            cclog("发放离线资源,弹出7日登陆奖励")
            --
            -- 取出资源cd时间（默认20秒）和离线奖励时间（默认3600秒）
            local CDTime = DataManager:getInstance():getRoleData(roleResourceCD)
            local OfflineTime = DataManager:getInstance():getRoleData(roleOfflineBonusTime)
            local realtime = basestr - LastTime;
            if realtime > OfflineTime then
                realtime = OfflineTime
            end
            -- 得到资源的倍数
            local getcom = math.floor(realtime / CDTime)
            local packData = DataManager:getInstance():getRoleData(rolePack)
            local workerCsv = DataManager:getInstance():getCSVByID(csvOfWorker)
            local workerData = DataManager:getInstance():getRoleData(roleProducerQueue)
            local produceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
            local floatTable = {}
            local coinNum = 0
            if #workerData > 0 then
                for i = 1, #workerData do
                    local workerTable = workerData[i]
                    if workerTable ~= nil then
                        local workerNumber = tonumber(workerTable[dataKeyNum])
                        local bIsCanAdd = true
                        local workerCsvData = workerCsv[workerTable[dataKeyID]]
                        local produceData = workerCsvData["produce"]
                        local resumeData = workerCsvData["resume"]
                        -- 一个一个的判断是否可以制作，不够就break，继续生产下一个单位
                        for k = 1, workerNumber * getcom do
                            if resumeData ~= nil then
                                -- 设置一个临时的表用来存储扣减数据
                                local tempData = {}
                                -- 先判断材料是否充足，不足不制造
                                for j = 1, #resumeData do
                                    -- 如果数量不存在，证明这个没数据，继续找下一个，没有就算了
                                    if resumeData[j][2] ~= nil then
                                        local needNum = tonumber(resumeData[j][2])
                                        local num = packData[resumeData[j][1]]
                                        if resumeData[j][1] == "1001" then
                                            num = DataManager:getInstance():getRoleData(roleMoney) + coinNum
                                        end
                                        if num == nil then
                                            num = 0
                                        end
                                        if num < needNum then
                                            -- 如果背包里的道具数量不足扣的，那么停止生产
                                            bIsCanAdd = false
                                            -- 清理数据，防止扣减
                                            tempData = {}
                                            break
                                        end
                                        -- 记录需要扣减的内容
                                        tempData[resumeData[j][1]] = needNum
                                    end
                                end

                                -- 扣减背包数量以及金币数量
                                for k, v in pairs(tempData) do
                                    if k == "1001" then
                                        coinNum = coinNum - v
                                    else
                                        packData[k] = packData[k] - v
                                    end
                                    -- 写入飘字数据
                                    if floatTable[k] ~= nil then
                                        floatTable[k] = floatTable[k] - v
                                    else
                                        floatTable[k] = -v
                                    end
                                end
                            else
                                -- 没需求数据，不生产
                                bIsCanAdd = false
                            end

                            -- 如果数量足够生产，那么生产道具
                            if bIsCanAdd then
                                if produceData ~= nil then
                                    for j = 1, #produceData do
                                        local resultNum = tonumber(produceData[j][2])
                                        -- 写入数据到背包,如果不是金币的话
                                        if produceData[j][1] == "1001" then
                                            coinNum = coinNum + resultNum
                                        else
                                            if packData[produceData[j][1]] ~= nil then
                                                -- 如果这条背包数据有，那么直接添加
                                                packData[produceData[j][1]] = packData[produceData[j][1]] + resultNum
                                            else
                                                -- 如果这条背包数据木有，那么直接赋值
                                                packData[produceData[j][1]] = resultNum
                                            end
                                        end
                                        -- 写入飘字数据
                                        if floatTable[produceData[j][1]] ~= nil then
                                            floatTable[produceData[j][1]] = floatTable[produceData[j][1]] + resultNum
                                        else
                                            floatTable[produceData[j][1]] = resultNum
                                        end
                                    end
                                end
                            else
                                break
                            end
                        end
                    end
                end

                -- 计算完毕之后操作一次金币，要不然每次操作都回卡，感谢祖祎提供bug反馈
                DataManager:getInstance():addCoin(coinNum)

                -- 存储数据
                DataManager:getInstance():setRoleData(rolePack, packData, nil)
                --
                --
                -- 最后循环飘字提示

                local showstr = "在您离开的这段时间，工匠们努力工作，收获了"
                for k,v in pairs(floatTable) do
                    if v > 0 then
                        local resname = produceCsv[k]["name"]
                        local resnum = v
                        showstr = showstr..resname.."+"..resnum
                        ToastUtil:downString(resname.."+"..resnum)
                    end
                end
                -- 没有离线资源的时候不加入空话
                if showstr ~= "在您离开的这段时间，工匠们努力工作，收获了" then
                    DataManager:getInstance():sendSystemInfo(showstr)
                end

            end
            
            DataManager:getInstance():setRoleData(roleLastTime, basestr, nil)
        end
    else
        -- 初始化
        DataManager:getInstance():setRoleData(roleLastTime, basestr, nil)
    end
    print("lasttime = "..basestr)
    -- 走过新手引导之后再弹出登陆礼包
    if GuideController:getInstance():getIsHaveStep(1) then
        -- -- 如果系统更新成功，那么现实7日登陆奖励
        local days = math.floor(basestr / 86400) -- 16541
        -- 根据存档判断时间是否合理，合理就弹7日奖励
        -- DataManager:getInstance():setRoleData(roleSevenDayBonus, 16541)
        local sevenData = DataManager:getInstance():getRoleData(roleSevenDayBonus)
        cclog("系统时间更新成功,最新的天数：%d 记录的天数：%d", days, sevenData)
        -- 如果当前天数减去开始的天数大于1天
        if days - sevenData % 1000000 >= 1 and math.floor(sevenData / 1000000) < 7 then
            -- 如果还没领过奖励，那么弹出alert窗
            NotificationNode:getInstance():runAction(cc.Sequence:create(cc.DelayTime:create(2.0), cc.CallFunc:create(function()
                -- body
                SevenDayBonusLayer:create()
            end)))
        end
    end
end

-- co = coroutine.create(function ()
--     print("sdasdasda")
--     for i = 1,10 do
--         print("co1111",i)
--         sleep(5)
--         update()
--         -- NotificationNode.lastUpdateTime = NotificationNode.lastUpdateTime + 1
        
--     end
--     coroutine.yield()
-- end)

function NotificationNode:create()
    local view = NotificationNode.new()
    if view and view:init() then
        return view
    end
    return nil
end

function NotificationNode:init()

    NotificationNode.lastUpdateTime = os.clock()

    local function update()
        -- print("lastUpdateTime = ",NotificationNode.lastUpdateTime)
        NotificationNode.lastUpdateTime = NotificationNode.lastUpdateTime + 1
        -- coroutine.resume(co)
        -- 判断是否有http返回状态，有就调用回调函数
        if self.buyStatus ~= 0 then
            require "LuaClass/DataManager"
            DataManager:getInstance():diamondStoreBuySomethingSuccess(self.buyStatus);
            self.buyStatus = 0
        end
    end

    local function updateLasttime()
        requestLastTime()
        local LastTime = DataManager:getInstance():getRoleData(roleLastTime)
        if LastTime ~= nil then
            LastTime = LastTime + 180
            DataManager:getInstance():setRoleData(roleLastTime, LastTime, nil)
        end
        -- coroutine.resume(co)
    end

    -- coroutine.resume(co)
    -- 开始一个轮询，每秒走一次，更新下方信息条上的信息
    NotificationNode.lastUpdateTime = os.time()
    -- print("nowtime = ", self.lastUpdateTime)
    NotificationNode.schduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(update, 1.0, false)
    -- 优先调用一下更新系统时间
    updateLasttime()
    cc.Director:getInstance():getScheduler():scheduleScriptFunc(updateLasttime, 180, false)

    -- requestLastTime()
    return true
end

function NotificationNode:getResource()
    -- body
    local nowTime = NotificationNode:getInstance():GetGameTime()
    local CDTime = DataManager:getInstance():getRoleData(roleResourceCD)
    local workerCsv = DataManager:getInstance():getCSVByID(csvOfWorker)
    local produceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
    local nextProduceTime = DataManager:getInstance():getRoleData(roleProduceTime)
    -- 定时收获资源数据
    schedule(self, function()
        -- print("资源更新倒计时＋＋＋＋＋", nextProduceTime, nowTime)
        local packData = DataManager:getInstance():getRoleData(rolePack)
        local workerData = DataManager:getInstance():getRoleData(roleProducerQueue)
        -- cclog("更新倒计时，一旦时间到了重置时间，且生产产品")
        if nextProduceTime - nowTime < 0 then
            CDTime = DataManager:getInstance():getRoleData(roleResourceCD)
            local packData = DataManager:getInstance():getRoleData(rolePack)
            -- 证明时间到了，不能继续愉快的玩耍了,存储时间
            nextProduceTime = nowTime + CDTime
            DataManager:getInstance():setRoleData(roleProduceTime, nextProduceTime, nil)
            -- 生产数据，循环遍历加入原始背包数据，并且飘字
            local floatTable = {}
            local coinNum = 0
            for i = 1, #workerData do
                local workerTable = workerData[i]
                if workerTable ~= nil then
                    local workerNumber = tonumber(workerTable[dataKeyNum])
                    local bIsCanAdd = true
                    local workerCsvData = workerCsv[workerTable[dataKeyID]]
                    local produceData = workerCsvData["produce"]
                    local resumeData = workerCsvData["resume"]
                    -- 一个一个的判断是否可以制作，不够就break，继续生产下一个单位
                    for k = 1, workerNumber do
                        if resumeData ~= nil then
                            -- 设置一个临时的表用来存储扣减数据
                            local tempData = {}
                            -- 先判断材料是否充足，不足不制造
                            for j = 1, #resumeData do
                                -- 如果数量不存在，证明这个没数据，继续找下一个，没有就算了
                                if resumeData[j][2] ~= nil then
                                    -- print("需要", resumeData[j][1], resumeData[j][2])
                                    local needNum = tonumber(resumeData[j][2])
                                    local num = packData[resumeData[j][1]]
                                    if resumeData[j][1] == "1001" then
                                        num = DataManager:getInstance():getRoleData(roleMoney) + coinNum
                                    end
                                    if num == nil then
                                        num = 0
                                    end
                                    if num < needNum then
                                        -- 如果背包里的道具数量不足扣的，那么停止生产
                                        bIsCanAdd = false
                                        -- 清理数据，防止扣减
                                        tempData = {}
                                        break
                                    end
                                    -- 记录需要扣减的内容
                                    tempData[resumeData[j][1]] = needNum
                                end
                            end
                            -- 扣减背包数量以及金币数量
                            for k, v in pairs(tempData) do
                                if k == "1001" then
                                    coinNum = coinNum - v
                                else
                                    packData[k] = packData[k] - v
                                end
                                -- 写入飘字数据
                                if floatTable[k] ~= nil then
                                    floatTable[k] = floatTable[k] - v
                                else
                                    floatTable[k] = -v
                                end
                            end
                        else
                            -- 没需求数据，不生产
                            bIsCanAdd = false
                        end

                        -- 如果数量足够生产，那么生产道具
                        if bIsCanAdd then
                            if produceData ~= nil then
                                for j = 1, #produceData do
                                    local resultNum = tonumber(produceData[j][2])
                                    -- 写入数据到背包,如果不是金币的话
                                    if produceData[j][1] == "1001" then
                                        coinNum = coinNum + resultNum
                                    else
                                        if packData[produceData[j][1]] ~= nil then
                                            -- 如果这条背包数据有，那么直接添加
                                            packData[produceData[j][1]] = packData[produceData[j][1]] + resultNum
                                        else
                                            -- 如果这条背包数据木有，那么直接赋值
                                            packData[produceData[j][1]] = resultNum
                                        end
                                    end
                                    -- 写入飘字数据
                                    if floatTable[produceData[j][1]] ~= nil then
                                        floatTable[produceData[j][1]] = floatTable[produceData[j][1]] + resultNum
                                    else
                                        floatTable[produceData[j][1]] = resultNum
                                    end
                                end
                            end
                        else
                            break
                        end
                    end
                end
            end
            -- 计算完毕之后操作一次金币，要不然每次操作都回卡，感谢祖祎提供bug反馈
            DataManager:getInstance():addCoin(coinNum)
            if not isEnterMap then
                 -- 最后循环飘字提示
                for k,v in pairs(floatTable) do
                    if v > 0 then
                        if k == "1001" then
                            ToastUtil:downString("金币+"..v)
                        else
                            if k == "1005" then
                                -- 如果产出给养的话，发通知更新数据
                                DataManager:getInstance():postEvent("breadBirth", nil)
                            end
                            ToastUtil:downString(produceCsv[k]["name"].."+"..v)
                        end
                    end
                end
            end
            
            -- 存储数据
            DataManager:getInstance():setRoleData(rolePack, packData, nil)
        end
        -- 最后更新nowTime
        nowTime = NotificationNode:getInstance():GetGameTime()
    end, 1.0)
end

function NotificationNode:registerChargeCallBack()
    -- 注册支付成功的回调
    local function kBuyBackFailed()
        -- body
        ToastUtil:downString("支付失败，请重试！")
    end

    -- 处理支付成功的各种回调
    -- DataManager:getInstance():registerEvent("kChargeSuccess1", "NotificationNode", function()
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kChargeSuccess1)))
    -- end)
    -- DataManager:getInstance():registerEvent("kChargeSuccess2", "NotificationNode", function()
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kChargeSuccess2)))
    -- end)
    -- DataManager:getInstance():registerEvent("kChargeSuccess3", "NotificationNode", function()
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kChargeSuccess3)))
    -- end)
    -- DataManager:getInstance():registerEvent("kChargeSuccess5", "NotificationNode", function()
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kChargeSuccess5)))
    -- end)
    -- DataManager:getInstance():registerEvent("kChargeSuccess6", "NotificationNode", function()
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kChargeSuccess6)))
    -- end)
    -- DataManager:getInstance():registerEvent("kChargeSuccess7", "NotificationNode", function()
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kChargeSuccess7)))
    -- end)
    -- DataManager:getInstance():registerEvent("kChargeSuccess8", "NotificationNode", function()
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kChargeSuccess8)))
    -- end)
    -- DataManager:getInstance():registerEvent("kChargeSuccess9", "NotificationNode", function()
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kChargeSuccess9)))
    -- end)
    -- DataManager:getInstance():registerEvent("kChargeSuccess10", "NotificationNode", function()
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kChargeSuccess10)))
    -- end)
    -- DataManager:getInstance():registerEvent("kChargeSuccess11", "NotificationNode", function()
    --     self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kChargeSuccess11)))
    -- end)
    DataManager:getInstance():registerEvent("kBuyBackFailed", "NotificationNode", function()
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(kBuyBackFailed)))
    end)

    
end

-- function NotificationNode:buySuccess(type)
--     DataManager:getInstance():diamondStoreBuySomethingSuccess(type)
-- end

function NotificationNode:GetGameTime()
    return NotificationNode.lastUpdateTime
end


function NotificationNode:registeventDispatcher()
    local listener1 = cc.EventListenerCustom:create("getLasttime",HTTPCallback_getLasttime)
    cc.Director:getInstance():getNotificationNode():getEventDispatcher():addEventListenerWithFixedPriority(listener1, 6)

    local listener2 = cc.EventListenerCustom:create("backtobefor",function()
        requestLastTime()
        -- 再次发送通知，告知其他界面系统返回了
        DataManager:getInstance():postEvent("kSystemBackToForward", nil)
    end)
    cc.Director:getInstance():getNotificationNode():getEventDispatcher():addEventListenerWithFixedPriority(listener2, 6)

    local listener3 = cc.EventListenerCustom:create("chargeSuccess", function(event)
        -- body
        -- local temp = event:getUserData()
        -- local newEvent = tolua.cast(event, "cc.EventCustom")
        print("temp", event._userdata)
        DataManager:getInstance():chargeSuccess(3, true)
    end)
    cc.Director:getInstance():getNotificationNode():getEventDispatcher():addEventListenerWithFixedPriority(listener3, 6)
end

function NotificationNode:visit()
    -- 这里不会被调用，暂时没影响
    CCNode:visit()
end



