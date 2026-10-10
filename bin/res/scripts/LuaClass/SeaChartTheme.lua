-- Presentation for the live Explore chart only. No map, event or save writes.
require "LuaClass/MasterTheme"

SeaChartTheme = {}
local S = SeaChartTheme
local WorldTheme = require "LuaClass/SeaChartWorldTheme"
S.colors = {
    ink = cc.c3b(3, 43, 61), sea = cc.c3b(53, 216, 227),
    paper = cc.c3b(250, 237, 210), white = cc.c3b(255, 248, 226),
    muted = cc.c3b(52, 86, 101), coral = cc.c3b(239, 83, 54)
}
S.path = "Images/UI/Adventure/SeaChart/"

function S.label(text, size, color, x, y, anchorX)
    return MasterTheme.label(text, size, color, x, y, true, anchorX)
end

function S.panel(width, height, color, x, y)
    local node = cc.LayerColor:create(cc.c4b(color.r, color.g, color.b, color.a or 255), width, height)
    node:setAnchorPoint(cc.p(0, 0))
    node:ignoreAnchorPointForPosition(false)
    node:setPosition(cc.p(x or 0, y or 0))
    return node
end

function S.material(kind, width, height)
    return MasterTheme.material(kind, width, height)
end

function S.button(text, width, height, callback, coral, fontSize)
    return MasterTheme.button(text, width, height, callback, {
        material = coral and "coral-brush.png" or "ink-brush.png",
        textColor = S.colors.white, fontSize = fontSize, bold = true
    })
end

function S.fit(label, width)
    return MasterTheme.fit(label, width)
end

-- These marks share the harbor's native silhouettes and remain real UI nodes.
function S.icon(kind, size)
    if kind == "sail" or kind == "food" then
        return MasterTheme.icon(kind, size, S.colors.white)
    end
    local node = cc.Node:create()
    node:setContentSize(cc.size(size, size))
    local draw = cc.DrawNode:create()
    node:addChild(draw)
    local light = HomeTheme.rgba(S.colors.white)
    local dark = HomeTheme.rgba(S.colors.ink)
    local function p(x, y) return cc.p(x * size, y * size) end
    local function line(x, y, a, b, color, width)
        draw:drawSegment(p(x, y), p(a, b), (width or .022) * size, color or dark)
    end
    local function triangle(a, b, c)
        draw:drawTriangle(p(a[1], a[2]), p(b[1], b[2]), p(c[1], c[2]), light)
    end
    if kind == "cargo" then
        triangle({.12,.70}, {.49,.92}, {.90,.73})
        triangle({.12,.70}, {.90,.73}, {.53,.53})
        triangle({.12,.70}, {.53,.53}, {.53,.08})
        triangle({.12,.70}, {.53,.08}, {.14,.25})
        triangle({.53,.53}, {.90,.73}, {.88,.27})
        triangle({.53,.53}, {.88,.27}, {.53,.08})
        line(.13,.69,.53,.52); line(.53,.52,.89,.72); line(.53,.52,.53,.09)
        line(.33,.80,.73,.62); line(.31,.59,.70,.82)
        line(.26,.59,.27,.25); line(.39,.55,.40,.18)
        line(.65,.53,.65,.24); line(.77,.61,.77,.31)
    elseif kind == "scroll" then
        triangle({.19,.84}, {.88,.77}, {.74,.13})
        triangle({.19,.84}, {.74,.13}, {.08,.19})
        line(.19,.81,.83,.75); line(.11,.23,.72,.17)
        line(.26,.67,.58,.62); line(.26,.55,.43,.53)
        line(.32,.33,.64,.55); line(.43,.38,.51,.34)
        line(.40,.48,.39,.37); line(.61,.56,.68,.66)
        line(.60,.66,.68,.56)
    end
    return node
end

function S.rule(parent, x, y, width, color)
    local draw = cc.DrawNode:create()
    draw:drawSegment(cc.p(x, y), cc.p(x + width, y), .45, HomeTheme.rgba(color))
    parent:addChild(draw, 1)
    return draw
end

