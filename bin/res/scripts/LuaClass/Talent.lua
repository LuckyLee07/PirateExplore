require 'LuaClass/Header'
require 'LuaClass/BaseView'
require 'LuaClass/UIKit'
require 'LuaClass/DataManager'
require 'LuaClass/MasterTheme'

TalentLayer=class('TalentLayer',function() return BaseView:create() end)
TalentLayer.__index=TalentLayer
local EVENTS={roleTalent,roleMoney,roleDiamond,roleMapInfo,roleGuideStep}
function TalentLayer:create()
    local view=TalentLayer.new();if view and view:init() then return view end
end
local function compass(size,color)
    local node=cc.Node:create();node:setContentSize(cc.size(size,size))
    local d=cc.DrawNode:create();node:addChild(d);local c=HomeTheme.rgba(color)
    for i=0,31 do local a=i*math.pi/16;local b=(i+1)*math.pi/16
        d:drawSegment(cc.p(size*(.5+.3*math.cos(a)),size*(.5+.3*math.sin(a))),cc.p(size*(.5+.3*math.cos(b)),size*(.5+.3*math.sin(b))),.7,c)
    end
    d:drawSegment(cc.p(size*.5,0),cc.p(size*.5,size),1,c)
    d:drawSegment(cc.p(0,size*.5),cc.p(size,size*.5),1,c)
    return node
end
local function fittedSprite(path,w,h,rect)
    if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
    local s=rect and cc.Sprite:create(path,rect) or cc.Sprite:create(path)
    if not s then return nil end
    local z=s:getContentSize();if z.width<=0 or z.height<=0 then return nil end
    s:setScale(math.min(w/z.width,h/z.height));s:setAnchorPoint(cc.p(.5,.5))
    if s.getTexture then s:getTexture():setAntiAliasTexParameters() end
    return s
