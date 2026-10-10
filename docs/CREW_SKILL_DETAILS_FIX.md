# 船员技能详情映射修复

## 根因与范围

`EventDetailsLayer:showCellInfo` 的酒馆、黑市、货舱分支把 `soilderAttribute.skill` 当作 `buff` 的主键。真实打包数据中，探险者 144 的技能是 44「标记」，其 `skillAttribute.buffID` 为 0，且不存在 buff 44，因此点击详情崩溃。技能 1–24 中的同 ID buff 偶然存在时还会显示另一个效果。

新增只读小模块 `CrewSkillDetails.describe(skillId, skills, buffs)`，沿 `soldier.skill → skillAttribute → buffID → buff.description` 读取。保留真实技能名及已有 buff 描述；buffID 为 0 时显示「无额外附加效果」，不宣称技能无作用。缺失技能、名称、buffID、buff 或描述时对应字段显示「暂不可用」。缺失船员整行时显示「船员详情暂不可用」。真实 skillAttribute 没有技能 description 字段，未编造技能说明。

酒馆/黑市/货舱详情共用该描述器；船坞 Expedition、招募 TrainMode 原有技能效果展示也复用它，避免相同缺数据崩溃及「技能效果：无」的误解。不修改战斗、招募、购买、数量、消费、存档或网络逻辑。EventLayer/Explore 仅获取技能名，不存在该错误的 buff 解引用；FightMode 的 buff 使用属于战斗逻辑，保持不变。

## 自动验证

- `/workspace/shared/lua51 tools/tests/crew_skill_details_regression.lua`
- `source ../linux-runtime/env.sh; build/linux/tests/chart-lifecycle-native tools/tests/crew_skill_details_regression.lua`
- Lua 5.1 下 `expedition_ui_regression.lua`、`item_icon_offer_regression.lua`、`management_ui_regression.lua`、`material_caption_regression.lua`
- `git diff --check`

新回归复用既有 `home_master_regression.lua` 的 Record/LZSS 解码，从真实打包 CSV 获取全部船员、技能与 buff。对全部船员执行生产 `showCellInfo` 的 2/3/4 三分支，覆盖 38 条 buff0、52 条有效 buff、22 条同 ID 会误导的映射，以及缺技能/空名称、144、数值/字符串键、缺失引用、购买点击冒泡、空数据、墓地不显示、资源详情原样和 CSV 不变检查；也提取并执行 TrainMode 原生产 table-cell touched 闭包，在真实全船员 CSV 和 ID 键下验证技能详情（不构建其整个招募 UI）。原生测试使用真实 Cocos LuaEngine、Node、DialogTheme.card 与实际 Linux 详情字体 Noto Serif CJK SC/24、宽度 460.8 的 LabelTTF；不初始化游戏/真实档，不等同于完整 GUI 验收。

## 冷启动 GUI 复验指引

必须退出再启动游戏以清除 Lua require 缓存。仅在获准的独立测试档进入自然第三航的酒馆事件 3004，点击 144「探险者」名称行，而不是购买按钮；详情应显示「标记」「无额外附加效果」及真实生命/威力/速度。关闭、重开详情及酒馆，重复点名称和购买取消，确认无 Lua 异常，购买逻辑未改变。另在黑市/货舱各查看一名船员及资源，观察长描述边界；不要修改原存档或执行真实支付。GUI 结果由独立验证记录提供。

## GUI 发现后的卡片高度修复

独立 GUI 在144详情确认四行真实文字高127px而旧卡片仅120px，造成顶边纹理压字、统计行贴底栏。仅在 `EventDetailsLayer:showCellInfo` 中依据实际 label 内容高度加32px重建详情卡片；保留最小120px、原宽度/横坐标以及卡片底边（在退出栏上方），向上扩展并重新居中文字。关闭监听、infoNode位置和层级均不变，短资源详情恢复120px，不缩放文字/背景纹理。

新回归对所有船员和重复/资源切换断言上下各至少16px内边距、卡片底边不变、label居中、宽512px以及容器始终只有背景与label两个子节点。严格Lua及真实字体Cocos测试均通过；GUI冷重验由独立记录负责。

## 船坞详情对比度

独立 GUI 继续打开船坞详情发现 BaseView 保留的深色 `MaskBg_1` 与 Expedition 设置的深青字对比不足。仅将该详情 label 改为 MasterTheme 暖白（255,248,224），保留字体、透明底图、位置、尺寸及命中盒；不影响其他页面。真实底图中心 RGBA 为(15,1,1,230)。Expedition 生产创建流程回归在1136/960两种高度断言实际文本颜色并通过；最终清晰度由冷启动 GUI 确认。
