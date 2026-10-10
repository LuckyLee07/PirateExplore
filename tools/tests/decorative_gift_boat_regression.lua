-- Executes the exact production decoration/timer block with strict node mocks.
-- Fixed Port offer lifecycle is covered by home_master_regression.lua.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local home=read('tools/tests/home_master_regression.lua');local stop=assert(home:find("\ndofile(root..'Header.lua')",1,true))
local H=assert(loadstring(home:sub(1,stop-1)..'\nreturn {node=node,dispatcher=dispatcher}','@boat-node-fixture'))()
local source=read('bin/res/scripts/LuaClass/MainMenu.lua');local a=assert(source:find('    -- Decorative only:',1,true));local b=assert(source:find('    -- 刷新跟新手引导解锁有关的内容',a,true));local block=source:sub(a,b-1)
local run=assert(loadstring('local self,visibleSize=...\n'..block,'@MainMenu-decoration'))
local forbidden=function()error('decoration must never register a paid button, open an offer or enter checkout')end
SDButton={create=forbidden};PushGiftView={create=forbidden};purchase=forbidden
roleMapInfo='map';UIBottomHeight=136
for _,width in ipairs({480,540,640})do
    for _,returned in ipairs({false,true})do
        DataManager={getInstance=function()return {getRoleData=function()return returned and {} or nil end}end}
        local self=H.node('MainMenu');self.openGiftOffer=forbidden
        local listeners=#H.dispatcher.listeners
        run(self,{width=width,height=width*5/3})
        assert(#H.dispatcher.listeners==listeners,'no touch listeners added')
        local boat=assert(self.boatSpr);assert(#boat.children==1)
        local art=boat.children[1];assert(art.kind=='Sprite' and not art.callback and not art.onSingleCLick,'plain, noninteractive image')
        assert(art.path=='Images/DiamondStore/GoldenBoat.png')
        if returned then
            local timer=assert(self.actions[1]);assert(timer.kind=='RepeatForever')
            local seq=timer.args[1];assert(seq.args[1].kind=='DelayTime' and seq.args[1].args[1]==60)
            for i=1,3 do seq.args[2].args[1]();assert(boat.actions[i].kind=='MoveTo');assert(#H.dispatcher.listeners==listeners)end
        else assert(not self.actions or #self.actions==0,'pre-voyage has no timer')end
        self:cleanup();assert(boat.cleaned and art.cleaned,'return cleanup reaches decoration')
    end
end
assert(source:find('{"gift", "礼包（付费）"}',1,true),'fixed explicitly paid entry preserved')
print('PASS moving boat has no paid button, callbacks or listeners; repeat timer only animates; pre-voyage/cleanup and fixed Port entry retained')
