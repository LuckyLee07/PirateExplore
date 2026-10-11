-- Warm Q v1 native presentation; no economy, save, map or combat state writes.
require 'LuaClass/MasterTheme'
local W={path='Images/UI/Warm/',worldPath='Images/UI/CleanVoyage/',font='fonts/CleanVoyageSans-Regular.ttf'}
WarmTheme=W
function W.enabled() return rawget(_G,'WARM_PIRATE_V1')~=false end
W.colors={ink=cc.c3b(38,65,68),navy=cc.c3b(38,65,68),paper=cc.c3b(255,247,229),coral=cc.c3b(186,84,58),
 sea=cc.c3b(25,126,140),muted=cc.c3b(99,115,111),line=cc.c3b(217,224,204),white=cc.c3b(255,252,242),gold=cc.c3b(209,151,47)}
local function rgba(c,a)return cc.c4f(c.r/255,c.g/255,c.b/255,a or 1) end
function W.label(text,size,color,x,y,bold,anchorX)
 local n=cc.LabelTTF:create(tostring(text or ''),W.font,size or 24)
 n:setColor(color or W.colors.ink);n:setAnchorPoint(cc.p(anchorX or 0,.5));n:setPosition(cc.p(x or 0,y or 0));return n
end
function W.fit(n,width)
 local s=n:getContentSize().width;n:setScale(s>width and width/s or 1);return n