end
function TalentLayer:init()
    self.approvedPage=true;self.keepNavigation=false;self.talentDisposed=false
    local size=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin()
    local M=MasterTheme;local c=M.colors;local ux,uy=size.width/941,size.height/1672
    self.talentUX=ux;self.talentUY=uy
    self.mainBg:setVisible(false);self.titleBg:setVisible(false);self.storeMenu:setVisible(false)
    -- Keep the original alchemy controller, its cooldown and earned long-press
    -- entitlement. Only its visible sprites/hit rectangle are restyled below.
    self:addInfoNode(nil,nil,'出征',function() zqDispatch:moveToExpedition() end,
        'Images/MainMenu/an_lianj_a.png','Images/MainMenu/an_lianj_b.png',
        function() DataManager:getInstance():AlchemyButtonDidClick() end,nil,true,zqAlchemyTime,false)
    self.infoNode:setPosition(cc.p(0,0));self.infoNode:setLocalZOrder(20)
    for _,child in ipairs(self.infoNode:getChildren()) do if child~=self.setBtn then child:setVisible(false) end end
    self.setButtonProgrees:setVisible(false)
    local root=cc.Node:create();root:setPosition(origin);self:addChild(root,2);self.talentRoot=root
    local backdrop=M.cover('Images/UI/Adventure/Talent/backdrop.png',size.width,size.height)
    if backdrop then root:addChild(backdrop) else root:addChild(cc.LayerColor:create(cc.c4b(92,169,194,255),size.width,size.height)) end
    local function label(text,font,x,y,bold,color,anchor)
        local n=M.label(text,font,color or c.ink,x*ux,size.height-y*uy,bold,anchor);root:addChild(n);return n
    end
    local function material(name,x,y,w,h)
        local n=M.material(name,w*ux,h*uy)
        if name=='crew-paper.png' then
            n:removeAllChildren();local sheet=cc.Sprite:create('Images/UI/Adventure/Talent/paper.png')
            local z=sheet:getContentSize();sheet:setAnchorPoint(cc.p(.5,.5));sheet:setScale(math.max(w*ux/z.width,h*uy/z.height));sheet:setPosition(cc.p(w*ux/2,h*uy/2));sheet:getTexture():setAntiAliasTexParameters();n:addChild(sheet)
        end
        n:setPosition(cc.p(x*ux,size.height-(y+h)*uy));root:addChild(n);return n
    end
    local back=function() zqDispatch:backToLastView() end
    local topBack=M.button('‹',90*ux,82*uy,back,{fontSize=52,bold=true});topBack:setPosition(cc.p(78*ux,size.height-94*uy));root:addChild(topBack)
    label('冒险天赋',49,153,84,true)
    local titleCompass=compass(60*ux,c.ink);titleCompass:setPosition(cc.p(460*ux,size.height-120*uy));root:addChild(titleCompass)
    label('已获得的团队天赋',25,153,154,'regular')
    material('currency-paper.png',97,192,223,68);material('currency-paper.png',343,192,194,68)
    for _,s in ipairs({{'coin-detail.png',130},{'gem-detail.png',384}}) do
        local sprite=fittedSprite(M.path..'Details/'..s[1],52*ux,52*uy)
        if sprite then sprite:setPosition(cc.p(s[2]*ux,size.height-225*uy));root:addChild(sprite) end
    end
    self.talentCoin=label('',31,187,225,true);self.talentDiamond=label('',31,433,225,true)
    material('crew-paper.png',31,365,875,1170)
    local badge=material('ink-brush.png',148,405,440,66)
    local badgeMark=compass(57*ux,c.ink);badgeMark:setPosition(cc.p(76*ux,size.height-466*uy));root:addChild(badgeMark)
    self.talentChapter=label('',26,179,438,true,c.paper)
    self.talentCount=label('',40,95,525,true)
    HomeTheme.rule(root,94*ux,size.height-568*uy,760*ux,c.ink)
    local viewH=(1345-590)*uy;local viewW=776*ux
    self.scrollViewContainer=cc.Layer:create();self.scrollView=cc.ScrollView:create(cc.size(viewW,viewH))
    self.scrollView:setPosition(cc.p(78*ux,size.height-1345*uy));self.scrollView:setContainer(self.scrollViewContainer)
    self.scrollView:setClippingToBounds(true);self.scrollView:setBounceable(true);self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    root:addChild(self.scrollView,4);self.talentListWidth=viewW;self.talentListHeight=viewH
    self.alertLabel=label('尚未获得天赋',27,470,900,'regular',c.muted,.5);self.alertLabel:setVisible(false)
    -- Restyle the existing SDButton so single/long press still invokes exactly
    -- the original callback and cooldown. Invisible hit sprites retain bounds.
    local aw,ah=230*ux,58*uy
    for _,sprite in ipairs({self.setBtn.normalSpr,self.setBtn.selectSpr}) do
        local z=sprite:getContentSize();sprite:setScaleX(aw/z.width);sprite:setScaleY(ah/z.height);sprite:setOpacity(0)
    end
    self.setBtn:setContentSize(cc.size(aw,ah));self.setBtn:setPosition(cc.p(origin.x+341*ux,origin.y+size.height-1370*uy))
    local alchemyFace=M.material('currency-paper.png',aw,ah);self.setBtn:addChild(alchemyFace,-1)
    self.setBtn:addChild(M.label('炼金',25,c.ink,aw*.6,ah/2,true,.5))
    local flask=cc.DrawNode:create();local ink=HomeTheme.rgba(c.ink)
    flask:drawDot(cc.p(14,10),10,ink);flask:drawSegment(cc.p(14,12),cc.p(14,25),3,ink);flask:drawSegment(cc.p(9,25),cc.p(19,25),1.5,ink)
    flask:setPosition(cc.p(aw*.18,ah/2-14));self.setBtn:addChild(flask)
    self.alchemyButton=self.setBtn
    local intelligence=HomeTheme.button('情报',230*ux,58*uy,function()
        if DataManager:getInstance():getRoleData(roleMapInfo)~=nil and not isEnterMap then RandomEventView:create():show()
        else ToastUtil:downString('您需要建造船坞并出征\n之后方可激活该功能') end
    end,{color=c.paper,textColor=c.ink,size=25,bold=true})
    intelligence.label:setFontName(M.headingFont(true));intelligence.label:setPositionX(230*ux*.62)
    local scroll=cc.DrawNode:create();local ink=HomeTheme.rgba(c.ink)
    scroll:drawSegment(cc.p(4,4),cc.p(23,23),5,ink);scroll:drawDot(cc.p(4,4),5,ink);scroll:drawDot(cc.p(4,4),2,HomeTheme.rgba(c.paper))
    scroll:setPosition(cc.p(230*ux*.16,58*uy/2-14));intelligence.item:addChild(scroll)
    intelligence:setPosition(cc.p(602*ux,size.height-1370*uy));root:addChild(intelligence)
    self.talentIntelligence=intelligence
    label('天赋通过探索与剧情获得',20,470,1420,'regular',c.muted,.5)
    label('此处查看已获得的团队增益',20,470,1460,'regular',c.muted,.5)
    local bottomBack=M.button('←  返回上一页',695*ux,108*uy,back,{fontSize=37,bold=true});bottomBack:setPosition(cc.p(470*ux,size.height-1564*uy));root:addChild(bottomBack)
    self.talentBackButton=bottomBack
    self:loadTalentData();self:refreshTalentHeader()
    for _,key in ipairs(EVENTS) do
        DataManager:getInstance():registerEvent(key,'talent',function()
            if not self.talentDisposed then if key==roleTalent then self:loadTalentData() end;self:refreshTalentHeader() end
        end)
    end
    return true
