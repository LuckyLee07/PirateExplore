-- Components used by the user-approved full-scene harbor and its route groups.
-- Text and interaction remain native; only unlettered paint/materials are images.
require 'LuaClass/HomeTheme'
MasterTheme={}
local M=MasterTheme
M.colors={ink=cc.c3b(8,53,68),sea=cc.c3b(50,188,204),paper=cc.c3b(246,235,207),
    coral=cc.c3b(230,104,72),white=cc.c3b(255,248,224),muted=cc.c3b(74,101,105)}
M.path='Images/UI/Adventure/Master/'
function M.headingFont(strong)
    if cc.Application and cc.Application.getInstance then
        local platform=cc.Application:getInstance():getTargetPlatform()
        if platform==cc.PLATFORM_OS_LINUX then
            if strong and cc.FileUtils:getInstance():isFileExist('fonts/HarborSerif-Bold.ttf') then return 'fonts/HarborSerif-Bold.ttf' end
            return 'Noto Serif CJK SC'
        end
        if platform==cc.PLATFORM_OS_MAC or platform==cc.PLATFORM_OS_IPHONE or platform==cc.PLATFORM_OS_IPAD then return 'Songti SC' end
    end
    return BoldFont
end
function M.label(text,size,color,x,y,bold,anchorX)
    local n=HomeTheme.label(text,size,color or M.colors.ink,x,y,false,anchorX)
    if bold then n:setFontName(M.headingFont(bold==true)) end
    return n
end
function M.cover(path,w,h) return HomeTheme.cover(path,w,h) end
function M.fit(label,width)
    local z=label:getContentSize().width;label:setScale(z>width and width/z or 1);return label
end
function M.material(name,w,h,color)
    local rects={['ink-brush.png']={27,244,630,364},['coral-brush.png']={667,356,565,169},
        ['crew-paper.png']={23,787,688,300},['currency-paper.png']={756,867,474,127}}
    local path=M.path..name;local rect=rects[name]
    if name=='coral-brush.png' and cc.FileUtils:getInstance():isFileExist(M.path..'Polish/coral-action.png') then
        path=M.path..'Polish/coral-action.png';rect=nil
    end
    if rect then path=M.path..'materials.png' end
    if cc.FileUtils:getInstance():isFileExist(path) then
        local s=rect and cc.Sprite:create(path,cc.rect(unpack(rect))) or cc.Sprite:create(path)
        local z=s and s:getContentSize()
        if z and z.width>0 and z.height>0 then
        s:setScaleX(w/z.width);s:setScaleY(h/z.height);s:setAnchorPoint(cc.p(0,0))
        if name=='coral-brush.png' and cc.ClippingNode then
            -- Use the generated brush only as an edge stencil. The action's
            -- interior stays a quiet native coral field behind real lettering.
            local clip=cc.ClippingNode:create();clip:setContentSize(cc.size(w,h))
            clip:setStencil(s);clip:setAlphaThreshold(.5)
            local base=cc.c3b(235,94,62)
            if color then base=cc.c3b(base.r*color.r/255,base.g*color.g/255,base.b*color.b/255) end
            clip:addChild(cc.LayerColor:create(cc.c4b(base.r,base.g,base.b,255),w,h));return clip
        end
        if color then s:setColor(color) end
        local n=cc.Node:create();n:setContentSize(cc.size(w,h));n:addChild(s);return n
        end
    end
    local fallback=(name=='coral-brush.png') and M.colors.coral or ((name=='ink-brush.png') and M.colors.ink or M.colors.paper)
    if name=='Polish/roster-blue.png' then fallback=cc.c3b(117,168,195) end
    return HomeTheme.rounded(w,h,color or fallback,5)
end
function M.button(text,w,h,callback,opts)
    opts=opts or {};local material=opts.material or 'ink-brush.png'
    local normal=M.material(material,w,h);local selected=M.material(material,w,h,cc.c3b(210,216,207))
    local item=cc.MenuItemSprite:create(normal,selected)
    local label=M.label(text,opts.fontSize or 27,opts.textColor or M.colors.white,w/2,h/2,opts.bold,0.5)
    item:addChild(label,5);item:registerScriptTapHandler(callback)
    local node=cc.Node:create();node:setContentSize(cc.size(w,h));node:setAnchorPoint(cc.p(.5,.5))
    item:setPosition(cc.p(w/2,h/2));local menu=cc.Menu:create(item);menu:setPosition(cc.p(0,0));node:addChild(menu)
    node.item=item;node.label=label;node.menu=menu;return node
