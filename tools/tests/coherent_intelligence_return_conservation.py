#!/usr/bin/env python3
"""Exact four-file conservation against 2b4d21d, with narrow reviewed opt-ins.
Any change outside the literal presentation-only replacements is rejected.
The original unlock debit, rewards, learning, save schema and return transaction
remain byte-identical after normalization; mutation counterfactuals stay live.
"""
from pathlib import Path
import hashlib

ROOT=Path(__file__).resolve().parents[2]
RULES={'bin/res/scripts/LuaClass/DataManager.lua': {'sha256': '86bfb7311cf2f7ac3efb7b11c719239ca5633f7294dbff653a9fec33b9977dfd',
                                              'reverse': [('function DataManager:checkTallentPass(tallent, '
                                                           'costType, presentation)\n',
                                                           'function DataManager:checkTallentPass(tallent, '
                                                           'costType)\n'),
                                                          ('                    self:addDiamond(-needDiamod, '
                                                           'nil, nil, presentation)\n',
                                                           '                    '
                                                           'self:addDiamond(-needDiamod)\n'),
                                                          ('                    self:addDiamond(-needDiamod, '
                                                           'nil, nil, presentation)\n',
                                                           '                    '
                                                           'self:addDiamond(-needDiamod)\n')]},
 'bin/res/scripts/LuaClass/Explore.lua': {'sha256': '1125629a80d1cd6334804fbb82e823ca0f55a20eaf2b96036283d29d9f8d8c2a',
                                          'reverse': [('            local presentation\n'
                                                       "            if rawget(_G,'WARM_PIRATE_V1')~=false "
                                                       'then\n'
                                                       '                '
                                                       "presentation=require('LuaClass/WarmShortageOwnership').forOwner(self,'mapIndex')\n"
                                                       '            end\n',
                                                       ''),
                                                      ('                if presentation and not '
                                                       'presentation.isActive() then return end\n'
                                                       '                if '
                                                       'DataManager:getInstance():addDiamond(-price,nil,nil,presentation) '
                                                       '== 1 then\n',
                                                       '        \t\t\n'
                                                       '        \t\tif '
                                                       'DataManager:getInstance():addDiamond(-price) == 1 '
                                                       'then\n'),
                                                      ('    if self.warmShortageContext then '
                                                       'self.warmShortageContext.retire() end\n',
                                                       '')]},
 'bin/res/scripts/LuaClass/MissionManagers.lua': {'sha256': '54a6009e1fd1b315f2da95d6011db277851ad6a1c97353a35db749ab25ebce25',
                                                  'reverse': [('function Mission:completedMissionByCosted( '
                                                               'presentation )\n',
                                                               'function Mission:completedMissionByCosted(  '
                                                               ')\n'),
                                                              ('    if '
                                                               'DataManager:getInstance():addDiamond(-self.price, '
                                                               'nil, nil, presentation) == 0 then\n',
                                                               '    if '
                                                               'DataManager:getInstance():addDiamond(-self.price) '
                                                               '== 0 then\n')]},
 'bin/res/scripts/LuaClass/RandomEventMode.lua': {'sha256': 'b061c891d886bd441b77c85d076ce4697f1d6bcab8e8cfcb8020a4088f5e28e7',
                                                  'reverse': [('function RandomEventLayer:handleEvent(event, '
                                                               'costType, presentation)\n',
                                                               'function RandomEventLayer:handleEvent(event, '
                                                               'costType)\n'),
                                                              ('            local isSuccessed = '
                                                               'DataManager:getInstance():checkTallentPass(talent, '
                                                               'costType, presentation)\n',
                                                               '            local isSuccessed = '
                                                               'DataManager:getInstance():checkTallentPass(talent, '
                                                               'costType)\n'),
                                                              ('-- A list refresh keeps the same failed '
                                                               'offer usable. A different event/mission,\n'
                                                               '-- an expired target, a rebound view or a '
                                                               'closed view retires only its own offer.\n'
                                                               'function '
                                                               'RandomEventView:isIntelligenceTargetActive(event, '
                                                               'mission)\n'
                                                               '    if self._dialogueClosing or not '
                                                               'self:isVisible() or not self:getParent() '
                                                               'then return false end\n'
                                                               '    if mission then\n'
                                                               '        return '
                                                               'MissionManagers:getInstance().waitingMissions[mission.id]==mission\n'
                                                               '            and '
                                                               'mission:getMissionStatue()=="wait" and '
                                                               'mission:checkTime()\n'
                                                               '    end\n'
                                                               '    if '
                                                               'event.lifeTime-(os.time()-event.startTime)<=0 '
                                                               'then return false end\n'
                                                               '    for _,current in '
                                                               'ipairs(RandomEventManager:getInstance().eventList) '
                                                               'do\n'
                                                               '        if current==event then return true '
                                                               'end\n'
                                                               '    end\n'
                                                               '    return false\n'
                                                               'end\n'
                                                               '\n'
                                                               'function '
                                                               'RandomEventView:intelligencePresentation(event, '
                                                               'mission)\n'
                                                               "    if rawget(_G,'WARM_PIRATE_V1')==false "
                                                               'then return nil end\n'
                                                               '    local '
                                                               "ownership=require('LuaClass/WarmShortageOwnership')\n"
                                                               '    ownership.retire(self)\n'
                                                               '    return '
                                                               "ownership.forOwner(self,'warmIntelligenceGeneration',function()\n"
                                                               '        return '
                                                               'self:isIntelligenceTargetActive(event,mission)\n'
                                                               '    end)\n'
                                                               'end\n'
                                                               '\n'
                                                               'function RandomEventView:closeEffect()\n'
                                                               '    if self.warmShortageContext then '
                                                               'self.warmShortageContext.retire() end\n'
                                                               '    return DialogueView.closeEffect(self)\n'
                                                               'end\n'
                                                               '\n',
                                                               ''),
                                                              ('    if self.warmShortageContext then '
                                                               'self.warmShortageContext.retire() end\n'
                                                               '    '
                                                               'self.warmIntelligenceGeneration=(self.warmIntelligenceGeneration '
                                                               'or 0)+1\n',
                                                               ''),
                                                              ('        local binding={}\n'
                                                               '        '
                                                               'cell.warmIntelligenceBinding=binding\n'
                                                               '        local '
                                                               'generation=self.warmIntelligenceGeneration\n'
                                                               '        local missionState=mission and '
                                                               'mission:getMissionStatue()\n'
                                                               '        local '
                                                               'scene=cc.Director:getInstance():getRunningScene()\n'
                                                               '        local function activeRow()\n'
                                                               '            if '
                                                               "rawget(_G,'WARM_PIRATE_V1')==false then "
                                                               'return true end\n'
                                                               '            return self:getParent()~=nil and '
                                                               'not self._dialogueClosing and '
                                                               'self:isVisible()\n'
                                                               '                and '
                                                               'cc.Director:getInstance():getRunningScene()==scene\n'
                                                               '                and '
                                                               'self.warmIntelligenceGeneration==generation\n'
                                                               '                and '
                                                               'cell.warmIntelligenceBinding==binding and '
                                                               'cell:getParent()~=nil\n'
                                                               '                and (mission and '
                                                               'MissionManagers:getInstance().missions[mission.id]==mission\n'
                                                               '                    and '
                                                               'mission:getMissionStatue()==missionState\n'
                                                               '                    or not mission and '
                                                               'self:isIntelligenceTargetActive(event))\n'
                                                               '        end\n',
                                                               ''),
                                                              ('            if not activeRow() then return '
                                                               'end\n',
                                                               ''),
                                                              ('            if not activeRow() then return '
                                                               'end\n',
                                                               ''),
                                                              ('                    if not '
                                                               'RandomEventLayer.instance:handleEvent(event, '
                                                               '2, self:intelligencePresentation(event)) '
                                                               'then\n',
                                                               '                    if not '
                                                               'RandomEventLayer.instance:handleEvent(event, '
                                                               '2) then\n'),
                                                              ('                        '
                                                               'mission:completedMissionByCosted(self:intelligencePresentation(event,mission))\n',
                                                               '                        '
                                                               'mission:completedMissionByCosted()\n')]}}

