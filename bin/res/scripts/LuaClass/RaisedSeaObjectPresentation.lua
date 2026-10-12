-- Display-only map-object catalog. Never resolve site meaning from a shared GID.
-- IDs/callbacks are independently checked against shipped strongholdAttribute.csv
-- by raised_map2_objects_contract.lua. Original model identity/state is untouched.
local M={version='map2-object-polish-v1',path='Images/UI/CleanSeaObjects/'}
local families={
 port={extent=112,anchorX=140.5/256,callback='',label='start-port'},
 ['world-chart']={extent=68,anchorX=134/256,callback='changeToTeleportLayer',label='world-chart-access'},
 resurrection={extent=60,anchorX=132/256,callback='changeToResurrectionLayer',label='resurrection-point'},
 gateway={extent=76,anchorX=130/256,callback='changeToNextMapEnter',label='next-area-gateway'},
 tavern={extent=90,anchorX=130/256,callback='changeToPubLayer',label='tavern'},
 arena={extent=96,anchorX=130.5/256,callback='changeToArenaLayer',label='arena'},
}
local function family(id)
 if id==3001 then return 'port' end
 if id==3002 then return 'world-chart' end
 if id==3003 then return 'resurrection' end
 if id>=3004 and id<=3019 then return 'tavern' end
 if id>=3036 and id<=3051 then return 'arena' end
 if id==3052 then return 'gateway' end
end
function M.resolve(event)
 local id=event and tonumber(event.id)
 if not id or id%1~=0 then return nil,'missing-exact-site-id' end
 local name=family(id);local item=name and families[name]
 if not item then return nil,'uncovered-site-id' end
 if event.callback~=nil and event.callback~=item.callback then return nil,'site-callback-mismatch' end
 -- GID/occupation/raw state are metadata, never selectors or replacements.
 return {family=name,label=item.label,path=M.path..name..'-v1.png',extent=item.extent,
  scale=item.extent/224,anchorX=item.anchorX,anchorY=.18,contactCenterY=4,contactX=item.extent*.43,
  contactY=item.extent*.14,siteId=event.id,gid=event.gid,state=event.state,
  identitySource=event.identitySource,callback=item.callback}
end
return M
