-- Actual production constructors/actions with native nodes, isolated in-memory
-- game state. No application window, player profile or external purchase.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,tables=tables,csv=csv,fixture=fixture,serialize=serialize,getData=function()return data end,visit=visit,
 prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
 finish=function()scene:cleanup();scene:release();scene=nil end,realGet=realGet}
]],'@coherent-battle-native-fixture'))()
local W=require 'LuaClass/WarmTheme';local C=require 'LuaClass/CombatTheme';require 'LuaClass/DialogTheme';require 'LuaClass/EffectUtil'
local realCreateAnimation=EffectUtil.createAnimation
local dm=H.dm;H.tables[csvOfSkillAttribute]=H.csv('skillAttribute');H.tables[csvOfBuff]=H.csv('buff')
local now=100;getSystemTimeMilliSecond=function()return now end
local fdm={bonusAttribute={ready=false,hits=0}}
source=read('bin/res/scripts/LuaClass/FightMode.lua')
local first=assert(source:find('Fighter = class(',1,true));local last=assert(source:find('FightBoxViewAlert = class(',first,true))
local start=assert(source:find('FightBufferData = class(',last,true));local finish=assert(source:find('FightRewardScene = class(',start,true))
assert(loadstring('local fdm=...\n'..source:sub(first,last-1)..source:sub(start,finish-1),'@production-battle'))(fdm)
local count=0
local function eq(a,b,why)count=count+1;assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function near(a,b,why)count=count+1;assert(math.abs(a-b)<.02,why..': '..a..' ~= '..b)end
local writes,charges,toast,achievement=0,0,nil,0
local diamonds=20;local pack
ToastUtil.downString=function(_,s)toast=s end
dm.getSound_off=function()return 1 end
dm.getAchievementInfo=function()return achievement end
dm.setAchievementInfo=function(_,key,value)achievement=value end
dm.setRoleData=function(_,key,value)eq(key,roleBattlePack,'only existing food inventory write');writes=writes+1;pack=value end
dm.getRoleData=function(_,key)if key==roleBreadHp then return 30 elseif key==roleBattlePack then return pack end;return H.getData()[key]end
dm.addDiamond=function(_,delta,forced)eq(delta,-5,'original instant cost');eq(forced,false,'original shortage behavior');if diamonds+delta<0 then return 0 end;diamonds=diamonds+delta;charges=charges+1;return 1 end
local function tap(item)if coherentMenuTap then coherentMenuTap(item)else item:activate()end end
local originalTraceback=__G__TRACKBACK__;local callbackErrors={}
__G__TRACKBACK__=function(message)callbackErrors[#callbackErrors+1]=tostring(message);return tostring(message)end
local function parseTalk(row)row.talk1={{'0'}};row.talk2={{'0'}}end
local function fighter(id,i,enemy)
 local data=assert(H.tables[csvOfSoilderAttribute][tostring(id)],'actual fighter '..id);parseTalk(data)
 local f=Fighter.new();f.soilderId=id;f.name=data.name;f.description=data.description or '海上的相遇';f.star=tonumber(data.star)
 f.m_hp=100+i*37;f.hp=f.m_hp-30;f.interval=2;f.atk=7;f.skillRatio=1;f.damageReduction=0;f.bufferId=0;f.miss=0
 f.lastAtkTime=0;f.alive=true;f.isHalo=false;f.teamType=enemy and 2 or 1;f.teamIndex=i;return f
end
local bossId
for id,data in pairs(H.tables[csvOfSoilderAttribute])do if data.icon=='g_303.png' then bossId=id;break end end
assert(bossId)
local function fresh(size,boarding,n,mode,ids,enemyId)
 local host=H.prepare(size[1],size[2]);local view=FightScene.new();host:addChild(view)
 view.fightType=boarding and 2 or 1;view.fightMode=mode or 2;view.isAutoAtk=true;view.isPause=false;view.isBossInjured=false;view.isShowEffect=true
 view.playerTeam={fighters={},star=1,miss=0};view.enemyTeam={fighters={},star=enemyId and tonumber(H.tables[csvOfSoilderAttribute][tostring(enemyId)].star) or 3,miss=0};view.buffers={};view.bufferLabels={};view.jiyangtime=5
 for i=1,n do view.playerTeam.fighters[i]=fighter(ids and ids[i] or 100+(i-1)%6,i,false)end
 for i=1,(boarding and 1 or n)do view.enemyTeam.fighters[i]=fighter(enemyId or bossId,i,true)end
 view:calculateTeamHp();view.breadData={id='1005',num=3};pack={['1005']=view.breadData};writes=0;charges=0;diamonds=20;achievement=0
 if boarding then view:initAboardWarUIScene()else view:initShipWarUIScene()end
 return view
end
local function walk(view,w,h)
 H.visit(view,function(n,visible)
  if visible and n.getString and n:getString()~='' then
   local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
   assert(a.x>=-1 and b.x<=w+1,'text horizontal '..n:getString()..' '..a.x..' '..b.x)
   assert(a.y>=-1 and b.y<=h+1,'text vertical '..n:getString()..' '..a.y..' '..b.y)
   if n.getFontName then eq(n:getFontName(),W.font,'shared text face')end
  end
 end)
end
local function capture(view,size,name)
 if coherentCapture and os.getenv('COHERENT_BATTLE_CAPTURE_DIR') then
  assert(coherentCapture(view,size[1],size[2],os.getenv('COHERENT_BATTLE_CAPTURE_DIR')..'/'..name..'-'..size[1]..'x'..size[2]..'.png'))
 end
end
local function step(view,dt)
 local manager=cc.Director:getInstance():getActionManager()
 H.visit(view,function(n)manager:resumeTarget(n)end);manager:update(dt)
end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 for _,n in ipairs({1,6})do
  local v=fresh(size,true,n,1);walk(v,size[1],size[2]);eq(#v.cleanBattleCards,n,'only actual embarked crew')
  eq(v.label_hp:getString(),v.playerTeam.hp..'/'..v.playerTeam.m_hp,'real aggregate HP')
  eq(v.playerHpLabels[1]:getString(),v.playerTeam.fighters[1].hp..'/'..v.playerTeam.fighters[1].m_hp,'real individual HP')
  if n==6 then assert(v.playerHpLabels[1]:getString()~=v.label_hp:getString(),'individual and aggregate are distinct')end
  for i,actor in ipairs(v.playerActors)do
   local id=tostring(v.playerTeam.fighters[i].soilderId);local path='Images/Icon/'..H.tables[csvOfSoilderAttribute][id].icon
   eq((actor.statusPortrait or actor):getTexture(),cc.Director:getInstance():getTextureCache():addImage(path),'exact profession/identity status texture preserved')
  end
  local path='Images/Boss/'..H.tables[csvOfSoilderAttribute][tostring(v.enemyTeam.fighters[1].soilderId)].icon
  eq((v.enemyActors[1].identitySprite or v.enemyActors[1]):getTexture(),cc.Director:getInstance():getTextureCache():addImage(path),'exact enemy identity source preserved')
  eq(writes,0,'read-only layout');eq(charges,0,'read-only buttons');capture(v,size,'boarding-'..n)
  local enemy=v.enemyActors[1];near(enemy:getScale()*enemy:getContentSize().height,enemy.battleBody and 150 or 160,'bounded exact enemy presentation')
  local old=enemy:getScale();enemy:stopAllActions();v:runAttackEffect(2,1);step(v,0);step(v,.18)
  if enemy.battleBody then
   local dx=enemy.battleArt:getPositionX()-48;assert(math.abs(dx)<=12.1 and math.abs(dx)>0,'bounded body response before reset')
  else assert(enemy:getScale()<=old*1.121 and enemy:getScale()>old,'bounded attack pulse before reset')end
  capture(v,size,'boarding-attack-'..n)
  step(v,.03);near(enemy:getScale(),old,'original pulse returns after .2 seconds');near(enemy:getOpacity(),255,'original fade returns')
  local crew=v.playerActors[1];local crewScale=crew:getScale();v:runAttackEffect(1,1);step(v,0);step(v,.18)
  if crew.battleBody then assert(math.abs(crew.battleArt:getPositionX()-48)<=12.1 and crew.battleArt:getPositionX()>48,'bounded crew body response')
  else assert(crew:getScale()<=crewScale*1.121 and crew:getScale()>crewScale,'crew pulse stays inside compact portrait region')end
  step(v,.03);near(crew:getScale(),crewScale,'crew response resets at original time');if crew.battleBody then near(crew.battleArt:getPositionX(),48,'body step resets at .2 seconds')end
  local hpBefore=v.playerTeam.hp
  tap(v.cleanBattleActions.food);eq(v.playerTeam.hp,hpBefore+30,'original heal amount/distribution');eq(v.breadData.num,2,'food consumed once');eq(writes,1,'one original pack write');eq(achievement,1,'one original achievement');eq(v.jiyangtime,0,'same cooldown')
  tap(v.cleanBattleActions.food);eq(v.playerTeam.hp,hpBefore+30,'cooldown does not heal again');eq(v.breadData.num,2,'cooldown blocks repeat');eq(writes,1,'cooldown no write');assert(toast:find('冷却中',1,true))
  local playerAttack=v.playerAttack;local enemyAttack=v.enemyAttack;v.playerAttack=function()end;v.enemyAttack=function()end
  v:update(2.5);near(v.jyProgress:getScaleX(),.5,'live half cooldown');eq(v.breadNumLabel:getString(),'2','live count')
  v:update(2.5);near(v.jyProgress:getScaleX(),0,'cooldown completes');v.breadData.num=0;tap(v.cleanBattleActions.food);eq(writes,1,'no-food no write')
  local instant=0;v.miaoshaAttack=function()instant=instant+1 end;diamonds=4;tap(v.cleanBattleActions.instant);eq(charges,0,'shortage no spend');eq(instant,0,'shortage no kill')
  diamonds=20;tap(v.cleanBattleActions.instant);eq(charges,1,'5-diamond action charges once');eq(diamonds,15,'same paid cost');eq(instant,1,'same instant callback');assert(not v.cleanBattleActions.instant:isEnabled(),'original disables paid action');tap(v.cleanBattleActions.instant);eq(charges,1,'disabled paid input cannot charge twice')
  local manual=0;v.attack=function(_,attacker,defender)eq(attacker,v.playerTeam.fighters[1],'same indexed attacker');eq(defender,v.enemyTeam.fighters[1],'same defender');manual=manual+1 end
  v.isAutoAtk=false;v:update(0);assert(v.playerAtkBtns[1]:isVisible(),'manual action exposed when ready');capture(v,size,'boarding-manual-'..n);tap(v.playerAtkBtns[1]);eq(manual,1,'same manual callback')
  v.isAutoAtk=true;v:update(0);assert(not v.playerAtkBtns[1]:isVisible(),'auto hides manual input')
  H.finish()
 end
 for _,n in ipairs({1,6,10})do
  local v=fresh(size,false,n);walk(v,size[1],size[2]);eq(#v.playerActors,n,'actual cannon count');capture(v,size,'ship-'..n)
  for _,team in ipairs({1,2})do
   local actors=team==1 and v.playerActors or v.enemyActors
   for i,actor in ipairs(actors)do
    local h=i>6 and 73 or 185;eq(actor:getContentSize().width,101,'logical cannon width');eq(actor:getContentSize().height,h,'logical cannon height')
    local visual=assert(actor.battleVisual);near(visual:getContentSize().width*visual:getScaleX(),101,'normalized cannon art width');near(visual:getContentSize().height*visual:getScaleY(),h,'normalized cannon art height')
    eq(visual:isFlippedY(),team==2,'enemy visual mirror');local point=actor:convertToWorldSpace(cc.p(50.5,team==1 and h-10 or 10));assert(point.x>0 and point.x<size[1] and point.y>0 and point.y<size[2],'muzzle on screen')
   end
  end
  local flames={};EffectUtil.createAnimation=function(self,path,repeats)local a=realCreateAnimation(self,path,repeats);flames[#flames+1]=a;return a end
  v:runAttackEffect(1,n);v:runAttackEffect(2,n);step(v,0);step(v,.1);eq(#flames,2,'both original .1-second muzzle callbacks')
  local h=n>6 and 73 or 185;near(flames[1]:getPositionY(),h-10,'player muzzle geometry');near(flames[2]:getPositionY(),10,'enemy muzzle geometry')
  capture(v,size,'ship-fire-'..n);step(v,.11);near(v.playerActors[n]:getScaleX(),1,'recoil X reset');near(v.playerActors[n]:getScaleY(),1,'recoil Y reset');capture(v,size,'ship-action-'..n)
  H.finish()
 end
 print('PASS clean battle '..size[1]..'x'..size[2]..': 1/6 crew, 1/6/10 guns, real HP/input/cost/CD, bounded pulse and muzzles')
end
-- The two swipes and title keep the same entry/callback schedule.
local size={480,800};local v=fresh(size,true,6);v:stopAllActions();local curtains=0
v:showCurtainEffect(1,function()curtains=curtains+1 end);step(v,0);capture(v,size,'curtain-0');eq(curtains,0,'curtain no early callback')
step(v,.15);capture(v,size,'curtain-015');eq(curtains,0,'swipe callback unchanged')
step(v,.45);capture(v,size,'curtain-06');eq(curtains,0,'title callback unchanged')
step(v,.99);eq(curtains,0,'callback not before 1.6 seconds');step(v,.02);eq(curtains,1,'original 1.6-second callback once');capture(v,size,'curtain-complete')
step(v,1);eq(curtains,1,'curtain does not repeat');H.finish()
-- Legacy opt-out still constructs Sprite actors and original geometry.
WARM_PIRATE_V1=false
v=fresh({640,960},false,1);assert(not v.cleanBattleRoot);assert(v.playerActors[1].setFlippedY);eq(v.playerActors[1]:getContentSize().height,185,'legacy cannon size');H.finish()
v=fresh({640,960},true,1);assert(not v.cleanBattleRoot);near(v.enemyActors[1]:getScale(),2.5,'legacy boss scale remains');H.finish()
WARM_PIRATE_V1=true
assert(#callbackErrors==0,table.concat(callbackErrors,'\n'));__G__TRACKBACK__=originalTraceback;cc.Director.getInstance=H.realGet
print('PASS clean battle native assertions: '..count)
