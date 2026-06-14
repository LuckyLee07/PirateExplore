require "LuaClass/Header"
require "LuaClass/MainMenu"
require "LuaClass/Talent"
require "LuaClass/Expedition"
require "LuaClass/Repository"
require "LuaClass/Resource"
require "LuaClass/RandomEventMode"
require "LuaClass/GuideController"


Dispatch = class("Dispatch", function ()
    return cc.Layer:create()
end)

Dispatch.__index = Dispatch
Dispatch.BaseNode = nil
Dispatch.rightNode = nil
Dispatch.leftNode = nil
Dispatch.rightNodeStack = {}
Dispatch.lastPos = cc.p(0, 0)
Dispatch.bIsMoveToOther = false
-- Dispatch.lastLeftNode = nil
-- Dispatch.lastRightNode = nil
-- Dispatch.pageIndex = 0
Dispatch.mainMenu = nil
Dispatch.bIsMoving = false
Dispatch.talent = nil
Dispatch.expedition = nil
Dispatch.repository = nil
Dispatch.resource = nil
Dispatch.aniTime = 0.0

function Dispatch:create(bIsDead)
    local view = Dispatch.new()
    if view and view:init(bIsDead) then
        zqDispatch = view
        return view
    end
    return nil
end

-- 清理函数
function Dispatch:destory()
    if self ~= nil then
        if self:getParent() ~= nil then
            cclog("Dispatch:我自由了！")
            if self.rightNode ~= nil then
                self.rightNode:destory()
                self.rightNode = nil
            end
            -- if self.lastRightNode ~= nil then
            --     self.lastRightNode:destory()
            --     self.lastRightNode = nil
            -- end
            -- self.talent:destory()
            -- self.expedition:destory()
            -- self.repository:destory()
            -- self.resource:destory()
            self.mainMenu:destory()
            self:removeFromParent()
        end
        zqDispatch = nil
        pNeedUpdateLayer = nil
        -- 注销event
        DataManager:getInstance():unregisterEvent(roleGuideStep, "Dispatch")
    end
end

