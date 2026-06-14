--
-- Created by IntelliJ IDEA.
-- User: sunxy
-- Date: 15/1/27
-- Time: 下午3:17
-- To change this template use File | Settings | File Templates.
--

require "LuaClass/Header"
require "LuaClass/Utils"

EffectUtil = {}
EffectUtil.__index = EffectUtil

-- 生成一个动画特效
-- plistName  plist文件路径  必须传
-- loopTime   动画循环次数，0或负数表示无限循环（不传默认为0)
-- num        动画帧数  0、负数、nil 都表示自动循环最大值（这里给个默认值，最大不超过100）
-- delayTime  每帧之间的延迟（不传默认0.05s)
function EffectUtil:createAnimation(plistName, loopTime, num, delayTime)
    if loopTime == nil then loopTime = 0 end
    if num == nil or num <=0 then num = 100 end
    if delayTime == nil then delayTime = 0.05 end

    local str = string.sub(plistName, 1, string.find(plistName, ".plist")-1)
    local splits = split(str, "/")
    local fileName = splits[#splits]

--    cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RGB5_A1)
    cc.SpriteFrameCache:getInstance():addSpriteFrames(plistName)

    local sp = cc.Sprite:createWithSpriteFrameName(fileName.."_1.png")
    local animation = cc.Animation:create()
    animation:setDelayPerUnit(delayTime)
--    sp:setBlendFunc(gl.ONE, gl.SRC_ALPHA)
    for i=1,num do
        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(fileName.."_"..tostring(i)..".png")
        if frame == nil then break end
        animation:addSpriteFrame(frame)
    end
    if loopTime <= 0 then
        sp:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))
    else
        animation:setLoops(loopTime)
        sp:runAction(cc.Sequence:create(cc.Animate:create(animation), cc.RemoveSelf:create()))
    end
    cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(plistName)
--    cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)
    return sp
end

function EffectUtil:getAnimate(fileName, startNumber, endNumber, duration)
    local cache = cc.SpriteFrameCache:getInstance()
    -- 构造每一个帧的实际图像数据
    local animation = cc.Animation:create()
    local frameName = nil
    local frame = nil
    for i = startNumber, endNumber do
        frameName = string.format(fileName, i)
        -- print("imnage %d:%s", i, frameName->getCString())
        frame = cache:getSpriteFrame(frameName)
        if frame ~= nil then
            animation:addSpriteFrame(frame)
        end
    end
    animation:setDelayPerUnit(duration)
    return cc.Animate:create(animation)
end

-- 生成一个粒子特效
-- plistName  plist文件路径
function EffectUtil:createParticle(plistName)
    local particle = cc.ParticleSystemQuad:create(plistName)
    particle:setBlendFunc(gl.SRC_ALPHA, gl.ONE)
    return particle
end

