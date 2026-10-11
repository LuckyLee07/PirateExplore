local F=dofile('tools/tests/fixtures/warm_upgrade_fixture.lua');local U=require 'LuaClass/WarmUpgrade';local eq=F.equal;local dm=F.dm
local function fail(q,reason)local ok,status=U.confirm(dm,q);eq(ok,false,reason);eq(status,reason,reason)end
local function snapshot()return F.capture()..F.snapshot(F.locked)end
local function current()return dm:getRoleData(rolePackSize)end
local q=U.quote(dm,'1148');eq(q.current,20);eq(q.target,30);eq(q.status,'ready');eq(q.sortId,'6')
eq(q.costs[1].id,'1007');eq(q.costs[1].required,5);eq(q.costs[2].id,'1018');eq(q.costs[2].required,5)
local before,disc=snapshot(),F.disk;U.cancel(q);fail(q,'cancelled');eq(snapshot(),before);eq(F.disk,disc);eq(F.atomic,0);eq(F.normal,0)
-- The full original successful craft is an oracle, including next recipe,
-- original guide flags, hidden crafted item and automatic talent check cadence.
local function original(id,sortId)
 for _,r in ipairs(F.csv[csvOfResourceInfo][id].resume)do assert(dm:addPackItemWithId(r[1],-tonumber(r[2]),false))end
 assert(dm:addPackItemWithId(id,1,false));assert(dm:createSuccessCheck(kUnlockMake,sortId))
end
for _,entry in ipairs({{'1148','6',rolePackSize,30},{'1176','30',roleAlchemyUnit,2}})do
 F.reset();original(entry[1],entry[2]);local originalState=F.capture();local checks=F.checks;local logs=F.snapshot(F.logs)
 F.reset();q=U.quote(dm,entry[1]);assert(U.confirm(dm,q));eq(F.capture(),originalState,'matches complete original craft');eq(F.checks,checks,'original talent check cadence');eq(F.snapshot(F.logs),logs,'original success log')
 eq(dm:getRoleData(entry[3]),entry[4]);eq(F.atomic,1,'single atomic snapshot');eq(F.normal,0,'zero sequential save writes');eq(dm:getPackNumWithId(entry[1]),1)
 local after=F.capture();fail(q,'already_owned');fail(U.quote(dm,entry[1]),'already_owned');eq(F.capture(),after);eq(F.atomic,1)
 local disk=F.disk;dm.__roleData=UserData.new();assert(dm.__roleData:loadData());eq(F.capture(),after,'encrypted JSON cold reload');eq(F.disk,disk)
