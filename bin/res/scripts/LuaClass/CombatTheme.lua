-- Presentation-only battle chrome. Actors, timing, damage and controls stay owned
-- by FightMode; these helpers never read or write player state.
require 'LuaClass/MasterTheme'
CombatTheme = {}
local C = CombatTheme
local function warm()
    if rawget(_G,'WARM_PIRATE_V1')==false then return nil end
    local W=rawget(_G,'WarmTheme')
    if type(W)~='table' then
        local ok,value=pcall(require,'LuaClass/WarmTheme');if ok then W=value end
    end
    if type(W)=='table' and type(W.enabled)=='function' and W.enabled() then return W end
end
local function inkPlate(w,h)
    local W=warm()
    return W and W.panel(w,h,W.colors.ink,8) or MasterTheme.material('ink-brush.png',w,h)
end
function C.deckPath(boarding)
    local path = 'Images/UI/Adventure/Combat/' .. (boarding and 'boarding-deck-b.png' or 'ship-deck-b.png')
    if cc.FileUtils:getInstance():isFileExist(path) then return path end
    return boarding and 'Images/Fight/chuan_01.png' or 'Images/Fight/chuan_04.png'
end
function C.chestPath(open)
    local path = 'Images/UI/Adventure/Combat/' .. (open and 'chest-open-b.png' or 'chest-closed-b.png')
    if cc.FileUtils:getInstance():isFileExist(path) then return path end
    return open and 'Images/Fight/baoxiang02.png' or 'Images/Fight/baoxiang01.png'
end
function C.captionPlate(parent, size, z)
    -- The ship deck reaches the top edge; put the existing white encounter
    -- sentence on ink while staying above the stars, HP plate and cannons.
    local plate = inkPlate(size.width+20,62)
    plate:setPosition(cc.p(-10, size.height-62))
    parent:addChild(plate, z or 0)
    return plate
end
function C.label(text, _, size)
    local W=warm()
    local label=cc.LabelTTF:create(text,W and W.font or MasterTheme.headingFont(size>=30),size)
    label:setColor(W and W.colors.white or MasterTheme.colors.white)
    return label
end
function C.background(size)
    local root=cc.Node:create();root:setContentSize(size);root:setAnchorPoint(cc.p(0,0))
    local W=warm()
    if W then
        local sea=cc.LayerColor:create(cc.c4b(58,176,181,255),size.width,size.height)
        root:addChild(sea)
        local path='Images/UI/CleanVoyage/sea-turquoise-caustics.png'
        local water=W.cover(path,size.width,size.height)
        if water then root:addChild(water) end
        -- Existing bottom action captions stay white. Keep their original safe
        -- strip, without darkening the sunny water or framing it with brushes.
        local bottom=inkPlate(size.width+20,105)
        bottom:setPosition(cc.p(-10,-10));root:addChild(bottom)
        return root
    end
    local water=MasterTheme.cover('Images/UI/Adventure/SeaChart/Tiles/sea-water-repeat.png',size.width,size.height)
    root:addChild(water)
    local shade=cc.LayerColor:create(cc.c4b(3,35,48,85),size.width,size.height);root:addChild(shade)
    local top=MasterTheme.material('ink-brush.png',size.width+20,220)
    top:setPosition(cc.p(-10,size.height-220));root:addChild(top)
    local bottom=MasterTheme.material('ink-brush.png',size.width+20,105)
    bottom:setPosition(cc.p(-10,-10));root:addChild(bottom)
    return root
end
function C.bar(filled, width, height, side)
    width,height=width or 313,height or 23
    local W=warm()
    local color=filled and (side=='player' and (W and W.colors.sea or cc.c3b(61,178,170)) or
        (W and W.colors.coral or MasterTheme.colors.coral)) or (W and cc.c3b(24,46,50) or cc.c3b(3,35,47))
    local bar=cc.Node:create();bar:setContentSize(cc.size(width,height))
    local face=W and W.panel(width,20,color,4) or HomeTheme.rounded(width,20,color,10)
    face:setPosition(cc.p(0,(height-20)*.5));bar:addChild(face)
    return bar
end
function C.statusPlate(parent,x,barY,z)
    local plate=inkPlate(390,98)
    plate:setPosition(cc.p(x-195,barY-37));parent:addChild(plate,z or 0)
    return plate
