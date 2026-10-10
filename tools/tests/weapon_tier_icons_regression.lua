-- Real CSVParser and Utils implementations, no mock resource identities.
require=function()return true end
class=function()return {} end
local unavailable={}
cc={FileUtils={getInstance=function()return {isFileExist=function(_,path)
    if unavailable[path]then return false end
    local f=io.open('bin/res/assets/'..path,'rb');if f then f:close();return true end;return false
end}end}}
dofile('bin/res/scripts/LuaClass/Utils.lua')
dofile('bin/res/scripts/LuaClass/CSVParser.lua')
local f=assert(io.open(arg[1],'rb'));local bytes=f:read('*a');f:close()
local rows=CSVParser:loadCSVFileByString(bytes)
local R=dofile('bin/res/scripts/LuaClass/ResourceTheme.lua')
local expected={['1053']='steel-sword-1053.png',['1073']='sacred-silver-sword-1073.png'}
local before={}
for id,row in pairs(rows)do before[id]={};for k,v in pairs(row)do before[id][k]=v end end
assert(rows['1053'].name=='钢剑' and rows['1073'].name=='圣银长剑')
local aliases={['1049']=true,['1053']=true,['1065']=true,['1069']=true,['1073']=true,['1081']=true,['1083']=true}
local aliasCount=0
for id,row in pairs(rows)do if row.iconName=='w_12.png' then assert(aliases[id]);aliasCount=aliasCount+1 end end
assert(aliasCount==7)
assert(R.applyIcons(rows)==17 and R.applyIcons(rows)==0)
for id,name in pairs(expected)do
    assert(rows[id].iconName=='B/'..name)
    for _,case in ipairs({{ID='9999',iconName='w_12.png'},{ID=id},{ID=id,iconName=''},
        {ID=id,iconName='unexpected.png'},{ID=id,iconName='B/iron-sword-1049.png'}})do
        local icon=case.iconName;assert(R.applyIcons({[id]=case})==0 and case.iconName==icon)
    end
    unavailable['Images/Icon/B/'..name]=true
    local missing={ID=id,iconName='w_12.png'}
    assert(R.applyIcons({[id]=missing})==0 and missing.iconName=='w_12.png')
    unavailable['Images/Icon/B/'..name]=nil
    local numeric={ID=tonumber(id),iconName='w_12.png'}
    assert(R.applyIcons({[id]=numeric})==1 and numeric.iconName=='B/'..name)
end
for _,id in ipairs({'1065','1069','1081','1083'})do assert(rows[id].iconName=='w_12.png')end
assert(rows['1049'].iconName=='B/iron-sword-1049.png')
assert(rows['1011'].iconName=='B/r_8.png', 'steel material is separate from equipment')
for id,row in pairs(rows)do
    for k,v in pairs(before[id])do if k~='iconName' then assert(row[k]==v,'changed gameplay field '..id..'/'..k)end end
    if not R.icons[id] and not R.itemIcons[id]then assert(row.iconName==before[id].iconName,'unmapped identity changed')end
end
print('PASS real seven-alias audit, 1053/1073 exact guards, all non-icon fields, remaining aliases, 1011 material, absent/wrong-ID/nil/path/idempotent fallbacks')
