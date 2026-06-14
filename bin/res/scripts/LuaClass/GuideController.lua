require "LuaClass/Header"
require "LuaClass/DataManager"


GuideController = {}
GuideController.__index = GuideController
GuideController.step = ""
GuideController.instance = nil

function GuideController:new()  
    local self = {}  
    setmetatable(self, GuideController)  
    return self  
end  
  
function GuideController:getInstance()  
    if nil == self.instance then
        self.instance = self:new()
        self.instance:init()
    end
    return self.instance
end

-- 清理函数
function GuideController:destory()

end

-- 初始化函数
function GuideController:init()
    cclog("GuideController诞生了")
    self.step = DataManager:getInstance():getRoleData(roleGuideStep)
    -- cclog("初始化后的新手引导步骤：", self.step)
    -- 初始化的时候发送通知，告诉各个地方刷新显示，暂时注释，先不显示 by 杨杰
    -- DataManager:getInstance():postEvent(roleGuideStep, nil)
end

-- 触发函数
function GuideController:addStep(step, bIsRedPoint)
    -- 如果传进来的步数等于当前步数，那么解锁响应的步骤
    -- cclog("存档的数据结构：", self.step)
    local fixedStep = self:fixStep(step)
    if bIsRedPoint then
        fixedStep = "r"..fixedStep
    else
        fixedStep = "s"..fixedStep
    end
    if string.find(self.step, fixedStep) == nil then
        if self.step == "" then
            self.step = self.step..fixedStep
        else
            self.step = self.step.."_"..fixedStep
        end
        
        -- if step - 1 > 0 then

        --     local recordTips = string.format("新手引导第%d步",step - 1)

        --     -- TDGAMission:onCompleted(recordTips)
        --     -- ToastUtil:toastString(recordTips)

        -- end


        -- local recordTips = string.format("新手引导第%d步",step)

        -- TDGAMission:onBegin(recordTips)

        -- print("GuideController:setStep更新新手引导步骤：", step)
        -- ToastUtil:toastString(recordTips)
        DataManager:getInstance():setRoleData(roleGuideStep, self.step, nil)

    end

end

-- 取得当前引导步数的函数
function GuideController:getIsHaveStep(step, bIsRedPoint)
    local fixedStep = self:fixStep(step)
    if bIsRedPoint then
        fixedStep = "r"..fixedStep
    else
        fixedStep = "s"..fixedStep
    end
    if string.find(self.step, fixedStep) == nil then
        return false
    end
    return true
end

-- 删除指定的权限的函数
function GuideController:removeStep(step, bIsRedPoint)
    local fixedStep = self:fixStep(step)
    if bIsRedPoint then
        fixedStep = "r"..fixedStep
    else
        fixedStep = "s"..fixedStep
    end
    local s, e = 1, string.len(self.step)
    if string.find(self.step, "_"..fixedStep) == nil then
        if string.find(self.step, fixedStep.."_") ~= nil then
            -- 获得开始和结束的位置
            s, e = string.find(self.step, fixedStep.."_")
        else
            -- 如果都找不到就不要找了，表浪费时间
            return
        end
    else
        -- 获得开始和结束的位置
        s, e = string.find(self.step, "_"..fixedStep)
    end
    -- 开始重新合并字符串
    local tempFront = string.sub(self.step, 1, s - 1)
    self.step = tempFront .. string.sub(self.step, e + 1, string.len(self.step))
    -- 存档
    DataManager:getInstance():setRoleData(roleGuideStep, self.step, nil)
end

-- 将传进来的值转换成N位的函数
function GuideController:fixStep(step)
    if type(step) == "string" then
        step = tonumber(step)
    end
    if step < 10 then
        return "00"..step
    elseif step < 100 then
        return "0"..step
    elseif step < 1000 then
        return ""..step
    else
        return "e"..step
    end
end

