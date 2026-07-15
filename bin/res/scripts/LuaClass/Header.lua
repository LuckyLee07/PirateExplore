require "LuaClass/V2Config"

if false then
	require "Cocos.init"
	cc.Scale9Sprite = ccui.Scale9Sprite
else
	require "Cocos2d"
	require "Cocos2dConstants"
end

-- 是否开启debug功能（包括debug菜单、cclog是否打印和代码中判断的块）
zqDebug = true

-- 包类型，礼包类型1对应A类包，2对应B类包，之后如果还有其他的，以此类推
zqPackageType = 1

isEnterMap = false

-- 炼金按钮的cd时间
zqAlchemyTime = 0.3

-- 是否更新系统时间成功
bIsTimeUpdateSuccess = false

--[[
网游模式设置参数开始 by 杨杰
]]
-- 记录用户id,主要用于多用户模式的存档
zqUserId = nil

--[[
网游模式设置参数结束 by 杨杰
]]

-- 完全仿照c++方式写的cclog
cclog = function(...)
	if zqDebug then
    	print(string.format(...))
    end
end

-- 音效列举
HAS_MUSIC_FILE   = 0 --正在播放的音乐文件
MUSIC_Main   	 = "music/musicMain.mp3"
MUSIC_Map        = "music/musicMap.mp3"
MUSIC_PK         = "music/musicPK.mp3"


-- 音效列举
EFFECT_Gold         = "music/gold.mp3"        -- 炼金
EFFECT_Button       = "music/button.mp3"      -- 按钮
EFFECT_Caiji        = "music/caiji.mp3"       -- 采集
EFFECT_Chenchuan    = "music/chenchuan.mp3"   -- 沉船
EFFECT_walk         = "music/walk.mp3"        -- 船行走
EFFECT_notoption    = "music/notoption.mp3"   -- 无法操作

EFFECT_mattack      = "music/mattack.mp3"     -- 怪物攻击
EFFECT_mdead        = "music/mdead.mp3"       -- 怪物死亡

EFFECT_attack       = "music/attack.mp3"      -- 物理攻击
EFFECT_magic        = "music/magic.mp3"       -- 魔法攻击
EFFECT_paoji        = "music/paoji.mp3"       -- 炮击
EFFECT_addhp        = "music/addhp.mp3"       -- 回血

--debug权限
mapPermissions = {}

-- UI调度类句柄
zqDispatch = nil

-- 切换到主游戏UI的句柄
gotoMainUI = nil

-- 切换到update的句柄
gotoUpdate = nil

-- 切换到地图的句柄
gotoMap = nil

-- 切换到战斗的句柄
gotoFight = nil

-- 需要更新的下方信息框的scrollView里的Label内容和位置函数的句柄（负责更新每个界面里下方的信息框里的内容）
pNeedUpdateLayer = nil

-- csv表格数据索引
csvOfAchievement = 1			-- 成就表格
csvOfBuff = 2					-- Buff表格
csvOfBuild = 3					-- 建造表格
csvOfProduce = 4				-- 生产表格
csvOfResourceInfo = 5			-- 资源信息表格
csvOfSkillAttribute = 6			-- 技能信息表格
csvOfSoilderAttribute = 7		-- 士兵信息表格
csvOfStore = 8					-- 商店表格
csvOfTalent = 9					-- 天赋表格
csvOfWorker = 10				-- woker表格
csvOfStrongholdAttribute = 11 	-- 据点属性
csvOfStrongholdDistribution = 12 --据点布局
csvOfFightBoxes = 13            -- 战斗宝箱
csvOfRandomEvent = 14           -- 随机事件
csvOfWorldMapCoordinates = 15   -- 世界地图布局表
csvOfPlot = 16                  -- 游戏剧情表
csvOfEternalArena = 17			-- 永恒竞技场
csvOfShopGift = 18				-- 钻石商店上方推荐物品
csvOfShopItem = 19				-- 钻石商店下方物品
csvOfLoadingTips = 20			-- loading界面的提示文字csv
csvOfGift = 21					-- 兑换码对应表格
csvOfPushGift = 22				-- pushGift
csvOfLogingReward = 23			-- 7日登陆奖励表
csvOfMapStrategy = 24			-- 地图攻略
csvOfBlackMarket = 25			-- 地图黑市
csvOftask = 26					-- 任务表
csvOfEncounter = 27				-- 随机遇敌表


