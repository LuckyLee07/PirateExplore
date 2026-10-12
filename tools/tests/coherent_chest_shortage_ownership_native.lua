local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/coherent_loot_pages_native.lua');local stop=assert(source:find('local taskId',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,reset=reset,errors=callbackErrors,restore=function()cc.UserDefault.getInstance=realUserDefault end}
]],'@chest-shortage-owner-fixture'))()
local H=F.H;local director=H.realGet(cc.Director)
local T=dofile('tools/tests/fixtures/real_shortage_owner_fixture.lua')(H,director)
for _,route in ipairs({'retry','continue'})do
 for _,how in ipairs({'remove','reload','giveup','scene'})do
  for _,phase in ipairs({'prompt','gift'})do
   if how~='scene'or coherentEventEnter then
    F.reset(20,0,{});local scene=H.prepare(480,800);H.getData()[roleDiamond]=0;isEnterMap=true
    local chest=assert(FightBoxView:create());chest:retain();chest:show();chest:stopAllActions();chest:setScale(1);T.enter(scene)
    local alert;local before=T.writes
    if route=='retry'then chest.isFail=true;chest.failTime=1;chest.chestButtons[1]:activate()
    else alert=assert(FightBoxViewAlert:create());alert:retain();alert:show();alert.coherentAlertPaid.item:activate()end
    local prompt,context=T.prompt(chest);local gift=phase=='gift'and T.gift(prompt,context)or nil
    T.eq(T.writes,before,'chest shortage never debits');T.eq(chest.openTimeTotal,0,'shortage never opens chest')
    T.expired(scene,chest,prompt,context,gift,function()
     if how=='remove'then chest:removeFromParent(true)
     elseif how=='reload'then chest:reloadBoxes()
     elseif how=='giveup'then chest:giveUpCallback()
     else director:replaceScene(cc.Scene:create());for _=1,4 do director:drawScene()end end
    end)
    H.finish();if gift then gift:release()end;if alert then alert:release()end;prompt:release();chest:release()
    print('PASS actual chest '..route..' '..phase..' '..how)
   end
  end
 end
end
for _,route in ipairs({'retry','continue'})do
 F.reset(20,0,{});local scene=H.prepare(480,800);local cost=route=='retry'and 2 or 7;H.getData()[roleDiamond]=cost;isEnterMap=true
 local chest=FightBoxView:create();chest:retain();chest:show();T.enter(scene);local before=T.writes
 local alert
 if route=='retry'then chest.isFail=true;chest.failTime=1;chest.rewardRate={0,0,0};chest.chestButtons[1]:activate()
 else alert=FightBoxViewAlert:create();alert:retain();alert:show();alert.coherentAlertPaid.item:activate()end
 T.eq(H.getData()[roleDiamond],0,'original exact chest price');T.eq(T.writes,before+1,'one original chest debit')
 H.finish();if alert then alert:release()end;chest:release()
end
assert(#F.errors==0,table.concat(F.errors,'\n'));T.finish('actual chest retry and seven-diamond continuation shortage lifecycle');F.restore();cc.Director.getInstance=H.realGet