-- 主函数
function Dispatch:init(bIsDead)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- 添加主界面层
    self.mainMenu = MainMenuLayer:create()
    self:addChild(self.mainMenu, 9999)

    -- 最后添加承载中间view的节点
    self.BaseNode = cc.Node:create()
    self.BaseNode:setPosition(0, 0)
    self:addChild(self.BaseNode)

    -- 依次贴好三个界面
    -- self.talent = TalentLayer:create()
    -- self.talent:setPosition(cc.p(-visibleSize.width * 2, 0))
    -- self.BaseNode:addChild(self.talent)

    -- self.expedition = ExpeditionLayer:create()
    -- self.expedition:setPosition(cc.p(-visibleSize.width, 0))
    -- self.BaseNode:addChild(self.expedition)

    -- self.repository = RepositoryLayer:create()
    -- self.repository:setPosition(cc.p(0, 0))
    -- self.BaseNode:addChild(self.repository)
    -- self.repository:setIsReload(true)

    -- self.resource = ResourceLayer:create()
    -- self.resource:setPosition(cc.p(visibleSize.width, 0))
    -- self.BaseNode:addChild(self.resource)
    -- self:setViewWithDirection(self.resource, false, 1)

    -- 注册touch事件
    -- local touchBeginPoint = nil
    -- local function onTouchBegan(touch, event)
    --     local location = touch:getLocation()
    --     -- cclog("onTouchBegan: %0.2f, %0.2f", location.x, location.y)
    --     touchBeginPoint = location
    --     -- {x = location.x, y = location.y}
    --     -- CCTOUCHBEGAN event must return true
    --     return true
    -- end

    -- local function onTouchMoved(touch, event)
    --     -- local location = touch:getLocation()
    --     -- cclog("onTouchMoved: %0.2f, %0.2f", location.x, location.y)
    --     -- if touchBeginPoint then
    --     --     local cx, cy = BaseNode:getPosition()
    --     --     BaseNode:setPosition(cx + location.x - touchBeginPoint.x, BaseNode:getPositionY())
    --     --     touchBeginPoint = {x = location.x, y = location.y}
    --     -- end
    -- end

    -- local function onTouchEnded(touch, event)
    --     local location = touch:getLocation()
    --     if touchBeginPoint == nil then
    --         return
    --     end
    --     if not self.bIsMoving then
    --         -- cclog("onTouchEnded: %0.2f, %0.2f", location.x, location.y)
    --         -- 计算斜率以及移动方向
    --         local slope = (location.y - touchBeginPoint.y) / (location.x - touchBeginPoint.x)
    --         local distanceX = location.x - touchBeginPoint.x
    --         -- cclog("slope:%f", slope)
    --         -- 首先判断斜率是否符合触发条件
    --         if slope < 0.5 and slope > -0.5 then
    --             -- 符合的话再判断移动的距离是否大于指定数值
    --             if cc.pGetDistance(location, touchBeginPoint) > 60 then
    --                 self.repository:setIsReload(false)
    --                 if distanceX > 0 then
    --                     -- cclog("触发手指向右滑动的翻页事件")
    --                     if self.bIsMoveToOther then
    --                         self:moveToMain(true)
    --                     else
    --                         if self.pageIndex == 1 then
    --                             self:moveToTalent()
    --                         elseif self.pageIndex == 2 then
    --                             self:moveToExpedition()
    --                         elseif self.pageIndex == 3 then
    --                             self:moveToRepository()
    --                         end
    --                     end
    --                 else
    --                     -- cclog("触发手指向左滑动的翻页事件")
    --                     if self.pageIndex == 2 then
    --                         self:moveToResource()
    --                     elseif self.pageIndex == 1 then
    --                         self:moveToRepository()
    --                     elseif self.pageIndex == 0 then
    --                         self:moveToExpedition()
    --                     end
    --                 end 
    --             end
    --         end
    --         touchBeginPoint = nil
    --     end
    -- end

    -- local listener = cc.EventListenerTouchOneByOne:create()
    -- listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    -- listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    -- listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    -- local eventDispatcher = self.BaseNode:getEventDispatcher()
    -- eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.BaseNode)

    -- 随机事件
    local randomLayer = RandomEventLayer:create()
    self:addChild(randomLayer)

    -- 设置仓库为接受信息的主界面
    -- self:setUpdateSystemInfoLayer(self.repository)

    self:moveToRepository()

    -- 设置点点选中仓库
    -- self.mainMenu:setPointWithIndex(3, 4)

    -- 初始化一下GuideController,为了让界面显示正常
    GuideController:getInstance()

    DataManager:getInstance():registerEvent(roleGuideStep, "Dispatch", function()
        -- body
        -- if self.mainMenu ~= nil then
        --     self.mainMenu:setPointWithIndex(self.pageIndex + 1, 4)
        -- end
    end)

    return true
end

-- 移动到天赋界面
function Dispatch:moveToTalent()
    self:setViewWithDirection(TalentLayer:create(), true, 1)
    -- 进入的时候清理红点
    GuideController:getInstance():addStep(401, true)
    -- 如果正在移动中，那么禁止移动
    -- if self.bIsMoving then
    --     return
    -- end
    -- if self.bIsMoveToOther then
    --     -- print("先回到主界面moveToTalent")
    --     self:moveToMain(false)
    -- end
    -- -- 补偿，防止右侧没显示
    -- self:setRightViewVisible(true)
    -- if nil ~= self.BaseNode then
    --     self.pageIndex = 0
    --     local function cleanUp()
    --         self.bIsMoving = false
    --     end
    --     local visibleSize = cc.Director:getInstance():getVisibleSize()
    --     self.BaseNode:stopAllActions()
    --     self.lastPos = cc.p(visibleSize.width * 2, self.BaseNode:getPositionY())
    --     local actions = {cc.EaseExponentialOut:create(cc.MoveTo:create(self.aniTime, self.lastPos)), cc.DelayTime:create(self.aniTime), cc.CallFunc:create(cleanUp)}
    --     self.BaseNode:runAction(cc.Sequence:create(unpack(actions)))

    --     self:setUpdateSystemInfoLayer(self.talent)

    --     -- if self.mainMenu ~= nil then
    --     --     -- 移动点点
    --     --     self.mainMenu:setPointWithIndex(1, 4)
    --     -- end

    --     -- 进入的时候清理红点
    --     GuideController:getInstance():addStep(401, true)
    -- end
