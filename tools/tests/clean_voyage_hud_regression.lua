-- Exercise every production compact-menu callback; nodes are isolated fixtures.
package.path='bin/res/scripts/?.lua;'..package.path
local H=require 'LuaClass/CleanVoyageHUD'
local handlers={}
local function noop()end
local function node()
 return setmetatable({}, {__index=function(_,key)
  if key=='registerScriptTapHandler' then return function(_,fn)handlers[#handlers+1]=fn end end
  return noop
 end})
end
cc={Node={create=node},LayerColor={create=node},LabelTTF={create=node},MenuItemLabel={create=node},Menu={create=node},
 p=function(x,y)return{x=x,y=y}end,size=function(w,h)return{width=w,height=h}end,c3b=noop,c4b=noop}
screenSize={width=640,height=1200}
local counts={pause=0,hint=0,cargo=0,chart=0,returned=0}
package.loaded['LuaClass/WarmPause']={open=function()counts.pause=counts.pause+1 end}
package.loaded['LuaClass/AdventureSea']={tryEvent=function()counts.hint=counts.hint+1;return true end}
package.loaded['LuaClass/AdventureDialog']={show=function()counts.chart=counts.chart+1 end}
DataManager={getInstance=function()return{}end}
local visible=false
local owner={statue='ready',mapIndex=1,tipLayer=node(),jointed={enable=true},moveWaitingQueue={},moveDirectionQueue={},
 eventManger={layer={isVisible=function()return visible end}},goBag=function()counts.cargo=counts.cargo+1 end,
 adventureReturnButton={item={activate=function()counts.returned=counts.returned+1 end}}}
local view={u=1,node=node()};H.mount(owner,view);assert(#handlers==5,'pause/hint/cargo/chart/return must all be registered')
local function reset()owner.statue='ready';owner.adventureDialog=nil;owner.warmPause=nil;owner.warmSettingsModal=nil;view.animating=false;owner.jointed.enable=true;owner.moveWaitingQueue={};owner.moveDirectionQueue={};owner.eventManger.isMinesweeper=false;visible=false end
local function blocked()
 assert(not H.canAct(owner,view))
 for _,fn in ipairs(handlers)do assert(fn()==false)end
 for _,count in pairs(counts)do assert(count==0,'no original action can fire through an overlay/busy state')end
end
for _,setup in ipairs({
 function()owner.statue='Triggering'end,function()owner.statue='Location'end,
 function()owner.adventureDialog={}end,function()owner.warmPause={}end,function()owner.warmSettingsModal={}end,
 function()view.animating=true end,function()owner.jointed.enable=false end,
 function()owner.moveWaitingQueue={1}end,function()owner.moveDirectionQueue={1}end,
 function()owner.eventManger.isMinesweeper=true end,function()visible=true end})do reset();setup();blocked()end
reset();assert(H.canAct(owner,view));for _,fn in ipairs(handlers)do fn()end
for name,count in pairs(counts)do assert(count==1,name..' must delegate once after dismissal')end
print('PASS all five real compact HUD callbacks block busy/queued/animated/disabled/modal/event states and delegate original actions once when ready')