INTELLIGENCE_STYLE_OPT_IN="    if require('LuaClass/WarmTheme').enabled() then\n        return require('LuaClass/IntelligencePresentation').mount(self, formatSecondToTimeCn)\n    end\n"

INTELLIGENCE_STYLE_PREFIX='-- init\nfunction RandomEventView:init()\n    if self.warmShortageContext then self.warmShortageContext.retire() end\n    self.warmIntelligenceGeneration=(self.warmIntelligenceGeneration or 0)+1\n    RandomEventView.instance = self\n'
INTELLIGENCE_STYLE_SUFFIX='\n--    DataManager:getInstance():addDiamond(100000)\n\n'
INTELLIGENCE_STYLE_ANCHOR=INTELLIGENCE_STYLE_PREFIX+INTELLIGENCE_STYLE_OPT_IN+INTELLIGENCE_STYLE_SUFFIX

# Optional map2 presentation is accepted only as the exact reviewed dormant
# diff, including three-line positional anchors. Normalize before the existing
# economy/ownership check, so both independent contracts remain strict. This is
# test-only and does not enable the runtime flag or modify source under test.
DORMANT_MAP2_EXPLORE_HUNKS = [('local AdventureProgress = require "LuaClass/AdventureProgress"\n'
  'local AdventureSea = require "LuaClass/AdventureSea"\n'
  'local CleanVoyageView = require "LuaClass/CleanVoyageView"\n'
  'local RaisedSeaMap2Live = require "LuaClass/RaisedSeaMap2Live"\n'
  'local CleanFirstMap = require "LuaClass/CleanFirstMap"\n'
  'require "LuaClass/Header"\n'
  'require "LuaClass/ExploreDataManager"\n',
  'local AdventureProgress = require "LuaClass/AdventureProgress"\n'
  'local AdventureSea = require "LuaClass/AdventureSea"\n'
  'local CleanVoyageView = require "LuaClass/CleanVoyageView"\n'
  'local CleanFirstMap = require "LuaClass/CleanFirstMap"\n'
  'require "LuaClass/Header"\n'
  'require "LuaClass/ExploreDataManager"\n'),
 ('    -- local t1 = os.clock()\n'
  '\n'
  ' \t--计算出来的角度是逆时针为正方向角度\n'
  '    local radian = (target.raisedMap2Live and '
  'RaisedSeaMap2Live.inputAngle(target,judgePos,ownerWdP)) or '
  'getRadianBetweenTwoPoints(judgePos,ownerWdP)\n'
  ' \t-- print("radian",radian)\n'
  '\n'
  ' \tif radian < 45 then\n',
  '    -- local t1 = os.clock()\n'
  '\n'
  ' \t--计算出来的角度是逆时针为正方向角度\n'
  ' \tlocal  radian = getRadianBetweenTwoPoints(judgePos,ownerWdP)\n'
  ' \t-- print("radian",radian)\n'
  '\n'
  ' \tif radian < 45 then\n'),
 ('end\n'
  '\n'
  '\n'
  '-- Shared by normal construction and isolated native input fixtures.\n'
  'function Explore:installChartTouchListener()\n'
  '    --添加touch事件\n'
  '    local listener = cc.EventListenerTouchOneByOne:create()\n'
  '    listener:registerScriptHandler(function ( touch,event )\n'
  '        return onTouchesBegan(self,touch,event)\n'
  '    end,cc.Handler.EVENT_TOUCH_BEGAN)\n'
  '    listener:registerScriptHandler(function ( touch,event )\n'
  '        onTouchesMoved(self,touch,event)\n'
  '    end,cc.Handler.EVENT_TOUCH_MOVED )\n'
  '    listener:registerScriptHandler(function ( touch,event )\n'
  '        onTouchesEnd(self,touch,event)\n'
  '    end,cc.Handler.EVENT_TOUCH_ENDED )\n'
  '    listener:registerScriptHandler(function ( touch,event )\n'
  '        -- print("onTouchCancelledL")\n'
  '        onTouchCancelled(self,touchcount,event)\n'
  '    end,cc.Handler.EVENT_TOUCH_CANCELLED)\n'
  '    -- listener:setFixedPriority(-127)\n'
  '    local eventDispatcher = self:getEventDispatcher()\n'
  '    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)\n'
  '    eventDispatcher:setPriority(listener,-130)\n'
  'end\n'
  '\n'
  'function Explore:init(index)\n'
  '\n'
  '\t-- local ids = getCustomTable()\n',
  'end\n\n\nfunction Explore:init(index)\n\n\t-- local ids = getCustomTable()\n'),
 ('   \t-- print("dic")\n'
  '\n'
  '   \t-- print("initTipLayered")\n'
  '    self:installChartTouchListener()\n'
  '\t\n'
  '    --添加迷雾管理者\n'
  '    self.fogManager = FogManager:create()\n',
  '   \t-- print("dic")\n'
  '\n'
  '   \t-- print("initTipLayered")\n'
  '   \t--添加touch事件\n'
  '   \tlocal listener = cc.EventListenerTouchOneByOne:create()\n'
  '    listener:registerScriptHandler(function ( touch,event )\n'
  '    \treturn onTouchesBegan(self,touch,event)\n'
  '    end,cc.Handler.EVENT_TOUCH_BEGAN)\n'
  '    listener:registerScriptHandler(function ( touch,event )\n'
  '    \tonTouchesMoved(self,touch,event)\n'
  '    end,cc.Handler.EVENT_TOUCH_MOVED )\n'
  '    listener:registerScriptHandler(function ( touch,event )\n'
  '    \tonTouchesEnd(self,touch,event)\n'
  '    end,cc.Handler.EVENT_TOUCH_ENDED )\n'
  '    listener:registerScriptHandler(function ( touch,event )\n'
  '    \t-- print("onTouchCancelledL")\n'
  '    \tonTouchCancelled(self,touchcount,event)\n'
  '    end,cc.Handler.EVENT_TOUCH_CANCELLED)\n'
  '    -- listener:setFixedPriority(-127)\n'
  '    local eventDispatcher = self:getEventDispatcher()\n'
  '    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)\n'
  '    eventDispatcher:setPriority(listener,-130)\n'
  '\t\n'
  '    --添加迷雾管理者\n'
  '    self.fogManager = FogManager:create()\n'),
 ('        arrow:setPosition(cc.p(29 * u, 27 * u))\n'
  '        arrow:setRotation(angle)\n'
  '        node.item:addChild(arrow, 3)\n'
  '        self.raisedMap2Arrows=self.raisedMap2Arrows or {}\n'
  '        '
  'table.insert(self.raisedMap2Arrows,{node=arrow,angle=angle,button=node.item,direction=direction})\n'
  '    end\n'
  '    directionButton(UpDiriction, 410, 178, 0)\n'
  '    directionButton(LeftDirction, 352, 125, -90)\n',
  '        arrow:setPosition(cc.p(29 * u, 27 * u))\n'
  '        arrow:setRotation(angle)\n'
  '        node.item:addChild(arrow, 3)\n'
  '    end\n'
  '    directionButton(UpDiriction, 410, 178, 0)\n'
  '    directionButton(LeftDirction, 352, 125, -90)\n'),
 ('\n'
  'function Explore:initMapByMapIndex( mapIndex,isclear )\n'
  '    if self.warmShortageContext then self.warmShortageContext.retire() end\n'
  '    if self.raisedMap2Live then RaisedSeaMap2Live.unmount(self)end\n'
  '    CleanVoyageView.unmount(self)\n'
  '\t--在加载的时候，不允许任何操作\n'
  '\tself.statue = "loading"\n',
  '\n'
  'function Explore:initMapByMapIndex( mapIndex,isclear )\n'
  '    if self.warmShortageContext then self.warmShortageContext.retire() end\n'
  '    CleanVoyageView.unmount(self)\n'
  '\t--在加载的时候，不允许任何操作\n'
  '\tself.statue = "loading"\n'),
 ('    self.adventureBreadCoefficient=breadCoefficient\n'
  '    AdventureSea.refresh(self,breadCoefficient)\n'
  '    CleanVoyageView.mount(self)\n'
  "    RaisedSeaMap2Live.mount(self)\n"
  'end\n'
  '\n'
  'function Explore:initPlayer( )\n',
  '    self.adventureBreadCoefficient=breadCoefficient\n'
  '    AdventureSea.refresh(self,breadCoefficient)\n'
  '    CleanVoyageView.mount(self)\n'
  'end\n'
  '\n'
  'function Explore:initPlayer( )\n'),
 ('end\n'
  '\n'
  'function Explore:clampChartPosition(position)\n'
  '    local raised=self.raisedMap2Live and RaisedSeaMap2Live.clamp(self,position);if raised then '
  'return raised end\n'
  '    local size = self.map:getContentSize()\n'
  '    local scale = self.moveLayer:getScale()\n'
  '    -- A Layer defaults to a centered anchor. Even with ignored positioning,\n',
  'end\n'
  '\n'
  'function Explore:clampChartPosition(position)\n'
  '    local size = self.map:getContentSize()\n'
  '    local scale = self.moveLayer:getScale()\n'
  '    -- A Layer defaults to a centered anchor. Even with ignored positioning,\n'),
 ('end\n'
  '\n'
  'function Explore:getCenterViewPositionByActualPosition( actualPosition )\n'
  '    if self.raisedMap2Live then '
  'actualPosition=RaisedSeaMap2Live.projectPoint(self,actualPosition)end\n'
  '\n'
  '\n'
  '\t--获取当前屏幕中心的位置相对于movelayer上的哪个位置\n',
  'end\n'
  '\n'
  'function Explore:getCenterViewPositionByActualPosition( actualPosition )\n'
  '\n'
  '\n'
  '\t--获取当前屏幕中心的位置相对于movelayer上的哪个位置\n'),
 ('\n'
  '\tself.fogManager:clearClearFogs()\n'
  '\tself:updataExtent(isUpdateTotalExtent)\n'
  '    if self.raisedMap2Live then RaisedSeaMap2Live.dirty(self)end\n'
  'end\n'
  '\n'
  '--改变坐标的迷雾\n',
  '\n'
  '\tself.fogManager:clearClearFogs()\n'
  '\tself:updataExtent(isUpdateTotalExtent)\n'
  'end\n'
  '\n'
  '--改变坐标的迷雾\n'),
 ('\t\tgid = 42\n'
  '\tend\n'
  '\tself.meta:setTileGID(gid,titlePosition)\n'
  '    if self.raisedMap2Live then RaisedSeaMap2Live.dirty(self)end\n'
  '\n'
  'end\n'
  '\n',
  '\t\tgid = 42\n\tend\n\tself.meta:setTileGID(gid,titlePosition)\n\nend\n\n')]

