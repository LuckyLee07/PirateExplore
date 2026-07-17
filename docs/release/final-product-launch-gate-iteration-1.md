# 总体产品上线门禁迭代 1

日期：2026-07-17

本轮结论：**`V2-032 / P1` 已在仓库内关闭。项目现在区分“App Store 提交就绪”和“产品总体可上线”，并新增唯一总体 GO 命令：它先联合盘点产品决策、30 个 App Store 字段、5 个外部质量状态和 4 个开放 P0/P1；全部清零后，才对同一候选运行完整发行回归、两轮外测、三类 TestFlight 真机、App Store 最终门禁和跨证据提交一致性。当前实测 `pending_gate_count: 47`、`product_launch_ready: false`、5 项检查均 skipped、退出码 2，没有联网、没有读取不存在的外测/真机文件，也没有把内部样片或 App Store 准备态冒充总体 GO。**

## 1. 为什么还需要顶层门禁

`final_app_store_gate.py` 的职责是证明 App Store Connect 元数据、公网页面、archive 和 Distribution 签名具备提交条件。它不应替代产品决策，因为以下情况仍必须 HOLD：

- 两轮目标用户指标没有通过；
- 三类真实设备没有用同一 TestFlight build 验收；
- 仍有开放 P0/P1；
- 外测 R2 之后又产生未覆盖的候选代码；
- 真机验证的 build ID 与实际上传 build 不一致；
- 阶段 4 文档和负责人仍是 HOLD。

`V2-032` 在 App Store 提交门禁之上增加总体产品门禁，不改变下层工具的职责。

## 2. 唯一总体 GO 命令

```bash
python3 -B tools/release/final_product_launch_gate.py --json
```

只有输出同时满足以下条件才允许把产品标记为可上线：

```text
pending_gate_count: 0
audit_errors: []
all five checks.status: passed
product_launch_ready: true
exit: 0
```

空检查列表、缺少任一检查、任一 skipped、任一 failed 或任一 audit error 都不能得到 GO。

## 3. 总体上线 manifest

[`product-launch-manifest.json`](product-launch-manifest.json) 只保存跨域交接字段：

| 字段 | 完成定义 |
| --- | --- |
| `candidate.candidate_id` | 与 App Store 提交 manifest 的 `marketing_version-build_number` 一致 |
| `candidate.release_commit` | 生成最终 TestFlight 候选的仓库 commit |
| `evidence.external_test_records` | 仓库内真实两轮匿名 CSV 路径 |
| `evidence.device_acceptance_records` | 仓库内真实三类设备 CSV 路径 |
| `decision.phase4_status` | 最终为 `GO` |
| `decision.product_scope_approved` | 产品负责人确认首发范围 |
| `decision.second_map_budget_approved` | 内容预算评审确认 |
| `decision.approved_by` / `approved_date` | 最终决策负责人和日期 |

当前这些外部字段保持 `null`、`false` 或 `HOLD`，没有示例姓名和伪证据路径。

## 4. 当前 47 个总体门槛

当前机器分组：

| 分组 | 数量 | 当前缺口 |
| --- | ---: | --- |
| `launch` | 8 | release commit、外测/真机记录路径、最终状态、范围/预算批准、负责人、日期 |
| `app_store` | 30 | App 记录、公开 URL、联系人、问卷、分发签名、上传 build、地区与发布方式 |
| `quality_gate` | 5 | 四项外测指标 `external_pass`、真机目标帧率 `device_pass` |
| `issue_register` | 4 | `V2-006`、`V2-014`、`V2-018`、`V2-019` 仍阻断决策或提交 |
| **合计** | **47** | 任一项未完成都保持总体 HOLD |

当前报告摘要：

```text
pending_gate_count: 47
launch: 8
app_store: 30
quality_gate: 5
issue_register: 4
internal_release_regression: skipped
external_user_evidence: skipped
device_acceptance_testflight: skipped
app_store_submission: skipped
candidate_consistency: skipped
product_launch_ready: false
audit_errors: []
exit: 2
```

前置条件未完成时不运行网络、公网页面、archive、外测或真机子命令；`skipped` 表示安全短路，不表示通过。

## 5. 零 pending 后的五项证据

