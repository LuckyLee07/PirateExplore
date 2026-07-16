# V2 迭代完成度审计

审计日期：2026-07-16

本文件按 [`../product-iteration-plan-v2.md`](../product-iteration-plan-v2.md) 的阶段目标、交付和门槛逐项核对。结论以当前仓库、验证命令、构建产物和真实测试记录为证据；“没有发现问题”不等于完成。

## 总结

| 阶段 | 实现与内部验证 | 仍缺证据 | 结论 |
| --- | --- | --- | --- |
| 0 设计与工程收口 | 文档、流程/节点图、18 张源表、feature gate、scoped save、基线截图、模拟器/device compile | 无 | 完成 |
| 1 灰盒首章纵切 | 安全/风险完整路径、双阶段战斗、失败恢复、返航升级、首章外隔离 | “无口头指导首次出航”的外部证据并入阶段 4 | 工程阶段完成 |
| 2 探索与战斗重做 | 情报、路线取舍、部位目标、甲板传递、船员技能、失败复盘、源表数值 | 玩家能否解释利弊和传递机制并入阶段 4 | 工程阶段完成 |
| 3 内容与美术定调 | 8 事件、18 对白、14 表现、6 cue、四英雄画面、正式资源映射 | 真机字号、触控、安全区、帧率和声音体验 | 内容阶段完成，设备门槛待验 |
| 4 测试与立项 | 本地记录、质量门槛、存档迁移、内部审计、外测协议、预算、商业建议 | 真机体验；两轮外部目标用户；外测后的 P0/P1 清零；最终 Go/No-Go | 进行中，HOLD |

## 已证明的阶段 0～3 要求

- `tools/v2/validate_phase4.sh` 递归执行阶段 0～4 验证；数据引用、运行时导出、安全/风险路径、失败恢复、内容、资源、音频和存档迁移均通过；
- 提交 `a0e9a73`、`63e34f4`、`56be8ce`、`b577b60` 分别保存阶段 0～3 的已验证状态；
- arm64 simulator 和 device compile 均通过；四英雄画面已在 iOS 26.2 模拟器完成全屏截图复核；
- V2 不要求进入商店、充值、排行、七日、任务 toast 或旧付费地图；
- 正式表现映射拒绝 `generated`/`placeholder` 路径，声音走稳定的 AVFoundation bridge。

这些证据能证明实现完整，但不能证明首次接触的目标用户理解玩法，也不能替代真机触控和帧率。

## 阶段 4 已证明要求

- 17 类匿名、本地、随 scoped save 持久化的过程记录；
- 3→4 存档保留式迁移、损坏档回退、失败重试和返港恢复自动测试；
- physical footprint 102.7 MB、峰值 103.7 MB，低于 256 MB 内部门槛；
- 最终候选触发原生 cannon cue 后约 26 秒仍存活；
- 8 个已登记问题覆盖 P0/P1/P2，内部发现的 P0/P1 已修复，外测证据缺口保持开启；
- 第二张地图 7.5 人周、前三海域 22 人周的限额预算，以及首章试玩后一次解锁的商业建议；
- 外测模板保持空白，没有用内部自动化生成参与者结果。

阶段 4 内部基线提交为 `3362ca1`。

## 尚未证明且不可替代的要求

### 1. 真实设备体验

需要把签名候选安装到真实 iPhone，逐项记录：启动与安全区、所有按钮触控、字号、30 FPS 航行/舰炮/接舷体验、横竖屏约束、静音键、系统音频混合和响度。compile-only 不能证明这些项目。

当前只读预检发现一台 iOS 18.7.8 的 iPhone 12 Pro：设备已配对、已启动开发者模式，但 Developer Disk Image 未能挂载，DDI 服务不可用。继续前需要通过 USB 连接并解锁设备，在 Xcode Devices and Simulators 中完成一次设备准备。

本机存在有效 Apple Development 身份，但证书 Team ID 与项目中的旧 Team ID 不一致，且没有当前项目可用的 provisioning profile。为避免覆盖设备上的既有 `com.fancyGame.NewPirate` 及其数据，后续应在用户明确授权后，使用证书所属团队、自动 provisioning 和独立 QA Bundle ID 构建并安装；该操作会联系开发者服务并改变设备/开发者账号状态，不能在只读预检中代办。

### 2. 两轮外部目标用户测试

按 [`phase-4-user-test-protocol.md`](phase-4-user-test-protocol.md) 执行：第一轮至少 5 名有效参与者；修复 P0/P1 并提交新构建；第二轮使用至少 5 名新参与者。项目成员、看过完整流程的人和内部模拟结果不能计入。

复制 [`phase-4-test-record-template.csv`](phase-4-test-record-template.csv) 为实际匿名记录文件后运行：

```bash
python3 tools/v2/analyze_user_tests.py /path/to/phase-4-test-records.csv \
  --output /path/to/phase-4-external-report.md
```

工具会验证轮次、匿名 ID、技术失败排除规则和布尔字段，并只用第二轮计算四项门槛。即使四项外测均通过，输出也明确不是总体 Go。

### 3. 最终决策与回归

完成前两项后还必须：

1. 把真实问题写入 issue register 并清零 P0/P1；
2. 将 `quality_gate.csv` 的设备与外测状态更新为真实结论；
3. 将 [`phase-4-decision.md`](phase-4-decision.md) 从 provisional HOLD 更新为最终 Go/No-Go；
4. 再跑阶段 0～4、simulator、device 和关键运行 smoke；
5. 提交外测修复与最终决策，确认工作区没有遗漏的本阶段文件。

## 当前结论

V2 的代码、内容样片和内部质量基线已经成立，但完整 V2 迭代尚未完成。权威结论仍是 **HOLD**，剩余工作不能由自动化伪造或推断。
