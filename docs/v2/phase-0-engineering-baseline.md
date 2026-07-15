# V2 阶段 0 工程基线

> 状态：已完成
>
> 目标：将 V2 与旧产品运行状态隔离，为首章灰盒提供可验证基础。

## 1. 统一运行配置

入口：`bin/res/scripts/LuaClass/V2Config.lua`

该文件统一定义：

- V2 版本与当前阶段；
- 当前章节 ID；
- 存档 schema 和命名空间；
- QA 存档档位；
- 旧系统开关；
- 旧功能关闭时的统一提示。

不得在业务页面新增另一套独立的 V2 全局布尔值。

## 2. 旧系统隔离矩阵

| 功能 | 开关 | 默认 | 运行时处理 |
|---|---|---:|---|
| 成就 | `legacy.achievement` | 关闭 | Dispatch 硬门禁 |
| 排行榜 | `legacy.ranking` | 关闭 | 顶部入口隐藏、Dispatch 门禁 |
| 钻石商城 | `legacy.diamond_store` | 关闭 | 顶部入口与钻石栏隐藏、Dispatch 门禁 |
| 充值 | `legacy.charge` | 关闭 | 充值按钮隐藏、不注册支付回调 |
| 礼包船 | `legacy.push_gift` | 关闭 | 不创建礼包船、不自动弹礼包 |
| 七日奖励 | `legacy.seven_day_bonus` | 关闭 | 不加载和弹出奖励层 |
| 永恒竞技场 | `legacy.eternal_arena` | 关闭 | 不初始化控制器、事件入口禁用 |
| 评分/广告 | `legacy.rating_ads` | 关闭 | 返航不弹评分或广告 |
| 付费地图锁 | `legacy.paid_map_unlock` | 关闭 | 不显示购买流程，仅提示完成海域目标 |

旧代码暂时保留用于历史对照，但关闭状态必须阻止玩家进入对应流程。

## 3. 存档隔离

所有通过 `SaveDataManager` 读写的角色、地图和任务文件使用以下格式：

```text
v2_chapter_01_<profile>_<legacy-file-name>[_<user-id>]
```

默认档位：

| Profile | 用途 |
|---|---|
| `player` | 正常 V2 开发与试玩 |
| `qa_fresh` | 全新首章与新手流程 |
| `qa_explore` | 海图和事件复现 |
| `qa_combat` | 双阶段战斗复现 |

运行前设置全局 `zqV2SaveProfile` 可选择 QA 档位；无效值自动回退到
`player`。该机制当前只负责命名空间，阶段 1 再为各 QA 档位写入固定状态。

首次剧情的 `UserDefault` key 同样带 V2 命名空间，旧版本已播放的开场不会
导致 V2 开场被跳过。

## 4. 内容源与校验

可读内容源位于 `design/v2/data`：

- `chapter.csv`
- `resource.csv`
- `map_node.csv`
- `map_edge.csv`
- `event.csv`
- `event_choice.csv`
- `crew.csv`
- `ship_module.csv`
- `enemy.csv`
- `reward.csv`
- `dialogue.csv`

阶段 0 校验器：`tools/v2/validate_phase0.py`

当前检查：

- 必需表和字段；
- ID 唯一性；
- 章节、节点、事件、敌人、奖励之间的外键；
- 五种资源和四类船员；
- 首章 7～12 个有效节点；
- 15～20 分钟章节目标；
- 双阶段战斗传递规则；
- 旧系统运行时门禁是否接入。

阶段 1 将增加“源表导出到运行时”和运行时加载检查。在此之前，V2 表不与
旧加密 CSV 混写。

## 5. 验证命令

```bash
tools/v2/validate_phase0.sh
./xcode.sh ios-sim
./xcode.sh ios-device
```

`validate_phase0.sh` 包含：

1. 所有生产 Lua 文件语法检查；
2. `V2Config` 功能开关和存档命名测试；
3. V2 内容表 schema、外键和范围检查；
4. 运行时门禁接入检查。

## 6. 阶段 0 完成门槛

- [x] V2 产品基线文档；
- [x] 首章 20 分钟流程；
- [x] 首章节点图；
- [x] 旧系统集中开关；
- [x] V2 存档命名空间与 QA 档位；
- [x] 首章最小数据定义；
- [x] 自动校验脚本；
- [x] 所有 Lua 语法检查通过；
- [x] 内容和门禁校验通过；
- [x] iOS 模拟器构建与启动通过；
- [x] iOS 设备编译通过；
- [x] 阶段 0 变更提交（本阶段提交）。

详细验证证据见 [`phase-0-validation.md`](phase-0-validation.md)。提交后进入阶段 1。
