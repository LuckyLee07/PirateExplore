-- Warm Q v1 native presentation; no economy, save, map or combat state writes.
require 'LuaClass/MasterTheme'
local W={path='Images/UI/Warm/'}
WarmTheme=W
function W.enabled() return rawget(_G,'WARM_PIRATE_V1')~=false end
W.colors={ink=cc.c3b(83,49,37),paper=cc.c3b(255,245,228),coral=cc.c3b(255,108,86),
 sea=cc.c3b(39,143,157),muted=cc.c3b(137,106,82),line=cc.c3b(226,202,170),white=cc.c3b(255,252,241),gold=cc.c3b(236,176,60)}
local function rgba(c,a)return cc.c4f(c.r/255,c.g/255,c.b/255,a or 1) end
function W.label(text,size,color,x,y,bold,anchorX)
 local n=cc.LabelTTF:create(tostring(text or ''),MasterTheme.headingFont(bold==true),size or 24)
 n:setColor(color or W.colors.ink);n:setAnchorPoint(cc.p(anchorX or 0,.5));n:setPosition(cc.p(x or 0,y or 0));return n
end
function W.fit(n,width)
 local s=n:getContentSize().width;n:setScale(s>width and width/s or 1);return n
end
function W.panel(w,h,color,radius)
 local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setCascadeOpacityEnabled(true)
 local d=cc.DrawNode:create();local pts={};local r=math.min(radius or 18,w/2,h/2)
 for _,a in ipairs({{w-r,h-r,0},{r,h-r,90},{r,r,180},{w-r,r,270}}) do
  for i=0,8 do local ang=math.rad(a[3]+i*11.25);pts[#pts+1]=cc.p(a[1]+r*math.cos(ang),a[2]+r*math.sin(ang)) end
 end
 d:drawPolygon(pts,#pts,rgba(color or W.colors.paper),.65,rgba(W.colors.line));n:addChild(d);return n
end
function W.sprite(path,w,h)
 if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
 local s=cc.Sprite:create(path);if not s then return nil end
 local z=s:getContentSize();s:setScale(math.min(w/z.width,h/z.height));s:setAnchorPoint(cc.p(.5,.5));return s
end
function W.cover(path,w,h) return MasterTheme.cover(path,w,h) end
function W.icon(name,size)
 local icons={sail=1,map=2,crew=3,hammer=4,chest=5,log=6,settings=7,bag=8,back=9}
 local path=W.path..'icons.png';local index=icons[name]
 if index and cc.FileUtils:getInstance():isFileExist(path) then
  local full=cc.Sprite:create(path);local z=full:getContentSize();local cw,ch=z.width/3,z.height/3
  local col=(index-1)%3;local row=math.floor((index-1)/3)
  local boxes={{124,132,388,395},{75,129,367,400},{50,114,323,413},{109,93,374,356},{81,111,366,360},{70,96,332,357},{114,89,354,324},{93,67,362,323},{67,90,324,318}}
  local b=boxes[index];local x,y,bw,bh=b[1]-4,b[2]-4,b[3]-b[1]+9,b[4]-b[2]+9
  local s=cc.Sprite:create(path,cc.rect(col*cw+x,row*ch+y,bw,bh));s:setScale(math.min(size/bw,size/bh));s:setAnchorPoint(cc.p(.5,.5));s:setPosition(cc.p(size/2,size/2))
  local n=cc.Node:create();n:setContentSize(cc.size(size,size));n:addChild(s);return n
 end
 local alias={hammer='build',chest='cargo',settings='wheel',log='port',bag='cargo',map='sail',back='sail'}
 return MasterTheme.icon(alias[name] or name,size,W.colors.ink)
end
function W.crewArt(index,w,h)
 local path=W.path..'crew.png'
 if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
 local full=cc.Sprite:create(path);local z=full:getContentSize();local cell=z.width/2
 local s=cc.Sprite:create(path,cc.rect((index-1)*cell,0,cell,z.height));s:setScale(math.min(w/cell,h/z.height));s:setAnchorPoint(cc.p(.5,0));return s
end
function W.button(text,w,h,callback,opts)
 opts=opts or {};local primary=opts.primary;local color=opts.color or (primary and W.colors.coral or W.colors.paper)
 local normal=W.panel(w,h,color,math.min(24,h/2));local dark=cc.c3b(math.max(0,color.r-22),math.max(0,color.g-22),math.max(0,color.b-22))
 local selected=W.panel(w,h,dark,math.min(24,h/2));local item=cc.MenuItemSprite:create(normal,selected)
 local txt=W.label(text,opts.size or 25,opts.textColor or (primary and W.colors.white or W.colors.ink),w/2,h/2,true,.5)
 W.fit(txt,w-(opts.icon and 62 or 24));item:addChild(txt,2)
 if opts.icon then local icon=W.icon(opts.icon,math.min(34,h*.6));icon:setPosition(cc.p(18,(h-math.min(34,h*.6))/2));item:addChild(icon,3);txt:setPositionX(w/2+16) end
 item:registerScriptTapHandler(function() if callback then callback() end end)
 local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:setAnchorPoint(cc.p(.5,.5));n:setCascadeOpacityEnabled(true)
 item:setPosition(cc.p(w/2,h/2));local menu=cc.Menu:create(item);menu:setPosition(cc.p(0,0));n:addChild(menu);n.item=item;n.label=txt;n.menu=menu;return n
end
return W
