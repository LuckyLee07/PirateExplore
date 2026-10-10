-- Actual FightRewardScene callbacks with decoded shipped CSV. No player saves.
local root='bin/res/scripts/LuaClass/'
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local function eq(a,b,why)assert(a==b,(why or 'value')..': '..tostring(a)..' ~= '..tostring(b))end
local src=read('tools/tests/home_master_regression.lua')
local a=assert(src:find('local function readFile(path)',1,true));local b=assert(src:find("\nlocal soldiers=packagedCSV('soilderAttribute')",a,true))
local decode=assert(loadstring('local equal=...\n'..src:sub(a,b-1)..'\nreturn packagedCSV','@loot-real-csv'))(eq)
local resources=decode('resourceInfo')
eq(resources['1012'].cubage,'2','actual dark steel volume');eq(resources['1039'].cubage,'5','actual ram volume')
local fixtureEnd=assert(src:find("\ndofile(root..'Header.lua')",1,true))
local H=assert(loadstring(src:sub(1,fixtureEnd-1)..'\nreturn {node=node,methods=Node,copy=copy}','@loot-node-fixture'))()
local N=H.methods
clone=H.copy
cc.Scene={create=function()return H.node('Scene')end}
cc.Scale9Sprite={create=function()return H.node('Scale9Sprite')end}
cc.TABLECELL_TOUCHED=101;cc.TABLECELL_SIZE_AT_INDEX=102;cc.TABLECELL_SIZE_FOR_INDEX=103;cc.NUMBER_OF_CELLS_IN_TABLEVIEW=104
cc.TABLEVIEW_FILL_TOPDOWN=1;cc.SCROLLVIEW_DIRECTION_VERTICAL=1
cc.TableView={create=function(_,s)local n=H.node('TableView');n:setContentSize(s);n.handlers={};return n end}
cc.TableViewCell={create=function()return H.node('TableViewCell')end}
function N:getTag()return self.tag end
function N:setDirection()end
function N:setVerticalFillOrder()end
function N:setDelegate()end
function N:setPreferredSize(s)self:setContentSize(s)end
function N:dequeueCell()return nil end
function N:reloadData()self.reloads=(self.reloads or 0)+1 end
function N:scheduleUpdateWithPriorityLua(fn)self.updateCallback=fn end
local register=N.registerScriptHandler
function N:registerScriptHandler(fn,event)if self.kind=='TableView' then self.handlers[event]=fn else register(self,fn)end end
local viewport={width=640,height=1136}
cc.Director={getInstance=function()return {getVisibleSize=function()return viewport end,getVisibleOrigin=function()return cc.p(0,0)end}end}
dofile(root..'Header.lua')
dofile(root..'HomeTheme.lua');dofile(root..'MasterTheme.lua');dofile(root..'DialogTheme.lua');dofile(root..'CombatTheme.lua');dofile(root..'ItemIcon.lua')
local data={};local writes,coins,closed=0,0,0;local toast
DataManager={getInstance=function()return {getCSVByID=function()return resources end,getRoleData=function(_,key)return data[key]end,
 setRoleData=function(_,key,value)data[key]=value;writes=writes+1 end,getSound_off=function()return 1 end}end}
ExploreBagController={getBagController=function()return {addCoin=function(_,n)coins=coins+n end}end}
ToastUtil={downString=function(_,s)toast=s end}
local source=read(root..'FightMode.lua')
local begin=assert(source:find('local changeListItemNum = function',1,true));local finish=assert(source:find('-- changeListItemNum1',begin,true))
local sceneBegin=assert(source:find('FightRewardScene = class(',1,true))
local fdm={dropData={}}
assert(loadstring('local fdm=...\n'..source:sub(begin,finish-1)..'\n'..source:sub(sceneBegin),'@production-loot-scene'))(fdm)
local function newScene(capacity,food,drop,reserved)
 data={[rolePackSize]=capacity,[roleBattlePack]={}}
 if food>0 then data[roleBattlePack]['1005']={id='1005',num=food} end
 if reserved then data[roleBattlePack][reserved.id]=clone(reserved) end
 fdm.dropData=clone(drop);writes=0;coins=0;closed=0;toast=nil
 local p=assert(FightRewardScene:create());p:setFightOverCallback(function()closed=closed+1 end);p:setFightResult(true)
 return p
end
local function amount(list,id)
 for _,v in ipairs(list)do if tostring(v.id)==id then return v.num end end
 return 0
end
local function tapRow(p,left,id)
 local list=left and p.package or p.rewardItems;local index
 for i,v in ipairs(list)do if tostring(v.id)==id then index=i;break end end
 assert(index,'visible row '..id)
 local cell=H.node('Cell');cell:setTag(index)
 local tableview=left and p.tableview1 or p.tableview2
 tableview.handlers[cc.TABLECELL_TOUCHED](tableview,cell);p.updateCallback()
