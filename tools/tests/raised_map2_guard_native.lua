-- Guard negatives use real Cocos nodes, original controller/model and pixels.
-- Test-only lookup overrides never remove or modify a shipped file or profile.
return function(f)
 local L=require 'LuaClass/RaisedSeaMap2Live'
 local owner=f.seed();local originalHit=require('LuaClass/AdventureSea').isHudPoint
 local parent,actor,fog,meta=owner.map:getParent(),owner.player,owner.fogLayer,owner.meta
 local add=owner.moveLayer.addChild;local visible=owner.tipLayer.setVisible
 local before=f.geometry(owner);local bytes,writes=f.snapshot()
 local function unchanged()
  assert(not owner.raisedMap2Live and owner.map:getParent()==parent)
  assert(owner.player==actor and owner.fogLayer==fog and owner.meta==meta)
  assert(owner.moveLayer.addChild==add and owner.tipLayer.setVisible==visible)
  assert(require('LuaClass/AdventureSea').isHudPoint==originalHit)
  assert(f.geometry(owner)==before)
  local now,count=f.snapshot();assert(now==bytes and count==writes)
 end
 local function rejected(name,reason)
  local ok,why=L.mount(owner);assert(not ok and not owner.raisedMap2Live,name)
  assert(not reason or why:find(reason,1,true),name..':'..tostring(why))
  return why
 end
 RAISED_MAP2_LIVE=nil
 local mode=os.getenv('PIRATE_MAP2_PRESENTATION')
 if mode and mode~='' and mode~='clean' then
  rejected('environment-original','disabled');unchanged();f.capture(owner,'original-environment')
  owner:removeFromParent(true);owner:release();cleanWorldDrain()
  print('PASS guarded environment original route: '..mode);return
 end
 f.capture(owner,'original-reference')
 for i=1,16 do if i~=2 then
  owner.mapIndex=i;rejected('map-'..i,'disabled');owner.mapIndex=2;unchanged()
 end end
 RAISED_MAP2_LIVE=false;rejected('explicit-original','disabled');unchanged();RAISED_MAP2_LIVE=nil
 RAISED_MAP2_LIVE='true';rejected('non-boolean','disabled');unchanged();RAISED_MAP2_LIVE=nil
 local files=cc.FileUtils:getInstance();local nativeExists=files.isFileExist
 local manifest=require('LuaClass/CleanSeaPresentation').gate()
 local paths={manifest.water,manifest.decor,manifest.ship,'fonts/CleanVoyageSans-Regular.ttf'}
 for _,p in pairs(manifest.atlases)do paths[#paths+1]=p end
 for _,p in pairs(manifest.surfaces)do paths[#paths+1]=p end
 for _,d in ipairs({'ne','nw','sw','se'})do paths[#paths+1]='Images/UI/CleanVoyage/boat-clean-'..d..'.png' end
 table.sort(paths)
 for i,path in ipairs(paths)do
  files.isFileExist=function(self,p)if p==path then return false end;return nativeExists(self,p)end
  rejected('missing-art-'..i,'missing-art:');files.isFileExist=nil;unchanged()
  f.capture(owner,'original-missing-art-'..i)
 end
 local getLayer=owner.map.getLayer
 for _,name in ipairs({'Sea','Blocks_1','Blocks_2','Meta','GridLayer','Fogs'})do
  owner.map.getLayer=function(self,key)if key==name then return nil end;return getLayer(self,key)end
  rejected('missing-layer-'..name,'unsupported-layer:');owner.map.getLayer=nil;unchanged()
  f.capture(owner,'original-missing-layer-'..name)
 end
 owner.map.getLayer=function(self,key)if key=='Blocks_2'then return getLayer(self,'Blocks_1')end;return getLayer(self,key)end
 rejected('duplicate-layer','unsupported-layer:');owner.map.getLayer=nil;unchanged()
 local land=getLayer(owner.map,'Blocks_1')
 land.getLayerSize=function()return cc.size(30,31)end
 rejected('layer-bounds','unsupported-layer-bounds:');land.getLayerSize=nil;unchanged()
 land.getPositionX=function()return 1 end
 rejected('layer-offset','unsupported-layer-bounds:');land.getPositionX=nil;unchanged()
 local z=meta:getLocalZOrder();meta.getLocalZOrder=function()return -100 end
 rejected('layer-order','unsupported-layer-order');meta.getLocalZOrder=nil;unchanged()
 local mapSize=owner.map.getMapSize
 owner.map.getMapSize=function()return cc.size(30,31)end
 rejected('grid','unsupported-grid');owner.map.getMapSize=nil;unchanged()
 owner.map.getMapSize=function()return nil end
 rejected('malformed-grid','incompatible-package');owner.map.getMapSize=nil;unchanged()
 owner.meta=fog;rejected('layer-owner','unsupported-layer-owner');owner.meta=meta;unchanged()
 local fogData=owner.fogManager.data;owner.fogManager.data='invalid'
 rejected('model','unsupported-model');owner.fogManager.data=fogData;unchanged()
 local coast=owner.map._seaChartWorldCoast;owner.map._seaChartWorldCoast={groups={'invalid'}}
 rejected('coast','unsupported-coast');owner.map._seaChartWorldCoast=coast;unchanged()
 local bread=owner.bagController.getBreads;owner.bagController.getBreads=function()return 'invalid'end
 rejected('food','unsupported-food');owner.bagController.getBreads=bread;unchanged()
 local requireOriginal=require
 _G.require=function(name)if name=='LuaClass/CleanSeaPresentation'then error('fixture optional package unavailable')end;return requireOriginal(name)end
 rejected('package','incompatible-package');_G.require=requireOriginal;unchanged()
 f.capture(owner,'original-incompatible-package')
 -- Every entry point used during install, refresh, disposal or deferred HUD
 -- callbacks is independently made missing and noncallable. No install runs.
 local contracts={
  {'RaisedSeaMap2',{'build','project','inverse','depth','tilePoint','transform','alphaAt','eventAt'}},
  {'RaisedSeaMap2ObjectsLive',{'create','sync','rebuild','dispose'}},
  {'RaisedSeaMap2Boat',{'create','sync','dispose','heading'}},
  {'RaisedSeaMap2HUD',{'create','sync','dispose','canAct','invalidate','arrowPoints','contains','details'}},
  {'CleanVoyageHUD',{'canAct'}},{'AdventureNavigation',{'query','snapshot','port'}},{'KnownRoute',{'key','inBounds','direction','foodCost','find'}},{'AdventureNavigationView',{'lines'}},
  {'AdventureDialog',{'show'}},{'AdventureProgress',{'getState','showHarborBrief','getHarborStatus'}},{'AdventureSea',{'isHudPoint'}},
  {'WarmTheme',{'panel','label','button','fit','enabled','icon','sprite'}},{'WarmPause',{'open','canOpen','checkpoint'}},{'WarmCollection',{'open'}},{'WarmDialog',{'show'}},{'WarmMemories',{'get','setDisplay','definitions'}},{'WarmActivities',{'open','textPages'}},
  {'CleanSeaPresentation',{'gate'}},{'RaisedSeaObjectPresentation',{'resolve'}},
  {'SeaChartWorldTheme',{'landLayers','familyForLayer','placeMaskTile'}},
 }
 cleanWorldDrain();local _,nativeNodes,nativeListeners=liveBufferCounts();local cases=0
 for _,entry in ipairs(contracts)do
  local module=require('LuaClass/'..entry[1])
  for _,method in ipairs(entry[2])do
   local original=module[method];assert(type(original)=='function')
   for _,kind in ipairs({'missing','noncallable'})do
    if kind=='noncallable'then module[method]=false else module[method]=nil end
    local ok,result,reason=pcall(L.mount,owner)
    module[method]=original
    assert(ok and result==false and reason=='unsupported-api:'..entry[1]..'.'..method,entry[1]..'.'..method)
    unchanged();cleanWorldDrain();local _,nodes,listeners=liveBufferCounts()
    assert(nodes==nativeNodes and listeners==nativeListeners,'API guard changed native lifetime')
    cases=cases+1;f.capture(owner,'original-api-'..cases)
   end
  end
 end
 print('PASS malformed optional APIs: '..cases..' missing/noncallable install, refresh, disposal and deferred entries; exact original ownership/hooks/save/native lifetime')
 local metadataCases=0
 local function metadata(module,key,value)
  local saved=module[key];module[key]=value
  local ok,result,reason=pcall(L.mount,owner);module[key]=saved
  assert(ok and result==false and reason=='unsupported-package-metadata',key..':'..tostring(reason))
  unchanged();cleanWorldDrain();local _,nodes,listeners=liveBufferCounts()
  assert(nodes==nativeNodes and listeners==nativeListeners,'metadata guard changed native lifetime')
  metadataCases=metadataCases+1;f.capture(owner,'original-metadata-'..metadataCases)
 end
 local W=require('LuaClass/WarmTheme');metadata(W,'colors',nil);metadata(W,'colors',false)
 for _,name in ipairs({'ink','navy','paper','coral','sea','muted','line','white','gold'})do
  metadata(W.colors,name,nil);metadata(W.colors,name,{r='bad',g=0,b=0});metadata(W.colors,name,{r=0,g=0,b=256})
 end
 for _,entry in ipairs({{W,'font'},{require('LuaClass/RaisedSeaMap2HUD'),'font'},{require('LuaClass/RaisedSeaMap2Boat'),'path'}})do
  metadata(entry[1],entry[2],nil);metadata(entry[1],entry[2],false);metadata(entry[1],entry[2],'')
 end
 local renderer=require('LuaClass/RaisedSeaMap2')
 for _,field in ipairs({'halfX','halfY','rise'})do
  metadata(renderer,field,nil);metadata(renderer,field,false);metadata(renderer,field,0);metadata(renderer,field,0/0)
 end
 assert(metadataCases==50)
 print('PASS malformed package metadata: '..metadataCases..' palette/font/path/projection cases; exact original ownership/hooks/save/native lifetime')

 assert(L.mount(owner),'default map2 must mount without flag')
 assert(owner.raisedMap2Live and owner.raisedMap2Status=='clean-map2-native-fog')
 assert(f.geometry(owner)==before);local now,count=f.snapshot();assert(now==bytes and count==writes)
 -- Switching off is a runtime-only presentation operation, restoring native
 -- identities/hooks and original camera. No migration or retry loop is added.
 RAISED_MAP2_LIVE=false;assert(not L.refresh(owner));RAISED_MAP2_LIVE=nil;unchanged()
 f.capture(owner,'original-after-unmount')
 for i=1,3 do assert(L.mount(owner));L.unmount(owner);unchanged()end
 f.capture(owner,'original-after-reentry')
 owner:removeFromParent(true);owner:release();cleanWorldDrain()
 print('PASS guarded default map2, other-map refusal, missing art/layer/model/package fallback, original restoration and zero save writes')
end
