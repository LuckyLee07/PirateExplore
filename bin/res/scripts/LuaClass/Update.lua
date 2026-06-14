--require "LuaClass/Header"
require "json"
require "LuaClass/SaveDataManager"
require "LuaClass/HttpSingleton"
require "LuaClass/CSVParser"
require "LuaClass/SDResourceManager"

--cc.FileUtils:getInstance():addSearchPath("LuaClass")
--cc.FileUtils:getInstance():addSearchResolutionsOrder(cc.FileUtils:getInstance():getWritablePath())

local kHttpRequestFieldNum = 1

Update = class("Update", function ()
    return cc.Layer:create()
end)

Update.__index = Update
Update.centerPos = cc.p(0, 0)
Update.titleLabel = nil
Update.DownloadTable = nil
Update.DownloadNum = 0
Update.HasLoad = 0
Update.TotalSize = 0
Update.FinishSize = 0
Update.IsloadingFile = nil
Update.IsloadingFileMD5 = nil
Update.UpdateState = {checking = 1, downloading = 2, finished = 3 }
Update.state = Update.UpdateState.checking
Update.serverAddress = "http://113.31.128.35:11300"
Update.path = nil


-- 本类函数
local requestFile					= nil
local requestresources				= nil

local function jumpToController()
    print("更新完成(不一定成功)，去主逻辑")
    require "LuaClass/controller"
    startGame()
end

function Update:create()
    local Updatelayer = Update.new()
    if Updatelayer and Updatelayer:init() then
        return Updatelayer
    end
    return nil
end

function Update:destory()
    if self:getParent() ~= nil then
        self:removeFromParent()
    end
-- cc.Director:getInstance():setNotificationNode(nil)
end

