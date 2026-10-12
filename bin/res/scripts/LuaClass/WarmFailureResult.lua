-- Read-only continuity after the original failed-voyage transaction. This
-- module neither owns losses nor saves, revives, grants or starts a voyage.
local F={}
local function number(v)return tonumber(v)or 0 end
local function copy(v)
    if type(v)~='table'then return v end
    local out={};for k,x in pairs(v)do out[k]=copy(x)end;return out
end
local function deaths(rows)
    local out={}
    for _,row in pairs(rows or{})do
        if type(row)=='table'and row.id~=nil then
            local id=tostring(row.id);out[id]=(out[id]or 0)+number(row.num)
        end
    end
    return out
end
function F.before(dm,state,reason)
    if rawget(_G,'WARM_PIRATE_V1')==false or (reason~='Killed'and reason~='NoBread')
        or type(state)~='table'or state.version~=1 or not state.enabled
        or type(state.activeVoyage)~='number'or state.activeVoyage<1 or state.activeVoyage%1~=0 then return nil end
    local resources=dm:getCSVByID(csvOfResourceInfo)or{}
    local lost,mission={},{}
    for id,row in pairs(dm:getRoleData(roleBattlePack)or{})do
        local amount=type(row)=='table'and number(row.num)or 0
        if amount>0 then
            local target=tostring((resources[id]or{}).carryType)=='2'and mission or lost
            target[tostring(id)]=amount
        end
    end
    return {voyage=state.activeVoyage,reason=reason,lostCargo=lost,missionCargo=mission,
        deathCounts=deaths(dm:getRoleData(roleDeathInformation)),mapCoins=number(dm:getRoleData(roleMapCoin))}
end
function F.complete(dm,before,success)
    if not before or before.completed or success~=true or rawget(_G,'WARM_PIRATE_V1')==false then return nil end
    local state=dm:getRoleData('adventureProgressV1')
    if type(state)~='table'or state.version~=1 or not state.enabled or state.activeVoyage
        or state.voyage~=before.voyage or dm:getRoleData(roleStatue)~=0
        or next(dm:getRoleData(roleBattlePack)or{}) or next(dm:getRoleData(roleBattleQueue)or{}) then return nil end
    local record
    local ok,M=pcall(require,'LuaClass/WarmMemories')
    if ok and type(M)=='table'and type(M.get)=='function'then
        local history=M.get(dm)
        if not history.readOnly and history.lastResult and history.lastResult.voyage==before.voyage then record=history.lastResult end
    end
    if record and record.outcome~='failed'then return nil end
    local lostCrew=0
    for id,amount in pairs(deaths(dm:getRoleData(roleDeathInformation)))do
        lostCrew=lostCrew+math.max(0,amount-(before.deathCounts[id]or 0))
    end
    before.completed=true
    return {committed=true,voyage=before.voyage,reason=before.reason,lostCrew=lostCrew,
        lostCargo=copy(before.lostCargo),missionCargo=copy(before.missionCargo),mapCoinsLost=math.max(0,before.mapCoins),
        historyRecorded=record~=nil}
