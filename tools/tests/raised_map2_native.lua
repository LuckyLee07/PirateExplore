-- Actual native renderer fixture. No player profile or production activation.
local R=require('LuaClass/RaisedSeaMap2')
local map=assert(cc.TMXTiledMap:create('Images/Map/map_2.tmx'));map:retain()
local size=map:getMapSize();local owner={map=map,mapIndex=2,meta=map:getLayer('Meta'),fogManager={data={}},mapLayoutManagers={data={}}}
local function geometry()
 local values={}
 for _,name in ipairs({'Sea','Blocks_1','Blocks_2','Meta','GridLayer','Fogs'})do local layer=map:getLayer(name)
  for y=0,30 do for x=0,30 do values[#values+1]=layer:getTileGIDAt(cc.p(x,y));values[#values+1]=layer:getTileFlagsAt(cc.p(x,y))end end
  values[#values+1]=layer:getLocalZOrder();values[#values+1]=layer:getPositionX();values[#values+1]=layer:getPositionY()
 end
 return table.concat(values,',')
end
local before=geometry()
DataManager=setmetatable({},{__index=function()error('DataManager access forbidden')end})
ExploreDataManager=setmetatable({},{__index=function()error('save access forbidden')end})
for y=0,30 do for x=0,30 do owner.fogManager.data[tostring(x+y*31)]=0 end end
local view,reason=R.build(owner);assert(view,reason);view.root:retain();cleanWorldEnter(view.root)
print('RAISED_COUNTS',#view.model.tiles,#view.model.borders,view.wallFaces,view.scenery,#view.events)
local output=assert(os.getenv('RAISED_MAP2_CAPTURE_DIR'))
local function capture(name,width,height,x,y,scale)
 local focus=R.tilePoint(map,x,y)
 view.root:setScale(scale);view.root:setPosition(cc.p(width/2-focus.x*scale,height/2-focus.y*scale))
 assert(cleanWorldCapture(view.root,width,height,output..'/'..name..'.png'))
end
capture('map2-raised-mixed-coast-v8',1200,760,17,22,1)
capture('map2-raised-viewport-v8',1200,760,15,15,1)
capture('map2-raised-overview-v8',1600,980,15,15,.52)
capture('map2-raised-port-v8',1000,760,15,15,1.15)
-- Input uses the same camera transform as rendered geometry and billboard bases.
for _,scale in ipairs({.52,1,1.4})do
 view.root:setScale(scale);view.root:setPosition(cc.p(37,-83))
 for _,event in ipairs(view.events)do
  local p=R.tilePoint(map,event.x,event.y);local world=view.root:convertToWorldSpace(p)
  local hit=R.pick(owner,view,world)
  assert(hit.status=='known' and hit.x==event.x and hit.y==event.y and hit.event.gid==event.gid,'event input projection mismatch')
 end
end
view.root:setScale(1);view.root:setPosition(cc.p(0,0))
local landPass,waterPass=0,0
for y=1,29 do for x=1,29 do
 local p=R.tilePoint(map,x,y,R.rise);local wx,wy=(x+.5)*64,(30-y+.5)*64
 if R.alphaAt(view.model,wx,wy)then
  local hit=R.pick(owner,view,p)
  if hit.x==x and hit.y==y then assert(hit.blocked);landPass=landPass+1 end
 elseif not R.alphaAt(view.model,wx-64,wy)and not R.alphaAt(view.model,wx+64,wy)
  and not R.alphaAt(view.model,wx,wy-64)and not R.alphaAt(view.model,wx,wy+64)then
  local hit=R.pick(owner,view,R.tilePoint(map,x,y))
  if hit.plane=='water'then assert(hit.x==x and hit.y==y and not hit.blocked);waterPass=waterPass+1 end
 end
end end
assert(landPass>100 and waterPass>400)
for tile,node in pairs(view.terrainNodes)do assert(node:getLocalZOrder()==R.depth(view.model,tile.x,tile.y,4+tile.layer:getLocalZOrder()))end
for _,item in ipairs(view.eventSprites)do assert(item.sprite:getLocalZOrder()==item.depth)end
assert(R.pick(owner,view,R.project(-100,-100)).status=='out_of_bounds')
local shorePass,seen=0,{}
for _,bucket in pairs(view.wallBuckets)do for _,wall in ipairs(bucket)do
 if not seen[wall] and shorePass<100 then
  seen[wall]=true;local q={x=0,y=0};for _,p in ipairs(wall.quad)do q.x=q.x+p.x/4;q.y=q.y+p.y/4 end
  local hit=R.pick(owner,view,q);assert(hit.status=='known' and hit.blocked,'visible shore selected water');shorePass=shorePass+1
 end
end end
assert(shorePass==100)
print('SHORE_HITS',shorePass)
print('INPUT_CONTRACT',landPass,waterPass,#view.events,'source depths and out-of-bounds')
capture('map2-restore-before-v8',1200,760,15,15,1)
local extra=cc.Node:create();view.clip:addChild(extra,999999)
capture('map2-insertion-v8',1200,760,15,15,1)
extra:removeFromParent()
capture('map2-removal-v8',1200,760,15,15,1)
cleanWorldBackground();cleanWorldBackground();cleanWorldRestore()
capture('map2-restore-active-v8',1200,760,15,15,1)
cleanWorldExit(view.root);cleanWorldBackground();cleanWorldRestore();cleanWorldEnter(view.root)
capture('map2-restore-paused-v8',1200,760,15,15,1)
local raised=view;view=assert(R.build(owner,{sourceReference=true}));view.root:retain();cleanWorldEnter(view.root)
capture('map2-source-projected-viewport-v8',1200,760,15,15,1)
capture('map2-source-projected-mixed-coast-v8',1200,760,17,22,1)
cleanWorldExit(view.root);view.root:cleanup();view.root:release()
-- This is a separate synthetic discovery fixture; no FogManager/save is run.
for y=0,30 do for x=0,30 do owner.fogManager.data[tostring(x+y*31)]=x<=15 and '0' or '113' end end
view=assert(R.build(owner));view.root:retain();cleanWorldEnter(view.root)
assert(#view.events==2)
capture('map2-half-known-v8',1200,760,15,15,1)
local hidden=R.pick(owner,view,view.root:convertToWorldSpace(R.tilePoint(map,18,15)))
assert(hidden.status=='unknown' and hidden.event==nil)
owner.fogManager.data[tostring(18+15*31)]='0'
assert(R.pick(owner,view,view.root:convertToWorldSpace(R.tilePoint(map,18,15))).status=='unknown','new discovery requires matching presentation rebuild')
owner.fogManager.data[tostring(18+15*31)]='113'
cleanWorldExit(view.root);view.root:cleanup();view.root:release()
owner.fogManager.data={}
view=assert(R.build(owner));view.root:retain();cleanWorldEnter(view.root)
assert(view.visibleTiles==0 and #view.events==0 and view.scenery==0)
capture('map2-all-unknown-v8',1200,760,15,15,1)
cleanWorldExit(view.root);view.root:cleanup();view.root:release()
for y=0,30 do for x=0,30 do owner.fogManager.data[tostring(x+y*31)]='0' end end
view=assert(R.build(owner));view.root:retain();cleanWorldEnter(view.root)
capture('map2-reveal-return-v8',1200,760,15,15,1)
cleanWorldExit(view.root);view.root:cleanup();view.root:release()
local start=map:getObjectGroup('Objects'):getObject('Start')
local sx,sy=math.floor(start.x/64),math.floor((31*64-start.y)/64)
owner.playerTitlePosition={x=sx,y=sy}
view=assert(R.build(owner));view.root:retain();cleanWorldEnter(view.root)
assert(view.shipCell.x==sx and view.shipCell.y==sy and owner.playerTitlePosition.x==sx and owner.playerTitlePosition.y==sy)
capture('map2-start-ship-v8',1200,760,sx,sy,1)
cleanWorldExit(view.root);view.root:cleanup();view.root:release();owner.playerTitlePosition=nil;view=raised
-- Compare actual engine stencil/flip output with independent runtime inverse.
local W=require('LuaClass/SeaChartWorldTheme');local masks=require('LuaClass/RaisedSeaSourceAlpha')
local flags={0,2147483648,1073741824,3221225472,536870912,2684354560,1610612736,3758096384}
local root=cc.Node:create();root:retain();cleanWorldEnter(root)
local texture=cc.Director:getInstance():getTextureCache():addImage('Images/Map/dt_ludi.png');texture:setAliasTexParameters()
local expected=assert(io.open(output..'/source-alpha-flips.txt','w'))
for i,f in ipairs(flags)do
 local sprite=cc.Sprite:createWithTexture(texture,cc.rect(0,0,64,64));W.placeMaskTile(sprite,cc.p((i-1)*64,0),f)
 local clip=cc.ClippingNode:create(sprite);clip:setAlphaThreshold(.5);root:addChild(clip)
 local draw=cc.DrawNode:create();local a,b,c,d=cc.p((i-1)*64,0),cc.p(i*64,0),cc.p(i*64,64),cc.p((i-1)*64,64);draw:drawTriangle(a,b,c,cc.c4f(1,1,1,1));draw:drawTriangle(a,c,d,cc.c4f(1,1,1,1));clip:addChild(draw)
end
for y=63,0,-1 do for _,f in ipairs(flags)do for x=0,63 do
 local u,v=R.transform(x+.5,y+.5,f,true);expected:write(masks['dt_ludi.png'][0].rows[math.floor(v)+1]:sub(math.floor(u)+1,math.floor(u)+1))
end end;expected:write('\n')end;expected:close()
assert(cleanWorldCapture(root,512,64,output..'/source-alpha-eight-flips.png'))
cleanWorldExit(root);root:cleanup();root:release()
assert(before==geometry(),'prototype modified source model')
cleanWorldExit(view.root);view.root:cleanup();view.root:release();map:release();cleanWorldDrain()
print('PASS raised map2 native prototype, source model unchanged; input, fog, event and save contracts')