end

-- 移动到远征界面
function Dispatch:moveToExpedition()
    -- 进入之后触发清理出征红点的操作
    GuideController:getInstance():addStep(6, true)
    -- 加载出征界面
    self:setViewWithDirection(ExpeditionLayer:create(), true, 1)
    self.mainMenu:activeButtonWithIndex(1)
    -- 如果正在移动中，那么禁止移动
    -- if self.bIsMoving then
    --     return
    -- end
    -- -- 判断步骤是否已经解锁船坞
    -- if not GuideController:getInstance():getIsHaveStep(8) then
    --     return
    -- end
    -- GuideController:getInstance():addStep(6, true)
    -- if self.bIsMoveToOther then
    --     -- print("先回到主界面moveToExpedition")
    --     self:moveToMain(false)
    -- end
    -- -- 补偿，防止右侧没显示
    -- self:setRightViewVisible(true)
    -- if nil ~= self.BaseNode then
    --     self.pageIndex = 1
    --     local function cleanUp()
    --         self.bIsMoving = false
    --     end
    --     self.BaseNode:stopAllActions()
    --     local visibleSize = cc.Director:getInstance():getVisibleSize()
    --     self.lastPos = cc.p(visibleSize.width, self.BaseNode:getPositionY())
    --     local actions = {cc.EaseExponentialOut:create(cc.MoveTo:create(self.aniTime, self.lastPos)), cc.DelayTime:create(self.aniTime), cc.CallFunc:create(cleanUp)}
    --     self.BaseNode:runAction(cc.Sequence:create(unpack(actions)))
    --     -- 如果按钮组存在，那么移动它
    --     -- if self.mainMenu ~= nil then
    --         -- self.mainMenu.MainMenuButtonGroup:stopAllActions()
    --         -- self.mainMenu.MainMenuButtonGroup:runAction(cc.EaseExponentialOut:create(cc.MoveTo:create(0.3, cc.p(0, self.BaseNode:getPositionY()))))
    --         -- 移动点点
    --     --     self.mainMenu:setPointWithIndex(2, 4)
    --     -- end

    --     self:setUpdateSystemInfoLayer(self.expedition)
    --     -- 最后重新设置UI
    --     self.expedition:resetUI()
    -- end
end

-- 移动到仓库界面
function Dispatch:moveToRepository()
    self:setViewWithDirection(RepositoryLayer:create(), true, 1)
    self.mainMenu:activeButtonWithIndex(4)
    -- 如果正在移动中，那么禁止移动
    -- if self.bIsMoving then
    --     return
    -- end
    -- if self.bIsMoveToOther then
    --     -- print("先回到主界面moveToRepository")
    --     self:moveToMain(false)
    -- end
    -- -- 补偿，防止右侧没显示
    -- self:setRightViewVisible(true)
    -- if nil ~= self.BaseNode then
    --     local function cleanUp()
    --         self.bIsMoving = false
    --     end
    --     local visibleSize = cc.Director:getInstance():getVisibleSize()
    --     self.BaseNode:stopAllActions()
    --     self.lastPos = cc.p(0, self.BaseNode:getPositionY())
    --     local actions = {cc.EaseExponentialOut:create(cc.MoveTo:create(self.aniTime, self.lastPos)), cc.DelayTime:create(self.aniTime), cc.CallFunc:create(cleanUp)}
    --     self.BaseNode:runAction(cc.Sequence:create(unpack(actions)))
    --     -- if self.rightNode ~= nil then
    --     --     self.rightNode:removeFromParent()
    --     --     self.rightNode = nil
    --     -- end
    --     -- 判断之前的界面是否是从哪个方向回来的重新设置界面
    --     if self.pageIndex == 1 then
    --         -- if self.lastLeftNode ~= nil then
    --         --     self:setViewWithDirection(self.lastLeftNode, false, 0)
    --         -- end
    --     elseif self.pageIndex == 3 then
    --         self:emptyRightNodeStack()
    --     end
    --     self.pageIndex = 2
    --     -- 如果按钮组存在，那么移动它
    --     if self.mainMenu ~= nil then
    --         -- self.mainMenu.MainMenuButtonGroup:stopAllActions()
    --         -- self.mainMenu.MainMenuButtonGroup:runAction(cc.EaseExponentialOut:create(cc.MoveTo:create(0.3, cc.p(0, self.BaseNode:getPositionY()))))
    --         -- 移动点点
    --         self.mainMenu:setPointWithIndex(3, 4)
    --     end
    --     -- 刷新一下自己的数据
    --     self.repository:reloadData()
    --     -- 设置仓库自动刷新
    --     self.repository:setIsReload(true)
    --     -- 设置系统信息更新节点为仓库
    --     self:setUpdateSystemInfoLayer(self.repository)
    -- end