end
function M.icon(kind,size,color)
    local n=cc.Node:create();n:setContentSize(cc.size(size,size));local d=cc.DrawNode:create();n:addChild(d)
    local c=HomeTheme.rgba(color or M.colors.paper);local function p(x,y)return cc.p(x*size,y*size)end
    local function poly(points)local a={} for _,v in ipairs(points) do a[#a+1]=p(v[1],v[2]) end;d:drawPolygon(a,#a,c,0,c)end
    local function line(x,y,a,b,w)d:drawSegment(p(x,y),p(a,b),(w or .026)*size,c)end
    if kind=='sail' or kind=='ship' then
        -- Unequal wind-filled sails, drawn as quiet broad shapes rather than
        -- two symmetric triangles. Sampled curvature stays resolution-free.
        poly({{.47,.88},{.42,.71},{.34,.53},{.23,.36},{.13,.28},{.28,.31},{.47,.31}})
        poly({{.55,.94},{.65,.83},{.73,.68},{.77,.51},{.78,.36},{.73,.28},{.64,.3},{.55,.31}})
        line(.52,.97,.52,.21,.015);poly({{.08,.22},{.92,.25},{.73,.09},{.24,.08}})
        line(.16,.025,.76,.025,.012)
        local dark=HomeTheme.rgba(M.colors.ink)
        d:drawSegment(p(.24,.17),p(.75,.18),.008*size,dark)
    elseif kind=='crew' then
        for _,v in ipairs({{.24,.72,.105},{.76,.72,.105},{.50,.82,.12}}) do d:drawDot(p(v[1],v[2]),v[3]*size,c) end
        poly({{.04,.13},{.09,.47},{.24,.54},{.35,.49},{.39,.1}})
        poly({{.64,.1},{.65,.49},{.78,.54},{.91,.47},{.97,.13}})
        poly({{.31,.06},{.35,.54},{.5,.64},{.65,.54},{.7,.06}})
    elseif kind=='port' then
        poly({{.05,.7},{.48,.98},{.89,.7}});poly({{.13,.06},{.13,.67},{.29,.67},{.29,.06}});poly({{.64,.06},{.64,.67},{.8,.67},{.8,.06}});poly({{.13,.56},{.8,.56},{.8,.67},{.13,.67}})
        line(.03,.03,.96,.03,.025)
        local dark=HomeTheme.rgba(M.colors.ink)
        d:drawDot(p(.48,.79),size*.045,dark)
        poly({{.68,.06},{.98,.06},{.98,.39},{.68,.39}})
        d:drawSegment(p(.71,.1),p(.95,.36),.018*size,dark)
        d:drawSegment(p(.71,.36),p(.95,.1),.013*size,dark)
        line(.05,.2,.05,.46,.025);line(.01,.48,.11,.48,.025)
    elseif kind=='anchor' then
        d:drawDot(p(.5,.84),size*.115,c);d:drawDot(p(.5,.84),size*.052,HomeTheme.rgba(M.colors.ink))
        line(.5,.76,.5,.18,.04);line(.23,.6,.77,.6,.032)
        local left={{.15,.32},{.18,.24},{.23,.18},{.31,.13},{.40,.1},{.5,.085}}
        for i=1,#left-1 do
            local a,b=left[i],left[i+1]
            line(a[1],a[2],b[1],b[2],.037);line(1-a[1],a[2],1-b[1],b[2],.037)
        end
        poly({{.06,.39},{.3,.33},{.16,.15}});poly({{.94,.39},{.7,.33},{.84,.15}})
    elseif kind=='key' then
        d:drawDot(p(.73,.78),size*.16,c);d:drawDot(p(.73,.78),size*.085,HomeTheme.rgba(M.colors.ink))
        line(.64,.66,.19,.16,.045);line(.29,.26,.39,.15,.04);line(.4,.39,.49,.29,.04)
    elseif kind=='food' then
        poly({{.23,.1},{.15,.37},{.15,.65},{.24,.87},{.76,.87},{.85,.65},{.85,.37},{.77,.1}})
        local dark=HomeTheme.rgba(M.colors.ink)
        d:drawSegment(p(.18,.64),p(.82,.64),.032*size,dark);d:drawSegment(p(.2,.34),p(.8,.34),.032*size,dark)
        d:drawSegment(p(.41,.17),p(.41,.8),.013*size,dark);d:drawSegment(p(.61,.17),p(.61,.8),.013*size,dark)
        d:drawSegment(p(.28,.8),p(.71,.8),.032*size,dark)
        d:drawDot(p(.28,.65),size*.018,dark);d:drawDot(p(.72,.65),size*.018,dark)
    end
    return n
end
function M.portraitBrush(w,h)
    if cc.FileUtils:getInstance():isFileExist(M.path..'Polish/roster-blue.png') then
        return M.material('Polish/roster-blue.png',w,h)
    end
    -- Reuse the ink brush's irregular alpha as a stencil for a pale-blue wash.
    -- No lettering/characters are embedded in this native material treatment.
    if cc.ClippingNode then
        local clip=cc.ClippingNode:create();clip:setContentSize(cc.size(w,h))
        clip:setStencil(M.material('ink-brush.png',w,h));clip:setAlphaThreshold(.08)
        local fill=cc.LayerColor:create(cc.c4b(109,162,185,185),w,h);clip:addChild(fill)
        return clip
    end
    return HomeTheme.rounded(w,h,cc.c3b(151,187,198),4)
end
function M.portrait(id,w,h)
    local cells={['107']={37,70,663,587},['102']={764,87,666,570},['124']={1488,70,647,587}}
    local r=cells[tostring(id)];local path=M.path..'crew-trio.png'
    if not r or not cc.FileUtils:getInstance():isFileExist(path) then return nil end
    local n=cc.Node:create();n:setContentSize(cc.size(w,h))
    local s=cc.Sprite:create(path,cc.rect(unpack(r)));local z=s:getContentSize()
    s:setScale(math.min(w/z.width,h/z.height));s:setAnchorPoint(cc.p(.5,0));s:setPosition(cc.p(w/2,0));n:addChild(s)
    return n
end
function M.silhouette(w,h,locked)
    if not locked then return HomeTheme.silhouette(w,h) end
    local n=HomeTheme.rounded(w,h,cc.c3b(237,231,211),4)
    local d=cc.DrawNode:create();local c=HomeTheme.rgba(cc.c3b(188,194,177))
    d:drawDot(cc.p(w/2,h*.66),w*.15,c)
    local p={cc.p(w*.18,h*.15),cc.p(w*.23,h*.39),cc.p(w*.4,h*.49),cc.p(w*.6,h*.49),cc.p(w*.77,h*.39),cc.p(w*.82,h*.15)}
    d:drawPolygon(p,#p,c,0,c);n:addChild(d);return n
end
return M
