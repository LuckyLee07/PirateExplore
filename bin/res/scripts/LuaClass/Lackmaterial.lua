require "LuaClass/Header"
require "LuaClass/ManagementTheme"
require "LuaClass/UIKit"
require "LuaClass/DialogueView"
require "LuaClass/DataManager"
require "LuaClass/ProductionSources"
require "AudioEngine"
require "LuaClass/GuideController"

local MAX_Z_ORDER = 2147483647   -- 32(or 64)位机器上int的最大值

-- DialogueViewManager
Lackmaterial = class("Lackmaterial", function ()
    return DialogueView:create()
end)

Lackmaterial.__index = Lackmaterial

-- lacktable的格式位
-- 材料id 
-- 材料名字
-- 材料价格
-- 缺少数量
-- create
-- -- {{mtID = "1007",mtname = "b",mtprice = "100",mtnum = "20",mtStar = “2”,mtonlyProduce = "1"}..}
function Lackmaterial:create(lacktable,callback)
    local view = Lackmaterial.new()
    if view and view:init(lacktable,callback) then
        return view
    end
    return nil
end

-- init
function Lackmaterial:init(lacktable,callback)
    if rawget(_G, 'WARM_PIRATE_V1') ~= false then return self:initCoherentLack(lacktable, callback) end
     local size = cc.Director:getInstance():getVisibleSize()

    -- background
    -- local bg = cc.Sprite:create("Images/UI/tankuang_01.png")
    
    local datanum = #lacktable
    print("datanum",datanum)
    local temp = cc.Sprite:create("Images/UI/tankuang_01.png")
    local bg = ManagementTheme.panel(temp:getContentSize().width,460+120*(datanum-1),'paper')


    bg:setAnchorPoint(cc.p(0.5, 0.5))

    self:addChild(bg)
    bg:setPosition(cc.p(0.5*size.width, 0.5*size.height ))

    --title
    local title = nil

    title = cc.LabelTTF:create("材料获得",ManagementTheme.bodyFont(),36)

    title:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()+bg:getContentSize().height/2-34))
    ManagementTheme.styleLabel(title,'heading')
    -- title:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    self:addChild(title)



    local btn = ManagementTheme.menuItem(58,58,'ink')
    btn:addChild(ManagementTheme.label('×',32,'action',29,29,.5),2)
    btn:registerScriptTapHandler(function()
if DataManager:getInstance():getSound_off() == 0 then
AudioEngine.playEffect(EFFECT_Button, false)
end
        self:close()
    end)
    btn:setPosition(cc.p(bg:getPositionX()+bg:getContentSize().width/2-40,title:getPositionY()))
    local menu = cc.Menu:create(btn)
    menu:setPosition(cc.p(0, 0))
    self:addChild(menu)

    local _fontSize = 26

    local _title2 = cc.LabelTTF:create("您可以通过以下方式获得",ManagementTheme.bodyFont(),_fontSize+2)
    _title2:setPosition(cc.p(title:getPositionX(),title:getPositionY()-62 - 30 * datanum))
    _title2:setColor(ManagementTheme.colors.ink)
    -- _title2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    self:addChild(_title2)

    for i = 1,datanum do
        --self:initMaterialGet()
        local type = 0 
        if tonumber(lacktable[i].mtId) == 1001 then
            --金币去炼金
            type = 1
        elseif tonumber(lacktable[i].mtStar) > 6 then
            --六星以上不提示
            type = 2
        elseif tonumber(lacktable[i].mtonlyProduce) == 1 then
            --只能生产
            type = 3
        
        end

        if type == 0 then
            local StoreUnlockData = DataManager:getInstance():getStoreUnlockTable()
            if StoreUnlockData == nil or StoreUnlockData[lacktable[i].mtId] == nil  then
                -- 暂时还未解锁
                type = 4
            end
        end
        local productionSource = type == 3 and ProductionSources.find(DataManager:getInstance(), GuideController:getInstance(), lacktable[i].mtId) or nil
        print("lacktable[i].mtID",lacktable[i].mtId)
        local _title1 = cc.LabelTTF:create("当前缺少"..lacktable[i].mtnum.."个"..lacktable[i].mtname,ManagementTheme.bodyFont(),_fontSize)
        _title1:setPosition(cc.p(title:getPositionX(),title:getPositionY()-62 - 30 * (i - 1)))
        _title1:setColor(ManagementTheme.colors.ink)
       -- _title1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        self:addChild(_title1)


        

        local _back1 = ManagementTheme.surfaceLike("Images/UI/dibantiao_03.png",'section')
        _back1:setPosition(cc.p(_title2:getPositionX(),_title2:getPositionY()-85 - 118 * (i - 1)))
        self:addChild(_back1)
        local needcoin

        if type == 0 then
            local _back1Font1 = cc.LabelTTF:create("购买"..lacktable[i].mtnum.."个"..lacktable[i].mtname,ManagementTheme.bodyFont(),_fontSize)
            _back1Font1:setAnchorPoint(cc.p(0,0))
            _back1Font1:setColor(ManagementTheme.colors.ink)
            -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
            self:addChild(_back1Font1)

            needcoin = tonumber(lacktable[i].mtnum) * tonumber(lacktable[i].mtprice)
            local _back1Font2 = cc.LabelTTF:create("花费"..tostring(needcoin).."金币",ManagementTheme.bodyFont(),_fontSize)
            _back1Font2:setAnchorPoint(cc.p(0,1))
            _back1Font2:setColor(ManagementTheme.colors.ink)
            -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
            self:addChild(_back1Font2)
        elseif type == 1 then
            local _back1Font1 = cc.LabelTTF:create("缺少"..lacktable[i].mtnum.."个"..lacktable[i].mtname,ManagementTheme.bodyFont(),_fontSize)
            _back1Font1:setAnchorPoint(cc.p(0,0))
            _back1Font1:setColor(ManagementTheme.colors.ink)
            -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
            self:addChild(_back1Font1)

            local _back1Font2 = cc.LabelTTF:create("可通过炼金获得",ManagementTheme.bodyFont(),_fontSize)
            _back1Font2:setAnchorPoint(cc.p(0,1))
            _back1Font2:setColor(ManagementTheme.colors.ink)
            -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
            self:addChild(_back1Font2)
        elseif type == 2 then
            local _back1Font1 = cc.LabelTTF:create("缺少"..lacktable[i].mtnum.."个"..lacktable[i].mtname,ManagementTheme.bodyFont(),_fontSize)
            _back1Font1:setAnchorPoint(cc.p(0,0))
            _back1Font1:setColor(ManagementTheme.colors.ink)
            -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
            self:addChild(_back1Font1)

            local _back1Font2 = cc.LabelTTF:create("需要通过探索获得",ManagementTheme.bodyFont(),_fontSize)
            _back1Font2:setAnchorPoint(cc.p(0,1))
            _back1Font2:setColor(ManagementTheme.colors.ink)
            -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
            self:addChild(_back1Font2)
        elseif type == 3 then
            local _back1Font1 = cc.LabelTTF:create("缺少"..lacktable[i].mtnum.."个"..lacktable[i].mtname,ManagementTheme.bodyFont(),_fontSize)
            _back1Font1:setAnchorPoint(cc.p(0,0))
            _back1Font1:setColor(ManagementTheme.colors.ink)
            -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
            self:addChild(_back1Font1)

            local _back1Font2 = cc.LabelTTF:create(productionSource and "安排工人并备齐原料后生产" or ProductionSources.caption(nil),ManagementTheme.bodyFont(),_fontSize)
            _back1Font2:setAnchorPoint(cc.p(0,1))
            _back1Font2:setColor(ManagementTheme.colors.ink)
            -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
            _back1Font2:setDimensions(cc.size(_back1:getContentSize().width-(productionSource and 180 or 44),44))
            _back1Font2:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
            self:addChild(_back1Font2)
        elseif type == 4 then
            local _back1Font1 = cc.LabelTTF:create("缺少"..lacktable[i].mtnum.."个"..lacktable[i].mtname,ManagementTheme.bodyFont(),_fontSize)
            _back1Font1:setAnchorPoint(cc.p(0,0))
            _back1Font1:setColor(ManagementTheme.colors.ink)
            -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
            self:addChild(_back1Font1)

            local _back1Font2 = cc.LabelTTF:create("当前无法获得，需出征探索海域",ManagementTheme.bodyFont(),_fontSize)
            _back1Font2:setAnchorPoint(cc.p(0,1))
            _back1Font2:setColor(ManagementTheme.colors.ink)
            -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
            self:addChild(_back1Font2)
        end
        --
        


        

        --button
        local _buyButton = ManagementTheme.menuItem(128,59,'coral')
        _buyButton:setPosition(cc.p(_back1:getPositionX()+_back1:getContentSize().width/2-90,_back1:getPositionY()))
        _buyButton:registerScriptTapHandler(function()
            --购买
            if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
            end
            if type == 0 then
                -- 建设完商城之后的操作
                if GuideController:getInstance():getIsHaveStep(5) then
                    local _result = DataManager:getInstance():addCoin(-1 * needcoin)
                    if _result == 0 then
                        self:close()
                        ToastUtil:toastString("金币不足")
                    else
                        ToastUtil:toastString("购买成功！"..lacktable[i].mtname.."+"..tonumber(lacktable[i].mtnum) )

                        DataManager:getInstance():addPackItemWithId(lacktable[i].mtId, tonumber(lacktable[i].mtnum))
                        print("存购买的物品 name=",lacktable[i].mtname,"个数=", tonumber(lacktable[i].mtnum))

                        table.remove(lacktable,i) 
                        print("asdasd",#lacktable)

                        if #lacktable > 0 then
                            self:reflush(lacktable,callback)
                            callback()
                        else
                            callback()
                            self:close()
                        end

                    end
                else
                    self:close()
                    ToastUtil:toastString("市场还未建造，不能购买")
                end
                
            elseif type == 1 then 
                self:close()
                -- zqDispatch:moveToResource()
                -- 去炼金
            elseif type == 2 then 
                self:close()
                zqDispatch:moveToExpedition()
                -- 去出征
            elseif type == 3 then 
                if not ProductionSources.find(DataManager:getInstance(), GuideController:getInstance(), lacktable[i].mtId) then
                    self:reflush(lacktable,callback)
                    return
                end
                self:close()
                zqDispatch:moveToResource()
                -- 去生产
            elseif type == 4 then 
                self:close()
                zqDispatch:moveToExpedition()
                -- 去出征
            end

        end)
        _buyButton:setEnabled(type ~= 3 or productionSource ~= nil)
        _buyButton:setVisible(type ~= 3 or productionSource ~= nil)


        local menuIcon = cc.Menu:create(_buyButton)
        menuIcon:setPosition(0.0, 0.0)
        self:addChild(menuIcon)


        local desstr = nil
        if type == 0 then
            desstr = "购 买"
        elseif type == 1 then 
            desstr = "去炼金"
        elseif type == 2 then 
            desstr = "出 征"
        elseif type == 3 then 
            desstr = "生 产"
        elseif type == 4 then 
            desstr = "出 征"
        end
        local _buyLabel = cc.LabelTTF:create(desstr, ManagementTheme.bodyFont(), 32.0)
        -- _buyLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        _buyLabel:setColor(cc.c3b(255,255,255))
        _buyLabel:setPosition(_buyButton:getPosition())
        _buyLabel:setVisible(type ~= 3 or productionSource ~= nil)
        self:addChild(_buyLabel)

    end
        
    local _back2 = ManagementTheme.surfaceLike("Images/UI/dibantiao_03.png",'section')
    _back2:setPosition(cc.p(_title2:getPositionX(),_title2:getPositionY()-85 - 118 * datanum  ))
    self:addChild(_back2)
    local source = ProductionSources.first(DataManager:getInstance(), GuideController:getInstance(), lacktable)
    local _back2Font1 = cc.LabelTTF:create(ProductionSources.caption(source),ManagementTheme.bodyFont(),_fontSize)
    _back2Font1:setAnchorPoint(cc.p(0,0.5))
    _back2Font1:setColor(ManagementTheme.colors.ink)
    -- _back2Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    _back2Font1:setPosition(cc.p(_back2:getPositionX()-_back2:getContentSize().width/2+22,_back2:getPositionY()))
    _back2Font1:setDimensions(cc.size(_back2:getContentSize().width-(source and 180 or 44),72))
    _back2Font1:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    self:addChild(_back2Font1)

    
    local _produceButton = ManagementTheme.menuItem(128,59,'coral')
    _produceButton:setPosition(cc.p(_back2:getPositionX()+_back2:getContentSize().width/2-90,_back2:getPositionY()))
    _produceButton:registerScriptTapHandler(function()
        if not ProductionSources.first(DataManager:getInstance(), GuideController:getInstance(), lacktable) then
            self:reflush(lacktable,callback)
            return
        end
        --生产
        --关闭所有窗口
        --self:close()
if DataManager:getInstance():getSound_off() == 0 then
AudioEngine.playEffect(EFFECT_Button, false)
end
        DialogueViewManager:sharedInstance():removeAllView()
        zqDispatch:moveToResource()
    end)
    _produceButton:setEnabled(source ~= nil)
    _produceButton:setVisible(source ~= nil)
    
    

    local producemenuIcon = cc.Menu:create(_produceButton)
    producemenuIcon:setPosition(0.0, 0.0)
    self:addChild(producemenuIcon)

    local _produceButtonLabel = cc.LabelTTF:create("查看生产", ManagementTheme.bodyFont(), 26.0)
    -- _produceButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    _produceButtonLabel:setColor(cc.c3b(255,255,255))
    _produceButtonLabel:setPosition(_produceButton:getPosition())
    _produceButtonLabel:setVisible(source ~= nil)
    self:addChild(_produceButtonLabel)

    return true

end

-- init
function Lackmaterial:reflush(lacktable,callback)
    if self.coherentLack then return self:refreshCoherentLack() end
    self:removeAllChildren(true);
    self:init(lacktable,callback)
end


-- Bounded Warm shortage sheet. The caller's recipe stays authoritative and
-- purchases still use the original addCoin/addPackItemWithId/callback sequence.
local lackObserverId=0
local function lackStock(dm,id)
    if tostring(id)=='1001' then return tonumber(dm:getRoleData(roleMoney)) or 0 end
    return tonumber((dm:getRoleData(rolePack) or {})[tostring(id)]) or 0
end
local function lackLabel(parent,text,size,x,y,width,color)
    local W=require 'LuaClass/WarmTheme'
    local label=W.label(text,size,color or W.colors.ink,x,y,false,0)
    if width then W.fit(label,width) end
    parent:addChild(label);return label
end
local function lackButton(parent,text,width,x,y,callback,primary)
    local W=require 'LuaClass/WarmTheme'
    local button=W.button(text,width,46,callback,{primary=primary,size=19})
    button:setPosition(cc.p(x,y));parent:addChild(button);return button
end
function Lackmaterial:initCoherentLack(materials,callback)
    self.coherentLack=true;self.coherentMaterials=materials;self.coherentCallback=callback
    self.coherentRequired={}
    local dm=DataManager:getInstance();local W=require 'LuaClass/WarmTheme'
    for _,row in ipairs(materials) do self.coherentRequired[tostring(row.mtId)]=lackStock(dm,row.mtId)+(tonumber(row.mtnum) or 0) end
    local size=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin()
    local scale=math.min(size.width/480,size.height/800)
    local canvas=cc.Node:create();canvas:setContentSize(cc.size(480,800));canvas:setScale(scale)
    canvas:setPosition(cc.p(origin.x+(size.width-480*scale)/2,origin.y+(size.height-800*scale)/2));self:addChild(canvas)
    self.coherentCanvas=canvas
    local height=math.min(584,220+math.max(1,#materials)*122);local bottom=(800-height)/2
    self.coherentSheetBounds={bottom=bottom,top=bottom+height,height=height}
    local paper=W.panel(416,height,W.colors.paper);paper:setPosition(cc.p(32,bottom));canvas:addChild(paper)
    lackLabel(canvas,'备齐所需材料',27,52,bottom+height-38,300)
    self.coherentClose=lackButton(canvas,'关闭',66,395,bottom+height-38,function()
        if self.coherentDisposed or self._dialogueClosing then return end
        self:close()
    end)
    lackLabel(canvas,'查看缺口，选择已开放的获取方式',17,52,bottom+height-78,376,W.colors.muted)
    self.coherentContent=cc.Node:create();canvas:addChild(self.coherentContent)
    lackObserverId=lackObserverId+1;local name='coherentLack'..lackObserverId
    local keys={rolePack,roleMoney,roleProducerQueue,roleGuideStep,roleStore}
    for _,key in ipairs(keys) do dm:registerEvent(key,name,function()
        if not self.coherentDisposed and not self.coherentBusy and not self._dialogueClosing then self:refreshCoherentLack() end
    end) end
    local owner=cc.Node:create();self:addChild(owner)
    owner:registerScriptHandler(function(event)
        if event=='cleanup' then
            self.coherentDisposed=true
            for _,key in ipairs(keys) do
                dm:unregisterEvent(key,name)
                local bucket=dm.__eventListener and dm.__eventListener[key]
                if bucket then bucket[name]=nil end
            end
        end
    end)
    self:refreshCoherentLack();return true
end
function Lackmaterial:coherentLackRoute(route)
    if self.coherentDisposed or self._dialogueClosing then return end
    self.coherentDisposed=true
    DialogueViewManager:sharedInstance():removeAllView()
    if route=='production' then zqDispatch:moveToResource()
    elseif route=='alchemy' then zqDispatch:moveToRepository()
    else zqDispatch:moveToExpedition() end
end
function Lackmaterial:refreshCoherentLack()
    if self.coherentDisposed or self._dialogueClosing then return end
    local W=require 'LuaClass/WarmTheme';local dm=DataManager:getInstance();local guide=GuideController:getInstance()
    local parent=self.coherentContent;parent:removeAllChildren();self.coherentGeneration=(self.coherentGeneration or 0)+1
    local generation=self.coherentGeneration;local materials=self.coherentMaterials;local bounds=self.coherentSheetBounds
    self.coherentRows={}
    local function valid()return not self.coherentDisposed and not self._dialogueClosing and not self.coherentBusy and generation==self.coherentGeneration end
    local list=cc.TableView:create(cc.size(376,bounds.height-180));list:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    list:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN);list:setPosition(cc.p(52,bounds.bottom+80));list:setDelegate()
    list:registerScriptHandler(function()return #materials end,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    list:registerScriptHandler(function()return 122,376 end,cc.TABLECELL_SIZE_FOR_INDEX)
    list:registerScriptHandler(function(tableview,index)
        index=index+1;local row=materials[index];local id=tostring(row.mtId)
        local cell=tableview:dequeueCell() or cc.TableViewCell:create();cell:removeAllChildren()
        local have=lackStock(dm,id);local need=self.coherentRequired[id];local missing=math.max(0,need-have)
        local prices=dm:getStoreUnlockTable() or {};local source=ProductionSources.find(dm,guide,id)
        local mode=id=='1001' and 'alchemy' or ((tonumber(row.mtStar) or 0)>6 and 'explore' or (tonumber(row.mtonlyProduce)==1 and 'production' or (prices[id] and 'buy' or 'explore')))
        local cost=missing*(tonumber(row.mtprice) or 0)
        local panel=W.panel(376,114,W.colors.white);panel:setPosition(cc.p(0,4));cell:addChild(panel)
        lackLabel(cell,row.mtname,21,14,92,246)
        lackLabel(cell,'拥有 '..have..' / 需要 '..need,17,14,64,246,W.colors.muted)
        local caption=missing==0 and '材料已备齐' or ('还缺 '..missing..' 个')
        if missing>0 then
            if mode=='buy' then caption=caption..' · '..cost..' 金币'
            elseif mode=='alchemy' then caption=caption..' · 可通过炼金获得'
            elseif mode=='production' then caption=source and (caption..' · 安排工人生产') or '暂无已解锁的生产途径'
            else caption=caption..' · 出征探索获得' end
        end
        lackLabel(cell,caption,16,14,33,246,missing>0 and W.colors.coral or W.colors.sea)
        local state={id=id,have=have,need=need,missing=missing,mode=mode,cost=cost};self.coherentRows[index]=state
        if missing>0 and (mode~='production' or source) then
            local text=mode=='buy' and '购买' or (mode=='alchemy' and '去炼金' or (mode=='production' and '生产' or '出征'))
            state.button=lackButton(cell,text,92,316,61,function()
                if not valid() then return end
                if mode=='buy' then
                    if not guide:getIsHaveStep(5) then self:close();ToastUtil:toastString('市场还未建造，不能购买');return end
                    if not (dm:getStoreUnlockTable() or {})[id] then self:refreshCoherentLack();return end
                    local currentMissing=math.max(0,need-lackStock(dm,id))
                    if currentMissing~=missing then self:refreshCoherentLack();return end
                    self.coherentBusy=true
                    local result=dm:addCoin(-cost)
                    if result==0 then self:close();ToastUtil:toastString('金币不足')
                    else
                        dm:addPackItemWithId(id,missing);ToastUtil:toastString('购买成功！'..row.mtname..'+'..missing)
                        table.remove(materials,index)
                        if self.coherentCallback then self.coherentCallback() end
                        if #materials==0 then self:close() end
                    end
                    self.coherentBusy=false
                    if #materials>0 then self:refreshCoherentLack() end
                elseif mode=='production' then
                    if ProductionSources.find(dm,guide,id) then self:coherentLackRoute(mode) else self:refreshCoherentLack() end
                else self:coherentLackRoute(mode) end
            end,false)
        end
        return cell
    end,cc.TABLECELL_SIZE_AT_INDEX)
    parent:addChild(list);list:reloadData();self.coherentTable=list
    local source=ProductionSources.first(dm,guide,materials)
    if source then
        self.coherentProduction=lackButton(parent,'查看生产',160,240,bounds.bottom+34,function()
            if valid() and ProductionSources.first(dm,guide,materials) then self:coherentLackRoute('production') end
        end)
    else lackLabel(parent,#materials==0 and '材料已备齐，请返回继续' or '返回后可继续原来的建设或制造',17,52,bounds.bottom+34,376,W.colors.muted) end
end