def normalize_dormant_map2(source):
    if 'RaisedSeaMap2Live' not in source:
        return source
    for current, original in DORMANT_MAP2_EXPLORE_HUNKS:
        assert source.count(current)==1, 'Missing, duplicated or relocated exact dormant map2 hook'
        source=source.replace(current,original,1)
    return source

def validate(path, source):
    if path=='bin/res/scripts/LuaClass/Explore.lua':
        source=normalize_dormant_map2(source)
    if path=='bin/res/scripts/LuaClass/RandomEventMode.lua':
        assert source.count(INTELLIGENCE_STYLE_OPT_IN)==1, 'Missing or duplicated exact intelligence style opt-in'
        assert source.count(INTELLIGENCE_STYLE_ANCHOR)==1, 'Intelligence dispatch must follow exact ownership setup and precede legacy boundary'
        source=source.replace(INTELLIGENCE_STYLE_ANCHOR,INTELLIGENCE_STYLE_PREFIX+INTELLIGENCE_STYLE_SUFFIX,1)
    rule=RULES[path]
    for current, original in rule['reverse']:
        assert current in source, 'Missing reviewed ownership edit: '+path
        source=source.replace(current,original,1)
    assert hashlib.sha256(source.encode()).hexdigest()==rule['sha256'], 'Gameplay/source conservation: '+path

