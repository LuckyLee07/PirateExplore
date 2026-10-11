-- Warm Q v1: native, read-only crew, ship, inventory and voyage pages.
-- Every quantity comes from the live save. Actions enter existing game pages;
-- this module does not recruit, assign, craft, grant, purchase or save anything.
require 'LuaClass/Header'
local Progress = require 'LuaClass/AdventureProgress'
local Goals = require 'LuaClass/HarborGoals'
local Skills = require 'LuaClass/CrewSkillDetails'
local Recovery = require 'LuaClass/CrewRecovery'
local A = {}
local serial = 0
local kinds = {crew=true,ship=true,collection=true,log=true}
local function count(v) return math.max(0,tonumber(v) or 0) end
local function row(t,id) return t[tostring(id)] or t[tonumber(id)] or {} end
local function sorted(t)
    table.sort(t,function(a,b)
        local x,y=tonumber(a.id),tonumber(b.id)
        if x and y then return x<y end
        return tostring(a.id)<tostring(b.id)
    end)
    return t
end
local function unlocked(guide,step,red)
    return guide and guide:getIsHaveStep(step,red==true)==true
end

-- Identity-specific Warm Q art is opt-in per profession; missing art retains
-- that same profession's shipped portrait instead of substituting the duo.
function A.crewPortrait(id,w,h)
    local text=tostring(id)
    local path=text:match('^%d+$') and ('Images/UI/Warm/crew-'..text..'.png')
    local art=path and cc.FileUtils:getInstance():isFileExist(path) and cc.Sprite:create(path) or nil
    if art then
        local z=art:getContentSize()
        if z.width>0 and z.height>0 then
            local node=cc.Node:create();node:setContentSize(cc.size(w,h))
            art:setScale(math.min(w/z.width,h/z.height));art:setAnchorPoint(cc.p(.5,0))
            art:setPosition(cc.p(w/2,0));node:addChild(art);return node
        end
    end
    return require('LuaClass/MasterTheme').portrait(id,w,h)
end

