-- Real Cocos/EGL result sheet on the native Home fixture. No player save,
-- reward path or external service is used. Actual commit hooks are tested in
-- warm_return_result_regression.lua; all UI writes are forbidden here.
local f=assert(io.open('tools/tests/warm_home_dialog_native.lua','rb'));local source=f:read('*a');f:close()
local stop=assert(source:find("for _,height in ipairs({960,1067,1136})do",1,true))
local H=assert(loadstring(source:sub(1,stop-1)..'\n'..[[
return {check=check,equal=equal,serialize=serialize,dm=dm,fixture=fixture,getData=function()return data end,
 setViewport=function(w,h)viewport=cc.size(w,h)end,fresh=fresh,finish=finish,
 visit=visit,labelsWithin=labelsWithin,failures=failures,realGet=realGet,tables=tables}
]],'@native-return-result-fixture'))()
local R=require 'LuaClass/WarmReturnResult'
local M=require 'LuaClass/WarmMemories'
local check=H.check
local function equal(a,b,message)return H.equal(a,b,message or'value')end
local function textContains(root,text)
    local found=false;H.visit(root,function(node)if node.getString and node:getString():find(text,1,true)then found=true end end);return found
end
local function receipt(withMemory,long)
    local data=H.getData();data[roleMapInfo]={curIndex=1};data[roleDiamond]=20
    local state={version=1,enabled=true,voyage=1,activeVoyage=1,firstReturnClaimed=false}
    state.warmMemoriesVoyageV1=assert(M.prepareDeparture(H.dm,state))
    state.pending={voyage=1,episode='first',action='rescue',choice='rescue'}
    state.pending=assert(M.prepareEvent(H.dm,state));data.adventureProgressV1=state
    local before=assert(R.before(H.dm,state));local pack={['1005']=107,['1006']=15,['1007']=5,['1008']=2,['1018']=5}
    if long then for id=1100,1160 do pack[tostring(id)]=id-1000 end end
    local fields={[rolePack]=pack,[roleMoney]=55,[roleDiamond]=12,
        [roleStatue]=0,[roleSoildierQueue]={['100']={id='100',num=2}},
        adventureProgressV1={version=1,enabled=true,voyage=1,firstReturnClaimed=true}}
    if withMemory then data[M.KEY]=assert(M.prepareReturn(H.dm,state,{['1008']={id='1008',num=2}},data[roleMapInfo],fields))end
    for key,value in pairs(fields)do data[key]=value end
    return assert(R.complete(H.dm,before,true))
end
for _,size in ipairs({{480,800},{640,960},{640,1067},{640,1136}})do
    H.setViewport(size[1],size[2]);H.fixture();local result=receipt(true,true)
    local home=H.fresh();local before=H.serialize(H.getData())
    local layer=assert(R.show(H.dm,result,home));layer:retain()
    equal(home.warmReturnResult,layer,'Home owns actual result');equal(R.show(H.dm,result,home),layer,'duplicate show reuses one sheet')
    check(home:blocked(),'receipt blocks queued Home actions')
    home:openActivity('crew');equal(home.warmActivity,nil,'queued crew action cannot open beneath result')
    check(textContains(layer,'金币 +25'),'actual money delta');check(textContains(layer,'钻石 -8'),'actual diamond cost')
    check(textContains(layer,'仓库物资净变化'),'stock delta explicitly labeled as net warehouse change')
    check(textContains(layer,'原有补给'),'returned original provisions are not claimed as newly earned loot')
    check(textContains(layer,'补助及返航消耗'),'warehouse delta explains original subsidy and return consumption')
    check(not textContains(layer,'本航物资结算'),'ambiguous material heading removed')
    check(textContains(layer,'新增珍藏：沉船航图残页'),'new memorial is accurately attributed')
    H.labelsWithin(layer,'Result '..size[1]..'x'..size[2])
    local staleNext=assert(layer.buttons.next);staleNext:retain();staleNext.item:activate();equal(layer.page,2,'long settlement can paginate')
    staleNext.item:activate();equal(layer.page,2,'removed pager callback is inert');staleNext:release()
    H.labelsWithin(layer,'Paged result '..size[1]..'x'..size[2])
    local staleClose=layer.buttons.close;staleClose:retain();staleClose.item:activate()
    equal(home.warmReturnResult,nil,'close clears owner');check(layer.closed,'closed state');staleClose.item:activate();staleClose:release()
    equal(R.show(H.dm,result,home),nil,'closed receipt cannot reappear');equal(H.serialize(H.getData()),before,'show/page/close never save or grant')
    layer:release();H.finish(home)
    -- A fresh confirmed result can enter collection, with exactly one route.
    H.fixture();result=receipt(true,false);home=H.fresh();local routes=0
    home.openActivity=function(_,kind)equal(kind,'collection');routes=routes+1 end
    layer=assert(R.show(H.dm,result,home));layer:retain();local collect=layer.buttons.collection;collect:retain()
    collect.item:activate();collect.item:activate();equal(routes,1,'collection route closes first and cannot repeat')
    equal(home.warmReturnResult,nil);collect:release();layer:release();H.finish(home)
    -- Old-active receipt is honest, no old history or collectible claim.
    H.fixture();result=receipt(false,false);home=H.fresh();before=H.serialize(H.getData())
    layer=assert(R.show(H.dm,result,home));layer:retain()
    check(textContains(layer,'不补写旧航程'),'old-active receipt explains no log backfill')
    check(not textContains(layer,'新增珍藏'),'old-active receipt never claims a memory')
    equal(layer.buttons.collection,nil,'no misleading collection CTA')
    H.finish(home);check(layer.closed,'Home disposal closes sheet');equal(home.warmReturnResult,nil)
    layer:close();equal(H.serialize(H.getData()),before,'owner exit cannot mutate saved data');layer:release()
    print('CHECKED native WarmReturnResult '..size[1]..'x'..size[2]..': actual text, pagination, repeat/close/collection/owner lifecycle and read-only old-voyage receipt')
end
cc.Director.getInstance=H.realGet
assert(#H.failures==0,table.concat(H.failures,'\n'))
print('PASS native WarmReturnResult; no result UI write or reward action')
