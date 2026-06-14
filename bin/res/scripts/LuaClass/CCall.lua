require "LuaClass/Header"
require "LuaClass/DataManager"
require "LuaClass/ToastUtil"
require "LuaClass/GuideController"
require "LuaClass/NotificationNode"
--[[
支付相关操作开始
]]
function chargeSuccess(val)
	-- body
	print("DataManager:chargeSuccess", val)
	local chargeType = 0
	local bIsSuccess = false
	if val < 2000 then
		chargeType = val - 1000
		bIsSuccess = true
	else
		chargeType = val - 2000
		bIsSuccess = false
	end

    -- 充值相关1-3,礼包相关4-12
	if bIsSuccess then
		-- 支付成功
		-- if chargeType == 1 then
		-- 	ToastUtil:downString("支付成功")
		-- 	DataManager:getInstance():addDiamond(120)
		-- elseif chargeType == 2 then
		-- 	ToastUtil:downString("支付成功")
		-- 	DataManager:getInstance():addDiamond(398)
		-- elseif chargeType == 3 then
		-- 	ToastUtil:downString("支付成功")
		-- 	DataManager:getInstance():addDiamond(888)
		-- else
		if chargeType == 4 then
			-- 死亡无伤返回
			ToastUtil:downString("支付成功，您的队伍将返回战船！")
			paySuccess()
		-- elseif chargeType == 5 then
		-- 	-- 天赋：耐饿（探索地图每行动2格减少1个补给） 金币：10000 钻石：88
		-- 	ToastUtil:downString("支付成功!")
		-- 	-- ToastUtil:downString("您获得天赋：耐饿")
		-- 	ToastUtil:downString("金币+10000")
		-- 	-- ToastUtil:downString("钻石+88")
		-- 	DataManager:getInstance():addCoin(10000)
		-- 	DataManager:getInstance():addDiamond(88)
		-- 	DataManager:getInstance():unlockTallentByKey("2003")

		-- 	GuideController:getInstance():addStep(805)
		-- elseif chargeType == 6 then
		-- 	-- 英雄：深渊之龙 金币：20000 钻石：288
		-- 	ToastUtil:downString("支付成功!")
		-- 	ToastUtil:downString("您获得：深渊之龙")
		-- 	ToastUtil:downString("金币+20000")
		-- 	-- ToastUtil:downString("钻石+288")
		-- 	DataManager:getInstance():addCoin(20000)
		-- 	DataManager:getInstance():addDiamond(288)
		-- 	DataManager:getInstance():addSoilderWithId("158", 1)

		-- 	GuideController:getInstance():addStep(806)
		-- elseif chargeType == 7 then
		-- 	-- 天赋：先发制人（战斗中每回合开始，首先攻击） 加速生产：生产时间由20秒1次降低至15秒1次 钻石：666
		-- 	ToastUtil:downString("支付成功!")
		-- 	-- ToastUtil:downString("您获得天赋：先发制人")
		-- 	ToastUtil:downString("您获得：加速生产")
		-- 	-- ToastUtil:downString("钻石+666")
		-- 	DataManager:getInstance():addDiamond(666)
		-- 	DataManager:getInstance():unlockTallentByKey("2005")
		-- 	DataManager:getInstance():setRoleData(roleResourceCD, 15)

		-- 	GuideController:getInstance():addStep(807)
		-- elseif chargeType == 8 then
		-- 	-- 金币：20000
		-- 	ToastUtil:downString("支付成功，您获得20000金币！")
		-- 	DataManager:getInstance():addCoin(20000)
		-- elseif chargeType == 9 then
		-- 	-- 钻石：320
		-- 	ToastUtil:downString("支付成功")
		-- 	DataManager:getInstance():addDiamond(320)
		-- elseif chargeType == 10 then
		-- 	-- 回城卷轴：10 金币：88888 钻石：666
		-- 	ToastUtil:downString("支付成功!")
		-- 	ToastUtil:downString("您获得 回城卷轴 x 10")
		-- 	ToastUtil:downString("金币+88888")
		-- 	-- ToastUtil:downString("钻石+666")
		-- 	DataManager:getInstance():addCoin(88888)
		-- 	DataManager:getInstance():addDiamond(666)
		-- 	DataManager:getInstance():addPackItemWithId("1303", 1)
		-- elseif chargeType == 11 then
		-- 	ToastUtil:downString("支付成功，您获得100金币！")
		-- 	DataManager:getInstance():addCoin(100)

		-- 	GuideController:getInstance():addStep(811)
		end

		-- DataManager:getInstance():postEvent("kChargeSuccess"..chargeType, nil)
		-- DataManager:getInstance():postEvent("diamondStoreBuySomethingSuccess", "" .. chargeType)

		-- NotificationNode:getInstance():buySuccess(chargeType)
		NotificationNode:getInstance().buyStatus = chargeType
	else
		-- -- 支付失败
		-- if chargeType == 4 then
		-- 	--DataManager:getInstance():postEvent("kBuyBackFailed", nil) 
		-- 	--delayPop()
		-- end 
		--DataManager:getInstance():postEvent("kBuyBackFailed", nil)

	end
end

--[[
支付相关操作结束
]]

function doAddJewels(jewels)
    DataManager:getInstance():addDiamond(jewels)
end