end
print('PASS exact real-CSV cargo/furnace recipes, original method parity, next recipe + guide + item + talent checks; one atomic save; repeat and reload')
F.reset();q=U.quote(dm,'1148');dm.__roleData:setRoleData(rolePack,{['1007']=4,['1018']=10});before=snapshot();fail(q,'insufficient');eq(snapshot(),before);eq(F.atomic,0)
F.reset();q=U.quote(dm,'1148');dm.__roleData:setRoleData(roleMake,{});before=snapshot();fail(q,'locked');eq(snapshot(),before)
F.reset();q=U.quote(dm,'1148');dm.__roleData:setRoleData(roleGuideStep,'s001');before=snapshot();fail(q,'guide_locked');eq(snapshot(),before)
F.reset();q=U.quote(dm,'1148');dm.__roleData:setRoleData(roleStatue,1);before=snapshot();fail(q,'at_sea');eq(snapshot(),before)
F.reset();q=U.quote(dm,'1148');local row=F.csv[csvOfResourceInfo]['1148'];local cost=row.resume[1][2];row.resume[1][2]='6';before=snapshot();fail(q,'stale_quote');eq(snapshot(),before);row.resume[1][2]=cost
F.reset();q=U.quote(dm,'1148');q.costs[1].required=0;q.target=1000;q.id='1176';assert(U.confirm(dm,q));eq(current(),30,'caller cannot tamper bound quote');eq(dm:getPackNumWithId('1007'),5)
F.reset();dm.__roleData:setRoleData(rolePackSize,80);fail(U.quote(dm,'1148'),'already_owned');eq(current(),80,'never downgrade')
F.reset();dm.__roleData:setRoleData(rolePack,{['1148']=1,['1007']=10,['1018']=10});fail(U.quote(dm,'1148'),'already_owned');eq(current(),20,'corrupt owned-state cannot double charge')
print('PASS cancel, insufficient/stale inventory, revoked recipe/guide, at-sea gate, changed CSV quote, tamper prevention and advanced save')
-- Atomic-save rejection or exception leaves every live role/guide/talent value,
-- observer and success toast unchanged. Retrying the same quote works once.
for _,failure in ipairs({'fail','throw'})do
 F.reset();q=U.quote(dm,'1148');F[failure]=true;before=snapshot();disc=F.disk;local guide=GuideController:getInstance().step
 local getters={DataManager.getInstance,GuideController.getInstance,MissionManagers.getInstance};local toast=ToastUtil
 fail(q,'save_failed');eq(snapshot(),before);eq(F.disk,disc);eq(GuideController:getInstance().step,guide);eq(F.atomic,0);eq(F.normal,0);eq(#F.events,0);eq(#F.logs,0);eq(#F.toasts,0)
 eq(DataManager.getInstance,getters[1]);eq(GuideController.getInstance,getters[2]);eq(MissionManagers.getInstance,getters[3]);eq(ToastUtil,toast)
 F[failure]=false;assert(U.confirm(dm,q));eq(F.atomic,1);eq(current(),30)
end
F.reset();q=U.quote(dm,'1148');local completion=dm.createSuccessCheck;dm.createSuccessCheck=function(self)self:setRoleData(rolePackSize,999);GuideController:getInstance():addStep(999);error('injected completion failure')end
before=snapshot();disc=F.disk;fail(q,'transaction_failed');eq(snapshot(),before);eq(F.disk,disc);eq(F.normal,0);eq(F.atomic,0);eq(#F.events,0);dm.createSuccessCheck=completion;assert(U.confirm(dm,q))
F.reset();q=U.quote(dm,'1148');dm:registerEvent(rolePack,'test',function()fail(q,'already_owned')end);assert(U.confirm(dm,q));eq(F.atomic,1)
print('PASS save false/throw and staging exception rollback; original singleton/guide/toasts restored; safe retry; reentrant observer cannot double-charge')
F.reset({[roleMake]={},[roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=0}}});q=U.quote(dm,'1148');eq(q.status,'prerequisite');eq(#q.prerequisite.costs,3)
for i,v in ipairs({{'1001',25},{'1006',15},{'1008',2}})do eq(q.prerequisite.costs[i].id,v[1]);eq(q.prerequisite.costs[i].required,v[2])end
before=snapshot();fail(q,'prerequisite');eq(snapshot(),before);eq(F.atomic,0)
F.reset();local made=F.csv[csvOfProduce]['6'];made.taskID='8';q=U.quote(dm,'1148');eq(q.status,'unsupported');before=snapshot();fail(q,'unsupported');eq(snapshot(),before);made.taskID=nil
print('PASS exact original forge prerequisite cost; preview is read-only; unsupported new mission contract fails closed')

-- A post-save cache or presentation failure must not turn success into a retry
-- request, leave the global transaction lock set, or block a different recipe.
F.reset();q=U.quote(dm,'1148');local publish=dm.__dynamicData.loadLockedTallent
dm.__dynamicData.loadLockedTallent=function()error('injected volatile-cache observer failure')end
dm:registerEvent(rolePack,'brokenObserver',function()error('injected observer failure')end)
assert(U.confirm(dm,q));eq(F.atomic,1);eq(current(),30);fail(q,'already_owned')
assert(U.confirm(dm,U.quote(dm,'1176')));eq(F.atomic,2);eq(dm:getRoleData(roleAlchemyUnit),2)
dm.__dynamicData.loadLockedTallent=publish
print('PASS postcommit cache/observer exceptions preserve durable success, single debit and availability of another upgrade')

-- Execute the REAL nonempty automatic-talent path with packaged talent 2025.
-- A clearly synthetic achievement row exercises its otherwise optional reward
-- cascade; these rows exist only in this isolated test, never in game assets.
dofile('bin/res/scripts/LuaClass/Utils.lua')
local originalChecks=dm.checkAutoLearnedTallent;dm.checkAutoLearnedTallent=DataManager.checkAutoLearnedTallent
local function talentFixture()
 F.reset({[roleAchievementPoint]=40,[roleMapInfo]={mapIndex=7},
  [roleBonusAttribute]={[10]={['4']={['1']='0'},['2']={['1']='0'}}},
  [roleAchievement]={['fixture']=0},[roleGuideStep]='s001_s010_s060_r102_r002_r401_r402'})
 F.locked={['2025']=F.copy(F.csv[csvOfTalent]['2025'])}
 F.csv[csvOfAchievement].fixture={[dataKeyType]=tostring(achievement_Skill),[dataKeyTotalValue]='2025',
  [dataKeyName]='TEST ONLY cascade',[dataKeyPoint]='1',[dataKeyDiamond]='3'}
end
talentFixture();original('1148','6');local oracle=F.capture();local oracleLocked=F.snapshot(F.locked)
eq(dm:getRoleData(roleTalent)['1'],'2025');eq(dm:getRoleData(roleBonusAttribute)[10]['4']['1'],'40')
eq(dm:getRoleData(roleAchievement).fixture,1);eq(dm:getRoleData(roleDiamond),3);eq(dm:getRoleData(roleAchievementPoint),41)
talentFixture();q=U.quote(dm,'1148');before=snapshot();disc=F.disk;local steps=GuideController:getInstance().step;F.fail=true
fail(q,'save_failed');eq(snapshot(),before,'all talent/bonus/achievement/diamond/lock fields rollback');eq(F.disk,disc)
eq(GuideController:getInstance().step,steps);eq(#F.toasts,0);eq(#F.logs,0);eq(#F.events,0)
F.fail=false;assert(U.confirm(dm,q));eq(F.capture(),oracle,'real nonempty automatic-talent original parity');eq(F.snapshot(F.locked),oracleLocked)
eq(F.atomic,1);eq(F.normal,0);eq(dm:getRoleData(roleDiamond),3);eq(GuideController:getInstance().step,dm:getRoleData(roleGuideStep))
F.csv[csvOfAchievement].fixture=nil;dm.checkAutoLearnedTallent=originalChecks
print('PASS REAL nonempty packaged auto-talent plus controlled bonus/achievement/diamond cascade: exact original parity, rollback and once-only atomic publication')