for path in RULES:
    source=(ROOT/path).read_text()
    validate(path,source)
    print('PASS exact source conservation: '+path)

mutations=[
 ('RandomEventMode.lua',".mount(self, formatSecondToTimeCn)",".mount(nil, formatSecondToTimeCn)"),
 ('RandomEventMode.lua',"if require('LuaClass/WarmTheme').enabled() then","if true then"),
 ('RandomEventMode.lua',"    RandomEventView.instance = self","    RandomEventView.instance = nil"),
 ('DataManager.lua','self:addDiamond(-needDiamod, nil, nil, presentation)','self:addDiamond(-needDiamod-1, nil, nil, presentation)'),
 ('DataManager.lua','self:handleTallentItemAddition(value)','self:handleTallentItemAddition(nil)'),
 ('Explore.lua','addDiamond(-price,nil,nil,presentation)','addDiamond(-price-1,nil,nil,presentation)'),
 ('Explore.lua','self.bagController:safeTransformCoinToPack(statue)','self.bagController:safeTransformCoinToPack(nil)'),
 ('MissionManagers.lua','addDiamond(-self.price, nil, nil, presentation)','addDiamond(-self.price-1, nil, nil, presentation)'),
 ('MissionManagers.lua','self.complete[k].num = v','self.complete[k].num = v + 1'),
 ('RandomEventMode.lua','unlockTallentByKey(talent.ID, costType)','unlockTallentByKey(talent.ID, nil)'),
 ('RandomEventMode.lua','if not activeRow() then return end','if false then return end'),
]
for name, old, new in mutations:
    path='bin/res/scripts/LuaClass/'+name
    source=(ROOT/path).read_text();assert old in source
    try: validate(path,source.replace(old,new,1))
    except AssertionError: print('PASS conservation rejects counterfactual: '+name+' / '+old)
    else: raise AssertionError('Mutation escaped conservation: '+name+' / '+old)