| 检查 | 权威入口 | 必须证明 |
| --- | --- | --- |
| `internal_release_regression` | `validate_ios_release.sh` | 阶段 0～4、原生安全、发行静态、商店素材和提交准备态完整通过 |
| `external_user_evidence` | `analyze_user_tests.py --format json` | 两轮冻结构建、样本分层、访谈证据完整，R2 四项阈值全部 PASS |
| `device_acceptance_testflight` | `validate_device_acceptance.py --require-testflight` | 低端 iPhone、现代 iPhone、iPad 对同一个 TestFlight build 全部通过 |
| `app_store_submission` | `final_app_store_gate.py --json` | 真实公网页面、Distribution archive、上传/后台字段和 App Store 提交证据全部通过 |
| `candidate_consistency` | 顶层内置联合校验 | 外测 R2 → release commit 祖先关系、真机 commit/build ID、上传 build、版本和最终决策一致 |

五项都会执行；某一项失败不会因为其他四项通过而得到总体 GO。

## 6. 跨证据候选一致性

顶层门禁额外拒绝：

- `release_commit` 不是仓库 commit；
- 真机 `candidate_id` 与提交版本/build 不一致；
- 真机 `build_commit` 不等于最终 release commit；
- 三类真机 TestFlight build ID 不等于 App Store manifest 的上传 build ID；
- 最终 release commit 不包含外测 R2 冻结构建；
- [`../v2/phase-4-decision.md`](../v2/phase-4-decision.md) 仍显示 HOLD。

因此旧外测、旧真机或另一个上传 build 不能通过复制路径拼成上线证据。

## 7. 防绕过边界

- 产品 manifest 不替代 App Store manifest、外测 CSV 或真机 CSV；
- `quality_gate.csv` 改成 pass 仍必须有原始 CSV 通过对应分析器；
- issue register 的 P0/P1 必须同时为 `status=fixed`、`release_effect=closed`；
- App Store strict 通过仍必须通过外测、真机和候选一致性；
- development 真机结果不接受；
- 模拟器、device compile、无签名 archive 和开发签名 App 都不能关闭总体门槛；
- 顶层命令没有忽略 pending、跳过外测、允许 development 或忽略开放问题的选项。

## 8. 外部负责人交接顺序

1. 完成 R1 外测、修复 P0/P1、提交新构建，再完成 R2；
2. 确认发行主体、URL、App 记录、团队、Bundle ID 和分发签名链；
3. 生成 Distribution archive，上传并取得真实 App Store build ID；
4. 三类设备安装同一个 TestFlight build，完成真机矩阵和网络复核；
5. 关闭 `V2-006/014/018/019`，把质量状态更新为真实 `external_pass` / `device_pass`；
6. 产品和预算负责人更新阶段 4 决策为 GO；
7. 将真实匿名 CSV、release commit 和审批字段写入产品 manifest；
8. 运行唯一总体命令；只有退出 0 与 `product_launch_ready: true` 才能标记可上线。

## 9. 自动回归

`test_final_product_launch_gate.py` 覆盖：

- 当前 47 项按四组稳定聚合；
- 空检查列表不能 GO；
- 缺少任一检查不能 GO；
- failed 或 skipped 不能 GO；
- 五项完整 passed 才能 GO；
- 真机 commit 必须等于 release commit；
- release commit 必须包含外测 R2；
- Phase 4 HOLD 不能通过。

发行静态门禁锁定顶层五项名称、manifest 仍为 HOLD/空证据，以及本文件的当前机器结论。

## 10. 本轮回归验收

| 验收项 | 结果 |
| --- | --- |
| 顶层门禁专项 | 通过；47 项分组、完整五项、空/缺失/failed/skipped 与跨证据一致性均覆盖 |
| 当前总体上线命令 | 按预期 HOLD；47 pending、5 skipped、0 audit error、退出码 2 |
| 阶段 0～4 与完整发行门禁 | 通过；17 个事件、10 个质量门槛、32 项问题登记，原生安全、签名、真机证据、App Store 与总体门禁专项全部完成 |
| Release 模拟器运行 | 通过；专用 QA 模拟器重新安装并启动，PID `69744` 在 35 秒后仍存活；未减少任何外部门槛 |
| Release device compile | 通过；arm64 通用设备编译完成；未冒充真机/TestFlight 证据 |
| archive 内容检查 | 通过；`build/archives/NewPirate-final-product-gate.xcarchive` 生成并通过版本、架构、隐私清单与遗留符号检查 |
