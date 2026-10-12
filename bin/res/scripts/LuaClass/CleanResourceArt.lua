-- Exact resource identities in a generated clean atlas; no gameplay data writes.
local A={path='Images/UI/CleanWorkyard/resources-v1.png'}
A.cells={['1004']=1,['1005']=2,['1007']=3,['1006']=4,['1008']=5,['1011']=6,
 ['1009']=7,['1001']=8,['1016']=9,['1013']=10,['1010']=11,['1012']=12,
 ['1014']=13,['1015']=14,['1022']=15,['1076']=16}
local xs={0,314,628,942,1254};local ys={0,348,635,935,1254}
function A.sprite(id,size)
 local cell=A.cells[tostring(id)];if not cell then return nil end
 local col=(cell-1)%4+1;local row=math.floor((cell-1)/4)+1
 local s=cc.Sprite:create(A.path,cc.rect(xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]))
 if not s then return nil end
 local z=s:getContentSize();s:setScale(math.min(size/z.width,size/z.height));s:setAnchorPoint(cc.p(.5,.5));return s
end
return A
