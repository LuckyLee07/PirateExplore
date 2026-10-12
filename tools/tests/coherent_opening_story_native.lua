-- Real native textures, logical sprite anchors, cascading fades and opt-out.
-- Production story action/timing/skip suite remains separate and unchanged.
require 'extern';require 'LuaClass/Header'
WARM_PIRATE_V1=true
local Art=require 'LuaClass/OpeningStoryArt'
local director=cc.Director:getInstance();local actions=director:getActionManager()
local prefix='Images/Plot/CleanOpening/'
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local parts={{7,539,216},{8,316,45},{9,243,143}}
for i=1,9 do
 local id='juqing_'..i
 check(Art.path(id)==prefix..id..'.png','clean identity '..id)
 local node=assert(Art.sprite(id));node:retain()
 check(node:getContentSize().width>0 and node:getContentSize().height>0,'native texture decode '..id)
 if i<=6 then check(node.getTexture~=nil,'full scene is a real illustrated sprite '..id)end
 node:release()
end
for _,p in ipairs(parts)do
 local node=Art.sprite('juqing_'..p[1]);node:retain()
 check(node:getContentSize().width==p[2] and node:getContentSize().height==p[3],'original logical geometry '..p[1])
 check(node:getAnchorPoint().x==.5 and node:getAnchorPoint().y==.5,'stable center anchor '..p[1])
 local child=node:getChildren()[1];local z=child:getContentSize()
 check(math.abs(z.width*child:getScaleX()-p[2])<.01,'source-rect width fills logical node '..p[1])
 check(math.abs(z.height*child:getScaleY()-p[3])<.01,'source-rect height fills logical node '..p[1])
 check(child:getPositionX()==p[2]/2 and child:getPositionY()==p[3]/2,'source-rect center '..p[1])
 node:runAction(cc.FadeOut:create(.9));actions:resumeTarget(node)
 for _=1,40 do actions:update(.025)end
 check(node:getOpacity()==0 and child:getDisplayedOpacity()==0,'original fade reaches art child '..p[1])
 node:cleanup();node:release()
end
-- The wrapper uses no alternative business data or profile manager.
WARM_PIRATE_V1=false
for i=1,9 do
 local id='juqing_'..i
 check(Art.path(id)=='Images/Plot/'..id..'.png','legacy original file '..id)
 local node=Art.sprite(id)
 check(node.getTexture~=nil and node:getChildrenCount()==0,'legacy remains original sprite '..id)
end
WARM_PIRATE_V1=true
check(Art.path('unrelated_story')=='Images/Plot/unrelated_story.png','other narrative namespace preserved')
local files=cc.FileUtils:getInstance();local original=files.isFileExist
files.isFileExist=function(_,path)return path:sub(1,#prefix)~=prefix and original(files,path)end
check(Art.path('juqing_1')=='Images/Plot/juqing_1.png','missing clean art falls back to original')
files.isFileExist=original
print('PASS opening-story native asset identities, logical geometry, opacity and opt-out: '..checks..' assertions')
