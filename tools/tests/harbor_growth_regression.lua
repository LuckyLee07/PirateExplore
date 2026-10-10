-- Uses the established native-node mock and real Home/HomeTheme implementations.
-- Pixel placement and paint fidelity still require the two-size native check.
dofile('tools/tests/home_master_regression.lua')
local function equal(a,b,why) assert(a==b,(why or 'value')..': '..tostring(a)..' ~= '..tostring(b)) end
cc.ClippingNode={create=function()
    local n=cc.Node:create()
    function n:setStencil(value) self.stencil=value end
    function n:setAlphaThreshold(value) self.alphaThreshold=value end
    return n
end}
local capacity=20
local state={version=1,enabled=true,npcRescued=false,firstReturnClaimed=false,objective='rescue'}
local reads,briefs=0,0
assert(rawget(_G,'AdventureProgress')==nil,'test must not inject an AdventureProgress global')
local progress=assert(package.loaded['LuaClass/AdventureProgress'],'real returned module loaded by HomeTheme')
local dm={getRoleData=function(_,key)
    reads=reads+1
    if key==progress.KEY then return state end
    equal(key,rolePackSize,'harbor reads only ledger and real capacity');return capacity
end}
local lastBrief
-- Only the native modal drawing is stubbed. HomeTheme -> real module import ->
-- getHarborStatus/getState and showHarborBrief all execute without a global.
local oldDialog=package.loaded['LuaClass/AdventureDialog']
package.loaded['LuaClass/AdventureDialog']={show=function(title,body,options,home)
    assert(home);briefs=briefs+1;lastBrief={title=title,body=body,options=options}
end}
for _,viewport in ipairs({{width=640,height=1136},{width=640,height=1067}}) do
    local home={content=cc.Node:create(),viewport=viewport,masterScaleX=viewport.width/941,masterScaleY=viewport.height/1672}
    capacity=20;state={version=1,enabled=true,npcRescued=false,firstReturnClaimed=false,objective='rescue',cargoUpgraded=true}
    HomeTheme.refreshGrowth(home,dm)
    equal(home.harborGrowthStatus.cargoUpgraded,false,'real capacity beats stale progress flag')
    equal(#home.harborGrowthLayer:getChildren(),1,'initial only briefing entry')
    local layer=home.harborGrowthLayer
    for i=1,30 do HomeTheme.refreshGrowth(home,dm) end
    equal(home.harborGrowthLayer,layer,'same state preserves layer')
    equal(#home.content:getChildren(),1,'no duplicate layer after refresh')
    equal(home.harborBriefButton.label:getString(),'本航目标  ›')
    home.harborBriefButton.item.callback();equal(briefs,viewport.height==1136 and 1 or 3,'brief routes once')
    home.goalDialog={};home.harborBriefButton.item.callback();home.goalDialog=nil
    equal(briefs,viewport.height==1136 and 1 or 3,'existing modal blocks second entry')
    capacity=30;state.cargoUpgraded=false
    HomeTheme.refreshGrowth(home,dm)
    equal(layer:getParent(),nil,'old layer detached on transition')
    equal(home.harborGrowthStatus.cargoUpgraded,true,'actual upgrade controls visible freight')
    equal(#home.harborGrowthLayer:getChildren(),3,'cargo and capacity legend added')
    local cargo=home.harborGrowthLayer:getChildren()[1]
    equal(#cargo:getChildren(),2,'two separate painted cargo boxes')
    for _,crate in ipairs(cargo:getChildren()) do
        assert(crate.stencil,'painted crate has silhouette stencil')
        equal(crate:getChildren()[1].path,'Images/UI/Adventure/Master/harbor-full.png','approved source art reused')
    end
    state.npcRescued=true;state.firstEventReturned=true;state.firstReturnClaimed=true;state.choice='rescue';state.gateClue='真实测试线索：北侧海湾'
    HomeTheme.refreshGrowth(home,dm)
    equal(#home.harborGrowthLayer:getChildren(),4,'returned rescue adds one signal flag')
    equal(home.harborBriefButton.label:getString(),'航图员林恩 · 航图线索  ›')
    local button=home.harborBriefButton;local box=button:getBoundingBox()
    local scale=home.masterScaleY
    assert(box.y>=viewport.height-975*scale,'brief remains above roster')
    assert(box.y+box.height<=viewport.height-805*scale,'brief remains below ship plaque')
    button.item.callback();equal(briefs,viewport.height==1136 and 2 or 4)
    equal(lastBrief.title,'航图员林恩','actual module supplies NPC title')
    assert(lastBrief.body:find(state.gateClue,1,true),'actual persisted gate clue reaches dialog')
    assert(rawget(_G,'AdventureProgress')==nil,'render and click never create a module global')
    state.npcRescued=false;state.choice='supply'
    HomeTheme.refreshGrowth(home,dm)
    equal(home.harborBriefButton.label:getString(),'港务记录 · 下一航  ›')
    equal(#home.harborGrowthLayer:getChildren(),3,'supplies do not invent rescued NPC')
    state={enabled=false,npcRescued=false}
    HomeTheme.refreshGrowth(home,dm)
    equal(home.harborBriefButton,nil,'legacy save gets no new task')
    equal(#home.harborGrowthLayer:getChildren(),2,'old upgraded save still shows actual freight')
    capacity=20;HomeTheme.refreshGrowth(home,dm)
    equal(#home.harborGrowthLayer:getChildren(),0,'non-upgraded legacy is unchanged')
    local finalLayer=home.harborGrowthLayer;home.homeDisposed=true;capacity=30
    HomeTheme.refreshGrowth(home,dm);equal(home.harborGrowthLayer,finalLayer,'disposed Home stays untouched')
    equal(#home.content:getChildren(),1,'every transition keeps exactly one presentation layer')
    home.homeDisposed=false
    local dialog=cc.Node:create();home.content:addChild(dialog);home.adventureDialog=dialog
    HomeLayer.openPrimary(home);HomeLayer.openGoals(home);HomeLayer.openRecovery(home);HomeLayer.openRoute(home,1)
    home.closeRecovery=function() end;home.closeSources=function() end
    HomeLayer.destory(home)
    equal(home.adventureDialog,nil,'destroy clears briefing ownership')
    equal(dialog:getParent(),nil,'destroy removes scene-owned briefing')
end
package.loaded['LuaClass/AdventureDialog']=oldDialog
assert(reads>60,'read-only refreshes exercised')
print('PASS harbor growth: real 20/30 capacity, rescue/supply/legacy matrix, two viewports, repeat/modal/dispose safety')
