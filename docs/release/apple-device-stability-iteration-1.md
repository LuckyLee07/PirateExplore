# Apple 真机稳定性预检迭代 1

日期：2026-07-17

本轮结论：**`V2-027 / P1` 已在仓库内关闭。Apple 设备预检不再解析易漂移的终端表格，也不再以单次 `available` 判断开发真机就绪；开发严格门禁现在强制同一台物理 iOS 设备连续至少 3 次满足配对、连接、开发者模式和 DDI 条件。当前连续实测为 0 台，命令以退出码 2 正确失败，真机矩阵继续保持未完成。**

## 1. 实测暴露的问题

`V2-026` 首次把证书、私钥、Profile、Bundle ID 和设备状态做了关联，但设备侧仍有两个缺口：

1. 工具解析 `xcrun devicectl list devices` 的人类可读表格；本机 `--help` 明确说明，写入文件的 JSON 是脚本消费的唯一受支持接口；
2. 开发严格门禁只采样一次。同一轮实测中配对设备连续出现 0→1→0 台 available，单点采样可能恰好落在瞬时在线窗口。

这不会把分发门禁误判为通过，但在账号团队配置完成后，可能把“设备短暂可见”错误升级为 `development_ready: true`，从而提前进入安装或真机验收。

## 2. 官方 JSON 输入契约

工具现在让 devicectl 把 `jsonVersion: 3` 结果写入自动清理的临时目录，并只读取以下字段：

| JSON 字段 | 用途 |
| --- | --- |
| `identifier` | 只用于进程内判断连续样本是否为同一设备；报告前做 SHA-256 截断哈希 |
| `connectionProperties.pairingState` | 必须为 `paired` |
| `connectionProperties.tunnelState` | 必须为 `available` 或 `connected` |
| `deviceProperties.developerModeStatus` | 必须为 `enabled` |
| `deviceProperties.ddiServicesAvailable` | 必须为 `true`，证明开发者磁盘映像服务实际可用 |
| `hardwareProperties.platform` | 必须为 `iOS` |
| `hardwareProperties.reality` | 必须为 `physical`，排除模拟器 |
| `hardwareProperties.marketingName` / `productType` | 只用于非个人化的机型诊断 |

`info.outcome` 不是 `success`、文件缺失或 JSON 无效都会记为 `audit_errors` 并以退出码 1 失败，不能当成“只是没有设备”。

## 3. 连续稳定性定义

普通只读报告默认采 1 次，便于快速查看；一旦使用 `--require-development`，即使调用者传入更小值，也会强制至少 3 次：

```text
minimum_samples = 3
same physical identifier in every sample
pairingState = paired in every sample
tunnelState in {available, connected} in every sample
developerModeStatus = enabled in every sample
ddiServicesAvailable = true in every sample
```

任一采样离线、缺失、开发者模式关闭或 DDI 不可用，该设备的 `stable_ready` 都是 false。不同设备在不同采样中轮流上线也不能互相拼成一次通过；同一 JSON 内的重复行会先按 identifier 去重，不能伪造连续样本。

这只是“可以开始开发安装”的前置条件，仍不等于真机矩阵、性能、触控、音频或 TestFlight 已完成。

## 4. 脱敏输出

devicectl 原始 JSON 可能含个人设备名称、`serialNumber`、UDID、ECID 和最近连接时间。发行报告不会序列化这些字段：

- 不输出设备自定义名称；
- 不输出序列号、UDID、ECID、主机名或最近连接时间；
- 原始 CoreDevice identifier 只在内存中关联样本；
- 对外只输出 12 位 `device_key` 哈希、标准机型、product type 和就绪原因。

专项回归明确注入 `must-not-leak` 序列号/UDID 和原始 identifier，并检查它们不会进入摘要。

## 5. 本机三连样本实测

命令：

```bash
python3 -B tools/release/apple_signing_readiness.py \
  --team-id 24U7H6TL68 --require-development --json
```

稳定性摘要：

```text
audit_errors: []
device_sample_count: 3
consecutive_ready_device_count: 0
development_ready: false
distribution_ready: false
exit: 2
```

脱敏设备观察：

| 机型 | seen | ready | 最后状态 | 开发者模式 | DDI | stable |
| --- | ---: | ---: | --- | --- | --- | --- |
| iPhone 12 Pro | 3 | 0 | unavailable | enabled | false | false |
| iPad mini（A17 Pro） | 3 | 0 | unavailable | disabled | false | false |

三次结果一致，没有再次命中此前的瞬时 available 窗口。即便后续某一次看到设备上线，严格门禁也必须等同一设备连续三次满足完整开发条件。

## 6. 专项回归覆盖

`tools/release/test_apple_signing_readiness.py` 新增并通过：

- 官方 JSON 字段解析与物理 iOS 设备判定；
- 同一设备连续三次就绪通过；
- 中间一次 unavailable 时失败；
- 两台设备轮流瞬时上线时失败；
- 开发者模式关闭时失败；
- 单个样本重复设备行不能冒充连续样本；
- 输出不包含原始 CoreDevice identifier；
- 原有证书过期、Profile 证书/私钥错配、团队与 Bundle ID 用例保持通过。

## 7. 本轮边界

本轮只读取本机状态，没有：

- 唤醒、配对、信任或安装任何真实设备；
- 打开 iPad 的开发者模式；
- 修改 Xcode 工程团队、Apple 账号或 Provisioning Profile；
- 把模拟器、开发签名编译或瞬时在线状态写成真机体验证据。

因此 `V2-027` 可以关闭，但 `V2-014`、真机矩阵与 `V2-006` 外测门槛均不受影响。

## 8. 回归验收

| 验收项 | 结果 |
| --- | --- |
| 设备 JSON/稳定性专项 | 通过；官方 JSON、三连同设备、波动/轮换/重复/开发者模式和脱敏用例全部通过 |
| 本机开发严格门禁 | 按预期失败；3 次采样、0 台连续就绪、无审计错误、退出码 2 |
| 完整发行门禁 | 通过；阶段 0～4、27 项问题登记、六组原生专项、发行静态、商店素材、公共页面和提交准备全部通过 |
| Release 模拟器运行 | 通过；专用 iOS 26.2 QA 模拟器重新安装并启动，PID 22127 在 37 秒复核时仍存活 |
| Release device compile | 通过；arm64 通用设备无签名构建成功 |
| 无签名 archive 内容检查 | 通过；`NewPirate-device-stability.xcarchive` 的版本、架构、隐私清单、动态库和遗留符号检查通过 |