# The exact dispatch bytes are insufficient: moving the early return above any
# ownership setup would still normalize to the baseline while skipping it live.
path='bin/res/scripts/LuaClass/RandomEventMode.lua'
source=(ROOT/path).read_text();lines=INTELLIGENCE_STYLE_PREFIX.splitlines(keepends=True)
for label,index in [('before-retirement',2),('before-generation',3),('before-singleton',4)]:
    misplaced=''.join(lines[:index])+INTELLIGENCE_STYLE_OPT_IN+''.join(lines[index:])+INTELLIGENCE_STYLE_SUFFIX
    relocated=source.replace(INTELLIGENCE_STYLE_ANCHOR,misplaced,1)
    assert relocated!=source and relocated.count(INTELLIGENCE_STYLE_OPT_IN)==1
    try: validate(path,relocated)
    except AssertionError as error:
        assert 'exact ownership setup' in str(error), 'Relocation failed for an unrelated reason: '+str(error)
        print('PASS conservation rejects dispatch relocation: '+label)
    else: raise AssertionError('Relocated dispatch escaped conservation: '+label)

# Optional-map positive and negative contracts also run on the core-only branch:
# construct the exact reviewed view of Explore rather than skipping coverage.
path='bin/res/scripts/LuaClass/Explore.lua'
source=(ROOT/path).read_text()
core=normalize_dormant_map2(source)
validate(path,core)
reviewed=core
for current, original in DORMANT_MAP2_EXPLORE_HUNKS:
    assert reviewed.count(original)==1, 'Reviewed map2 anchor is not unique'
    reviewed=reviewed.replace(original,current,1)
