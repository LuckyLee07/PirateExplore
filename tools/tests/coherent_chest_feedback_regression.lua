-- Whole-file conservation against 3565e7b, excluding exact success-feedback edits only.
local C=dofile('tools/tests/fixtures/chest_feedback_conservation.lua')
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local function checksum(s)local a=0;for i=1,#s do a=(a*131+s:byte(i))%2147483647 end;return a end
for file,kind in pairs({['FightMode.lua']='fight',['ExploreBagController.lua']='bag',['DataManager.lua']='diamond'})do
 local source=read('bin/res/scripts/LuaClass/'..file);assert(loadstring(source))
 local restored=C[kind](source);local wanted=C[kind..'Expected']
 assert(#restored==wanted[1] and checksum(restored)==wanted[2],file..' unchanged outside exact presentation edits')
 -- Adding a gameplay mutation must still fail even when all expected UI edits exist.
 local mutations={fight={'self.openTime = self.openTime+1','self.openTime = self.openTime+2'},
  bag={'self.mapCoin = self.mapCoin + addCoin','self.mapCoin = self.mapCoin + addCoin + 1'},
  diamond={'money = money + _Diamondnum','money = money + _Diamondnum + 1'}}
 local m=mutations[kind];local a,b=assert(source:find(m[1],1,true))
 local corrupted=source:sub(1,a-1)..m[2]..source:sub(b+1)
 assert(checksum(C[kind](corrupted))~=wanted[2],'conservation counterfactual must fail')
 print('PASS '..file..': complete source conserved outside explicit chest feedback lines')
end