end

-- 移动到资源界面
function Dispatch:moveToResource()
    cclog("***************移动到资源界面**************")
    -- 进入之后清理资源界面的红点
    GuideController:getInstance():addStep(5, true)
    -- 加载资源界面
    local resources = ResourceLayer:create()
    self:setViewWithDirection(resources, true, 1)
    -- 检查是否有刚刚解锁的，播放动画
    resources:checkIsHaveNewUnlock()
    self.mainMenu:activeButtonWithIndex(6)

    -- -- 如果正在移动中，那么禁止移动
    -- if self.bIsMoving then
    --     return
    -- end
    -- -- 判断步骤是否已经解锁
    -- if not GuideController:getInstance():getIsHaveStep(2) then
    --     return
    -- end
    -- GuideController:getInstance():addStep(5, true)
    -- if self.bIsMoveToOther then
    --     -- print("先回到主界面moveToResource")
    --     self:moveToMain(false)
    -- end
    -- -- 补偿，防止右侧没显示
    -- self:setRightViewVisible(true)
    -- local function cleanUp()
    --     self.bIsMoving = false
    -- end
    -- if nil ~= self.BaseNode then
    --     local visibleSize = cc.Director:getInstance():getVisibleSize()
    --     self.pageIndex = 3
    --     self.BaseNode:stopAllActions()
    --     self.lastPos = cc.p(-visibleSize.width, self.BaseNode:getPositionY())
    --     local actions = {cc.EaseExponentialOut:create(cc.MoveTo:create(self.aniTime, self.lastPos)), cc.DelayTime:create(self.aniTime), cc.CallFunc:create(cleanUp)}
    --     self.BaseNode:runAction(cc.Sequence:create(unpack(actions)))

    --     self:setUpdateSystemInfoLayer(self.resource)
    --     -- 检查是否有刚刚解锁的，播放动画
    --     self.resource:checkIsHaveNewUnlock()
    -- end

    -- if self.mainMenu ~= nil then
    --     -- 移动点点
    --     self.mainMenu:setPointWithIndex(4, 4)
    -- end
end