end
function W.panel(w,h,color,radius)
 local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setCascadeOpacityEnabled(true)
 local d=cc.DrawNode:create();local pts={};local r=math.min(radius or 8,8,w/2,h/2)
 if r==0 then pts={cc.p(0,0),cc.p(w,0),cc.p(w,h),cc.p(0,h)} else
 for _,a in ipairs({{w-r,h-r,0},{r,h-r,90},{r,r,180},{w-r,r,270}}) do
  for i=0,8 do local ang=math.rad(a[3]+i*11.25);pts[#pts+1]=cc.p(a[1]+r*math.cos(ang),a[2]+r*math.sin(ang)) end
 end
 end
 d:drawPolygon(pts,#pts,rgba(color or W.colors.paper),.65,rgba(W.colors.line));n:addChild(d);return n
end
function W.sprite(path,w,h)
 if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
 local s=cc.Sprite:create(path);if not s then return nil end
 local z=s:getContentSize();s:setScale(math.min(w/z.width,h/z.height));s:setAnchorPoint(cc.p(.5,.5));return s
end
function W.cover(path,w,h) return MasterTheme.cover(path,w,h) end
function W.icon(name,size,color)
 local tint=color or W.colors.ink
 -- Reuse the shipped illustrated functional props, without a generic face for
 -- crew ownership. Navigation-only symbols remain restrained native geometry.
 local indices={hammer=4,chest=5,bag=8,map=2,log=6}
 local index=indices[name];local path=W.path..'icons.png'
 if name=='food' then
  local art=W.sprite('Images/Icon/r_2.png',size,size)
  if art then local n=cc.Node:create();n:setContentSize(cc.size(size,size));art:setPosition(cc.p(size/2,size/2));n:addChild(art);return n end
 elseif index and cc.FileUtils:getInstance():isFileExist(path) then
  local full=cc.Sprite:create(path);local z=full:getContentSize();local cw,ch=z.width/3,z.height/3
  local boxes={{124,132,388,395},{75,129,367,400},{50,114,323,413},{109,93,374,356},{81,111,366,360},{70,96,332,357},{114,89,354,324},{93,67,362,323}}
  local b=boxes[index];local x,y,bw,bh=b[1]-4,b[2]-4,b[3]-b[1]+9,b[4]-b[2]+9
  local art=cc.Sprite:create(path,cc.rect((index-1)%3*cw+x,math.floor((index-1)/3)*ch+y,bw,bh))
  art:setScale(math.min(size/bw,size/bh));art:setPosition(cc.p(size/2,size/2))
  local n=cc.Node:create();n:setContentSize(cc.size(size,size));n:addChild(art);return n
 end
 if name=='sail' or name=='crew' or name=='food' or name=='anchor' then return MasterTheme.icon(name,size,tint) end
 local n=cc.Node:create();n:setContentSize(cc.size(size,size));local d=cc.DrawNode:create();n:addChild(d)
 local c=rgba(tint);local function p(x,y)return cc.p(x*size,y*size)end
 local function line(x,y,a,b,width)d:drawSegment(p(x,y),p(a,b),(width or .025)*size,c)end
 local function poly(points)local q={};for _,v in ipairs(points)do q[#q+1]=p(v[1],v[2])end;d:drawPolygon(q,#q,c,0,c)end
 if name=='hammer' then
  poly({{.18,.20},{.28,.12},{.65,.61},{.55,.69}})
  poly({{.35,.76},{.54,.96},{.91,.67},{.74,.48}})
 elseif name=='chest' or name=='bag' then
  poly({{.14,.16},{.86,.16},{.86,.65},{.14,.65}})
  poly({{.14,.72},{.86,.72},{.76,.89},{.24,.89}})
  -- The seam/lock is a genuinely open gap, not an incompatible color paint.
 elseif name=='settings' then
  for i=0,7 do local a=i*math.pi/4
   line(.5+.25*math.cos(a),.5+.25*math.sin(a),.5+.41*math.cos(a),.5+.41*math.sin(a),.055)
  end
  for i=0,23 do local a,b=i*math.pi/12,(i+1)*math.pi/12
   line(.5+.22*math.cos(a),.5+.22*math.sin(a),.5+.22*math.cos(b),.5+.22*math.sin(b),.045)
  end
 elseif name=='back' then
  line(.75,.50,.22,.50,.035);line(.22,.50,.45,.74,.035);line(.22,.50,.45,.26,.035)
 elseif name=='map' then
  for _,v in ipairs({{.13,.19,.13,.79},{.13,.79,.38,.9},{.38,.9,.64,.78},{.64,.78,.87,.9},{.87,.9,.87,.29},{.87,.29,.64,.18},{.64,.18,.38,.3},{.38,.3,.13,.19},{.38,.3,.38,.9},{.64,.18,.64,.78}})do line(unpack(v))end
 else
  for _,v in ipairs({{.17,.16,.83,.16},{.17,.16,.17,.88},{.17,.88,.83,.88},{.83,.88,.83,.16},{.30,.68,.70,.68},{.30,.5,.70,.5},{.30,.32,.57,.32}})do line(unpack(v))end
 end
 return n
end
-- Home and preparation are views of the same harbor seen during the voyage.
-- These nodes are scenery only; they never fabricate ownership or write state.
function W.harborWorld(w,h,opts)
 opts=opts or {};local root=cc.Node:create();root:setContentSize(cc.size(w,h))
 local sea=W.cover(W.worldPath..'sea-turquoise-caustics.png',w,h)
 if sea then root:addChild(sea) end
 local harbor=W.sprite(W.worldPath..'harbor-clean-ne.png',w*.99,h*1.15)
 if harbor then harbor:setAnchorPoint(cc.p(0,.5));harbor:setPosition(cc.p(-w*.15,h*.51));root:addChild(harbor,1) end
 local boat
 if opts.boat~=false then
  boat=W.sprite(W.worldPath..'boat-clean-ne.png',w*.38,h*.57)
  if boat then boat:setPosition(cc.p(w*.68,h*.54));root:addChild(boat,2) end
 end
 return root,harbor,boat
end
function W.crewArt(index,w,h)
 local path=W.path..'crew.png'
 if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
 local full=cc.Sprite:create(path);local z=full:getContentSize();local cell=z.width/2
 local s=cc.Sprite:create(path,cc.rect((index-1)*cell,0,cell,z.height));s:setScale(math.min(w/cell,h/z.height));s:setAnchorPoint(cc.p(.5,0));return s
end
function W.button(text,w,h,callback,opts)
 opts=opts or {};local primary=opts.primary;local color=opts.color or (primary and W.colors.sea or W.colors.paper)
 local normal=W.panel(w,h,color,math.min(24,h/2));local dark=cc.c3b(math.max(0,color.r-22),math.max(0,color.g-22),math.max(0,color.b-22))
 local selected=W.panel(w,h,dark,math.min(24,h/2));local item=cc.MenuItemSprite:create(normal,selected)
 local txt=W.label(text,opts.size or 25,opts.textColor or (primary and W.colors.white or W.colors.ink),w/2,h/2,true,.5)
 W.fit(txt,w-(opts.icon and 62 or 24));item:addChild(txt,2)
 if opts.icon then local icon=W.icon(opts.icon,math.min(34,h*.6),primary and W.colors.white or W.colors.ink);icon:setPosition(cc.p(text=='' and (w-math.min(34,h*.6))/2 or 18,(h-math.min(34,h*.6))/2));item:addChild(icon,3);txt:setPositionX(w/2+16) end
 item:registerScriptTapHandler(function() if callback then callback() end end)
 local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setAnchorPoint(cc.p(.5,.5));n:setCascadeOpacityEnabled(true)
 item:setPosition(cc.p(w/2,h/2));local menu=cc.Menu:create(item);menu:setPosition(cc.p(0,0));n:addChild(menu);n.item=item;n.label=txt;n.menu=menu;return n
end
return W
