-- Opt-in map2 presentation prototype. Original TMX/model remains untouched.
-- Actual shoreline walls are an extrusion of the source-alpha union boundary;
-- elevated top sprites retain exact original alpha, offsets and flip flags.
local R={halfX=math.sqrt(.5),halfY=math.sqrt(.5)*.56,rise=30}
local W=require('LuaClass/SeaChartWorldTheme')
local P=require('LuaClass/CleanSeaPresentation')
local masks=require('LuaClass/RaisedSeaSourceAlpha')
local function c(r,g,b,a)return cc.c4f(r/255,g/255,b/255,a or 1)end
function R.project(x,y,z)return {x=R.halfX*(x+y),y=R.halfY*(y-x)+(z or 0)}end
function R.inverse(x,y,z)return (x/R.halfX-(y-(z or 0))/R.halfY)/2,(x/R.halfX+(y-(z or 0))/R.halfY)/2 end
function R.depth(model,x,y,slot)return ((x+y)*(model.width+1)+x)*32+(slot or 0)end
function R.tilePoint(map,x,y,z)local s=map:getMapSize();return R.project((x+.5)*64,(s.height-y-.5)*64,z)end
local function flags(f)
 return math.floor(f/2147483648)%2==1,math.floor(f/1073741824)%2==1,math.floor(f/536870912)%2==1
end
function R.transform(x,y,f,inverse)
 local h,v,d=flags(f)
 if not d then return h and 64-x or x,v and 64-y or y end
 if h and not v then if inverse then return 64-y,x end;return y,64-x end
 if v and not h then if inverse then return y,64-x end;return 64-y,x end
 if h and v then return y,x end
 return 64-y,64-x
end
local function source(layer,p)
 local gid=layer:getTileGIDAt(p);if gid==0 then return nil end
 local family=W.familyForLayer(layer);if not family or not masks[family.atlas] then return nil end
 local rect=layer:getTileSet():getRectForGID(gid)
 return masks[family.atlas][math.floor(rect.x/64)+math.floor(rect.y/64)*6],layer:getTileFlagsAt(p),family,rect,gid
end
function R.alphaAt(model,x,y)
 for _,layer in ipairs(model.layers)do
  local ox,oy=layer:getPositionX(),layer:getPositionY()
  local tx,by=math.floor((x-ox)/64),math.floor((y-oy)/64)
  local ty=model.height-1-by
  if tx>=0 and ty>=0 and tx<model.width and ty<model.height then
   local mask,f=source(layer,cc.p(tx,ty))
   if mask then
    local u,v=R.transform(x-ox-tx*64,y-oy-by*64,f,true);u,v=math.floor(u),math.floor(v)
    if u>=0 and u<64 and v>=0 and v<64 and mask.rows[v+1]:sub(u+1,u+1)=='1' then return true,layer end
   end
  end
 end
 return false
end
local function known(owner,x,y)
 local s=owner.map:getMapSize();local f=owner.fogManager and owner.fogManager.data
 return x>=0 and y>=0 and x<s.width and y<s.height and f and tonumber(f[tostring(x+y*s.width)])==0 or false
end
local function blocked(owner,x,y)
 for _,layer in ipairs(W.landLayers(owner.map))do
  local gid=layer:getTileGIDAt(cc.p(x,y))
  if gid~=0 and type(owner.map:getPropertiesForGID(gid))=='table' then return true end
 end
 return false
end
function R.eventAt(owner,x,y)
 local map=owner.map;local meta=owner.meta or map:getLayer('Meta');local gid=meta:getTileGIDAt(cc.p(x,y))
 if gid==0 then return nil end
 local key=tostring(x+y*map:getMapSize().width)
 local record=owner.mapLayoutManagers and owner.mapLayoutManagers.data and owner.mapLayoutManagers.data[key]
 local properties=map:getPropertiesForGID(gid)
 local id=record and record.id or (type(properties)=='table' and properties.eventid)
 -- Do not invent live event identity from generic GID10, or occupation from a
 -- signed property. The exact record and GID remain available to the caller.
 local info=id and owner.eventManger and owner.eventManger.csvData and owner.eventManger.csvData[tostring(id)]
 return {x=x,y=y,gid=gid,id=id,triggerId=type(properties)=='table' and properties.eventid or nil,identitySource=record and 'live-layout' or 'tmx-property',
  state=record and record.statues or nil,layoutGid=record and record.gid or nil,
  name=info and info.name or nil,callback=info and info.eventFucString or nil}
