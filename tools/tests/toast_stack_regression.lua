-- Real ToastUtil and measured native Cocos labels/actions when run in the EGL
-- harness. The normal Lua suite uses its established API-shaped node fixture.
-- No player save, economy or network is initialized.
local native=type(nativeEnter)=='function'
if native then require('extern') else dofile('tools/tests/home_master_regression.lua') end
local originalRequire=require;require=function()return true end
BoldFont='Arial-BoldMT'
dofile('bin/res/scripts/LuaClass/ToastUtil.lua');require=originalRequire
local originalDirector=cc.Director.getInstance
local real=originalDirector(cc.Director)
local size=cc.size(640,1136)
local scene=cc.Node:create();if native then scene:retain();nativeEnter(scene) end
local notification
local enter
if not native then
    local Node=getmetatable(cc.Node:create()).__index
    function Node:getChildren()local copy={};for i,c in ipairs(self.children)do copy[i]=c end;return copy end
    local addChild=Node.addChild
    function Node:addChild(child,z)
        addChild(self,child,z)
        if self.running then enter(child) end
    end
end
local function exit(node)
    if native then nativeExit(node) else
        node.running=false
        for _,child in ipairs(node:getChildren())do exit(child)end
        if node.scriptHandler then node.scriptHandler('exit')end
    end
end
enter=function(node)
    if native then nativeEnter(node) else
        for _,child in ipairs(node:getChildren())do enter(child)end
        node.running=true
        if node.scriptHandler then node.scriptHandler('enter')end
    end
end
local function replaceNotification()
    local nextNode=cc.Node:create()
    if native then real:setNotificationNode(nextNode) elseif notification then exit(notification) end
    notification=nextNode
    if not native then enter(notification) end
