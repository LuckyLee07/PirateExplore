-- Pure configuration gate: no engine, profile or save reads are necessary.
local L=assert(loadfile('bin/res/scripts/LuaClass/RaisedSeaMap2Live.lua'))()
local getenv=os.getenv;local mode
os.getenv=function(key)assert(key=='PIRATE_MAP2_PRESENTATION');return mode end
for _,entry in ipairs({{nil,true},{'',true},{'clean',true},{'original',false},{'CLEAN',false},{'typo',false},{'0',false}})do
 mode=entry[1];RAISED_MAP2_LIVE=nil;assert(L.enabled({mapIndex=2})==entry[2]);assert(L.enabled({mapIndex='2'})==entry[2])
 for i=1,16 do if i~=2 then assert(not L.enabled({mapIndex=i}))end end
 RAISED_MAP2_LIVE=true;assert(L.enabled({mapIndex=2}));assert(not L.enabled({mapIndex=3}))
 RAISED_MAP2_LIVE=false;assert(not L.enabled({mapIndex=2}))
 RAISED_MAP2_LIVE='true';assert(not L.enabled({mapIndex=2}))
end
assert(not L.enabled(nil));os.getenv=getenv;RAISED_MAP2_LIVE=nil
print('PASS map2-only default, environment opt-out, unknown-mode fallback and boolean comparison precedence')
