-- A bounded native upgrade transaction for the first cargo/furnace recipes.
-- Prices, effects and cascading unlocks come from the shipped CSV. The original
-- DataManager craft methods run against an isolated synchronous candidate; no
-- observer, guide or live role data is published until its atomic save succeeds.
require 'LuaClass/Header'
local U={}
local quotes=setmetatable({}, {__mode='k'})
local busy=false
local serial=0
local function copy(value,seen)
 if type(value)~='table' then return value end
 seen=seen or {};if seen[value] then return seen[value] end
 local result={};seen[value]=result;for k,v in pairs(value)do result[copy(k,seen)]=copy(v,seen)end;return result
end
local function rows(value)
 if type(value)=='table' then return value end
 local result={};for part in tostring(value or ''):gmatch('[^;]+')do
  local row={};for cell in part:gmatch('[^_]+')do row[#row+1]=cell end;result[#result+1]=row
 end;return result
end
local function find(queue,id)
 for _,row in ipairs(queue or {})do if tostring(row[dataKeyID])==id then return row end end
end
local function token(dm,n,red)
 local step=(red and 'r' or 's')..string.format('%03d',n)
 return ('_'..tostring(dm:getRoleData(roleGuideStep) or '')..'_'):find('_'..step..'_',1,true)~=nil
end
local function integer(n)return type(n)=='number' and n==n and n>=0 and n<9007199254740991 and n%1==0 end
local function spec(id)
 if id=='1148' then return {role=rolePackSize,kind='1',title='货舱改装',unit='格'} end
 if id=='1176' then return {role=roleAlchemyUnit,kind='4',title='炼金炉升级',unit='金币/次'} end
end
local function fingerprint(value)
 if type(value)~='table' then return type(value)..':'..tostring(value) end
 local keys={};for k in pairs(value)do keys[#keys+1]=k end;table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 local parts={};for _,k in ipairs(keys)do parts[#parts+1]=fingerprint(k)..'='..fingerprint(value[k])end;return '{'..table.concat(parts,'|')..'}'
end
local function costs(dm,recipe,resources)
 local out,byId={},{}
 for _,r in ipairs(rows(recipe and recipe.resume))do
  local id=tostring(r[1]);local amount=tonumber(r[2]);if not integer(amount) or amount==0 or not resources[id] then return nil end
  if not byId[id] then local c={id=id,name=resources[id].name or id,required=0};byId[id]=c;out[#out+1]=c end
  byId[id].required=byId[id].required+amount
 end
 if #out==0 then return nil end
 local sufficient=true
 for _,c in ipairs(out)do
  c.have=tonumber(dm:getPackNumWithId(c.id)) or 0
  if not integer(c.have) or not integer(c.required) then return nil end
  c.missing=math.max(0,c.required-c.have);if c.missing>0 then sufficient=false end
 end
 return out,sufficient
end
function U.inspect(dm,goalId)
 local id=tostring(goalId);local s=spec(id);local result={id=id,status='unsupported',costs={}}
 if not s then return result end
 local resources=dm:getCSVByID(csvOfResourceInfo) or {};local recipe=resources[id]
 result.title=s.title;result.unit=s.unit;result.current=tonumber(dm:getRoleData(s.role)) or 0;result.role=s.role
 result.name=recipe and recipe.name or s.title;result.recipe=copy(recipe)
 if not recipe or not integer(result.current) then result.status='invalid';return result end
 for _,effect in ipairs(rows(recipe.raiseType))do if tostring(effect[1])==s.kind then result.target=tonumber(effect[2])end end
 if not integer(result.target) or result.target==0 then result.status='invalid';return result end
 result.costs,result.sufficient=costs(dm,recipe,resources)
 if not result.costs then result.costs={};result.status='invalid';return result end
 if result.current>=result.target or (tonumber(dm:getPackNumWithId(id)) or 0)>0 then result.status='already_owned';return result end
 if tonumber(dm:getRoleData(roleStatue))==1 then result.status='at_sea';return result end
 local unlocked=find(dm:getRoleData(roleMake),id)
 local available=unlocked and tonumber(unlocked[dataKeyNum])
 local produce=dm:getCSVByID(csvOfProduce) or {}
 if unlocked and available and (available==-1 or (integer(available) and available>0)) then
  result.sortId=tostring(unlocked.sortId or '')
  local made=produce[result.sortId]
  if not made or tostring(made.resourceInfoID)~=id then result.status='invalid';return result end
  -- These two shipped rows have no mission hook. Fail closed if future content
  -- changes that contract: a generic mission transaction is intentionally absent.
  if (made.taskID and made.taskID~='0') or (made.taskOk and made.taskOk~='0') then result.status='unsupported';return result end
  result.produce=copy(made)
  if not token(dm,102,true) then result.status='guide_locked';return result end
  result.status=result.sufficient and 'ready' or 'insufficient'
 else
  local forge=find(dm:getRoleData(roleBuilding),'57');local build=(dm:getCSVByID(csvOfBuild) or {})['57']
  if forge and tonumber(forge[dataKeyNum])==0 and build and token(dm,1,false) then
   local forgeCosts,forgeEnough=costs(dm,build,resources)
   if not forgeCosts then result.status='invalid';return result end
   result.status='prerequisite';result.prerequisite={id='57',name='铁匠铺',costs=forgeCosts,sufficient=forgeEnough}
  else result.status='locked' end
 end
 result.signature=fingerprint({id=id,current=result.current,target=result.target,sortId=result.sortId,
  recipe=recipe,produce=result.produce})
 return result
end
function U.quote(dm,goalId)
 local q=U.inspect(dm,goalId)
 quotes[q]={dm=dm,id=q.id,signature=q.signature,cancelled=false,used=false}
 return q
end
function U.cancel(q)local record=quotes[q];if record then record.cancelled=true end end

local function stagedCraft(dm,q)
 if not dm.__roleData or type(dm.__roleData.commitAdventure)~='function' or
    type(dm.addPackItemWithId)~='function' or type(dm.createSuccessCheck)~='function' then return nil,'unavailable' end
 local fields,cache,loaded,events,logs,toasts={},{},{},{},{},{}
 local role={getRoleData=function(_,key)
  if not loaded[key] then cache[key]=copy(dm:getRoleData(key));loaded[key]=true end;return cache[key]
 end,setRoleData=function(_,key,value)cache[key]=value;loaded[key]=true;fields[key]=copy(value)end,saveData=function()end}
 local stage=setmetatable({__roleData=role},{__index=function(_,key)return dm[key]end})
 stage.getRoleData=function(_,key)return role:getRoleData(key)end
 stage.getCSVByID=function(_,key)return dm:getCSVByID(key)end
 stage.postEvent=function(_,key,value)events[key]={value=value}end
 stage.sendSystemInfo=function(_,value)logs[#logs+1]=value end
 local locked=dm.__dynamicData and copy(dm.__dynamicData:getLockedTallent()) or nil
 if dm.__dynamicData then
  stage.__dynamicData=setmetatable({getLockedTallent=function()return locked end},
   {__index=function(_,key)return dm.__dynamicData[key]end})
 end
 local guide=GuideController and GuideController:getInstance()
 if not guide or not MissionManagers then return nil,'unavailable' end
 local stagedGuide=setmetatable({step=tostring(dm:getRoleData(roleGuideStep) or '')},{__index=guide})
 local oldDM,oldGuide,oldMission=DataManager.getInstance,GuideController.getInstance,MissionManagers.getInstance
 local oldToast,oldActId=ToastUtil,rawget(_G,'actId')
 local toastProxy=setmetatable({downString=function(_,value)toasts[#toasts+1]={'downString',value}end,
  toastString=function(_,value)toasts[#toasts+1]={'toastString',value}end},{__index=oldToast})
 -- This block cannot yield or dispatch UI. Restore singleton accessors on every
 -- exit, including a recipe/legacy-method exception, before touching storage.
 DataManager.getInstance=function()return stage end
 GuideController.getInstance=function()return stagedGuide end
 MissionManagers.getInstance=function()return {onTriggerMission=function(_,taskID,taskOk)
  assert((not taskID or taskID=='0') and (not taskOk or taskOk=='0'),'unsupported mission hook')
 end}end
 ToastUtil=toastProxy
 local ok,err=pcall(function()
  for _,c in ipairs(q.costs)do assert(stage:addPackItemWithId(c.id,-c.required,false)~=false,'debit failed')end
  assert(stage:addPackItemWithId(q.id,1,false)~=false,'item failed')
  assert(stage:createSuccessCheck(kUnlockMake,q.sortId)==true,'completion failed')
  assert(tonumber(stage:getRoleData(q.role))==q.target,'effect failed')
 end)
 DataManager.getInstance,GuideController.getInstance,MissionManagers.getInstance=oldDM,oldGuide,oldMission
 ToastUtil=oldToast;actId=oldActId
 if not ok then return nil,'transaction_failed' end
 return {fields=fields,events=events,logs=logs,toasts=toasts,guide=guide,locked=locked}
end
function U.confirm(dm,quote)
 local record=quotes[quote]
 if not record or record.dm~=dm then return false,'invalid_quote' end
 if record.cancelled then return false,'cancelled' end
 if record.used then return false,'already_owned' end
 if busy then return false,'busy' end
 local current=U.inspect(dm,record.id)
 if current.status~='ready' then return false,current.status end
 if current.signature~=record.signature then return false,'stale_quote' end
 busy=true
 local preparedOK,tx,reason=pcall(stagedCraft,dm,current)
 if not preparedOK or not tx then busy=false;return false,reason or 'transaction_failed' end
 local savedOK,saved=pcall(function()return dm.__roleData:commitAdventure(tx.fields)end)
 if not savedOK or saved~=true then busy=false;return false,'save_failed' end
 record.used=true
 -- Durable state is now authoritative. Observer failures cannot re-open this
 -- transaction or charge again. No post-commit exception is reported as a debit failure.
 if tx.fields[roleGuideStep] then tx.guide.step=tx.fields[roleGuideStep] end
 if tx.locked and dm.__dynamicData then pcall(function()dm.__dynamicData:loadLockedTallent(tx.locked)end) end
 for key,event in pairs(tx.events)do pcall(function()dm:postEvent(key,event.value)end)end
 for _,value in ipairs(tx.logs)do pcall(function()dm:sendSystemInfo(value)end)end
 for _,toast in ipairs(tx.toasts)do pcall(function()ToastUtil[toast[1]](ToastUtil,toast[2])end)end
 busy=false
 return true,U.inspect(dm,record.id)
end

local messages={unsupported='这项改装暂不可用',invalid='改装资料暂不可用',at_sea='请先回港，再进行改装',
 already_owned='这项升级已经完成',guide_locked='制造功能尚未开放',locked='继续探索，解锁铁匠铺与制造配方',
 insufficient='材料还没备齐，备好后再来',stale_quote='改装条件已变化，请重新确认',
 save_failed='保存失败，未扣除材料，请重试',transaction_failed='改装未完成，未扣除材料',unavailable='改装暂不可用',cancelled='已取消改装'}
function U.open(owner,goalId)
 if not owner or owner.homeDisposed or owner.warmDisposed or owner.disposed then return nil end
 if owner.warmUpgrade and not owner.warmUpgrade.disposed then return owner.warmUpgrade end
 local W=require 'LuaClass/WarmTheme';local dm=DataManager:getInstance()
 local size=cc.Director:getInstance():getVisibleSize();local scale=math.min(size.width/480,size.height/800)
 local layer=cc.LayerColor:create(cc.c4b(54,42,34,185),size.width,size.height)
 owner:addChild(layer,20000);owner.warmUpgrade=layer;layer.goalId=tostring(goalId)
 local canvas=cc.Node:create();canvas:setContentSize(cc.size(480,800));canvas:setScale(scale)
 canvas:setPosition(cc.p((size.width-480*scale)/2,(size.height-800*scale)/2));layer:addChild(canvas);layer.canvas=canvas
 serial=serial+1;local eventKey='warmUpgrade'..serial
 local eventKeys={rolePack,roleMoney,rolePackSize,roleAlchemyUnit,roleMake,roleBuilding,roleGuideStep,roleStatue}
 local listener=cc.EventListenerTouchOneByOne:create();listener:setSwallowTouches(true)
 listener:registerScriptHandler(function()return not layer.disposed end,cc.Handler.EVENT_TOUCH_BEGAN)
 layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,layer)
 local function dispose()
  if layer.disposed then return end;layer.disposed=true;U.cancel(layer.quote)
  for _,key in ipairs(eventKeys)do
   dm:unregisterEvent(key,eventKey);local bucket=dm.__eventListener and dm.__eventListener[key];if bucket then bucket[eventKey]=nil end
  end
  layer:getEventDispatcher():removeEventListener(listener)
  if owner.warmUpgrade==layer then owner.warmUpgrade=nil end
 end
 function layer:close()if not self.disposed then dispose();self:removeFromParent(true)end end
 layer:registerScriptHandler(function(event)if event=='exit' or event=='cleanup' then dispose()end end)
 local function label(text,font,x,y,width,color,bold)
  local n=W.label(text,font,color or W.colors.ink,x,y,bold,0)
  if width then n:setDimensions(cc.size(width,0));n:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)end
  canvas:addChild(n);return n
 end
 local function button(key,text,x,y,w,action,primary,enabled)
  local generation=layer.generation
  local b=W.button(text,w,54,function()
   if layer.disposed or generation~=layer.generation or layer.committing then return end;action()
  end,{primary=primary,size=21});b:setPosition(cc.p(x,y));canvas:addChild(b)
  b.item:setEnabled(enabled~=false);if enabled==false then b:setOpacity(135)end;layer.buttons[key]=b;return b
 end
 function layer:refresh()
  if self.disposed or self.committing then return end
  U.cancel(self.quote);self.quote=U.quote(dm,self.goalId);local q=self.quote
  self.generation=(self.generation or 0)+1;canvas:removeAllChildren(true);self.buttons={}
  local done=self.success or q.status=='already_owned'
  local panel=W.panel(448,744,W.colors.paper,28);panel:setPosition(cc.p(16,28));canvas:addChild(panel)
  label(done and (self.success and '改装完成！' or '已完成改装') or (q.title or '改装预览'),28,40,738,400,nil,true)
  label(q.id=='1148' and '更宽敞的货舱，带回更多收获' or '在港口提升每次手动炼金收益',17,40,698,400,W.colors.muted)
  -- Keep the effect caption in its own warm-paper row, below the ship
  -- bounds and above the capability text (including at short viewports).
  local art=W.sprite(W.path..'ship-home.png',408,238)
  if art then art:setPosition(cc.p(240,577));canvas:addChild(art)end
  if q.id=='1148' then
   local crate=W.icon('chest',66);crate:setPosition(cc.p(137,483));canvas:addChild(crate)
   label(done and '货舱已扩容' or '新增货舱 · 效果预览',16,40,447,400,W.colors.muted,true)
  else
   local furnace=W.icon('hammer',54)
   if furnace then furnace:setPosition(cc.p(179,515));canvas:addChild(furnace)end
   label(done and '炼金炉已升级' or '炼金炉 · 效果预览',16,40,447,400,W.colors.muted,true)
  end
  local value=(q.current and tostring(q.current) or '—')
  local effect=done and (value..(q.unit or '')) or (value..'  →  '..tostring(q.target or '—')..(q.unit or ''))
  label((q.id=='1148' and '出航储物空间  ' or '每次炼金收益  ')..effect,25,40,416,400,nil,true)
  local list=q.costs or {};local title='本次消耗';local note=self.notice
  if q.status=='prerequisite' then title='先建铁匠铺 · 建造消耗';list=q.prerequisite.costs;note=note or '建成后再来，用原配方改装货舱或炼金炉'
  elseif q.status=='ready' then note=note or '确认后按以上配方消耗材料，并立即完成升级'
  elseif not self.success then note=note or messages[q.status] end
  label(done and '已按原配方完成升级' or title,21,40,362,400,nil,true)
  if done then
   label(q.id=='1148' and ('现在每次出航可使用 '..q.current..' 格货舱。\n回到船上就能看到扩容标记。') or
    ('现在每次手动炼金可获得 '..q.current..' 金币。'),21,40,294,394,W.colors.sea)
  else
   for i,cost in ipairs(list)do
    label(cost.name..' ×'..cost.required,21,44,324-(i-1)*36,232)
    label('已有 '..cost.have..(cost.missing>0 and (' · 缺 '..cost.missing) or ''),17,280,324-(i-1)*36,160,
     cost.missing>0 and W.colors.coral or W.colors.sea)
   end
   label(note or '',17,40,185,400,W.colors.muted)
  end
  if self.success or q.status=='already_owned' then
   button('close','完成',240,88,400,function()self:close()end,true)
  else
   button('cancel','取消',135,88,190,function()self:close()end,false)
   if q.status=='prerequisite' then
    button('confirm','前往建造',345,88,190,function()
     local latest=U.inspect(dm,self.goalId)
     if latest.status~='prerequisite' then self:refresh();return end
     if not zqDispatch or type(zqDispatch.gotoBuild)~='function' then return end
     self:close()
     if owner.kind=='ship' and type(owner.close)=='function' then owner:close()end
     zqDispatch:gotoBuild('57')
    end,true)
   else
    button('confirm','确认改装',345,88,190,function()
     self.committing=true;local ok,result=U.confirm(dm,self.quote);self.committing=false
     if self.disposed then return end
     if ok then self.success=true;self.notice=nil else self.notice=messages[result] or '条件已变化，请重试'end
     self:refresh()
    end,true,q.status=='ready')
   end
  end
 end
 for _,key in ipairs(eventKeys)do dm:registerEvent(key,eventKey,function()layer:refresh()end)end
 layer:refresh();return layer
end
return U
