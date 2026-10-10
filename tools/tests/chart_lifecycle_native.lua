-- This file runs inside the real native LuaEngine, with real cc objects and GL.
local W = require('LuaClass/SeaChartWorldTheme')
local S = require('LuaClass/SeaChartTheme')
local chart = cc.TMXTiledMap:create('Images/Map/map_1.tmx')
assert(chart)
chart:retain();nativeEnter(chart)
assert(S.tintFog(chart,chart:getLayer('Fogs')) and S.softenGrid(chart))
assert(nativePremultiplied(chart:getLayer('Fogs')) and nativePremultiplied(chart:getLayer('GridLayer')))
local grid=chart:getLayer('GridLayer')
local gridTexture=cc.Director:getInstance():getTextureCache():addImage('Images/UI/Adventure/SeaChart/Tiles/grid.png')
assert(gridTexture);gridTexture:setAliasTexParameters();grid:setTexture(gridTexture)
assert(S.softenGrid(chart) and nativeGridComposite(grid), 'real uploaded grid tinted transparent sea or overbrightened its border')
nativeDrain()
print('PASS native actual uploaded grid compositing: transparent pixels preserve sea RGB; border matches intended alpha')
local function chartLinked()
    return nativeLinked(chart:getLayer('Fogs'):getShaderProgram())
        and nativeLinked(chart:getLayer('GridLayer'):getShaderProgram())
end
local map = cc.Node:create()
local dispatcher = map:getEventDispatcher()
map:retain()
nativeEnter(map)
local program = cc.GLProgram:new()
assert(W.initProgram(program, W.coastSpriteVertexShader, W.coastFragmentShader))
local restores, disposed = 0, 0
local function callback(ok)
    assert(ok and nativeLinked(program), 'restored production shader must link')
    restores = restores + 1
end
assert(W.restoreProgram(map, 'coast-test', program, W.coastSpriteVertexShader, W.coastFragmentShader, callback))
local target = cc.RenderTexture:create(16,16)
assert(target)
map:addChild(target)
target:setVisible(false)
nativeFillMask(target)
target:getSprite():getTexture():setTexParameters(9729,9729,33071,33071)
local edge=cc.Sprite:createWithTexture(target:getSprite():getTexture())
edge:setShaderProgram(program)
map:addChild(edge)
-- Separate coast program so the production coast callback and counter callback
-- each reset one actual program once per context.
local coastProgram=cc.GLProgram:new()
assert(W.initProgram(coastProgram,W.coastSpriteVertexShader,W.coastFragmentShader))
edge:setShaderProgram(coastProgram)
W.restoreCoast(map,{groups={{target=target,edge=edge}}},coastProgram)
local state = map._seaChartLifecycle
local owner = state.owner
-- Re-registering a key replaces the callback and balances the retained program.
local references = program:getReferenceCount()
assert(W.restoreProgram(map, 'coast-test', program, W.coastSpriteVertexShader, W.coastFragmentShader, callback))
assert(program:getReferenceCount()==references and map._seaChartLifecycle.owner==owner)
local before = cc.EventListenerCustom:create('event_come_to_foreground',function() disposed=disposed+1 end)
dispatcher:addEventListenerWithFixedPriority(before,-1)
assert(W.onContextRestored(map,'order',function() assert(disposed==restores or disposed==restores+1) end))
local liveProgram=program:getProgram()
nativeBackground();nativeBackground()
assert(nativeCheckMask(target) and program:getProgram()==liveProgram and nativeLinked(program), 'preserved-context pause invalidated mask or shader')
for i=1,2 do nativeBackground();nativeRestore();assert(restores==i and nativeCheckMask(target) and chartLinked() and nativeGridComposite(grid)) end
nativeExit(chart)
nativeExit(map) -- same Node pause path used when its scene is pushed under battle
for i=3,4 do nativeBackground();nativeRestore();assert(restores==i and nativeCheckMask(target) and chartLinked() and nativeGridComposite(grid)) end
nativeEnter(map);nativeEnter(chart)
nativeBackground();nativeBackground();nativeRestore();assert(restores==5 and nativeCheckMask(target))
nativeExit(chart);chart:cleanup();chart:release()
nativeExit(map);map:cleanup()
assert(map._seaChartLifecycle==nil and next(state.callbacks)==nil)
map:cleanup() -- cleanup is safe if an owner also cleans its already-clean child
map:release()
dispatcher:removeEventListener(before)
nativeDrain();nativeRestore();assert(restores==5)
-- A map disposed before it ever enters must not leave a fixed listener behind.
local unopened=cc.Node:create()
local called=0
assert(W.onContextRestored(unopened,'pending',function()called=called+1 end))
unopened:cleanup(); nativeRestore();assert(called==0)