-- 移动到4个主界面中的一个
function Dispatch:moveToMain(bIsNeedAnimation)
    if bIsNeedAnimation == nil then
        bIsNeedAnimation = true
    end
    -- 如果正在移动中，那么禁止移动
    if self.bIsMoving then
        return
    end
    -- cclog("!!!!!!moveToMain!!!!!!!!")
    local function cleanUp()
        -- 移动完毕后清空所有数据
        self:emptyRightNodeStack()
        -- 显示当前界面右侧界面
        self:setRightViewVisible(true)
        self.bIsMoveToOther = false
        self.bIsMoving = false
    end

    if nil ~= self.BaseNode then
        local visibleSize = cc.Director:getInstance():getVisibleSize()
        self.BaseNode:stopAllActions()
        if bIsNeedAnimation then
            local actions = {cc.EaseExponentialOut:create(cc.MoveTo:create(self.aniTime, self.lastPos)), cc.DelayTime:create(self.aniTime), cc.CallFunc:create(cleanUp)}
            self.BaseNode:runAction(cc.Sequence:create(unpack(actions)))
        else
            self.BaseNode:setPosition(self.lastPos)
            cleanUp()
        end
        
        -- if self.rightNode ~= nil then
        --     self.rightNode:removeFromParent()
        --     self.rightNode = nil
        -- end
        
        -- 如果按钮组存在，那么移动它
        -- if self.mainMenu ~= nil then
        --     self.mainMenu.MainMenuButtonGroup:stopAllActions()
        --     self.mainMenu.MainMenuButtonGroup:runAction(cc.EaseExponentialOut:create(cc.MoveTo:create(0.3, cc.p(0, self.BaseNode:getPositionY()))))
        -- end
        -- 刷新跟新手引导有关的内容
        self.mainMenu:playUnlockAni()
        -- 提前调用一下右侧界面的销毁方法，否则有些内容不提前销毁会有问题
        if self.rightNode ~= nil then
            self.rightNode:viewWillDestory()
        end

        if self.pageIndex == 0 then
            self:setUpdateSystemInfoLayer(self.talent)
        elseif self.pageIndex == 1 then
            self:setUpdateSystemInfoLayer(self.expedition)
            -- 最后重新设置UI
            self.expedition:resetUI()
        elseif self.pageIndex == 2 then
            self:setUpdateSystemInfoLayer(self.repository)
            -- 最后刷新UI
            self.repository:reloadData()
            self.repository:setIsReload(true)
        elseif self.pageIndex == 3 then
            self:setUpdateSystemInfoLayer(self.resource)
            -- 检查是否有刚刚解锁的，播放动画
            self.resource:checkIsHaveNewUnlock()
        end
    end
end

function Dispatch:setUpdateSystemInfoLayer(view)
    -- 重新指定刷新数据的界面
    if view ~= nil then
        pNeedUpdateLayer = view
        view:updateInfoLabel(DataManager:getInstance():getSystemInfoString())
    end
end

function Dispatch:backToLastView()
    -- 根据mainmenu的pageindex移动界面
    if self.mainMenu == nil then
        return
    end
    local index = self.mainMenu:getSelectedIndex()
    if index == 1 then
        self:moveToExpedition()
    elseif index == 2 then
        self:gotoTrain()
    elseif index == 3 then
        self:gotoBuild()
    elseif index == 5 then
        self:gotoMake()
    elseif index == 6 then
        self:moveToResource()
    elseif index == 7 then
        self:gotoStore()
    else
        self:moveToRepository()
    end
end

