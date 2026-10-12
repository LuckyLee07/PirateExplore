-- Native production RandomEventView pixels, scene-graph input and transactions.
-- All models are disposable memory fixtures; billing stays a counted spy.
local X=dofile('tools/tests/fixtures/intelligence_return_fixture.lua');local H,T,F,dm=X.H,X.T,X.F,X.dm
local errors={};__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
local out=os.getenv('INTELLIGENCE_CAPTURE_DIR')or'/workspace/shared/pirate-audit/intelligence-sheet'
local frames=assert(io.open(out..'/frames.tsv','w'))
local width,height=480,800;local fresh=F.fresh
F.fresh=function()return fresh(width,height)end
T.enter=function(scene)if coherentEventEnter then coherentEventEnter(scene,width,height)end end
local function stable(v)
 v.owner:stopAllActions();v.owner:setScale(1)
 if coherentWorldStep then coherentWorldStep(1)end
end
local function make(kind,w,h,balance)
 width,height=w,h;local v=X.new(kind,balance or 0);stable(v)
 if kind=='talent'then
  local source=RandomEventLayer.instance;source.eventId=3;source.costId=1;source.talent=H.tables[csvOfTalent]['2002']
  v.target.description=source:getFormatedDesc();v.owner.tableview1:reloadData()
 end
 return v
end
local function dispose(v)H.finish();v.owner:release()end
local function capture(v,name)
 stable(v)
 H.visit(v.owner,function(n,visible)
  if visible and n.getString and n:getString()~=''then
   local scroll=false;local p=n:getParent();while p do if tolua.type(p)=='cc.ScrollView'then scroll=true;break end;p=p:getParent()end
   if not scroll then local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
    T.ok(a.x>=-1 and a.y>=-1 and b.x<=width+1 and b.y<=height+1,'visible fixed label bounds: '..n:getString())end
   if n.getFontSize then T.ok(n:getFontSize()*n:getScaleX()>=15,'readable actual type: '..n:getString())end
  end
 end)
 if coherentCapture then
  local path=out..'/'..name..'-'..width..'x'..height..'.png';assert(coherentCapture(v.owner,width,height,path))
  local root=v.owner.intelligenceCanvas;local size=root:getContentSize();local pos=cc.p(root:getPositionX(),root:getPositionY())
  frames:write(table.concat({path,width,height,pos.x,pos.y,size.width,size.height},'\t')..'\n');frames:flush()
  if name=='intelligence-talent'then
   local nodes={};for i=1,16 do local n=cc.Node:create();root:addChild(n);nodes[i]=n end
   assert(coherentCapture(v.owner,width,height,path:gsub('%.png$','-dynamic.png')))
   for _,n in ipairs(nodes)do n:removeFromParent(true)end
  end
 end
end
local function point(control)
 local s=control.item:getContentSize();return control.item:convertToWorldSpace(cc.p(s.width/2,s.height/2))
end
local function gesture(phase,p)assert(coherentEventGesture,'actual native dispatcher required');coherentEventGesture(phase,p.x,p.y)end
local function tap(control)local p=point(control);gesture(0,p);gesture(2,p)end
for _,size in ipairs({{360,640},{480,800},{640,960}})do
 for _,kind in ipairs({'talent','mission'})do
  local v=make(kind,size[1],size[2]);capture(v,'intelligence-'..kind)
  local sc=v.owner.intelligenceScroll;local row=v.owner.intelligenceRows[1];local p=point(row.primary)
  T.ok(p.x>=0 and p.x<=width and p.y>=0 and p.y<=height,'visible first action')
  if coherentEventGesture then
   local writes,created=T.writes,T.created;gesture(0,p);gesture(3,p);gesture(2,p)
   T.eq(T.writes,writes,'native cancelled press never charges');T.eq(T.created,created,'native cancelled press never opens gift');T.eq(v.owner.warmShortageContext,nil,'cancelled press creates no prompt')
   gesture(0,p);gesture(1,cc.p(p.x,p.y+20));gesture(1,p);gesture(2,p)
   T.eq(v.owner.warmShortageContext,nil,'out-and-back drag never activates')
   local old=row.primary;old:retain();gesture(0,p);v.owner.tableview1:reloadData();gesture(2,p);old.item:activate()
   T.eq(v.owner.warmShortageContext,nil,'rebound held native and retained buttons stay inert');old:release()
   tap(v.owner.intelligenceRows[1].primary);local prompt,context=T.prompt(v.owner)
   T.eq(T.writes,writes,'shortage native tap does not charge');prompt.warmOptions[2].item:activate();prompt:release()
   v.data[roleDiamond]=kind=='talent'and 3 or 50
   local control=v.owner.intelligenceRows[1].primary;control:retain();tap(control);control.item:activate()
   T.eq(v.data[roleDiamond],0,'native success uses exact original price');T.eq(T.writes,writes+1,'native rapid retained activation charges once');control:release()
   if kind=='mission'then capture(v,'mission-complete')end
  end
  dispose(v)
 end
 local v=make('talent',size[1],size[2]);v.random.eventList={};v.owner.tableview1:reloadData();capture(v,'intelligence-empty');dispose(v)
 local v=make('mission',size[1],size[2]);local originalDescription=v.target.infos.desc;v.target.infos.desc=string.rep(originalDescription..'\n',24);v.owner.tableview1:reloadData();capture(v,'mission-long-top')
 local sc=v.owner.intelligenceScroll
 T.ok(sc:getContainer():getContentSize().height>sc:getViewSize().height,'long text fully measured into real scrolling content')
 if coherentDescriptionDrag then local visible,moved=coherentDescriptionDrag(sc);T.ok(visible and moved,'actual dispatched long-description scrolling')end
 sc:setContentOffset(cc.p(0,0));capture(v,'mission-long-bottom')
 if coherentEventGesture then
  local before=T.writes;tap(v.owner.intelligenceRows[1].primary);local prompt=T.prompt(v.owner);T.eq(T.writes,before,'scrolled quick-complete original shortage');prompt:release()
 end
 v.target.infos.desc=originalDescription;dispose(v)
