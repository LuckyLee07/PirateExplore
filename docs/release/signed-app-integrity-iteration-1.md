# iOS 签名产物完整性迭代 1

日期：2026-07-17

本轮结论：**`V2-028 / P1` 已在仓库内关闭。新增签名 App 产物验证器后，本地 Release arm64 开发签名 App 的 codesign 完整性、Bundle ID、Team、entitlements、embedded Profile、leaf 证书指纹、有效期和架构全部一致；同一产物按 App Store 分发模式校验时以退出码 2 正确失败。当前仍没有真正的 Distribution/App Store 产物，因此 `V2-014 / P0` 继续开启。**

## 1. 为什么材料预检还不够

`V2-026` 能证明本机证书、私钥和 Profile 有可用关联，`V2-027` 能证明真机是否稳定可开发。但最终 `.app` 仍可能因为构建参数、Scheme、团队 override 或 Xcode 自动选择发生偏差，例如：

- Info.plist 是目标 Bundle ID，code signature identifier 却不同；
- 使用正确 Team 的证书，但 embedded Profile 属于其他 Bundle ID；
- App 用一个 leaf 证书签名，Profile 内嵌的是另一个证书；
- 开发签名包被当作 App Store 包，仍带 `get-task-allow=true` 和设备列表；
- 签名结构有效，但 Profile 已过期或可执行文件不是 arm64。

因此本轮把“签名前材料就绪”和“签名后产物事实”拆成两个独立门禁。前者不能代替后者，codesign 命令退出 0 也不能单独证明 App Store 模式正确。

## 2. 新增工具

```bash
python3 -B tools/release/validate_ios_signed_app.py /path/to/App.app \
  --team-id <已确认团队> --mode development|distribution --json
```

工具只读取给定 App，并执行：

1. `codesign --verify --deep --strict` 验证签名与 sealed resources 完整性；
2. `codesign -dvvv` 读取实际 identifier、Authority 和 TeamIdentifier；
3. `codesign -d --entitlements - --xml` 读取签名内真实 entitlements；
4. `security cms -D` 解码 App 内 `embedded.mobileprovision`；
5. `codesign --extract-certificates` 只读提取签名证书链到自动清理的临时目录；
6. 用 SHA-1 指纹证明 leaf 签名证书确实属于 Profile 的 `DeveloperCertificates`，并用 OpenSSL 读取 leaf 的实际到期时间；
7. 用 `lipo` 确认可执行文件包含 arm64；
8. 联合检查 Info、signature、entitlements 与 Profile 的 Team/Bundle ID 一致性。

工具不访问开发者账号、不更新 Profile、不重签 App，也不把任何构建产物写入版本控制。

后续 `V2-040` 为同一工具增加 `--expected-source-commit`、`--expected-candidate-id` 和 `--require-clean-provenance`；最终 Distribution 门禁会强制使用三者，把签名产物绑定到产品总体 `release_commit`，详见 [`final-candidate-identity-iteration-1.md`](final-candidate-identity-iteration-1.md)。

## 3. 共同门槛

无论开发还是分发模式，都必须同时满足：

| 门槛 | 完成条件 |
| --- | --- |
| 签名结构 | strict verify 成功，sealed resources 未被修改 |
| Bundle ID | Info、codesign Identifier、签名 `application-identifier` 三者均为 `com.fancyGame.NewPirate` |
| Team | codesign TeamIdentifier、team entitlement、Profile TeamIdentifier 均为期望团队 |
| Profile 范围 | Profile 的 application-identifier 精确或通配允许目标 Bundle ID |
| leaf/Profile 关联 | 实际签名 leaf SHA-1 必须出现在 Profile DeveloperCertificates 中 |
| 有效期 | 实际签名 leaf 证书和 embedded Profile 均未过期 |
| 架构 | App 主可执行文件包含 arm64 |

审计命令失败、plist 无法解析或证书链无法提取时退出码为 1；产物可以读取但不满足门槛时退出码为 2；只有全部通过才返回 0。

## 4. 开发与 App Store 模式不能混用

### 4.1 development

- Authority 必须为 Apple Development / iPhone Developer；
- App 和 Profile 都必须有 `get-task-allow=true`；
- Profile 必须包含可安装设备列表。

