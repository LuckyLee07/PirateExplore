-- Execute the actual production expiry/removal methods without starting Cocos.
local file=assert(io.open('bin/res/scripts/LuaClass/RandomEventMode.lua','rb'))
local source=file:read('*a');file:close()
RandomEventManager={eventList={},saves=0}
function RandomEventManager:getInstance() return self end
function RandomEventManager:saveEvents() self.saves=self.saves+1 end
RandomEventView={}
local removal=assert(source:match('(function RandomEventManager:removeEvent%(event%).-)\n%s*%-%- RandomEventView'))
assert(loadstring(removal))()
local update=assert(source:match('(function RandomEventView:update%(%)%s+.-)%s*$'))
assert(loadstring(update))()
local clock=os.time;os.time=function()return 1000 end
local tableView={reloads=0}
function tableView:reloadData() assert(self==tableView,'reload must retain native receiver');self.reloads=self.reloads+1 end
local view=setmetatable({tableview1=tableView},{__index=RandomEventView})
local alive={startTime=990,lifeTime=20,reward=7}
local expired={startTime=950,lifeTime=50,reward=9}
local second={startTime=900,lifeTime=90,reward=11}
RandomEventManager.eventList={alive,expired,second}
view:update()
assert(#RandomEventManager.eventList==2 and RandomEventManager.eventList[1]==alive and RandomEventManager.eventList[2]==second)
assert(RandomEventManager.saves==1 and tableView.reloads==1)
view:update()
assert(#RandomEventManager.eventList==1 and RandomEventManager.eventList[1]==alive)
assert(RandomEventManager.saves==2 and tableView.reloads==2)
for i=1,5 do view:update() end
assert(#RandomEventManager.eventList==1 and RandomEventManager.saves==2 and tableView.reloads==2)
assert(alive.startTime==990 and alive.lifeTime==20 and alive.reward==7 and expired.reward==9 and second.reward==11)
os.time=clock
print('PASS actual intelligence expiry/removal methods: correct item removed once, receiver retained, live task and rewards untouched')
