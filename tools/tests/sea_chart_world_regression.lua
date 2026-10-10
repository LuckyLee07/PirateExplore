-- Production Lua against read-only, decoded real TMX fixtures. No game or save.
local fixtures = assert(loadfile(assert(arg[1], 'TMX fixture path required')))()
local methods = {}
local function node(kind)
    return setmetatable({kind=kind, children={}, position={x=0,y=0}, anchor={x=0,y=0},
        size={width=0,height=0}, rotation=0, flippedX=false, flippedY=false, visible=true}, {__index=methods})
end
function methods:addChild(child,z) child.parent=self;child.z=z or 0;self.children[#self.children+1]=child end
function methods:getChildren() return self.children end
function methods:setPosition(p) self.position=p end
function methods:setAnchorPoint(p) self.anchor=p end
function methods:setRotation(v) self.rotation=v end
function methods:setFlippedX(v) self.flippedX=v end
function methods:setFlippedY(v) self.flippedY=v end
function methods:setScale(v) self.scale=v end
function methods:getContentSize() return self.size end
function methods:getTexture() return self.texture end
function methods:setTextureRect(rect) self.rect=rect;self.size={width=rect.width,height=rect.height} end
function methods:getLocalZOrder() return self.z end
function methods:getPositionX() return self.position.x end
function methods:getPositionY() return self.position.y end
function methods:setVisible(v) self.visible=v end
function methods:setColor(v) self.color=v end
function methods:setShaderProgram(v) self.shader=v end
function methods:setBlendFunc(src,dst)
    assert(type(src)=="number" and type(dst)=="number", "native blend API requires two numbers")
    self.blend={src=src,dst=dst}
end
local renderingTarget
function methods:visit()
    assert(renderingTarget, 'mask visit outside GPU target')
    renderingTarget.batches[#renderingTarget.batches+1]=self
end
local function forbidden() error('presentation changed gameplay data or materialized a native tile') end
cc={p=function(x,y)return {x=x,y=y}end,rect=function(x,y,w,h)return {x=x,y=y,width=w,height=h}end}
cc.c3b=function(r,g,b)return {r=r,g=g,b=b}end
local available, dimensions, factor = {}, {}, 1
local textures = {}
local function texture(path, width, height)
    local t={path=path,width=width,height=height}
    function t:getPixelsWide() return self.width end
    function t:getPixelsHigh() return self.height end
    function t:setTexParameters(...) self.parameters={...} end
    textures[path]=t;available[path]=true
    return t
end
local atlasNames={'dt_ludi.png','dt_senlin.png','dt_huoshan.png','dt_bingdao.png','dt_ziseludi.png','dt_youlingdao.png'}
for _,name in ipairs(atlasNames)do texture('Images/Map/'..name,384,384) end
texture('Images/Map/dt_zhanzmw.png',384,192);texture('Images/Map/t_00.png',512,384);texture('Images/Map/grid.png',64,64)
local base='Images/UI/Adventure/SeaChart/Tiles/'
for _,name in ipairs({'sand','forest','volcanic','ice','violet','ghost'})do texture(base..'land-'..name..'-repeat.png',512,512)end
texture(base..'sea-water-repeat.png',1024,1024);texture(base..'decor-world.png',1536,1024)
texture(base..'landmarks-world-b.png',1536,1024)
local cache={getTextureForKey=function(_,path)return textures[path]end, addImage=function(_,path)return textures[path]end}
cc.Director={getInstance=function()return {getTextureCache=function()return cache end,getContentScaleFactor=function()return factor end}end}
cc.FileUtils={getInstance=function()return {isFileExist=function(_,path)return available[path]end}end}
cc.Node={create=function()return node('node')end}
cc.Sprite={createWithTexture=function(_,texture,rect)
    local n=node('sprite');n.texture=texture
    n:setTextureRect(rect or cc.rect(0,0,texture.width/factor,texture.height/factor));return n
end}
cc.SpriteBatchNode={createWithTexture=function(_,texture,capacity)
    local n=node('batch');n.texture=texture;n.capacity=capacity;return n
end}
cc.ClippingNode={create=function(_,stencil)
    local n=node('clip');n.stencil=stencil;n.setAlphaThreshold=function(self,v)self.threshold=v end;return n
end}
cc.GLProgram={new=function()
    return {initWithByteArrays=function(self,v,f)self.vertex=v;self.fragment=f;return true end,
        bindAttribLocation=function()end,link=function()return true end,updateUniforms=function()end}
end}
cc.RenderTexture={create=function(_,width,height)
    local n=node('render');n.batches={};n.width=width;n.height=height
    n.sprite=cc.Sprite:createWithTexture(texture('render-'..tostring(n),width*factor,height*factor))
    function n:getSprite()return self.sprite end
    function n:setVirtualViewport(origin,full,viewport)self.viewport=viewport;self.fullRect=full;self.origin=origin end
    function n:beginWithClear(r,g,b,a)
        assert(not renderingTarget and r==0 and g==0 and b==0 and a==0)
        renderingTarget=self
    end
    function n:endToLua()assert(renderingTarget==self);renderingTarget=nil end
    return n
end}
local W=dofile('bin/res/scripts/LuaClass/SeaChartWorldTheme.lua')
local function makeMap(fixture)
    local map=node('map');map.layers={};map.width=fixture.width;map.height=fixture.height
    function map:getLayer(name)return self.layers[name]end
    function map:getMapSize()return {width=self.width,height=self.height}end
    function map:getTileSize()return {width=64,height=64}end
    for _,source in ipairs(fixture.layers)do
        local layer=node('tmx');layer.name=source.name;layer.source=source;layer.texture=textures['Images/Map/'..source.atlas]
        layer.position={x=source.offsetx,y=source.offsety}
        function layer:getLayerName()return self.name end
        function layer:getLayerSize()return map:getMapSize()end
        function layer:getTileGIDAt(point)
            assert(point.x>=0 and point.y>=0 and point.x<map.width and point.y<map.height, 'out-of-bounds tile read')
            return (self.source.gids[point.y*map.width+point.x+1] or 0)%536870912
        end
        function layer:getTileFlagsAt(point)
            local value=self.source.gids[point.y*map.width+point.x+1]or 0
            return value-value%536870912
        end
        function layer:getPositionAt(point)return {x=point.x*64/factor,y=(map.height-point.y-1)*64/factor}end
        function layer:getTileSet()
            return {getRectForGID=function(_,gid)
                local id=gid-source.firstgid;return cc.rect(id%6*64,math.floor(id/6)*64,64,64)
            end}
        end
        layer.setTileGID=forbidden;layer.removeTileAt=forbidden;layer.getTileAt=forbidden;layer.setTexture=forbidden
        map.layers[source.name]=layer;map:addChild(layer,source.z)
    end
    return map
end
local flipStates={
    {0,0,false,false},{2147483648,0,true,false},{1073741824,0,false,true},{3221225472,0,true,true},
    {536870912,270,true,false},{2684354560,90,false,false},{1610612736,270,false,false},{3758096384,90,true,false}
}
for _,f in ipairs(flipStates)do
    local sprite=cc.Sprite:createWithTexture(textures['Images/Map/dt_ludi.png'],cc.rect(0,0,64,64))
    W.placeMaskTile(sprite,cc.p(17,29),f[1])
    assert(sprite.rotation==f[2] and sprite.flippedX==f[3] and sprite.flippedY==f[4],'incorrect Tiled flip transform')
    local diagonal=f[1]%1073741824>=536870912
    assert(sprite.anchor.x==(diagonal and .5 or 0))
    assert(sprite.position.x==(diagonal and 49 or 17) and sprite.position.y==(diagonal and 61 or 29))
end
local total, allThemes, largeGroups=0,{},0
for _,fixture in ipairs(fixtures)do
    local map=makeMap(fixture)
    assert(W.addWater(map), 'water coverage chapter '..fixture.index)
    assert(not map:getLayer('Sea').visible and map._seaChartWorldWater.z==map:getLayer('Sea').z)
    assert(map._seaChartWorldWater.rect.width==fixture.width*64 and map._seaChartWorldWater.rect.height==fixture.height*64)
    local expected=0
    for _,layer in ipairs(W.landLayers(map))do
        for _,gid in ipairs(layer.source.gids)do if gid%536870912~=0 then expected=expected+1 end end
    end
    local count=W.addLand(map);assert(count==expected, 'missing original land on chapter '..fixture.index)
    total=total+count
    local report=map._seaChartWorldLand
    for family in pairs(report.families)do allThemes[family]=true end
    local checked=0
    for _,clip in ipairs(report.groups)do
        local batch=clip.stencil
        assert(#batch.children<=256 and batch.capacity==#batch.children and clip.threshold==.5)
        local layer
        for _,candidate in ipairs(W.landLayers(map))do if candidate.z==clip.z then layer=candidate end end
        assert(layer and batch.texture==textures['Images/Map/'..layer.source.atlas], 'source alpha atlas or original z changed')
        assert(clip.z<map:getLayer('Meta').z and clip.z<map:getLayer('GridLayer').z and clip.z<map:getLayer('Fogs').z)
        for _,sprite in ipairs(batch.children)do
            local xx=sprite.position.x-sprite.anchor.x*sprite.rect.width-layer.position.x
            local yy=sprite.position.y-sprite.anchor.y*sprite.rect.height-layer.position.y
            local p=cc.p(xx/64,fixture.height-1-yy/64)
            local gid=layer:getTileGIDAt(p);local rect=layer:getTileSet():getRectForGID(gid)
            assert(gid~=0 and sprite.rect.x==rect.x and sprite.rect.y==rect.y)
            assert(rect.x>=0 and rect.y>=0 and rect.x+rect.width<=384 and rect.y+rect.height<=384)
            local flags=layer:getTileFlagsAt(p);local matching
            for _,state in ipairs(flipStates)do if state[1]==flags then matching=state end end
            assert(matching and sprite.rotation==matching[2] and sprite.flippedX==matching[3] and sprite.flippedY==matching[4])
            checked=checked+1
        end
        local surface=clip.children[1]
        assert(surface.rect.x==surface.position.x and surface.rect.y==-surface.position.y-surface.rect.height, 'chunk UV phase discontinuity')
        assert(surface.texture.parameters[3]==33648 and surface.texture.parameters[4]==33648, 'authored paint needs mirrored seams')
    end
    assert(checked==expected)
    local coast=assert(map._seaChartWorldCoast, 'original-alpha depth missing')
    assert(coast.chunks>0 and coast.maskPixels==256 and coast.gutter>16)
    local sourceCells=0
    for _,chunk in ipairs(coast.groups)do
        assert(chunk.target.width==256/factor and chunk.target.height==256/factor and not chunk.target.visible)
        assert(chunk.target.viewport.width==256 and chunk.target.viewport.height==256, 'native FBO must not inherit the window viewport')
        assert(chunk.edge.flippedY and chunk.edge.scale==4 and chunk.edge.rect.x==8/factor and chunk.edge.rect.width==240/factor)
        assert(chunk.edge.position.x==chunk.x/factor and chunk.edge.position.y==chunk.y/factor)
        assert(chunk.edge.shader.fragment==W.coastFragmentShader and chunk.edge.blend.src==1)
        assert(chunk.edge.shader.vertex==W.coastSpriteVertexShader and not chunk.edge.shader.vertex:find('CC_MVPMatrix',1,true), 'display sprite must not apply its world transform twice')
        assert(chunk.group.z<map.layers.Meta.z and chunk.group.z<map.layers.GridLayer.z and chunk.group.z<map.layers.Fogs.z)
        for _,batch in ipairs(chunk.target.batches)do
            assert(batch.scale==.25 and batch.shader.fragment==W.coastMaskFragmentShader)
            assert(batch.shader.vertex==W.coastVertexShader and batch.shader.vertex:find('CC_MVPMatrix',1,true))
            assert(#batch.children<=289, 'coast source batch exceeds padded 17x17 neighborhood')
            assert(batch.texture.path:find('Images/Map/',1,true)==1, 'coast must use ORIGINAL alpha')
            for _,sprite in ipairs(batch.children)do
                assert(sprite.color and sprite.color.r>0)
                sourceCells=sourceCells+1
            end
        end
    end
    assert(sourceCells>=expected,'GPU union omitted original cells')
    local nodeCount=#map.children;assert(W.addLand(map)==expected and #map.children==nodeCount, 'repeat application must be idempotent')
    local details=W.addDetails(map);assert(details<=W.detailLimit)
    if details>0 then
        for _,placement in ipairs(map._seaChartWorldDetails.placements)do
            assert(placement.layer:getTileGIDAt(cc.p(placement.x,placement.y))~=0, 'scenery base in water')
            for y=placement.y-1,placement.y+1 do for x=placement.x-1,placement.x+1 do
                assert(map:getLayer('Meta'):getTileGIDAt(cc.p(x,y))==0, 'event center obstructed')
                if placement.broad then assert(placement.layer:getTileGIDAt(cc.p(x,y))~=0,'raised group crosses water center') end
            end end
            if placement.broad then largeGroups=largeGroups+1;assert(placement.extent==176)
            elseif placement.paired then
                assert(placement.extent==144 and placement.layer:getTileGIDAt(cc.p(placement.x+1,placement.y))~=0)
                largeGroups=largeGroups+1
            else assert(placement.extent==72 or placement.extent==76 or placement.extent==100 or placement.extent==112)end
            local box=assert((placement.landmark and fixtures.landmarkBases or fixtures.decorBases)[placement.frame])
            local halfWidth=placement.broad and 96 or (placement.paired and 64 or 32)
            local halfHeight=placement.broad and 96 or 32
            assert((box[1]/512-placement.anchorX)*placement.extent>=-halfWidth, 'opaque scenery foot hangs over water to left')
            assert((box[3]/512-placement.anchorX)*placement.extent<=halfWidth, 'opaque scenery foot hangs over water to right')
            assert((1-box[4]/512-placement.anchorY)*placement.extent>=-halfHeight, 'opaque scenery foot hangs over water below')
            assert((1-box[2]/512-placement.anchorY)*placement.extent<=halfHeight, 'opaque scenery foot hangs over water above')
            if placement.broad then
                for y=placement.y-2,placement.y+2 do for x=placement.x-2,placement.x+2 do
                    if x>=0 and y>=0 and x<fixture.width and y<fixture.height then
                        assert(map.layers.Meta:getTileGIDAt(cc.p(x,y))==0,'large raised canopy obscures a nearby event center')
                    end
                end end
            end
            if placement.landmark then
                assert(placement.broad or placement.paired, 'new landmark must keep a safe grouped foundation')
                local expected={sand=0,forest=1,volcanic=2,ice=3,violet=4,ghost=5}
                assert(placement.frame==expected[placement.family],'raised landmark lost actual atlas identity')
            else
                if placement.layer.source.atlas=='dt_bingdao.png' then assert(placement.frame==2,'ice scenery lost theme')end
                if placement.layer.source.atlas=='dt_huoshan.png' then assert(placement.frame==1,'volcano scenery lost theme')end
            end
        end
        nodeCount=#map.children;assert(W.addDetails(map)==details and #map.children==nodeCount)
    end
    print('PASS world chapter '..fixture.index..': '..count..' mask cells, '..report.chunks..' bounded land batches, '..coast.chunks..' coast targets ('..(coast.chunks*.25)..' MiB RGBA), '..details..' raised accents')
end
for _,family in ipairs(W.families)do assert(allThemes[family.name])end
assert(largeGroups>0,'real large-island interiors must gain grouped silhouettes')

-- A completely solid 101x101 stress layer must not silently fall back.
local stress={width=101,height=101,layers={{name='Blocks_1',z=1,atlas='dt_bingdao.png',firstgid=67,gids={},offsetx=13,offsety=-7}}}
for i=1,10201 do stress.layers[1].gids[i]=85 end
local map=makeMap(stress);assert(W.addLand(map)==10201 and map._seaChartWorldLand.chunks==49)
for _,clip in ipairs(map._seaChartWorldLand.groups)do assert(#clip.stencil.children<=256)end
local shifted=map._seaChartWorldLand.groups[1].stencil.children[1]
assert(shifted.position.x==13 and shifted.position.y==6393,'source layer offset lost')
assert(map._seaChartWorldCoast.chunks<=81,'101x101 coast targets must remain bounded')
local coastChildren=#map.children;assert(W.addCoast(map)==map._seaChartWorldCoast.chunks and #map.children==coastChildren)

-- Safe fallbacks and live content scale: no guessing an old binary's flips.
for _, missing in ipairs({true, false}) do
    available[base..'landmarks-world-b.png'] = not missing
    textures[base..'landmarks-world-b.png'].width = missing and 1536 or 1024
    map=makeMap(fixtures[4]);assert(W.addDetails(map)>0)
    for _, placement in ipairs(map._seaChartWorldDetails.placements) do
        assert(not placement.landmark, 'missing or wrong-sized landmark atlas must retain original decor')
    end
end
available[base..'landmarks-world-b.png']=true;textures[base..'landmarks-world-b.png'].width=1536
map=makeMap(fixtures[1]);map.layers.Blocks_1.getTileFlagsAt=false
assert(W.addLand(map)==0 and W.addDetails(map)==0 and map.layers.Blocks_1.visible)
available[base..'land-sand-repeat.png']=false;map=makeMap(fixtures[1]);assert(W.addLand(map)==0)
available[base..'land-sand-repeat.png']=true;textures[base..'land-sand-repeat.png'].width=513
assert(W.addLand(map)==0 and map.layers.Blocks_1.visible)
textures[base..'land-sand-repeat.png'].width=512
map.layers.Fogs.z=map.layers.Blocks_1.z;assert(W.addLand(map)==0 and W.addDetails(map)==0,'unsafe overlay order must retain original rendering')
map=makeMap(fixtures[1]);map.layers.Blocks_1.texture={};assert(W.addLand(map)==0,'unknown atlas fallback')
map=makeMap(fixtures[4]);map.layers.Blocks_2.getTileFlagsAt=false
assert(W.addCoast(map)==0,'an incomplete multi-family union can create false coasts')
factor=2;map=makeMap(fixtures[1]);assert(W.addLand(map)>0)
local mask=map._seaChartWorldLand.groups[1].stencil.children[1];assert(mask.rect.width==32 and mask.rect.height==32)
assert(map._seaChartWorldCoast.groups[1].target.width==128 and map._seaChartWorldCoast.groups[1].edge.rect.width==120)
print('PASS all eight flip states, six layer-selected themes, original geometry/z, 101x101 bounded GPU coast masks, safe raised groups, idempotence and missing-art/API/order fallbacks')
