--#!/usr/local/bin/lua50
--require "LuaClass/md5"

-- 参数:待分割的字符串,分割字符
-- 返回:子串表.(含有空串)
function getIsDownloadExistFile(fileName, fileMD5)
	local writepath = cc.FileUtils:getInstance():getWritablePath()
	
	local path = writepath..fileName;
	print("writepath = "..path);
	local isExist = cc.FileUtils:getInstance():isFileExist(path);
-- 如果存在验证数据有效性
	if true == isExist then
        local _md5 = getFileMD5(path)
        if _md5 ~= fileMD5 then
            isExist = false
        end
    end
	return isExist
end