end
-- Battle-only opt-in. Shared loot/chest helpers above retain their exact contract.
function C.cleanBattleEnabled() return warm() ~= nil end
function C.battleViewport(size)
    if not C.cleanBattleEnabled() then return size end
    return cc.size(640,size.height/(size.width/640))
end
local battlePath='Images/UI/CleanVoyage/Combat/'
local function logicalArt(path,width,height,rect,flip)
    local visual=rect and cc.Sprite:create(path,rect) or cc.Sprite:create(path)
    local root=cc.Node:create();root:setContentSize(cc.size(width,height))
    root:setCascadeColorEnabled(true);root:setCascadeOpacityEnabled(true)
    visual:setAnchorPoint(cc.p(0,0));visual:setPosition(cc.p(0,0))
    local z=visual:getContentSize();visual:setScaleX(width/z.width);visual:setScaleY(height/z.height)
    if flip then visual:setFlippedY(true) end
    root:addChild(visual);root.battleVisual=visual;root.battleArtPath=path
    return root
end
function C.deckSprite(boarding,flip)
    if not C.cleanBattleEnabled() then
        local s=cc.Sprite:create(C.deckPath(boarding));s:setFlippedY(flip or false);return s
    end
    return logicalArt(battlePath..(boarding and 'boarding-deck-clean-v1.png' or 'ship-deck-clean-v1.png'),640,boarding and 569 or 423,nil,flip)
end
function C.cannonActor(rear,flip)
    if not C.cleanBattleEnabled() then
        local s=cc.Sprite:create(rear and 'Images/Fight/chuan_03.png' or 'Images/Fight/chuan_02.png');s:setFlippedY(flip or false);return s
    end
    -- Rear view is the top of the accepted full cannon, never the rejected art.
    local rect=rear and cc.rect(0,0,927,1697*73/185) or nil
    return logicalArt(battlePath..'cannon-full-clean-v1.png',101,rear and 73 or 185,rect,flip)
end
local function relocate(node,parent,x,y,z)
    node:retain();node:removeFromParent(false);parent:addChild(node,z or 0);node:release()
    if x then node:setPosition(cc.p(x,y)) end
    node:setVisible(true);return node
end
local function battleText(parent,text,size,x,y,width,color,anchor)
    local W=warm();local n=W.label(text,size,color or W.colors.ink,x,y,false,anchor or 0)
    if width then W.fit(n,width) end;parent:addChild(n);return n
end
local function battleTrack(parent,x,y,width,height,side,filled)
    local W=warm();local color=filled and (side=='player' and W.colors.sea or W.colors.coral) or W.colors.line
    local n=cc.Node:create();n:setContentSize(cc.size(width,height));n:setAnchorPoint(cc.p(0,.5))
    n:addChild(cc.LayerColor:create(cc.c4b(color.r,color.g,color.b,255),width,height))
    n:setPosition(cc.p(x,y));parent:addChild(n);return n
end
local function battleHealth(scene,parent,player,x,y,width)
    local team=player and scene.playerTeam or scene.enemyTeam
    local side=player and 'player' or 'enemy'
    battleTrack(parent,x,y,width,12,side,false)
    local fill=battleTrack(parent,x,y,width,12,side,true)
    fill:setScaleX(team.hp/math.max(1,team.m_hp))
    local label=battleText(parent,tostring(team.hp)..'/'..tostring(team.m_hp),18,x+width+14,y,152)
    if player then scene.hp=fill;scene.label_hp=label else scene.ehp=fill;scene.label_ehp=label end
end
local function battleItem(item,parent,x,y,width,height,color)
    local W=warm()
    item:setNormalImage(W.panel(width,height,color,8))
    item:setDisabledImage(W.panel(width,height,W.colors.line,8))
    item:setSelectedImage(W.panel(width,height,cc.c3b(math.max(0,color.r-16),math.max(0,color.g-16),math.max(0,color.b-16)),8))
    local menu=cc.Menu:create();menu:setPosition(cc.p(0,0));parent:addChild(menu)
    relocate(item,menu,x,y);item:setScale(1);return item
