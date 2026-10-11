-- A receipt for the original completed return. This module never saves, claims,
-- grants, changes cargo, or repeats the return transaction.
local R={}
local function copy(v)
    if type(v)~='table' then return v end
    local out={};for k,value in pairs(v)do out[k]=copy(value)end;return out
end
local function number(v)return tonumber(v)or 0 end
local function totalCrew(crew)
    local count=0
    for _,row in pairs(crew or{})do if type(row)=='table'then count=count+number(row[dataKeyNum])end end
    return count
end
local function delta(before,after)
    local keys,out={},{}
    for id in pairs(before or{})do keys[id]=true end
    for id in pairs(after or{})do keys[id]=true end
    for id in pairs(keys)do
        local change=number((after or{})[id])-number((before or{})[id])
        if change~=0 then out[tostring(id)]=change end
    end
    return out
end
function R.before(dm,state)
    if rawget(_G,'WARM_PIRATE_V1')==false or type(state)~='table' or not state.enabled
        or type(state.activeVoyage)~='number' or state.activeVoyage<1 or state.activeVoyage%1~=0 then return nil end
    return {voyage=state.activeVoyage,money=number(dm:getRoleData(roleMoney)),diamonds=number(dm:getRoleData(roleDiamond)),
        pack=copy(dm:getRoleData(rolePack)or{}),crew=totalCrew(dm:getRoleData(roleSoildierQueue))}
end
function R.complete(dm,before,success)
    if not before or before.completed or success~=true or rawget(_G,'WARM_PIRATE_V1')==false then return nil end
    local state=dm:getRoleData('adventureProgressV1')
    if type(state)~='table' or state.version~=1 or not state.enabled or state.activeVoyage
        or state.voyage~=before.voyage or dm:getRoleData(roleStatue)~=0 then return nil end
    local record
    local ok,memories=pcall(require,'LuaClass/WarmMemories')
    if ok and type(memories)=='table' and type(memories.get)=='function' then
        local view=memories.get(dm)
        if not view.readOnly and view.lastResult and view.lastResult.voyage==before.voyage then record=view.lastResult end
    end
    if record and record.outcome~='returned' then return nil end
    before.completed=true
    -- Actual post-commit deltas include the original subsidy and return payment.
    -- An old active voyage can have a receipt without a fabricated durable log.
    return {voyage=before.voyage,historyRecorded=record~=nil,memoryIds=copy(record and record.memoryIds or{}),
        moneyDelta=number(dm:getRoleData(roleMoney))-before.money,
        diamondDelta=number(dm:getRoleData(roleDiamond))-before.diamonds,
        stockDelta=delta(before.pack,dm:getRoleData(rolePack)),
        crewReturned=math.max(0,totalCrew(dm:getRoleData(roleSoildierQueue))-before.crew),
        record=copy(record),committed=true}
