-- Execute the production composition block, not a copied layout algorithm.
local f=assert(io.open('bin/res/scripts/LuaClass/TrainMode.lua','rb'))
local source=f:read('*a');f:close()
local first=assert(source:find('local menuIcon = cc.Menu:create(_cannelButton,_sureButton)',1,true))
local last=assert(source:find('\n    elseif Type == 2 then',first,true))
local function node(text)
    return {text=text,setPosition=function(self,x,y)self.x,self.y=x,y end,
        setColor=function(self,color)self.color=color end}
end
cc={Menu={create=function(_,a,b)local n=node();n.buttons={a,b};return n end},
    LabelTTF={create=function(_,text)return node(text)end},
    c3b=function(r,g,b)return {r=r,g=g,b=b}end}
ManagementTheme={bodyFont=function()return 'fixture-font'end}
local parent={children={}}
function parent:addChild(child,z)
    child.z=z or 0;child.order=#self.children+1
    self.children[child.order]=child
end
local cancel={getPosition=function()return 100,50 end}
local confirm={getPosition=function()return 360,50 end}
local compose=assert(loadstring('return function(self,_cannelButton,_sureButton)\n'..
    source:sub(first,last-1)..'\nend','@production-material-captions'))()
compose(parent,cancel,confirm)
local menu=parent.children[1]
assert(menu.buttons[1]==cancel and menu.buttons[2]==confirm,'original button identity')
assert(#parent.children==3,'one menu and both labels')
for index,text in ipairs({'合 成','取 消'}) do
    local label=parent.children[index+1]
    assert(label.text==text,'original caption retained')
    assert(label.z>=menu.z and label.order>menu.order,text..' hidden behind opaque menu face')
    assert(label.y==50,'vertical position retained')
end
assert(parent.children[2].x==360 and parent.children[3].x==100,'button centers retained')
print('PASS production material dialog captions render above both opaque button faces without changing button identity or centers')
