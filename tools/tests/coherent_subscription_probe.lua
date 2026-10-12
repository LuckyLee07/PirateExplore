-- Install the real production registration/teardown methods alongside a
-- fixture's economy/event spies. Native handlers and short callback aliases
-- must both disappear: counting only the spy handlers misses retained views.
return function(dm)
 local f=assert(io.open('bin/res/scripts/LuaClass/DataManager.lua','rb'));local source=f:read('*a');f:close()
 local first=assert(source:find('function DataManager:registerEvent',1,true))
 local last=assert(source:find('function DataManager:postEvent',first,true))
 local real=assert(loadstring('local DataManager={}\n'..source:sub(first,last-1)..'\nreturn DataManager','@production-event-lifecycle'))()
 dm.__eventListener={};dm.__eventDispatcher=cc.Node:create():getEventDispatcher()
 local register,unregister=dm.registerEvent,dm.unregisterEvent
 dm.registerEvent=function(self,key,name,callback)
  register(self,key,name,callback);real.registerEvent(self,key,name,callback)
 end
 dm.unregisterEvent=function(self,key,name)
  unregister(self,key,name);real.unregisterEvent(self,key,name)
 end
 return function()
  for key,bucket in pairs(dm.__eventListener)do
   for name in pairs(bucket)do assert(not tostring(name):find('coherent',1,true),'retained coherent callback/native handler '..key..':'..name)end
  end
 end
end
