-- Production detail method, authoritative packaged CSV, strict Lua or actual
-- Cocos labels (chart-lifecycle-native). No game scene, save or economy writes.
local root='bin/res/scripts/LuaClass/'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local function equal(a,b,why)assert(a==b,(why or 'value')..': '..tostring(a)..' ~= '..tostring(b))end
local source=read('tools/tests/home_master_regression.lua')
local start=assert(source:find('local function readFile(path)',1,true))
local stop=assert(source:find("\nlocal soldiers=packagedCSV('soilderAttribute')",start,true))
local packagedCSV=assert(loadstring('local equal=...\n'..source:sub(start,stop-1)..'\nreturn packagedCSV','@crew-csv-fixture'))(equal)
local soldiers,skills,buffs=packagedCSV('soilderAttribute'),packagedCSV('skillAttribute'),packagedCSV('buff')
local function snapshot(t)
    local parts={};for k,v in pairs(t)do parts[#parts+1]=tostring(k)..'='..(type(v)=='table' and snapshot(v) or tostring(v))end
    table.sort(parts);return table.concat(parts,'|')
end
local baseline=snapshot({soldiers,skills,buffs})
local native=type(nativeEnter)=='function'
local node,label
if native then
    require('extern')
    node=function()return cc.Node:create()end
    label=function()local n=cc.LabelTTF:create('','Noto Serif CJK SC',24);n:setDimensions(cc.size(640*.8*.9,0));return n end
else
    local endFixture=assert(source:find("\ndofile(root..'Header.lua')",1,true))
    local H=assert(loadstring(source:sub(1,endFixture-1)..'\nreturn {node=node,methods=Node}','@crew-node-fixture'))()
    node=function()return H.node('Node')end
    label=function()return H.node('Label')end
    cc.Director={getInstance=function()return {getVisibleSize=function()return cc.size(640,1136)end,getVisibleOrigin=function()return cc.p(0,0)end}end}
    class=function()return {}end
end
local D=dofile(root..'CrewSkillDetails.lua')
local originalRequire=require
require=function(name)if name=='LuaClass/CrewSkillDetails'then return D end;return true end
for _,name in ipairs({'HomeTheme','MasterTheme','DialogTheme'})do dofile(root..name..'.lua')end
dofile(root..'EventDetailsLayer.lua')
require=originalRequire
csvOfSkillAttribute='skills';csvOfBuff='buffs'
DataManager={getInstance=function(self)return self end,getCSVByID=function(_,id)return ({skills=skills,buffs=buffs})[id]end}
dataController={getSoilderInfoById=function(id)return soldiers[tostring(id)]end,
    getResourceInfoById=function(id)if id=='resource'then return {}end end,
    getResourceValueByIdAndKey=function()return '真实资源描述'end}
local view={infoNode=node(),infoLabel=label(),bottomInfoBox=DialogTheme.card(512,120)}
view.bottomInfoBox:setPosition(cc.p(256,60));view.infoLabel:setPosition(cc.p(256,60))
view.infoNode:addChild(view.bottomInfoBox);view.infoNode:addChild(view.infoLabel,1)
if native then view.infoNode:retain();view.infoLabel:retain()end
local function detail(id,kind)
    view.type=kind;view.data={{id=id,name=(soldiers[tostring(id)] or {}).name or '未知船员',skillName='stale wrong cached name'}}
    EventDetailsLayer.showCellInfo(view,1)
    assert(view.infoNode:isVisible())
    local card=view.bottomInfoBox;local height=card:getContentSize().height
    assert(height>=view.infoLabel:getContentSize().height+32,'detail needs 16px top/bottom padding')
    equal(card:getPositionY()-height/2,0,'detail stays above footer')
    equal(view.infoLabel:getPositionY(),card:getPositionY(),'label stays centered')
    equal(card:getContentSize().width,512,'width unchanged')
    equal(#view.infoNode:getChildren(),2,'repeated detail replaces only background')
    return view.infoLabel:getString()
end
local function contains(s,part)assert(s:find(part,1,true),s..' missing '..part)end
equal(soldiers['144'].skill,'44');equal(skills['44'].name,'标记');equal(skills['44'].buffID,'0');assert(not buffs['44'])
local counts={zero=0,buff=0,collision=0,missing=0}
for id,soldier in pairs(soldiers)do
    local skill=skills[soldier.skill]
    local expectedName=skill and skill.name~='' and skill.name or '暂不可用'
    local expected
    if not skill then expected='暂不可用';counts.missing=counts.missing+1
    elseif tonumber(skill.buffID)==0 then expected='无额外附加效果';counts.zero=counts.zero+1
    else expected=assert(buffs[skill.buffID]).description;counts.buff=counts.buff+1 end
    if buffs[soldier.skill] and buffs[soldier.skill].description~=expected then counts.collision=counts.collision+1 end
    local name,desc=D.describe(soldier.skill,skills,buffs);equal(name,expectedName);equal(desc,expected)
    for _,kind in ipairs({2,3,4})do
        local s=detail(id,kind);contains(s,'技能: '..expectedName);contains(s,'技能效果:'..expected)
        assert(not s:find('stale wrong cached name',1,true))
    end
end
assert(counts.zero>0 and counts.buff>0 and counts.collision>0)
for _,kind in ipairs({2,3,4})do contains(detail('144',kind),'技能: 标记\n技能效果:无额外附加效果');contains(detail('missing',kind),'船员详情暂不可用')end
-- Execute the exact production TrainMode table-cell touched closure with its
-- lexical CSV inputs, without constructing the unrelated recruitment UI.
local trainSource=read(root..'TrainMode.lua')
local callbackStart=assert(trainSource:find('    self.tableview:registerScriptHandler(function(view, cell)',1,true))
local bodyStart=assert(trainSource:find('\n',callbackStart,true))+1
local bodyEnd=assert(trainSource:find('    end, cc.TABLECELL_TOUCHED)',bodyStart,true))-1
local makeCallback=assert(loadstring('local self, SkillData, CrewSkillDetails, dataKeyID=...\nreturn function(view, cell)\n'..
    trainSource:sub(bodyStart,bodyEnd)..'\nend','@production-train-detail-callback'))
local trainView={data={},csvData=soldiers,bufData=buffs,getDataKeyByIndex=function(_,i)return i end,
    showInfoBox=function(_,message)view.infoLabel:setString(message)end}
local trainCallback=makeCallback(trainView,skills,D,'ID')
for id,soldier in pairs(soldiers)do
    trainView.data[1]={ID=id}
    trainCallback(nil,{getTag=function()return 1 end})
    local skillName,description=D.describe(soldier.skill,skills,buffs)
    contains(view.infoLabel:getString(),'技能：'..skillName..'\n技能效果：'..description)
end
-- Guard paths leave current detail untouched, including purchase click bubbling.
view.infoLabel:setString('unchanged');view.buttonClicked=true;EventDetailsLayer.showCellInfo(view,1)
equal(view.infoLabel:getString(),'unchanged');equal(view.buttonClicked,false)
view.data=nil;EventDetailsLayer.showCellInfo(view,1);equal(view.infoLabel:getString(),'unchanged')
view.data={};EventDetailsLayer.showCellInfo(view,1);equal(view.infoLabel:getString(),'unchanged')
view.type=1;view.data={{name='墓地'}};EventDetailsLayer.showCellInfo(view,1);equal(view.infoLabel:getString(),'unchanged')
for _,kind in ipairs({3,4})do contains(detail('resource',kind),'真实资源描述')end
-- Broken/missing references never imply no skill effect or invent descriptions.
for _,id in ipairs({'missing',0})do local n,d=D.describe(id,skills,buffs);equal(n,'暂不可用');equal(d,'暂不可用')end
local n,d=D.describe('44',{[44]={name='标记',buffID=0}},{});equal(n,'标记');equal(d,'无额外附加效果')
for _,record in ipairs({{name='技能'}, {name='技能',buffID='bad'}, {name='技能',buffID=999},{name='技能',buffID=1}})do
    local name,desc=D.describe(9,{['9']=record},{});equal(name,'技能');equal(desc,'暂不可用')
end
local _,missingDesc=D.describe(9,{['9']={name='技能',buffID=1}},{['1']={description=''}});equal(missingDesc,'暂不可用')
local _,missingTables=D.describe(9,nil,nil);equal(missingTables,'暂不可用')
equal(snapshot({soldiers,skills,buffs}),baseline,'CSV remains unchanged')
if native then view.infoLabel:release();view.infoNode:release();nativeDrain()end
print(string.format('PASS %s crew skill details: all shipped soldiers x tavern/market/cargo; %d buff0, %d mapped buffs, %d misleading ID collisions; Train callback/missing data/guards/read-only',native and 'native Cocos' or 'strict Lua',counts.zero,counts.buff,counts.collision))