-- 角色数据信息
roleName = "1"					-- 玩家名字
roleScopeOfVision = "2"			-- 探索视野范围
roleMapExplorationDegree = "3"	-- 地图探索度
rolePhysicalPower = "4"			-- 体力
roleCabinSize = "5"				-- 船舱大小
rolePackSize = "6"				-- 战斗背包大小
roleWarship = "7"					-- 战船炮筒数
roleMoney = "8"					-- 货币
roleMapInfo = "9"					-- 地图信息
rolePack = "10"					-- 背包数据
roleArenaRecords = "11"			-- 永恒经济场记录点
roleMapLayout = "12" 				-- 地图布局信息
roleDeathInformation = "13" 		-- 玩家阵亡信息
roleProducerQueue = "14"			-- 生产者队列
roleBattleQueue = "15"			-- 战斗队列
roleLivingUnitNum = "16"			-- 生活单位
roleTalent = "17"					-- 天赋数据
roleAchievementPoint = "18"		-- 成就点
roleDiamond = "19"				-- 钻石
roleBattlePack = "20"				-- 战斗背包
roleAchievement = "21" 			-- 成就
roleProduceTime = "22" 			-- 生产倒计时到期时间戳
roleSoildierQueue = "23" 			-- 兵将生产队列
roleStorageInfo = "24"			-- 存储成就相关信息
roleBuilding = "25"				-- 建造数据
roleMake = "26"					-- 制造数据
roleStore = "27"					-- 市场数据
roleShipHp = "28"					-- 战船血量
roleGatherUnit = "29"				-- 单位采集收益
roleAlchemyUnit = "30"			-- 单位炼金收益
roleShipGunPower = "31"			-- 战船炮筒攻击力
roleShipId = "32"					-- 战船id，用来取信息用
roleBonusAttribute = "33"			-- 增加属性信息
roleSelectUnit = "34"				-- 玩家出征之前选择的单位记录
roleLastTime = "35"				-- 玩家最后一次在游戏时间戳
roleBreadHp = "36"				-- 基础面包回血量
roleBreadOwn = "37"				-- 基础面包回血类型记录
roleChargingData = "38"			-- 计费数据
roleArenaMaxRecord = "39"			-- 竞技场最大记录点，用于触发成就
roleGuideStep = "40"				-- 新手引导步数记录
roleDiamondStoreData = "42"		-- 钻石商店数据
roleRandomEventSwitch = "43" 		-- 随机事件开关
roleStatue = "44"					-- 角色状态，0为在主城中,1为在探索
roleResourceCD = "45"				-- 资源界面采集cd时间
roleOfflineBonusTime = "46"			-- 角色离线奖励时间
roleTranslateDoor = "47"			-- 地图传送门层级
roleNickname = "48"					-- 玩家昵称
rolePolts	 = "49"					-- 前五章剧情播放数
roleExtents	 = "50"					-- 玩家总探索度
roleTempReceivedDatas	 = "51"		-- 玩家探索时候领取据点的临时数据，返回城时候清空			

roleMusic_off = "52"				-- 玩家音乐是否开
roleSound_off = "53"				-- 玩家音效是否开
roleEfect_off = "54"				-- 玩家特效是否开

roleBlackMarketRestrictions = "55"	-- 玩家黑市信息

roleMapBuyItems = "56"				-- 玩家在地图购买的商城物品
roleDiamondStroeRedPointer = "57"	-- 钻石商城红点
roleTempOccupationData = "58"		-- 玩家临时的占领数据,供战斗结算或者开箱子使用
roleBreadCostDecimal = "59"			-- 玩家在地图中面包消耗的系数
roleSevenDayBonus = "60"			-- 玩家7日登陆奖励记录数据
roleMapCoin = "61"					-- 玩家地图中金币的数据

roleAlchemyCanLongPress = "62"		-- 玩家是否可以长按炼金以炼金
roleAlchemyShowCount = "63"			-- 按炼金显示购买的次数

roleDefeatedHistory = "64"			-- 玩家杀怪历史记录

