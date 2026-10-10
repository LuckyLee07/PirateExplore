-- Exercise production camera functions with native-point map bounds.
-- No game state, display, save or event manager is opened by this test.
require = function() return {} end
cc = {
    p = function(x,y) return {x=x,y=y} end,
    size = function(w,h) return {width=w,height=h} end,
    Layer = {create=function() return {} end}
}
class = function() return {} end
dofile('bin/res/scripts/LuaClass/Explore.lua')
local originalPrint=print
print=function(first,...)
    if first~='checkMapScale' and first~='EaseExponentialOut' and first~='move'
        and first~='curstatue' and first~='addmove1111' and first~='triggeringEventOfWating' then originalPrint(first,...) end
end
cc.MoveTo={create=function(_,duration,target)return {duration=duration,target=target}end}
cc.DelayTime={create=function(_,duration)return {duration=duration}end}
cc.CallFunc={create=function(_,callback)return {callback=callback}end}
cc.EaseExponentialOut={create=function(_,action)return action end}
cc.Sequence={create=function(_,...)
    return {children={...},setTag=function(self,tag)self.tag=tag end}
end}

local function close(a,b) assert(math.abs(a-b)<1e-7, tostring(a)..' ~= '..tostring(b)) end
local function upvalue(fn, wanted)
    for i=1,100 do
        local name, value = debug.getupvalue(fn,i)
        if name == wanted then return value end
        if not name then break end
    end
    error('missing production touch callback '..wanted)
end
local began = upvalue(Explore.init,'onTouchesBegan')
local moved = upvalue(Explore.init,'onTouchesMoved')
local cancelled = upvalue(Explore.init,'onTouchCancelled')
local function origin(layer)
    return layer.x+(layer.anchorX or 0)*(1-layer.scale),
        layer.y+(layer.anchorY or 0)*(1-layer.scale)
end
getRelativePositionOfViewCenterByNode = function(layer)
    local x,y=origin(layer)
    return {x=(screenSize.width/2-x)/layer.scale,
        y=(screenSize.height/2-y)/layer.scale}
