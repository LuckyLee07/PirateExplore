require "LuaClass/Header"
require "LuaClass/UIKit"
require "LuaClass/DialogueView"
require "LuaClass/DataManager"
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
     local size = cc.Director:getInstance():getVisibleSize()

    -- background
    -- local bg = cc.Sprite:create("Images/UI/tankuang_01.png")
    
    local datanum = #lacktable
    print("datanum",datanum)
    local temp = cc.Sprite:create("Images/UI/tankuang_01.png")
    local bg = cc.Scale9Sprite:create("Images/UI/tankuang_01.png")
    bg:setPreferredSize(cc.size(temp:getContentSize().width, 460 + 120 * (datanum - 1)))


    bg:setAnchorPoint(cc.p(0.5, 0.5))

    self:addChild(bg)
    bg:setPosition(cc.p(0.5*size.width, 0.5*size.height ))

    --title
    local title = nil

    title = cc.LabelTTF:create("材料获得",BoldFont,36)

    title:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()+bg:getContentSize().height/2-34))
    title:setColor(WriteColor)
    -- title:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    self:addChild(title)



    local btn = cc.MenuItemImage:create("Images/UI/cancel_button.png", "Images/UI/cancel_button.png")
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

    local _title2 = cc.LabelTTF:create("您可以通过以下方式获得",BoldFont,_fontSize+2)
    _title2:setPosition(cc.p(title:getPositionX(),title:getPositionY()-62 - 30 * datanum))
    _title2:setColor(WriteColor)
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
        print("lacktable[i].mtID",lacktable[i].mtId)
        local _title1 = cc.LabelTTF:create("当前缺少"..lacktable[i].mtnum.."个"..lacktable[i].mtname,BoldFont,_fontSize)
        _title1:setPosition(cc.p(title:getPositionX(),title:getPositionY()-62 - 30 * (i - 1)))
        _title1:setColor(WriteColor)
       -- _title1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        self:addChild(_title1)


        

        local _back1 = cc.Sprite:create("Images/UI/dibantiao_03.png")
        _back1:setPosition(cc.p(_title2:getPositionX(),_title2:getPositionY()-85 - 118 * (i - 1)))
        self:addChild(_back1)
        local needcoin

        if type == 0 then
            local _back1Font1 = cc.LabelTTF:create("购买"..lacktable[i].mtnum.."个"..lacktable[i].mtname,BoldFont,_fontSize)
            _back1Font1:setAnchorPoint(cc.p(0,0))
            _back1Font1:setColor(WriteColor)
            -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
            self:addChild(_back1Font1)

            needcoin = tonumber(lacktable[i].mtnum) * tonumber(lacktable[i].mtprice)
            local _back1Font2 = cc.LabelTTF:create("花费"..tostring(needcoin).."金币",BoldFont,_fontSize)
            _back1Font2:setAnchorPoint(cc.p(0,1))
            _back1Font2:setColor(WriteColor)
            -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
            self:addChild(_back1Font2)
        elseif type == 1 then
            local _back1Font1 = cc.LabelTTF:create("缺少"..lacktable[i].mtnum.."个"..lacktable[i].mtname,BoldFont,_fontSize)
            _back1Font1:setAnchorPoint(cc.p(0,0))
            _back1Font1:setColor(WriteColor)
            -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
            self:addChild(_back1Font1)

            local _back1Font2 = cc.LabelTTF:create("可通过炼金获得",BoldFont,_fontSize)
            _back1Font2:setAnchorPoint(cc.p(0,1))
            _back1Font2:setColor(WriteColor)
            -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
            self:addChild(_back1Font2)
        elseif type == 2 then
            local _back1Font1 = cc.LabelTTF:create("缺少"..lacktable[i].mtnum.."个"..lacktable[i].mtname,BoldFont,_fontSize)
            _back1Font1:setAnchorPoint(cc.p(0,0))
            _back1Font1:setColor(WriteColor)
            -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
            self:addChild(_back1Font1)

            local _back1Font2 = cc.LabelTTF:create("需要通过探索获得",BoldFont,_fontSize)
            _back1Font2:setAnchorPoint(cc.p(0,1))
            _back1Font2:setColor(WriteColor)
            -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
            self:addChild(_back1Font2)
        elseif type == 3 then
            local _back1Font1 = cc.LabelTTF:create("缺少"..lacktable[i].mtnum.."个"..lacktable[i].mtname,BoldFont,_fontSize)
            _back1Font1:setAnchorPoint(cc.p(0,0))
            _back1Font1:setColor(WriteColor)
            -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
            self:addChild(_back1Font1)

            local _back1Font2 = cc.LabelTTF:create("该物品只能通过生产获得",BoldFont,_fontSize)
            _back1Font2:setAnchorPoint(cc.p(0,1))
            _back1Font2:setColor(WriteColor)
            -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
            self:addChild(_back1Font2)
        elseif type == 4 then
            local _back1Font1 = cc.LabelTTF:create("缺少"..lacktable[i].mtnum.."个"..lacktable[i].mtname,BoldFont,_fontSize)
            _back1Font1:setAnchorPoint(cc.p(0,0))
            _back1Font1:setColor(WriteColor)
            -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
            self:addChild(_back1Font1)

            local _back1Font2 = cc.LabelTTF:create("当前无法获得，需出征探索海域",BoldFont,_fontSize)
            _back1Font2:setAnchorPoint(cc.p(0,1))
            _back1Font2:setColor(WriteColor)
            -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
            self:addChild(_back1Font2)
        end
        --
        


        

        --button
        local _buyButton = cc.MenuItemImage:create("Images/btn/ann01_a.png","Images/btn/ann01_b.png")
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
                self:close()
                zqDispatch:moveToResource()
                -- 去生产
            elseif type == 4 then 
                self:close()
                zqDispatch:moveToExpedition()
                -- 去出征
            end

        end)


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
        local _buyLabel = cc.LabelTTF:create(desstr, BoldFont, 32.0)
        -- _buyLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        _buyLabel:setColor(cc.c3b(255,255,255))
        _buyLabel:setPosition(_buyButton:getPosition())
        self:addChild(_buyLabel)

    end
        
    local _back2 = cc.Sprite:create("Images/UI/dibantiao_03.png")
    _back2:setPosition(cc.p(_title2:getPositionX(),_title2:getPositionY()-85 - 118 * datanum  ))
    self:addChild(_back2)
    local _back2Font1 = cc.LabelTTF:create("生产：需花费一些时间",BoldFont,_fontSize)
    _back2Font1:setAnchorPoint(cc.p(0,0.5))
    _back2Font1:setColor(WriteColor)
    -- _back2Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    _back2Font1:setPosition(cc.p(_back2:getPositionX()-_back2:getContentSize().width/2+22,_back2:getPositionY()))
    self:addChild(_back2Font1)

    
    local _produceButton = cc.MenuItemImage:create("Images/btn/ann01_a.png","Images/btn/ann01_b.png")
    _produceButton:setPosition(cc.p(_back2:getPositionX()+_back2:getContentSize().width/2-90,_back2:getPositionY()))
    _produceButton:registerScriptTapHandler(function()
        --生产
        --关闭所有窗口
        --self:close()
if DataManager:getInstance():getSound_off() == 0 then
AudioEngine.playEffect(EFFECT_Button, false)
end
        DialogueViewManager:sharedInstance():removeAllView()
        zqDispatch:moveToResource()
    end)
    
    

    local producemenuIcon = cc.Menu:create(_produceButton)
    producemenuIcon:setPosition(0.0, 0.0)
    self:addChild(producemenuIcon)

    local _produceButtonLabel = cc.LabelTTF:create("生 产", BoldFont, 32.0)
    -- _produceButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    _produceButtonLabel:setColor(cc.c3b(255,255,255))
    _produceButtonLabel:setPosition(_produceButton:getPosition())
    self:addChild(_produceButtonLabel)

    return true

end

-- init
function Lackmaterial:reflush(lacktable,callback)
    self:removeAllChildren(true);
    self:init(lacktable,callback)
end