function S.pill(width, height, color)
    local node = cc.Node:create()
    node:setContentSize(cc.size(width, height))
    local draw = cc.DrawNode:create()
    node:addChild(draw)
    local points, radius = {}, height / 2
    for _, arc in ipairs({{width-radius, -90}, {radius, 90}}) do
        for i=0,12 do
            local angle = math.rad(arc[2] + i * 15)
            points[#points+1] = cc.p(arc[1] + radius * math.cos(angle), radius + radius * math.sin(angle))
        end
    end
    local center = cc.p(width / 2, radius)
    for i=1,#points do
        draw:drawTriangle(center, points[i], points[i % #points + 1], HomeTheme.rgba(color))
    end
    return node
end

function S.shipHalo(tileSize)
    local draw = cc.DrawNode:create()
    local radius = tileSize * .60
    for i=0,47 do
        local a, b = i * math.pi / 24, (i+1) * math.pi / 24
        local p = cc.p(tileSize / 2 + radius * math.cos(a), tileSize / 2 + radius * math.sin(a))
        local q = cc.p(tileSize / 2 + radius * math.cos(b), tileSize / 2 + radius * math.sin(b))
        draw:drawSegment(p, q, 3.8, cc.c4f(.15, .91, 1, .18))
        draw:drawSegment(p, q, 1.2, cc.c4f(.79, 1, 1, .96))
    end
    return draw
end

-- The source fog has black RGB and a meaningful alpha mask. Read that alpha
-- directly in the original batch shader; recoloring black pixels by multiply
-- cannot work. No render target, texture swap, UV change or tile materialization.
S.fogVertexShader = [[
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
S.fogFragmentShader = [[
#ifdef GL_ES
precision lowp float;
#endif
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D CC_Texture0;
void main() {
    float alpha = texture2D(CC_Texture0, v_texCoord).a * v_fragmentColor.a;
    gl_FragColor = vec4(vec3(0.012, 0.137, 0.204) * alpha, alpha);
}
]]
S.gridFragmentShader = [[
#ifdef GL_ES
precision lowp float;
#endif
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D CC_Texture0;
void main() {
    vec4 color = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);
#ifndef GRID_TEXTURE_PREMULTIPLIED
    // PNG upload is straight-alpha on some platforms. Transparent authored
    // pixels still carry RGB, which must never add light to the whole chart.
    color.rgb *= color.a;
#endif
    // Preserve the accepted muted line RGB: the previous straight-alpha
    // material applied both this ink tint and the opacity below.
    color.rgb *= 0.42;
    gl_FragColor = color * 0.42;
}
]]
local function chartProgram(fragment)
    if not cc.GLProgram or not cc.GLProgram.new then return nil end
    local program = cc.GLProgram:new()
    if not WorldTheme.initProgram(program, S.fogVertexShader, fragment) then return nil end
    return program
end
function S.restoreChartProgram(map, key, layer, program, fragment)
    return WorldTheme.restoreProgram(map, key, program, S.fogVertexShader, fragment, function(ok)
        -- Native fog remains opaque if a driver cannot restore the tint.
        local fallback = cc.ShaderCache:getInstance():getProgram("ShaderPositionTextureColor")
        layer:setShaderProgram(ok and program or fallback)
    end)
end
function S.tintFog(map, layer)
    if not layer then return false end
    local program = chartProgram(S.fogFragmentShader)
    if not program then return false end
    layer:setShaderProgram(program)
    S.restoreChartProgram(map, "fog", layer, program, S.fogFragmentShader)
    -- The fragment emits premultiplied RGB while retaining the original alpha.
    layer:setBlendFunc(1, 771) -- GL_ONE, GL_ONE_MINUS_SRC_ALPHA
    return true
end

function S.softenGrid(map)
    local layer = map:getLayer("GridLayer")
    if not layer then return false end
    local fragment = S.gridFragmentShader
    local texture = layer.getTexture and layer:getTexture()
    if texture and texture.hasPremultipliedAlpha and texture:hasPremultipliedAlpha() then
        fragment = "#define GRID_TEXTURE_PREMULTIPLIED\n" .. fragment
    end
    local program = chartProgram(fragment)
    if not program then return false end
    layer:setShaderProgram(program)
    S.restoreChartProgram(map, "grid", layer, program, fragment)
    layer:setBlendFunc(1, 771)
    return true
end

-- World-space surfaces use each real layer's tileset and original alpha.
-- All map sizes share this path; the approved irregular slice stays separate.
function S.addContinuousWater(map)
    return WorldTheme.addWater(map)
end
function S.addContinuousLand(map)
    return WorldTheme.addLand(map)
end

-- TMXLayer renders a SpriteBatchNode. Swap only its same-sized atlas texture;
-- tile rects, GIDs, positions, properties, collisions and fog topology stay owned
-- by the original TMX and managers. No replacement art means the original atlas.
function S.applyTileArt(map)
    local files = {
        {"dt_zhanzmw.png", 384, 192}, {"t_00.png", 512, 384},
        {"dt_ludi.png", 384, 384}, {"dt_senlin.png", 384, 384},
        {"dt_huoshan.png", 384, 384}, {"dt_bingdao.png", 384, 384},
        {"dt_ziseludi.png", 384, 384}, {"dt_youlingdao.png", 384, 384},
        {"grid.png", 64, 64}
    }
    local fileUtils = cc.FileUtils:getInstance()
    local cache = cc.Director:getInstance():getTextureCache()
    local replacements, applied = {}, {}
    for _, file in ipairs(files) do
        local path = S.path .. "Tiles/" .. file[1]
        if fileUtils:isFileExist(path) then
            local original = cache:getTextureForKey("Images/Map/" .. file[1])
            if original then
                local texture = cache:addImage(path)
                if texture and texture:getPixelsWide() == file[2] and texture:getPixelsHigh() == file[3] then
                    -- TMXLayer::setupTiles uses nearest sampling for its tightly
                    -- packed atlas. A freshly loaded replacement defaults to
                    -- linear and samples adjacent land frames at clear edges,
                    -- producing isolated lines when the chart is zoomed out.
                    texture:setAliasTexParameters()
                    replacements[#replacements+1] = {original=original, texture=texture, name=file[1]}
                end
            end
        end
    end
    for _, name in ipairs({"Sea", "Blocks_1", "Blocks_2", "Meta", "GridLayer", "Fogs"}) do
        local layer = map:getLayer(name)
        if layer then
            for _, replacement in ipairs(replacements) do
                if layer:getTexture() == replacement.original then
                    layer:setTexture(replacement.texture)
                    applied[name] = replacement.name
                    break
                end
            end
        end
    end
    if not applied.Fogs and S.tintFog(map, map:getLayer("Fogs")) then
        applied.Fogs = "native-ink-fog"
    end
    if S.addContinuousWater(map) then applied.Sea = "continuous-painted-water" end
    applied.landMaskCells = S.addContinuousLand(map)
    if S.softenGrid(map) then applied.GridLayer = "soft-chart-grid" end
    return applied
end

-- Sparse raised accents derive safe bases from each original land layer.
function S.addLandDetails(map)
    return WorldTheme.addDetails(map)
end

-- Authored event families use the original shared t_00 atlas on all sixteen maps.
-- Existing Meta GIDs still own occupation, disappearance and effects.
function S.applySliceEventArt(map, mapIndex)
    if type(mapIndex) ~= "number" or mapIndex < 1 or mapIndex > 16 then return false end
    local tile = map:getTileSize()
    if tile.width ~= 64 or tile.height ~= 64 then return false end
    local path = S.path .. "Tiles/events-world.png"
    if not cc.FileUtils:getInstance():isFileExist(path) then return false end
    local meta = map:getLayer("Meta")
    if not meta then return false end
    local cache = cc.Director:getInstance():getTextureCache()
    local original = cache:getTextureForKey("Images/Map/t_00.png")
    if not original or meta:getTexture() ~= original then return false end
    local texture = cache:addImage(path)
    if not texture or texture:getPixelsWide() ~= 512 or texture:getPixelsHigh() ~= 384 then return false end
    texture:setAntiAliasTexParameters()
    meta:setTexture(texture)
    return true
end

return S