--[[
 重新设置右侧界面
 view：要设置的层
 bIsMove：是否需要播放移动动画
 direction：移动方向，0是左，1是右
]]
function Dispatch:setViewWithDirection(view, bIsMove, direction)
    if self.rightNode ~= nil then
        self.rightNode:viewWillDestory()
        self.rightNode:destory()
        self.rightNode:removeFromParent()
        self.rightNode = nil
    end
    self.rightNode = view
    self.rightNode:setPosition(cc.p(0, 0))
    self.BaseNode:addChild(self.rightNode)
    self:setUpdateSystemInfoLayer(self.rightNode)

    -- -- 如果正在移动中，那么禁止移动
    -- if self.bIsMoving then
    --     return;
    -- end
    -- self.bIsMoveToOther = true
    -- local visibleSize = cc.Director:getInstance():getVisibleSize()
    -- -- 根据左右方向设置页面
    -- if direction == 0 then
    --     -- 向左移动，先删除之前view上的所有节点
    --     -- if nil ~= self.leftNode then
    --     --     self.lastLeftNode = self.leftNode
    --     --     self.lastLeftNode:setPosition(cc.p(0, 0))
    --     -- end
    --     -- -- 然后加载新的节点
    --     -- self.leftNode = view
    --     -- self.leftNode:setPosition(cc.p(-visibleSize.width, 0))
    --     -- if self.leftNode:getParent() == nil then
    --     --     self.BaseNode:addChild(self.leftNode)
    --     -- end
    -- else
    --     -- 向右移动，先删除之前view上的所有节点
    --     if nil ~= self.rightNode then
    --         self:pushRightNodeStack(self.rightNode)
    --         self.rightNode = nil
    --     end
    --     -- 然后加载新的节点
    --     self.rightNode = view
    --     self.rightNode:setPosition(cc.p(-visibleSize.width * 2 + visibleSize.width * (1 + self.pageIndex), self.BaseNode:getPositionY()))
    --     -- if self.rightNode:getParent() == nil then
    --     self.BaseNode:addChild(self.rightNode, 9999)
    --     -- end
    --     -- 隐藏当前界面右侧界面
    --     self:setRightViewVisible(false)
    --     self:setUpdateSystemInfoLayer(view)
    -- end
    -- -- 清理移动锁的函数
    -- local function cleanUp()
    --     self.bIsMoving = false
    -- end
    -- -- 如果需要移动
    -- if bIsMove then
    --     if direction == 0 then
    --         -- 首先移动主界面
    --         -- self.bIsMoving = true
    --         -- -- self.pageIndex = 1
    --         -- self.BaseNode:stopAllActions()
    --         -- self.BaseNode:setPosition(cc.p(self.lastPos.x, self.BaseNode:getPositionY()))
    --         -- local actions = {cc.EaseExponentialOut:create(cc.MoveTo:create(0.3, cc.p(self.lastPos.x + visibleSize.width, self.BaseNode:getPositionY()))), cc.DelayTime:create(0.3), cc.CallFunc:create(cleanUp)}
    --         -- self.BaseNode:runAction(cc.Sequence:create(unpack(actions)))

    --         -- -- 如果按钮组存在，那么移动它
    --         -- if self.mainMenu ~= nil then
    --         --     self.mainMenu.MainMenuButtonGroup:stopAllActions()
    --         --     self.mainMenu.MainMenuButtonGroup:runAction(cc.EaseExponentialOut:create(cc.MoveTo:create(0.3, cc.p(visibleSize.width, self.BaseNode:getPositionY()))))
    --         -- end
    --     else
    --         -- 关闭仓库界面自动刷新
    --         self.repository:setIsReload(false)
    --         -- 向右移动首先移动主界面
    --         self.bIsMoving = true
    --         -- self.pageIndex = 3
    --         self.BaseNode:stopAllActions()
    --         self.BaseNode:setPosition(cc.p(self.lastPos.x, self.BaseNode:getPositionY()))
    --         local actions = {cc.EaseExponentialOut:create(cc.MoveTo:create(self.aniTime, cc.p(self.lastPos.x - visibleSize.width, self.BaseNode:getPositionY()))), cc.DelayTime:create(self.aniTime), cc.CallFunc:create(cleanUp)}
    --         self.BaseNode:runAction(cc.Sequence:create(unpack(actions)))

    --         -- 如果按钮组存在，那么移动它
    --         -- if self.mainMenu ~= nil then
    --         --     self.mainMenu.MainMenuButtonGroup:stopAllActions()
    --         --     self.mainMenu.MainMenuButtonGroup:runAction(cc.EaseExponentialOut:create(cc.MoveTo:create(0.3, cc.p(-visibleSize.width, self.BaseNode:getPositionY()))))
    --         -- end
    --     end
    -- else
    --     cclog("走了销毁方法")
    --     if direction == 0 then
    --         -- if self.lastLeftNode ~= nil then
    --         --     self.lastLeftNode:destory()
    --         --     self.lastLeftNode:removeFromParent()
    --         --     self.lastLeftNode = nil
    --         -- end
    --     else
    --         -- if self:getRightNodeStackIsEmpty() then
    --         --     self:popRightNodeStack()
    --         -- end
    --     end
    -- end
end

-- 右侧界面压栈处理
function Dispatch:pushRightNodeStack(view)
    if view ~= nil then
        local visibleSize = cc.Director:getInstance():getVisibleSize()
        view:setPosition(cc.p(self.lastPos.x + visibleSize.width, 0))
        view:setVisible(false)
        table.insert(self.rightNodeStack, view)
    end
end