end
local cases, edgeTiles = 0, 0
for mapIndex=1,16 do
    local f = assert(io.open('bin/res/assets/Images/Map/map_'..mapIndex..'.tmx'))
    local xml=f:read('*a');f:close()
    local mapTag=assert(xml:match('<map%s+([^>]+)>'))
    local cols=assert(tonumber(mapTag:match('width="(%d+)"')))
    local rows=assert(tonumber(mapTag:match('height="(%d+)"')))
    for _, factor in ipairs({1,2}) do
        local width,height=cols*64/factor,rows*64/factor
        for _, screen in ipairs({{640,853},{640,1136},{540,960},{480,800}}) do
            screenSize=cc.size(screen[1],screen[2])
            local u=screenSize.width/640
            local bottom,top=222*u,screenSize.height-124*u
            for _, scale in ipairs({.3,.8,1}) do
                local layer={x=0,y=0,scale=scale,actions={},
                    anchorX=screenSize.width/2,anchorY=screenSize.height/2}
                function layer:getPosition() return self.x,self.y end
                function layer:getPositionX() return self.x end
                function layer:getPositionY() return self.y end
                function layer:getScale() return self.scale end
                function layer:setScale(s) self.scale=s end
                function layer:setPosition(x,y)
                    if type(x)=='table' then self.x,self.y=x.x,x.y else self.x,self.y=x,y end
                end
                function layer:runAction(action) self.actions[action.tag]=action end
                function layer:stopActionByTag(tag) self.actions[tag]=nil end
                local owner=setmetatable({moveLayer=layer,adventureHudBottom=bottom,
                    adventureHudTop=top,statue='ready',jointed={enable=true},
                    contentOffset={x=0,y=0},mapSize=cc.size(-1,-1)}, {__index=Explore})
                owner.map={
                    getContentSize=function()return cc.size(width,height)end,
                    getMapSize=function()return cc.size(cols,rows)end,
                    getTileSize=function()return cc.size(64,64)end,
                    convertToWorldSpace=function(_,p)
                        local x,y=origin(layer);return cc.p(x+p.x*layer.scale,y+p.y*layer.scale)
                    end
                }
                function owner:convertToNodeSpace(p) return p end
                function owner:runAction(action) self.completion=action end
                local function verify()
                    local w,h=width*layer.scale,height*layer.scale
                    local x,y=origin(layer)
                    if w<=screenSize.width then close(x,(screenSize.width-w)/2)
                    else assert(x<=1e-7 and x+w>=screenSize.width-1e-7) end
                    if h<=top-bottom then close(y,(top+bottom-h)/2)
                    else assert(y<=bottom+1e-7 and y+h>=top-1e-7) end
                end
                -- Actual drag callback, including extreme overscroll in every
                -- direction; stale cached mapSize must never affect the bounds.
                for _, corner in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}}) do
                    local p=cc.p(screenSize.width/2,(bottom+top)/2)
                    local touch={getLocation=function()return p end}
                    assert(began(owner,touch))
                    p=cc.p(p.x+corner[1]*1e6,p.y+corner[2]*1e6)
                    moved(owner,touch)
                    verify();cancelled(owner,touch)
                end
                -- Use the original gameplay conversion at the application's
                -- actual content factor 1. Factor 2 above/below is a camera-
                -- geometry check only: gameplay still uses source tile pixels.
                local function edge(x,y)
                    local target=owner:positionForTilePosition(cc.p(x,y))
                    owner:setViewpointCenter(target);verify()
                    local x,y=origin(layer)
                    local px,py=x+target.x*layer.scale,y+target.y*layer.scale
                    assert(px>=0 and px<=screenSize.width and py>=bottom and py<=top)
                    assert(owner.contentOffset.x==0 and owner.contentOffset.y==0)
                    edgeTiles=edgeTiles+1
                end
                if factor==1 then
                    for x=0,cols-1 do edge(x,0);edge(x,rows-1) end
                    for y=1,rows-2 do edge(0,y);edge(cols-1,y) end
                end
                -- Repeated initial-scale and pinch paths use the same clamp.
                for _, nextScale in ipairs({1,.3,.8,.3,1,scale}) do
                    owner:setZoomScale(nextScale);verify()
                    owner:setMapScale(nextScale);verify()
                end
                -- An old-scale MoveTo must not overwrite a newer pinch or
                -- recenter. Unrelated actions and the gameplay completion
                -- sequence keep their identity and are never executed here.
                local unrelated={}
                layer.actions[777]=unrelated
                for _, interrupt in ipairs({'setZoomScale','setMapScale','setViewpointCenter'}) do
                    owner:slowlyMoveViewpointCenter(cc.p(width-32/factor,height-32/factor))
                    local completion=owner.completion
                    assert(completion.children[1].duration==2.7)
                    local cameraTag
                    for tag in pairs(layer.actions) do if tag~=777 then cameraTag=tag end end
                    assert(cameraTag,'production camera tween needs an interruptible tag')
                    if interrupt=='setViewpointCenter' then owner[interrupt](owner,cc.p(32/factor,32/factor))
                    else owner[interrupt](owner,.3) end
                    assert(not layer.actions[cameraTag] and layer.actions[777]==unrelated)
                    assert(owner.completion==completion,'camera changes must preserve gameplay completion')
                    verify()
                end
                cases=cases+1
            end
        end
    end
