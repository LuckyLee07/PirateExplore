-- Chapter-scoped atlas replacement owns no event state or display overlays.
local f=assert(io.open('bin/res/scripts/LuaClass/SeaChartTheme.lua','rb'));local source=f:read('*a');f:close()
local code=assert(source:match('(function S.applySliceEventArt%(%s*map, mapIndex%).-\nend)'))
local S={path='Images/UI/Adventure/SeaChart/'}
local environment=setmetatable({S=S},{__index=_G});local fn=assert(loadstring(code));setfenv(fn,environment);fn()
local original={}
local art={width=512,height=384}
function art:getPixelsWide()return self.width end
function art:getPixelsHigh()return self.height end
function art:setAntiAliasTexParameters()self.linear=true end
local exists=true
local cache={getTextureForKey=function()return original end,addImage=function()return art end}
environment.cc={FileUtils={getInstance=function()return {isFileExist=function()return exists end}end},Director={getInstance=function()return {getTextureCache=function()return cache end}end}}
local writes=0;local texture=original
local meta={getTexture=function()return texture end,setTexture=function(_,v)texture=v;writes=writes+1 end}
local tile={width=64,height=64};local size={width=21,height=21}
local map={getMapSize=function()return size end,getTileSize=function()return tile end,getLayer=function(_,name)assert(name=='Meta');return meta end,addChild=function()error('event art must not create overlays')end}
assert(not S.applySliceEventArt(map,0) and writes==0)
assert(not S.applySliceEventArt(map,17) and writes==0)
exists=false;assert(not S.applySliceEventArt(map,1) and writes==0);exists=true
art.width=1024;assert(not S.applySliceEventArt(map,1) and writes==0);art.width=512
tile.width=32;assert(not S.applySliceEventArt(map,1) and writes==0);tile.width=64
assert(S.applySliceEventArt(map,1) and writes==1 and texture==art and art.linear)
assert(not S.applySliceEventArt(map,1) and writes==1)
texture=original;assert(S.applySliceEventArt(map,16) and writes==2)
print('PASS all-chapter event atlas: tile/theme/asset guards, same texture dimensions, no overlay or GID mutation')
