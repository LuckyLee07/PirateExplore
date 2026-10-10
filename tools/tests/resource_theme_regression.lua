-- Executes the real icon resolver and deck fallback; no game or save is loaded.
local available = {}
cc = {FileUtils={getInstance=function()
    return {isFileExist=function(_, path) return available[path] end}
end}}
local R = dofile('bin/res/scripts/LuaClass/ResourceTheme.lua')
local records, originalFields = {}, {}
for id, icon in pairs(R.icons) do
    records[id] = {ID=id, iconName=icon, name='semantic-'..id, quantity='7', resume={{1001,9}}, worth='13'}
    originalFields[id] = records[id].resume
    available['Images/Icon/B/'..icon] = true
end
records['9999'] = {iconName='r_2.png', quantity='17'}
assert(R.applyIcons(records)==13)
for id, icon in pairs(R.icons) do
    local row=records[id]
    assert(row.iconName=='B/'..icon and row.ID==id and row.name=='semantic-'..id)
    assert(row.quantity=='7' and row.worth=='13' and row.resume==originalFields[id])
end
assert(records['9999'].iconName=='r_2.png' and records['9999'].quantity=='17')
assert(records['1037'].iconName==records['1120'].iconName, 'both original key meanings retained')
assert(records['1001'].iconName~=records['1009'].iconName, 'currency and gold ore remain distinct')
assert(R.applyIcons(records)==0, 'presentation hook must be idempotent')
records={['1005']={ID='1005',iconName='unexpected.png'},['1006']={ID='1006',iconName='r_3.png'},
    ['1007']={ID='1008',iconName='r_4.png'}}
available['Images/Icon/B/r_3.png']=nil
assert(R.applyIcons(records)==0 and records['1005'].iconName=='unexpected.png' and records['1006'].iconName=='r_3.png')
assert(records['1007'].iconName=='r_4.png', 'mismatched row identity must not be changed')
assert(R.applyIcons(nil)==0)
local files=cc.FileUtils; cc.FileUtils=nil; assert(R.applyIcons(records)==0); cc.FileUtils=files

local crew={['103']={ID='103',icon='j_3.png',hp='45'}}
for id,names in pairs(R.crewIcons) do
    crew[id]={ID=id,icon=names[1],name='crew-'..id,hp='31',attack='7'}
    available['Images/Icon/B/'..names[2]]=true
end
assert(R.applyCrewIcons(crew)==5 and R.applyCrewIcons(crew)==0)
for id,names in pairs(R.crewIcons) do
    assert(crew[id].icon=='B/'..names[2] and crew[id].ID==id and crew[id].name=='crew-'..id)
    assert(crew[id].hp=='31' and crew[id].attack=='7')
end
assert(crew['103'].icon=='j_3.png' and crew['103'].hp=='45', 'upgraded units sharing old icon must not silently change identity')
crew={['100']={ID='100',icon='j_1.png'},['101']={ID='101',icon='unknown.png'},['102']={ID='103',icon='j_3.png'}}
available['Images/Icon/B/crew-100.png']=nil
assert(R.applyCrewIcons(crew)==0 and crew['100'].icon=='j_1.png' and crew['101'].icon=='unknown.png' and crew['102'].icon=='j_3.png')
assert(R.applyCrewIcons(nil)==0)

package.preload['LuaClass/MasterTheme']=function()end
local C=dofile('bin/res/scripts/LuaClass/CombatTheme.lua')
assert(C.deckPath(false)=='Images/Fight/chuan_04.png')
assert(C.deckPath(true)=='Images/Fight/chuan_01.png')
available['Images/UI/Adventure/Combat/ship-deck-b.png']=true
available['Images/UI/Adventure/Combat/boarding-deck-b.png']=true
assert(C.deckPath(false)=='Images/UI/Adventure/Combat/ship-deck-b.png')
assert(C.deckPath(true)=='Images/UI/Adventure/Combat/boarding-deck-b.png')
assert(C.chestPath(false)=='Images/Fight/baoxiang01.png' and C.chestPath(true)=='Images/Fight/baoxiang02.png')
available['Images/UI/Adventure/Combat/chest-closed-b.png']=true
available['Images/UI/Adventure/Combat/chest-open-b.png']=true
assert(C.chestPath(false)=='Images/UI/Adventure/Combat/chest-closed-b.png')
assert(C.chestPath(true)=='Images/UI/Adventure/Combat/chest-open-b.png')
cc.p=function(x,y)return{x=x,y=y}end
MasterTheme={material=function(name,w,h)
    return {name=name,width=w,height=h,setPosition=function(self,p)self.position=p end}
end}
local parent={addChild=function(self,node,z)self.plate=node;self.z=z end}
local plate=C.captionPlate(parent,{width=640,height=1136},3)
assert(plate==parent.plate and parent.z==3 and plate.name=='ink-brush.png')
assert(plate.width==660 and plate.height==62 and plate.position.x==-10 and plate.position.y==1074)
assert(plate.position.y>1136-75, 'caption backing must stop above the original star row')
print('PASS 13 guarded resource IDs, 12 icon names, shared key, ore/currency separation, non-icon fields, absent/mismatched/idempotent fallbacks, both deck paths')
print('PASS 5 exact common crew IDs, original shared advanced-unit identity, non-icon combat fields and missing/mismatched/idempotent crew fallbacks')
print('PASS original and B-art closed/open chest path fallbacks')
print('PASS ship caption ink backing ends above original stars/HP/cannon rows')