### 4.2 distribution

- Authority 必须为 Apple Distribution / iPhone Distribution；
- App 和 Profile 均不得有 `get-task-allow=true`；
- Profile 不得包含 `ProvisionedDevices`；
- Profile 不得是 `ProvisionsAllDevices` 的企业分发类型。

这使 Development、Ad Hoc、Enterprise 和 App Store Profile 不会仅凭“签名有效”被混成同一个发布状态。

## 5. 本地开发签名 App 实测

被测产物：Release、iphoneos、arm64；构建时没有使用 `-allowProvisioningUpdates`。

development 模式摘要：

```text
audit_errors: []
passed: true
mode: development
bundle_id: com.fancyGame.NewPirate
team_id: 24U7H6TL68
authority: Apple Development: Zhiqiang Li (8Z4SDCM935)
leaf_certificate_fingerprint: 551AA974D457F137BFEE66838213D36FB327AF47
leaf_certificate_expiration: 2027-04-19T13:49:46+00:00
profile_name: iOS Team Provisioning Profile: *
profile_expiration: 2027-05-12T03:07:53+00:00
profile_application_identifier: 24U7H6TL68.*
signed_application_identifier: 24U7H6TL68.com.fancyGame.NewPirate
get-task-allow: true
architecture: arm64
```

说明本机开发签名链不仅材料匹配，最终 App 也确实按预期签出。

## 6. 分发模式负向验收

同一开发 App 用 `--mode distribution` 复验，以退出码 2 失败，并同时报告：

1. `not signed by a distribution identity`；
2. `distribution app must not have get-task-allow=true`；
3. `distribution profile must not have get-task-allow=true`；
4. `App Store profile must not contain provisioned devices`。

因此开发签名编译不会因为 codesign 本身有效而被错误记录为 App Store 可上传产物。

## 7. 自动回归

纯本地 fixture 覆盖：

- 合法 Development 通配 Profile；
- 合法 App Store 精确 Profile；
- codesign 多级 Authority 解析；
- Team 错配；
- leaf 证书不属于 Profile；
- leaf 证书或 Profile 已过期；
- Development 产物冒充 Distribution；
- `get-task-allow` 与设备列表的模式边界。

完整发行门禁只运行这些确定性 fixture，不依赖某台开发机持有 Apple 私钥；真实签名 App 验证作为候选版本发布验收命令单独执行。

## 8. 未关闭范围

本轮没有也不能证明：

- 团队 `24U7H6TL68` 已由账号负责人确认为最终发布团队；
- 已创建 `com.fancyGame.NewPirate` 的 App Store Connect App 记录；
- Apple Distribution 私钥身份和 NewPirate App Store Profile 存在；
- distribution 模式对真正的分发 App 已通过；
- 签名 archive 已上传或产生 TestFlight build ID；
- 真机矩阵和两轮外部用户测试已执行。

最终提交前必须对导出的真实 App Store `.app` 再运行 `--mode distribution` 并通过；不能复用本轮 Development 结果。

`V2-029` 已将该 Distribution 检查纳入唯一最终 GO 入口，见 [`final-app-store-gate-iteration-1.md`](final-app-store-gate-iteration-1.md)。

## 9. 回归验收

| 验收项 | 结果 |
| --- | --- |
| 签名产物纯本地专项 | 通过；开发/分发正例与 Team、证书、过期、模式错用负例全部通过 |
| 真实 Development App | 通过；strict codesign、leaf/Profile 指纹、Team、Bundle ID、entitlements、Profile 有效期和 arm64 一致 |
| Development 冒充分发 | 按预期失败；4 个模式错误完整输出，退出码 2 |
| 完整发行门禁 | 通过；阶段 0～4、28 项问题登记、八组原生/发布专项、发行静态、商店素材、公共页面和提交准备全部通过 |
| Release 模拟器运行 | 通过；专用 iOS 26.2 QA 模拟器重新安装并启动，PID 37595 在 19 秒复核时仍存活 |
| Release device compile | 通过；arm64 通用设备无签名构建成功 |
| 无签名 archive 内容检查 | 通过；`NewPirate-signed-app-integrity.xcarchive` 的版本、架构、隐私清单、动态库和遗留符号检查通过 |