-- 右侧界面出栈处理
function Dispatch:popRightNodeStack()
    -- 从栈顶取出数据来
    local view = self.rightNodeStack[#self.rightNodeStack]
    if view ~= nil then
        print("view:", view)
        if view:getParent() ~= nil then
            self.rightNode:destory()
            self.rightNode:removeFromParent()
            self.rightNode = nil
            view:setVisible(true)
            self:setViewWithDirection(view, false, 1)
        end
        table.remove(self.rightNodeStack, #self.rightNodeStack)
    end
end

-- 清空右侧栈
function Dispatch:emptyRightNodeStack()
    -- 逆向遍历删除栈数据
    -- print("总数据长度", #self.rightNodeStack)
    for i = #self.rightNodeStack, 1, -1 do
        -- print("开始删除界面:", i)
        local view = self.rightNodeStack[i]
        if view ~= nil then
            if view:getParent() ~= nil then
                view:destory()
                view:removeFromParent()
            end
            table.remove(self.rightNodeStack, i)
        end
    end
    -- 清理最后的rightNode
    if self.rightNode ~= nil then
        self.rightNode:destory()
        self.rightNode:removeFromParent()
        self.rightNode = nil
    end
end

-- 判断右侧栈是否为空
function Dispatch:getRightNodeStackIsEmpty()
    if #self.rightNodeStack > 0 then
        return true
    end
    return false
end

-- 设置当前基本页面右侧的页面隐藏，以防止点穿bug
function Dispatch:setRightViewVisible(bIsShow)
    -- print("设置右侧界面隐藏或显示：", bIsShow)
    if self.pageIndex == 0 then
        self.expedition:setVisible(bIsShow)
    elseif self.pageIndex == 1 then
        self.repository:setVisible(bIsShow)
    elseif self.pageIndex == 2 then
        self.resource:setVisible(bIsShow)
    else
        -- 其他情况不用处理的说
    end
end

-- 移动到战斗界面
function Dispatch:moveToFightLayer()

    gotoMap()

--    if nil ~= self.BaseNode then
--        local visibleSize = cc.Director:getInstance():getVisibleSize()
--        self.BaseNode:runAction(cc.EaseExponentialOut:create(cc.MoveTo:create(0.3, cc.p(0, self.BaseNode:getPositionY()))))
--        -- 判断之前的界面是否是从右侧回来的重新设置界面
--        self:setRightView(FightLayer:create(), false)
--        self.pageIndex = 0
    --        -- 如果按钮组存在，那么移动它
    --        if self.mainMenu ~= nil then
    --            self.mainMenu.MainMenuButtonGroup:runAction(cc.EaseExponentialOut:create(cc.MoveTo:create(0.3, cc.p(0, self.BaseNode:getPositionY()))))
    --        end
    --    end
end

--[[
    各种跳转函数开始了~
]]

-- 跳转到建造模块
function Dispatch:gotoBuild()
    require "LuaClass/BuildMode"
    self:setViewWithDirection(BuildLayer:create(), true, 1)
end

-- 跳转到建造模块
function Dispatch:gotoMake()
    require "LuaClass/MakeMode"
    self:setViewWithDirection(MakeLayer:create(), true, 1)
end

-- 跳转到建造模块
function Dispatch:gotoTrain()
    require "LuaClass/TrainMode"
    self:setViewWithDirection(TrainLayer:create(), true, 1)
end

-- 跳转到建造模块
function Dispatch:gotoStore(bIsMoveToBottom)
    if bIsMoveToBottom == nil then
        bIsMoveToBottom = false
    end
    require "LuaClass/StoreMode"
    self:setViewWithDirection(StoreLayer:create(bIsMoveToBottom), true, 1)
    self.mainMenu:activeButtonWithIndex(7)
end

-- 移动到天赋模块
function Dispatch:gotoTalent()
    self:moveToTalent()
end

-- 移动到成就模块
function Dispatch:gotoAchievement()
    require "LuaClass/Achievement"
    self:setViewWithDirection(AchievementLayer:create(), true, 1)
end

-- 移动到设置模块
function Dispatch:gotoSetting()
    require "LuaClass/Setting"
    self:setViewWithDirection(SettingLayer:create(), true, 1)
end

-- 移动到排行榜模块
function Dispatch:gotoRanking()
    require "LuaClass/Ranking"
    self:setViewWithDirection(RankingLayer:create(), true, 1)
end

-- 移动到钻石商城模块
function Dispatch:gotoDiamondStore()
    require "LuaClass/DiamondStore"
    self:setViewWithDirection(DiamondStore:create(), true, 1)
end