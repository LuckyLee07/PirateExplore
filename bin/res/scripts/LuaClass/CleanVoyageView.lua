-- Map-one presentation adapter. Production Explore/FogManager own every rule,
-- position, event, discovery and save. This module never commits gameplay data.
local V={assetPath='Images/UI/CleanVoyage/'}
local function color(r,g,b,a) return cc.c4f(r/255,g/255,b/255,a or 1) end
function V.project(x,y,unit) return {x=(x-y)*67*unit,y=-(x+y)*37*unit} end
function V.unproject(x,y,unit) return (-y/(37*unit)+x/(67*unit))/2,(-y/(37*unit)-x/(67*unit))/2 end
function V.isKnown(owner,x,y)
    local size=owner.map:getMapSize()
    return x>=0 and y>=0 and x<size.width and y<size.height and owner.fogManager and owner.fogManager.data
        and tonumber(owner.fogManager.data[tostring(x+y*size.width)])==0
end
function V.heading(dx,dy)
    if dx>0 then return 'se' elseif dx<0 then return 'nw' elseif dy>0 then return 'sw' end
    return 'ne'
end
function V.shipPoint(tile,unit)
    local p=V.project(tile.x,tile.y,unit);local port=require('LuaClass/CleanFirstMap').port()
    -- Cosmetic berth offset keeps the hull in the port tile's water alongside
    -- the pier. Logical tile, collision, port trigger and camera stay exact.
    if tile.x==port.x and tile.y==port.y then p.x=p.x+10*unit;p.y=p.y+30*unit end
    return p
