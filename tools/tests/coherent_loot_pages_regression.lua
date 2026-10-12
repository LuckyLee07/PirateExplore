-- Counterfactual for the exact production settlement boundary: the guard must
-- cover synchronous role-state listeners and the original completion callback.
local f=assert(io.open('bin/res/scripts/LuaClass/FightMode.lua','rb'));local source=f:read('*a');f:close()
local method=source:sub((assert(source:find('function FightRewardScene:settleCargo()',1,true))))
local function run(code)
 FightRewardScene={};roleBattlePack='battlePack'
 local writes,callbacks=0,0;local order={};local view
 DataManager={getInstance=function()return{
  getCSVByID=function()return{}end,
  setRoleData=function(_,key,value)
   writes=writes+1;order[#order+1]='write'
   if writes==1 then view:settleCargo()end
  end
 }end}
 ToastUtil={downString=function()error('no mission items in this exact-once fixture')end}
 assert(loadstring('local changeListItemNum=function()end\n'..code,'@production-cargo-commit'))()
 view=setmetatable({package={},rewardItems={},reservedItems={},fightResult=false,isClosed=false},{__index=FightRewardScene})
 view.fightOverCallback=function(result)
  assert(result==false,'ordinary event result stays false');callbacks=callbacks+1;order[#order+1]='callback'
  if callbacks==1 then view:settleCargo()end
 end
 view:settleCargo();view:settleCargo()
 return writes,callbacks,table.concat(order,',')
end
local writes,callbacks,order=run(method)
assert(writes==1 and callbacks==1 and order=='write,callback','commit occurs once before original completion')
local counterfactual=method:gsub(' or self%.cargoCommitInProgress','',1)
local badWrites,badCallbacks=run(counterfactual)
assert(badWrites>1 and badCallbacks>1,'counterfactual proves removed guard reopens the original transaction')
assert(source:find('if rawget(_G, \'WARM_PIRATE_V1\') ~= false then\n        return self:initCoherentCargo()',1,true),'legacy cargo opt-out retained')
assert(source:find("if rawget(_G, 'WARM_PIRATE_V1') ~= false then return self:initCoherentChest() end",1,true),'legacy chest opt-out retained')
print('PASS coherent loot production settlement counterfactual: unguarded reentry duplicates; actual write/callback each run once with false event result')
