-- Versioned adventure ledger. Absent ledger means a legacy save: never infer a
-- new-game grant from guide steps, map index, or missing buildings.
local A = { KEY = 'adventureProgressV1', VERSION = 1 }
local function copy(t)
    if type(t)~='table' then return t end
    local out={};for k,v in pairs(t) do out[k]=copy(v) end;return out
end
local function step(s,n,red)
    local token=(red and 'r' or 's')..string.format('%03d',n)
    if not ('_'..(s or '')..'_'):find('_'..token..'_',1,true) then return (s and s~='' and s..'_' or '')..token end
    return s
end
local function rows(v)
    if type(v)=='table' then return v end
    local out={};for r in tostring(v or ''):gmatch('[^;]+') do local row={};for x in r:gmatch('[^_]+') do row[#row+1]=x end;out[#out+1]=row end;return out
end
function A.getState(dm)
    local s=dm:getRoleData(A.KEY)
    if type(s)~='table' or s.version~=A.VERSION then return {enabled=false} end
    return copy(s)
end
function A.commit(dm,fields)
    if not dm.__roleData or not dm.__roleData:commitAdventure(fields) then return false,'save_failed' end
    if fields[roleGuideStep] and GuideController and GuideController.instance then GuideController.instance.step=fields[roleGuideStep] end
    for k in pairs(fields) do dm:postEvent(k,nil) end
    return true
end
-- Called exclusively inside DataManager's confirmed empty-role initialization.
-- Completed buildings retain their actual counts. The next house is waiting;
-- only completed buildings activate CSV effects, never waiting ones.
function A.initializeNewRole(user,dm)
    local buildings,store,workers={},copy(user:getRoleData(roleStore) or {}),{}
    local built={['1']=true,['2']=true,['53']=true,['56']=true}
    local pending={};local population=0
    local buildCSV=dm:getCSVByID(csvOfBuild);local stores=dm:getCSVByID(csvOfStore);local resources=dm:getCSVByID(csvOfResourceInfo)
    local function addStore(id)
        for _,r in ipairs(store) do if tostring(r.sortId)==id then return end end
        local r=assert(stores[id]);store[#store+1]={[dataKeyID]=r.resourceInfoID,[dataKeyNum]=resources[r.resourceInfoID].limits,sortId=id,S=1}
    end
    for _,id in ipairs({'1','2','53','56'}) do
        for _,r in ipairs(rows(assert(buildCSV[id]).activateID)) do
            if tostring(r[1])=='2' then pending[tostring(r[2])]=true
            elseif tostring(r[1])=='3' then addStore(tostring(r[2]))
            elseif tostring(r[1])=='5' then population=tonumber(r[2]) or population
            elseif tostring(r[1])=='4' then workers[#workers+1]={[dataKeyID]=tostring(r[2]),[dataKeyNum]='0'} end
        end
    end
    for id in pairs(pending) do if not built[id] then buildings[#buildings+1]={[dataKeyID]=id,[dataKeyNum]=0,S=1} end end
    table.sort(buildings,function(a,b)return tonumber(a[dataKeyID])<tonumber(b[dataKeyID]) end)
    for _,id in ipairs({'56','53','2','1'}) do buildings[#buildings+1]={[dataKeyID]=id,[dataKeyNum]=1} end
    local guide=user:getRoleData(roleGuideStep) or ''
    for _,n in ipairs({1,2,3,5,8}) do guide=step(guide,n) end
    local fields={ [A.KEY]={version=1,enabled=true,objective='rescue',voyage=0,firstReturnClaimed=false,npcRescued=false},
        [roleBuilding]=buildings,[roleStore]=store,[roleProducerQueue]=workers,[roleLivingUnitNum]=population,[roleGuideStep]=guide }
    return user:commitAdventure(fields)
end
function A.setObjective(dm,objective)
    if objective~='rescue' and objective~='supply' then return false,'invalid_objective' end
    local s=A.getState(dm);if not s.enabled then return false,'legacy' end
    s.objective=objective;return A.commit(dm,{[A.KEY]=s})
end
-- The original gift, with its original amount and step, now commits as one unit.
function A.claimStarter(dm)
    local s=A.getState(dm);if not s.enabled then return false,'legacy' end
    local guide=dm:getRoleData(roleGuideStep) or ''
    if ('_'..guide..'_'):find('_r030_',1,true) then return false,'claimed' end
    local pack=copy(dm:getRoleData(rolePack) or {});local crew=copy(dm:getRoleData(roleSoildierQueue) or {})
    pack['1005']=(tonumber(pack['1005']) or 0)+100
    crew['100']=crew['100'] or {[dataKeyID]='100',[dataKeyNum]=0}
    crew['100'][dataKeyNum]=(tonumber(crew['100'][dataKeyNum]) or 0)+1
    return A.commit(dm,{[rolePack]=pack,[roleSoildierQueue]=crew,[roleGuideStep]=step(guide,30,true)})
end
function A.beginVoyage(dm)
    local s=A.getState(dm);if not s.enabled then return true end
    if s.activeVoyage then return false,'voyage_active' end
    s.voyage=(s.voyage or 0)+1;s.activeVoyage=s.voyage;s.pending=nil
    return A.commit(dm,{[A.KEY]=s})
end
function A.depart(dm,selected)
    local s=A.getState(dm);if not s.enabled then return false,'legacy' end
    if s.activeVoyage then return false,'voyage_active' end
    local pack=copy(dm:getRoleData(rolePack) or {});local crew=copy(dm:getRoleData(roleSoildierQueue) or {})
    local battle,party={},{};local food,people=0,0
    for key,value in pairs(selected or {}) do
        local num=tonumber(value) or 0
        if num>0 then
            if num%1~=0 then return false,'invalid_selection' end
            if tonumber(key)>=10000 then
                local id=tostring(tonumber(key)-10000)
                if (tonumber((crew[id] or {})[dataKeyNum]) or 0)<num then return false,'insufficient' end
                crew[id][dataKeyNum]=crew[id][dataKeyNum]-num
                if crew[id][dataKeyNum]==0 then crew[id]=nil end
                party[id]=num;people=people+num
            else
                local id=tostring(key)
                if (tonumber(pack[id]) or 0)<num then return false,'insufficient' end
                pack[id]=pack[id]-num;battle[id]={id=id,num=num};if id=='1005' then food=num end
            end
        end
    end
    if food<1 or people<1 or people>(tonumber(dm:getRoleData(roleCabinSize)) or 1) then return false,'invalid_selection' end
    if A.capacity(dm,battle)>(tonumber(dm:getRoleData(rolePackSize)) or 0) then return false,'cargo_full' end
    s.voyage=(s.voyage or 0)+1;s.activeVoyage=s.voyage;s.pending=nil
    return A.commit(dm,{[A.KEY]=s,[rolePack]=pack,[roleSoildierQueue]=crew,[roleBattlePack]=battle,[roleBattleQueue]=party,[roleSelectUnit]={},[roleStatue]=1})
end
-- Read-only quote for the existing return button. Rechecked at confirmation;
-- a stale offer never silently switches from a scroll to a diamond charge.
function A.quoteReturn(dm,mapIndex)
    local map=dm:getRoleData(roleMapInfo) or {}
    mapIndex=tonumber(mapIndex or map.curIndex or map.mapIndex or 1)
    local current=tonumber(map.curIndex or map.mapIndex)
    if current and current~=mapIndex then return nil,'return_map_changed' end
    if not map.fristReturnBaseByTool then return {kind='free',mapIndex=mapIndex} end
    local areas=dm:getCSVByID(csvOfStrongholdDistribution) or {}
    local home=rows((areas[tostring(mapIndex)] or {}).gohome)[1]
    if not home then return nil,'return_unavailable' end
    local id=tostring(home[1]);local count=tonumber(home[2])
    if not count or count<1 or count%1~=0 then return nil,'invalid_return_cost' end
    local resources=dm:getCSVByID(csvOfResourceInfo) or {};local resource=resources[id] or {}
    local cargo=dm:getRoleData(roleBattlePack) or {};local stock=dm:getRoleData(rolePack) or {}
    local available=tonumber((cargo[id] or {}).num) or 0
    if tostring(resource.carryType)=='2' then available=available+(tonumber(stock[id]) or 0) end
    if available>=count then return {kind='scroll',mapIndex=mapIndex,toolId=id,count=count} end
    local offer=(dm:getCSVByID(csvOfShopItem) or {})[tostring(resource.shop_connect)]
    local price=offer and tonumber(offer.price)
    if not price or price<0 or price%1~=0 then return nil,'return_unavailable' end
    return {kind='diamond',mapIndex=mapIndex,toolId=id,count=count,price=price}
end
-- Successful return is a single role snapshot, including the original cargo,
-- crew, map coins and first-return award. Re-entry cannot deposit them twice.
function A.returnVoyage(dm,statue,returnRequest)
    if statue=='Killed' or statue=='NoBread' then return false,'failed_voyage' end
    local s=A.getState(dm);if not s.enabled then return false,'legacy' end
    if not s.activeVoyage then return true,false end
    local cargo=copy(dm:getRoleData(roleBattlePack) or {})
    local pack=copy(dm:getRoleData(rolePack) or {});local crew=copy(dm:getRoleData(roleSoildierQueue) or {})
    local selected={};local resources=dm:getCSVByID(csvOfResourceInfo) or {}
    local money=tonumber(dm:getRoleData(roleMoney)) or 0
    local diamonds=tonumber(dm:getRoleData(roleDiamond)) or 0
    local map=copy(dm:getRoleData(roleMapInfo) or {})
    if returnRequest then
        local quote,reason=A.quoteReturn(dm,returnRequest.mapIndex)
        if not quote then return false,reason end
        for _,key in ipairs({'kind','mapIndex','toolId','count','price'}) do
            if quote[key]~=returnRequest[key] then return false,'return_offer_changed' end
        end
        if quote.kind=='free' then map.fristReturnBaseByTool='1'
        elseif quote.kind=='scroll' then
            local id=quote.toolId;local atSea=math.min(tonumber((cargo[id] or {}).num) or 0,quote.count)
            if atSea>0 then cargo[id].num=cargo[id].num-atSea;if cargo[id].num==0 then cargo[id]=nil end end
            local remaining=quote.count-atSea
            if remaining>0 then pack[id]=(tonumber(pack[id]) or 0)-remaining;if pack[id]==0 then pack[id]=nil end end
        elseif quote.kind=='diamond' then
            if diamonds<quote.price then return false,'insufficient_diamonds' end
            diamonds=diamonds-quote.price
        else return false,'invalid_return_kind' end
    end
    local alive=0;for _,num in pairs(dm:getRoleData(roleBattleQueue) or {}) do alive=alive+(tonumber(num) or 0) end
    if alive<1 then return false,'no_survivors' end
    for id,v in pairs(cargo) do
        local num=tonumber(v.num) or 0
        if num>0 then
            if id=='1001' then money=money+num elseif id=='1002' then diamonds=diamonds+num else pack[id]=(tonumber(pack[id]) or 0)+num end
            if tostring((resources[id] or {}).carryType)=='1' then selected[id]=num end
        end
    end
    for id,num in pairs(dm:getRoleData(roleBattleQueue) or {}) do
        if num>0 then
            crew[id]=crew[id] or {[dataKeyID]=id,[dataKeyNum]=0}
            crew[id][dataKeyNum]=(tonumber(crew[id][dataKeyNum]) or 0)+num
            selected[tostring(tonumber(id)+10000)]=num
        end
    end
    if not statue then money=money+(tonumber(dm:getRoleData(roleMapCoin)) or 0) end
    if s.pending and s.pending.voyage==s.activeVoyage then
        if s.pending.episode=='crew' then s.followupReturned=true;s.followupAction=s.pending.action;s.chartRecovered=s.pending.choice=='chart'
        else s.firstEventReturned=true;s.npcRescued=s.pending.choice=='rescue';s.choice=s.pending.choice end
    end
    s.returnedIron=tonumber((cargo['1008'] or {}).num) or 0
    local awarded=s.firstEventReturned and not s.firstReturnClaimed and s.returnedIron>=2
    if awarded then
        s.firstReturnClaimed=true
        money=money+25
        for id,num in pairs({['1006']=15,['1007']=5,['1018']=5}) do pack[id]=(tonumber(pack[id]) or 0)+num end
    end
    s.pending=nil;s.activeVoyage=nil
    map.playerTitlePosition=nil
    local restrictions=copy(dm:getRoleData(roleBlackMarketRestrictions) or {});restrictions.tempRestrictions=nil
    local fields={[roleBlackMarketRestrictions]=restrictions,[roleTempReceivedDatas]={},[A.KEY]=s,[rolePack]=pack,[roleMoney]=money,[roleDiamond]=diamonds,[roleSoildierQueue]=crew,
        [roleBattlePack]={},[roleBattleQueue]={},[roleSelectUnit]=selected,[roleMapCoin]=0,
        [roleStatue]=0,[roleBreadCostDecimal]=0,[roleMapInfo]=map,
        [roleGuideStep]=step(dm:getRoleData(roleGuideStep) or '',60)}
    local ok,err=A.commit(dm,fields);return ok,ok and awarded or err
end
function A.setTutorialPoint(dm,point)
    local s=A.getState(dm);if not s.enabled or s.tutorialPoint or not point then return false end
    s.tutorialPoint={x=point.x,y=point.y,mapIndex=1}
    s.tutorialPath=copy(point.path or {})
    return A.commit(dm,{[A.KEY]=s})
end
function A.isTutorialProtected(dm,mapIndex,position)
    local s=A.getState(dm)
    if not s.enabled or s.voyage~=1 or s.activeVoyage~=1 or tonumber(mapIndex)~=1 or not position then return false end
    for _,p in ipairs(s.tutorialPath or {}) do if p.x==position.x and p.y==position.y then return true end end
    return false
end
function A.setGateClue(dm,clue)
    local s=A.getState(dm);if not s.enabled or type(clue)~='string' or clue==s.gateClue then return false end
    s.gateClue=clue;return A.commit(dm,{[A.KEY]=s})
end
function A.capacity(dm,pack)
    local total=0;local resources=dm:getCSVByID(csvOfResourceInfo) or {}
    for id,v in pairs(pack or {}) do total=total+(tonumber(v.num) or 0)*(tonumber((resources[tostring(id)] or {}).cubage) or 0) end
    return total
end
function A.availableEpisode(dm)
    local s=A.getState(dm)
    if not s.enabled or s.pending then return nil end
    if not s.firstEventReturned then return 'first' end
    if not s.followupReturned and (tonumber(dm:getRoleData(rolePackSize)) or 0)>=30 then return 'crew' end
    return nil
end
function A.eventOptions(dm)
    local crew=dm:getRoleData(roleBattleQueue) or {}
    local followup=A.getState(dm).firstEventReturned
    if followup then return {
        {id='rescue',label='基础：整理残骸航图',cost=3,rewards={['1008']=2,['1017']=8},choice='chart',detail='耗3粮｜2铁8皮｜返港得章门方位'},
        {id='supply',label='基础：回收散落货物',cost=0,rewards={['1008']=6,['1007']=6},choice='supplies',detail='耗0粮｜6铁6木｜补首职业装备材料'},
        {id='sailor',label='水手：辨认残骸航图',cost=1,rewards={['1008']=3,['1017']=12},choice='chart',requires='101',enabled=(tonumber(crew['101']) or 0)>0,detail='需水手｜耗1粮｜3铁12皮｜返港得方位'},
        {id='knife',label='刀手：拆开加固货箱',cost=0,rewards={['1008']=8,['1007']=8},choice='supplies',requires='112',enabled=(tonumber(crew['112']) or 0)>0,detail='需刀手｜耗0粮｜8铁8木｜不取航图'}
    } end
    return {
        {id='rescue',label='先救人',cost=3,rewards={['1008']=2},choice='rescue',detail='耗3粮｜2铁｜返港后林恩留下'},
        {id='supply',label='先抢救材料',cost=0,rewards={['1008']=2,['1007']=2},choice='supply',detail='耗0粮｜2铁2木｜放弃本次救援'},
        {id='sailor',label='水手：支稳舷梯救人',cost=1,rewards={['1008']=2},choice='rescue',requires='101',enabled=(tonumber(crew['101']) or 0)>0,detail='需水手｜耗1粮｜2铁｜返港后林恩留下'},
        {id='knife',label='刀手：切开缆网取货',cost=0,rewards={['1008']=2,['1007']=4},choice='supply',requires='112',enabled=(tonumber(crew['112']) or 0)>0,detail='需刀手｜耗0粮｜2铁4木｜放弃救援'}
    }
end
function A.resolveEvent(dm,id)
    local s=A.getState(dm)
    local episode=A.availableEpisode(dm)
    if not s.enabled or not s.activeVoyage or not episode then return false,'unavailable' end
    local option;for _,o in ipairs(A.eventOptions(dm)) do if o.id==id then option=o end end
    if not option then return false,'invalid_choice' end
    if option.requires and not option.enabled then return false,'crew_required' end
    local pack=copy(dm:getRoleData(roleBattlePack) or {});local food=tonumber((pack['1005'] or {}).num) or 0
    if food<option.cost then return false,'food_required' end
    if option.cost>0 then pack['1005'].num=food-option.cost;if pack['1005'].num==0 then pack['1005']=nil end end
    for item,num in pairs(option.rewards) do pack[item]=pack[item] or {id=item,num=0};pack[item].num=pack[item].num+num end
    if A.capacity(dm,pack)>(tonumber(dm:getRoleData(rolePackSize)) or 0) then return false,'cargo_full' end
    s.pending={voyage=s.activeVoyage,choice=option.choice,action=id,episode=episode}
    if episode=='first' then s.choice=option.choice end
    local buildings=copy(dm:getRoleData(roleBuilding) or {});local found=false
    for _,b in ipairs(buildings) do if tostring(b[dataKeyID])=='57' then found=true end end
    if not found then table.insert(buildings,1,{[dataKeyID]='57',[dataKeyNum]=0,S=1}) end
    return A.commit(dm,{[A.KEY]=s,[roleBattlePack]=pack,[roleBuilding]=buildings})
end
-- New-mode death preserves the original losses and mission-item exceptions
-- while storing the revival record, sea cleanup and ledger together.
function A.failVoyage(dm,deathInformation)
    local s=A.getState(dm);if not s.enabled then return false,'legacy' end
    if not s.activeVoyage then return true end
    s.pending=nil;s.activeVoyage=nil
    local map=copy(dm:getRoleData(roleMapInfo) or {});map.playerTitlePosition=nil;map.willFight=nil
    local restrictions=copy(dm:getRoleData(roleBlackMarketRestrictions) or {});restrictions.tempRestrictions=nil
    local pack=copy(dm:getRoleData(rolePack) or {})
    local money=tonumber(dm:getRoleData(roleMoney)) or 0
    local diamonds=tonumber(dm:getRoleData(roleDiamond)) or 0
    local resources=dm:getCSVByID(csvOfResourceInfo) or {}
    for id,v in pairs(dm:getRoleData(roleBattlePack) or {}) do
        local num=tonumber(v.num) or 0
        if num>0 and tostring((resources[id] or {}).carryType)=='2' then
            if id=='1001' then money=money+num elseif id=='1002' then diamonds=diamonds+num
            else pack[id]=(tonumber(pack[id]) or 0)+num end
        end
    end
    return A.commit(dm,{[rolePack]=pack,[roleMoney]=money,[roleDiamond]=diamonds,[A.KEY]=s,[roleBattlePack]={},[roleBattleQueue]={},[roleMapCoin]=0,
        [roleDeathInformation]=copy(deathInformation or dm:getRoleData(roleDeathInformation) or {}),
        [roleMapInfo]=map,[roleBlackMarketRestrictions]=restrictions,[roleTempReceivedDatas]={},
        [roleStatue]=0,[roleBreadCostDecimal]=0,[roleGuideStep]=step(dm:getRoleData(roleGuideStep) or '',60)})
end
function A.finishVoyage(dm,success,returnedPack)
    if success then return A.returnVoyage(dm,nil) end
    return A.failVoyage(dm,dm:getRoleData(roleDeathInformation))
end
function A.getHarborStatus(dm)
    local s=A.getState(dm);s.cargoUpgraded=(tonumber(dm:getRoleData(rolePackSize)) or 0)>=30
    s.eventPending=s.pending~=nil;s.npcName=s.npcRescued and '航图员林恩' or '港务员'
    if not s.enabled then s.npcText='沿用原有航海进度。'
    elseif s.eventPending then s.npcText='沉船成果尚在海上，安全返港后才会结算。'
    elseif s.firstEventReturned then
        s.npcText=(s.npcRescued and '林恩已在港口安顿，愿意帮你辨认航线。\n' or '回收的材料已经卸货。必要章门仍可正常探索。\n')
        if not s.firstReturnClaimed then s.npcText=s.npcText..'救援/回收已安全结算，但还未带回2铁。下一航正常带回至少2铁，再领取一次建设补助；遗失的铁不会自动补发。'
        elseif not s.cargoUpgraded then
            local forgeBuilt=false
            for _,building in ipairs(dm:getRoleData(roleBuilding) or {}) do
                if tostring(building[dataKeyID])=='57' and (tonumber(building[dataKeyNum]) or 0)>0 then forgeBuilt=true;break end
            end
            s.npcText=s.npcText..'首返补助已发：25金、15石、5木、5布。'
            if forgeBuilt then s.npcText=s.npcText..'铁匠铺已建，去制造货舱：消耗5木、5布，将容量20→30。'
            else s.npcText=s.npcText..'用25金、15石和实际带回的2铁建铁匠铺，再用5木、5布制造货舱20→30。' end
            s.npcText=s.npcText..'缺失或已消费的材料仍需补齐。'
        else s.npcText=s.npcText..'30格货舱已经装好。下一步建设农场保障补给，探索铁矿与木材，准备训练营、船工厂和双人队。'
            if not s.followupReturned then s.npcText=s.npcText..'沉船残骸可再做一次有限回收；水手辨认航图、刀手拆加固箱，建议带上新职业。' end end
        if (s.npcRescued or s.chartRecovered) and s.gateClue then s.npcText=s.npcText..'\n'..s.gateClue end
    else s.npcText='近港有一艘沉船。选救援或补给目标，带上船员和适量食物出航。两种选择都能回收2铁，额外收益与后续不同。' end
    return s
end
function A.showHarborBrief(dm,home)
    local status=A.getHarborStatus(dm)
    require('LuaClass/AdventureDialog').show(status.npcName,status.npcText,{{label='知道了'}},home)
end
return A
