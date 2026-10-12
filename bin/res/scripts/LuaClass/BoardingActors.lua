-- Exact-identity battle illustration only. No stats, inventory or outcome writes.
local B={path='Images/UI/CleanVoyage/Combat/Actors/'}
B.manifest={
 ['100']={icons={['j_1.png']=true,['B/crew-100.png']=true},name='低级船员',visibleHeight=1510,foot={550,1493},flip=false},
 ['101']={icons={['j_2.png']=true,['B/crew-101.png']=true},name='水手',visibleHeight=1490,foot={550,1493},flip=false},
 ['10001']={icons={['g_317.png']=true},name='骷髅兵',visibleHeight=1502,foot={530,1495},flip=true},
 ['10083']={icons={['g_303.png']=true},name='亡灵士兵',visibleHeight=1506,foot={530,1497},flip=true}
}
local Actor=class('CleanBoardingActor',function()return cc.Node:create()end)
function Actor:setColor(color)
 cc.Node.setColor(self,color)
 if self.statusPortrait then self.statusPortrait:setColor(color)end
end
local function move(node,parent,x,y,z)
 node:retain();node:removeFromParent(false);parent:addChild(node,z or 0);node:release();node:setPosition(cc.p(x,y));return node
end
local function shadow(parent,width,height)
 local n=cc.DrawNode:create();local points={}
 for i=0,31 do local a=i*math.pi/16;points[#points+1]=cc.p(width*.5*math.cos(a),height*.5*math.sin(a))end
 n:drawPolygon(points,#points,cc.c4f(.10,.17,.17,.25),0,cc.c4f(0,0,0,0));parent:addChild(n,-1);return n
end
function B.create(fighter,data,height,portrait)
 local id=tostring(fighter.soilderId);local entry=B.manifest[id]
 if not entry or not entry.icons[data.icon] or tostring(data.ID)~=id or data.name~=entry.name then return nil end
 local path=B.path..'body-'..id..'-v2.png'
 if not cc.FileUtils:getInstance():isFileExist(path)then return nil end
 local root=Actor.new();root:setContentSize(cc.size(96,height));root:setAnchorPoint(cc.p(.5,0))
 root:setCascadeColorEnabled(true);root:setCascadeOpacityEnabled(true)
 local art=cc.Sprite:create(path);local z=art:getContentSize();local footX=entry.flip and z.width-entry.foot[1] or entry.foot[1]
 art:setAnchorPoint(cc.p(footX/z.width,(z.height-entry.foot[2])/z.height))
 art:setFlippedX(entry.flip);art:setPosition(cc.p(48,0));art:setScale(height/entry.visibleHeight);root:addChild(art)
 root.battleShadow=shadow(root,height*.52,height*.085);root.battleShadow:setPosition(cc.p(48,0))
 root.battleBody=true;root.battleArt=art;root.battleIdentity=id;root.battleOriginalIcon=data.icon
 root.battleFoot=cc.p(48,0);root.battleBodyHeight=height;root.identitySprite=portrait
 root.battleAttackDirection=entry.flip and -1 or 1
 return root
end
function B.attack(actor)
 -- Same .2-second presentation window, with visible ground-level movement.
 -- Position belongs to the art child; health/effect ownership stays on actor.
 for _,node in ipairs({actor.battleArt,actor.battleShadow})do
  local dx=actor.battleAttackDirection*12
  node:stopActionByTag(73101);node:setPosition(cc.p(48,0))
  local action=cc.Sequence:create(cc.MoveTo:create(.1,cc.p(48+dx,0)),cc.MoveTo:create(.1,cc.p(48,0)))
  action:setTag(73101);node:runAction(action)
 end
end
function B.attach(scene,layout)
 local root=scene.cleanBattleRoot;local data=DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
 local count=#scene.playerTeam.fighters;local ncols=math.min(3,count)
 local deckLeft=320-320*layout.stageScale
 -- Foot positions are explicit points on the walkable lower deck. A small
 -- team occupies a readable opposing pair; a full team uses two real rows.
 local frontY=layout.stageBottom+layout.stageHeight*.14
 local rearY=frontY+math.min(58,layout.stageHeight*.15)
 local enemyY=layout.stageBottom+layout.stageHeight*.43
 local playerHeight=count>3 and 104 or 134
 scene.cleanBattleBodies={};scene.cleanBattleLegacyBodies={}
 local actualPlayerBodies=0
 for i,fighter in ipairs(scene.playerTeam.fighters)do
  local portrait=scene.playerActors[i];local entry=data[tostring(fighter.soilderId)]
  local body=B.create(fighter,entry,playerHeight,portrait)
  if body then
   local col=(i-1)%ncols;local row=math.floor((i-1)/ncols)
   local center=count==1 and 235 or 265
   local step=math.min(92,layout.stageScale*154)
   local x=center+(col-(ncols-1)/2)*step+(row%2)*20
   local y=row==0 and frontY or rearY
   body:setPosition(cc.p(x,y));root:addChild(body,row==0 and 8 or 7);body.statusPortrait=portrait
   scene.playerActors[i]=body;scene.cleanBattleBodies[i]=body;actualPlayerBodies=actualPlayerBodies+1
  else
   -- Unmapped identities keep their exact status portrait. No invented body.
   scene.cleanBattleLegacyBodies[i]=tostring(fighter.soilderId)
  end
 end
 for i,fighter in ipairs(scene.enemyTeam.fighters)do
  local old=scene.enemyActors[i];local entry=data[tostring(fighter.soilderId)]
  local height=150;local body=B.create(fighter,entry,height,old)
  if body then
   old:setVisible(false)
   local x=count==1 and 422 or 445
   body:setPosition(cc.p(x+(i-1)*110,enemyY));root:addChild(body,6)
   scene.enemyActors[i]=body;scene.cleanBattleEnemyBody=body
   local mount=scene.enemyEffectActors[i]
   move(mount,body,48,height*.58,4);mount:setScale(.3)
  end
 end
 scene.cleanBattleBodyCount=actualPlayerBodies
 if scene.cleanBattleEnemyBody then
  local actor=scene.cleanBattleEnemyBody
  scene.shipWarEffectNodeEnemy:setPosition(cc.p(actor:getPositionX(),actor:getPositionY()+130))
  scene.shipWarEffectNodeEnemy:setScale(.65)
  scene.dlgNode:setPosition(cc.p(320,math.min(scene.cleanBattleSize.height-220,enemyY+195)))
 end
 if actualPlayerBodies>0 then
  scene.playerHealActors:setPosition(cc.p(count==1 and 235 or 265,frontY+72));scene.playerHealActors:setScale(.4)
  scene.shipWarEffectNodePlayer:setPosition(cc.p(count==1 and 235 or 265,frontY+95));scene.shipWarEffectNodePlayer:setScale(.65)
 end
 scene.cleanBattleWalkable={left=deckLeft,right=640-deckLeft,bottom=layout.stageBottom,top=layout.stageBottom+350*layout.stageScale}
end
return B
