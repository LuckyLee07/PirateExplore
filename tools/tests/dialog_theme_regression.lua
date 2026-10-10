-- Native dialog geometry/action contract smoke test. Does not make purchases.
unpack=unpack or table.unpack
local root='bin/res/scripts/LuaClass/'
local Node={}
local dispatcher={}
local function node(kind) return setmetatable({kind=kind,children={},size={width=0,height=0},x=0,y=0,visible=true,scale=1},{__index=Node}) end
function Node:addChild(c,z) assert(c and not c.parent);self.children[#self.children+1]=c;c.parent=self;c.z=z or 0 end
function Node:removeFromParent() if self.parent then for i,c in ipairs(self.parent.children) do if c==self then table.remove(self.parent.children,i);break end end end;self.parent=nil end
function Node:getParent() return self.parent end
function Node:getChildren() return self.children end
function Node:setContentSize(s) self.size=s end
function Node:getContentSize() return self.size end
function Node:setPosition(x,y) if type(x)=='table' then self.x=x.x;self.y=x.y else self.x=x;self.y=y end end
function Node:getPosition() return self.x,self.y end
function Node:getPositionX() return self.x end
function Node:getPositionY() return self.y end
function Node:setPositionY(v) self.y=v end
function Node:setAnchorPoint(a) self.anchor=a end
function Node:getBoundingBox() return {x=self.x-self.size.width*self.anchor.x,y=self.y-self.size.height*self.anchor.y,width=self.size.width,height=self.size.height} end
function Node:setVisible(v) self.visible=v end
function Node:isVisible() return self.visible end
function Node:setScale(v) self.scale=v end
function Node:setColor(v) self.color=v end
function Node:setOpacity(v) self.opacity=v end
function Node:getOpacity() return self.opacity or 255 end
function Node:setFontName(v) self.font=v end
function Node:setFontSize(v) self.fontSize=v end
function Node:disableStroke() self.strokeDisabled=true end
function Node:setString(v) self.text=v end
function Node:getString() return self.text end
function Node:setTag(v) self.tag=v end
function Node:getTag() return self.tag end
function Node:setCascadeOpacityEnabled(v) self.cascade=v end
function Node:setLocalZOrder(v) self.z=v end
function Node:ignoreAnchorPointForPosition() end
function Node:drawPolygon() end
function Node:drawSegment() end
function Node:drawTriangle() end
function Node:getViewSize() return self.viewSize or self.size end
function Node:setContentOffset(v) self.offset=v end
function Node:stopAllActions() end
function Node:getEventDispatcher() return dispatcher end
function Node:registerScriptTapHandler(f) self.callback=f end
function Node:setNormalImage(n) self.normal=n end
function Node:setSelectedImage(n) self.selected=n end
function dispatcher:addEventListenerWithSceneGraphPriority(listener,owner) owner.touchListener=listener end
function class(_,factory)
    local c={}
    function c.new(...)
        local n=factory();setmetatable(n,{__index=function(_,k) return c[k] or Node[k] end})
        if c.ctor then c.ctor(n,...) end
        return n
    end
    return c
end
cc={p=function(x,y)return{x=x,y=y}end,size=function(w,h)return{width=w,height=h}end,
    rect=function(x,y,w,h)return{x=x,y=y,width=w,height=h}end,
    c3b=function(r,g,b)return{r=r,g=g,b=b}end,c4b=function(r,g,b,a)return{r=r,g=g,b=b,a=a}end,
    c4f=function(r,g,b,a)return{r=r,g=g,b=b,a=a}end,
    Handler={EVENT_TOUCH_BEGAN=1,EVENT_TOUCH_MOVED=2,EVENT_TOUCH_ENDED=3}}
for _,kind in ipairs({'Node','Layer','DrawNode'}) do local k=kind;cc[k]={create=function()return node(k)end} end
cc.LayerColor={create=function(_,c,w,h)local n=node('LayerColor');n.color=c;n.size=cc.size(w or 640,h or 1136);return n end}
cc.Sprite={create=function(_,path)
    local f=assert(io.open('bin/res/assets/'..path,'rb'));local h=f:read(24);f:close()
    local function u32(i)local a,b,c,d=h:byte(i,i+3);return ((a*256+b)*256+c)*256+d end
    local n=node('Sprite');n.size=cc.size(u32(17),u32(21));n.path=path;return n
end}
cc.LabelTTF={create=function(_,s,font,size)local n=node('LabelTTF');n.text=tostring(s);n.font=font;n.size=cc.size(#n.text*size*.4,size);return n end}
cc.MenuItemSprite={create=function(_,normal,selected,disabled)local n=node('MenuItemSprite');n.size=normal:getContentSize();n.normal=normal;n.selected=selected;n.disabled=disabled;n:addChild(normal);n:addChild(selected);return n end}
cc.Menu={create=function(_,...)local n=node('Menu');for _,c in ipairs({...})do n:addChild(c)end;return n end}
cc.EventListenerTouchOneByOne={create=function()return{handlers={},registerScriptHandler=function(self,f,id)self.handlers[id]=f end,setSwallowTouches=function(self,v)self.swallow=v end}end}
cc.FileUtils={getInstance=function()return{isFileExist=function()return false end}end}
local scene=node('Scene');local viewport=cc.size(640,1136)
cc.Director={getInstance=function()return{getWinSize=function()return viewport end,getVisibleSize=function()return viewport end,getRunningScene=function()return scene end}end}
ccui={TouchEventType={ended=2}}
BoldFont='test';cclog=function()end
require=function()return true end
dofile(root..'HomeTheme.lua');dofile(root..'MasterTheme.lua');dofile(root..'DialogTheme.lua')
dofile(root..'SDButton.lua');dofile(root..'AlertView.lua')
local function equal(a,b,why)assert(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function findLabel(n,text)
    if n.text==text then return n end
    for _,c in ipairs(n.children) do local found=findLabel(c,text);if found then return found end end
end
for box,expected in pairs({[0]={572,437},[1]={572,664},[2]={504,326},[3]={578,870}})do
    local a=AlertView:create(0,box,'Modal')
    equal(a.s_size.width,expected[1],'legacy modal width');equal(a.s_size.height,expected[2],'legacy modal height')
    equal(a.s_position.x,320);equal(a.s_position.y,568)
    equal(a.s_bg.anchor.x,.5);equal(a.s_bg.anchor.y,.5)
    equal(a.closeBtn:getContentSize().width,58,'close hit target')
    equal(a.closeBtn.clickArea.width,60,'expanded close area')
    equal(a.touchListener.swallow,true,'modal input swallowing')
    equal(a.closeBtn.touchListener.swallow,true,'SD close input')
    a.closeBtn:onSingleCLick();equal(a:getParent(),nil,'close removes modal')
end
local accepted,cancelled=0,0
local function modal(kind)return AlertView:create(kind,0,'Actions',function()accepted=accepted+1 end,function()cancelled=cancelled+1 end,'NO','YES')end
local a=modal(2)
findLabel(a,'YES').parent.callback();equal(accepted,1);equal(cancelled,0);equal(a:getParent(),nil)
a=modal(2);findLabel(a,'NO').parent.callback();equal(accepted,1);equal(cancelled,1);equal(a:getParent(),nil)
a=modal(2);a:setOkRemove(false);findLabel(a,'YES').parent.callback();equal(accepted,2);equal(a:getParent(),scene,'manual-close confirmation remains open')
a.closeBtn:onSingleCLick();equal(cancelled,2);equal(a:getParent(),nil)
-- A one-button Alert has always used the dismissal callback; preserve it.
a=modal(1);findLabel(a,'YES').parent.callback();equal(accepted,2);equal(cancelled,3)
local fired=0
local b=DialogTheme.sdButton('Images/btn/ann03_a.png','Images/btn/ann03_b.png',function()fired=fired+1 end)
equal(b:getContentSize().width,176);equal(b.normalSpr:getContentSize().width,176)
b:setActive(true);equal(b.normalSpr.visible,false);equal(b.selectSpr.visible,true)
b:setActive(false);equal(b.normalSpr.visible,true);equal(b.selectSpr.visible,false)
b:registerLongPressed(function()end);assert(b.onLongPressed,'long press API remains available')
b:onSingleCLick();equal(fired,1,'SD callback retained')
local purchases=0;purchase=function()purchases=purchases+1 end
for _,offer in ipairs({{bg='Images/charging/cz_01.png',diamond=120,money=6},{bg='Images/charging/cz_02.png',diamond=398,money=16},{bg='Images/charging/cz_03.png',diamond=888,money=30}})do
    local item=DialogTheme.chargeOffer(offer)
    equal(item:getContentSize().width,523);equal(item:getContentSize().height,165)
    assert(findLabel(item,tostring(offer.diamond)..' 钻石'),'real quantity is rendered')
    assert(findLabel(item,tostring(offer.money)..' 元'),'real price is rendered')
    assert(findLabel(item,'购 买'),'native purchase caption')
end
equal(purchases,0,'building charge cards never purchases')
local oldPrices={}
purchase=function(id)oldPrices[#oldPrices+1]=id end
-- Use the production availability guard while stubbing only the native bridge.
dofile('src/engine/cocos2d-x/cocos/scripting/lua-bindings/script/Cocos2dConstants.lua')
cc.Application={getInstance=function()return{getTargetPlatform=function()return cc.PLATFORM_OS_IPHONE end}end}
local availability=dofile(root..'PurchaseAvailability.lua')
local oldRequire=require
require=function(name)if name=='LuaClass/PurchaseAvailability'then return availability end;return oldRequire(name)end
dofile(root..'ChargeMode.lua')
local scroll=node('ScrollView');scroll.size=cc.size(578,730)
local charge={scrollView=scroll,scrollViewContainer=node('Layer')}
ChargeLayer.loadData(charge)
local offers=charge.scrollViewContainer.children[1].children
equal(#offers,3,'all configured charging offers remain available')
equal(#oldPrices,0,'initializing the actual charging list never buys')
offers[1].callback();offers[2].callback();offers[3].callback()
equal(table.concat(oldPrices,','),'2,3,1','actual offer handlers keep their original purchase IDs')
local view=node('BaseView')
view.titleHeight=67;view.titleBg=cc.Sprite:create('Images/UI/TitleBg.png')
view.titleBg:setPosition(cc.p(320,970));view:addChild(view.titleBg)
view.titleLabel=DialogTheme.label('Auxiliary',36);view.titleBg:addChild(view.titleLabel)
view.mainBg=node('Sprite');view:addChild(view.mainBg)
view.topLeftBtn=DialogTheme.menuItem('Images/btn/ann02_a.png','Images/btn/ann02_b.png')
view.topRightBtn=DialogTheme.menuItem('Images/btn/ann02_a.png','Images/btn/ann02_b.png')
view.topLeftBtnLabel=DialogTheme.label('Left',24);view.topRightBtnLabel=DialogTheme.label('Back',24)
local back=function()end;view.topRightBtn.callback=back
local dimensions=view.topRightBtn:getContentSize()
view.infoNode=node('Layer');view.infoNode.size=cc.size(610,230);view:addChild(view.infoNode)
view.setBtn=SDButton:create('Images/MainMenu/an_lianj_a.png','Images/MainMenu/an_lianj_b.png',function()end)
view.infoNode:addChild(view.setBtn,1)
view.setButtonProgrees=node('ProgressTimer');view.setBtn:addChild(view.setButtonProgrees)
view.leftBtn=DialogTheme.menuItem('Images/btn/ann03_a.png','Images/btn/ann03_b.png')
view.rightBtn=DialogTheme.menuItem('Images/btn/ann03_a.png','Images/btn/ann03_b.png')
view.leftBtn:setOpacity(51);view.rightBtn:setOpacity(255)
view.infoNode:addChild(cc.Menu:create(view.leftBtn,view.rightBtn),1)
for _,key in ipairs({'setBtnText','leftBtnText','rightBtnText'})do view[key]=DialogTheme.label('Legacy',24);view.infoNode:addChild(view[key],1)end
view.leftBtnText:setOpacity(51)
view.infoScrollView=node('ScrollView');view.infoNode:addChild(view.infoScrollView)
view.infoLabel=DialogTheme.label('Log',24);view.infoScrollView:addChild(view.infoLabel)
view.bottomInfoBox=node('Scale9Sprite');view.bottomInfoBox.size=cc.size(520,120);view.infoNode:addChild(view.bottomInfoBox)
view.infoBoxLabel=DialogTheme.label('Tooltip',24);view.bottomInfoBox:addChild(view.infoBoxLabel)
local alchemy=view.setBtn.onSingleCLick;local listener=view.setBtn.touchListener
DialogTheme.applyBase(view)
equal(view.titleBg:getPositionY(),970,'auxiliary title location')
equal(view.titleBg:getContentSize().height,67,'auxiliary title height')
equal(view.topRightBtn.callback,back,'auxiliary navigation callback stays on same object')
equal(view.topRightBtn:getContentSize(),dimensions,'auxiliary navigation geometry retained')
equal(view.mainBg.visible,false,'old backdrop covered')
equal(view.leftBtn:getOpacity(),51,'locked action opacity retained')
equal(view.leftBtnText:getOpacity(),51,'locked caption opacity retained')
equal(view.setBtn.onSingleCLick,alchemy,'alchemy callback retained')
equal(view.setBtn.touchListener,listener,'alchemy listener retained')
equal(view.setButtonProgrees.parent,view.setBtn,'progress timer retained')
equal(view.infoBoxLabel.parent,view.bottomInfoBox,'tooltip content retained')
equal(view.infoLabel.fontSize,22,'footer log uses the readable regular text treatment')
equal(view.infoLabel.strokeDisabled,true,'footer log removes legacy outline')
equal(#view.LeftBg.children,0,'title decoration placeholder has no metal artwork')
equal(view.setBtn:getContentSize().width,135,'smaller visual preserves the original alchemy hitbox')
local children=#view.children;DialogTheme.applyBase(view);equal(#view.children,children,'chrome applies once')
print('PASS dialog geometry, dismiss/confirm/cancel routes, manual close, SD state/long press and charge price rendering')
