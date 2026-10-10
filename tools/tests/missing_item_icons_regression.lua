-- Invoked by Python with independently decoded packaged CSV bytes.
require=function()return true end
class=function()return {} end
cc={FileUtils={getInstance=function()return {isFileExist=function(_,path)
    local f=io.open('bin/res/assets/'..path,'rb');if f then f:close();return true end;return false
end}end}}
dofile('bin/res/scripts/LuaClass/Utils.lua')
dofile('bin/res/scripts/LuaClass/CSVParser.lua')
local f=assert(io.open(arg[1],'rb'));local bytes=f:read('*a');f:close()
local rows=CSVParser:loadCSVFileByString(bytes)
assert(type(rows['1039'].iconName)=='string' and rows['1039'].iconName=='', 'real parser empty icon must be empty string, not nil')
assert(rows['1039'].name=='攻城冲车' and rows['1049'].name=='铁剑' and rows['1053'].name=='钢剑')
local before={}
for id,row in pairs(rows)do before[id]={};for k,v in pairs(row)do before[id][k]=v end end
local R=dofile('bin/res/scripts/LuaClass/ResourceTheme.lua')
assert(R.applyIcons(rows)==17 and R.applyIcons(rows)==0)
assert(rows['1039'].iconName=='B/siege-ram-1039.png')
assert(rows['1049'].iconName=='B/iron-sword-1049.png')
for id,row in pairs(rows)do
    for k,v in pairs(before[id])do
        if k~='iconName' then assert(row[k]==v,'non-icon field changed: '..id..'/'..k) end
    end
    if not R.icons[id] and not R.itemIcons[id] then assert(row.iconName==before[id].iconName, 'unmapped alias changed') end
end
assert(rows['1053'].iconName=='B/steel-sword-1053.png' and rows['1053'].resume==before['1053'].resume)
for _,case in ipairs({{ID='1038',iconName=''}, {ID='1039'}, {ID='1039',iconName='unexpected.png'}, {ID='1049',iconName=''}})do
    local icon=case.iconName;assert(R.applyIcons({['1039']=case})==0 and case.iconName==icon)
end
for _,case in ipairs({{ID='1053',iconName='w_12.png'}, {ID='1049'}, {ID='1049',iconName='unexpected.png'}})do
    local icon=case.iconName;assert(R.applyIcons({['1049']=case})==0 and case.iconName==icon)
end
local unknown={['9999']={ID='9999',iconName=''},['1065']={ID='1065',iconName='w_12.png'}}
assert(R.applyIcons(unknown)==0 and unknown['9999'].iconName=='' and unknown['1065'].iconName=='w_12.png')
cc.FileUtils.getInstance=function()return {isFileExist=function()return false end}end
local missing={['1039']={ID='1039',iconName=''},['1049']={ID='1049',iconName='w_12.png'}}
assert(R.applyIcons(missing)==0 and missing['1039'].iconName=='' and missing['1049'].iconName=='w_12.png')
print('PASS real CSVParser empty-string type, 17 guarded mappings, all non-icon fields and shared sword aliases preserved, absent/wrong-ID/nil/wrong-path/unknown/idempotent cases')
