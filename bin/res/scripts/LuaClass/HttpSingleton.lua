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
  
-- JSON4Lua's decoder accepts missing separators/trailing text, arithmetic
-- expressions and comments, and silently drops null array elements. Validate
-- this endpoint's complete non-null JSON response before using that decoder.
-- This is a conservative decoder-compatible subset, not a replacement for a
-- standards-compliant service parser. Raw UTF-8 works; Unicode escapes and any
-- syntax the packaged decoder cannot consume fail closed. Never patch globals.
function HttpSingleton:decodeResponse(text)
    assert(type(text) == "string", "Response must be JSON text")
    local pos, length = 1, #text
    local function peek() return text:sub(pos, pos) end
    local function whitespace()
        while pos <= length and text:sub(pos, pos):match("[ \t\r\n]") do pos = pos + 1 end
    end
    local function scanString()
        assert(peek() == '"', "JSON strings must use double quotes")
        local start = pos
        pos = pos + 1
        while pos <= length do
            local char = peek()
            pos = pos + 1
            if char == '"' then return text:sub(start, pos - 1) end
            assert(char:byte() >= 32, "Unescaped control character")
            if char == "\\" then
                local escape = peek()
                pos = pos + 1
                if escape == "u" then
                    -- JSON4Lua evaluates strings as Lua literals, so it would
                    -- corrupt Unicode escapes (including escaped status keys).
                    -- Raw UTF-8 remains supported; reject this unsupported form.
                    error("Unicode escapes are unsupported by the packaged decoder")
                else
                    assert(escape ~= "" and ('"\\/bfnrt'):find(escape, 1, true), "Invalid JSON escape")
                end
            end
        end
        error("Unterminated JSON string")
    end
    local scanValue
    scanValue = function(depth)
        assert(depth <= 64, "JSON response is too deeply nested")
        whitespace()
        local char = peek()
        if char == '"' then
            scanString()
            return {kind="string"}
        elseif char == "{" then
            pos = pos + 1; whitespace()
            local keys, shape = {}, {kind="object", fields={}}
            if peek() == "}" then pos = pos + 1; return shape end
            while true do
                local encodedKey = scanString()
                local key = json.decode(encodedKey)
                assert(not keys[key], "Duplicate JSON object key")
                keys[key] = true
                whitespace(); assert(peek() == ":", "Missing JSON colon")
                pos = pos + 1; shape.fields[key] = scanValue(depth + 1); whitespace()
                if peek() == "}" then pos = pos + 1; return shape end
                assert(peek() == ",", "Missing JSON object separator")
                pos = pos + 1; whitespace()
            end
        elseif char == "[" then
            pos = pos + 1; whitespace()
            if peek() == "]" then pos = pos + 1; return {kind="array"} end
            while true do
                scanValue(depth + 1); whitespace()
                if peek() == "]" then pos = pos + 1; return {kind="array"} end
                assert(peek() == ",", "Missing JSON array separator")
                pos = pos + 1
            end
        elseif text:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return {kind="boolean"}
        elseif text:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return {kind="boolean"}
        else
            -- Reject null rather than let the legacy decoder silently change
            -- a list's shape or drop an explicitly supplied status field.
            local start = pos
            if char == "-" then pos = pos + 1 end
            if peek() == "0" then
                pos = pos + 1
            else
                assert(peek():match("[1-9]"), "Missing JSON value")
                repeat pos = pos + 1 until not peek():match("%d")
            end
            if peek() == "." then
                pos = pos + 1; assert(peek():match("%d"), "Missing fractional digits")
                repeat pos = pos + 1 until not peek():match("%d")
            end
            if peek() == "e" or peek() == "E" then
                pos = pos + 1
                if peek() == "+" or peek() == "-" then pos = pos + 1 end
                assert(peek():match("%d"), "Missing exponent digits")
                repeat pos = pos + 1 until not peek():match("%d")
            end
            local number = tonumber(text:sub(start, pos - 1))
            assert(number and number == number and number ~= math.huge and number ~= -math.huge, "Nonfinite JSON number")
            return {kind="number"}
        end
    end
    local shape = scanValue(1); whitespace()
    assert(pos == length + 1, "Trailing JSON data")
    local value, nextPos = json.decode(text)
    assert(type(nextPos) == "number" and text:sub(nextPos):match("^[ \t\r\n]*$"), "Incomplete JSON decode")
    return value, shape
end

-- 发送数据，参数：string，string，table  
function HttpSingleton:send(type, url, data, callback, timeout)
    if timeout == nil then
        timeout = 6
    end
    local xhr = cc.XMLHttpRequest:new() --new 一个http request 实例
    -- 设置请求超时时间 by 杨杰
    xhr.timeout = timeout
    -- Capture this request's callback; other in-flight requests share the singleton.
      
    local newData = self:dataParse(data)  
    if nil == newData or "" == newData then  
        return   
    end  
      
    -- response回调函数  
    local function responseCallback()  
        --print("httpSingleton - "..xhr.response)  
        if nil ~= callback then
            callback(xhr)
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
