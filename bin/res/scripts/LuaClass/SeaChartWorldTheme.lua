-- Display-only world materials. The live TMX owns every tile and gameplay rule.
-- Theme identity comes from each layer's actual atlas, never the chapter number.
SeaChartWorldTheme = {}
local W = SeaChartWorldTheme
W.path = "Images/UI/Adventure/SeaChart/"
W.chunkSide = 16
W.detailLimit = 96
-- A 15-tile interior and one half-tile gutter fit exactly in a 256px
-- quarter-resolution mask. All GPU targets are POT, including old GLES2.
W.coastChunkSide = 15
W.coastMaskPixels = 256
W.coastGutter = 32
W.families = {
    {name="sand", atlas="dt_ludi.png"},
    {name="forest", atlas="dt_senlin.png"},
    {name="volcanic", atlas="dt_huoshan.png"},
    {name="ice", atlas="dt_bingdao.png"},
    {name="violet", atlas="dt_ziseludi.png"},
    {name="ghost", atlas="dt_youlingdao.png"}
}

local function cache()
    return cc.Director:getInstance():getTextureCache()
end
local function scaleFactor()
    local director = cc.Director:getInstance()
    return director.getContentScaleFactor and director:getContentScaleFactor() or 1
end
local function offset(layer)
    return layer.getPositionX and layer:getPositionX() or 0,
        layer.getPositionY and layer:getPositionY() or 0
end
local function layerSize(map, layer)
    return layer.getLayerSize and layer:getLayerSize() or map:getMapSize()
end

-- This is the engine's context-restored event (CCEventType.h), not the app's
-- ordinary resume notification. A dedicated child keeps only its own listener
-- resumed under a pushed battle scene; gameplay on the map remains paused.
-- Node association also removes it if an unentered map is destroyed directly.
function W.onContextRestored(map, key, callback)
    if not cc.EventListenerCustom or not map or not map.addChild then return false end
    local state = map._seaChartLifecycle
    if not state then
        local owner = cc.Node:create()
        if not owner.registerScriptHandler then return false end
        local dispatcher = owner:getEventDispatcher()
        state = {callbacks={}, shaders={}, owner=owner}
        map._seaChartLifecycle = state
        local listener = cc.EventListenerCustom:create("event_come_to_foreground", function()
            for _, restore in pairs(state.callbacks) do restore() end
        end)
        -- Native RenderTexture's negative-priority callbacks restore FBOs first.
        dispatcher:addEventListenerWithSceneGraphPriority(listener, owner)
        owner:registerScriptHandler(function(event)
            if event == "exit" then
                dispatcher:resumeEventListenersForTarget(owner)
            elseif event == "cleanup" and not state.disposed then
                state.disposed = true
                dispatcher:removeEventListener(listener)
                state.callbacks = {}
                map._seaChartLifecycle = nil
            end
        end)
        map:addChild(owner)
        dispatcher:resumeEventListenersForTarget(owner)
    end
    state.callbacks[key] = callback
    return true
end

function W.initProgram(program, vertex, fragment)
    if not program or not program:initWithByteArrays(vertex, fragment) then return false end
    program:bindAttribLocation("a_position", 0)
    program:bindAttribLocation("a_color", 1)
    program:bindAttribLocation("a_texCoord", 2)
    if not program:link() then return false end
    program:updateUniforms()
    return true
end

function W.restoreProgram(map, key, program, vertex, fragment, completed)
    local added = W.onContextRestored(map, key, function()
        -- Context loss already freed these IDs. Deleting the old name could
        -- delete an unrelated program allocated in the new context.
        program:reset()
        completed(W.initProgram(program, vertex, fragment))
    end)
    if added then
        -- Native node ownership keeps a failed shader alive after the layer
        -- switches to its fallback, and releases it even without Lua cleanup.
        local state = map._seaChartLifecycle
        local holder = state.shaders[key]
        if not holder then
            holder = cc.Node:create()
            state.owner:addChild(holder)
            state.shaders[key] = holder
        end
        holder:setShaderProgram(program)
    end
    return added
end