end
function F.lines(dm,result)
    local resources=dm:getCSVByID(csvOfResourceInfo)or{}
    local function entries(items)
        local keys,lines={},{}
        for id in pairs(items or{})do keys[#keys+1]=id end;table.sort(keys)
        for _,id in ipairs(keys)do lines[#lines+1]=tostring((resources[id]or{}).name or id)..' × '..tostring(items[id])end
        return lines
    end
    local lines=entries(result.lostCargo)
    if #lines==0 then lines[1]='结算时货舱中没有普通物资。'end
    if number(result.mapCoinsLost)>0 then lines[#lines+1]='海上金币 × '..result.mapCoinsLost..'（未带回）'end
    local retained=entries(result.missionCargo)
    if #retained>0 then
        lines[#lines+1]='';lines[#lines+1]='按原任务例外保留：'
        for _,line in ipairs(retained)do lines[#lines+1]=line end
    end
    return table.concat(lines,'\n')
end
-- Paginate each outcome category independently. A retained item must never
-- inherit the lost-cargo title when a long receipt crosses a page boundary.
function F.pages(dm,result)
    local paginate=require('LuaClass/WarmActivities').textPages
    local pages={}
    local lost=copy(result);lost.missionCargo={}
    for _,body in ipairs(paginate(F.lines(dm,lost),18,376,172))do
        pages[#pages+1]={title='未带回的货舱物资',body=body}
    end
    local resources=dm:getCSVByID(csvOfResourceInfo)or{}
    local keys,lines={},{}
    for id in pairs(result.missionCargo or{})do keys[#keys+1]=id end
    table.sort(keys)
    for _,id in ipairs(keys)do
        lines[#lines+1]=tostring((resources[id]or{}).name or id)..' × '..tostring(result.missionCargo[id])
    end
    if #lines>0 then
        for _,body in ipairs(paginate(table.concat(lines,'\n'),18,376,172))do
            pages[#pages+1]={title='按原任务例外保留：',body=body}
        end
    end
    return pages
end
function F.show(dm,result,owner)
    if rawget(_G,'WARM_PIRATE_V1')==false or not result or not result.committed or not owner
        or owner.homeDisposed or not owner.warmHomePresentation then return nil end
    -- Home's shared outcome slot already blocks queued background actions.
    if owner.warmReturnResult then return owner.warmReturnResult end
    if result.presented then return nil end
    result.presented=true
    local W=require 'LuaClass/WarmTheme';local C=W.colors
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
    function layer:close()if not self.closed then dispose();self:removeFromParent(true)end end
    layer:registerScriptHandler(function(event)if event=='exit'or event=='cleanup'then dispose()end end)
    local function add(node,x,y)node:setPosition(cc.p(x,y));canvas:addChild(node);return node end
    local function label(text,size,x,y,width,color,bold)
        local n=W.label(text,size,color or C.ink,x,y,bold,0)
        n:setDimensions(cc.size(width,0));n:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT);canvas:addChild(n);return n
    end
    local pages=F.pages(dm,result)
    local function button(key,text,x,y,w,h,action,primary)
        local generation=layer.generation
        local b=W.button(text,w,h,function()
            if not layer.closed and generation==layer.generation and owner.warmReturnResult==layer then action()end
        end,{primary=primary,size=19})
        layer.buttons[key]=add(b,x,y);return b
    end
    function layer:refresh()
        if self.closed then return end
        self.generation=self.generation+1;canvas:removeAllChildren(true);self.buttons={}
        add(W.panel(440,700,C.paper,8),20,50)
        add(W.panel(440,87,C.ink,8),20,663)
        label('第 '..result.voyage..' 次航程  /  已保存',15,52,718,376,C.white)
        label(result.reason=='NoBread'and '补给耗尽，航程结束' or '本次航程失利',27,52,682,376,C.white,true)
        label('本次结算失去伙伴 '..result.lostCrew..' 人',23,52,624,376,C.ink,true)
        label(result.lostCrew>0 and '伙伴已计入复活记录，可在复活据点查看。'or '本次没有新增复活记录。',16,52,592,376,C.muted)
        add(cc.LayerColor:create(cc.c4b(C.line.r,C.line.g,C.line.b,255),376,1),52,566)
        label(pages[self.page].title,22,52,537,376,C.ink,true)
        local body=label(pages[self.page].body,18,52,507,376,C.muted)
        body:setAnchorPoint(cc.p(0,1));body:setDimensions(cc.size(376,172));body:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
        if #pages>1 then
            button('previous','上一页',123,309,133,36,function()self.page=math.max(1,self.page-1);self:refresh()end)
            label(self.page..' / '..#pages,15,218,309,64,C.muted)
            button('next','下一页',357,309,133,36,function()self.page=math.min(#pages,self.page+1);self:refresh()end)
        end
        label('任务物品例外按原规则处理。',16,52,265,376,C.muted)
        label(result.historyRecorded and '本次失利已记入航海日志。'or '仅显示本次结果，不补写旧航程。',16,52,237,376,C.muted)
        if type(owner.openPrimary)=='function'then
            button('prepare','重整船员与补给',240,179,376,54,function()
                self:close();if not owner.homeDisposed then owner:openPrimary()end
            end,true)
            if result.historyRecorded and type(owner.openActivity)=='function'then
                button('log','查看航海日志',145,112,181,46,function()
                    self:close();if not owner.homeDisposed then owner:openActivity('log')end
                end)
                button('close','留在港口',338,112,180,46,function()self:close()end)
            else button('close','留在港口',240,112,376,46,function()self:close()end)end
        else button('close','回到港口',240,145,376,60,function()self:close()end,true)end
    end
    layer:refresh();return layer
end
return F
