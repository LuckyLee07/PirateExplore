-- Exact full-body mappings, deck contact, original action timing and health tint.
-- Native memory-only teams and engine actions; no live game profile or window.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/coherent_battle_stage_native.lua')
local stop=assert(source:find('for _,size in ipairs({{480,800}',1,true))
local T=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,fresh=fresh,capture=capture,step=step,eq=eq,near=near,tap=tap,errors=callbackErrors,
 counters=function()return writes,charges,diamonds end,
 oldTraceback=originalTraceback,count=function()return count end}
]],'@boarding-body-native-fixture'))()
local H=T.H;local B=require 'LuaClass/BoardingActors'
local expected={['100']='j_1.png',['101']='j_2.png',['10001']='g_317.png',['10083']='g_303.png'}
local function bounds(node,size,label)
 local z=node:getContentSize();local a=node:convertToWorldSpace(cc.p(0,0));local b=node:convertToWorldSpace(cc.p(z.width,z.height))
 assert(a.x>=0 and a.y>=0 and b.x<=size[1] and b.y<=size[2],label..' fully inside viewport')
 return a,b
end
local function bodyCheck(v,body,id)
 T.eq(body.battleIdentity,tostring(id),'exact identity');T.eq(body.battleOriginalIcon,expected[tostring(id)],'exact texture guard')
 local rect=v.cleanBattleWalkable;local x,y=body:getPositionX(),body:getPositionY()
 assert(x>=rect.left and x<=rect.right and y>=rect.bottom and y<=rect.top,'foot anchor on walkable deck')
 local rootFoot=body:convertToWorldSpace(body.battleFoot)
 local art=body.battleArt;local z=art:getContentSize();local anchor=art:getAnchorPoint()
 local artFoot=art:convertToWorldSpace(cc.p(z.width*anchor.x,z.height*anchor.y))
 T.near(artFoot.x,rootFoot.x,'illustrated foot x');T.near(artFoot.y,rootFoot.y,'illustrated foot y')
 local shadow=body.battleShadow:convertToWorldSpace(cc.p(0,0))
 T.near(shadow.x,rootFoot.x,'contact shadow x');T.near(shadow.y,rootFoot.y,'contact shadow y')
 local entry=B.manifest[tostring(id)];T.near(art:getScale()*entry.visibleHeight,body.battleBodyHeight,'measured visible body height')
 T.eq(art:isFlippedX(),tonumber(id)>10000,'only enemies mirror source-facing art')
 T.eq(body:getOpacity(),255,'body stays readable and opaque')
