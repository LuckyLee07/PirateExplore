-- Only the reviewed chest feedback deltas may normalize to the frozen base.
-- Any other byte change remains visible to the whole-file and 71-method checks.
local M={}
local function replaceOne(text,from,to)
 local first=assert(text:find(from,1,true),"missing exact feedback edit: "..from)
 assert(not text:find(from,first+#from,true),"ambiguous feedback edit: "..from)
 return text:sub(1,first-1)..to..text:sub(first+#from)
end
function M.fight(source)
 -- Separately reviewed recovery entry points; the gameplay bodies stay exact.
 source=replaceOne(source,[=[        if not self.fightResult and rawget(_G,'WARM_PIRATE_V1') ~= false then
            return require('LuaClass/WarmBattleRecovery').choice(self)
        end
]=],[=[]=])
 source=replaceOne(source,[=[    if rawget(_G,'WARM_PIRATE_V1') ~= false then
        return require('LuaClass/WarmBattleRecovery').result(self)
    end
]=],[=[]=])
 source=replaceOne(source,[=[self:showInfo(data.name, data.desc, prop[2], state == FightBoxView.BoxState.open)]=],[=[self:showInfo(data.name, data.desc)]=])
 source=replaceOne(source,[=[function FightBoxView:showInfo(name, desc, quantity, earned)]=],[=[function FightBoxView:showInfo(name, desc)]=])
 source=replaceOne(source,[=[            if self.coherentChest and quantity then
                name = tostring(name).." × "..tostring(quantity)..(earned and " · 已收入" or " · 未获得")
            end
]=],[=[]=])
 source=replaceOne(source,[=[ExploreBagController:getBagController():addCoin(propNum, not self.coherentChest)]=],[=[ExploreBagController:getBagController():addCoin(propNum)]=])
 source=replaceOne(source,[=[DataManager:getInstance():addDiamond(propNum, false, not self.coherentChest)]=],[=[DataManager:getInstance():addDiamond(propNum, false)]=])
 source=replaceOne(source,[=[if not self.coherentChest then ToastUtil:downString("打开宝箱成功!") end]=],[=[ToastUtil:downString("打开宝箱成功!")]=])
 source=replaceOne(source,[=[self:showInfo(data.name, data.desc, propNum, true)]=],[=[self:showInfo(data.name, data.desc)]=])
 source=replaceOne(source,[=[    if self.coherentChest then require('LuaClass/WarmShortageOwnership').retire(self)end
]=],[=[]=])
 source=replaceOne(source,[=[addDiamond(-FightBoxView.FailDiamond[self.failTime],nil,nil,self.coherentChest and require('LuaClass/WarmShortageOwnership').forOwner(self,'chestRenderGeneration',function()return not self.chestCompleted and not self.chestDisposed end)or nil)]=],[=[addDiamond(-FightBoxView.FailDiamond[self.failTime])]=])
 source=replaceOne(source,[=[        require('LuaClass/WarmShortageOwnership').retire(self)
]=],[=[]=])
 source=replaceOne(source,[=[        local presentation=require('LuaClass/WarmShortageOwnership').forOwner(owner,'chestRenderGeneration',function()return FightBoxView.instance==owner and not owner.chestCompleted and not owner.chestDisposed end)
]=],[=[]=])
 source=replaceOne(source,[=[addDiamond(-7,nil,nil,presentation)]=],[=[addDiamond(-7)]=])
 return source
end
M.fightExpected={166087,638090212}
function M.bag(source)
 source=replaceOne(source,[=[function ExploreBagController:addCoin( addCoin, isTip )]=],[=[function ExploreBagController:addCoin( addCoin )]=])
 source=replaceOne(source,[=[	-- Coherent chests show their own persistent reward detail. Other callers keep both legacy tips.
	if isTip ~= false then
		ToastUtil:downString("金币+" .. addCoin)
		ToastUtil:downString("总共" .. money.."金币")
	end]=],[=[	ToastUtil:downString("金币+" .. addCoin)
	ToastUtil:downString("总共" .. money.."金币")]=])
 return source
end
M.bagExpected={25312,767986519}
function M.diamond(source)
 -- Intelligence only forwards an optional shortage owner; keep the original
 -- whole-file checksum and economic counterfactual unchanged.
 source=replaceOne(source,'function DataManager:checkTallentPass(tallent, costType, presentation)','function DataManager:checkTallentPass(tallent, costType)')
 local count
 source,count=source:gsub('self:addDiamond%(%-needDiamod, nil, nil, presentation%)','self:addDiamond(-needDiamod)')
 assert(count==2,'exact intelligence affordability owner forwarding')
 -- Separate shortage follow-up: normalize only its exact presentation branch.
 source=replaceOne(source,[=[        if rawget(_G, 'WARM_PIRATE_V1') ~= false then
            local available = require('LuaClass/PurchaseAvailability').isAvailable()
            local body = available and '钻石不足，可查看充值选项。购买结果由平台确认。'
                or '钻石不足，当前平台暂不支持充值购买。'
            local options = {{label='知道了'}}
            if available then
                local offered = false
                options = {{label='查看充值选项', action=function()
                    if offered or (presentation and not presentation.isActive()) then return false end
                    offered = true
                    local gift = PushGiftView:create()
                    if presentation then
                        presentation.showGift(gift, isEnterMap and 999 or nil)
                    elseif isEnterMap then
                        gift:show(999)
                    else
                        gift:show()
                    end
                end}, {label='取消'}}
            end
            require('LuaClass/WarmDialog').show('钻石不足', body, options, presentation and presentation.owner)
            return
        end
]=],[=[]=])
 source=replaceOne(source,[=[-- Optional presentation context scopes only the warm shortage UI to its caller.
function DataManager:addDiamond(_Diamondnum, bIsShowAlert, isTip, presentation)]=],[=[function DataManager:addDiamond(_Diamondnum, bIsShowAlert)]=])
 source=replaceOne(source,[=[if (_Diamondnum > 0) and isTip ~= false then]=],[=[if (_Diamondnum > 0) then]=])
 return source
end
M.diamondExpected={98551,101271098}
return M
