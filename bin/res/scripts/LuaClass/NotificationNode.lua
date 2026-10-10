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
local LocalProduction = require "LuaClass/LocalProduction"

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

    -- Production is settled by the independent local ledger, never this event.
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

    -- coroutine.resume(co)
    -- 开始一个轮询，每秒走一次，更新下方信息条上的信息
    NotificationNode.lastUpdateTime = os.time()
    -- print("nowtime = ", self.lastUpdateTime)
    NotificationNode.schduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(update, 1.0, false)

    -- Keep server daily-reward checks independent from local production.
    requestLastTime()
    cc.Director:getInstance():getScheduler():scheduleScriptFunc(requestLastTime, 180, false)
    return true
end

-- Commit inventory, money, phase, and local wall anchor as one snapshot.
function NotificationNode:settleLocalProduction(checkpoint)
    local dm = DataManager:getInstance()
    local result = LocalProduction.calculate({
        now = os.time(), gameTime = self:GetGameTime(),
        ledger = dm:getRoleData(LocalProduction.KEY),
        nextTime = dm:getRoleData(roleProduceTime),
        cd = dm:getRoleData(roleResourceCD), cap = dm:getRoleData(roleOfflineBonusTime),
        pack = dm:getRoleData(rolePack), money = dm:getRoleData(roleMoney),
        workers = dm:getRoleData(roleProducerQueue), recipes = dm:getCSVByID(csvOfWorker),
        idKey = dataKeyID, numKey = dataKeyNum,
    })
    if not result or (not result.checkpoint and not checkpoint) then return end
    local fields = {
        [LocalProduction.KEY] = result.ledger,
        [roleProduceTime] = result.nextTime,
        [rolePack] = result.pack, [roleMoney] = result.money,
    }
    if not dm.__roleData:commitLocalProduction(fields) then
        -- No memory changes or notifications on failed writes. Retry next tick.
        return
    end
    -- Preserve the normal resource-triggered talent unlock checks, after the
    -- durable grant (a later observer save therefore contains the same ledger).
    local learned = dm:checkAutoLearnedTallent()
    for key, value in pairs(learned or {}) do
        if value ~= nil then dm:unlockTallentByKey(key) end
    end
    dm:postEvent(roleProduceTime, nil)
    dm:postEvent(rolePack, nil)
    dm:postEvent(roleMoney, nil)
    local csv = dm:getCSVByID(csvOfResourceInfo)
    for id, count in pairs(result.delta) do
        if count > 0 then
            if not isEnterMap then
                if id == "1005" then dm:postEvent("breadBirth", nil) end
                local name = id == "1001" and "金币" or (csv[id] and csv[id].name)
                if name then ToastUtil:productionString(name .. "+" .. count) end
            end
        end
    end
end

function NotificationNode:getResource()
    if self.localProductionStarted then return end
    self.localProductionStarted = true
    self:settleLocalProduction(true)
    schedule(self, function() self:settleLocalProduction() end, 1.0)
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
        if self.localProductionStarted then self:settleLocalProduction(true) end
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