-- No cleanup/onEnter path: destruction must dissociate the native listener and
-- release shader holders, so a later event cannot call disposed Lua objects.
local abandoned=cc.Node:create()
local orphaned=0
assert(W.onContextRestored(abandoned,'orphan',function() orphaned=orphaned+1 end))
nativeDrain(); nativeRestore(); assert(orphaned==0)

-- Destroy a cached target between background and foreground. Its fixed native
-- callbacks must be gone before the new context dispatches the restore event.
local doomed=cc.RenderTexture:create(16,16)
doomed:retain();nativeFillMask(doomed);nativeDrain()
nativeBackground();doomed:release();nativeRestore()

-- Compile/link errors use real driver diagnostics and the production bool API.
-- Each failure clears shader/program IDs, allowing reuse and safe destruction.
local failedCompile=cc.GLProgram:new()
assert(not W.initProgram(failedCompile,W.coastVertexShader,'intentionally invalid GLSL'))
assert(failedCompile:getProgram()==0)
assert(W.initProgram(failedCompile,W.coastVertexShader,W.coastMaskFragmentShader))
assert(nativeLinked(failedCompile))
local failedVertex=cc.GLProgram:new()
assert(not W.initProgram(failedVertex,'invalid vertex GLSL',W.coastMaskFragmentShader))
assert(failedVertex:getProgram()==0)
local failedLink=cc.GLProgram:new()
local mismatchedFragment='varying vec3 v_texCoord; void main() { gl_FragColor=vec4(v_texCoord,1.0); }'
assert(not W.initProgram(failedLink,W.coastVertexShader,mismatchedFragment))
assert(failedLink:getProgram()==0)
assert(W.initProgram(failedLink,W.coastVertexShader,W.coastMaskFragmentShader))
assert(nativeLinked(failedLink))
nativeDrain()
local failureMap=cc.TMXTiledMap:create('Images/Map/map_1.tmx')
failureMap:retain();nativeEnter(failureMap)
local fog=failureMap:getLayer('Fogs')
local originalFragment=S.fogFragmentShader
S.fogFragmentShader='invalid optional fog GLSL'
assert(not S.tintFog(failureMap,fog))
S.fogFragmentShader=originalFragment
assert(S.tintFog(failureMap,fog))
local fogProgram=fog:getShaderProgram()
assert(S.restoreChartProgram(failureMap,'fog',fog,fogProgram,'invalid restored fog GLSL'))
nativeBackground();nativeRestore()
assert(fog:getShaderProgram()~=fogProgram and nativeLinked(fog:getShaderProgram()))
assert(fogProgram:getProgram()==0, 'holder must retain failed program without a GL handle')
assert(S.restoreChartProgram(failureMap,'fog',fog,fogProgram,originalFragment))
nativeBackground();nativeRestore()
assert(fog:getShaderProgram()==fogProgram and nativeLinked(fogProgram))
nativeExit(failureMap);failureMap:cleanup();failureMap:release()
nativeDrain()
print('PASS native invalid compile/link cleanup, initial optional-fog fallback, restored fog fallback and successful shader retry')
