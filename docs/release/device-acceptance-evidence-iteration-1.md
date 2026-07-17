# iOS 真机验收证据迭代 1

日期：2026-07-17

本轮结论：**`V2-031 / P1` 已在仓库内关闭。项目现在有结构化真机体验记录模板和严格验证器，会把低端 iPhone、现代 iPhone、iPad 三类设备、同一候选构建、持续时长、触控/布局/帧率/温控/声音/恢复逐项联合判定；最终发布模式还必须是同一个 TestFlight build。当前模板保持零记录，实测 `ready_for_device_release: false`、缺少三类设备、退出码 2，没有把模拟器、device compile 或瞬时在线设备冒充真机体验。**

## 1. 原有风险

现有发行文档已经列出真机检查项，`V2-027` 也能只读判断设备是否稳定连接，但二者都不能证明应用实际安装并完成体验验收：

- Markdown 勾选无法保证三类设备使用同一构建；
- 单台现代 iPhone 通过可能被误写成完整矩阵；
- “启动成功”可能漏掉小屏安全区、舰炮/接舷触控、静音键和后台恢复；
- 短暂打开应用可能被当作 30 FPS 与温控结论；
- development 包的本地结果可能被误用为最终 TestFlight 候选证据；
- device compile、模拟器进程存活和 devicectl 在线状态都可能被错误替代为体验结论。

`V2-031` 将这些条件变成机器可拒绝的证据合同，但不生成真实设备结果。

## 2. 使用方式

开发阶段真机候选：

```bash
python3 -B tools/release/validate_device_acceptance.py \
  /path/to/device-acceptance-records.csv --json
```

最终上线候选：

```bash
python3 -B tools/release/validate_device_acceptance.py \
  /path/to/device-acceptance-records.csv --require-testflight --json
```

返回码约定：

- `0`：格式有效，三类设备齐全，全部检查和最低时长通过；
- `2`：记录有效但设备缺失、检查失败、时长不足或最终模式不是 TestFlight；
- `1`：证据格式无效、混合候选、提交不存在或字段矛盾。

## 3. 候选一致性

所有行必须共享：

- `candidate_id`；
- 仓库中可解析的 `build_commit`；
- `distribution_channel`；
- `app_store_build_id`。

`candidate_id` 还必须与 `app-store-submission-manifest.json` 的当前 `marketing_version-build_number` 一致，防止旧真机结果被复制到新候选。

`development` 记录必须把 `app_store_build_id` 留空；`testflight` 记录必须填写真实 App Store Connect build ID。`--require-testflight` 不接受 development 结果，因此开发签名 App 只能用于早期排障，不能关闭最终上线真机门槛。

模板不记录 UDID、序列号、Apple ID、电话号码或设备所有者姓名。`tester_id` 使用 QA 匿名代号，`device_model` 只记录公开机型。

## 4. 设备角色

至少覆盖以下三类：

| `device_role` | 目的 |
| --- | --- |
| `low_end_iphone` | 小屏/较低性能手机上的安全区、文字、触控和性能下限 |
| `modern_iphone` | 当前常规手机上的完整体验、声音、后台恢复和性能 |
| `ipad` | 4:3/平板布局、触控间距、文字与战斗操作 |

同一角色可以增加不同机型，但相同角色与机型不能重复填两行。任何已记录场次失败都会保持总体 HOLD，不能通过挑选另一台通过设备隐藏失败。

## 5. 每台设备的强制检查

验证器要求 14 项均明确为真：

1. 全新安装；
2. 冷启动进入第一章；
3. 安全区无覆盖；
4. 所有关键触控可用；
5. 文字可读；
6. 航行帧率体验可接受；
7. 舰炮帧率体验可接受；
8. 接舷帧率体验可接受；
9. 温控可接受；
10. 静音键行为正确；
11. 与系统音频混合符合预期；
12. 主观响度可接受；
13. 进入后台再恢复正常；
14. 存档与恢复路径正常。

“可接受”是人工体验判定，不伪装成仪器级 FPS 或温度数值；`evidence_notes` 必须说明测试路径、异常与复核方式。任何检查失败或持续时长不足都必须填写 `issue_ids`，没有登记问题的失败记录按格式无效处理。

## 6. 最低持续时长

为避免“只打开几秒”得到性能结论，每行至少满足：

| 字段 | 最低值 |
| --- | ---: |
| `session_duration_min` | 20 分钟 |
| `voyage_duration_min` | 5 分钟 |
| `naval_duration_min` | 3 分钟 |
| `boarding_duration_min` | 3 分钟 |
| `thermal_duration_min` | 15 分钟 |

时长达到最低值不自动等于通过；相应检查仍必须显式为真。

## 7. 当前真实状态

直接对仓库空模板执行：

```text
ready_for_device_release: false
missing_roles:
  - low_end_iphone
  - modern_iphone
  - ipad
sessions: []
exit: 2
```

本机虽曾看到 iPhone 12 Pro 和 iPad mini 配对，但三连稳定性复核为 0 台 ready，且没有本轮签名安装、触控、帧率、温控或声音记录。因此它们没有进入模板。

## 8. 自动回归

`test_validate_device_acceptance.py` 覆盖：

- 空模板按预期 HOLD；
- 三角色 development 候选内部通过；
- development 结果不能通过 `--require-testflight`；
- 同一 TestFlight build 的三角色通过；
- 缺少 iPad；
- 静音键失败；
- 温控持续时长不足；
- 失败记录没有对应 `issue_ids`；
- 混用 build commit 或 candidate ID；
- candidate ID 与当前提交 manifest 版本/build 不一致；
- TestFlight build ID 缺失、development 错填 build ID；
- 非法布尔值、重复角色/机型、仓库中不存在的提交。

发行静态门禁还锁定模板必须保持零行，防止内部自动化伪造真机结果。

## 9. 后续执行顺序

1. 先让至少三类设备稳定连接，完成开发签名安装排障；
2. 关闭发现的 P0/P1，并生成新的候选构建；
3. App Store Connect 上传完成后，三类设备统一安装同一个 TestFlight build；
4. 从空模板复制真实记录文件，逐设备完成 20 分钟以上全流程；
5. 问题写入 issue register，修复后换新 build 重新执行受影响矩阵；
6. 用 `--require-testflight` 验证，保存匿名原始 CSV 与 JSON 报告；
7. 再与外测、账号、公开页面、分发 archive 和最终商店门禁一起做总体 GO 判定。

## 10. 本轮回归验收

| 验收项 | 结果 |
| --- | --- |
| 真机验收器专项 | 通过；角色、候选一致性、时长、逐项检查、development/TestFlight 分层均覆盖 |
| 当前空模板 | 按预期 HOLD；零记录、缺三角色、退出码 2 |
| 阶段 0～4 与完整发行门禁 | 通过；17 个事件、10 个质量门槛、31 项问题登记，原生安全、签名、商店素材、网页模板和提交准备态全链完成 |
| Release 模拟器运行 | 通过；专用 QA 模拟器重新安装并启动，PID `63730` 在 35 秒后仍存活；未计入真机记录 |
| Release device compile | 通过；arm64 通用设备编译完成；未冒充安装或体验证据 |
| archive 内容检查 | 通过；`build/archives/NewPirate-device-evidence.xcarchive` 生成并通过版本、架构、隐私清单与遗留符号检查 |
