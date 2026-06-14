require "LuaClass/Header"
require "LuaClass/UIKit"
require "LuaClass/DataManager"
require "LuaClass/WoWUtils"
require "LuaClass/GuideController"

chargingListForTd = {}

--local chargeData = {{["id"] = "2", ["bg"] = "Images/charging/cz_02.png", ["diamond"] = 398, ["money"] = 16},
--                    {["id"] = "3", ["bg"] = "Images/charging/cz_03.png", ["diamond"] = 888, ["money"] = 30},
--                    {["id"] = "1", ["bg"] = "Images/charging/cz_01.png", ["diamond"] = 120, ["money"] = 6},
--                    {["id"] = "11", ["bg"] = "Images/charging/cz_04.png", ["coin"] = 100, ["money"] = 0.1}}
local chargeData = {{["id"] = "2", ["bg"] = "Images/charging/cz_02.png", ["diamond"] = 398, ["money"] = 16},
                    {["id"] = "3", ["bg"] = "Images/charging/cz_03.png", ["diamond"] = 888, ["money"] = 30},
                    {["id"] = "1", ["bg"] = "Images/charging/cz_01.png", ["diamond"] = 120, ["money"] = 6}}

ChargeLayer = class("ChargeLayer", function ()
    return AlertView:create(0, 3, "充 值", function()
    end, nil)
end)

ChargeLayer.__index = ChargeLayer
ChargeLayer.scrollView = nil
ChargeLayer.scrollViewContainer = nil

function ChargeLayer:create()
    local view = ChargeLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

-- 清理函数
function ChargeLayer:destory()
    
end

function ChargeLayer:init()
    -- 钻石商店物品
    local scrollViewSize = cc.size(self.s_size.width, self.s_size.height - 140)
    self.scrollViewContainer = cc.Layer:create()

    self.scrollView = cc.ScrollView:create(scrollViewSize)

    self.scrollView:setPosition(cc.p(self.s_position.x - self.s_size.width * 0.5, self.s_position.y - self.s_size.height * 0.5 + 40))
    self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    self.scrollViewContainer:setPosition(cc.p(0.0, 0.0))
    self.scrollView:setClippingToBounds(true) -- 設置剪切
    self.scrollView:setBounceable(true)  -- 設置彈性效果
    self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    self.scrollView:setDelegate()
    -- self.scrollView:registerScriptHandler(scrollViewDidScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self:addChild(self.scrollView)
    
    -- 加载数据回调
    self:loadData()

    -- 添加析构回调
    self:setCancelCallback(function()
        -- body
        self:destory()
    end)
    return true
end

function ChargeLayer:loadData()
    cclog("开始加载充值界面的数据")
    local tempSpr = cc.Sprite:create("Images/charging/cz_01.png")
    local gap = 20

    --[[ 
    {["id"] = "5", ["bg"] = "Images/charging/cz_05.png", ["coin"] = 100, ["money"] = 8}, 
    {["id"] = "6", ["bg"] = "Images/charging/cz_06.png", ["coin"] = 100, ["money"] = 15}, 
    {["id"] = "7", ["bg"] = "Images/charging/cz_07.png", ["coin"] = 100, ["money"] = 30}, 
    {["id"] = "8", ["bg"] = "Images/charging/cz_08.png", ["coin"] = 100, ["money"] = 6}, 
    {["id"] = "9", ["bg"] = "Images/charging/cz_09.png", ["coin"] = 100, ["money"] = 10}, 
    {["id"] = "10", ["bg"] = "Images/charging/cz_10.png", ["coin"] = 100, ["money"] = 29}
    ]]--

    local totalHeight = (tempSpr:getContentSize().height + gap) * #chargeData
    if totalHeight < self.scrollView:getViewSize().height then
        totalHeight = self.scrollView:getViewSize().height
    end
    local menuItemArr = {}
    for i = 1, #chargeData do
        local bg = cc.MenuItemImage:create(chargeData[i]["bg"], chargeData[i]["bg"]) 
        if bg ~= nil then
            bg:registerScriptTapHandler(function ()
                local money = tonumber(chargeData[i]["money"])
                
                print("点击了"..chargeData[i]["money"].." 钱的按钮")
                if chargeData[i]["id"] == "5" or chargeData[i]["id"] == "6" or chargeData[i]["id"] == "7" or chargeData[i]["id"] == "11" then
                    -- 要判断是否买过，买过就不让买了
                    if not GuideController:getInstance():getIsHaveStep(800 + tonumber(chargeData[i]["id"])) then
                        purchase(chargeData[i]["id"])
                    else
                        ToastUtil:downString("该商品不能重复购买")
                    end
                else
                    purchase(chargeData[i]["id"])
                end
            end)
            bg:setPosition(cc.p(self.scrollView:getViewSize().width * 0.5, totalHeight - (i - 0.5) * (bg:getContentSize().height + gap)))
            table.insert(menuItemArr, bg)
        end
    end
    local menus = cc.Menu:create(unpack(menuItemArr))
    menus:setPosition(cc.p(0, 0))
    self.scrollViewContainer:addChild(menus)

    self.scrollView:setContentSize(cc.size(self.scrollView:getViewSize().width, totalHeight))
    self.scrollView:setContentOffset(cc.p(0, -(totalHeight - self.scrollView:getViewSize().height)))
end

--[[
小支付界面，只给钻石不足的时候用
]]
ChargeMiniLayer = class("ChargeMiniLayer", function ()
    return AlertView:create(0, 0, "获取钻石", function()
    end, nil)
end)

ChargeMiniLayer.__index = ChargeMiniLayer

function ChargeMiniLayer:create()
    local view = ChargeMiniLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

-- 清理函数
function ChargeMiniLayer:destory()
    
end

function ChargeMiniLayer:init()
    -- 添加提示的文本
    local showLabel1 = cc.LabelTTF:create("点击下方图标领取更多钻石", BoldFont, 33.0)
    showLabel1:setColor(cc.c3b(255, 255, 255))
    -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    showLabel1:setPosition(cc.p(self.s_position.x, self.s_position.y + showLabel1:getContentSize().height * 2.0))
    self:addChild(showLabel1)
    
    -- 增加按钮
    local chargeBtn = cc.MenuItemImage:create(chargeData[1]["bg"], chargeData[1]["bg"])
    chargeBtn:registerScriptTapHandler(function ()
        local money = tonumber(chargeData[1]["money"])
        print("点击了未知的按钮")
        purchase(chargeData[1]["id"])
    end)
    chargeBtn:setPosition(cc.p(0, 0))

    local menus = cc.Menu:create(chargeBtn)
    menus:setPosition(cc.p(self.s_position.x, self.s_position.y - 100.0))
    self:addChild(menus)

    -- 添加析构回调
    self:setCancelCallback(function()
        -- body
        self:destory()
    end)
    return true
end