function W.familyForLayer(layer)
    if not layer or not layer.getTexture then return nil end
    local textures, current = cache(), layer:getTexture()
    for _, family in ipairs(W.families) do
        local original = textures:getTextureForKey("Images/Map/" .. family.atlas)
        local paintedPath = W.path .. "Tiles/" .. family.atlas
        local painted = cc.FileUtils:getInstance():isFileExist(paintedPath)
            and textures:getTextureForKey(paintedPath) or nil
        if original and (current == original or (painted and current == painted)) then
            return family, original
        end
    end
end

-- Read every actual Blocks layer. Keep its original z, including maps where
-- Blocks_2 precedes Blocks_1 and two tilesets share one filename (chapter 16).
function W.landLayers(map)
    local result, seen = {}, {}
    if map.getChildren then
        for _, layer in ipairs(map:getChildren()) do
            if layer.getLayerName then
                local name = layer:getLayerName()
                if name:match("^Blocks_%d+$") then
                    result[#result+1] = layer
                    seen[layer] = true
                end
            end
        end
    end
    for _, name in ipairs({"Blocks_1", "Blocks_2"}) do
        local layer = map:getLayer(name)
        if layer and not seen[layer] then result[#result+1] = layer; seen[layer] = true end
    end
    table.sort(result, function(a, b) return a:getLocalZOrder() < b:getLocalZOrder() end)
    return result
end

local function material(paths, mirrored)
    local files, textures = cc.FileUtils:getInstance(), cache()
    for _, path in ipairs(paths) do
        if files:isFileExist(path) then
            local texture = textures:addImage(path)
            if texture and texture.setTexParameters then
                local width, height = texture:getPixelsWide(), texture:getPixelsHigh()
                if width == height and (width == 512 or width == 1024) then
                    -- MIRRORED_REPEAT joins the authored, non-periodic paint at
                    -- exactly matching pixels without repainting its artwork.
                    local wrap = mirrored and 33648 or 10497
                    texture:setTexParameters(9729, 9729, wrap, wrap)
                    return texture, path
                end
            end
        end
    end
end

function W.addWater(map)
    if not map.getLayer then return false end
    if map._seaChartWorldWater then return true end
    local sea = map:getLayer("Sea")
    local family = W.familyForLayer(sea)
    if not family then return false end
    local texture = material({W.path .. "Tiles/water-" .. family.name .. "-repeat.png",
        W.path .. "Tiles/sea-water-repeat.png"}, false)
    if not texture then return false end
    local size, tile, factor = layerSize(map, sea), map:getTileSize(), scaleFactor()
    local water = cc.Sprite:createWithTexture(texture)
    if not water then return false end
    water:setTextureRect(cc.rect(0, 0, size.width * tile.width / factor, size.height * tile.height / factor))
    water:setAnchorPoint(cc.p(0, 0))
    local x, y = offset(sea)
    water:setPosition(cc.p(x, y))
    map:addChild(water, sea:getLocalZOrder())
    sea:setVisible(false)
    map._seaChartWorldWater = water
    return true
end

-- Match CCTMXLayer::setupTileSprite, including all eight Tiled flip states.
-- Never use getTileAt: materializing original tiles changes the TMX batch.
function W.placeMaskTile(sprite, position, flags)
    sprite:setAnchorPoint(cc.p(0, 0))
    sprite:setPosition(position)
    local horizontal = math.floor(flags / 2147483648) % 2 == 1
    local vertical = math.floor(flags / 1073741824) % 2 == 1
    local diagonal = math.floor(flags / 536870912) % 2 == 1
    if diagonal then
        local size = sprite:getContentSize()
        sprite:setAnchorPoint(cc.p(.5, .5))
        sprite:setPosition(cc.p(position.x + size.height / 2, position.y + size.width / 2))
        if horizontal and not vertical then sprite:setRotation(90)
        elseif vertical and not horizontal then sprite:setRotation(270)
        elseif horizontal and vertical then sprite:setRotation(90); sprite:setFlippedX(true)
        else sprite:setRotation(270); sprite:setFlippedX(true) end
    else
        if horizontal then sprite:setFlippedX(true) end
        if vertical then sprite:setFlippedY(true) end
    end
end

local function protectedOrder(map, layer)
    local z = layer:getLocalZOrder()
    for _, name in ipairs({"Meta", "GridLayer", "Fogs"}) do
        local overlay = map:getLayer(name)
        if overlay and overlay.getLocalZOrder and overlay:getLocalZOrder() <= z then return false end
    end
    return true
end

W.coastVertexShader = [[
attribute vec4 a_position;
attribute vec2 a_texCoord;
attribute vec4 a_color;
#ifdef GL_ES
varying lowp vec4 v_fragmentColor;
varying mediump vec2 v_texCoord;
#else
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
#endif
void main() {
    gl_Position = CC_MVPMatrix * a_position;
    v_fragmentColor = a_color;
    v_texCoord = a_texCoord;
}
]]
-- Sprite QuadCommand already transforms vertices on the CPU in this engine;
-- SpriteBatchNode does not. Applying MVP to the displayed sprite would apply
-- its scale and map translation twice, moving its alpha far from the coast.
W.coastSpriteVertexShader = W.coastVertexShader:gsub("CC_MVPMatrix", "CC_PMatrix")
W.coastMaskFragmentShader = [[
#ifdef GL_ES
precision mediump float;
varying lowp vec4 v_fragmentColor;
varying mediump vec2 v_texCoord;
#else
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
#endif
uniform sampler2D CC_Texture0;
void main() {
    float a = texture2D(CC_Texture0, v_texCoord).a;
    gl_FragColor = vec4(v_fragmentColor.rgb * a, a);
}
]]
W.coastFragmentShader = [[
#ifdef GL_ES
precision mediump float;
varying lowp vec4 v_fragmentColor;
varying mediump vec2 v_texCoord;
#else
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
#endif
uniform sampler2D CC_Texture0;
// The texture is a union of ORIGINAL atlas alpha, including neighboring tiles.
// One UV unit is 1024 original map pixels, irrespective of content scale.
float land(vec2 p) {
    return smoothstep(0.22, 0.78, texture2D(CC_Texture0, p).a);
}
void main() {
    vec2 p = v_texCoord;
    vec2 d = vec2(0.0009765625);
    vec4 source = texture2D(CC_Texture0, p);
    float a = smoothstep(0.22, 0.78, source.a);
    float n = land(p + vec2(0.0, 7.0) * d);
    float s = land(p - vec2(0.0, 7.0) * d);
    float e = land(p + vec2(7.0, 0.0) * d);
    float w = land(p - vec2(7.0, 0.0) * d);
    float nearMin = min(min(n, s), min(e, w));
    nearMin = min(nearMin, land(p + vec2(5.0, 5.0) * d));
    nearMin = min(nearMin, land(p + vec2(-5.0, 5.0) * d));
    nearMin = min(nearMin, land(p + vec2(5.0, -5.0) * d));
    nearMin = min(nearMin, land(p - vec2(5.0, 5.0) * d));
    // OPAQUE_INTERIOR_EARLY_RETURN_BEGIN
    // Every later term is exactly zero here. Skip twelve farther taps on
    // opaque interiors without changing any shoreline or partial-alpha pixel.
    if (a == 1.0 && nearMin == 1.0) {
        gl_FragColor = vec4(0.0);
        return;
    }
    // OPAQUE_INTERIOR_EARLY_RETURN_END
    float far = land(p + vec2(0.0, 16.0) * d);
    far += land(p - vec2(0.0, 16.0) * d);
    far += land(p + vec2(16.0, 0.0) * d);
    far += land(p - vec2(16.0, 0.0) * d);
    far += land(p + vec2(11.0, 11.0) * d);
    far += land(p + vec2(-11.0, 11.0) * d);
    far += land(p + vec2(11.0, -11.0) * d);
    far += land(p - vec2(11.0, 11.0) * d);
    float shallows = (1.0 - a) * min(1.0, far * 0.24);
    float closest = max(max(land(p + vec2(2.5, 0.0) * d), land(p - vec2(2.5, 0.0) * d)),
                        max(land(p + vec2(0.0, 2.5) * d), land(p - vec2(0.0, 2.5) * d)));
    // Both periods divide the 960px chunk interior. The broken line therefore
    // has one global phase, not a newly repeated edge at each tile/chunk.
    vec2 world = p * 1024.0;
    float wave = sin(world.x * 0.0523598776 + sin(world.y * 0.0654498469) * 1.8);
    float breaks = smoothstep(-0.25, 0.6, wave);
    float foam = (1.0 - a) * closest * breaks * 0.72;
    // South-facing edges receive a dark undercut outside the true shoreline;
    // the inner ledge is always constrained by the original land alpha.
    float undercut = (1.0 - a) * n * 0.50;
    float inner = a * (1.0 - nearMin);
    float shade = inner * (0.20 + max(0.0, n - s) * 0.28);
    float lip = inner * (0.24 + max(0.0, s - n) * 0.18);
    vec3 shore = source.rgb / max(source.a, 0.001);
    vec4 color = vec4(vec3(0.29, 0.88, 0.79) * shallows * 0.43, shallows * 0.43);
    color = vec4(vec3(0.07, 0.25, 0.26) * undercut, undercut) + color * (1.0 - undercut);
    color = vec4(vec3(0.10, 0.19, 0.17) * shade, shade) + color * (1.0 - shade);
    color = vec4(shore * lip, lip) + color * (1.0 - lip);
    color = vec4(vec3(0.93, 0.97, 0.84) * foam, foam) + color * (1.0 - foam);
    gl_FragColor = color * v_fragmentColor.a;
}
]]

local function coastProgram(fragment, sprite)
    if not cc.GLProgram or not cc.GLProgram.new then return nil end
    local program = cc.GLProgram:new()
    if not W.initProgram(program, sprite and W.coastSpriteVertexShader or W.coastVertexShader, fragment) then return nil end
    return program
end

local shoreColors = {
    sand={245,219,148}, forest={214,196,115}, volcanic={143,135,117},
    ice={204,237,237}, violet={199,168,181}, ghost={148,191,168}
}

function W.restoreCoast(map, report, edgeProgram)
    return W.restoreProgram(map, "coast", edgeProgram, W.coastSpriteVertexShader, W.coastFragmentShader, function(ok)
        for _, chunk in ipairs(report.groups) do
            -- Restore only the downsampled coast mask's interpolation.
            -- Original packed atlases must remain nearest-filtered.
            chunk.target:getSprite():getTexture():setTexParameters(9729, 9729, 33071, 33071)
            chunk.edge:setVisible(ok)
        end
        map._seaChartWorldCoastStatus = ok and "enabled" or "restore-shader-compile-or-link"
    end)
end

function W.addCoast(map)
    if map._seaChartWorldCoast then return map._seaChartWorldCoast.chunks end
    local function disabled(reason) map._seaChartWorldCoastStatus = reason; return 0 end
    if not cc.RenderTexture or not cc.GLProgram or not cc.c3b then return disabled("missing-native-api") end
    local tile, factor = map:getTileSize(), scaleFactor()
    if tile.width ~= 64 or tile.height ~= 64 then return disabled("unsupported-tile-size") end
    local layers, z = W.landLayers(map), nil
    for _, layer in ipairs(layers) do
        -- The union must include EVERY land family. Partial knowledge could
        -- incorrectly draw water along a perfectly continuous land boundary.
        if not W.familyForLayer(layer) then return disabled("unknown-source-atlas") end
        if not layer.getTileFlagsAt then return disabled("missing-tile-flags") end
        if not protectedOrder(map, layer) then return disabled("unsafe-overlay-order") end
        z = math.max(z or layer:getLocalZOrder(), layer:getLocalZOrder())
    end
    if not z then return disabled("no-land-layers") end
    local edgeProgram, maskProgram = coastProgram(W.coastFragmentShader, true), coastProgram(W.coastMaskFragmentShader)
    if not edgeProgram or not maskProgram then return disabled("shader-compile-or-link") end
    local span, gutter = W.coastChunkSide * 64, W.coastGutter
    local chunks, ordered = {}, {}
    for _, layer in ipairs(layers) do
        local family, original = W.familyForLayer(layer)
        local size, tileset = layerSize(map, layer), layer:getTileSet()
        local ox, oy = offset(layer)
        for y=0,size.height-1 do
            for x=0,size.width-1 do
                local point = cc.p(x, y)
                local gid = layer:getTileGIDAt(point)
                if gid ~= 0 then
                    local rect, pos = tileset:getRectForGID(gid), layer:getPositionAt(point)
                    local px, py = (pos.x + ox) * factor, (pos.y + oy) * factor
                    local cell = {rect=cc.rect(rect.x/factor, rect.y/factor, rect.width/factor, rect.height/factor),
                        x=px, y=py, flags=layer:getTileFlagsAt(point)}
                    -- Include adjacent chunks even when the cell is only in
                    -- their gutter. Water on the other side still needs its rim.
                    for cy=math.floor((py-gutter)/span),math.floor((py+rect.height+gutter-0.001)/span) do
                        for cx=math.floor((px-gutter)/span),math.floor((px+rect.width+gutter-0.001)/span) do
                            local key = cx .. ":" .. cy
                            if not chunks[key] then
                                chunks[key] = {x=cx*span, y=cy*span, layers={}}
                                ordered[#ordered+1] = chunks[key]
                            end
                            local entry = chunks[key].layers[layer]
                            if not entry then
                                entry = {texture=original, color=shoreColors[family.name], cells={}}
                                chunks[key].layers[layer] = entry
                            end
                            entry.cells[#entry.cells+1] = cell
                        end
                    end
                end
            end
        end
    end
    local report = {chunks=0, groups={}, maskPixels=W.coastMaskPixels, gutter=gutter,
        maxSamplesPerFragment=21, opaqueInteriorSamples=9}
    for _, chunk in ipairs(ordered) do
        local target = cc.RenderTexture:create(W.coastMaskPixels/factor, W.coastMaskPixels/factor)
        if target then
            local texture = target:getSprite():getTexture()
            if not target.setVirtualViewport then return disabled("missing-target-viewport") end
            if texture:getPixelsWide() ~= W.coastMaskPixels or texture:getPixelsHigh() ~= W.coastMaskPixels then
                return disabled("unsupported-target-size")
            end
            local group = cc.Node:create()
            local maskCells = 0
            -- This shipped Cocos version defaults the FBO viewport to the
            -- WINDOW size. Explicit pixels prevent a small target's source
            -- geometry being enlarged and cropped by the live window aspect.
            target:setVirtualViewport(cc.p(0, 0),
                cc.rect(0, 0, W.coastMaskPixels/factor, W.coastMaskPixels/factor),
                cc.rect(0, 0, W.coastMaskPixels, W.coastMaskPixels))
            -- Keep the target alive as a hidden child, including Cocos's own
            -- background/foreground texture restoration. No CPU readback here.
            group:addChild(target); target:setVisible(false)
            target:beginWithClear(0, 0, 0, 0)
            for _, layer in ipairs(layers) do
                local entry = chunk.layers[layer]
                if entry then
                    maskCells = maskCells + #entry.cells
                    local batch = cc.SpriteBatchNode:createWithTexture(entry.texture, #entry.cells)
                    batch:setShaderProgram(maskProgram)
                    batch:setBlendFunc(1, 771)
                    batch:setScale(.25)
                    for _, cell in ipairs(entry.cells) do
                        local sprite = cc.Sprite:createWithTexture(entry.texture, cell.rect)
                        W.placeMaskTile(sprite, cc.p((cell.x-chunk.x+gutter)/factor, (cell.y-chunk.y+gutter)/factor), cell.flags)
                        sprite:setColor(cc.c3b(entry.color[1], entry.color[2], entry.color[3]))
                        batch:addChild(sprite)
                    end
                    batch:visit()
                end
            end
            target:endToLua()
            texture:setTexParameters(9729, 9729, 33071, 33071)
            local edge = cc.Sprite:createWithTexture(texture,
                cc.rect(gutter*.25/factor, gutter*.25/factor, span*.25/factor, span*.25/factor))
            edge:setFlippedY(true)
            edge:setAnchorPoint(cc.p(0, 0)); edge:setPosition(cc.p(chunk.x/factor, chunk.y/factor))
            edge:setScale(4)
            edge:setShaderProgram(edgeProgram); edge:setBlendFunc(1, 771)
            group:addChild(edge)
            map:addChild(group, z)
            report.groups[#report.groups+1] = {group=group, target=target, edge=edge, x=chunk.x, y=chunk.y, maskCells=maskCells}
            report.chunks = report.chunks + 1
        end
    end
    if report.chunks > 0 then
        map._seaChartWorldCoast = report; map._seaChartWorldCoastStatus = "enabled"
        W.restoreCoast(map, report, edgeProgram)
    else map._seaChartWorldCoastStatus = #ordered > 0 and "render-target-allocation" or "empty-source" end
    return report.chunks
end

function W.addLand(map)
    if not cc.ClippingNode or not cc.SpriteBatchNode or not map.getLayer then return 0 end
    if map._seaChartWorldLand then return map._seaChartWorldLand.cells end
    local report = {cells=0, chunks=0, families={}, groups={}}
    local factor = scaleFactor()
    for _, layer in ipairs(W.landLayers(map)) do
        local family, original = W.familyForLayer(layer)
        -- Old binaries cannot expose flip flags safely. Keep native rendering;
        -- never assume unflipped geometry or call the unsafe two-argument API.
        if family and layer.getTileFlagsAt and protectedOrder(map, layer) then
            local paths = {W.path .. "Tiles/land-" .. family.name .. "-repeat.png"}
            if family.name == "sand" then paths[#paths+1] = W.path .. "Tiles/land-surface-repeat.png" end
            local paint = material(paths, true)
            if paint then
                local size = layerSize(map, layer)
                local ox, oy = offset(layer)
                local tileset = layer:getTileSet()
                -- Each stencil has at most 256 quads. A 101x101 map remains
                -- covered; there is no map-size or cell-count bailout.
                for cy=0,size.height-1,W.chunkSide do
                    for cx=0,size.width-1,W.chunkSide do
                        local cells, minX, minY, maxX, maxY = {}, nil, nil, nil, nil
                        for y=cy,math.min(cy+W.chunkSide-1,size.height-1) do
                            for x=cx,math.min(cx+W.chunkSide-1,size.width-1) do
                                local point = cc.p(x, y)
                                local gid = layer:getTileGIDAt(point)
                                if gid ~= 0 then
                                    local rect = tileset:getRectForGID(gid)
                                    local pos = layer:getPositionAt(point)
                                    rect = cc.rect(rect.x/factor, rect.y/factor, rect.width/factor, rect.height/factor)
                                    pos = cc.p(pos.x + ox, pos.y + oy)
                                    cells[#cells+1] = {rect=rect, position=pos, flags=layer:getTileFlagsAt(point)}
                                    minX = math.min(minX or pos.x, pos.x); minY = math.min(minY or pos.y, pos.y)
                                    maxX = math.max(maxX or pos.x, pos.x + rect.width)
                                    maxY = math.max(maxY or pos.y, pos.y + rect.height)
                                end
                            end
                        end
                        if #cells > 0 then
                            local stencil = cc.SpriteBatchNode:createWithTexture(original, #cells)
                            for _, cell in ipairs(cells) do
                                local sprite = cc.Sprite:createWithTexture(original, cell.rect)
                                W.placeMaskTile(sprite, cell.position, cell.flags)
                                stencil:addChild(sprite)
                            end
                            local clip = cc.ClippingNode:create(stencil)
                            clip:setAlphaThreshold(.5)
                            local surface = cc.Sprite:createWithTexture(paint)
                            -- Global UV phase is continuous across chunks and
                            -- layers. Original soft coast alpha stays beneath.
                            surface:setTextureRect(cc.rect(minX, -maxY, maxX-minX, maxY-minY))
                            surface:setAnchorPoint(cc.p(0, 0)); surface:setPosition(cc.p(minX, minY))
                            clip:addChild(surface)
                            map:addChild(clip, layer:getLocalZOrder())
                            report.groups[#report.groups+1] = clip
                            report.cells = report.cells + #cells
                            report.chunks = report.chunks + 1
                            report.families[family.name] = true
                        end
                    end
                end
            end
        end
    end
    if report.cells > 0 then map._seaChartWorldLand = report; W.addCoast(map) end
    return report.cells
end

local solidIds = {[10]=true, [18]=true, [19]=true, [20]=true, [21]=true, [22]=true}
local decorFrames = {
    sand={0,3}, forest={0,4}, volcanic={1},
    ice={2}, violet={1,5}, ghost={5,1}
}
-- Center the actual opaque bottom-quarter footprint, not the whole painted
-- canvas. Dark rock and dead-tree roots are slightly wider than other frames.
local decorAnchorX = {[0]=.54, .53, .50, .55, .51, .51}
-- Each new raised landmark has its own actual terrain identity. It replaces
-- only an existing paired/broad decoration, never terrain or event coordinates.
local landmarkFrames = {sand=0, forest=1, volcanic=2, ice=3, violet=4, ghost=5}

-- Fully opaque source tiles are safe under all flip states. Narrow coastal
-- alpha is deliberately excluded from raised groups; their bases never float.
local function solidAt(layer, family, size, x, y)
    if x < 0 or y < 0 or x >= size.width or y >= size.height then return false end
    local gid = layer:getTileGIDAt(cc.p(x, y))
    if gid == 0 then return false end
    local rect = layer:getTileSet():getRectForGID(gid)
    local id = rect.x / 64 + rect.y / 64 * 6
    return solidIds[id] or (family.name == "volcanic" and (id == 34 or id == 35)) or false
end

local function noEvents(meta, size, x, y, radius)
    if not meta then return true end
    radius = radius or 1
    for yy=math.max(0,y-radius),math.min(size.height-1,y+radius) do
        for xx=math.max(0,x-radius),math.min(size.width-1,x+radius) do
            if meta:getTileGIDAt(cc.p(xx, yy)) ~= 0 then return false end
        end
    end
    return true
end

function W.addDetails(map)
    if not map.getLayer then return 0 end
    if map._seaChartWorldDetails then return map._seaChartWorldDetails.count end
    local files, textures = cc.FileUtils:getInstance(), cache()
    local sheetPath = W.path .. "Tiles/decor-world.png"
    local sheet = files:isFileExist(sheetPath) and textures:addImage(sheetPath) or nil
    if sheet and (sheet:getPixelsWide() ~= 1536 or sheet:getPixelsHigh() ~= 1024) then sheet = nil end
    local landmarkPath = W.path .. "Tiles/landmarks-world-b.png"
    local landmarks = files:isFileExist(landmarkPath) and textures:addImage(landmarkPath) or nil
    if landmarks and (landmarks:getPixelsWide() ~= 1536 or landmarks:getPixelsHigh() ~= 1024) then landmarks = nil end
    local fallbacks = {}
    for _, path in ipairs({W.path .. "Decor/rock-palm.png", W.path .. "Decor/rock-small.png"}) do
        if files:isFileExist(path) then fallbacks[#fallbacks+1] = path end
    end
    if not sheet and #fallbacks == 0 then return 0 end
    local layers, meta = W.landLayers(map), map:getLayer("Meta")
    local factor, tile = scaleFactor(), map:getTileSize()
    local report = {count=0, groups={}, placements={}}
    local occupied = {}
    local detailZ
    for _, layer in ipairs(layers) do
        if protectedOrder(map, layer) then detailZ = math.max(detailZ or layer:getLocalZOrder(), layer:getLocalZOrder()) end
    end
    local limit = math.max(1, math.floor(W.detailLimit / math.max(1, #layers)))
    for _, layer in ipairs(layers) do
        local family = W.familyForLayer(layer)
        if family and layer.getTileFlagsAt and protectedOrder(map, layer)
            and (sheet or (family.name == "sand" and #fallbacks > 0)) then
            local size, count = layerSize(map, layer), 0
            local ox, oy = offset(layer)
            local group = sheet and cc.SpriteBatchNode:createWithTexture(sheet, limit) or cc.Node:create()
            local landmarkGroup = sheet and landmarks and cc.SpriteBatchNode:createWithTexture(landmarks, limit) or nil
            local landmarkCount = 0
            local candidates = {}
            for y=1,size.height-2 do
                for x=1,size.width-2 do
                    local hash = x * 73 + y * 151
                    if solidAt(layer, family, size, x, y) and noEvents(meta, size, x, y) then
                        local broad = true
                        for yy=y-1,y+1 do
                            for xx=x-1,x+1 do
                                if not solidAt(layer, family, size, xx, yy) then broad = false end
                            end
                        end
                        if broad and not noEvents(meta, size, x, y, 2) then broad = false end
                        local paired = not broad and solidAt(layer, family, size, x+1, y)
                            and noEvents(meta, size, x+1, y)
                        candidates[#candidates+1] = {x=x, y=y, hash=hash, broad=broad, paired=paired,
                            rank=broad and 3 or (paired and 2 or 1)}
                    end
                end
            end
            -- Give broad foundations first choice instead of letting an early
            -- tiny accent occupy their space. Hash order avoids row/column bands.
            table.sort(candidates, function(a,b)
                if a.rank ~= b.rank then return a.rank > b.rank end
                if a.hash % 997 ~= b.hash % 997 then return a.hash % 997 < b.hash % 997 end
                return a.hash < b.hash
            end)
            for _, candidate in ipairs(candidates) do
                local x, y, hash = candidate.x, candidate.y, candidate.hash
                local broad, paired = candidate.broad, candidate.paired
                if count < limit and not occupied[y*size.width+x]
                    and (not paired or not occupied[y*size.width+x+1]) then
                        local sprite
                        local frame
                        local landmark = landmarkGroup and (broad or paired)
                        if landmark then
                            frame = landmarkFrames[family.name]
                            sprite = cc.Sprite:createWithTexture(landmarks,
                                cc.rect(frame%3*512/factor, math.floor(frame/3)*512/factor, 512/factor, 512/factor))
                        elseif sheet then
                            local choices = decorFrames[family.name]
                            frame = choices[hash % #choices+1]
                            sprite = cc.Sprite:createWithTexture(sheet,
                                cc.rect(frame%3*512/factor, math.floor(frame/3)*512/factor, 512/factor, 512/factor))
                        else sprite = cc.Sprite:create(fallbacks[hash % #fallbacks+1]) end
                        if sprite then
                            -- A paired foundation is two genuinely opaque land
                            -- cells, not two merely nonzero coastal GIDs. Rock
                            -- bases fit that 128px strip; raised tops may overhang.
                            local tree = frame == 3 or frame == 4 or frame == 5
                            local single = frame == 1 and 72 or (frame == 5 and 100 or (tree and 112 or 76))
                            local extent = sheet and (broad and 176 or (paired and 144 or single)) or (broad and 110 or 46)
                            local bounds, position = sprite:getContentSize(), layer:getPositionAt(cc.p(x, y))
                            sprite:setScale(extent/factor / math.max(bounds.width, bounds.height))
                            -- A raised silhouette stands above its safe base.
                            -- Small fallback art was authored around its center.
                            local anchorX = landmark and .5 or (sheet and decorAnchorX[frame] or .5)
                            local anchorY = landmark and .115 or (sheet and (tree and .18 or .11) or .5)
                            sprite:setAnchorPoint(cc.p(anchorX, anchorY))
                            sprite:setPosition(cc.p(position.x+ox+tile.width*(paired and 1 or .5)/factor,
                                position.y+oy+tile.height/(2*factor)))
                            if landmark then landmarkGroup:addChild(sprite); landmarkCount = landmarkCount + 1
                            else group:addChild(sprite) end
                            count = count + 1; report.count = report.count + 1
                            report.placements[#report.placements+1] = {layer=layer, x=x, y=y, extent=extent,
                                broad=broad, paired=paired, frame=frame, anchorX=anchorX, anchorY=anchorY,
                                landmark=landmark and true or false, family=family.name}
                            for yy=y-2,y+2 do
                                for xx=x-2,x+(paired and 3 or 2) do occupied[yy*size.width+xx] = true end
                            end
                        end
                end
            end
            if count > 0 then
                -- Raised silhouettes sit over the shared shore pass, while
                -- every gameplay marker, chart grid and fog remains above.
                map:addChild(group, detailZ or layer:getLocalZOrder())
                report.groups[#report.groups+1] = group
                if landmarkCount > 0 then
                    map:addChild(landmarkGroup, detailZ or layer:getLocalZOrder())
                    report.groups[#report.groups+1] = landmarkGroup
                end
            end
        end
    end
    if report.count > 0 then map._seaChartWorldDetails = report end
    return report.count
end

return W