end
local function signed(value)return value>0 and ('+'..tostring(value))or tostring(value)end
function R.lines(dm,result)
    local lines={};local resources=dm:getCSVByID(csvOfResourceInfo)or{}
    local keys={};for id in pairs(result.stockDelta or{})do keys[#keys+1]=id end;table.sort(keys)
    for _,id in ipairs(keys)do lines[#lines+1]=tostring((resources[id]or{}).name or id)..'  '..signed(result.stockDelta[id])end
    return #lines>0 and table.concat(lines,'\n')or'本航没有物资变化。'
end
function R.show(dm,result,owner)
    if rawget(_G,'WARM_PIRATE_V1')==false or not result or not result.committed or not owner
        or owner.homeDisposed or not owner.warmHomePresentation then return nil end
    if owner.warmReturnResult then return owner.warmReturnResult end
    if result.presented then return nil end
    result.presented=true
    local W=require 'LuaClass/WarmTheme'
    local size=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin()
    local scale=math.min(size.width/480,size.height/800)
    local layer=cc.LayerColor:create(cc.c4b(25,49,52,180),size.width,size.height)
    layer.isAdventureModal=true;layer.closed=false;layer.result=copy(result);layer.page=1;layer.generation=0
    owner.warmReturnResult=layer;owner:addChild(layer,21000)
    local canvas=cc.Node:create();canvas:setScale(scale)
    canvas:setPosition(cc.p(origin.x+(size.width-480*scale)/2,origin.y+(size.height-800*scale)/2));layer:addChild(canvas)
    local touch=cc.EventListenerTouchOneByOne:create();touch:setSwallowTouches(true)
    touch:registerScriptHandler(function()return not layer.closed end,cc.Handler.EVENT_TOUCH_BEGAN)
    layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(touch,layer)
    local function dispose()
        if layer.closed then return end
        layer.closed=true
        if owner.warmReturnResult==layer then owner.warmReturnResult=nil end
        layer:getEventDispatcher():removeEventListener(touch)
    end
    function layer:close()
        if self.closed then return end
        dispose();self:removeFromParent(true)
    end
    layer:registerScriptHandler(function(event)if event=='exit'or event=='cleanup'then dispose()end end)
    local function add(node,x,y)node:setPosition(cc.p(x,y));canvas:addChild(node);return node end
    local function label(text,font,x,y,width,color,bold)
        local node=W.label(text,font,color or W.colors.ink,x,y,bold,0)
        node:setDimensions(cc.size(width,0));node:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT);canvas:addChild(node);return node
    end
    local function button(key,text,x,y,w,h,action,primary)
        local generation=layer.generation
        local b=W.button(text,w,h,function()if not layer.closed and generation==layer.generation and owner.warmReturnResult==layer then action()end end,{primary=primary,size=19})
        layer.buttons[key]=add(b,x,y);return b
    end
    local body=R.lines(dm,result)
    local pages=require('LuaClass/WarmActivities').textPages(body,18,372,125)
    function layer:refresh()
        if self.closed then return end
        self.generation=self.generation+1
        canvas:removeAllChildren(true);self.buttons={}
        local C=W.colors
        add(W.panel(440,700,C.paper,10),20,50)
        add(W.panel(440,87,C.ink,10),20,663)
        label('航程结算  /  已保存',15,52,718,376,C.white)
        label('平安返回港口',29,52,682,376,C.white,true)
        label('第 '..result.voyage..' 次航程 · 已保存',17,52,631,376,C.muted)
        label('金币 '..signed(result.moneyDelta)..'  ·  钻石 '..signed(result.diamondDelta),22,52,589,376,C.ink,true)
        label('同行伙伴归来 '..result.crewReturned..' 人',18,52,551,376,C.muted)
        add(cc.LayerColor:create(cc.c4b(C.line.r,C.line.g,C.line.b,255),376,1),52,530)
        label('仓库物资净变化',22,52,503,376,C.ink,true)
        label('含带回物资（包括原有补给）、补助及返航消耗',14,52,474,376,C.muted)
        local text=label(pages[self.page],18,52,451,372,C.muted)
        text:setAnchorPoint(cc.p(0,1));text:setDimensions(cc.size(372,125));text:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
        if #pages>1 then
            button('previous','上一页',123,302,133,36,function()self.page=math.max(1,self.page-1);self:refresh()end)
            label(self.page..' / '..#pages,15,218,302,64,C.muted)
            button('next','下一页',357,302,133,36,function()self.page=math.min(#pages,self.page+1);self:refresh()end)
        end
        local newMemory=#result.memoryIds>0
        label(newMemory and '新增珍藏：沉船航图残页' or '收获与费用已按原规则结算。',19,52,259,376,C.ink,true)
        label(result.historyRecorded and '这次归航已记在航海日志里。' or '这次仅显示结算，不补写旧航程。',15,52,231,376,C.muted)
        -- Closing the receipt is always first. The Home route retains its own
        -- unlock/recovery guards; this button never starts or settles a voyage.
        if type(owner.openPrimary)=='function' then
            button('prepare','准备下次出航',240,179,376,54,function()
                self:close();if not owner.homeDisposed then owner:openPrimary()end
            end,true)
            if newMemory and type(owner.openActivity)=='function' then
                button('collection','看看珍藏',145,112,181,46,function()
                    self:close();if not owner.homeDisposed then owner:openActivity('collection')end
                end)
                button('close','留在港口',338,112,180,46,function()self:close()end)
            else button('close','留在港口',240,112,376,46,function()self:close()end)end
        elseif newMemory and type(owner.openActivity)=='function' then
            button('collection','看看珍藏',240,174,376,54,function()
                self:close();if not owner.homeDisposed then owner:openActivity('collection')end
            end,true)
            button('close','留在港口',240,112,376,46,function()self:close()end)
        else button('close','回到港口',240,145,376,60,function()self:close()end,true)end
    end
    layer:refresh();return layer
end
return R