end
local function inside(points,p)
 local sign
 for i,a in ipairs(points)do local b=points[i%#points+1];local cross=(b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x)
  if math.abs(cross)>1e-7 then local nextSign=cross>0;if sign~=nil and sign~=nextSign then return false end;sign=nextSign end
 end
 return true
end
function R.pick(owner,view,point)
 local function visible(x,y)return view.known[tostring(x+y*view.model.width)] and known(owner,x,y)end
 local p=view.root.convertToNodeSpace and view.root:convertToNodeSpace(point) or point
 local wx,wy=R.inverse(p.x,p.y,0)
 local x,y=math.floor(wx/64),view.model.height-1-math.floor(wy/64)
 if x<0 or y<0 or x>=view.model.width or y>=view.model.height then return {status='out_of_bounds'} end
 -- The same ground-plane mask clips every billboard and elevated surface.
 if not visible(x,y) then return {status='unknown',x=x,y=y} end
 local hit={x=x,y=y,plane='water',depth=-1}
 local rise=view.rise or R.rise
 local tx,ty=R.inverse(p.x,p.y,rise)
 local isLand,hitLayer=R.alphaAt(view.model,tx,ty)
 if isLand then
  local xx,yy=math.floor(tx/64),view.model.height-1-math.floor(ty/64)
  if visible(xx,yy)then hit={x=xx,y=yy,plane='terrain',depth=R.depth(view.model,xx,yy,4+hitLayer:getLocalZOrder())}end
 end
 local bucket=view.wallBuckets and view.wallBuckets[math.floor(p.x/64)..':'..math.floor(p.y/64)] or {}
 for _,wall in ipairs(bucket)do
  if wall.depth>=hit.depth and inside(wall.quad,p)then hit={x=wall.x,y=wall.y,plane='shore',depth=wall.depth}end
 end
 for _,item in ipairs(view.eventSprites or {})do
  local b=item.sprite:getBoundingBox()
  if item.depth>=hit.depth and p.x>=b.x and p.x<b.x+b.width and p.y>=b.y and p.y<b.y+b.height then
   hit={x=item.event.x,y=item.event.y,plane='event',depth=item.depth}
  end
 end
 return {status='known',x=hit.x,y=hit.y,plane=hit.plane,blocked=blocked(owner,hit.x,hit.y),event=R.eventAt(owner,hit.x,hit.y)}
end
local function iso(parent)
 local squash=cc.Node:create();squash:setScaleY(.56);parent:addChild(squash)
 local turn=cc.Node:create();turn:setRotation(45);squash:addChild(turn);return turn
end
local function texture(path)local t=cc.Director:getInstance():getTextureCache():addImage(path);return t end
local function drawNode()
 local node=cc.DrawNode:create()
 -- DrawNode's native context listener is scene-targeted and otherwise pauses
 -- beneath a pushed scene. Keep this presentation-only target listening; never
 -- resume the map, gameplay listeners, actions or scheduler.
 if node.registerScriptHandler and node.getEventDispatcher then
  local dispatcher=node:getEventDispatcher()
  node:registerScriptHandler(function(event)if event=='exit'then dispatcher:resumeEventListenersForTarget(node)end end)
 end
 return node
end
local function polygon(draw,points,col)for i=2,#points-1 do draw:drawTriangle(points[1],points[i],points[i+1],col)end end
local function rectPoly(x,y,w,h,z)
 return {R.project(x,y,z),R.project(x+w,y,z),R.project(x+w,y+h,z),R.project(x,y+h,z)}
end
local function prepare(owner)
 if not owner or not owner.map or tonumber(owner.mapIndex)~=2 then return nil,'map2-only' end
 local map=owner.map;local size=map:getMapSize();local tile=map:getTileSize()
 if size.width~=31 or size.height~=31 or tile.width~=64 or tile.height~=64 then return nil,'unsupported-grid' end
 local model={map=map,layers=W.landLayers(map),width=size.width,height=size.height,tiles={},borders={},wallDustEdges=0}
 for _,layer in ipairs(model.layers)do
  local family=W.familyForLayer(layer)
  if not family or not masks[family.atlas] or not layer.getTileFlagsAt then return nil,'unsupported-source' end
  if layer:getPositionX()~=0 or layer:getPositionY()~=0 then return nil,'prototype-offset-unsupported' end
  for y=0,size.height-1 do for x=0,size.width-1 do
   local mask,f,family,rect,gid=source(layer,cc.p(x,y))
   if mask then
    local pos=layer:getPositionAt(cc.p(x,y))
    model.tiles[#model.tiles+1]={x=x,y=y,pos=pos,mask=mask,flags=f,family=family,rect=rect,gid=gid,layer=layer}
   end
  end end
 end
 local seen={}
 for _,tile in ipairs(model.tiles)do
  for _,e in ipairs(tile.mask.edges)do
   local ax,ay=R.transform(e[1],e[2],tile.flags);local bx,by=R.transform(e[3],e[4],tile.flags)
   ax,ay,bx,by=ax+tile.pos.x,ay+tile.pos.y,bx+tile.pos.x,by+tile.pos.y
   local dx,dy=bx-ax,by-ay;local mx,my=(ax+bx)/2,(ay+by)/2
   local plus,minus=R.alphaAt(model,mx+dy*.5,my-dx*.5),R.alphaAt(model,mx-dy*.5,my+dx*.5)
   if plus~=minus then
    local nx,ny=plus and -dy or dy,plus and dx or -dx
    local a,b=ax..':'..ay,bx..':'..by;local key=a<b and a..':'..b or b..':'..a
    if not seen[key] then
     seen[key]=true
     -- Original alpha speckles remain in tops and pick truth. Tiny detached
     -- source components have no extrusion: a cosmetic wall LOD only.
     if e[5]>=16 then model.borders[#model.borders+1]={ax,ay,bx,by,nx,ny,tile=tile}
     else model.wallDustEdges=model.wallDustEdges+1 end
    end
   end
  end
 end
 return model
end
function R.build(owner,options)
 options=options or {}
 local rise=options.sourceReference and 0 or R.rise
 local model,reason=options.model
 if not model then model,reason=prepare(owner)end
 if not model then return nil,reason end
 if model.map~=owner.map then return nil,'stale-model' end
 if not cc.ClippingNode or not cc.DrawNode then return nil,'missing-native-api' end
 local manifest=P.gate();local required={manifest.water,manifest.decor,manifest.ship,manifest.atlases['t_00.png']}
 for _,tile in ipairs(model.tiles)do required[#required+1]=manifest.surfaces[tile.family.name];required[#required+1]=manifest.atlases[tile.family.atlas] end
 for _,path in ipairs(required)do if not cc.FileUtils:getInstance():isFileExist(path)then return nil,'missing-art' end end
 local root=cc.Node:create();local view={root=root,model=model,manifest=manifest,events={},eventSprites={},wallBuckets={},known={},visibleTiles=0,wallFaces=0,rise=rise}
 local function waterAt(parent,padding,z)
  local water=cc.Sprite:createWithTexture(texture(manifest.water));water:getTexture():setTexParameters(9729,9729,33648,33648)
  water:setTextureRect(cc.rect(-padding,-padding,(model.width*64)+padding*2,(model.height*64)+padding*2))
  water:setAnchorPoint(cc.p(0,0));water:setPosition(cc.p(-padding,-padding));local turn=iso(parent);turn:getParent():setLocalZOrder(z or -2);turn:addChild(water)
 end
 -- Exterior sea is purely viewport continuation. The source map bounds remain
 -- authoritative for input, fog and movement; this never creates playable cells.
 if not options.liveOverlay then
  waterAt(root,4096,-2)
  local fog=drawNode();polygon(fog,rectPoly(0,0,model.width*64,model.height*64),c(201,222,224));root:addChild(fog,-1)
 end
 local stencil=drawNode()
 for y=0,model.height-1 do for x=0,model.width-1 do
  if known(owner,x,y)then polygon(stencil,rectPoly(x*64,(model.height-y-1)*64,64,64),c(255,255,255));view.visibleTiles=view.visibleTiles+1;view.known[tostring(x+y*model.width)]=true end
 end end
 local clip=cc.ClippingNode:create(stencil);clip:setAlphaThreshold(.5);root:addChild(clip,1);view.clip=clip
 waterAt(clip,0)
 local roots={};local wallNodes={};view.terrainNodes=roots
 for _,tile in ipairs(model.tiles)do
  if known(owner,tile.x,tile.y)then
   local node=cc.Node:create();local p=R.project(tile.pos.x,tile.pos.y);node:setPosition(p)
   clip:addChild(node,R.depth(model,tile.x,tile.y,4+tile.layer:getLocalZOrder()));roots[tile]=node
   local turn=iso(node);turn:getParent():setPosition(cc.p(0,rise))
   local original=texture('Images/Map/'..tile.family.atlas);local painted=options.sourceReference and original or texture(manifest.atlases[tile.family.atlas]);painted:setAliasTexParameters()
   local base=cc.Sprite:createWithTexture(painted,tile.rect);W.placeMaskTile(base,cc.p(0,0),tile.flags);turn:addChild(base,0)
   if not options.sourceReference then
   local mask=cc.Sprite:createWithTexture(original,tile.rect);W.placeMaskTile(mask,cc.p(0,0),tile.flags)
   local top=cc.ClippingNode:create(mask);top:setAlphaThreshold(.5);turn:addChild(top,1)
   local material=texture(manifest.surfaces[tile.family.name]);material:setTexParameters(9729,9729,33648,33648)
   local surface=cc.Sprite:createWithTexture(material);surface:setTextureRect(cc.rect(tile.pos.x,-tile.pos.y-64,64,64));surface:setAnchorPoint(cc.p(0,0));top:addChild(surface)
   end
  end
 end
 for _,e in ipairs(options.sourceReference and {} or model.borders)do
  local node=roots[e.tile]
  if node then
   local origin=R.project(e.tile.pos.x,e.tile.pos.y)
   local function p(x,y,z)local a=R.project(x,y,z);return cc.p(a.x-origin.x,a.y-origin.y)end
   local d=wallNodes[e.tile]
   if not d then d=drawNode();node:addChild(d,-1);wallNodes[e.tile]=d end
   local a,b=p(e[1],e[2],0),p(e[3],e[4],0)
   d:drawSegment(a,b,1.4,c(192,239,214,.35))
   if e[5]-e[6]>0 then
    local topB,topA=p(e[3],e[4],rise),p(e[1],e[2],rise)
    local color=c(231,211,174)
    -- Raw triangles avoid drawPolygon's per-edge AA seams on pixel contours.
    local midA,midB=p(e[1],e[2],rise*.4),p(e[3],e[4],rise*.4)
    d:drawTriangle(a,b,midB,c(184,167,134));d:drawTriangle(a,midB,midA,c(184,167,134))
    d:drawTriangle(midA,midB,topB,color);d:drawTriangle(midA,topB,topA,color)
    local quad={R.project(e[1],e[2]),R.project(e[3],e[4]),R.project(e[3],e[4],rise),R.project(e[1],e[2],rise)}
    local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
    for _,q in ipairs(quad)do minX=math.min(minX,q.x);minY=math.min(minY,q.y);maxX=math.max(maxX,q.x);maxY=math.max(maxY,q.y)end
    local wall={x=e.tile.x,y=e.tile.y,quad=quad,depth=R.depth(model,e.tile.x,e.tile.y,3+e.tile.layer:getLocalZOrder())}
    for yy=math.floor(minY/64),math.floor(maxY/64)do for xx=math.floor(minX/64),math.floor(maxX/64)do
     local key=xx..':'..yy;view.wallBuckets[key]=view.wallBuckets[key]or{};table.insert(view.wallBuckets[key],wall)
    end end
    view.wallFaces=view.wallFaces+1
   end
  end
 end
 -- Upright scenery on fully opaque original foundations. Source IDs and all
 -- neighboring event slots are inspected, never a regenerated land footprint.
 local occupied={};local count=0;local candidates={}
 local meta=owner.meta or owner.map:getLayer('Meta')
 local function safe(x,y)
  if not known(owner,x,y)then return false end
  for yy=math.max(0,y-1),math.min(model.height-1,y+1)do for xx=math.max(0,x-1),math.min(model.width-1,x+1)do
   if not known(owner,xx,yy)or meta:getTileGIDAt(cc.p(xx,yy))~=0 then return false end
  end end
  local mask
  -- The family being decorated must itself offer an opaque foundation.
  for _,layer in ipairs(model.layers)do
   mask=source(layer,cc.p(x,y))
   if mask then local full=true;for _,row in ipairs(mask.rows)do if row:find('0',1,true)then full=false;break end end
    if full then return true end
   end
  end
  return false
 end
 for _,tile in ipairs(model.tiles)do
  local x,y=tile.x,tile.y
  if safe(x,y)then
   local broad=true
   for yy=y-1,y+1 do for xx=x-1,x+1 do if not safe(xx,yy)then broad=false end end end
   local paired=not broad and safe(x+1,y)
   candidates[#candidates+1]={tile=tile,broad=broad,paired=paired,rank=broad and 3 or(paired and 2 or 1),hash=x*73+y*151}
  end
 end
 table.sort(candidates,function(a,b)if a.rank~=b.rank then return a.rank>b.rank end;return a.hash%997<b.hash%997 end)
 for _,candidate in ipairs(candidates)do
  local tile=candidate.tile;local x,y=tile.x,tile.y;local key=x+y*model.width
  if not options.sourceReference and not occupied[key]and count<24 then
   local frame=manifest.landmarkFrames[tile.family.name];local s=cc.Sprite:createWithTexture(texture(manifest.landmarks),cc.rect(frame*512,0,512,512))
   local extent=candidate.broad and 176 or(candidate.paired and 116 or 90)
   s:setAnchorPoint(cc.p(.5,.115));s:setScale(extent/512)
   s:setPosition(R.tilePoint(owner.map,x+(candidate.paired and .5 or 0),y,rise))
   clip:addChild(s,R.depth(model,x,y,13));count=count+1
   for yy=y-2,y+2 do for xx=x-2,x+2 do occupied[xx+yy*model.width]=true end end
  end
 end
 view.scenery=count
 local meta=owner.meta or owner.map:getLayer('Meta');local art=options.sourceReference and meta:getTexture() or texture(manifest.atlases['t_00.png']);art:setAliasTexParameters()
 for y=0,model.height-1 do for x=0,model.width-1 do
  local event=R.eventAt(owner,x,y)
  if not options.liveOverlay and event and known(owner,x,y)then
   local rect=meta:getTileSet():getRectForGID(event.gid);local s=cc.Sprite:createWithTexture(art,rect)
   s:setScale(options.sourceReference and 1 or(event.gid==51 and 1.5 or .7))
   s:setAnchorPoint(cc.p(.5,.3));s:setPosition(R.tilePoint(owner.map,x,y))
   if not options.sourceReference then
    local contact=drawNode();local p=R.tilePoint(owner.map,x,y);local points={}
    for i=0,23 do local angle=i*math.pi/12;points[#points+1]=cc.p(p.x+math.cos(angle)*(event.gid==51 and 27 or 15),p.y-4+math.sin(angle)*6)end
    polygon(contact,points,c(22,130,128,.24));clip:addChild(contact,R.depth(model,x,y,11))
   end
   clip:addChild(s,R.depth(model,x,y,12));view.events[#view.events+1]=event;view.eventSprites[#view.eventSprites+1]={event=event,sprite=s,depth=R.depth(model,x,y,12)}
  end
 end end
 if not options.liveOverlay and owner.playerTitlePosition and known(owner,owner.playerTitlePosition.x,owner.playerTitlePosition.y)then
  local t=owner.playerTitlePosition;local s=cc.Sprite:create(manifest.ship);s:setScale(64/s:getContentSize().width)
  local p=R.tilePoint(owner.map,t.x,t.y)
  -- In-tile cosmetic berth only; owner/player/source coordinates never change.
  if meta:getTileGIDAt(cc.p(t.x,t.y))==51 then p.x=p.x-16;p.y=p.y-9 end
  s:setPosition(p);clip:addChild(s,R.depth(model,t.x,t.y,14));view.shipSprite=s;view.shipCell={x=t.x,y=t.y}
 end
 return view
end
return R
