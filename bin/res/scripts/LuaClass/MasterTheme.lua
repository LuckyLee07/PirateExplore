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
    -- Selected generated silhouettes use separate padded textures, avoiding
    -- atlas UV bleed. White-RGB alpha masks retain the caller's exact tint.
    -- The existing native geometry below remains the missing/failed-art fallback.
    local refined={port='port',food='barrel'}
    local path=refined[kind] and (M.path..'Icons/'..refined[kind]..'.png')
    if path and cc.FileUtils:getInstance():isFileExist(path) then
        local art=cc.Sprite:create(path)
        local z=art and art:getContentSize()
        if z and z.width>0 and z.height>0 then
            local n=cc.Node:create();n:setContentSize(cc.size(size,size))
            art:setScale(math.min(size/z.width,size/z.height))
            art:setAnchorPoint(cc.p(.5,.5));art:setPosition(cc.p(size/2,size/2))
            art:setColor(color or M.colors.paper)
            local texture=art.getTexture and art:getTexture()
            if texture and texture.setTexParameters then
                texture:setTexParameters(9729,9729,33071,33071)
            end
            n:addChild(art);return n
        end
    end
    local n=cc.Node:create();n:setContentSize(cc.size(size,size));local d=cc.DrawNode:create();n:addChild(d)
    local c=HomeTheme.rgba(color or M.colors.paper);local function p(x,y)return cc.p(x*size,y*size)end
    local function triangle(a,b,e)d:drawTriangle(p(a[1],a[2]),p(b[1],b[2]),p(e[1],e[2]),c)end
    local function cross(a,b,e)return (b[1]-a[1])*(e[2]-a[2])-(b[2]-a[2])*(e[1]-a[1])end
    -- Curved silhouettes can be concave. Native triangles preserve openings
    -- and avoid DrawNode polygon-edge miters on the narrow curve samples.
    local function poly(points)
        local v={};local area=0
        for i,a in ipairs(points) do local b=points[i%#points+1];area=area+a[1]*b[2]-b[1]*a[2] end
        for i=1,#points do v[i]=points[area>0 and i or #points-i+1] end
        while #v>3 do
            local cut=false
            for i=1,#v do
                local a,b,e=v[(i-2)%#v+1],v[i],v[i%#v+1]
                if cross(a,b,e)>1e-10 then
                    local clear=true
                    for j,q in ipairs(v) do
                        if j~=i and j~=(i-2)%#v+1 and j~=i%#v+1
                            and cross(a,b,q)>=-1e-10 and cross(b,e,q)>=-1e-10 and cross(e,a,q)>=-1e-10 then clear=false;break end
                    end
                    if clear then triangle(a,b,e);table.remove(v,i);cut=true;break end
                end
            end
            if not cut then return end
        end
        if #v==3 then triangle(v[1],v[2],v[3]) end
    end
    local function line(x,y,a,b,w)d:drawSegment(p(x,y),p(a,b),(w or .026)*size,c)end
    local function curve(a,x1,y1,x2,y2,x3,y3)
        local q=a[#a];local x,y=q[1],q[2]
        for i=1,10 do local t=i/10;local u=1-t
            a[#a+1]={u*u*u*x+3*u*u*t*x1+3*u*t*t*x2+t*t*t*x3,u*u*u*y+3*u*u*t*y1+3*u*t*t*y2+t*t*t*y3}
        end
    end
    local function ellipse(x,y,rx,ry)
        local a={};for i=0,23 do local t=i*math.pi/12;a[#a+1]={x+rx*math.cos(t),y+ry*math.sin(t)} end;poly(a)
    end
    local function ring(x,y,rx,ry,w)
        -- The opening stays genuinely transparent, including on pale paper.
        for i=0,31 do local a=i*math.pi/16;local b=(i+1)*math.pi/16
            poly({{x+rx*math.cos(a),y+ry*math.sin(a)},{x+rx*math.cos(b),y+ry*math.sin(b)},
                {x+(rx-w)*math.cos(b),y+(ry-w)*math.sin(b)},{x+(rx-w)*math.cos(a),y+(ry-w)*math.sin(a)}})
        end
    end
    if kind=='sail' or kind=='ship' then
        local a={{.467,.847}}
        curve(a,.385,.665,.231,.423,.103,.294);curve(a,.235,.343,.361,.332,.451,.288)
        curve(a,.448,.482,.460,.695,.467,.847);table.remove(a);poly(a)
        a={{.554,.926}}
        curve(a,.726,.772,.823,.540,.795,.350);curve(a,.720,.360,.644,.333,.562,.291)
        curve(a,.579,.496,.573,.761,.554,.926);table.remove(a);poly(a)
        line(.512,.965,.512,.222,.013)
        a={{.065,.225}};curve(a,.291,.180,.684,.186,.927,.265)
        a[#a+1]={.759,.111};curve(a,.609,.077,.365,.081,.214,.120);poly(a)
        a={{.222,.049}};curve(a,.390,.030,.603,.032,.760,.054)
        for i=1,#a-1 do line(a[i][1],a[i][2],a[i+1][1],a[i+1][2],.011) end
    elseif kind=='crew' then
        ellipse(.205,.676,.099,.120);ellipse(.795,.676,.099,.120);ellipse(.5,.802,.121,.143)
        local a={{.033,.117},{.049,.328}}
        curve(a,.054,.424,.124,.493,.218,.483);curve(a,.245,.481,.271,.470,.287,.451)
        curve(a,.266,.397,.255,.282,.251,.106);curve(a,.173,.100,.095,.103,.033,.117)
        table.remove(a);poly(a)
        local right={};for _,q in ipairs(a) do right[#right+1]={1-q[1],q[2]} end;poly(right)
        a={{.294,.063},{.309,.326}}
        curve(a,.315,.455,.391,.564,.5,.565);curve(a,.609,.564,.685,.455,.691,.326)
        a[#a+1]={.706,.063};curve(a,.584,.039,.416,.039,.294,.063);table.remove(a);poly(a)
    elseif kind=='port' then
        -- Four roof pieces leave a small diamond window, without a painted hole.
        poly({{.292,.856},{.478,.980},{.654,.856}})
        poly({{.175,.778},{.292,.856},{.478,.856},{.441,.817},{.478,.778}})
        poly({{.478,.856},{.654,.856},{.768,.778},{.478,.778},{.515,.817}})
        poly({{.058,.700},{.175,.778},{.768,.778},{.880,.700}})
        local a={{.143,.683},{.804,.683},{.804,.545},{.650,.545}}
        curve(a,.649,.605,.588,.644,.474,.645);curve(a,.361,.644,.300,.605,.299,.545)
        a[#a+1]={.143,.545};poly(a)
        for _,b in ipairs({{.143,.299,.094,.248},{.143,.299,.273,.431},{.143,.299,.456,.559},
            {.650,.804,.406,.431},{.650,.804,.456,.559},{.650,.678,.094,.381}}) do
            poly({{b[1],b[3]},{b[2],b[3]},{b[2],b[4]},{b[1],b[4]}})
        end
        line(.034,.049,.972,.049,.021);line(.055,.145,.055,.414,.023);line(.021,.432,.103,.432,.020)
        -- Broad crate faces are divided by a clean, open X brace.
        poly({{.703,.083},{.703,.343},{.808,.213}});poly({{.956,.083},{.956,.343},{.850,.213}})
        poly({{.724,.365},{.935,.365},{.829,.239}});poly({{.724,.062},{.935,.062},{.829,.187}})
        line(.686,.064,.976,.064,.014);line(.686,.381,.976,.381,.014)
        line(.686,.064,.686,.381,.014);line(.976,.064,.976,.381,.014)
    elseif kind=='anchor' then
        ring(.5,.837,.104,.114,.035);line(.5,.741,.5,.137,.040)
        local a={{.228,.610}};curve(a,.368,.624,.632,.624,.772,.610)
        for i=1,#a-1 do line(a[i][1],a[i][2],a[i+1][1],a[i+1][2],.033) end
        line(.219,.610,.232,.641,.027);line(.781,.610,.768,.641,.027)
        a={{.127,.372}};curve(a,.158,.253,.316,.163,.5,.154)
        curve(a,.684,.163,.842,.253,.873,.372);a[#a+1]={.925,.309}
        curve(a,.877,.159,.676,.063,.5,.052);curve(a,.324,.063,.123,.159,.075,.309);poly(a)
        poly({{.056,.411},{.279,.326},{.106,.211}});poly({{.944,.411},{.721,.326},{.894,.211}})
    elseif kind=='key' then
        ring(.735,.803,.161,.164,.065)
        line(.626,.681,.187,.172,.050)
        line(.292,.288,.398,.185,.047);line(.406,.418,.505,.318,.047)
    elseif kind=='food' then
        -- One oval opening joins a broad barrel body. Only two narrow hoop
        -- grooves and two short stave seams interrupt the cream silhouette.
        ring(.5,.823,.288,.114,.052)
        local a={{.212,.823},{.264,.823}}
        curve(a,.264,.789,.370,.761,.5,.761);curve(a,.630,.761,.736,.789,.736,.823)
        a[#a+1]={.788,.823};curve(a,.806,.770,.817,.710,.818,.662)
        curve(a,.650,.612,.350,.612,.182,.662);curve(a,.183,.710,.194,.770,.212,.823)
        table.remove(a);poly(a)
        a={{.173,.635}};curve(a,.230,.616,.306,.599,.385,.591)
        a[#a+1]={.385,.305};curve(a,.302,.319,.229,.338,.175,.356)
        curve(a,.151,.449,.150,.548,.173,.635);table.remove(a);poly(a)
        local right={};for _,q in ipairs(a) do right[#right+1]={1-q[1],q[2]} end;poly(right)
        a={{.411,.586}};curve(a,.470,.579,.530,.579,.589,.586)
        a[#a+1]={.589,.298};curve(a,.530,.289,.470,.289,.411,.298);poly(a)
        a={{.190,.325}};curve(a,.350,.240,.650,.240,.810,.325)
        curve(a,.801,.270,.789,.210,.765,.170);curve(a,.630,.099,.370,.099,.235,.170)
        curve(a,.211,.210,.199,.270,.190,.325);table.remove(a);poly(a)
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
    -- The starter crew and sailor already have identity-matched portraits in
    -- loadout/combat. Reuse those exact assets, keeping empty slots neutral.
    local singles={['100']='Images/Icon/B/crew-100.png',['101']='Images/Icon/B/crew-101.png'}
    local r=cells[tostring(id)];local path=singles[tostring(id)] or (r and M.path..'crew-trio.png')
    if not path then return nil end
    local s
    -- Only large100/101 portraits load the new masters. Lists/combat keep their
    -- existing64px identity-matched icons and memory footprint. A failed large
    -- asset falls back to the original small portrait, never another profession.
    if singles[tostring(id)] and (w>64 or h>64) then
        local high=M.path..'Portraits/crew-'..tostring(id)..'.png'
        if cc.FileUtils:getInstance():isFileExist(high) then
            s=cc.Sprite:create(high)
            local z=s and s:getContentSize()
            if not z or z.width<=0 or z.height<=0 then s=nil end
        end
    end
    if not s then
        if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
        if r then s=cc.Sprite:create(path,cc.rect(unpack(r))) else s=cc.Sprite:create(path) end
    end
    if not s then return nil end
    local z=s:getContentSize();if z.width<=0 or z.height<=0 then return nil end
    local texture=s.getTexture and s:getTexture()
    if texture and texture.setTexParameters then texture:setTexParameters(9729,9729,33071,33071) end
    local n=cc.Node:create();n:setContentSize(cc.size(w,h))
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
