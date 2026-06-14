--
-- Created by IntelliJ IDEA.
-- User: sunxy
-- Date: 15/1/23
-- Time: 下午3:17
--
--  战斗中需要的数据的定义
--

-- FightDataManager
FightDataManager = class("FightDataManager", function ()
    return {}
end)
FightDataManager.__index = FightDataManager


-- 我方大炮数据（FightCannonData 类型 ）
FightDataManager.playerCanoon = nil
-- 敌方大炮数据（FightCannonData 类型 ）
FightDataManager.enemyCanoon = nil

-- 我方队伍数据（FightFighterData[] 类型 ）
FightDataManager.playerFighters = nil
-- 敌方队伍数据（FightFighterData[] 类型 ）
FightDataManager.enemyFighters = nil
-- 战斗胜利的掉落数据(table类型)
FightDataManager.dropData = nil
-- 地图ID(number类型)
FightDataManager.mapID = nil
-- 据点当前层数(number类型)
FightDataManager.curLevel = nil
-- 据点总层数(number类型)
FightDataManager.totalLevel = nil

--我放成员的战斗加层属性值
FightDataManager.bonusAttribute = nil

local instance
local function create()
    instance = FightDataManager.new()
    if instance and instance:init() then
        return instance
    end
    return nil
end
function FightDataManager:init()
    self.playerFighters = {}
    self.enemyFighters = {}
    self.mapID = 1
    self.curLevel = 0
    self.totalLevel = 0
    return true
end
function FightDataManager:getInstance()
    if nil == instance then
        instance = create()
    end
    return instance
end

function FightDataManager:clearEnemyData( )
    self.enemyCanoon = nil
    for i=1,#self.enemyFighters do
        self.enemyFighters[i] = nil
    end
end

function FightDataManager:clearAllData()
    self.playerCanoon = nil
    self.enemyCanoon = nil
    for i=1,#self.playerFighters do
        self.playerFighters[i] = nil
    end
    for i=1,#self.enemyFighters do
        self.enemyFighters[i] = nil
    end
end
function FightDataManager:addPlayerFighterData(t)
    table.insert(self.playerFighters, #self.playerFighters+1, t)
end
function FightDataManager:addEnemyFighterData(t)
    table.insert(self.enemyFighters, #self.enemyFighters+1, t)
end

-- 大炮数据
FightCannonData = class("FightCannonData", function ()
    return {}
end)
FightCannonData.__index = FightCannonData

-- 威力值
FightCannonData.power = 0
-- 炮数
FightCannonData.num = 0
-- 血量值
FightCannonData.hp = 0
-- 名字
FightCannonData.name = ""
-- 速度
FightCannonData.speed = 0
-- 描述
FightCannonData.description = ""
-- 星级
FightCannonData.star = 0

-- 水手数据
FightFighterData = class("FightFighterData", function ()
    return {}
end)
FightFighterData.__index = FightFighterData

-- 威力值
FightFighterData.power = 0
-- 血量值
FightFighterData.hp = 0
-- 名字
FightFighterData.name = ""
-- 速度
FightFighterData.speed = 0
-- 闪避
FightFighterData.miss = 0
-- soilder ID
FightFighterData.soilderId = 0
-- 描述
FightFighterData.description = ""

--计算公式，先算加成百分比，再加上加成值
--天赋加成属性(Coefficient为百分比)
FightBonusAttribute = class("FightBonusAttribute", function ()
    return {}
end)

FightBonusAttribute.__index = FightBonusAttribute
--血量
FightBonusAttribute.hp = 0
FightBonusAttribute.hpCoefficient = 0
--威力
FightBonusAttribute.power = 0
FightBonusAttribute.powerCoefficient = 0.0
--攻击
FightBonusAttribute.att = 0
FightBonusAttribute.attCoefficient = 0

--FightBonusAttribute.speed = 0

--命中
FightBonusAttribute.hits = 0
FightBonusAttribute.hitsCoefficient = 0
--闪避
FightBonusAttribute.dodge = 0
FightBonusAttribute.dodgeCoefficient = 0
--先手
FightBonusAttribute.ready = false
--伤害减少
FightBonusAttribute.damageReduction = 0
FightBonusAttribute.damageReductionCoefficient = 0