end
-- Interruptions are dispatched through the real GLView, including a scene
-- push/pop during a held press and a live generation change before release.
if coherentEventGesture then
 for _,kind in ipairs({'talent','mission'})do
  for _,how in ipairs({'cancel','scroll','offset','rebuild','reinit','generation','remove','push','close','model'})do
   local v=make(kind,360,640)
   if how=='offset'then
    if kind=='talent'then v.target.description=string.rep(v.target.description,12)
    else local old=v.target.infos.desc;v.target.infos.desc=string.rep(old,12);v.owner.tableview1:reloadData();v.target.infos.desc=old end
    if kind=='talent'then v.owner.tableview1:reloadData()end
    v.owner.intelligenceScroll:setContentOffset(cc.p(0,0))
   end
   local button=v.owner.intelligenceRows[1].primary;button:retain();local p=point(button)
   local writes=T.writes;gesture(0,p)
   if how=='cancel'then gesture(3,p)
   elseif how=='scroll'then gesture(1,cc.p(p.x,p.y+32));gesture(1,p)
   elseif how=='offset'then
    local sc=v.owner.intelligenceScroll;sc:setContentOffset(cc.p(0,sc:getContentOffset().y-12),false)
   elseif how=='rebuild'then local oldRoot=v.owner.intelligenceCanvas;oldRoot:retain();v.owner.tableview1:reloadData();button.item:activate();oldRoot:release()
   elseif how=='reinit'then v.owner:init()
   elseif how=='generation'then v.owner.warmIntelligenceGeneration=v.owner.warmIntelligenceGeneration+1
   elseif how=='remove'then
    local root=v.owner.intelligenceCanvas;v.owner:removeFromParent(true);v.owner.tableview1:reloadData()
    T.eq(v.owner.intelligenceCanvas,root,'retained producer refresh cannot rebuild removed owner')
   elseif how=='push'then
    F.director:pushScene(cc.Scene:create());for _=1,4 do F.director:drawScene()end
    T.eq(v.owner.intelligenceSuspended,true,'scene suspension invalidates input immediately')
    F.director:popScene();for _=1,4 do F.director:drawScene()end
   elseif how=='close'then v.owner:close()
   elseif kind=='talent'then v.random.eventList={}
   else v.manager.missions[v.target.id]=nil end
   gesture(2,p);T.eq(T.writes,writes,'interrupted '..kind..' '..how..' never charges');T.eq(v.owner.warmShortageContext,nil,'interrupted '..kind..' '..how..' never opens shortage')
   if how=='reinit'or how=='push'then
    tap(v.owner.intelligenceRows[1].primary);local prompt=T.prompt(v.owner);prompt.warmOptions[2].item:activate();prompt:release()
   end
   button:release();dispose(v)
  end
 end
