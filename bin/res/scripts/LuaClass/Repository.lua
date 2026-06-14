require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/SDButton"


RepositoryLayer = class("RepositoryLayer", function ()
	return BaseView:create()
end)

RepositoryLayer.__index = RepositoryLayer
RepositoryLayer.scrollView = nil
RepositoryLayer.scrollViewContainer = nil
RepositoryLayer.produceCsv = nil
RepositoryLayer.lastSortType = "0"
RepositoryLayer.lastUpdateMd5 = nil

function RepositoryLayer:create()
	local view = RepositoryLayer.new()
	if view and view:init() then
		return view
	end
	return nil
end

function RepositoryLayer:destory()
	DataManager:getInstance():unregisterEvent(rolePack, "repository")
	DataManager:getInstance():unregisterEvent(roleGuideStep, "repository")
	DataManager:getInstance():unregisterEvent(roleMapInfo, "RepositoryLayer")

	-- 调用父类的析构
	self:superDestory()
end

function RepositoryLayer:init()
    DataManager:getInstance():registerEvent(roleMapInfo, "RepositoryLayer", function()
        -- body
        local flag = DataManager:getInstance():checkDiamondStoreNewGoods()
        if (flag) then
        	GuideController:getInstance():addRedPoint(self.topRightBtn)
        else
        	GuideController:getInstance():removeRedPoint(self.topRightBtn)
        end
    end)

	local flag = DataManager:getInstance():checkDiamondStoreNewGoods()
	if (flag) then
		GuideController:getInstance():addRedPoint(self.topRightBtn)
	else
		GuideController:getInstance():removeRedPoint(self.topRightBtn)
	end

	self.produceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)

	local visibleSize = cc.Director:getInstance():getVisibleSize()
	local origin = cc.Director:getInstance():getVisibleOrigin()

	-- 设置title文字
	self:setTitleString("仓 库")

	-- 修改顶部左侧按钮显示
    self.topLeftBtn:setVisible(true)

    -- 修改顶部左侧侧按钮为快速出征
    self:resetTopLeftButtonToExpedition()

	-- 设置下方信息界面
	self:addInfoNode("船 坞", function()
		zqDispatch:moveToExpedition()
	end, "资 源", function()
		zqDispatch:moveToResource()
	end, "Images/MainMenu/an_lianj_a.png", "Images/MainMenu/an_lianj_b.png", function()
		-- cclog("点击了炼金按钮")
		DataManager:getInstance():AlchemyButtonDidClick()
	end, nil, true, zqAlchemyTime, false)

	-- 添加顶部筛选按钮组的背景
	local topButtonGroup = cc.Sprite:create("Images/UI/TopButtonGroupBg.png")
	topButtonGroup:setPosition(cc.p(visibleSize.width * 0.5, visibleSize.height - UITopHeight - self.titleHeight - topButtonGroup:getContentSize().height * 0.5))
	self:addChild(topButtonGroup)

	-- 添加全部筛选按钮
	local allBtnNormal = cc.MenuItemImage:create("Images/UI/c_quanbu_b.png", "Images/UI/c_quanbu_b.png")
	local allBtnSelected = cc.MenuItemImage:create("Images/UI/c_quanbu_a.png", "Images/UI/c_quanbu_a.png")
	local allBtn = cc.MenuItemToggle:create(allBtnNormal, allBtnSelected)
	allBtn:setPosition(cc.p(self.titleLabel:getPositionX() - 220, topButtonGroup:getPositionY()))

	allBtn:setSelectedIndex(1)

	-- 添加装备按钮
	local equipBtnNormal = cc.MenuItemImage:create("Images/UI/c_zhuangbei_b.png", "Images/UI/c_zhuangbei_b.png")
	local equipBtnSelected = cc.MenuItemImage:create("Images/UI/c_zhuangbei_a.png", "Images/UI/c_zhuangbei_a.png")
	local equipBtn = cc.MenuItemToggle:create(equipBtnNormal, equipBtnSelected)
	equipBtn:setPosition(cc.p(self.titleLabel:getPositionX() - 108, allBtn:getPositionY()))

	-- 添加资源按钮
	local resourceBtnNormal = cc.MenuItemImage:create("Images/UI/c_ziyuan_b.png", "Images/UI/c_ziyuan_b.png")
	local resourceBtnSelected = cc.MenuItemImage:create("Images/UI/c_ziyuan_a.png", "Images/UI/c_ziyuan_a.png")
	local resourceBtn = cc.MenuItemToggle:create(resourceBtnNormal, resourceBtnSelected)
	resourceBtn:setPosition(cc.p(self.titleLabel:getPositionX(), allBtn:getPositionY()))

	-- 添加碎片按钮
	local pieceBtnNormal = cc.MenuItemImage:create("Images/UI/c_suipian_b.png", "Images/UI/c_suipian_b.png")
	local pieceBtnSelected = cc.MenuItemImage:create("Images/UI/c_suipian_a.png", "Images/UI/c_suipian_a.png")
	local pieceBtn = cc.MenuItemToggle:create(pieceBtnNormal, pieceBtnSelected)
	pieceBtn:setPosition(cc.p(self.titleLabel:getPositionX() + 108, allBtn:getPositionY()))

	-- 添加其他按钮
	local otherBtnNormal = cc.MenuItemImage:create("Images/UI/c_qita_b.png", "Images/UI/c_qita_b.png")
	local otherBtnSelected = cc.MenuItemImage:create("Images/UI/c_qita_a.png", "Images/UI/c_qita_a.png")
	local otherBtn = cc.MenuItemToggle:create(otherBtnNormal, otherBtnSelected)
	otherBtn:setPosition(cc.p(self.titleLabel:getPositionX() + 220, allBtn:getPositionY()))

	local function buttonClickToggle(tag)
		-- body
		allBtn:setSelectedIndex(0)
		equipBtn:setSelectedIndex(0)
		resourceBtn:setSelectedIndex(0)
		pieceBtn:setSelectedIndex(0)
		otherBtn:setSelectedIndex(0)
		-- 刷新数据
		self:initBagDataWithType(tag.."")
	end
	allBtn:registerScriptTapHandler(function()
		buttonClickToggle(0)
		allBtn:setSelectedIndex(1)
	end)
	equipBtn:registerScriptTapHandler(function()
		buttonClickToggle(1)
		equipBtn:setSelectedIndex(1)
	end)
	resourceBtn:registerScriptTapHandler(function()
		buttonClickToggle(2)
		resourceBtn:setSelectedIndex(1)
	end)
	pieceBtn:registerScriptTapHandler(function()
		buttonClickToggle(3)
		pieceBtn:setSelectedIndex(1)
	end)
	otherBtn:registerScriptTapHandler(function()
		buttonClickToggle(4)
		otherBtn:setSelectedIndex(1)
	end)

	local btnTable = {allBtn, equipBtn, resourceBtn, pieceBtn, otherBtn}
	local menu = cc.Menu:create(unpack(btnTable))
	menu:setPosition(cc.p(0, 0))
	self:addChild(menu)

	-- 添加没有任何道具的时候的提示label
	-- local MaskAlertLabel = cc.LabelTTF:create("请点击下方【炼金】按钮", BoldFont, 32.0)
 --    MaskAlertLabel:setPosition(self.centerPos)
 --    MaskAlertLabel:setColor(WriteColor)
 --    -- MaskAlertLabel:enableStroke(cc.c4b(16, 16, 16, 255), 1)
 --    self:addChild(MaskAlertLabel)

	-- 添加scrollView
	self.scrollViewContainer = cc.Layer:create()
    local scrollViewSize = cc.size(self.areaWidth, self.areaHeight - self.titleHeight)
    self.scrollViewContainer:setContentSize(scrollViewSize)
    self.scrollView = cc.ScrollView:create(scrollViewSize)
    self.scrollView:setPosition(cc.p(self.centerPos.x - self.areaWidth * 0.5, self.centerPos.y - self.areaHeight * 0.5))
    self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    self.scrollView:setViewSize(scrollViewSize)
    self.scrollView:setClippingToBounds(true) -- 設置剪切
    self.scrollView.bIsScrollView = true
    self.scrollView:setBounceable(true)  -- 設置彈性效果
    self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    self.scrollView:setDelegate()
    self.scrollView:registerScriptHandler(function()

    end, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self:addChild(self.scrollView)

    self:initBagDataWithType()

    -- 更新新手引导界面显示
    local guideNode = nil
    local finger = nil
    local function resetGuideStatus()
        -- cclog("repository新手引导步骤变化")
        -- 没走第一步之前的操作
        if GuideController:getInstance():getIsHaveStep(1) then
        	self.setBtn:setEnabled(true)
        	if finger ~= nil then
                finger:removeFromParent()
                finger = nil
            end
            
            if GuideController:getInstance():getIsHaveStep(101, true) then
                -- 干掉炼金按钮的红点
                GuideController:getInstance():removeRedPoint(self.setBtn)
            end
        else
        	-- 默认禁用炼金按钮的点击
            self.setBtn:setEnabled(false)
            self.setBtnText:runAction(cc.FadeOut:create(0.0))
            -- 什么都没做过的话在炼金上显示红点
            GuideController:getInstance():addRedPoint(self.setBtn)
            self.setBtn:runAction(cc.FadeOut:create(0.0))
            self.setBtn:runAction(cc.Sequence:create(cc.DelayTime:create(6.2), cc.FadeIn:create(0.0), cc.ScaleTo:create(0.0, 2.0), cc.EaseExponentialIn:create(cc.ScaleTo:create(0.6, 1.0)), cc.DelayTime:create(2.6), cc.CallFunc:create(function()
            	-- body
            	self.setBtn:setEnabled(true)
            	self.setBtnText:runAction(cc.FadeIn:create(0.6))
            	-- 添加引导的小手动画, 点击10次之后消失~
                finger = cc.Sprite:create("Images/Map/Guide/finger_1.png")
                finger:setAnchorPoint(0,1)
                finger:setScale(0.8)
                finger:setPosition(cc.p(self.setBtn:getPositionX(), self.setBtn:getPositionY() + self.setBtn:getContentSize().height * 1.2))
                self:addChild(finger, 9999)

                local spriteFrame = cc.SpriteFrameCache:getInstance()   
                for i = 1, 2 do
                    local sprName = string.format("Images/Map/Guide/finger_%d.png", i)
                    local tempSprite = cc.Sprite:create(sprName)
                    if tempSprite ~= nil then
                        spriteFrame:addSpriteFrame(tempSprite:getSpriteFrame(), sprName)
                    end
                end
                local touchAni = EffectUtil:getAnimate("Images/Map/Guide/finger_%d.png", 1, 2, 0.3)
                finger:runAction(cc.RepeatForever:create(touchAni))
            end)))
        end
        -- 建设完仓库之后的操作
        if GuideController:getInstance():getIsHaveStep(2) then
            self:setTitleString("仓 库")
            self.storeMenu:setVisible(true)
            menu:setVisible(true)
            topButtonGroup:setVisible(true)
            self.scrollView:setVisible(true)
            -- MaskAlertLabel:setVisible(false)
        else
        	-- 先设置好各种控件的状态
        	self:setTitleString("荒 岛")
        	self.storeMenu:setVisible(false)
        	menu:setVisible(false)
        	topButtonGroup:setVisible(false)
        	self.scrollView:setVisible(false)
        	-- MaskAlertLabel:setVisible(not GuideController:getInstance():getIsHaveStep(1))
            if not GuideController:getInstance():getIsHaveStep(1) then
	            -- 隐藏父节点的一些内容
	            self.titleBg:setOpacity(0.0)
	            self.bgIcon:setOpacity(0.0)
	            -- MaskAlertLabel:setOpacity(0.0)
	            self.mainBg:setOpacity(0.0)
	            -- 第一次走引导的时候按顺序播放动画，先显示荒岛和背景图
	            self.titleBg:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.FadeIn:create(1.6)))
	            self.mainBg:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.FadeIn:create(1.6)))
	            -- 显示海盗船
	            self.bgIcon:runAction(cc.Sequence:create(cc.DelayTime:create(3.6), cc.FadeIn:create(1.6)))
	            -- MaskAlertLabel:runAction(cc.Sequence:create(cc.FadeOut:create(0.0), cc.DelayTime:create(10.8), cc.FadeIn:create(1.6)))
	        end
        end
        -- 如果解锁了船坞，那么现实左侧快速出征按钮
        -- self.topLeftBtn:setVisible(GuideController:getInstance():getIsHaveStep(8))
        -- 如果走了这步，那么就不显示钻石商城的红点鸟~
        if GuideController:getInstance():getIsHaveStep(61) then
			GuideController:getInstance():removeRedPoint(self.topRightBtn)
		end
    end
    DataManager:getInstance():registerEvent(roleGuideStep, "repository", resetGuideStatus)

    -- 初始化的时候默认调用一次
    resetGuideStatus()

