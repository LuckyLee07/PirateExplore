-- Optional generated silhouettes preserve native boxes/tints and geometry fallback.
dofile('tools/tests/home_master_regression.lua')
local oldFiles,oldSprite=cc.FileUtils.getInstance,cc.Sprite.create
for _,mode in ipairs({'present','missing','decode-failure','zero-width','zero-height'}) do
    cc.FileUtils.getInstance=function() return {isFileExist=function()return mode~='missing'end}end
    cc.Sprite.create=function(_,path)
        if mode=='decode-failure' then return nil end
        local s=cc.Node:create();s.path=path
        s:setContentSize(cc.size(mode=='zero-width' and 0 or 128,mode=='zero-height' and 0 or 128))
        s.getTexture=function()return{setTexParameters=function(_,a,b,c,d)s.filter={a,b,c,d}end}end
        return s
    end
    for _,kind in ipairs({'port','food'}) do
        for _,size in ipairs({24,29,40,48,64}) do
            for _,color in ipairs({MasterTheme.colors.ink,MasterTheme.colors.paper}) do
                local n=MasterTheme.icon(kind,size,color)
                assert(n:getContentSize().width==size and n:getContentSize().height==size)
                local s=n:getChildren()[1]
                if mode=='present' then
                    assert(s.path=='Images/UI/Adventure/Master/Icons/'..(kind=='port' and 'port' or 'barrel')..'.png')
                    assert(s:getScale()==size/128 and s:getPositionX()==size/2 and s:getPositionY()==size/2)
                    assert(s.color==color and s.filter[1]==9729 and s.filter[2]==9729)
                    assert(s.filter[3]==33071 and s.filter[4]==33071)
                else assert(s.kind=='DrawNode' and #s.draws>0) end
            end
        end
    end
    print('PASS refined icons '..mode..': exact native box/tint, centered uniform fit, bilinear clamp or original vector fallback')
end
cc.FileUtils.getInstance,cc.Sprite.create=oldFiles,oldSprite