end
function C.finishBattle(scene,size,boarding,refs)
    local W=warm();if not W then return end
    refs=refs or {}
    local actual=cc.Director:getInstance():getVisibleSize()
    local root=cc.Node:create();root:setContentSize(size);root:setScale(actual.width/640)
    -- Keep original live hooks owned until normal scene cleanup, but suppress
    -- obsolete chrome. Reparent original inputs so their handlers stay exact.
    local previous=scene:getChildren();local stash=cc.Node:create();stash:setVisible(false)
    scene:addChild(stash)
    for _,child in ipairs(previous)do relocate(child,stash) end
    scene:addChild(root,10);scene.cleanBattleRoot=root;scene.cleanBattleSize=size;scene.cleanBattleLegacy=stash
    local water=W.cover('Images/UI/CleanVoyage/sea-turquoise-caustics.png',size.width,size.height)
    if water then root:addChild(water) end
    local header=W.panel(592,148,W.colors.paper,8);header:setPosition(cc.p(24,size.height-168));root:addChild(header,20)
    local enemy=scene.enemyTeam.fighters[1]
    local description=boarding and (enemy and enemy.description or '') or '一艘阴森森的海盗船对你发起了炮击'
    local desc=battleText(header,description,19,24,120,nil,W.colors.muted)
    desc:setDimensions(cc.size(544,0));desc:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    local dz=desc:getContentSize();desc:setScale(math.min(1,40/math.max(1,dz.height)));desc:setAnchorPoint(cc.p(0,.5))
    scene.cleanBattleDescription=desc
    scene.cleanBattleName=battleText(header,enemy and enemy.name or '',27,24,78,408)
    battleText(header,'星级 '..tostring(scene.enemyTeam.star),17,568,78,110,W.colors.muted,1)
    battleHealth(scene,header,false,24,31,360)
    if not boarding then
        relocate(scene.shipNodePlayer,root,nil,nil,1);relocate(scene.shipNodeEnemy,root,nil,nil,1)
        relocate(scene.shipWarEffectNodePlayer,root,nil,nil,30);relocate(scene.shipWarEffectNodeEnemy,root,nil,nil,30)
        relocate(scene.shipWarBombNodePlayer,root,nil,nil,4);relocate(scene.shipWarBombNodeEnemy,root,nil,nil,4)
        local footer=W.panel(592,100,W.colors.paper,8);footer:setPosition(cc.p(24,20));root:addChild(footer,20)
        battleText(footer,'船队',22,24,72,170)
        battleText(footer,'炮击中',18,568,72,160,W.colors.muted,1)
        battleHealth(scene,footer,true,24,30,360)
        return
    end
    local count=#scene.playerTeam.fighters
    local rows=math.max(1,math.ceil(count/2));local cardsBottom=112
    local cardsTop=cardsBottom+rows*86-6
    local teamY=cardsTop+12
    local team=W.panel(592,66,W.colors.paper,8);team:setPosition(cc.p(24,teamY));root:addChild(team,20)
    battleText(team,'船员',19,20,47,150)
    battleHealth(scene,team,true,20,22,364)
    local stageBottom=teamY+48
    local stageHeight=math.min(569,size.height-186-stageBottom)
    local stageScale=stageHeight/569
    relocate(scene.shipNodePlayer,root,320*(1-stageScale),stageBottom,1);scene.shipNodePlayer:setScale(stageScale)
    -- This is a bounded exact legacy portrait, not a claimed full-body actor.
    local enemyY=stageBottom+stageHeight*.35
    relocate(refs.monsterNode,root,320,enemyY,5)
    for i,actor in ipairs(scene.enemyActors)do
        local z=actor:getContentSize();actor:setScale(math.min(160/z.width,160/z.height))
        actor:setPosition(cc.p((i-(#scene.enemyActors+1)/2)*176,0))
        scene.enemyEffectActors[i]:setPosition(actor:getPosition())
    end
    scene.cleanBattlePortraitHeight=160
    relocate(scene.dlgNode,root,320,math.min(size.height-220,enemyY+128),24)
    local label=scene.dlgLabel;label:retain();label:removeFromParent(false);scene.dlgNode:removeAllChildren()
    local speech=W.panel(432,60,W.colors.paper,8);speech:setPosition(cc.p(-216,-30));scene.dlgNode:addChild(speech)
    scene.dlgNode:addChild(label);label:release();label:setPosition(cc.p(0,0));label:setColor(W.colors.ink)
    label:setFontSize(18);label:setDimensions(cc.size(400,48));label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    scene:hideMonasterDialogue()
    relocate(scene.bufferNode,root,320,teamY+92,22);scene.bufferNode:setScale(.55)
    relocate(scene.debufferNode,root,320,size.height-196,22);scene.debufferNode:setScale(.55)
    scene.cleanBattleCards={}
    local soldiers=DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
    local skills=DataManager:getInstance():getCSVByID(csvOfSkillAttribute)
    for i,fighter in ipairs(scene.playerTeam.fighters)do
        local col=(i-1)%2;local row=math.floor((i-1)/2)
        local card=W.panel(286,80,W.colors.paper,8)
        local cardX=(count==1) and 177 or 24+col*306
        card:setPosition(cc.p(cardX,cardsTop-80-row*86));root:addChild(card,20)
        scene.cleanBattleCards[i]=card
        local data=soldiers[tostring(fighter.soilderId)];local skill=skills[tostring(data.skill)]
        battleText(card,fighter.name,20,76,61,144)
        battleText(card,tostring(data.star)..' 星',13,270,61,42,W.colors.muted,1)
        local actor=relocate(scene.playerActors[i],card,35,40,2)
        local z=actor:getContentSize();actor:setScale(math.min(52/z.width,52/z.height))
        local button=battleItem(scene.playerAtkBtns[i],card,171,23,202,34,W.colors.paper)
        button:setVisible(false)
        battleText(button,'攻击',13,190,17,46,W.colors.sea,1)
        local skillText=battleText(card,skill and skill.name or '',17,76,38,140,W.colors.muted);skillText:setLocalZOrder(2)
        -- HP and skill are separate lines in one-by-one mode. Manual input
        -- remains the same indexed MenuItem with its original attack handler.
        local hp=battleText(card,tostring(fighter.hp)..'/'..tostring(fighter.m_hp),14,76,19,188,W.colors.coral)
        hp:setLocalZOrder(2);hp:setVisible(scene.fightMode==FightScene.FightMode.oneByOne);scene.playerHpLabels[i]=hp
        battleTrack(card,76,7,194,5,'player',false)
        scene.playerAtkPgBar[i]=battleTrack(card,76,7,194,5,'player',true)
        scene.playerAtkPgBar[i]:setScaleX(0)
    end
    relocate(scene.playerHealActors,root,320,cardsBottom+(cardsTop-cardsBottom)/2,25)
    relocate(scene.shipWarEffectNodeEnemy,root,320,enemyY+50,30)
    relocate(scene.shipWarEffectNodePlayer,root,320,teamY+36,30)
    local dock=W.panel(592,82,W.colors.paper,8);dock:setPosition(cc.p(24,16));root:addChild(dock,20)
    local instant=battleItem(refs.instant,dock,112,41,200,60,W.colors.paper)
    local food=battleItem(refs.food,dock,400,41,344,60,W.colors.sea)
    scene.cleanBattleActions={food=food,instant=instant}
    battleText(dock,'秒杀',22,112,52,158,W.colors.ink,.5)
    battleText(dock,'5 钻石',16,112,28,158,W.colors.muted,.5)
    battleText(dock,'吃食物',25,353,43,184,W.colors.white,.5)
    battleText(dock,'剩余',15,472,56,68,W.colors.white,.5)
    local num=scene.breadData and scene.breadData.num or 0
    scene.breadNumLabel=battleText(dock,tostring(num),20,472,32,120,W.colors.white,.5)
    scene.jyProgress=cc.Node:create();scene.jyProgress:setContentSize(cc.size(328,5));scene.jyProgress:setAnchorPoint(cc.p(0,.5))
    local gold=W.colors.gold;scene.jyProgress:addChild(cc.LayerColor:create(cc.c4b(gold.r,gold.g,gold.b,255),328,5))
    scene.jyProgress:setPosition(cc.p(236,18));dock:addChild(scene.jyProgress);scene.jyProgress:setScaleX(0)
    local bodies=require 'LuaClass/BoardingActors'
    bodies.attach(scene,{stageBottom=stageBottom,stageHeight=stageHeight,stageScale=stageScale})
end

return C
