# Apple 签名就绪预检迭代 2

日期：2026-07-17

本轮结论：**`V2-026 / P1` 已在仓库内关闭；NewPirate 的 Apple 签名状态从人工摘录改为可重复、可严格失败的只读预检。当前开发证书与开发 Profile 链有效，但工程团队尚未确认、真机连接不稳定，且没有匹配 NewPirate 的 App Store 分发链，因此 `development_ready: false`、`distribution_ready: false`，`V2-014 / P0` 继续开启。**

## 1. 为什么需要这一轮

此前发布记录用证书显示名称和 Profile 是否存在来判断状态。钥匙串中可能同时存在同名旧证书，而 `security find-identity` 的一行摘要也不能单独证明 Profile、Bundle ID、团队、私钥与有效期全部匹配。这种人工流程曾把当前有效的开发身份误记为 2023 年已过期，不能作为上线决策依据。

本轮新增：

- `tools/release/apple_signing_readiness.py`：读取而不修改钥匙串、Provisioning Profile、Xcode 工程和 CoreDevice 状态；
- `tools/release/test_apple_signing_readiness.py`：锁定通配/精确 Bundle ID、证书过期、Profile 内嵌证书与本机私钥不匹配、团队和设备门禁；
- `--require-development` 与 `--require-distribution`：条件不满足时以退出码 2 严格失败；
- 完整发行门禁自动运行纯本地解析回归，但不会把某台开发机的证书或设备状态写成仓库通用通过条件。

## 2. 判定模型

| 层级 | 只读证据 | 通过条件 |
| --- | --- | --- |
| 身份 | `security find-identity -v -p codesigning` 与钥匙串全部证书 | 以 SHA-1 指纹关联真正带私钥的身份，再检查证书实际到期时间与团队，不按显示名称猜测 |
| Profile | 两个 Xcode 常用 Profile 目录，逐个执行 `security cms -D` | 未过期；团队匹配；`application-identifier` 精确或通配匹配目标 Bundle ID |
| 身份/Profile 链 | Profile 的 `DeveloperCertificates` | Profile 内嵌证书指纹必须命中本机未过期、类型正确且带私钥的 codesigning identity |
| 工程 | `project.pbxproj` | `DEVELOPMENT_TEAM` 必须与已确认团队一致；当前仓库不在未确认前硬编码个人团队 |
| 开发真机 | `xcrun devicectl list devices` | 至少一台已配对设备在本次验收期间持续 available；瞬时出现不等于真机矩阵完成 |
| App Store 分发 | Distribution identity + App Store profile | 两者均未过期、指纹相连、团队及 `com.fancyGame.NewPirate` 一致 |

只要其中任一关系断开，预检都会保留阻塞项，而不是用“证书存在”或“Profile 存在”替代可签名结论。

## 3. 2026-07-17 本机只读快照

目标候选：

- Bundle ID：`com.fancyGame.NewPirate`；
- 观测到的团队候选：`24U7H6TL68`；
- 工程内已确认团队：空；团队候选仍需账号负责人确认，不因本机存在开发身份而自动写入工程。

### 3.1 开发身份

| 字段 | 结果 |
| --- | --- |
| 名称 | `Apple Development: Zhiqiang Li (8Z4SDCM935)` |
| SHA-1 指纹 | `551AA974D457F137BFEE66838213D36FB327AF47` |
| 团队 | `24U7H6TL68` |
| 到期时间 | 2027-04-19 13:49:46 UTC |
| 私钥身份 | 存在；由 `find-identity` 指纹与证书指纹关联确认 |

因此，“本机开发证书已于 2023-10-05 过期”是旧人工取证方法造成的错误结论。新的权威结论是：**当前开发身份未过期。**

### 3.2 开发 Profile

本机存在一个可匹配目标 Bundle ID 的当前开发 Profile：

| 字段 | 结果 |
| --- | --- |
| 名称 | `iOS Team Provisioning Profile: *` |
| UUID | `c3cdad5c-fc0c-479b-a4ef-eb261b799a05` |
| application-identifier | `24U7H6TL68.*` |
| 到期时间 | 2027-05-12 03:07:53 UTC |
| 内嵌证书指纹 | `551AA974D457F137BFEE66838213D36FB327AF47` |
| 与本机私钥身份关系 | 匹配 |

本机另外可见的 Store/开发 Profiles 属于其他 Bundle ID，不能拿来给 NewPirate 分发签名。

### 3.3 分发身份与 Profile

- 匹配 `com.fancyGame.NewPirate` 的未过期 App Store Distribution Profile：0；
- 可与之相连的未过期 Apple Distribution 私钥身份：0；
- 可用 App Store 分发链：0。

这是当前不能生成可上传 archive 的直接签名原因；开发链可用不等于分发链可用。

### 3.4 真实设备

配对列表可见 iPhone 12 Pro 与 iPad mini（A17 Pro），但状态在连续预检间出现 `unavailable → available → unavailable` 波动。最终复核时两台均为 `unavailable`，且没有完成任何签名安装、触控、性能或音频验收。因此本轮不把瞬时在线计作真实设备证据，真机矩阵仍保持未完成。

## 4. 机器报告与严格门禁

