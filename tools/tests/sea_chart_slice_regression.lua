-- Run from the repository root: build/linux/tests/lua-ui-tests tools/tests/sea_chart_slice_regression.lua
-- Read-only TMX fixtures, pure display-node mocks, no game process or save.
local function equal(actual, wanted, message)
    assert(actual == wanted, (message or 'value') .. ': expected ' .. tostring(wanted) .. ', got ' .. tostring(actual))
end
local function forbidden(name)
    return function() error('Display slice must not call ' .. name, 2) end
end
local function read(path)
    local file = assert(io.open(path, 'rb'))
    local bytes = file:read('*a'); file:close(); return bytes
end
local tmxPath = 'bin/res/assets/Images/Map/map_1.tmx'
local originalTMX = read(tmxPath)
-- The game's embedded Lua omits io.popen. Decode into an ephemeral test-only
-- file, read it once, and remove it; the source TMX is opened read-only.
local temporaryFixture=os.tmpname()
local function shellQuote(value)return "'"..value:gsub("'", "'\\''").."'"end
local decodeStatus=os.execute("python3 - > "..shellQuote(temporaryFixture).." <<'PY'\n"..[[
import base64, struct, xml.etree.ElementTree as E, zlib
root = E.parse('bin/res/assets/Images/Map/map_1.tmx').getroot()
print('return {width=%s,height=%s,tilewidth=%s,tileheight=%s,layers={' % tuple(root.attrib[k] for k in ('width','height','tilewidth','tileheight')))
for layer in root.findall('layer'):
    values = struct.unpack('<%dI' % (int(root.attrib['width'])*int(root.attrib['height'])), zlib.decompress(base64.b64decode(layer.find('data').text)))
    print('{name="%s",gids={%s}},' % (layer.attrib['name'], ','.join(map(str, values))))
print('}}')
PY
]])
local fixtureText=read(temporaryFixture)
assert(os.remove(temporaryFixture))
assert(decodeStatus==0 or decodeStatus==true,'read-only TMX decoder failed')
local fixture = assert((loadstring or load)(fixtureText))()
equal(fixture.width, 21, 'shipped map width')
equal(fixture.height, 21, 'shipped map height')
local function immutable(values)
    return setmetatable({}, {__index=values, __newindex=forbidden('fixture mutation')})
end
local Node = {}
local function node(kind)
    return setmetatable({kind=kind or 'Node', children={}, position={x=0,y=0},
        size={width=0,height=0}, anchor={x=.5,y=.5}, scaleX=1, scaleY=1, visible=true, z=0}, {__index=Node})