end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 for _,case in ipairs({{name='starter',ids={100},enemy=10001},{name='sailor',ids={101},enemy=10083},
  {name='mixed-two',ids={100,101},enemy=10083},{name='actual-six',ids={100,101,100,101,100,101},enemy=10001}})do
  local v=T.fresh(size,true,#case.ids,1,case.ids,case.enemy)
  T.eq(v.cleanBattleBodyCount,#case.ids,'exact actual player count');T.eq(#v.cleanBattleCards,#case.ids,'same indexed status controls')
  for i,id in ipairs(case.ids)do bodyCheck(v,v.playerActors[i],id)end
  bodyCheck(v,v.enemyActors[1],case.enemy)
  for i,card in ipairs(v.cleanBattleCards)do bounds(card,size,'roster card '..i)end
  for name,item in pairs(v.cleanBattleActions)do bounds(item,size,'complete '..name..' hit target');assert(item:isVisible() and item:isEnabled(),name..' usable')end
  T.capture(v,size,'bodies-'..case.name)
  local actor=v.playerActors[1];local enemy=v.enemyActors[1]
  v:runAttackEffect(1,1);v:runAttackEffect(2,1);T.step(v,0);T.step(v,.1)
  T.near(actor.battleArt:getPositionX(),60,'player visible forward step at .1s');T.near(enemy.battleArt:getPositionX(),36,'enemy visible forward step at .1s')
  T.near(actor.battleShadow:getPositionX(),60,'player contact follows step');T.near(enemy.battleShadow:getPositionX(),36,'enemy contact follows step')
  T.capture(v,size,'bodies-attack-'..case.name)
  T.step(v,.1);T.near(actor.battleArt:getPositionX(),48,'player reset at original .2s');T.near(enemy.battleArt:getPositionX(),48,'enemy reset at original .2s')
  v:runAttackEffect(1,1);T.step(v,0);T.step(v,.05);v:runAttackEffect(1,1);T.step(v,0);T.step(v,.1)
  T.near(actor.battleArt:getPositionX(),60,'repeated responses never accumulate displacement');T.step(v,.1);T.near(actor.battleArt:getPositionX(),48,'repeated response returns to exact foot anchor')
  local attacker=v.playerTeam.fighters[1];local defender=v.enemyTeam.fighters[1];local hp=defender.hp
  local oldRandom=math.random;math.random=function(a,b)return b or a end
  assert(v:attack(attacker,defender),'actual original attack executes');T.eq(defender.hp,hp-7,'unchanged calculated damage')
  T.step(v,0);T.step(v,.1);T.capture(v,size,'bodies-skill-'..case.name)
  T.eq(v.label_ehp:getString(),v.enemyTeam.hp..'/'..v.enemyTeam.m_hp,'same enemy HP update owner')
  T.step(v,.3);math.random=oldRandom
  v.playerAttack=function()end;v.enemyAttack=function()end;v.playerTeam.fighters[1].hp=0;v:update(0)
  T.eq(actor:getColor().g,0,'original death tint reaches body');T.eq(actor.statusPortrait:getColor().g,0,'same health owner tints status portrait')
  actor:setColor(cc.c3b(255,255,255));T.eq(actor.statusPortrait:getColor().g,255,'healing tint restoration reaches status portrait')
  H.finish()
  if case.name=='actual-six' then
   local v=T.fresh(size,true,#case.ids,1,case.ids,case.enemy)
   v.playerAttack=function()end;v.enemyAttack=function()end
   T.capture(v,size,'bodies-six-controls-before')
   -- Exercise original native Menu hit targets on the fully occupied layout.
   -- Food/diamond mutations exist only in this isolated fixture, never a profile.
   local before=v.playerTeam.hp
   T.tap(v.cleanBattleActions.food);T.eq(v.playerTeam.hp,before+30,'six-unit full-viewport food touch heals')
   T.eq(v.breadData.num,2,'six-unit food touch consumes once');T.eq(select(1,T.counters()),1,'six-unit original pack write once')
   T.tap(v.cleanBattleActions.food);T.eq(v.breadData.num,2,'six-unit repeated food touch respects cooldown')
   local instant=0;v.miaoshaAttack=function()instant=instant+1 end;T.tap(v.cleanBattleActions.instant)
   local _,charges,diamonds=T.counters();T.eq(charges,1,'six-unit paid touch charges once');T.eq(diamonds,15,'six-unit original five-diamond cost')
   T.eq(instant,1,'six-unit original paid callback once');T.tap(v.cleanBattleActions.instant);T.eq(select(2,T.counters()),1,'disabled paid touch cannot charge twice')
   v:update(0);T.eq(v.breadNumLabel:getString(),'2','original update tick refreshes food label')
   T.step(v,0);T.step(v,.01);T.capture(v,size,'bodies-six-controls-used')
   if size[1]==480 then
    for name,item in pairs(v.cleanBattleActions)do local a,b=bounds(item,size,name);print(string.format('PASS full 480x800 %s hit box: (%.2f,%.2f)-(%.2f,%.2f)',name,a.x,a.y,b.x,b.y))end
   end
   H.finish()
  end
 end
 local v=T.fresh(size,true,3,2,{100,102,101},10027)
 T.eq(v.cleanBattleBodyCount,2,'unmapped profession never receives generic body')
 T.eq(v.cleanBattleLegacyBodies[2],'102','missing actor identity remains explicit')
 assert(not v.enemyActors[1].battleBody,'g_303 alias 10027 is not mapped to 10083 body')
 T.capture(v,size,'bodies-unmapped-exact-fallback');H.finish()
 print('PASS grounded boarding bodies '..size[1]..'x'..size[2]..': exact 1/2/6 teams, boot/shadow anchors, .2s response, tint and truthful fallback')
end
-- Icon/name/ID guards independently reject an aliased or changed identity.
for id,entry in pairs(B.manifest)do
 local row=H.tables[csvOfSoilderAttribute][id];local f={soilderId=id}
 local wrong=clone(row);wrong.ID='10012';assert(B.create(f,wrong,134)==nil,'row ID mismatch rejected')
 wrong=clone(row);wrong.icon='g_303.png';if not entry.icons[wrong.icon]then assert(B.create(f,wrong,134)==nil,'icon mismatch rejected')end
 wrong=clone(row);wrong.name='另一个身份';assert(B.create(f,wrong,134)==nil,'semantic name mismatch rejected')
end
-- Existing exact ResourceTheme portrait guards remain compatible.
for id,name in pairs({['100']='B/crew-100.png',['101']='B/crew-101.png'})do
 local row=clone(H.tables[csvOfSoilderAttribute][id]);row.icon=name
 local actor=assert(B.create({soilderId=id},row,134));actor:retain();T.eq(actor.battleOriginalIcon,name,'approved current portrait alias');actor:release()
end
assert(#T.errors==0,table.concat(T.errors,'\n'));__G__TRACKBACK__=T.oldTraceback;cc.Director.getInstance=H.realGet
print('PASS grounded boarding native assertions: '..T.count())