roleMission = "65"					-- 玩家任务数据
roleCompletedMissionHistory = "66"	-- 玩家完成任务的历史记录

roleRandomEvents = "67"         	-- 随机事件的记录

roleAlchemyBtnClickCount = "68"		-- 炼金次数记录

roleFristLoginTime = "101"			-- 玩家第一天玩游戏的时间
roleLoginDayTime = "102"			-- 玩家前七日登陆记录
roleEncrypted	= "103"				-- 玩家的数据是否是加密过的(用来安全过度老版本的数据)

--地图信息和角色分离开来
mapInfo = 100

-- 成就类别
achievement_Alchemy = 1	--	炼金次数
achievement_Exploration = 2	--	探索次数
achievement_Gamble = 3	--	赌博次数
achievement_Training = 4	--	训练
achievement_Arena = 5	--	竞技场 
achievement_Skill = 6	--	技能
achievement_ConsumeBread = 7	--	消耗面包次数
achievement_KillBoss = 8	--	杀怪
achievement_Collect = 9	--	采集
-- achievement_ShareToFriends = 10	--	分享到朋友圈次数
-- achievement_ShareToWeibo = 11	--	分享到微博次数
achievement_Ranking = 10	--	排行榜
achievement_Plot = 11	--	剧情
achievement_Progress = 12	--	进度
achievement_Progress1 = 13	--	进度
achievement_Progress2 = 14	--	进度
achievement_Star1 = 15	--	记录玩家当前埋葬士兵的星级数1
achievement_Star2 = 16	--	记录玩家当前埋葬士兵的星级数2
achievement_Star3 = 17	--	记录玩家当前埋葬士兵的星级数3
achievement_Star4 = 18	--	记录玩家当前埋葬士兵的星级数4
achievement_Star5 = 19	--	记录玩家当前埋葬士兵的星级数5
achievement_KillMonster = 20	--	杀怪次数


-- 	模块数据ID
modelDataName = 1 	--	玩家名字
modelDataProductionInfo = 2 	--	生产信息
modelDataTalent = 3		--	天赋数据
modelDataAchievement = 4		--	成就数据

--	通用table数据key
dataKeyID = "ID"
dataKeyNum = "N"
dataKeyAchievement = "achievement"
dataKeyResumeCoin = "resumeCoin" 
dataKeyResumeType = "resumeType"
dataKeyResumeNum = "resumeNum"
dataKeyAutoType = "autoType"
dataKeyName = "name"
dataKeyComment = "comment"
dataKeyFlag = "flag"
dataKeyDesc = "desc"
dataKeyPoint = "point"
dataKeyType = "type"
dataKeyTotalValue = "totalValue"
dataKeyTrigger = "trigger"
dataKeyFatherID = "fatherID"
dataKeyPreFlag = "preFlag"
dataKeyPreID = "preID"
dataKeyProbability = "probability"
dataKeyIncreaseAttrs = "increaseAttrs"
dataKeyIncreaseTypes = "increaseTypes"
dataKeyIncreaseNums = "increaseNums"
dataKeyItem = "item"
dataKeyPrice = "price"
dataKeyDate = "date"
dataKeyTime = "time"
dataKeyDisplay = "display"
dataKeySort = "sort"
dataKeyNextId = "next_id"
dataKeyICON = "ICON"
dataKeyResume = "resume"
dataKeyRepeat = "repeat"
dataKeyUnlock = "unlock"
dataKeyDiamond = "diamond"
dataKeyPayType = "payType"
dataKeyShowType = "show_type"
dataKeyItems = "items"

-- 升级解锁类型枚举id by yangjie
kUnlockBuild = 1 		-- 解锁建造
kUnlockMake = 2 		-- 解锁制造
kUnlockStore = 3		-- 解锁商店
kUnlockResource = 4 	-- 解锁资源

kUpgradeWorker = 1		-- 升级工匠数量
kUpgradePack = 2		-- 解锁战斗背包格子数
kUpgradeCabin = 3		-- 解锁战船容积和血量
kUpgradeShipGun = 4		-- 解锁战船火力
kUpgradeGather = 5		-- 解锁采集收益
kUpgradeAlchemy = 6		-- 解锁炼金收益

--更新文件开关 0-Off 1-On
updateWrite = 1