-- 给按钮增加小红点
function GuideController:addRedPoint(node)
    if node ~= nil then
        -- 如果之前加过了，那么直接返回
        local lastRedPoint = node:getChildByTag(9527)
        if lastRedPoint == nil then
            local redPoint = cc.Sprite:create("Images/UI/RedPoint.png")
            redPoint:setPosition(cc.p(node:getContentSize().width - redPoint:getContentSize().width * 0.5, node:getContentSize().height - redPoint:getContentSize().height * 0.5))
            redPoint:setTag(9527)
            node:addChild(redPoint, 9999999)
        else
            return
        end
    end
end

-- 去掉按钮上的小红点
function GuideController:removeRedPoint(node)
    if node ~= nil then
        local lastRedPoint = node:getChildByTag(9527)
        if lastRedPoint ~= nil then
            lastRedPoint:removeFromParent()
        end
    end
end

-- bit = {data32 = {}}
-- for i = 1, 32 do
--     bit.data32[i] = 2 ^ (32 - i)
-- end
  
-- function bit:d2b(arg)
--     local tr = {}
--     for i = 1, 32 do
--         if arg >= self.data32[i] then
--             tr[i] = 1
--             arg = arg - self.data32[i]
--         else
--             tr[i]=0
--         end
--     end
--     return tr
-- end   --bit:d2b
  
-- function bit:b2d(arg)
--     local nr = 0
--     for i = 1, 32 do
--         if arg[i] == 1 then
--             nr = nr + 2 ^ (32 - i)
--         end
--     end
--     return nr
-- end   --bit:b2d
  
-- function bit:_xor(a,b)
--     local op1=self:d2b(a)
--     local op2=self:d2b(b)
--     local r={}
--     for i=1,32 do
--         if op1[i]==op2[i] then
--             r[i]=0
--         else
--             r[i]=1
--         end
--     end
--     return self:b2d(r)
-- end --bit:xor  
  
-- function bit:_and(a, b)
--     local op1 = self:d2b(a)
--     local op2 = self:d2b(b)
--     local r = {}
--     for i = 1, 32 do
--         if op1[i] == 1 and op2[i] == 1  then
--             r[i] = 1
--         else
--             r[i] = 0
--         end
--     end
--     return self:b2d(r)
-- end --bit:_and
  
-- function bit:_or(a, b)
--     local op1 = self:d2b(a)
--     local op2 = self:d2b(b)
--     local r = {}
--     for i = 1, 32 do
--         if  op1[i] == 1 or op2[i] == 1 then
--             r[i] = 1
--         else
--             r[i] = 0
--         end
--     end
--     return self:b2d(r)
-- end --bit:_or  
  
-- function bit:_not(a)
--     local op1 = self:d2b(a)
--     local r = {}
--     for i = 1, 32 do
--         if op1[i] == 1 then
--             r[i] = 0
--         else
--             r[i] = 1
--         end
--     end
--     return self:b2d(r)
-- end --bit:_not  
  
-- function bit:_rshift(a, n)
--     local op1 = self:d2b(a)
--     local r = self:d2b(0)
--     if n < 32 and n > 0 then
--         for i = 1, n do
--             for i = 31, 1, -1 do
--                 op1[i + 1] = op1[i]
--             end
--             op1[1] = 0
--         end
--         r = op1
--     end
--     return self:b2d(r)
-- end --bit:_rshift  
  
-- function bit:_lshift(a, n)
--     local op1 = self:d2b(a)
--     local r = self:d2b(0)
      
--     if n < 32 and n > 0 then
--         for i = 1, n do
--             for i = 1, 31 do
--                 op1[i] = op1[i + 1]
--             end
--             op1[32] = 0
--         end
--         r = op1
--     end
--     return self:b2d(r)
-- end --bit:_lshift

-- function bit:print(ta)
--     local sr = ""
--     for i = 1, 32 do
--         sr = sr .. ta[i]
--     end
--     print(sr)
-- end