validate(path,reviewed)
print('PASS exact dormant map2 hook normalization and unchanged original route')
for index,(current,original) in enumerate(DORMANT_MAP2_EXPLORE_HUNKS,1):
    # Corrupt a positional anchor, duplicate the block, and move it elsewhere.
    # Retaining the literal hook bytes is insufficient without the exact site.
    variants=[
      ('anchor-mutation',reviewed.replace(current,current.replace('\n','\n-- mutated positional anchor\n',1),1)),
      ('duplicate',reviewed.replace(current,current+current,1)),
      ('relocation',reviewed.replace(current,original,1)+'\n'+current),
    ]
    for label,changed in variants:
        try:validate(path,changed)
        except AssertionError:print('PASS map2 conservation rejects '+label+': '+str(index))
        else:raise AssertionError('Map2 hook mutation escaped: '+label+'/'+str(index))
retire='    if self.warmShortageContext then self.warmShortageContext.retire() end\n'
unmount='    if self.raisedMap2Live then RaisedSeaMap2Live.unmount(self)end\n'
assert retire+unmount in reviewed
try:validate(path,reviewed.replace(retire+unmount,unmount+retire,1))
except AssertionError:print('PASS map2 conservation rejects unmount before ownership retirement')
else:raise AssertionError('Reordered owner retirement escaped')
