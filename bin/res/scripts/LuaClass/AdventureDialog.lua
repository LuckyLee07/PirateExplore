-- A real modal: scene-owned, touch-swallowing, bounded to the current viewport.
local D={}
function D.show(title,body,options,owner)
    owner=owner or cc.Director:getInstance():getRunningScene()
    if owner.adventureDialog then return owner.adventureDialog end
    require 'LuaClass/DialogTheme'
    local size=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin()
    local scale=math.min(size.width/640,size.height/850);local w=590*scale
    local h=math.min(size.height-40*scale,(235+#options*77)*scale)
    local layer=cc.LayerColor:create(cc.c4b(3,20,29,205),size.width,size.height)
    layer.isAdventureModal=true;owner.adventureDialog=layer
    cc.Director:getInstance():getRunningScene():addChild(layer,3000)
    local panel=DialogTheme.panel(w,h);panel:setPosition(cc.p(origin.x+size.width/2,origin.y+size.height/2));layer:addChild(panel)
    local function label(text,font,y,color)
        local n=cc.LabelTTF:create(text,BoldFont,font*scale);n:setColor(color or MasterTheme.colors.paper)
        n:setDimensions(cc.size(w-44*scale,0));n:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        n:setPosition(cc.p(w/2,y));panel:addChild(n,5);return n
    end
    label(title,30,h-35*scale)
    local text=label(body,20,h-120*scale);text:setDimensions(cc.size(w-48*scale,130*scale))
    local function close()
        -- An action may already have replaced the scene (successful return).
        -- Its exit handler clears ownership; do not call a released node again.
        if owner.adventureDialog~=layer then return end
        owner.adventureDialog=nil
        layer:removeFromParent(true)
    end
    local items={}
    for i,o in ipairs(options) do
        local caption=o.label..(o.detail and ('\n'..o.detail) or '')
        local captionLabel=cc.LabelTTF:create(caption,BoldFont,(o.detail and 18 or 22)*scale)
        captionLabel:setDimensions(cc.size(w-40*scale,60*scale))
        captionLabel:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        local item=cc.MenuItemLabel:create(captionLabel)
        item:setPosition(cc.p(w/2,h-(222+(i-1)*77)*scale))
        item:setColor(o.disabled and cc.c3b(140,151,152) or MasterTheme.colors.paper)
        item:registerScriptTapHandler(function()
            if o.disabled then if ToastUtil then ToastUtil:toastString(o.reason or '条件尚未满足') end;return end
            if o.action then local result=o.action();if result==false then return end end
            close()
        end)
        items[#items+1]=item
    end
    local menu=cc.Menu:create(unpack(items));menu:setPosition(cc.p(0,0));panel:addChild(menu,10)
    local listener=cc.EventListenerTouchOneByOne:create();listener:setSwallowTouches(true)
    listener:registerScriptHandler(function()return true end,cc.Handler.EVENT_TOUCH_BEGAN)
    layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,layer)
    layer:registerScriptHandler(function(event)if event=='exit' then if owner.adventureDialog==layer then owner.adventureDialog=nil end end end)
    return layer
end
return D