-- Paginate complete Unicode text using the actual native font metrics. No
-- character is discarded, and every page fits its body box before display.
function A.textPages(text,font,width,height)
    local T=require 'LuaClass/WarmTheme'
    local chars={};for char in tostring(text):gmatch('[%z\1-\127\194-\244][\128-\191]*') do chars[#chars+1]=char end
    if #chars==0 then return {''} end
    local measure=T.label('',font,T.colors.ink,0,0,false)
    measure:setDimensions(cc.size(width,0));measure:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    local pages={};local first=1
    while first<=#chars do
        local low,high,best=first,#chars,first
        while low<=high do
            local middle=math.floor((low+high)/2)
            measure:setString(table.concat(chars,'',first,middle))
            if measure:getContentSize().height<=height then best=middle;low=middle+1 else high=middle-1 end
        end
        pages[#pages+1]=table.concat(chars,'',first,best);first=best+1
    end
    return pages
end

-- Also used by regression tests: no Cocos construction or write APIs here.
function A.snapshot(dm,guide)
    local resources=dm:getCSVByID(csvOfResourceInfo) or {}
    local soldiers=dm:getCSVByID(csvOfSoilderAttribute) or {}
    local stock=dm:getRoleData(roleSoildierQueue) or {}
    local selected=dm:getRoleData(roleSelectUnit) or {}
    local aboard=dm:getRoleData(roleBattleQueue) or {}
    local atSea=tonumber(dm:getRoleData(roleStatue))==1
    local s={crew={},inventory={},crewCount=0,assigned=0,atSea=atSea,
        cabin=count(dm:getRoleData(roleCabinSize)),capacity=count(dm:getRoleData(rolePackSize)),
        hp=count(dm:getRoleData(roleShipHp)),coins=count(dm:getRoleData(roleMoney)),
        ship=row(resources,dm:getRoleData(roleShipId)),progress=Progress.getState(dm)}
    local units={}
    for key,value in pairs(stock) do
        if type(value)=='table' then
            local id=tostring(value[dataKeyID] or key)
            units[id]={id=id,stock=count(value[dataKeyNum]),aboard=0}
        end
    end
    if atSea then
        for key,value in pairs(aboard) do
            local id=tostring(key);units[id]=units[id] or {id=id,stock=0,aboard=0}
            units[id].aboard=count(value)
        end
    end
    for id,value in pairs(units) do
        value.num=value.stock+value.aboard
        value.selected=atSea and value.aboard or math.min(value.stock,count(selected[tostring((tonumber(id) or 0)+10000)]))
        value.data=row(soldiers,id);value.name=value.data.name or ('船员 '..id)
        if value.num>0 then
            s.crew[#s.crew+1]=value;s.crewCount=s.crewCount+value.num;s.assigned=s.assigned+value.selected
        end
    end
    sorted(s.crew)
    local held={}
    for id,value in pairs(dm:getRoleData(rolePack) or {}) do
        if count(value)>0 then held[tostring(id)]={id=tostring(id),stock=count(value),aboard=0} end
    end
    if atSea then
        for id,value in pairs(dm:getRoleData(roleBattlePack) or {}) do
            if type(value)=='table' and count(value.num)>0 then
                id=tostring(id);held[id]=held[id] or {id=id,stock=0,aboard=0}
                held[id].aboard=count(value.num)
            end
        end
    end
    for id,value in pairs(held) do
        value.num=value.stock+value.aboard;value.data=row(resources,id)
        value.name=value.data.name or ('物品 '..id);s.inventory[#s.inventory+1]=value
    end
    sorted(s.inventory)
    s.goals=Goals.list(dm,unlocked(guide,60))
    s.recovery=not atSea and Recovery.next(dm,guide) or nil
    s.canTrain=unlocked(guide,103,true);s.canAssign=unlocked(guide,8) and not atSea
    s.canBuild=unlocked(guide,1);s.canMake=unlocked(guide,102,true);s.canStore=unlocked(guide,2)
    s.canRecords=unlocked(guide,8)
    return s
end

local EVENTS={rolePack,roleBattlePack,roleSoildierQueue,roleBattleQueue,roleSelectUnit,
    roleStatue,roleCabinSize,rolePackSize,roleShipId,roleShipHp,roleMoney,roleMake,
    roleBuilding,roleAlchemyUnit,roleGuideStep,roleStore,roleProducerQueue,'adventureProgressV1'}

function A.open(kind,owner)
    if not kinds[kind] or not owner or owner.homeDisposed or owner.warmDisposed then return nil end
    if owner.warmActivity then
        local current=owner.warmActivity
        if not current.disposed then
            if current.kind~=kind then current:showKind(kind) end
            return current
        end
        owner.warmActivity=nil
    end
    local T=require 'LuaClass/WarmTheme'
    local M=require 'LuaClass/MasterTheme'
    local I=require 'LuaClass/ItemIcon'
    local c=T.colors
    local dm=DataManager:getInstance();local guide=GuideController:getInstance()
    local size=cc.Director:getInstance():getVisibleSize()
    local origin=cc.Director:getInstance():getVisibleOrigin()
    local scale=math.min(size.width/480,size.height/800)
    local layer=cc.LayerColor:create(cc.c4b(c.paper.r,c.paper.g,c.paper.b,255),size.width,size.height)
    layer:setPosition(origin);owner:addChild(layer,10000)
    owner.warmActivity=layer;layer.owner=owner;layer.kind=kind;layer.page=1;layer.generation=0
    local canvas=cc.Node:create();canvas:setContentSize(cc.size(480,800));canvas:setScale(scale)
    canvas:setPosition(cc.p((size.width-480*scale)/2,(size.height-800*scale)/2));layer:addChild(canvas)
    layer.canvas=canvas
    serial=serial+1;local eventKey='warmActivities'..serial
    local touch=cc.EventListenerTouchOneByOne:create();touch:setSwallowTouches(true)
    touch:registerScriptHandler(function() return not layer.disposed end,cc.Handler.EVENT_TOUCH_BEGAN)
    layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(touch,layer)
    local function dispose()
        if layer.disposed then return end
        layer.disposed=true
        for _,key in ipairs(EVENTS) do
            dm:unregisterEvent(key,eventKey)
            -- The legacy dispatcher retains the callback under its short key.
            -- Remove only this presentation subscription, never role/save data.
            local bucket=dm.__eventListener and dm.__eventListener[key]
            if bucket then bucket[eventKey]=nil end
        end
        layer:getEventDispatcher():removeEventListener(touch)
        if owner.warmActivity==layer then owner.warmActivity=nil end
        layer.owner=nil;layer.snapshot=nil;layer.buttons=nil;layer.cards=nil;layer.sourceEntries=nil;layer.briefPages=nil
    end
    function layer:close()
        if self.disposed then return end
        dispose();self:removeFromParent(true)
    end
    layer:registerScriptHandler(function(event)
        if event=='exit' or event=='cleanup' then dispose() end
    end)
    function layer:showKind(nextKind)
        if self.disposed or not kinds[nextKind] then return end
        self.kind=nextKind;self.detailId=nil;self.sourceGoalId=nil;self.harborBrief=nil;self.page=1;self:refresh()
    end
    function layer:showDetail(id)
        if self.disposed then return end
        self.detailId=tostring(id);self:refresh()
    end
    function layer:showSources(id)
        if self.disposed then return end
        self.sourceGoalId=tostring(id);self.page=1;self:refresh()
    end
    function layer:showHarborBrief()
        if self.disposed then return end
        self.harborBrief=true;self.page=1;self:refresh()
    end
    function layer:back()
        if self.sourceGoalId then self.sourceGoalId=nil;self.page=1;self:refresh()
        elseif self.harborBrief then self.harborBrief=nil;self.page=1;self:refresh()
        elseif self.detailId then self.detailId=nil;self:refresh() else self:close() end
    end
    function layer:route(route,id)
        if self.disposed or owner.warmActivity~=self then return false end
        local state=A.snapshot(dm,guide);local method,argument,argument2,routeIndex
        if route=='recovery' and state.recovery then
            local recovery=state.recovery
            if recovery.route=='alchemy' then method='moveToRepository';routeIndex=4
            elseif recovery.route=='build' then method='gotoBuild';argument='58'
            elseif recovery.route=='recruit' then method='gotoTrain';routeIndex=2 end
        elseif route=='train' and state.canTrain then method='gotoTrain';routeIndex=2
        elseif route=='assign' and state.canAssign then method='moveToExpedition';routeIndex=1
        elseif route=='build' and state.canBuild then method='gotoBuild';routeIndex=3
        elseif route=='make' and state.canMake then method='gotoMake';routeIndex=5
        elseif route=='repository' and state.canStore then method='moveToRepository';routeIndex=4
        elseif route=='records' and state.canRecords then method='gotoAchievement'
        elseif route=='source' and self.sourceGoalId then
            for _,source in ipairs(Goals.sources(dm,guide,self.sourceGoalId)) do
                if source.id==id then
                    if source.route=='store' then method='gotoStore';argument=false;argument2=source.routeId
                    elseif source.route=='resource' then method='moveToResource';routeIndex=6
                    elseif source.route=='alchemy' then method='moveToRepository';routeIndex=4 end
                    break
                end
            end
        elseif route=='goal' then
            for _,goal in ipairs(state.goals) do
                if goal.id==id and (goal.route=='make' or goal.route=='build') then
                    method=goal.route=='make' and 'gotoMake' or 'gotoBuild';argument=goal.routeId;break
                end
            end
        end
        if not method or not zqDispatch or type(zqDispatch[method])~='function' then self:refresh();return false end
        local dispatch=zqDispatch;self:close()
        if routeIndex and dispatch.mainMenu and type(dispatch.mainMenu.openRoute)=='function' then
            dispatch.mainMenu:openRoute(routeIndex)
        elseif route=='records' and dispatch.mainMenu and type(dispatch.mainMenu.openUtilityRoute)=='function' then
            dispatch.mainMenu:openUtilityRoute('achievement')
        else
            -- Test/minimal dispatchers may omit MainMenu; the same shipyard
            -- gate was already rechecked above before this fallback is used.
            dispatch[method](dispatch,argument,argument2)
        end
        return true
    end
    local function add(n,x,y,parent)
        if not n then return end
        n:setPosition(cc.p(x or 0,y or 0));(parent or canvas):addChild(n);return n
    end
    local function label(text,font,x,y,width,color,bold,parent)
        local n=T.label(text,font,color or c.ink,x,y,bold,0)
        if width then n:setDimensions(cc.size(width,0));n:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT) end
        (parent or canvas):addChild(n);return n
    end
    local function card(x,y,w,h,color)
        return add(T.panel(w,h,color or c.white,22),x,y)
    end
    local function image(path,x,y,w,h)
        if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
        local art=cc.Sprite:create(path);if not art then return nil end
        local z=art:getContentSize();if z.width<=0 or z.height<=0 then return nil end
        art:setScale(math.min(w/z.width,h/z.height));art:setAnchorPoint(cc.p(.5,0))
        return add(art,x+w/2,y)
    end
    local function icon(data,x,y,w,h)
        local art=I.sprite(type(data.icon)=='string' and data.icon~='' and data.icon or data.iconName);local z=art:getContentSize()
        art:setScale(math.min(w/math.max(z.width,1),h/math.max(z.height,1)))
        art:setAnchorPoint(cc.p(.5,.5));return add(art,x+w/2,y+h/2)
    end
    local function portrait(entry,x,y,w,h)
        local art=A.crewPortrait(entry.id,w,h)
        if art then add(art,x,y) else icon(entry.data,x,y,w,h) end
    end
    local function button(key,text,x,y,w,h,action,primary,enabled,font)
        local generation=layer.generation
        local b=T.button(text,w,h,function()
            if layer.disposed or generation~=layer.generation or owner.warmActivity~=layer then return end
            action()
        end,{primary=primary==true,size=font or 19})
        b:setAnchorPoint(cc.p(.5,.5));add(b,x,y)
        b.item:setEnabled(enabled~=false)
        if enabled==false then b:setOpacity(140);b:setCascadeOpacityEnabled(true) end
        layer.buttons[key]=b;return b
    end
    local function footer(leftText,leftRoute,leftEnabled,rightText,rightRoute,rightEnabled)
        button('secondary',leftText,128,48,208,55,function() layer:route(leftRoute) end,false,leftEnabled)
        button('primary',rightText,352,48,208,55,function() layer:route(rightRoute) end,true,rightEnabled)
    end
    local function pager(total,perPage,y)
        local pages=math.max(1,math.ceil(total/perPage));layer.page=math.min(layer.page,pages)
        if pages==1 then return end
        button('previous','上一页',88,y,126,40,function() layer.page=layer.page-1;layer:refresh() end,false,layer.page>1,16)
        card(198,y-20,84,40,c.paper)
        label(layer.page..' / '..pages,16,219,y,62,c.muted)
        button('next','下一页',392,y,126,40,function() layer.page=layer.page+1;layer:refresh() end,false,layer.page<pages,16)
    end
    local function find(entries,id) for _,entry in ipairs(entries) do if entry.id==id then return entry end end end
    local function deck()
        -- An identity portrait gets a quiet full-size stage, never a tiny boat
        -- underneath a giant person. The ship overview owns the boat artwork.
        local stage=card(22,389,436,277,c.paper);stage:setOpacity(238)
    end
    local function header(title,subtitle)
        card(14,678,452,104,c.paper)
        button('back','‹',42,750,46,46,function() layer:back() end,false,true,32)
        local titleLabel=label(title,27,82,752,370,c.ink,true)
        label(subtitle,16,26,701,428,c.muted)
        return titleLabel
    end
    local function crew(state)
        local entry=layer.detailId and find(state.crew,layer.detailId)
        if layer.detailId and not entry then layer.detailId=nil end
        if entry then
            header(entry.name,'伙伴详情 · 原有职业与技能')
            deck();portrait(entry,130,407,220,253)
            card(20,123,440,275)
            label(entry.name,29,42,367,392,c.ink,true)
            label('拥有 '..entry.num..' 人  ·  '..(state.atSea and '随船 ' or '已编入 ')..entry.selected..' 人',17,42,324,390,c.muted)
            local data=entry.data
            label('生命 '..tostring(data.hp or '—')..'   威力 '..tostring(data.attack or '—')..'   速度 '..tostring(data.speed or '—'),17,42,287,390)
            local name,description=Skills.describe(data.skill,dm:getCSVByID(csvOfSkillAttribute) or {},dm:getCSVByID(csvOfBuff) or {})
            label('技能 · '..name,21,42,245,390,c.ink,true)
            local body=label(description,17,42,213,390,c.muted)
            body:setAnchorPoint(cc.p(0,1));body:setDimensions(cc.size(390,67));body:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
            label('基础属性来自职业资料',14,42,143,390,c.muted)
        else
            header('一起出海的伙伴','船员名册 · 已有船员 '..state.crewCount..' 人')
            deck()
            local pages=math.max(1,math.ceil(#state.crew/3));layer.page=math.min(layer.page,pages)
            local start=(layer.page-1)*3+1
            if #state.crew==0 then
                add(M.silhouette(112,160,false),184,472)
                label('船员名册还是空的',22,119,428,280,c.ink,true)
            else
                for i=start,math.min(start+2,#state.crew) do
                    local e=state.crew[i];local visible=math.min(3,#state.crew-start+1)
                    local x=(480-visible*150)/2+5+(i-start)*150
                    portrait(e,x,470,140,184)
                    button('crew:'..e.id,e.name,x+70,441,140,45,function() layer:showDetail(e.id) end,false,true,17)
                    card(x+36,389,68,31,c.paper)
                    label('× '..e.num,17,x+49,405,55,c.ink,true)
                end
            end
            card(20,123,440,249)
            if state.recovery then
                label('先补充一位伙伴',25,42,336,390,c.ink,true)
                local help=label(state.recovery.detail,18,42,302,390,c.muted)
                help:setAnchorPoint(cc.p(0,1));help:setDimensions(cc.size(390,151));help:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
            else
                label((state.atSea and '随船伙伴' or '出航队伍')..'  '..state.assigned..' / '..state.cabin,25,42,336,390,c.ink,true)
                label(state.atSea and '伙伴正在航行中，返港后可以重新安排。' or '在整备页选择同行伙伴，带上足够的食物。',18,42,290,390,c.muted)
                local progress=state.progress
                local note=progress.npcRescued and '航图员林恩已在港口安顿。' or '每一种职业，都有自己的本领。'
                label(note,18,42,226,390,c.ink)
                label(state.canTrain and '招募与转职沿用训练营的规则和消耗。' or '建好训练营后，可以招募和训练伙伴。',16,42,184,390,c.muted)
            end
            pager(#state.crew,3,106)
        end
        if state.recovery then
            footer(state.canTrain and '招募与训练' or '港口建设',state.canTrain and 'train' or 'build',state.canTrain or state.canBuild,
                state.recovery.action,'recovery',state.recovery.route~=nil)
        else
            footer(state.canTrain and '招募与训练' or '训练营未开放','train',state.canTrain,
                state.atSea and '正在航行' or (state.canAssign and '安排出航' or '先建设船坞'),'assign',state.canAssign)
        end
    end
    local function sources(state)
        local goal=find(state.goals,layer.sourceGoalId)
        if not goal or not goal.route then layer.sourceGoalId=nil;layer.page=1;return false end
        header('改造材料从哪里来',goal.title)
        card(20,585,440,78)
        local full=label(goal.detail,18,40,647,396,c.ink)
        full:setAnchorPoint(cc.p(0,1));full:setDimensions(cc.size(396,61));full:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
        local items=Goals.sources(dm,guide,goal.id)
        layer.sourceEntries=items
        local pages=math.max(1,math.ceil(#items/3));layer.page=math.min(layer.page,pages)
        if #items==0 then
            card(20,281,440,253)
            label('材料已经备齐',25,113,460,296,c.ink,true)
            label('可以返回改造，打开原有建设或制造页。',18,61,397,360,c.muted)
        end
        local start=(layer.page-1)*3+1
        for i=start,math.min(start+2,#items) do
            local item=items[i];local y=440-(i-start)*143
            card(20,y,440,131)
            label(item.title,21,38,y+106,390,c.ink,true)
            local detail=label(item.detail,16,38,y+80,270,c.muted)
            detail:setAnchorPoint(cc.p(0,1));detail:setDimensions(cc.size(270,73));detail:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
            button('source:'..item.id,item.action,382,y+39,118,48,function() layer:route('source',item.id) end,true,item.route~=nil,16)
        end
        pager(#items,3,112)
        button('sourceBack','返回改造',240,48,436,55,function() layer:back() end,true,true)
        return true
    end
    local function ship(state)
        if layer.sourceGoalId and sources(state) then return end
        header('让小船走得更远','船只成长 · 查看现有能力与改造条件')
        image(T.path..'ship-home.png',0,334,330,345)
        card(20,632,300,42,c.paper)
        label(state.ship.name or '当前战船',23,38,653,270,c.ink,true)
        for i,stat in ipairs({{'货舱',state.capacity},{'船舱',state.cabin},{'船体生命',state.hp}}) do
            local x,y=332,546-(i-1)*81;card(x,y,126,70)
            label(stat[1],14,x+14,y+49,104,c.muted)
            label(tostring(stat[2]),25,x+14,y+22,104,c.ink,true)
        end
        card(20,306,440,39,c.paper)
        label('回港后的小改造',22,37,325,401,c.ink,true)
        if #state.goals==0 then
            card(20,126,440,172)
            label(state.capacity<30 and ('货舱改造：'..tostring(state.capacity)..' → 30') or '货舱扩容已完成',23,40,262,394,c.ink,true)
            label('查看船上变化、原配方材料和真实解锁条件。确认前不会消耗物品。',18,40,210,390,c.muted)
            button('upgrade:1148','预览改装',240,157,388,47,function()require('LuaClass/WarmUpgrade').open(layer,'1148')end,true,true,21)
        else
            for i,goal in ipairs(state.goals) do
                if i>2 then break end
                local y=208-(i-1)*111;card(20,y,440,102)
                label(goal.title,20,37,y+77,276,c.ink,true)
                local short=not goal.route and '继续探索，解锁改造配方' or (goal.route=='build' and '先建设铁匠铺' or (goal.detail=='材料已备齐' and goal.detail or '仍需补齐材料'))
                label(short,15,37,y+52,282,c.muted)
                button('sources:'..goal.id,'材料来源',108,y+18,142,29,function() layer:showSources(goal.id) end,false,goal.route~=nil,14)
                button('goal:'..goal.id,'预览改装',384,y+43,118,47,function() require('LuaClass/WarmUpgrade').open(layer,goal.id) end,true,true,16)
            end
        end
        footer(state.canBuild and '港口建设' or '先完成炼金','build',state.canBuild,
            state.canMake and '船具制造' or '制造未开放','make',state.canMake)
    end
    local function inventory(state)
        local entry=layer.detailId and find(state.inventory,layer.detailId)
        if layer.detailId and not entry then layer.detailId=nil end
        if entry then
            header(entry.name,'物品详情 · 当前持有')
            card(35,406,410,255)
            icon(entry.data,144,458,192,170)
            label('× '..entry.num,29,196,435,180,c.ink,true)
            card(20,133,440,255)
            label(entry.name,27,42,351,390,c.ink,true)
            label('仓库 '..entry.stock..(state.atSea and ('  ·  船上 '..entry.aboard) or ''),18,42,309,390,c.muted)
            local body=label(type(entry.data.desc)=='string' and entry.data.desc~='' and entry.data.desc or '这是当前持有的物品，可到仓库查看和管理。',18,42,273,390,c.ink)
            body:setAnchorPoint(cc.p(0,1));body:setDimensions(cc.size(390,95));body:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
            label('库存会随使用、获得和航行结算变化。',16,42,156,390,c.muted)
        else
            header('船舱收纳','当前库存 · '..#state.inventory..' 种物品 · 随使用而变化')
            local pages=math.max(1,math.ceil(#state.inventory/6));layer.page=math.min(layer.page,pages)
            if #state.inventory==0 then
                card(28,284,424,271)
                add(T.icon('chest',60),210,440)
                label('这里还没有物品',25,120,408,270,c.ink,true)
                label('独特宝物收藏尚未开放。',18,98,356,304,c.muted)
                label('这里先查看当前持有的库存。',17,95,316,308,c.muted)
            end
            local start=(layer.page-1)*6+1
            for i=start,math.min(start+5,#state.inventory) do
                local entry=state.inventory[i];local index=i-start
                local x=22+(index%2)*224;local y=500-math.floor(index/2)*171
                card(x,y,212,154)
                icon(entry.data,x+66,y+62,80,78)
                button('item:'..entry.id,entry.name,x+106,y+40,192,39,function() layer:showDetail(entry.id) end,false,true,17)
                label('× '..entry.num,15,x+81,y+10,124,c.muted)
            end
            local visible=math.min(6,#state.inventory-start+1)
            if visible>0 and visible<=4 then
                local tall=visible<=2;local bottom=154;local height=tall and 319 or 171
                card(22,bottom,436,height,c.paper)
                local motif=add(T.icon('chest',tall and 82 or 62),tall and 199 or 47,tall and 341 or 203)
                if tall then
                    label('给未来的发现留个位置',22,94,307,314,c.ink,true)
                    label('独特宝物收藏尚未开放',19,112,262,308,c.muted)
                    label('这里先查看当前持有的库存',18,101,225,328,c.muted)
                else
                    label('独特宝物收藏尚未开放',20,133,270,299,c.ink,true)
                    label('这里先查看当前持有的库存。',17,133,223,299,c.muted)
                end
            end
            pager(#state.inventory,6,116)
        end
        button('log','航海日志',128,48,208,55,function() layer:showKind('log') end,false,true)
        button('primary',state.canStore and '打开仓库' or '仓库未开放',352,48,208,55,function() layer:route('repository') end,true,state.canStore)
    end
    local function harborBrief(state)
        local status=Progress.getHarborStatus(dm)
        header('航线与港务线索','查看完整的返港安排与下一程提示')
        card(22,169,436,491)
        label(status.npcName or '港务员',25,43,619,394,c.ink,true)
        local pages=A.textPages(status.npcText or '',19,394,365)
        layer.page=math.min(layer.page,#pages);layer.briefPages=pages
        local text=label(pages[layer.page],19,43,579,394,c.ink)
        text:setAnchorPoint(cc.p(0,1));text:setDimensions(cc.size(394,365));text:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
        label('依据当前存档与实际材料更新',15,43,194,394,c.muted)
        pager(#pages,1,116)
        button('briefBack','返回航海日志',240,48,436,55,function() layer:back() end,true,true)
    end
    local function log(state)
        if layer.harborBrief then harborBrief(state);return end
        header('我们的航程','航海日志 · 已保存的进展')
        button('brief','航线与港务线索',240,659,436,34,function() layer:showHarborBrief() end,false,true,18)
        local p=state.progress;local entries={}
        if not p.enabled then
            entries={{'原有航海记录','当前存档没有逐次航程记录。可继续查看已有成就与当前库存。'}}
        else
            if count(p.voyage)<1 then
                entries[#entries+1]={'第一段旅程','还未启航，先准备伙伴与补给。'}
            else
                entries[#entries+1]={'第 '..count(p.voyage)..' 次航行',p.activeVoyage and '伙伴正在海上，成果仍需安全返港结算。' or '当前已在港口。整备好后，可以开启下一程。'}
            end
            if p.firstEventReturned then
                entries[#entries+1]={'沉船边的选择',p.npcRescued and '救援成果已安全返港，航图员林恩在港口安顿。' or '回收的材料已安全返港。'}
            elseif p.pending then entries[#entries+1]={'尚未结算的发现','沉船成果仍在这次航行中，安全返港后才会记入进展。'}
            else entries[#entries+1]={'近港的沉船','这段旅程还没有完成。可在出航时选择救援或补给目标。'} end
            if p.firstReturnClaimed then entries[#entries+1]={'首返建设补助','首返补助已领取。这里记录领取状态，不代表材料仍在仓库。'} end
            if p.followupReturned then entries[#entries+1]={'再次回到残骸',p.chartRecovered and '残骸航图已经带回港口。' or '后续回收成果已经带回港口。'} end
            if p.gateClue and (p.npcRescued or p.chartRecovered) then entries[#entries+1]={'航线线索',p.gateClue} end
        end
        local pages=math.max(1,math.ceil(#entries/4));layer.page=math.min(layer.page,pages)
        local start=(layer.page-1)*4+1
        for i=start,math.min(start+3,#entries) do
            local y=526-(i-start)*127;card(22,y,436,114)
            label(string.format('%02d',i),19,39,y+83,44,c.coral,true)
            label(entries[i][1],22,84,y+84,349,c.ink,true)
            local body=label(entries[i][2],17,84,y+52,344,c.muted)
            body:setAnchorPoint(cc.p(0,1));body:setDimensions(cc.size(344,61));body:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
        end
        pager(#entries,4,112)
        button('collection','看看库存',128,48,208,55,function() layer:showKind('collection') end,false,true)
        button('primary',state.canRecords and '已有成就' or '成就未开放',352,48,208,55,function() layer:route('records') end,true,state.canRecords)
    end
    function layer:refresh()
        if self.disposed then return end
        self.generation=self.generation+1;self.buttons={};self.cards={};self.sourceEntries=nil;self.briefPages=nil
        canvas:removeAllChildren(true)
        local sky=T.panel(480,800,c.paper,0);add(sky,0,0)
        local sea=T.cover(T.path..'sea-home.png',480,800)
        if sea then add(sea,0,0) else add(T.panel(480,386,cc.c3b(202,235,232),0),0,382) end
        self.snapshot=A.snapshot(dm,guide)
        if self.kind=='crew' then crew(self.snapshot)
        elseif self.kind=='ship' then ship(self.snapshot)
        elseif self.kind=='collection' then inventory(self.snapshot)
        else log(self.snapshot) end
    end
    for _,key in ipairs(EVENTS) do
        dm:registerEvent(key,eventKey,function() if not layer.disposed then layer:refresh() end end)
    end
    layer:refresh()
    return layer
end
return A