local function CheackUpdate()
    Update.HasLoad = Update.HasLoad + 1
    if Update.HasLoad > Update.DownloadNum then
        Update.state = Update.UpdateState.finished
    else
        local temp = Update.DownloadTable[Update.HasLoad]

        print("TT -------- **** ", Update.HasLoad, Update.DownloadTable[Update.HasLoad], #temp, temp["name"], temp["md5"])
        Update.IsloadingFile = temp["name"]
        Update.IsloadingFileMD5 = temp["md5"]
        local _isExist = getIsDownloadExistFile(Update.IsloadingFile,temp["md5"])
        if _isExist then
            CheackUpdate()
        else
            requestFile(Update.IsloadingFile)
        end
    end
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------


-- 如果返回的是 json 德table 数据，这里解析
local function  parselua( data )
    table.foreach(data,
    function(key, var)
-- print("key = "..key)
        if ("table" == type(var) ) then
            parselua(var)
        else
-- print("value = "..var)
        end
    end)
end

----------------------------HTTP请求借口----------------------------------------------------
-------------------------------------------------------------------------------------------
----------------------- 请求resources.csv
requestresources = function()
    local tmp = HttpSingleton:getInstance()

    local function callback(xhr)
        local event = cc.EventCustom:new("requestresources")
        event._usedata = xhr.response
        local  temp = cc.Director:getInstance():getNotificationNode():getEventDispatcher()
        temp:dispatchEvent(event)
        print("post callback code = "..xhr.statusText)
    end

    local type = tmp.POST
    local url = Update.serverAddress..Update.path.."resources.csv"   --/pirateup/common/resource/91/  -- resources.csv
    local dataPost = {}
    dataPost.type = "local"
    tmp:send(type, url, dataPost, callback)
end


----------------------- 请求下载具体文件
requestFile = function( path)

    local tmp = HttpSingleton:getInstance()

    local function callback(xhr)
        local event = cc.EventCustom:new("requestFile")
        event._usedata = xhr.response
        local  temp = cc.Director:getInstance():getNotificationNode():getEventDispatcher()
        temp:dispatchEvent(event)
        print("post callback code = "..xhr.statusText)
    end

    local type = tmp.GET
    local url = Update.serverAddress..Update.path..path
    print("path = === "..url)
    local dataPost = {}
    dataPost.type = "local"
    tmp:send(type, url, dataPost, callback)
end


-- 网络测试函数
local function testSingletonPost()

    local tmp = HttpSingleton:getInstance()

    local function callback(xhr)
        if xhr.response == "" then
            if kHttpRequestFieldNum < 3 then
                print("http请求失败，重试！"..kHttpRequestFieldNum)
                testSingletonPost()
                kHttpRequestFieldNum = kHttpRequestFieldNum + 1
            else
                print("无法更新游戏资源，直接进入游戏")
                jumpToController()
                return
            end
        else
            local event = cc.EventCustom:new("getupdatepath")
            event._usedata = xhr.response
            local  temp = cc.Director:getInstance():getNotificationNode():getEventDispatcher()
            temp:dispatchEvent(event)
            print("post callback code = "..xhr.statusText)
        end
    end

    local type = tmp.POST
    local url = "http://113.31.128.35:11300/pirateup/common/getversion.jsp"
    local dataPost = {}
    dataPost.type = "local"
    tmp:send(type, url, dataPost, callback, kHttpRequestFieldNum)

end

--[[
local function testSingletonPost()

    local tmp = HttpSingleton:getInstance()

    local function callback(xhr)
        local event = cc.EventCustom:new("customEvent1")
        event._usedata = xhr.response
        local  temp = Httptest:getInstance()
        temp.eventDispatcher:dispatchEvent(event)
        print("post callback code = "..xhr.statusText)
    end

    local type = tmp.POST
    local url = "http://192.168.1.143:11099/pirateup/common/getversion.jsp"
    local dataPost = {}
    dataPost.type = "local"
    tmp:send(type, url, dataPost, callback)
end
]]--
----------------------------HTTP回调借口----------------------------------------------------
-------------------------------------------------------------------------------------------

----------------------- 创建自定义事件 Http返回path路径
local function HTTPCallback_getupdatepath(event)
    local str = "response: "..event._usedata
    local basestr = event._usedata
    local data =  json.decode(basestr)
    print("HTTPCallback_getupdatepath"..basestr)
    -- 请求根据返回的路径获取resource.csv
    Update.path = data["path"]
    print("return path:"..Update.path)
    requestresources()
    gotoMainUI()
end

----------------------- 创建自定义事件 Http返回resources.csv的文件内容
local function HTTPCallback_getresource_csv(event)
    local str = "response: "..event._usedata
    local basestr = event._usedata
    local _csvMd5 = MD5(basestr, string.len(basestr)):hexdigest()
    print("_resource_csvMd5 = ".._csvMd5)
    if updateWrite == 1 then
        local filename = cc.FileUtils:getInstance():getWritablePath().."resources.csv"
        local file = io.open(filename,"w")
        file:write(basestr)
        file:close()
        SaveDataManager:getInstance():loadRecourcesCSV(filename)
    end
    
    local parser = CSVParser:getInstance()


    local csvtable = parser:loadCSVFileByString(basestr)


    Update.DownloadTable = customTableToIKey(csvtable)
    Update.DownloadNum = #Update.DownloadTable
    for i=1,#Update.DownloadTable do
        local data = Update.DownloadTable[i]
        local isExist = getIsDownloadExistFile(data.name, data.md5)
        if not isExist then
            if data.filesize ~= nil then
                Update.TotalSize = Update.TotalSize+tonumber(data.filesize)
            end
        end
    end

    Update.state = Update.UpdateState.downloading

    CheackUpdate()
-- requestFile(_name1)
-- 初始化游戏主UI界面
-- gotoMainUI()
end

----------------------- 创建自定义事件 Http返回下载的文件内容
local function HTTPCallback_getFile(event)
    local basestr = event._usedata
    local _csvMd5 = MD5(basestr, string.len(basestr)):hexdigest()
    print("_csvMd5 = ".._csvMd5)
    local data = Update.DownloadTable[Update.HasLoad]
    if _csvMd5 == Update.IsloadingFileMD5 then
        if updateWrite == 1 then
            local filename = cc.FileUtils:getInstance():getWritablePath()..Update.IsloadingFile
            local fp = io.open(filename , "wb")
            if fp then
                fp:write(basestr)
                fp:close()
            end
        end
        if data.filesize ~= nil then
            Update.FinishSize = Update.FinishSize+data.filesize
        end
        CheackUpdate()
    else
        -- 异常处理— 重新下载该文件
        requestFile(Update.IsloadingFile)
    end
end


-- 将事件分配器赋值到HttpSingleton.eventDispatcher
-- 用来在http请求返回的回调函数中使用，因为回调函数是在异步线程中执行，必须用自定义事件更新ui线程数据
local tmpHttp = HttpSingleton:getInstance()
tmpHttp.eventDispatcher = eventDispatcher
----------------------- 创建自定义事件 end


function Update:init()
    cc.Director:getInstance():setNotificationNode(self)
--[[
    local listener1 = cc.EventListenerCustom:create("getupdatepath",HTTPCallback_getupdatepath)
    cc.Director:getInstance():getNotificationNode():getEventDispatcher():addEventListenerWithFixedPriority(listener1, 6)
    local listener2 = cc.EventListenerCustom:create("requestresources",HTTPCallback_getresource_csv)
    cc.Director:getInstance():getNotificationNode():getEventDispatcher():addEventListenerWithFixedPriority(listener2, 6)
    local listener3 = cc.EventListenerCustom:create("requestFile",HTTPCallback_getFile)
    cc.Director:getInstance():getNotificationNode():getEventDispatcher():addEventListenerWithFixedPriority(listener3, 6)
]]--
    local visibleSize = cc.Director:getInstance():getVisibleSize()

    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGB888)
    local bg = cc.Sprite:create("Images/UI/fm_01.png")
    bg:setPosition(cc.p(visibleSize.width / 2, visibleSize.height / 2))
    self:addChild(bg)

    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGB5A1)
    local title = cc.Sprite:create("Images/UI/logo_01.png")
    title:setPosition(cc.p(bg:getPositionX(),visibleSize.height * 0.9 - title:getContentSize().height * title:getScaleY() / 2))
    self:addChild(title)

    local waves = cc.Sprite:create("Images/UI/fmloding_02.png")
    waves:setPosition(cc.p(visibleSize.width * 0.5,visibleSize.height * 0.15))
    self:addChild(waves)
    self.progressBarWidth = waves:getContentSize().width
