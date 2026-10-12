local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local realDirector=cc.Director.getInstance
local source=read('tools/tests/coherent_event_pages_native.lua');local stop=assert(source:find('for _,size in ipairs(',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,resources=resources,soldiers=soldiers,reset=function()roles={};black={}end,
 black=function(v)black=v end,grants=function()return #grants+#bagGrants end}
]],'@event-shortage-owner-fixture'))()
local H=F.H;local director=realDirector(cc.Director)
local T=dofile('tools/tests/fixtures/real_shortage_owner_fixture.lua')(H,director)
local errors={};__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
local function fresh(kind)
 H.fixture();F.reset();screenSize=cc.size(480,800);local scene=H.prepare(480,800);H.getData()[roleDiamond]=0;isEnterMap=true
 local rows
 if kind==2 then
  local data=F.soldiers['10002'];rows={{id='10002',name=data.name,icon=data.iconName,costType='2',costs=7,desc=data.desc}}
 else
  local data=F.resources['1005'];rows={{id='1005',name=data.name,icon=data.iconName,costType='2',costs=9,num=1,desc=data.desc,limit=0}};F.black(rows)
 end
 EventDetailsLayer.type=kind;EventDetailsLayer.data=rows
 local page=assert(EventDetailsLayer:create());page:retain();scene:addChild(page);T.enter(scene)
 return scene,page,rows[1]
end
for _,kind in ipairs({2,3})do
 for _,how in ipairs({'remove','close','reload','reselect','scene'})do
  for _,phase in ipairs({'prompt','gift'})do
   if how~='scene'or coherentEventEnter then
    local scene,page,data=fresh(kind);local before=T.writes;local grants=F.grants()
    if kind==2 then page:buyHeroCallBack(data,1);assert(page.adventureDialog).warmOptions[1].item:activate()
    else page:buyItemCallBack(data,1)end
    local prompt,context=T.prompt(page);T.eq(page.adventureDialog,nil,'original confirmation closes without swallowing shortage')
    local gift=phase=='gift'and T.gift(prompt,context)or nil
    T.eq(T.writes,before,'event shortage never debits');T.eq(F.grants(),grants,'event shortage never grants')
    T.expired(scene,page,prompt,context,gift,function()
     if how=='remove'then page:removeFromParent(true)
     elseif how=='close'then page:close()
     elseif how=='reload'then page:reloadDetails()
     elseif how=='reselect'then page:showCellInfo(1)
     else director:replaceScene(cc.Scene:create());for _=1,4 do director:drawScene()end end
    end)
    H.finish();if gift then gift:release()end;prompt:release();page:release()
    print('PASS actual event '..kind..' '..phase..' '..how)
   end
  end
 end
end
for _,kind in ipairs({2,3})do
 local scene,page,data=fresh(kind);H.getData()[roleDiamond]=tonumber(data.costs)
 local before=T.writes;local grants=F.grants()
 if kind==2 then page:buyHeroCallBack(data,1);assert(page.adventureDialog).warmOptions[1].item:activate()
 else page:buyItemCallBack(data,1)end
 T.eq(H.dm:getRoleData(roleDiamond),0,'original exact event price');T.eq(T.writes,before+1,'one original event diamond write');T.eq(F.grants(),grants+1,'one original event grant')
 page:close();H.finish();page:release()
end
assert(#errors==0,table.concat(errors,'\n'));T.finish('actual diamond tavern/black-market shortage owner and generation lifecycle')
cc.Director.getInstance=realDirector
