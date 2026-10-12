-- Source conservation against the reviewed 169a424 page checkpoint.
-- Rolling byte checksums pin entire unchanged function blocks, including
-- outcomes, map transitions, save/economy writes, all loot/chest methods.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local function checksum(s)local a=0;for i=1,#s do a=(a*131+s:byte(i))%2147483647 end;return a end
local source=read('bin/res/scripts/LuaClass/FightMode.lua')
-- Normalize only exact approved chest feedback lines; all original 71 checks remain.
source=dofile('tools/tests/fixtures/chest_feedback_conservation.lua').fight(source)
assert(loadstring(source))
-- The shared exact allowlist also strips the six reviewed recovery hook lines.
local expected={
 ['Fighter:init']={1054,805982906},
 ['Fighter:reset']={228,323311187},
 ['Fighter:canAttack']={798,2101703346},
 ['FightBoxViewAlert:create']={166,986939379},
 ['FightBoxViewAlert:init']={3891,1406130908},
 ['FightBoxView:create']={156,180296089},
 ['FightBoxView:init']={6709,387371080},
 ['FightBoxView:reloadBoxes']={7942,550458039},
 ['FightBoxView:showInfo']={997,1009750472},
 ['FightBoxView:hideInfo']={120,730014907},
 ['FightBoxView:openBox']={4847,1801561775},
 ['FightBoxView:giveUpCallback']={835,2115447117},
 ['FightBoxView:useDiamondCallback']={2525,728083841},
 ['FightBoxView:createCoherentChestItem']={486,1261249180},
 ['FightBoxView:decorateCoherentChestReward']={685,1035763238},
 ['FightBoxView:coherentEmptyChestMark']={153,1405857713},
 ['FightBoxView:initCoherentChest']={3543,364542550},
 ['FightBoxView:refreshCoherentChest']={378,1022091697},
 ['FightBoxViewAlert:initCoherentChestAlert']={2288,746007263},
 ['FightTransitionScene:create']={217,536404088},
 ['FightTransitionScene:init']={1865,945262384},
 ['FightBufferData:init']={3606,839469699},
 ['FightScene:create']={220,2030796360},
 ['FightScene:init']={1298,337636941},
 ['FightScene:initData']={6968,249575200},
 ['FightScene:initShipWarCDData']={1384,712890757},
 ['FightScene:initUIAndScene']={244,1559492997},
 ['FightScene:update']={8193,872451051},
 ['FightScene:showCurtainEffect']={1849,992550527},
 ['FightScene:setFightOverCallback']={159,835839703},
 ['FightScene:gotoFightRewardScene']={646,588890719},
 ['FightScene:showFailInfoAndReturn']={9156,841141222},
 ['FightScene:updateBuffers']={1293,36107444},
 ['FightScene:bufferBegin']={465,1285791372},
 ['FightScene:bufferEnd']={515,2076160952},
 ['FightScene:bufferSettle']={1131,1052649640},
 ['FightScene:addBuffer']={386,1046641821},
 ['FightScene:removeBuffer']={354,1049919168},
 ['FightScene:reloadBuffers']={1468,200078192},
 ['FightScene:getDebufferNum']={272,1367088090},
 ['FightScene:calculateTeamMiss']={560,1520003788},
 ['FightScene:calculateTeamHp']={633,1268332906},
 ['FightScene:calculateTeamHpAndRunAction']={974,1782324857},
 ['FightScene:playerAttack']={363,556907323},
 ['FightScene:enemyAttack']={362,1133023599},
 ['FightScene:attack']={5750,1383316100},
 ['FightScene:calculateDamage']={1005,26397036},
 ['FightScene:calculateHeal']={628,918266549},
 ['FightScene:miaoshaAttack']={419,1842937290},
 ['FightScene:runInjuredEffect']={1573,1377383082},
 ['FightScene:injuredEffect']={1453,763851063},
 ['FightScene:shakeEffect']={853,1675789646},
 ['FightScene:runMissEffect']={515,1546805086},
 ['FightScene:missEffect']={709,753899645},
 ['FightScene:runAnimationEffect']={773,1716252954},
 ['FightScene:animationEffect']={1288,211173798},
 ['FightScene:runParticleEffect']={771,1805607663},
 ['FightScene:particleEffect']={533,314916902},
 ['FightScene:showMonasterDialogue']={887,1316546602},
 ['FightScene:hideMonasterDialogue']={963,638049928},
 ['FightRewardScene:create']={196,1416078501},
 ['FightRewardScene:init']={12577,742359266},
 ['FightRewardScene:initData']={2451,509454446},
 ['FightRewardScene:setFightOverCallback']={141,2030214163},
 ['FightRewardScene:setFightResult']={209,887139977},
 ['FightRewardScene:pickUpAllRewards']={3139,1883243360},
 ['FightRewardScene:getCargoHint']={2745,1409588583},
 ['FightRewardScene:refreshCargoHint']={888,1393054113},
 ['FightRewardScene:initCoherentCargo']={7071,230645710},
 ['FightRewardScene:refreshCoherentCargo']={1378,2045934623},
 ['FightRewardScene:settleCargo']={1019,654696493},
}
local offsets={};for pos,name in source:gmatch('()function ([^%(\n]+)')do
 if pos==1 or source:sub(pos-1,pos-1)=='\n' then offsets[#offsets+1]={pos,name}end
end
local checked=0
for i,entry in ipairs(offsets)do
 local want=expected[entry[2]]
 if want then
  local part=source:sub(entry[1],offsets[i+1] and offsets[i+1][1]-1 or #source)
  assert(#part==want[1] and checksum(part)==want[2],'unchanged gameplay/shared function: '..entry[2]);checked=checked+1
 end
end
local function between(text,a,b)local first=assert(text:find(a,1,true));local last=assert(text:find(b,first,true));return text:sub(first,last-1)end
local part=between(source,[=[    -- miaoshaBtn
]=],[=[        -- shipWarEffectNode
]=]);assert(#part==3085 and checksum(part)==1349433895,'food and paid handlers bytes and invocation order unchanged')
local part=between(source,[=[        atkBtn:registerScriptTapHandler(function(tag, menuItem)
        --]=],[=[        local menu = cc.Menu:create(atkBtn)]=]);assert(#part==334 and checksum(part)==1186774726,'manual attack callback bytes and invocation order unchanged')
local theme=read('bin/res/scripts/LuaClass/CombatTheme.lua');assert(loadstring(theme));local prefix=theme:sub(1,3846);assert(checksum(prefix)==155099980,'shared loot theme helpers byte-exact')
assert(source:find('local scale1 = cc.ScaleTo:create(0.2, (self.cleanBattleRoot and 1.12 or 3.0)*tmp)',1,true),'only opt-in pulse amplitude changes')
assert(theme:find('cc.rect(0,0,927,1697*73/185)',1,true),'rear cannon uses accepted top crop')
assert(not theme:find('cannon-short-clean',1,true),'rejected cannon never integrated')
assert(checked==71,'every immutable function checked')
print('PASS clean battle source conservation: '..checked..' complete methods, original input handlers and shared loot theme')
local effect=between(source,'function FightScene:runAttackEffect',[=[-- 播放受伤特效]=]);local bodyBranch=[=[            if actor.battleBody then
                require('LuaClass/BoardingActors').attack(actor)
                return
            end
]=];local bodyFirst=assert(effect:find(bodyBranch,1,true));effect=effect:sub(1,bodyFirst-1)..effect:sub(bodyFirst+#bodyBranch);local first=assert(effect:find([=[(self.cleanBattleRoot and 1.12 or 3.0)*tmp]=],1,true));effect=effect:sub(1,first-1)..[=[3.0*tmp]=]..effect:sub(first+42);assert(#effect==2435 and checksum(effect)==1310810459,'FightScene:runAttackEffect timing/attachments unchanged except approved presentation setting')
local effect=between(source,'function FightScene:runShipBombingEffect',[=[-- updateBuffers]=]);local first=assert(effect:find([=[self.cleanBattleSize or cc.Director:getInstance():getVisibleSize()]=],1,true));effect=effect:sub(1,first-1)..[=[cc.Director:getInstance():getVisibleSize()]=]..effect:sub(first+66);assert(#effect==1245 and checksum(effect)==589815643,'FightScene:runShipBombingEffect timing/attachments unchanged except approved presentation setting')