end
local function buttons(p)
 local result={}
 for _,n in ipairs(p.children)do if n.kind=='Menu' then for _,item in ipairs(n.children)do if item.callback then result[#result+1]=item end end end end
 return result
end
local function closeScene(p)local all=buttons(p);eq(#all,2,'two original buttons');all[1].callback()end
local function total(p,id)return amount(p.package,id)+amount(p.rewardItems,id)end
-- Original before-evidence: 19/20 + volume 2 yielded 21/20; volume 5 yielded 24/20.
-- Every actual shipped volume now stays within all small residual-capacity boundaries.
for _,id in ipairs({'1008','1012','1022','1076','1039'})do
 local volume=tonumber(resources[id].cubage)
 for _,room in ipairs({0,1,2,5})do
  local p=newScene(20,20-room,{{id=id,num=3}})
  p:pickUpAllRewards();eq(amount(p.package,id),math.min(3,math.floor(room/volume)),'whole units fit')
  assert(p.packageSize<=20,'never over capacity');eq(total(p,id),3,'loot conserved');eq(amount(p.package,'1005'),20-room,'food never automatically discarded')
  local occupied=p.packageSize;p:pickUpAllRewards();eq(p.packageSize,occupied,'repeat cannot overfill');eq(total(p,id),3,'repeat conserves loot')
  eq(writes,0,'preview pickup does not persist until close')
 end
end
for _,cap in ipairs({0,1,2,5})do
 local p=newScene(cap,0,{{id='1039',num=1}});p:pickUpAllRewards()
 eq(amount(p.package,'1039'),cap>=5 and 1 or 0,'small total capacity respected');assert(p.packageSize<=cap)
end
print('PASS loot actual CSV volumes 1/2/5: residual and total capacities 0/1/2/5, no overfill, no automatic discard, repeat conservation')
local p=newScene(20,20,{{id='1001',num=7},{id='1012',num=2}})
p:pickUpAllRewards();eq(coins,7,'zero-volume gold fits full hold');eq(p.packageSize,20);eq(amount(p.rewardItems,'1012'),2)
p:pickUpAllRewards();eq(coins,7,'gold credited only once')
-- The method deliberately retains its original stop-at-first-blocked behavior.
-- initData normally sorts zero-volume first; directly stage the other order to
-- specify this callback boundary rather than claiming arbitrary-order collection.
p=newScene(20,20,{})
p.rewardItems={{id='1012',num=2},{id='1001',num=7}}
p:pickUpAllRewards();eq(coins,0,'bulk does not scan past first blocked resource')
eq(amount(p.rewardItems,'1001'),7,'later zero-volume reward remains untouched')
tapRow(p,false,'1001');eq(coins,7,'specific zero-volume row still fits despite earlier blocked resource')
-- Actual reversible food/iron exchange, not a model of a different callback.
p=newScene(20,20,{{id='1008',num=3}})
local first,second=p:getCargoHint();assert(first:find('点左侧',1,true) and second:find('关闭后',1,true))
for _=1,3 do tapRow(p,true,'1005')end
eq(p.packageSize,17);eq(amount(p.rewardItems,'1005'),3);assert(p:getCargoHint():find('剩 17',1,true))
for _=1,3 do tapRow(p,false,'1008')end
eq(p.packageSize,20);eq(amount(p.package,'1008'),3);eq(total(p,'1005'),20)
tapRow(p,true,'1008');tapRow(p,false,'1005');eq(p.packageSize,20,'exchange can be reversed');eq(amount(p.package,'1005'),18)
closeScene(p);eq(writes,1);eq(closed,1);eq(data[roleBattlePack]['1005'].num,18);eq(data[roleBattlePack]['1008'].num,2)
closeScene(p);eq(writes,1,'repeat close cannot save twice');p:pickUpAllRewards();eq(writes,1,'closed scene ignores late pickup')
local cell=H.node('StaleCell');cell:setTag(99);p.tableview1.handlers[cc.TABLECELL_TOUCHED](p.tableview1,cell);p.tableview2.handlers[cc.TABLECELL_TOUCHED](p.tableview2,cell)
print('PASS loot first-item/blocked-later zero-volume boundary, reversible transfers, close persistence and late input guards')
-- Important task props retain the existing close block; reserve inventory stays intact.
local taskId
for id,r in pairs(resources)do if r.carryType=='2' and tonumber(r.cubage)==0 then taskId=id;break end end
assert(taskId,'real zero-volume mission prop exists')
p=newScene(20,20,{{id=taskId,num=1}});closeScene(p);eq(writes,0);eq(closed,0);assert(toast:find('重要道具',1,true))
tapRow(p,false,taskId);closeScene(p);eq(closed,1);eq(data[roleBattlePack][taskId].num,1)
p=newScene(20,20,{}, {id=taskId,num=2});eq(#p.reservedItems,1,'zero-volume carried prop reserved separately');closeScene(p);eq(data[roleBattlePack][taskId].num,2,'reserved prop restored unchanged')
p=newScene(20,1,{{id='1008',num=1}});tapRow(p,true,'1005')
local _,_,zero=p:getCargoHint();assert(zero,'moving the last food raises a warning without taking control')
eq(amount(p.rewardItems,'1005'),1);eq(writes,0)
cell:setTag(1);p.tableview1.handlers[cc.TABLECELL_TOUCHED](p.tableview1,cell) -- last row just disappeared
tapRow(p,false,'1005');eq(p:getCargoHint():find('剩 1',1,true)~=nil,true,'food can be taken back')
-- Empty/stale row input is ignored even before closing.
cell:setTag(99);p.tableview1.handlers[cc.TABLECELL_TOUCHED](p.tableview1,cell);p.tableview2.handlers[cc.TABLECELL_TOUCHED](p.tableview2,cell)
p=newScene(20,20,{{id='1008',num=3}});for _=1,3 do tapRow(p,true,'1005')end
p:pickUpAllRewards();eq(amount(p.package,'1005'),20,'bulk pickup still reloads moved-out food');eq(amount(p.rewardItems,'1008'),3,'no hidden preference or automatic swap')
print('PASS loot mission-item close guard, zero-food warning, restoration, stale-row safety and unchanged bulk reloading')
for _,size in ipairs({{width=480,height=800},{width=540,height=900},{width=640,height=1136}})do
 viewport.width=size.width;viewport.height=size.height;p=newScene(20,20,{{id='1008',num=3}})
 for _,view in ipairs({p.tableview1,p.tableview2})do
  eq(view:getPositionY(),200,'dedicated noninteractive hint strip below lists')
  eq(view:getContentSize().height,size.height-350,'list reserves 50px')
  eq(view:getPositionY()+view:getContentSize().height,size.height-150,'original list top preserved')
 end
 local b=buttons(p);for _,button in ipairs(b)do eq(button:getPositionY(),60,'original action center');eq(button:getContentSize().height,61,'original action height')end
 for _,label in ipairs(p.cargoHintLines)do
  -- Exercise actual layout fitting against tall native-like CJK metrics too.
  label.getContentSize=function(self)return {width=#self.text*12,height=32}end
  label:setString('stale')
 end
 p:refreshCargoHint()
 for _,label in ipairs(p.cargoHintLines)do
  local z=label:getContentSize();local h=z.height*label:getScale()
  assert(label:getPositionY()-h/2>90.5,'hint stays above original button hitbox')
  assert(label:getPositionY()+h/2<200,'hint stays below reserved list boundary')
  assert(label:getPositionY()-h/2>=143,'glyphs clear the observed ragged paper edge')
  assert(z.width*label:getScale()<=size.width-32+0.001,'hint stays in viewport')
 end
 p=newScene(20,0,{});local x,y=p:getCargoHint();eq(x,'战利品已收妥');eq(y,'','empty loot simplifies hint')
end
print('PASS loot hints clear ragged paper at 480/540/640 widths, preserve buttons/list tops and reserve a noninteractive strip')

-- Both actual loot columns use the shared neutral fallback, never a made-up item.
local originalIconName=resources['1039'].iconName
local originalSprite=cc.Sprite.create
for _,case in ipairs({{name='empty',icon=''}, {name='nil'},
    {name='missing',icon='missing-loot-icon.png'},
    {name='decode-failure',icon='r_9.png',fail=true},
    {name='valid',icon='r_2.png',valid=true}}) do
    resources['1039'].iconName=case.icon
    cc.Sprite.create=function(self,path,rect)
        if case.fail and path=='Images/Icon/r_9.png' then return nil end
        return originalSprite(self,path,rect)
    end
    p=newScene(20,0,{{id='1039',num=1}})
    p.package={{id='1039',num=1}}
    for _,view in ipairs({p.tableview1,p.tableview2}) do
        local cell=view.handlers[cc.TABLECELL_SIZE_AT_INDEX](view,0)
        local icon
        for _,child in ipairs(cell.children) do
            if child:getPositionX()==50 and child:getPositionY()==60 then icon=child;break end
        end
        assert(icon,'both columns keep a visible icon slot: '..case.name)
        if case.valid then
            eq(icon.path,'Images/Icon/r_2.png','normal icon keeps exact authoritative path')
            local actual=originalSprite(cc.Sprite,'Images/Icon/r_2.png'):getContentSize()
            eq(icon:getContentSize().width,actual.width,'valid width unchanged')
            eq(icon:getContentSize().height,actual.height,'valid height unchanged')
        else
            eq(icon.kind,'Node','missing art uses neutral node, not different item')
            eq(icon:getContentSize().width,64,'bounded fallback width');eq(icon:getContentSize().height,64,'bounded fallback height')
        end
        eq(icon:getScale(),1,'icon has no unrequested resize')
    end
end
resources['1039'].iconName=originalIconName;cc.Sprite.create=originalSprite
eq(resources['1039'].iconName,'','real siege ram still has no dedicated art')
print('PASS both loot columns preserve valid icon path/size/position and use neutral fallback for nil/empty/missing/decode-failed art')
