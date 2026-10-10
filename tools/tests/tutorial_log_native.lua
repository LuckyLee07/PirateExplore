-- Real Cocos labels/scroll views, no game boot, profile or window.
local file=assert(io.open(os.getenv('PIRATE_TUTORIAL_SOURCE') or 'bin/res/scripts/LuaClass/BaseView.lua'));local source=file:read('*a');file:close()
BaseView={}
assert(loadstring(source:match('(function BaseView:updateInfoLabel%(infoString%).-\nend)')))()
ManagementTheme={bodyFont=function()return 'Noto Serif CJK SC' end}
local geometry=assert(source:match('(    local btnDecor = cc.Sprite:create%("Images/MainMenu/di_a.png"%).-)    btnDecor:setPosition'))
local layout=assert(loadstring('return function(self,topSplit)\n'..geometry..'return btnDecor\nend'))()
local function label(text,width)
 local l=cc.LabelTTF:create(text,ManagementTheme.bodyFont(),24)
 l:setDimensions(cc.size(width,0));l:setAnchorPoint(cc.p(0,1));return l
end
for _,screen in ipairs({{480,800},{540,900},{540,960}})do
 -- Production SHOW_ALL calculates a 640-point design width at these sizes.
 local width,height=640,screen[2]*640/screen[1]
 local v={isHaveInfo=true,managementTheme=true,areaWidth=width-30,infoNode=cc.Layer:create()}
 v.infoNode:setContentSize(cc.size(v.areaWidth,230*height/1136))
 local decor=layout(v,cc.Node:create())
 local centerY=v.infoNode:getContentSize().height-decor:getContentSize().height*.55
 local viewHeight=centerY-72-20
 assert(viewHeight>=v.infoMinimumTextHeight-.01,'two-line reserve')
 assert(10+viewHeight<=centerY-72-9.99,'log must not touch action dock')
 v.infoScrollViewContainer=cc.Layer:create()
 v.infoScrollView=cc.ScrollView:create(cc.size(v.areaWidth,viewHeight))
 v.infoScrollView:setContainer(v.infoScrollViewContainer)
 v.infoLabel=label(' ',v.areaWidth);v.infoScrollViewContainer:addChild(v.infoLabel)
 local newest={
  '建设已解锁！\n点击底部“港务”，再选择“建设”。',
  '你建造了仓库，现在去收集一些东西吧。\n点击底部“港务”，再选择“采集”。',
  '你建造了仓库，现在去收集一些东西吧。点击底部港务，再选择采集。'
 }
 local history=''
 for i=1,22 do
  local text=newest[1+i%#newest]
  local measure=label(text,v.areaWidth)
  assert(measure:getContentSize().height<=viewHeight,'latest full entry must fit')
  history=text..'\n'..history
  -- Simulate browsing old history and an unfinished previous insertion.
  v.infoLabel:runAction(cc.MoveTo:create(.3,cc.p(0,999)))
  v.infoScrollView:setContentOffset(cc.p(0,0))
  BaseView.updateInfoLabel(v,history)
  local y=v.infoLabel:getPositionY()+v.infoScrollView:getContentOffset().y
  assert(math.abs(y-viewHeight)<.01,'newest entry starts at viewport top')
  assert(y-measure:getContentSize().height>=-.01,'entire latest entry visible')
  assert(v.infoLabel:getNumberOfRunningActions()==0,'stale label action stopped')
 end
 BaseView.updateInfoLabel(v,'短消息')
 assert(v.infoScrollView:getContentOffset().y==0,'short history resets offset')
 assert(v.infoLabel:getPositionY()==viewHeight,'short label remains top aligned')
 print(('PASS tutorial log %dx%d: native 24pt, %.1fpt viewport'):format(screen[1],screen[2],viewHeight))
end
