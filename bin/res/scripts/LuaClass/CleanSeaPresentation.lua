-- Optional display-only material gate. Nothing reads/writes role data here.
-- Call gate() explicitly in a fixture; production has no global activation.
local M={}
local root='Images/UI/CleanSea/'
local sources={sand='dt_ludi.png',forest='dt_senlin.png',volcanic='dt_huoshan.png'}
function M.gate()
    local m={id='clean-world-material-gate-v1',version=1,path=root,
        supported={sand=true,forest=true,volcanic=true},atlases={},surfaces={},
        water=root..'water-repeat.png',waterMirrored=true,
        decor=root..'scenery-gate.png',landmarks=root..'scenery-gate.png',
        decorFrames={sand={0},forest={1},volcanic={2}},
        landmarkFrames={sand=0,forest=1,volcanic=2},
        decorAnchorX={[0]=.5,[1]=.5,[2]=.5},decorAnchorY=.115,singleExtent=76,
        shoreColors={sand={249,231,185},forest={243,225,180},volcanic={205,185,156}},
        fogRGB={.79,.87,.88},gridRGBGain=.9,gridOpacity=.18,ship=root..'ship-clean.png',
        eventCoverage='partial: port, timber/quarry/iron pairs and neutral shared GID48; other original frames unchanged'}
    for family,atlas in pairs(sources) do
        m.atlases[atlas]=root..atlas
        m.surfaces[family]=root..'land-'..family..'-repeat.png'
    end
    m.atlases['t_00.png']=root..'events-gate.png'
    -- Reuse the already-audited transparent subtle grid, not the heavy source.
    m.atlases['grid.png']='Images/UI/Adventure/SeaChart/Tiles/grid.png'
    return m
end
function M.resolve(map,manifest,world)
    local report={id=type(manifest)=='table' and manifest.id or nil,status='fallback',reasons={}}
    local function reject(reason) report.reasons[#report.reasons+1]=reason;return nil,report end
    if type(manifest)~='table' or manifest.id~='clean-world-material-gate-v1' then return reject('unknown-manifest') end
    for _,key in ipairs({'supported','atlases','surfaces','decorFrames','landmarkFrames','decorAnchorX','shoreColors'}) do
        if type(manifest[key])~='table' then return reject('invalid-manifest:'..key) end
    end
    if map._seaChartPresentation then
        if map._seaChartPresentation.id~=manifest.id then return reject('live-theme-switch-unsupported') end
        return map._seaChartPresentation,map._seaChartPresentationReport
    end
    if map._seaChartWorldWater or map._seaChartWorldLand or map._seaChartWorldDetails then return reject('world-already-mounted') end
    local tile=map:getTileSize()
    if tile.width~=64 or tile.height~=64 then return reject('unsupported-tile-size') end
    if not cc.RenderTexture or not cc.ClippingNode or not cc.SpriteBatchNode or not cc.GLProgram then return reject('missing-native-api') end
    local files=cc.FileUtils:getInstance();local cache=cc.Director:getInstance():getTextureCache()
    local function asset(path,w,h)
        if not path or not files:isFileExist(path) then return false end
        local texture=cache:addImage(path)
        return texture and texture:getPixelsWide()==w and texture:getPixelsHigh()==h
    end
    local sea=map:getLayer('Sea');local seaFamily=world.familyForLayer(sea)
    if not seaFamily then return reject('unknown-sea-atlas') end
    local layers=world.landLayers(map)
    if #layers==0 then return reject('no-land-layers') end
    for _,layer in ipairs(layers) do
        local family=world.familyForLayer(layer)
        if not family or not manifest.supported[family.name] then return reject('unsupported-land-family:'..tostring(family and family.name)) end
        if not layer.getTileFlagsAt then return reject('missing-tile-flags') end
        for _,name in ipairs({'Meta','GridLayer','Fogs'}) do
            local overlay=map:getLayer(name)
            if not overlay or overlay:getLocalZOrder()<=layer:getLocalZOrder() then return reject('unsafe-overlay-order') end
        end
        if not asset(manifest.surfaces[family.name],512,512) or not asset(manifest.atlases[family.atlas],384,384) then return reject('invalid-family-art:'..family.name) end
    end
    if not asset(manifest.water,512,512) or not asset(manifest.decor,1536,1024)
        or not asset(manifest.landmarks,1536,1024) or not asset(manifest.atlases['t_00.png'],512,384)
        or not asset(manifest.ship,256,256) or not asset(manifest.atlases['grid.png'],64,64) then return reject('invalid-shared-art') end
    -- Install only after every required capability and texture has passed.
    report.status='enabled';report.eventCoverage=manifest.eventCoverage
    map._seaChartPresentation=manifest;map._seaChartPresentationReport=report
    return manifest,report
end
return M