常规审计命令：

```bash
python3 -B tools/release/apple_signing_readiness.py \
  --team-id 24U7H6TL68 --json
```

稳定字段的实测摘要：

```text
audit_errors: []
identity_count: 1
unexpired_identity_count: 1
matching_development_profile_count: 1
usable_development_profile_count: 1
matching_distribution_profile_count: 0
usable_distribution_profile_count: 0
project_team_ids: []
development_ready: false
distribution_ready: false
```

`available_device_count` 是实时值，连续采样出现 0 和 1，不能固化为仓库事实。严格门禁实测均以退出码 2 失败：

```bash
python3 -B tools/release/apple_signing_readiness.py \
  --team-id 24U7H6TL68 --require-development

python3 -B tools/release/apple_signing_readiness.py \
  --team-id 24U7H6TL68 --require-distribution
```

开发严格门禁至少受工程团队未确认阻塞；分发严格门禁同时受 NewPirate Distribution identity/profile 链缺失阻塞。设备如果再次离线，开发门禁还会明确增加设备阻塞。

作为关联结论的补充，本轮还执行了一次不带 `-allowProvisioningUpdates` 的本地 Release arm64 开发签名编译。构建只通过命令行临时传入 `DEVELOPMENT_TEAM=24U7H6TL68`，没有改工程或 Apple 账号；结果如下：

```text
codesign --verify --deep --strict: exit 0
Identifier=com.fancyGame.NewPirate
Authority=Apple Development: Zhiqiang Li (8Z4SDCM935)
TeamIdentifier=24U7H6TL68
application-identifier=24U7H6TL68.com.fancyGame.NewPirate
architecture=arm64
```

这证明本机现有开发身份/Profile 链确实能签出本地开发产物，也验证了预检没有误报。但临时团队 override、未安装到真机的开发签名 App 仍不能替代账号归属确认、稳定设备验收或 App Store 分发链，所以两类 readiness 结论不变。

## 5. 本轮关闭与未关闭范围

`V2-026` 的完成定义已经满足：

1. 不再按证书名字或 Profile 文件数量做签名结论；
2. 有效期、团队、Bundle ID、证书指纹、私钥身份、工程团队和设备状态可联合判断；
3. 解析回归能覆盖易误判的边界；
4. 当前不足以开发安装或 App Store 分发时，严格命令可靠失败；
5. 工具全程只读，不申请证书、不更新 Profile、不创建 App 记录、不安装设备包。

`V2-014` 仍未满足：

- 团队 `24U7H6TL68` 及 `com.fancyGame.NewPirate` 归属尚未由账号负责人确认；
- 工程/CI 尚未获得受控的最终 `DEVELOPMENT_TEAM` 配置；
- 没有 NewPirate 的 Distribution 私钥身份和 App Store Profile；
- 没有签名 archive、上传校验或 TestFlight build ID；
- 真机矩阵没有稳定连接和实际执行记录。

## 6. 外部条件具备后的执行顺序

1. 账号负责人确认正确 Team、Bundle ID 归属与 App Store Connect App 记录；
2. 在明确授权下建立或选择 NewPirate 的 Apple Distribution 私钥身份和 App Store Profile；
3. 通过受控 Xcode/CI 配置传入确认后的 `DEVELOPMENT_TEAM`，不要复用未知旧团队；
4. USB 连接、解锁并信任真机，使设备在完整验收期间持续 available；
5. 先让 `--require-development` 通过，再生成签名开发包并执行真机矩阵；
6. 让 `--require-distribution` 通过，生成签名 archive，执行 archive 校验与 App Store Connect 上传校验；
7. 用真实 TestFlight 构建复核网络、隐私、恢复、触控、性能和音频，再关闭 `V2-014`。

任何账号创建、证书申请、自动 provisioning 更新、App 记录创建、设备安装或上传都属于外部状态变更，需要账号/设备负责人明确授权；本轮没有代做或伪造。

## 7. 回归验收

| 验收项 | 结果 |
| --- | --- |
| 解析专项回归 | 通过；通配/精确/错误 Bundle ID、过期身份、证书私钥错配、工程团队和设备门禁均覆盖 |
| 本机普通只读审计 | 通过；无 `audit_errors`，真实输出保持两类 readiness 为 false |
| 开发严格门禁 | 按预期失败；退出码 2，不误报开发安装已就绪 |
| 分发严格门禁 | 按预期失败；退出码 2，不误报 App Store 分发已就绪 |
| 本地开发签名探针 | 通过；未允许 provisioning 更新，Release arm64 构建与 `codesign --verify --deep --strict` 均成功，身份、Team 和 application-identifier 一致 |
| 完整发行门禁 | 通过；阶段 0～4、26 项问题登记、六组原生专项、发行静态、商店素材、公共页面和提交准备全部通过 |
| Release 模拟器运行 | 通过；专用 iOS 26.2 QA 模拟器重新安装并启动，PID 13764 在 20 秒复核时仍存活 |
| Release device compile | 通过；arm64 通用设备无签名构建成功 |
| 无签名 archive 内容检查 | 通过；`NewPirate-signing-readiness.xcarchive` 的版本、架构、隐私清单、动态库和遗留符号检查通过 |
