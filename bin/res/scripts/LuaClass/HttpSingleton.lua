require "json"  
  
HttpSingleton = {}  
HttpSingleton.__index = HttpSingleton  
HttpSingleton.instance = nil  
HttpSingleton.callback = nil  
HttpSingleton.POST = "POST"  
HttpSingleton.GET = "GET"  


function HttpSingleton:new()  
    local self = {}  
    setmetatable(self,HttpSingleton)  
    return self  
end  
  
function HttpSingleton:getInstance()  
    if nil == self.instance then  
        self.instance = self:new()  
    end  
    return self.instance  
end  
  
-- 数据转换，将请求数据由 table 型转换成 string，参数：table  
function HttpSingleton:dataParse(data)  
    if "table" ~= type(data) then  
        --print("data is not a table")  
        return nil  
    end  
  
    local tmp = {}  
    for key, value in pairs(data) do  
        table.insert(tmp,key.."="..value)  
    end  
  
    local newData = ""  
    for i=1,#tmp do  
        newData = newData..tostring(tmp[i])  
        if i<#tmp then  
            newData = newData.."&&"  
        end  
    end  
    --print("------- name is "..newData)  
    return newData  
end  
  
-- 发送数据，参数：string，string，table  
function HttpSingleton:send(type, url, data, callback, timeout)
    if timeout == nil then
        timeout = 6
    end
    local xhr = cc.XMLHttpRequest:new() --new 一个http request 实例
    -- 设置请求超时时间 by 杨杰
    xhr.timeout = timeout
    self.callback = callback    --设置需要执行的函数
      
    local newData = self:dataParse(data)  
    if nil == newData or "" == newData then  
        return   
    end  
      
    -- response回调函数  
    local function responseCallback()  
        --print("httpSingleton - "..xhr.response)  
        if nil ~= self.callback then  
            self.callback(xhr)  
        else  
            --print("callback is nil")  
        end  
    end  
  
    -- 设置返回值类型及回调函数
    if self.POST == type then
        xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    elseif self.GET == type then
        xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    end

     xhr:registerScriptHandler(responseCallback)  
           
    -- 请求方式判断  
--    if self.POST == type then
        xhr:open(self.POST, url)  
        xhr:registerScriptHandler(responseCallback)  
        xhr:send(newData)
--    elseif self.GET == type then
--        xhr:open(self.GET, url.."?"..newData)
--        xhr:send()
--    else
--        --print("ERROR : type only can be \"Post\" or \"GET\"")
--    end
end  