end
replaceNotification()
cc.Director.getInstance=function()return{
    getVisibleSize=function()return size end,getRunningScene=function()return scene end,
    getNotificationNode=function()return notification end
}end
pNeedUpdateLayer=nil
local function cards()
    local out={}
    for _,stack in ipairs(notification:getChildren())do
        if stack.isOrdinaryToastStack then
            for _,card in ipairs(stack:getChildren())do if card.toastText and card:isVisible() then out[#out+1]=card end end
        end
    end
    table.sort(out,function(a,b)return a:getPositionY()>b:getPositionY()end)
    return out
end
local function fire(node)
    local actions={};for _,a in ipairs(node.actions or {})do actions[#actions+1]=a end
    for _,a in ipairs(actions)do
        if not a.fired and a.kind=='Sequence' then
            a.fired=true
            for _,step in ipairs(a.args)do if step.kind=='CallFunc' then step.args[1]()end end
        end
    end
end
local seen,history,peak={},{},0
local function inspect()
    local current=cards();peak=math.max(peak,#current);assert(#current<=3)
    local previousBottom
    for _,card in ipairs(current)do
        local backdrop=card:getChildren()[1];local extent=backdrop:getContentSize()
        local top=card:getPositionY()+extent.height/2
        local bottom=card:getPositionY()-extent.height/2
        assert(top<=size.height*.5+160+.01 and bottom>=size.height*.35-.01,'measured card must stay within central safe region')
        assert(extent.width<=size.width-47,'wrapped card must fit visible width')
        if previousBottom then assert(top<=previousBottom-11.9,'important messages may never overlap')end
        previousBottom=bottom
        if not seen[card] then seen[card]=true;history[#history+1]=card.toastText end
    end
end
local function advance(seconds)
    if native then
        for _=1,math.ceil(seconds/.05)do real:getActionManager():update(.05);inspect()end
    else
        for _,stack in ipairs(notification:getChildren())do if stack.isOrdinaryToastStack then fire(stack) end end
        inspect()
    end
end
local function drain()
    if native then advance(10) else
        for _=1,20 do local current=cards();if #current==0 and #ToastUtil.infoQueue==0 then break end
            for _,card in ipairs(current)do fire(card);inspect()end
        end
    end
    assert(#cards()==0 and #ToastUtil.infoQueue==0,'burst must drain without a stuck playing/scheduler flag')
end
local expected={'已解锁成就：炼金 I','钻石+1','建设已解锁！','金币不足','船坞已解锁','建造成功','获得食物+5','获得木头+2','任务完成','获得铁+1'}
for i,message in ipairs(expected)do ToastUtil:downString(message,i==4)end
advance(.2);assert(#cards()==3,'free slots fill immediately, not one slow toast at a time')
assert(cards()[1].toastText==expected[1] and cards()[2].toastText==expected[2])
drain();assert(peak==3 and #history==#expected)
for i,message in ipairs(expected)do assert(history[i]==message,'every important message must appear exactly once in FIFO order')end
print('PASS toast stack ten important messages FIFO, maximum three, immediate free-slot filling, distinct limited error retained, no overlap')

for _,height in ipairs({1136,1066.6667})do
    size=cc.size(640,height);replaceNotification();seen={};history={}
    local long='已解锁新的海域：请准备足够的食物和船员，再从港口整备出航。'..string.rep('不同的重要提示必须完整显示，不能覆盖或截断。',5)
    ToastUtil:downString(long);ToastUtil:downString('钻石+1');ToastUtil:downString('建造成功')
    advance(.2);assert(#cards()>=1)
    assert(cards()[1]:getChildren()[2]:getString()==long,'long Chinese content must not be truncated')
    drain();assert(#history==3 and history[1]==long and history[2]=='钻石+1' and history[3]=='建造成功')
end
print('PASS toast stack long Chinese labels measured and wrapped at both target aspect ratios, full text retained within bounds')

size=cc.size(640,1136);replaceNotification();seen={};history={}
for i=1,5 do ToastUtil:downString('pending-'..i)end
advance(.2);local oldCards=cards();assert(#oldCards==3 and #ToastUtil.infoQueue==2)
-- Real ordinary scene exit does not exit Director's independent notification
-- node. Existing notices continue once, without holding a scene reference.
exit(scene);enter(scene);inspect();assert(#cards()==3 and #history==3)
local stale
if not native then stale=oldCards[1].actions[1].args[2].args[1]end
exit(notification);assert(#cards()==0 and #ToastUtil.infoQueue==2,'visible cards retire; unshown messages remain pending')
enter(notification);advance(.2)
assert(#cards()==2 and cards()[1].toastText=='pending-4' and cards()[2].toastText=='pending-5')
if stale then stale();assert(#cards()==2,'old completion callback cannot remove new cards')end
drain();assert(#history==5,'already shown messages are not replayed on notification reentry')
print('PASS toast stack ordinary scene exit independence, notification suspension FIFO, no replay and stale callback invalidation')

replaceNotification();seen={};history={}
for i=1,5 do ToastUtil:downString('replace-'..i)end
advance(.2);replaceNotification()
if native then nativeDrain() end
ToastUtil:downString('new-context');advance(.2)
assert(cards()[1].toastText=='replace-4' and cards()[2].toastText=='replace-5' and cards()[3].toastText=='new-context')
drain();assert(#history==6,'replaced layer retains only unshown FIFO, not old visible cards')
-- A delayed old-host pump must never inject a card into a replacement host.
ToastUtil:downString('not-yet-shown');replaceNotification();ToastUtil:downString('after-replace');advance(.2)
assert(#cards()==2 and cards()[1].toastText=='not-yet-shown' and cards()[2].toastText=='after-replace')
drain()
print('PASS toast stack notification replacement/destruction and delayed old-host callbacks preserve only unshown text FIFO')

if native then
    for i=1,5 do
        ToastUtil:downString('ownership-'..i)
        local old=notification;old:retain()
        local stack=old:getChildren()[1];stack:retain()
        assert(old:getNumberOfRunningActions()==0,'toast driver must not retain notification host')
        -- Other notification business actions are not ours to cancel.
        if i==5 then old:runAction(cc.DelayTime:create(50)) end
        replaceNotification();nativeDrain()
        assert(stack:getNumberOfRunningActions()==0,'exit cancels delayed stack driver')
        assert(stack:getReferenceCount()==2,'only native parent and explicit test retain remain')
        assert(old:getReferenceCount()==(i==5 and 2 or 1),'early replacement must not leak host through paused toast action')
        if i==5 then
            assert(old:getNumberOfRunningActions()==1,'unrelated notification action must remain untouched')
            old:stopAllActions()
        end
        old:release();assert(stack:getReferenceCount()==1);stack:release();nativeDrain()
    end
    ToastUtil:downString('after-ownership-check');advance(.2);drain()
    print('PASS native toast driver reference counts across repeated early replacements; unrelated host actions untouched')
end

replaceNotification();pNeedUpdateLayer=nil
ToastUtil:productionString('routine');ToastUtil:downString('important');advance(.2)
assert(#cards()==2)
pNeedUpdateLayer={isAdventureHome=true}
ToastUtil:quietHomeProductionToasts()
assert(#cards()==1 and cards()[1].toastText=='important','quiet Home must remove routine production only')
pNeedUpdateLayer=nil;drain()
if native then real:setNotificationNode(nil);exit(scene);scene:cleanup();scene:release();nativeDrain() else exit(notification) end
scene=nil;notification=nil
ToastUtil:downString('cold-before-notification')
assert(ToastUtil.infoQueue[1]=='cold-before-notification','no-notification startup preserves pending text')
replaceNotification();ToastUtil:downString('notification-ready');advance(.2)
assert(cards()[1].toastText=='cold-before-notification' and cards()[2].toastText=='notification-ready')
drain()
if native then real:setNotificationNode(nil);nativeDrain()end
cc.Director.getInstance=originalDirector
print('PASS toast stack production-only quiet policy, no-notification startup, cleanup and no new scheduler registrations')