end
-- All shipped random-event descriptions and all costs remain real data. A
-- multi-row list proves that a drag starting on an action moves the list.
do
 local v=make('talent',360,640);local source=RandomEventLayer.instance;v.random.eventList={}
 for _,kind in ipairs({1,2,3,4,5})do
  source.eventId=kind;source.costId=1;source.talent=H.tables[csvOfTalent]['2002']
  v.random.eventList[#v.random.eventList+1]=RandomEvent:create(kind,1,'2002',os.time(),3600,source:getFormatedDesc())
 end
 v.owner.tableview1:reloadData();capture(v,'intelligence-all-top');T.eq(#v.owner.intelligenceRows,5,'all shipped event kinds visible')
 if coherentEventGesture then
  local sc=v.owner.intelligenceScroll;local b=v.owner.intelligenceRows[1].primary
  local p=point(b);local before=sc:getContentOffset().y;local writes=T.writes
  gesture(0,p);gesture(1,cc.p(p.x,p.y+22));gesture(1,cc.p(p.x,p.y+72));gesture(2,cc.p(p.x,p.y+72))
  T.ok(sc:getContentOffset().y>before,'action-origin drag scrolls through native dispatcher');T.eq(T.writes,writes,'scroll never performs event transaction');T.eq(#v.random.eventList,5,'scroll never discards a row')
  sc:setContentOffset(cc.p(0,0));capture(v,'intelligence-all-bottom')
  tap(v.owner.intelligenceRows[5].secondary);T.eq(#v.random.eventList,4,'native cancel removes only selected original event')
 end
 dispose(v)
end
-- Mission receive/abandon and gold-learning still run their original models.
do
 local v=make('mission',480,800,50);local grants={};local old=dm.addSoilderWithId
 dm.addSoilderWithId=function(_,id,num)grants[#grants+1]={id,num}end
 v.owner.intelligenceRows[1].primary.item:activate();T.eq(v.target:getMissionStatue(),'complete','original mission quick-complete')
 local button=v.owner.intelligenceRows[1].primary;button:retain();button.item:activate();button.item:activate()
 T.eq(v.target:getMissionStatue(),'receive','original reward receive');T.eq(#grants,1,'retained repeated receive grants once')
 local reward=v.target:getRewards()[1];T.eq(grants[1][1],reward.id,'original reward identity');T.eq(grants[1][2],reward.num,'original reward quantity')
 button:release();dm.addSoilderWithId=old;dispose(v)
 local v=make('mission',480,800);local writes=T.writes;v.owner.intelligenceRows[1].secondary.item:activate()
 T.eq(v.manager.missions[v.target.id],nil,'original mission abandonment');T.eq(T.writes,writes,'abandon never charges');dispose(v)
 local v=make('talent',480,800);local old=dm.addCoin;local spent=0
 dm.addCoin=function(_,amount)spent=spent+amount;v.data[roleMoney]=v.data[roleMoney]+amount;return 1 end
 v.data[roleMoney]=500;local b=v.owner.intelligenceRows[1].secondary;b:retain();b.item:activate();b.item:activate()
 T.eq(spent,-500,'gold-learning exact original cost once');T.eq(v.data[roleTalent]['1'],'2002','gold-learning original talent unlock');b:release();dm.addCoin=old;dispose(v)
end
-- A timed waiting mission uses its own model clock for display and expiry.
do
 local v=make('mission',480,800,50);local b=v.owner.intelligenceRows[1].primary;b:retain()
 v.target.time=60;v.target.startTime=NotificationNode:getInstance():GetGameTime()-61
 local writes=T.writes;b.item:activate();T.eq(T.writes,writes,'expired mission cannot quick-complete even before refresh')
 v.owner.intelligenceUpdateTimes();T.eq(v.manager.missions[v.target.id],nil,'original mission manager removes expired waiting mission')
 T.eq(#v.owner.intelligenceRows,0,'expired mission leaves no visible stale row');b:release();dispose(v)
end
-- Open the real RandomEventView through both unmodified coherent pages.
H.tables[csvOfAchievement]=H.csv('achievement');require 'LuaClass/Talent';require 'LuaClass/Achievement'
for _,which in ipairs({'talent','achievement'})do
 local v=make('talent',480,800);v.owner:removeFromParent(true)
 v.data[roleAlchemyCanLongPress]=0;v.data[roleAlchemyUnit]=3;v.data[roleAchievement]={};v.data[roleAchievementPoint]=0;v.data[roleStorageInfo]={}
 v.data[roleMapInfo]={curIndex=1};isEnterMap=false
 local page=which=='talent'and TalentLayer:create()or AchievementLayer:create();page:retain();v.scene:addChild(page)
 local entry=which=='talent'and page.talentIntelligence or page.achievementIntelligence
 if coherentEventGesture then tap(entry)else entry.item:activate()end
 local sheet=RandomEventView.instance;T.ok(sheet~=v.owner and sheet:getParent()==v.scene,'actual '..which..' route reaches production intelligence')
 sheet:stopAllActions();sheet:setScale(1)
 if coherentCapture then assert(coherentCapture(v.scene,480,800,out..'/from-'..which..'-480x800.png'))end
 local p=point(sheet.intelligenceClose)
 if coherentEventGesture then gesture(0,p);gesture(2,p)else sheet.intelligenceClose.item:activate()end
 T.ok(sheet._dialogueClosing,'obvious native close works from '..which);T.step(v.scene,0);T.step(v.scene,1)
 T.eq(sheet:getParent(),nil,'close removes exact sheet');T.eq(page:getParent(),v.scene,'close preserves original '..which..' page')
 page:destory();page:removeFromParent(true);page:release();dispose(v)
end
frames:close();assert(#errors==0,table.concat(errors,'\n'));T.finish('clean intelligence pixels and actual input')
