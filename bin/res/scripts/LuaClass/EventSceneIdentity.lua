-- Scene presentation only. Identity is resolved before artwork: an occupied
-- enemy's GID 48 is NOT the supply point that happens to use that same GID.
local S={path='Images/UI/CleanVoyage/'}
local exact={
 ['3108']={family='changeToEnemyLayer',kind='boarding',enemy='10001'},
 ['3004']={family='changeToPubLayer',kind='tavern',prop='Events/tavern-pontoon-clean-v1.png'},
 ['3053']={family='changeToSupplyPoint',kind='supply',prop='Events/bread-supply-raft-clean-v1.png'},
 ['3067']={family='changeToMaterialsLayer',kind='resource',prop='event-quarry-raft-clean-v1.png'},
 ['3068']={family='changeToMaterialsLayer',kind='resource',prop='event-iron-raft-clean-v1.png'},
 ['3070']={family='changeToMaterialsLayer',kind='resource',prop='event-timber-raft-clean-v1.png'}
}
-- Explicit IDs audited from the immutable packaged table, not an art GID.
local function allow(ids,family,kind,prop,backdrop)
 for _,id in ipairs(ids)do exact[tostring(id)]={family=family,kind=kind,prop='Events/'..prop,backdrop=backdrop}end
end
allow({3004,3005,3006,3007,3008,3009,3010,3011,3012,3013,3014,3015,3016,3017,3018,3019},'changeToPubLayer','tavern','tavern-pontoon-clean-v1.png')
allow({3020,3021,3022,3023,3024,3025,3026,3027,3028,3029,3030,3031,3032,3033,3034,3035},'changeToBlackMarket','blackmarket','blackmarket-pontoon-clean-v2.png')
allow({3036,3037,3038,3039,3040,3041,3042,3043,3044,3045,3046,3047,3048,3049,3050,3051},'changeToArenaLayer','arena','arena-ring-clean-v2.png','neutral')
allow({3003},'changeToResurrectionLayer','resurrection','resurrection-memorial-clean-v2.png','neutral')
allow({3052},'changeToNextMapEnter','nextsea','nextsea-gateway-clean-v2.png')
allow({3002},'changeToTeleportLayer','worldchart','worldchart-table-clean-v2.png','neutral')
allow({3074},'changeToEternalArena','eternalarena','eternal-arena-clean-v2.png','neutral')
function S.status(model)
 if not model then return nil end
 if model.occupied and (model.kind=='boarding' or model.kind=='resource')then return '已占领','查看这里的近况' end
 local states={boarding={'敌人登船','准备战斗'},resource={'发现资源','准备好后继续探索'},
  supply={'发现补给','查看物资后领取'},tavern={'抵达酒馆','招募的战士会返回基地'},
  blackmarket={'抵达黑市','进入后查看货品和价格'},resurrection={'抵达复活点','复活已经牺牲的战士'},
  worldchart={'世界海图','前往已经通过的海域'},arena={'进入竞技场','完整通关后获得奖励'},
  eternalarena={'永恒竞技场','选择起始层数'}}
 if model.kind=='nextsea'then
  return model.occupied and '下一海域已开启' or '抵达传送点',model.occupied and '前往下一海域' or '战胜驻守敌人后开启'
 end
 local pair=states[model.kind];return pair and pair[1],pair and pair[2]
end
function S.resolve(info,occupied,fighter)
 local rule=info and exact[tostring(info.ID)]
 if not rule or rule.family~=info.eventFucString then return nil end
 local model={id=tostring(info.ID),kind=rule.kind,prop=rule.prop,backdrop=rule.backdrop,occupied=occupied==true}
 if rule.kind=='boarding' and not occupied then
  -- At this exact site the original single enemy is unambiguous. Once the
  -- controller prepares a fighter, only its actual ID may select the body.
  local id=fighter and tostring(fighter.soilderId) or tostring(info.enemys)
  if id==rule.enemy then model.actor='Combat/Actors/body-10001-v2.png';model.enemy=id end
 end
 model.identity='stronghold:'..model.id..':'..model.kind..':'..(model.occupied and 'occupied' or 'open')
 return model
end
function S.summary(info,model)
 if not model then return '' end
 if model.kind=='tavern' then
  local rows=info.Carryitems;local parts={}
  if type(rows)=='table' then for _,row in ipairs(rows)do
   local name=dataController.getSoilderValueByIdAndKey(row[2],'name')
   local currency=tostring(row[1])=='1' and '金币' or (tostring(row[1])=='2' and '钻石' or nil)
   if name and currency and tonumber(row[3])then parts[#parts+1]=name..' · '..currency..' '..tostring(row[3])end
  end end
  return table.concat(parts,'\n')
 elseif model.kind=='supply' then
  local manager=ExploreBagController and ExploreBagController:getBagController();local parts={}
  for _,row in ipairs(manager and manager.breads or {})do
   local name=dataController.getResourceValueByIdAndKey(row.id,'name')
   if name and tonumber(row.num)then parts[#parts+1]=name..' × '..tostring(row.num)end
  end
  return table.concat(parts,' · ')
 end
 return ''
end
function S.paint(root,model,w,h,W)
 root:removeAllChildren();root:setContentSize(cc.size(w,h))
 -- Full rectangles receive explicit depths. Cocos visit resets arrival order,
 -- so equal-z insertion ordering cannot protect backgrounds after new children.
 if model.backdrop=='neutral'then
  -- A nongeographic display field is deliberate: a grave, chart or arena prop
  -- must not assert a new island/location in the game's authored geography.
  root:addChild(W.panel(w,h,cc.c3b(218,239,233),0),-30)
 else
  local sea=W.cover(S.path..'sea-turquoise-caustics.png',w,h)
  if sea then root:addChild(sea,-30)end
 end
 if model.kind=='boarding' then
  local deck=W.cover(S.path..'Combat/boarding-deck-clean-v1.png',w,h)
  if deck then root:addChild(deck,-20)end
  if model.actor then
   local actor=W.sprite(S.path..model.actor,w*.64,h*.92)
   if actor then actor:setAnchorPoint(cc.p(.5,0));actor:setPosition(cc.p(w*.53,h*.015));root:addChild(actor,5)end
  end
 else
  local prop=W.sprite(S.path..model.prop,w*.80,h*.90)
  if prop then prop:setPosition(cc.p(w*.5,h*.5));root:addChild(prop,5)end
 end
end
return S