end
-- Run the original explored-water movement branch, interrupt only its camera
-- tween, then dispatch the original player/event, completion and save callbacks.
-- These collaborators are in-memory doubles; this is not native gameplay QA.
do
    screenSize=cc.size(640,1136)
    cc.rect=function(x,y,w,h)return {x=x,y=y,width=w,height=h}end
    local function node(x,y)
        local n={x=x or 0,y=y or 0,scale=.8,actions={}}
        function n:getPosition()return self.x,self.y end
        function n:getPositionX()return self.x end
        function n:getPositionY()return self.y end
        function n:setPosition(p)self.x,self.y=p.x,p.y end
        function n:getScale()return self.scale end
        function n:setScale(s)self.scale=s end
        function n:runAction(a)self.actions[#self.actions+1]=a end
        function n:stopAllActions()self.actions={} end
        function n:stopActionByTag(tag)
            for i=#self.actions,1,-1 do if self.actions[i].tag==tag then table.remove(self.actions,i) end end
        end
        function n:getNumberOfRunningActions()return #self.actions end
        return n
    end
    local layer,player,manager=node(),node(800,800),node()
    layer.anchorX,layer.anchorY=screenSize.width/2,screenSize.height/2
    local owner=node()
    setmetatable(owner,{__index=Explore})
    owner.moveLayer,owner.player,owner.mapLayoutManagers=layer,player,manager
    owner.adventureHudBottom,owner.adventureHudTop=222,1012
    owner.mapSize,owner.visition=cc.size(1344,1344),1
    owner.contentOffset={x=0,y=0}
    owner.moveWaitingQueue,owner.moveDirectionQueue={{x=64,y=0}},{2}
    owner.jointed={enable=true,tipingByDirection=function()end}
    local blank={getTileGIDAt=function()return 0 end}
    owner.map={getContentSize=function()return cc.size(1344,1344)end,
        getMapSize=function()return cc.size(21,21)end,getTileSize=function()return cc.size(64,64)end,
        getLayer=function()return blank end,getPropertiesForGID=function()return nil end,
        convertToWorldSpace=function(_,p)
            local x,y=origin(layer);return cc.p(x+p.x*layer.scale,y+p.y*layer.scale)
        end}
    function owner:convertToNodeSpace(p)return p end
    owner.meta=blank
    local triggered,costs,reveals,saves=0,0,0,0
    owner.eventManger={willTriggerEventById=function(_,id)assert(id==0)end,
        triggeringEventOfWating=function()triggered=triggered+1 end,minesweeper=function()return false end}
    owner.moveAudioEffect=function()end
    owner.costbread=function()costs=costs+1 end
    owner.checkClearFogs=function()end
    owner.clearFogs=function()reveals=reveals+1 end
    roleMapInfo=2
    GuideController={getInstance=function()return {getIsHaveStep=function()return true end}end}
    local saved={}
    DataManager={getInstance=function()return {
        getRoleData=function()return saved end,
        setRoleData=function(_,key,value)assert(key==roleMapInfo and value==saved);saves=saves+1 end
    }end}
    owner:tryToMoveForDirction({x=64,y=0})
    assert(owner.statue=='lookAt' and #layer.actions==1 and player.x==864 and player.y==800)
    local playerAction,completion,saveAction=player.actions[1],owner.actions[1],manager.actions[1]
    owner:setZoomScale(.3)
    assert(#layer.actions==0 and player.actions[1]==playerAction and owner.actions[1]==completion
        and manager.actions[1]==saveAction,'zoom must only cancel its tagged camera action')
    local function dispatch(a)
        if a.children then for _,child in ipairs(a.children)do dispatch(child)end
        elseif a.callback then a.callback() end
    end
    dispatch(playerAction);dispatch(completion);dispatch(saveAction)
    assert(owner.statue=='ready' and owner.jointed.enable and triggered==1 and costs==1 and reveals==1 and saves==1)
    assert(saved.playerTitlePosition.x==13 and saved.playerTitlePosition.y==8)
end
print=originalPrint
print('PASS production chart pan, zoom and recenter: '..cases..' cases, '..edgeTiles..
    ' original-helper edge-cell checks at app content factor 1, all 16 maps, small-map centering, four screen sizes and interrupted tweens')
print('PASS content factor 2 camera bounds in isolation; this does not establish factor 2 gameplay-coordinate compatibility')
print('PASS interrupted production movement retains ready state, event dispatch, fog callback and saved tile position')
