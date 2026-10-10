-- Execute the actual production constructor, failure and give-up methods.
-- Mock nodes only observe presentation; any economy mutation fails this test.
local f=assert(io.open('bin/res/scripts/LuaClass/FightMode.lua','r'))
local source=f:read('*a');f:close()
local function method(name,nextName)
    local start=assert(source:find('function FightBoxView:'..name..'(',1,true))
    local finish=assert(source:find('function FightBoxView:'..nextName..'(',start+1,true))
    assert(loadstring(source:sub(start,finish-1)))()
end
local N={}
local function node()return setmetatable({visible=true,children={},size={width=572,height=664},x=0,y=0},{__index=N})end
function N:addChild(n)table.insert(self.children,n)end
function N:setVisible(v)self.visible=v end
function N:getContentSize()return self.size end
function N:setPreferredSize(v)self.size=v end
function N:setPosition(x,y)if type(x)=='table'then self.x=x.x;self.y=x.y else self.x=x;self.y=y end end
function N:getPosition()return self.x,self.y end
function N:getPositionX()return self.x end
function N:getPositionY()return self.y end
function N:setAnchorPoint()end
function N:setScale()end
function N:setTag(v)self.tag=v end
function N:setString(v)self.text=v end
function N:registerScriptTapHandler(f)self.callback=f end
function N:setTapEventListener(f)self.tap=f end
cc={p=function(x,y)return{x=x,y=y}end,size=function(w,h)return{width=w,height=h}end}
for _,kind in ipairs({'Node','Sprite','Scale9Sprite','Menu'})do cc[kind]={create=function()return node()end}end
cc.Director={getInstance=function()return{getVisibleSize=function()return{width=640,height=1136}end}end}
cc.UserDefault={getInstance=function()return{getBoolForKey=function()return false end}end}
DialogTheme={panelFromLegacy=node,menuItem=node}
CombatTheme={label=function(text)local n=node();n.text=text;return n end}
csvOfFightBoxes='boxes';roleDiamond='diamond';fdm={mapID=1};BoldFont='test'
local diamonds=998
local dm={getCSVByID=function()return{['1']={propShow={}}}end,getRoleData=function()return diamonds end,
    addDiamond=function()error('visibility change must not charge or reward')end,
    setRoleData=function()error('visibility change must not mutate saved state')end}
DataManager={getInstance=function()return dm end}
function clone(value)local copy={};for k,v in pairs(value)do copy[k]=v end;return copy end
FightBoxView={BoxState={close=1,open=2,show=3},FailDiamond={2,4,8}}
function FightBoxView:hideInfo()self.showInfoNode:setVisible(false)end
function FightBoxView:reloadBoxes()self.reloads=(self.reloads or 0)+1 end
method('init','reloadBoxes');method('openBox','giveUpCallback');method('giveUpCallback','useDiamondCallback')
local function fresh()
    local view=node();setmetatable(view,{__index=function(_,k)return FightBoxView[k]or N[k]end})
    assert(view:init());return view
end
local view=fresh()
assert(view.freeInfoNode.visible and not view.costInfoNode.visible)
assert(not view.isUserGiveUp and not view.closeBtn.visible and not view.giveupBtn.visible)
local originalRandom=math.random;math.random=function(_,maximum)return maximum end
view:openBox(1)
assert(view.isFail and view.failTime==1 and not view.freeInfoNode.visible and view.costInfoNode.visible)
assert(view.infoCost.text:find('花费2',1,true)and view.giveupBtn.visible and not view.closeBtn.visible)
local props,rates,rewardTime=view.props,view.rewardRate,view.rewardTime
view:giveUpCallback()
assert(view.isUserGiveUp and not view.freeInfoNode.visible and not view.costInfoNode.visible)
assert(view.closeBtn.visible and view.closeLabel.visible and not view.giveupBtn.visible and not view.giveupLabel.visible)
assert(view.props==props and view.rewardRate==rates and view.rewardTime==rewardTime and diamonds==998)
local nextView=fresh()
assert(nextView.freeInfoNode.visible and not nextView.costInfoNode.visible and not nextView.isUserGiveUp)
nextView:openBox(1)
assert(not nextView.freeInfoNode.visible and nextView.costInfoNode.visible)
assert(nextView.infoCost.text:find('花费2',1,true)and nextView.giveupBtn.visible)
nextView:giveUpCallback()
assert(not nextView.costInfoNode.visible and not nextView.freeInfoNode.visible and nextView.closeBtn.visible)
math.random=originalRandom
print('PASS actual fresh chest/init, original 2-diamond failure text, give-up hides free/paid offers, new chest restores initial text, reward/cost state untouched')
