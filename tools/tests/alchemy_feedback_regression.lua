-- Production ToastUtil + alchemy/addCoin code, isolated in-memory role storage.
-- Also runs in chart-lifecycle-native with actual Cocos nodes/actions/fonts.
local native = type(nativeEnter) == 'function'
if native then require('extern') else dofile('tools/tests/home_master_regression.lua') end
local originalRequire=require
require=function()return true end
local source='bin/res/scripts/LuaClass/'
dofile(source..'Header.lua')
dofile(source..'DataManager.lua')
dofile(source..'ToastUtil.lua')
require=originalRequire
local originalDirector=cc.Director.getInstance
local realDirector=originalDirector(cc.Director)
local scene=cc.Node:create()
if native then scene:retain() end
local notification=cc.Node:create();scene:addChild(notification)
local size=cc.size(640,1136)
cc.Director.getInstance=function()return{
    getVisibleSize=function()return size end,getRunningScene=function()return scene end,
    getNotificationNode=function()return notification end,
    getScheduler=function()return realDirector:getScheduler()end
}end
local function enter(n)
    if native then nativeEnter(n) end
end
local function leave(n)
    if native then nativeExit(n) else
        for _,child in ipairs(n:getChildren())do leave(child)end
        if n.scriptHandler then n.scriptHandler('exit')end
    end
end
local function advance(seconds)
    if native then for _=1,math.ceil(seconds/.05)do realDirector:getActionManager():update(.05)end end
end
local function makePage()
    local page=cc.Node:create();page.infoNode=cc.Node:create();page:addChild(page.infoNode)
    page.setBtn=cc.Node:create();page.setBtn:setPosition(320,130);page.infoNode:addChild(page.setBtn)
    scene:addChild(page);pNeedUpdateLayer=page;return page
end
local function badgeCount(host)
    local count=0;for _,n in ipairs(host:getChildren())do if n.isAlchemyToast then count=count+1 end end;return count
end
enter(scene)
local page=makePage()
local data={[roleMoney]=0,[roleAlchemyUnit]=1,[roleAlchemyCanLongPress]=0,[roleStorageInfo]={[achievement_Alchemy]=0}}
local dm=DataManager.new();DataManagerSingleton=dm
-- Preserve actual addCoin and AlchemyButtonDidClick arithmetic/callback order;
-- only persistence, guide UI and achievement unlocking are outside this test.
dm.__roleData={getRoleData=function(_,key)return data[key]end,getSound=function()return 1 end}
function dm:setRoleData(key,value)data[key]=value end
function dm:unlockAchievement()end
GuideController={getInstance=function(self)return self end,addStep=function()end,getIsHaveStep=function()return true end}
local first
for i=1,10 do
    dm:AlchemyButtonDidClick()
    local current
    for _,child in ipairs(page.infoNode:getChildren())do if child.isAlchemyToast then current=child end end
    assert(current,'successful alchemy must create feedback')
    first=first or current
    assert(current==first and badgeCount(page.infoNode)==1,'burst must reuse one native-owned badge')
    assert(current.alchemyAmount==i and current.alchemyTitle:getString()=='金币+'..i)
    advance(.3)
end
assert(data[roleMoney]==10 and data[roleStorageInfo][achievement_Alchemy]==10)
assert(#ToastUtil.infoQueue==0,'manual alchemy must not backlog generic notifications')
assert(first:getPositionY()==page.setBtn:getPositionY()+70,'badge stays beside alchemy control')
assert(dm:addCoin(-3)==1)
assert(data[roleMoney]==7 and first.alchemyTitle:getString()=='金币+10','immediate spending must not leave a duplicate outdated total')
dm:AlchemyButtonDidClick()
assert(data[roleMoney]==8 and first.alchemyTitle:getString()=='金币+11','receipt must not present a stale balance after spending')
print('PASS alchemy ten-click single badge, exact coin/achievement increments, no stale balance after spending')

for _,message in ipairs({'成就：炼金I','钻石+1','建造成功'})do ToastUtil:downString(message)end
for _=1,3 do dm:AlchemyButtonDidClick()end
local found={}
for _,message in ipairs(ToastUtil.infoQueue)do found[message]=true end
local function collectShown(node)
    local text=node.getString and node:getString()
    if text then found[text]=true end
    for _,child in ipairs(node:getChildren())do collectShown(child) end
end
collectShown(notification)
assert(found['成就：炼金I'] and found['钻石+1'] and found['建造成功'],'distinct important feedback is retained')
assert(badgeCount(page.infoNode)==1)
if native then advance(2) else
    local action=first.actions[1];action.args[2].args[1]()
end
assert(not first:isVisible() and first.alchemyAmount==0,'idle badge expires and resets burst total')
local reused=ToastUtil:alchemyCoins(2)
assert(reused==first and reused.alchemyAmount==2 and reused:isVisible())
print('PASS alchemy idle reset and independent achievement, diamond and construction messages')

leave(page)
assert(not first:isVisible() and first.alchemyAmount==0,'exiting page clears pending feedback')
enter(page)
assert(ToastUtil:alchemyCoins(1)==first and badgeCount(page.infoNode)==1,'push/pop must not accumulate badges')
page:removeFromParent()
pNeedUpdateLayer=nil
if native then nativeDrain() end
local nextPage=makePage();local fresh=ToastUtil:alchemyCoins(1)
assert(fresh~=first and fresh.alchemyAmount==1 and badgeCount(nextPage.infoNode)==1)
leave(scene);scene:cleanup()
if native then scene:release();nativeDrain() end
scene=nil;pNeedUpdateLayer=nil
assert(ToastUtil:alchemyCoins(1)==nil,'cold/no-scene feedback is safe')
cc.Director.getInstance=originalDirector
print('PASS alchemy native-owned page replacement, paused/reentered reuse, disposal and no-scene safety')