--[[
    self.tip = cc.LabelTTF:create("检测中...", "Arial-BoldMT", 26.0)
    self.tip:setPosition(cc.p(bg:getPositionX(),waves:getPositionY() - waves:getContentSize().height / 2 - self.tip:getContentSize().height))
    self:addChild(self.tip)
]]--
    self.progressBar = cc.Sprite:create("Images/UI/fmloding_03.png")
    self.progressBar:setAnchorPoint(cc.p(0,0.5))
    self.progressBar:setPosition(cc.p(waves:getPositionX() - waves:getContentSize().width * waves:getScaleX() / 2,waves:getPositionY()))
    self:addChild(self.progressBar)
    self.progressBar:setTextureRect(cc.rect(0, 0, 0,self.progressBar:getContentSize().height))

    self.ship = cc.Sprite:create("Images/UI/fmloding_01.png")
    self.ship:setAnchorPoint(0.5, 0.0)
    self.ship:setPosition(cc.p(self.progressBar:getPositionX(), self.progressBar:getPositionY()))
    self:addChild(self.ship)
    self.ship:runAction(cc.Sequence:create(cc.FadeOut:create(0.0),cc.EaseExponentialOut:create(cc.FadeIn:create(1.0))))

    -- 添加提示文字内容
    local updateTip = cc.LabelTTF:create("联网游戏可以获取离线资源，占用流量极少", "Arial-BoldMT", 26.0)
    updateTip:setPosition(cc.p(bg:getPositionX(),waves:getPositionY() + waves:getContentSize().height / 2 + self.ship:getContentSize().height + updateTip:getContentSize().height))
    self:addChild(updateTip)

    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)

    -- 添加船移动效果
    local rate = 0
    local finishSize  = 0
    local totalSize = 100
    
    function update()
        rate = rate + 5
        finishSize = rate

        if rate > 100 then rate = 100 end
        local posx = self.progressBar:getPositionX()
        self.ship:setPositionX(posx+0.01*rate*self.progressBarWidth)
        local newRect = cc.rect(0, 0, 0.01*rate*self.progressBarWidth, self.progressBar:getContentSize().height)
        self.progressBar:setTextureRect(newRect)

        if finishSize >= totalSize then
            self:stopAllActions()
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.05), cc.CallFunc:create(jumpToController)))
        end
    end
    schedule(self, update, 0.0)

    return true;
end

--xpcall(main, __G__TRACKBACK__)