--    require "LuaClass/EffectUtil"
--    local ani = EffectUtil:createAnimation("Effect/Animation/baofengyu.plist", 0)
--    ani:setScale(6.0)
--    ani:setPosition(320, 568)
--    self:addChild(ani)
	
	-- 如果是首次出征回来
	if GuideController:getInstance():getIsHaveStep(60) then
		-- 没显示过红点
		if not GuideController:getInstance():getIsHaveStep(61) then
			GuideController:getInstance():addRedPoint(self.topRightBtn)
		else
			GuideController:getInstance():removeRedPoint(self.topRightBtn)
		end
	end
	DataManager:getInstance():registerEvent(rolePack, "repository", function()
    	-- cclog("刷新背包数据")
    	self:reloadData()
    end)
	return true
end

function RepositoryLayer:setIsReload(bIsReload)
	if bIsReload then
		DataManager:getInstance():registerEvent(rolePack, "repository", function()
	    	-- cclog("刷新背包数据")
	    	self:reloadData()
	    end)
	else
		DataManager:getInstance():unregisterEvent(rolePack, "repository")
	end
end

function RepositoryLayer:reloadData()
	-- print("刷新背包数据")
	local jsons = json.encode(DataManager:getInstance():getRoleData(rolePack))
	local jsonMd5 = MD5(jsons, string.len(jsons)):hexdigest()
	-- 如果数据没变还刷新鸡毛啊。。。
	if self.lastUpdateMd5 == nil or self.lastUpdateMd5 ~= jsonMd5 then
		self:initBagDataWithType(self.lastSortType)
		self.lastUpdateMd5 = jsonMd5
	end