end
local function polygon(node,points,c)
    local d=cc.DrawNode:create();d:drawPolygon(points,#points,c,0,c);node:addChild(d);return d
end
local function circle(node,p,r,c)
    local pts={};for i=0,31 do local a=i*math.pi/16;pts[#pts+1]=cc.p(p.x+math.cos(a)*r,p.y+math.sin(a)*r) end
    return polygon(node,pts,c)
end
local function diamond(p,u)
    return {cc.p(p.x,p.y-37*u),cc.p(p.x+67*u,p.y),cc.p(p.x,p.y+37*u),cc.p(p.x-67*u,p.y)}
end
local function sprite(name,node,width,ax,ay)
    local s=cc.Sprite:create(V.assetPath..name..'.png');assert(s,'Missing clean voyage asset: '..name)
    s:setAnchorPoint(cc.p(ax or .5,ay or .5));s:setScale(width/s:getContentSize().width);node:addChild(s);return s
end
local function label(text,node,p,u)
    local l=cc.LabelTTF:create(text,'fonts/CleanVoyageSans-Regular.ttf',18*u);l:setPosition(p);l:setColor(cc.c3b(59,79,87));node:addChild(l);return l
end
local names={['3001']='港口',['3002']='航道入口',['3003']='复活点',['3068']='铁矿',['3067']='采石场',['3070']='伐木场'}
local function blocked(owner,p)
    for _,name in ipairs({'Blocks_1','Blocks_2'}) do
        local layer=owner.map:getLayer(name)
        if layer then
            local gid=layer:getTileGIDAt(p)
            local properties=gid and owner.map:getPropertiesForGID(gid)
            if type(properties)=='table' then return true end
        end
    end
    return false
end
local function shoreCell(owner,node,x,y,p,u)
    local points=diamond(p,u);local rise=18*u
    local top={};for i,v in ipairs(points) do top[i]=cc.p(v.x,v.y+rise) end
    -- Sand rim and faceted vertical rock walls only at actual known coasts.
    local edges={{1,2,x+1,y},{4,1,x,y+1},{2,3,x,y-1},{3,4,x-1,y}}
    for _,e in ipairs(edges) do
        if not V.isKnown(owner,e[3],e[4]) or not blocked(owner,cc.p(e[3],e[4])) then
            local a,b=points[e[1]],points[e[2]];local at,bt=top[e[1]],top[e[2]]
            local d=cc.DrawNode:create();node:addChild(d)
            d:drawSegment(a,b,5*u,color(217,250,228,.35))
            polygon(node,{a,b,bt,at},e[1]==1 and color(142,138,117) or color(182,169,132))
            local mx,my=(a.x+b.x)/2,(a.y+b.y)/2
            polygon(node,{a,cc.p(mx,my),cc.p(mx+4*u,my+rise*.8),at},color(201,192,157))
            d:drawSegment(at,bt,4*u,color(234,217,151))
        end
    end
    polygon(node,top,color(173,205,63))
end
local function terrainComponents(owner,u)
    local size=owner.map:getMapSize();local visited,components={},{}
    for y=0,size.height-1 do for x=0,size.width-1 do
        local key=x+y*size.width
        if not visited[key] and blocked(owner,cc.p(x,y)) then
            local queue={{x=x,y=y}};visited[key]=true;local i=1
            local c={minX=math.huge,minY=math.huge,maxX=-math.huge,maxY=-math.huge}
            while i<=#queue do
                local p=queue[i];i=i+1;local q=V.project(p.x,p.y,u)
                c.minX=math.min(c.minX,q.x-67*u);c.maxX=math.max(c.maxX,q.x+67*u)
                c.minY=math.min(c.minY,q.y-37*u);c.maxY=math.max(c.maxY,q.y+37*u)
                for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
                    local nx,ny=p.x+d[1],p.y+d[2];local k=nx+ny*size.width
                    if nx>=0 and ny>=0 and nx<size.width and ny<size.height and not visited[k] and blocked(owner,cc.p(nx,ny)) then
                        visited[k]=true;queue[#queue+1]={x=nx,y=ny}
                    end
                end
            end
            components[#components+1]=c
        end
    end end
    return components
end
local function drawWorld(owner,view,old)
    local map,size=owner.map,owner.map:getMapSize();local u=view.u
    local previousKnown=view.known or {};view.known={}
    view.world:removeAllChildren()
    local land=cc.Node:create();local events=cc.Node:create();local fog=cc.Node:create()
    view.world:addChild(land,1);view.world:addChild(fog,4)
    local known={};local stencil=cc.DrawNode:create();local groundStencil=cc.DrawNode:create();local harborStencil=cc.DrawNode:create()
    local discoveredClip=cc.ClippingNode:create(stencil);discoveredClip:setAlphaThreshold(.1);view.world:addChild(discoveredClip,2);discoveredClip:addChild(events)
    local harbor=require('LuaClass/CleanFirstMap').port()
    local harborPoint=V.project(harbor.x,harbor.y,u)
    for y=0,size.height-1 do for x=0,size.width-1 do
        if V.isKnown(owner,x,y) then
            local p=V.project(x,y,u);local points=diamond(p,u)
            local key=tostring(x+y*size.width);view.known[key]=true
            known[#known+1]={x=x,y=y,p=p,fresh=old and not previousKnown[key]}
            stencil:drawPolygon(points,#points,color(255,255,255),0,color(255,255,255))
            if blocked(owner,cc.p(x,y)) then
                local authoredPatch=(x>=5 and x<=6 and y>=7 and y<=8) or (x>=4 and x<=7 and y>=12 and y<=15)
                if not authoredPatch then shoreCell(owner,land,x,y,p,u) end
                groundStencil:drawPolygon(points,#points,color(255,255,255),0,color(255,255,255))
                harborStencil:drawPolygon(points,#points,color(255,255,255),0,color(255,255,255))
            else
                local d=cc.DrawNode:create();land:addChild(d)
                for i=1,4 do d:drawSegment(points[i],points[i%4+1],.6*u,color(201,247,240,.32)) end
            end
            if x==harbor.x and y==harbor.y then harborStencil:drawPolygon(points,#points,color(255,255,255),0,color(255,255,255)) end
            local gid=owner.meta:getTileGIDAt(cc.p(x,y));local prop=gid and map:getPropertiesForGID(gid)
            if type(prop)=='table' and prop.eventid then
                local id=tostring(prop.eventid);local positive=tostring(math.abs(tonumber(id) or 0));local name=names[positive]
                if not name and positive~='0' and positive~='10' then
                    local info=dataController.getStrongholdAttributeInfoById(positive)
                    name=info and info.name or '海上事件'
                end
                local propAssets={['3067']='event-quarry-raft-clean-v1',['3070']='event-timber-raft-clean-v1',['3068']='event-iron-raft-clean-v1'}
                if propAssets[positive] then
                    local propSprite=sprite(propAssets[positive],events,106*u,.5,.38);propSprite:setPosition(p)
                elseif name and positive~='3001' then
                    -- Preserve the shipped symbol for uncommon original events.
                    local tile=owner.meta:getTileAt(cc.p(x,y))
                    local frame=tile and tile:getSpriteFrame()
                    if frame then local icon=cc.Sprite:createWithSpriteFrame(frame);icon:setPosition(p);icon:setScale(54*u/icon:getContentSize().width);events:addChild(icon) end
                end
                if name and positive~='3001' then
                    if tonumber(id)<0 then name=name..' · 已占领' end
                    local caption=label(name,events,cc.p(p.x,p.y+48*u),u)
                    local size=caption:getContentSize();local backing=cc.LayerColor:create(cc.c4b(252,247,226,220),size.width+12*u,24*u)
                    backing:setPosition(cc.p(p.x-size.width/2-6*u,p.y+36*u));events:addChild(backing,1);caption:setLocalZOrder(2)
                end
            end
        end
    end end
    -- Continuous clean coast texture is constrained to the exact discovered
    -- blocked footprint. Full component bounds are stable across revelation;
    -- neither texture nor component metadata makes an unknown pixel visible.
    local groundClip=cc.ClippingNode:create(groundStencil);groundClip:setAlphaThreshold(.1);land:addChild(groundClip,3)
    for _,c in ipairs(view.terrainComponents) do
        local width=(c.maxX-c.minX)*1.18
        local coast=sprite('coast-clean-palms-v1',groundClip,width,.5,.5)
        coast:setPosition(cc.p((c.minX+c.maxX)/2,(c.minY+c.maxY)/2+5*u))
    end
    -- Authored foreground patches keep the local headland's texture scale
    -- independent of its longer, still-fogged northern continuation.
    for _,patch in ipairs({{x=5.5,y=7.5,width=290,ay=.38},{x=5.5,y=13.5,width=590,ay=.40}}) do
        local coast=sprite('coast-clean-palms-v1',groundClip,patch.width*u,.5,patch.ay)
        coast:setPosition(V.project(patch.x,patch.y,u))
    end
    -- Clip the large harbor artwork to genuinely discovered cells. Unknown
    -- shore/obstacle geometry never appears simply because an asset is large.
    local harborClip=cc.ClippingNode:create(harborStencil);harborClip:setAlphaThreshold(.1);events:addChild(harborClip,-1)
    local harborArt=sprite('harbor-clean-ne',harborClip,470*u,0,0)
    harborArt:setPosition(cc.p(harborPoint.x-412*u,harborPoint.y-383*u))
    local s=require('LuaClass/AdventureProgress').getState(DataManager:getInstance())
    local wreck=s.tutorialPoint
    if wreck and tonumber(wreck.mapIndex)==tonumber(owner.mapIndex) and not s.pending
        and require('LuaClass/AdventureProgress').availableEpisode(DataManager:getInstance())
        and V.isKnown(owner,wreck.x,wreck.y) then
        local p=V.project(wreck.x,wreck.y,u)
        local wreckSprite=sprite('event-wreck-hull-clean-v1',events,122*u,.5,.40);wreckSprite:setPosition(p)
        label('沉船',events,cc.p(p.x,p.y+48*u),u)
    end
    -- Known-route planner remains authoritative. Draw only its already-checked
    -- passable path, never a straight line through undiscovered sea.
    local route=require('LuaClass/AdventureNavigation').query(owner,{breadCoefficient=owner.adventureBreadCoefficient or 0})
    if route.path then
        local d=cc.DrawNode:create();events:addChild(d)
        for i=2,#route.path do
            local a,b=route.path[i-1],route.path[i]
            if V.isKnown(owner,a.x,a.y) and V.isKnown(owner,b.x,b.y) then
                d:drawSegment(V.project(a.x,a.y,u),V.project(b.x,b.y,u),1.3*u,color(255,214,120,.8))
            end
        end
    end
    -- Only fully clear production fog cells form holes in this visual fog.
    -- Unknown content wasn't rendered above, including at soft mask edges.
    local vs='attribute vec4 a_position;attribute vec2 a_texCoord;attribute vec4 a_color;varying vec2 uv;varying vec4 tint;varying vec2 pos;void main(){gl_Position=CC_PMatrix*a_position;uv=a_texCoord;tint=a_color;pos=a_position.xy;}'
    local fs='uniform sampler2D CC_Texture0;uniform float cameraX;uniform float cameraY;uniform float reveal;varying vec2 uv;varying vec4 tint;varying vec2 pos;void main(){vec2 mp=pos-vec2(cameraX,cameraY);float d=1000.0;'
    local center=view.tile
    for _,v in ipairs(known) do
        if math.abs(v.x-center.x)<11 and math.abs(v.y-center.y)<11 then
            fs=fs..string.format('d=min(d,length((mp-vec2(%.3f,%.3f))/vec2(%.3f,%.3f))%s);',v.p.x,v.p.y,72*u,46*u,v.fresh and '+(1.0-reveal)*4.0' or '')
        end
    end
    fs=fs..'float edge=sin(mp.x*.025+sin(mp.y*.037))*.15;float fade=smoothstep(.75,2.25,d+edge);vec4 c=texture2D(CC_Texture0,uv);c.rgb=mix(c.rgb,vec3(.85,.91,.93),.32);gl_FragColor=c*tint;gl_FragColor.a*=fade;}'
    local program=cc.GLProgram:new();program:initWithByteArrays(vs,fs);program:bindAttribLocation('a_position',0);program:bindAttribLocation('a_color',1);program:bindAttribLocation('a_texCoord',2);program:link();program:updateUniforms()
    view.shader={program=program,x=program:getUniformLocationForName('cameraX'),y=program:getUniformLocationForName('cameraY'),r=program:getUniformLocationForName('reveal')}
    local cp=V.project(center.x,center.y,u)
    for i=0,14 do
        local cloud=sprite('fog-bank-soft',fog,(1050+i%3*100)*u,.5,.5)
        cloud:setPosition(cc.p(cp.x+(i%3-1)*340*u,cp.y+(math.floor(i/3)-2)*250*u))
        cloud:setRotation((i%3-1)*27);cloud:setFlippedX(i%2==0);cloud:setOpacity(247);cloud:setShaderProgram(program)
    end
    local boat=cc.Node:create();view.world:addChild(boat,5);view.boat=boat
    local contact=cc.DrawNode:create();boat:addChild(contact)
    circle(contact,cc.p(0,-5*u),20*u,color(16,97,109,.20))
    local heading=view.heading or 'ne'
    local widths={ne=165,nw=165,sw=153,se=145};local anchors={ne={.48,.105},nw={.52,.175},sw={.5,.105},se={.5,.15}}
    sprite('boat-clean-'..heading,boat,widths[heading]*u,anchors[heading][1],anchors[heading][2])
    boat:setPosition(V.shipPoint(center,u))
    view.knownCount=#known
    require('LuaClass/CleanVoyageHUD').refresh(owner,view)
end
function V.keepLegacyHudHidden(owner)
    -- Original EventManger restores its own tipLayer after every event.
    -- The clean adapter keeps that live callback host hidden, without changing event rules.
    if owner.cleanVoyageView and owner.tipLayer then owner.tipLayer:setVisible(false) end
end
function V.refresh(owner)
    local view=owner.cleanVoyageView;if not view then return end
    local p=owner.playerTitlePosition;if not p then return end
    local previous=view.tile
    local moved=previous and (previous.x~=p.x or previous.y~=p.y)
    view.tile={x=p.x,y=p.y}
    if moved then view.heading=V.heading(p.x-previous.x,p.y-previous.y) end
    drawWorld(owner,view,previous)
    local target=V.project(p.x,p.y,view.u)
    view.world:stopAllActions();view.boat:stopAllActions()
    local origin=cc.p(view.cx-target.x,view.cy-target.y)
    view.world:setPosition(origin)
    if moved then
        local from=V.project(previous.x,previous.y,view.u)
        view.world:setPosition(cc.p(view.cx-from.x,view.cy-from.y));view.boat:setPosition(V.shipPoint(previous,view.u))
        view.animating=true;view.revealElapsed=0
        view.world:runAction(cc.EaseSineInOut:create(cc.MoveTo:create(.38,origin)))
        view.boat:runAction(cc.Sequence:create(cc.EaseSineInOut:create(cc.MoveTo:create(.38,V.shipPoint(p,view.u))),cc.CallFunc:create(function()view.animating=false end)))
    else view.animating=false;view.revealElapsed=.38 end
end
function V.mount(owner)
    V.unmount(owner)
    if not require('LuaClass/CleanFirstMap').isEnabled(DataManager:getInstance(),owner.mapIndex) then return end
    local size=screenSize or cc.Director:getInstance():getVisibleSize();local u=size.width/640
    local view={u=u,cx=size.width*.53,cy=size.height*.39}
    local node=cc.Node:create();view.node=node;owner:addChild(node,1);owner.cleanVoyageView=view
    local bg=cc.LayerColor:create(cc.c4b(31,163,178,255),size.width,size.height);node:addChild(bg)
    local sea=sprite('sea-turquoise-caustics',node,size.height*1.25,.5,.5);sea:setPosition(cc.p(size.width/2,size.height/2));sea:setOpacity(110)
    view.world=cc.Node:create();node:addChild(view.world)
    view.terrainComponents=terrainComponents(owner,u)
    owner.moveLayer:setVisible(false)
    require('LuaClass/CleanVoyageHUD').mount(owner,view)
    V.refresh(owner)
    node:scheduleUpdateWithPriorityLua(function(dt)
        V.keepLegacyHudHidden(owner)
        local bag=owner.bagController
        if bag and (view.hudFood~=bag:getBreads() or view.hudCost~=bag.costSpace or view.hudLimit~=bag.limited) then require('LuaClass/CleanVoyageHUD').refresh(owner,view) end
        if view.shader then local shader=view.shader;shader.program:use();shader.program:setUniformLocationF32(shader.x,view.world:getPositionX());shader.program:setUniformLocationF32(shader.y,view.world:getPositionY());view.revealElapsed=math.min(.38,(view.revealElapsed or .38)+dt);shader.program:setUniformLocationF32(shader.r,view.revealElapsed/.38) end
    end,0)
    print('CLEAN_VOYAGE_MOUNT','map='..tostring(owner.mapIndex),'known='..tostring(view.knownCount))
end
function V.unmount(owner)
    if owner.cleanVoyageView then
        owner.cleanVoyageView.node:unscheduleUpdate();owner.cleanVoyageView.node:removeFromParent(true);owner.cleanVoyageView=nil
        if owner.moveLayer then owner.moveLayer:setVisible(true) end
        if owner.tipLayer then owner.tipLayer:setVisible(true) end
    end
end
function V.touch(owner,point)
    local view=owner.cleanVoyageView
    if not view or view.animating or owner.statue~='ready' or owner.adventureDialog or owner.warmPause then return false end
    -- A cosmetic berth offset must not turn a tap on the visible boat into a
    -- sailing command. Keep directional picking relative to the logical tile.
    local tile=owner.playerTitlePosition or view.tile
    if tile then
        local logical=V.project(tile.x,tile.y,view.u)
        local contact=V.shipPoint(tile,view.u)
        local bx,by=V.unproject(point.x-view.cx-(contact.x-logical.x),point.y-view.cy-(contact.y-logical.y),view.u)
        if math.abs(bx)+math.abs(by)<.35 then return false end
    end
    local dx,dy=V.unproject(point.x-view.cx,point.y-view.cy,view.u)
    if math.abs(dx)+math.abs(dy)<.35 then return false end
    local direction
    if math.abs(dx)>math.abs(dy) then direction=dx>0 and RightDircion or LeftDirction
    else direction=dy>0 and BottomDirction or UpDiriction end
    owner:jointedCalBack(direction);return true
end
return V