end
function Node:addChild(child, z)
    assert(child and not child.parent, 'child already has a parent')
    child.parent = self; child.z = z or 0; self.children[#self.children+1] = child
end
function Node:getParent() return self.parent end
function Node:getLocalZOrder() return self.z end
function Node:setAnchorPoint(point) self.anchor=point end
function Node:setPosition(point) self.position=point end
function Node:getPositionX() return self.position.x end
function Node:getPositionY() return self.position.y end
function Node:setContentSize(size) self.size=size end
function Node:getContentSize() return self.size end
function Node:setScale(scale) self.scaleX=scale; self.scaleY=scale end
function Node:setVisible(visible) self.visible=visible end
function Node:removeFromParent(cleanup)
    if self.parent then
        for i, child in ipairs(self.parent.children) do
            if child == self then table.remove(self.parent.children, i); break end
        end
        self.parent=nil
    end
    if cleanup then
        while #self.children > 0 do self.children[#self.children]:removeFromParent(true) end
        self.cleaned=true
    end
end
for _, method in ipairs({'runAction','scheduleUpdateWithPriorityLua','registerScriptHandler','setScaleX','setScaleY'}) do
    Node[method]=forbidden(method)
end
local art={exists=true, readable=true, width=960, height=1152, creates=0}
cc={
    p=function(x,y)return {x=x,y=y}end,
    size=function(width,height)return {width=width,height=height}end,
    Node={create=function()return node()end},
    Sprite={create=function(_,path)
        art.creates=art.creates+1
        if not art.readable then return nil end
        local sprite=node('Sprite');sprite.path=path;sprite.size={width=art.width,height=art.height}
        function sprite:getTexture()return {setTexParameters=function(_,a,b,c,d)
            assert(a==9729 and b==9729 and c==33071 and d==33071,'independent NPOT linear/clamp import')
        end}end
        return sprite
    end, createWithTexture=forbidden('materialize TMX tiles')},
    FileUtils={getInstance=function()return {isFileExist=function(_,path)
        equal(path,'Images/UI/Adventure/SeaChart/Slice/coast-piece.png','asset path')
        return art.exists
    end}end},
    ClippingNode={create=forbidden('clip raised coast to a flat mask')},
    Director={getInstance=forbidden('create schedules or read global scene state')},
    EventListenerCustom={create=forbidden('register an event listener')}
}
DataManager=immutable({getInstance=forbidden('DataManager')})
SaveDataManager=immutable({getInstance=forbidden('SaveDataManager')})
local S=dofile('bin/res/scripts/LuaClass/SeaChartSlice.lua')
local assetFile=assert(io.open('bin/res/assets/'..S.path..'coast-piece.png','rb'))
local pngHeader=assetFile:read(26);assetFile:close()
equal(pngHeader:sub(1,8),'\137PNG\r\n\26\n','shipped slice is PNG')
local function uint32(offset)
    local a,b,c,d=pngHeader:byte(offset,offset+3)
    return ((a*256+b)*256+c)*256+d
end
local actualWidth,actualHeight=uint32(17),uint32(21)
equal(actualWidth*384,actualHeight*320,'shipped art keeps exact 5:6 canvas')
equal(pngHeader:byte(26),6,'shipped coast has a real RGBA alpha channel')

local function makeMap(options)
    options=options or {}
    local map=node('TMXTiledMap')
    local layers, values={},{}
    local mapSize=immutable({width=options.width or fixture.width,height=options.height or fixture.height})
    local tileSize=immutable({width=options.tilewidth or fixture.tilewidth,height=options.tileheight or fixture.tileheight})
    function map:getMapSize() return mapSize end
    function map:getTileSize() return tileSize end
    function map:getLayer(name) return layers[name] end
    map.setProperty=forbidden('TMX properties mutation')
    for index, source in ipairs(fixture.layers) do
        local layer=node('TMXLayer')
        local name=source.name
        local cells={}
        for i, gid in ipairs(source.gids) do cells[i]=gid end
        values[name]=cells
        layer.name=name
        layer.texture=immutable({name=name..'-original'})
        layer.position={x=options.landX and name=='Blocks_1' and options.landX or 0,y=0}
        function layer:getTileGIDAt(point)
            assert(point.x>=0 and point.y>=0 and point.x<21 and point.y<21,'out-of-map read')
            return cells[point.y*21+point.x+1]
        end
        function layer:getPositionAt(point)return {x=point.x*64,y=(21-point.y-1)*64}end
        for _, method in ipairs({'setTileGID','removeTileAt','getTileAt','setTexture','setVisible','setPosition','setOpacity','setColor','setLocalZOrder'}) do
            layer[method]=forbidden(name..':'..method)
        end
        map:addChild(layer,index-1)
        layers[name]=layer
    end
    -- Only the fixture controller may simulate a gameplay fog/land update.
    local controls={layers=layers}
    function controls.set(name,x,y,gid) values[name][y*21+x+1]=gid end
    function controls.fingerprint()
        local parts={}
        for _, source in ipairs(fixture.layers) do
            local layer=layers[source.name]
            if layer then
                parts[#parts+1]=source.name..':'..table.concat(values[source.name],',')..':'..tostring(layer.visible)
                    ..':'..tostring(layer.texture)..':'..layer.z..':'..layer.position.x..':'..layer.position.y
            end
        end
        return table.concat(parts,'|')
    end
    return map,controls
end
local function resetArt()art.exists=true;art.readable=true;art.width=960;art.height=1152 end
local function fallback(map,index,reason)
    local childCount=#map.children
    local group,actual=S.build(map,index)
    equal(group,nil,'fallback group');equal(actual,reason,'fallback reason')
    equal(#map.children,childCount,'fallback preserves children')
    equal(map._seaChartSliceGroup,nil,'fallback owns no display group')
end

local map,control=makeMap()
local baseline=control.fingerprint()
local group=assert(S.build(map,1))
equal(#map.children,6,'only one new root')
equal(group:getParent(),map,'map owns slice')
equal(group.position.x,192,'world x');equal(group.position.y,832,'world y')
equal(group.size.width,320,'logical width');equal(group.size.height,384,'logical height')
equal(group.anchor.x,0,'root anchor x');equal(group.anchor.y,0,'root anchor y')
equal(group.z,control.layers.Blocks_1.z,'same land z, added afterward')
for _,name in ipairs({'Meta','GridLayer','Fogs'})do assert(group.z<control.layers[name].z,name..' must stay above coast')end
equal(#group.children,1,'single coordinated raster')
local sprite=group.children[1]
equal(sprite.kind,'Sprite','raised coast is not clipped flat')
equal(sprite.path,S.path..'coast-piece.png','coast art')
equal(sprite.position.x,0,'art local x');equal(sprite.position.y,0,'art local y')
equal(sprite.anchor.x,0,'art anchor x');equal(sprite.anchor.y,0,'art anchor y')
equal(sprite.scaleX,1/3,'native uniform scale');equal(sprite.scaleY,sprite.scaleX,'no art distortion')
equal(sprite.size.width*sprite.scaleX,320,'display width');equal(sprite.size.height*sprite.scaleY,384,'display height')
equal(control.fingerprint(),baseline,'build preserves every source GID and layer')
equal(S.build(map,1),group,'repeat build reuses its own group');equal(#map.children,6,'no duplicate display root')

for _,index in ipairs({0,2,16,'1'})do fallback(makeMap(),index,'chapter')end
fallback(makeMap(),nil,'chapter')
for _,options in ipairs({{width=22},{height=22},{tilewidth=32},{tileheight=65}})do fallback(makeMap(options),1,'map-size')end
fallback(makeMap({landX=1}),1,'land-position')
for _,name in ipairs({'Blocks_1','Meta','GridLayer','Fogs'})do
    local candidate,state=makeMap();state.layers[name]=nil
    fallback(candidate,1,name=='Blocks_1' and 'land-layer' or 'overlay-order')
end
for _,name in ipairs({'Meta','GridLayer','Fogs'})do
    local candidate,state=makeMap();state.layers[name].z=state.layers.Blocks_1.z
    fallback(candidate,1,'overlay-order')
end
-- Every occupied cell and every empty border cell is part of the contract.
for y=2,7 do for x=3,7 do
    local candidate,state=makeMap()
    state.set('Blocks_1',x,y,state.layers.Blocks_1:getTileGIDAt({x=x,y=y})+1)
    fallback(candidate,1,'land-cells')
end end
local distant,distantState=makeMap();distantState.set('Blocks_1',19,19,95)
assert(S.build(distant,1),'this is an isolated slice, not a whole-map replacement')

art.exists=false;fallback(makeMap(),1,'missing-art');resetArt()
art.readable=false;fallback(makeMap(),1,'unreadable-art');resetArt()
for _,size in ipairs({{320,320},{0,384},{320,0},{321,384}})do
    art.width=size[1];art.height=size[2];fallback(makeMap(),1,'art-aspect')
end
for _,size in ipairs({{320,384},{640,768},{1280,1536},{actualWidth,actualHeight}})do
    art.width=size[1];art.height=size[2]
    local candidate=makeMap();local result=assert(S.build(candidate,1)).children[1]
    equal(result.scaleX,320/size[1],'source-resolution-independent scale')
    equal(result.scaleY,result.scaleX,'source keeps its aspect')
end
resetArt()

-- The native Fogs renderer remains authoritative during partial exploration.
-- One hidden foot must not suppress the already-visible rest of this coast.
for _,gid in ipairs({1,4,8,11,18})do
    control.set('Fogs',6,6,gid)
    local before=control.fingerprint()
    assert(S.refresh(map,group));assert(group.visible)
    equal(control.fingerprint(),before,'refresh does not alter native fog or any TMX state')
end
control.set('Blocks_1',4,3,71)
assert(not S.refresh(map,group));equal(group.visible,false,'changed land hides the stale display')
control.set('Blocks_1',4,3,70)
assert(S.refresh(map,group));equal(group.visible,true,'restored valid source may display again')
local fog=control.layers.Fogs;control.layers.Fogs=nil
assert(not S.refresh(map,group));equal(group.visible,false,'no protective fog layer means no new art')
control.layers.Fogs=fog;assert(S.refresh(map,group))

local other=makeMap()
assert(not S.refresh(other,group),'new chapter cannot refresh an old map group')
assert(not S.cleanup(other,group),'new map cannot remove a previous map group')
equal(group:getParent(),map,'wrong-owner cleanup leaves owner intact')
assert(S.cleanup(map,group));equal(map._seaChartSliceGroup,nil,'cleanup clears display ownership')
assert(group.cleaned and sprite.cleaned,'cleanup follows native child ownership')
equal(#map.children,5,'cleanup retains all five original TMX layers')
assert(not S.cleanup(map,group));assert(not S.refresh(map,group),'cleaned display never refreshes')
local nextGroup=assert(S.build(map,1));assert(nextGroup~=group,'re-entering builds a fresh owned display')
local scene=node();scene:addChild(map);map:removeFromParent(true)
assert(nextGroup.cleaned,'map removal cleans the complete slice without extra listeners')
assert(not S.refresh(map,nextGroup),'detached map child cannot refresh')
assert(S.cleanup(map,nextGroup),'explicit cleanup safely clears detached ownership')
equal(read(tmxPath),originalTMX,'the original TMX remains byte-for-byte unchanged')
print('PASS sea chart slice: real TMX guard, one chapter, natural scale, protected z order, native fog, safe fallback and owned cleanup')
