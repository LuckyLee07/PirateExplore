-- Large-only portrait loading, exact identity/fallback and unchanged dimensions.
dofile('tools/tests/home_master_regression.lua')
local oldFiles,oldSprite=cc.FileUtils.getInstance,cc.Sprite.create
local root='Images/UI/Adventure/Master/Portraits/'
for _,mode in ipairs({'present','missing-high','decode-high','zero-high','missing-small','both-missing','all-decode'}) do
    local requested={}
    cc.FileUtils.getInstance=function()return{isFileExist=function(_,p)
        local high=p:find('/Portraits/',1,true)
        if mode=='both-missing' then return false end
        if high then return mode~='missing-high' end
        return mode~='missing-small'
    end}end
    cc.Sprite.create=function(_,p)
        requested[#requested+1]=p
        local high=p:find('/Portraits/',1,true)
        if mode=='all-decode' or (high and mode=='decode-high') then return nil end
        local s=cc.Node:create();s.path=p
        s:setContentSize(cc.size(high and (mode=='zero-high' and 0 or 528) or 64,high and 505 or 64))
        s.getTexture=function()return{setTexParameters=function(_,a,b,c,d)s.filter={a,b,c,d}end}end
        return s
    end
    for _,id in ipairs({'100','101'}) do
        local n=MasterTheme.portrait(id,185,155)
        if mode=='both-missing' or mode=='all-decode' then assert(n==nil)
        else
            assert(n:getContentSize().width==185 and n:getContentSize().height==155)
            local s=n:getChildren()[1]
            local high=mode=='present' or mode=='missing-small'
            assert(s.path==(high and root or 'Images/Icon/B/')..'crew-'..id..'.png')
            local z=s:getContentSize()
            assert(s:getScale()==math.min(185/z.width,155/z.height))
            assert(s.anchor.x==.5 and s.anchor.y==0 and s:getPositionX()==92.5 and s:getPositionY()==0)
            assert(s.filter[1]==9729 and s.filter[2]==9729 and s.filter[3]==33071 and s.filter[4]==33071)
        end
        requested={};MasterTheme.portrait(id,64,64)
        for _,path in ipairs(requested) do assert(not path:find('/Portraits/',1,true),'small slot must never load large art') end
    end
    assert(MasterTheme.portrait('108',185,155)==nil,'unillustrated unit must not borrow another identity')
    print('PASS large100/101 '..mode..': identity, box, fit, tint filtering and small-path isolation')
end
cc.FileUtils.getInstance,cc.Sprite.create=oldFiles,oldSprite
