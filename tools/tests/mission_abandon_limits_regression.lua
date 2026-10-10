-- Executes real Mission/MissionManagers and the existing in-memory quest fixture.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local base=read('tools/tests/quest_reward_regression.lua')
local stop=assert(base:find('local passed, failed = 0, 0',1,true))
local checks=[=[
local function eq(a,b,label)assert(a==b,(label or '')..': '..tostring(a)..' ~= '..tostring(b))end
local failures=0
local function check(name,fn)reset();local ok,err=pcall(fn);report((ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..err));if not ok then failures=failures+1 end end
check('abandon immediately invalidates mission and survives map/reload',function()
    local m=add('24','wait',100,1000)
    assert(manager:missionsIsInValidMissions('24'))
    require 'LuaClass/SkirmishLogicManagers'
    local encounters=SkirmishLogicManagers.new();encounters:init()
    local candidate={Type={{'5','24'}}}
    encounters.validEncounters={candidate};encounters:checkValidEncountersByConditions();eq(#encounters.validEncounters,1)
    manager:giveUpTheMission(m)
    encounters.validEncounters={candidate};encounters:checkValidEncountersByConditions();eq(#encounters.validEncounters,0,'next movement immediately rejects abandoned task encounter')
    eq(manager:missionsIsInValidMissions('24'),false,'immediate condition query after abandon')
    assertRemoved('24');manager:checkMissions(1,true);eq(manager:missionsIsInValidMissions('24'),false)
    manager:init();manager:checkMissions(1,true);eq(manager:missionsIsInValidMissions('24'),false,'reload stays abandoned')
end)
-- Diagnostic only: frequency is deducted on acceptance, but the legacy
-- override resets history. Changing it needs a decision on abandon/retry.
for _,saved in ipairs({0,2,false})do
    reset();definition('limited').frequency='3';state[roleCompletedMissionHistory].limited=saved~=false and saved or nil
    manager:triggerMissionByIDAndStepInfos('limited',{},'taskID')
    report('DIAGNOSTIC legacy frequency with history '..(saved==false and 'nil' or tostring(saved))..': accepted='..tostring(manager.missions.limited~=nil)..', remaining='..tostring(state[roleCompletedMissionHistory].limited)..'; unresolved, not a once-only reward guard')
end
check('real mission 24 can be retried, each completed instance rewards once',function()
    local h=read('tools/tests/home_master_regression.lua');local a=assert(h:find('local function readFile(path)',1,true));local b=assert(h:find("\nlocal soldiers=packagedCSV('soilderAttribute')",a,true))
    local csv=assert(loadstring('local equal=...\n'..h:sub(a,b-1)..'\nreturn packagedCSV'))(eq)('task')
    local raw=assert(csv['24']);eq(raw.frequency,'1','actual mission 24 configured frequency')
    local row={};for k,v in pairs(raw)do row[k]=v end
    for _,k in ipairs({'complete','reward','killItems'})do local rows={};for cell in row[k]:gmatch('[^;]+')do local cols={};for v in cell:gmatch('[^_]+')do cols[#cols+1]=v end;rows[#rows+1]=cols end;row[k]=rows end
    tables.quests['24']=row
    manager:triggerMissionByIDAndStepInfos('24',{},'taskID');assert(manager.missions['24'])
    manager:giveUpTheMission(nil,'24');manager:triggerMissionByIDAndStepInfos('24',{},'taskID');local m=assert(manager.missions['24'])
    local received=0;m.receive=function()received=received+1 end -- effect spy; reward dispatch separately covered by quest_reward_regression
    m.statue='complete';manager.completedMissions['24']=m
    manager:tryReceiveMissionRewardsByMissionID('24');manager:tryReceiveMissionRewardsByMissionID('24');eq(received,1);assertRemoved('24')
    manager:triggerMissionByIDAndStepInfos('24',{},'taskID');assert(manager.missions['24'],'legacy history override currently permits a fresh instance');eq(received,1,'reaccept itself cannot pay')
end)
assert(failures==0,tostring(failures)..' mission abandon/limits regression failures')
]=]
assert(loadstring('local read=...\n'..base:sub(1,stop-1)..checks,'@mission-abandon-fixture'))(read)