end
function TalentLayer:refreshTalentHeader()
    if self.talentDisposed then return end
    local dm=DataManager:getInstance();self.talentCoin:setString(tostring(dm:getRoleData(roleMoney) or 0));self.talentDiamond:setString(tostring(dm:getRoleData(roleDiamond) or 0))
    MasterTheme.fit(self.talentCoin,106*self.talentUX);MasterTheme.fit(self.talentDiamond,90*self.talentUX)
    local map=dm:getRoleData(roleMapInfo);local chapter=map and tonumber(map.curIndex)
    self.talentChapter:setString(chapter and ('第'..(({[1]='一',[2]='二',[3]='三',[4]='四',[5]='五',[6]='六',[7]='七',[8]='八',[9]='九',[10]='十'})[chapter] or tostring(chapter))..'章 · 冒险天赋') or '冒险天赋')
    local available=map~=nil and not isEnterMap
    self.talentIntelligence:setCascadeOpacityEnabled(true);self.talentIntelligence:setOpacity(available and 255 or 115)
    self.talentIntelligence.item:setCascadeOpacityEnabled(true);self.talentIntelligence.item:setOpacity(available and 255 or 115)
end
function TalentLayer:loadTalentData()
    if self.talentDisposed then return end
    local dm=DataManager:getInstance();local data=dm:getRoleData(roleTalent) or {};local csv=dm:getCSVByID(csvOfTalent) or {}
    local ordered={};for index,id in pairs(data) do if tonumber(index) then ordered[#ordered+1]={index=tonumber(index),id=tostring(id)} end end
    table.sort(ordered,function(a,b)return a.index>b.index end)
    self.talentEntries=ordered;self.scrollViewContainer:removeAllChildren()
    self.talentCount:setString('已获得 '..#ordered..' 项');self.alertLabel:setVisible(#ordered==0)
    local M=MasterTheme;local c=M.colors;local ux,uy=self.talentUX,self.talentUY
    local rowH=195*uy;local total=math.max(self.talentListHeight,#ordered*rowH)
    for i,e in ipairs(ordered) do
        local record=csv[e.id] or {};local name=record[dataKeyName] or ('天赋 '..e.id);local effect=record[dataKeyComment] or '暂无效果说明'
        local node=cc.Node:create();node:setContentSize(cc.size(self.talentListWidth,rowH));node:setPosition(cc.p(0,total-i*rowH));self.scrollViewContainer:addChild(node)
        local cell=({['精准']=2,['闪避']=3,['耐饿']=4,['侦查']=5})[name]
        local art=cell and fittedSprite('Images/UI/Adventure/Pages/icons.png',222*ux,180*uy,cc.rect((cell%3)*512+64,math.floor(cell/3)*512+64,416,416)) or nil
        if art then art:setPosition(cc.p(126*ux,rowH/2));node:addChild(art)
        else local ink=M.material('ink-brush.png',174*ux,149*uy);ink:setPosition(cc.p(31*ux,(rowH-149*uy)/2));node:addChild(ink)
            local mark
            if name=='先发制人' then
                mark=cc.DrawNode:create();local paint=HomeTheme.rgba(c.paper);local w=91*ux
                mark:drawTriangle(cc.p(w*.62,w),cc.p(w*.14,w*.43),cc.p(w*.57,w*.49),paint)
                mark:drawTriangle(cc.p(w*.57,w*.49),cc.p(w*.33,0),cc.p(w*.87,w*.65),paint)
            else mark=compass(91*ux,c.paper) end
            mark:setPosition(cc.p(73*ux,(rowH-91*ux)/2));node:addChild(mark) end
        local title=M.label(name,34,c.ink,264*ux,rowH*.66,true);M.fit(title,self.talentListWidth-270*ux);node:addChild(title)
        local description=M.label(effect,24,c.ink,264*ux,rowH*.28,'regular');description:setDimensions(cc.size(self.talentListWidth-268*ux,rowH*.43));description:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT);description:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER);node:addChild(description)
        HomeTheme.rule(node,14*ux,1,self.talentListWidth-26*ux,c.ink)
    end
    self.scrollView:setContentSize(cc.size(self.talentListWidth,total));self.scrollView:setContentOffset(cc.p(0,-(total-self.talentListHeight)))
end
function TalentLayer:destory()
    if self.talentDisposed then return end
    self.talentDisposed=true
    for _,key in ipairs(EVENTS) do DataManager:getInstance():unregisterEvent(key,'talent') end
    if self.setBtn and self.setBtn.normalSpr then self.setBtn.normalSpr:stopAllActions() end
end