end

function RepositoryLayer:initBagDataWithType(sortType)
	if sortType == nil then
		self.lastSortType = "0"
	else
		self.lastSortType = sortType
	end
	
	-- 先删除上边所有内容
	self.scrollViewContainer:removeAllChildren()

	local produceTable = DataManager:getInstance():getRoleData(rolePack)
	local lineHeight = 76.0
	local dataNum = 0
	-- 要先计算数据
	for k,v in pairs(produceTable) do
		local csvData = self.produceCsv[k]
        if csvData ~= nil then
	        local number = v
	        local display = csvData["display"]
	        local itemType = csvData["type"]
	        if number > 0 and display == "1" and (itemType == self.lastSortType or self.lastSortType == "0") then
				dataNum = dataNum + 1
			end
		end
	end
	-- 循环取得的数据创建label
    local allHeight = math.ceil(dataNum / 2) * lineHeight
    if allHeight < self.scrollView:getViewSize().height then
        allHeight = self.scrollView:getViewSize().height
    end
	local num = 0
	local leftSpr = nil
	cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGB565)
    for k,v in pairs(produceTable) do
        -- print(k,v)
        local csvData = self.produceCsv[k]
        if csvData ~= nil then
	        local number = v
	        local name = csvData["name"]
	        local display = csvData["display"]
	        local itemType = csvData["type"]
	        local price = tonumber(csvData["worth"])
	        if number > 0 and display == "1" and (itemType == self.lastSortType or self.lastSortType == "0") then
	        	local sprName = "Images/UI/dibantiao_02.png"
	        	if csvData["iconName"] ~= nil and csvData["iconName"] ~= "" then
	        		sprName = "Images/Icon/"..csvData["iconName"]
	        	end
	        	leftSpr = SDButton:create(sprName, sprName, function ()
	                -- 点击之后显示详情 
	                if csvData["desc"] ~= nil and csvData["desc"] ~= "" then
	                	self:showInfoBox(csvData["desc"])
	                else
	                	self:showInfoBox("神没有赋予这个物品任何说明")
	                end
	            end)
	            leftSpr:setSwallowTouches(false)
	            leftSpr:addClickArea(cc.rect(0, 10, 200, 20))
        		leftSpr:registerLongPressedActiveOnce(function()
		            -- body
		            cclog("长按出售")
		            if price == nil or price == "" then
		            	ToastUtil:downString("抱歉，商人不收购此物品")
		            	return
		            end
		            local _alert = AlertView:create(0,0, "出售道具",nil)

		            -- 添加顶部的说明文字
		            local infoLabel = cc.LabelTTF:create("出售"..name.." 单价:"..price, BoldFont, 28.0)
	            	infoLabel:setColor(BaseColor)
	            	-- infoLabel:enableStroke(cc.c4b(16, 16, 16, 255), 1)
	            	infoLabel:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + 114))
	            	_alert:addChild(infoLabel)

		            local _menuButton1 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
		            _menuButton1:registerScriptTapHandler(function ()
		                -- body
		                if DataManager:getInstance():addPackItemWithId(k, -1) then
		                	DataManager:getInstance():addCoin(price)
		                	ToastUtil:downString("成功出售 1个"..name.." 金币+"..price)
		                end
		                _alert:removeFromParent()
		            end)

		            local _menuButton2 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
		            _menuButton2:registerScriptTapHandler(function ()
		                -- body
		                local sellNum = 10
		                if number < 10 then
		                	sellNum = number
		                end
		                if DataManager:getInstance():addPackItemWithId(k, -sellNum) then
		                	DataManager:getInstance():addCoin(price * sellNum)
		                	ToastUtil:downString("成功出售 "..sellNum.."个"..name.." 金币+"..price * sellNum)
		                end
		                _alert:removeFromParent()
		            end)

		            local _menuButton3 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
		            _menuButton3:registerScriptTapHandler(function ()
		                -- body
		                sellNum = number
		                if DataManager:getInstance():addPackItemWithId(k, -sellNum) then
		                	DataManager:getInstance():addCoin(price * sellNum)
		                	ToastUtil:downString("成功出售 "..sellNum.."个"..name.." 金币+"..price * sellNum)
		                end
		                _alert:removeFromParent()
		            end)

		            local _menuButton1Lable = cc.LabelTTF:create("出售1个", BoldFont, 30.0)
		            _menuButton1Lable:setPosition(cc.p(_menuButton1:getContentSize().width * 0.5,_menuButton1:getContentSize().height * 0.5))
		            -- _menuButton1Lable:enableStroke(cc.c4b(255, 255, 255, 255), 2)
		            _menuButton1:addChild(_menuButton1Lable)

		            local _menuButton2Lable = cc.LabelTTF:create("出售10个", BoldFont, 30.0)
		            _menuButton2Lable:setPosition(cc.p(_menuButton2:getContentSize().width * 0.5,_menuButton2:getContentSize().height * 0.5))
		            -- _menuButton2Lable:enableStroke(cc.c4b(255, 255, 255, 255), 2)
		            _menuButton2:addChild(_menuButton2Lable)

		            local _menuButton3Lable = cc.LabelTTF:create("出售所有", BoldFont, 30.0)
		            _menuButton3Lable:setPosition(cc.p(_menuButton3:getContentSize().width * 0.5,_menuButton3:getContentSize().height * 0.5))
		            -- _menuButton3Lable:enableStroke(cc.c4b(255, 255, 255, 255), 2)
		            _menuButton3:addChild(_menuButton3Lable)


		            _menuButton1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + _menuButton1:getContentSize().height * 2 - 66))
		            _menuButton2:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y - 46))
		            _menuButton3:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y - _menuButton1:getContentSize().height * 2 - 26))
		            local menu = cc.Menu:create(_menuButton1,_menuButton2,_menuButton3)
		            menu:setPosition(0.0, 0.0)
		            _alert:addChild(menu)
        		end)
	        	leftSpr:setPosition(cc.p((num % 2) * (self.scrollViewContainer:getContentSize().width / 2) + 40, allHeight - (math.ceil((num + 1) / 2) - 1) * lineHeight - leftSpr:getContentSize().height * 0.5))
	        	self.scrollViewContainer:addChild(leftSpr)

	        	-- 添加名字文本
	            local label = cc.LabelTTF:create(name, BoldFont, 28.0)
	            label:setAnchorPoint(cc.p(0, 1))
	            label:setColor(BaseColor)
	            -- label:enableStroke(cc.c4b(16, 16, 16, 255), 1)
	            label:setPosition(cc.p(leftSpr:getPositionX() + leftSpr:getContentSize().width * 0.6, leftSpr:getPositionY() + leftSpr:getContentSize().height * 0.5))
	            self.scrollViewContainer:addChild(label)

	            -- 添加数量文本
	            local numLabel = cc.LabelTTF:create(number.."", BoldFont, 28.0)
	            numLabel:setAnchorPoint(cc.p(0, 1))
	            numLabel:setColor(WriteColor)
	            -- numLabel:enableStroke(cc.c4b(16, 16, 16, 255), 1)
	            numLabel:setPosition(cc.p(leftSpr:getPositionX() + leftSpr:getContentSize().width * 0.6, label:getPositionY() - 30.0))
	            self.scrollViewContainer:addChild(numLabel)

	            num = num + 1
	        end
	    end
    end
    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
    self.scrollView:setContentSize(cc.size(self.scrollView:getViewSize().width, allHeight))
    self.scrollView:setContentOffset(cc.p(0, -(allHeight - self.scrollView:getViewSize().height)))
end