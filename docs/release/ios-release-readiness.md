# 海上探险家 V2：iOS 发行就绪基线

日期：2026-07-16

工程版本：2.0.0（build 1）

当前结论：**无签名工程归档已验收；总体上线 HOLD，尚未获准提交 App Store**

## 1. 本文用途

本文把“内部样片通过”之后的工作拆成可复验的发行门槛。只有工程、账号、
真机、外测和商店素材五组门槛全部通过，版本才可以从候选归档转为提交版本。

当前 Bundle ID 暂定为 `com.fancyGame.NewPirate`。在 App Store Connect 确认其
归属并创建 App 记录之前，它不是最终结论；一旦上传构建，Bundle ID 不能再改，
因此不得跳过账号侧核验。

## 2. 当前发行范围

首个候选版本只交付 V2 第一章纵切：

- 打开水晶瓶并进入瓶中世界；
- 在海图上选择安全或风险航线；
- 完成一次舰炮战与接舷战；
- 取得第一枚符文线索，返港并完成升级；
- 保留本地存档恢复，不开放广告、钻石商城、抽卡、付费复活或旧版内购。

这仍是约 15～20 分钟的第一章候选，不等同于十六海域完整产品。第二张地图及
商业化继续受阶段 4 外测 GO 门槛约束。

## 3. 已完成的工程门槛

| 门槛 | 当前状态 | 工程证据 |
| --- | --- | --- |
| 可复现工程 | 通过 | Xcode 工程与 iOS/macOS shared scheme 纳入版本控制，不依赖个人 `xcuserdata` |
| 版本与签名配置 | 通过 | 2.0.0（1）；自动签名；删除旧团队、证书和 provisioning profile 硬编码 |
| 发行隐私面 | 通过 | 移除 IDFA、AdSupport、Google Mobile Ads、旧内购、兑换码和奖励评论桥接 |
| 隐私清单 | 通过 | `PrivacyInfo.xcprivacy` 随 App 打包；跟踪关闭、收集数据为空 |
| Required Reason API | 通过 | `NSUserDefaults` 使用 `CA92.1`；应用内音频文件时间戳使用 `C617.1` |
| 出口合规清理 | 通过 | iOS 目标移除应用 AES、2012 年 libcurl/OpenSSL、WebSocket、XMLHttpRequest 和 LuaSocket；Info 声明不使用非豁免加密 |
| App Icon 技术规格 | 通过 | 所有 catalog 槽位都有正确像素文件；1024 图标为 RGB 且无 Alpha |
| 商店视觉素材 | 通过 | `V2-015` 已关闭；V2 瓶中黑帆图标定稿，iPhone 6.9 英寸与 iPad 13 英寸各 4 张玩家截图均为 RGB、无 Alpha |
| 商店画面适配 | 通过 | `V2-017` 已关闭；iPhone 标题避开 Dynamic Island，iPad 紧凑布局无数值/按钮重叠 |
| 离线启动入口 | 通过 | `V2-016` 已关闭；干净安装 5 秒内进入第一章，再次唤起保持同一进程；启动与回前台不访问旧服务器时钟 |
| Release 自动验收 | 通过 | 阶段 0～4、发行静态、Release arm64 模拟器、无签名 device archive 与 archive 内容检查通过；详见 `ios-release-engineering-iteration-1.md` |

隐私结论只对应当前提交候选。签名包进入 TestFlight 后仍需做一次网络流量复核；
若以后接入统计、崩溃上报、账号、广告或内购，必须同步更新代码、隐私清单和
App Store Connect 隐私问卷。

## 4. 仍然阻塞上线的门槛

| 优先级 | 门槛 | 完成定义 | 当前状态 |
| --- | --- | --- | --- |
| P0 | 开发者账号与 Bundle ID | 在正确团队中确认 `com.fancyGame.NewPirate` 可用并创建 App 记录 | `V2-014`，待外部账号操作 |
| P0 | 签名与上传 | 选择 Distribution 证书/描述文件，生成签名 archive，并通过 App Store Connect 上传校验 | `V2-014`，待外部账号操作 |
| P0 | 隐私政策与隐私问卷 | 提供可公开访问的隐私政策 URL；按最终二进制回答 App Privacy | URL 待提供 |
| P0 | 年龄分级与合规问卷 | 按奇幻战斗、恐怖元素等真实内容完成新版年龄分级和出口合规问卷 | 待 App Store Connect 操作 |
| P1 | 真机矩阵 | 至少一台低端 iPhone、一台现代 iPhone 和一台 iPad 验收触控、音量、发热、帧率和恢复 | 尚未完成 |
| P1 | 两轮目标用户外测 | 按阶段 4 协议完成两轮并达到理解率、继续意愿和核心幻想回忆阈值 | `V2-006` 未关闭 |
| P1 | 商店文案与本地化 | 名称可用性、描述、关键词、支持 URL、审核备注全部在后台校验 | 已有草案，待账号侧定稿 |

以上 P0 未完成时不得上传；P1 未完成时不得把版本标记为可上线。模拟器和无签名
archive 只能证明工程可构建，不能替代真机、签名或 App Review 结果。

## 5. Apple 当前要求基线

截至 2026-07-16，本项目按以下官方要求准备：

- 2026-04-28 起，上传需使用 Xcode 26 或更新版本，并基于 iOS/iPadOS 26 SDK；
  本机 Xcode 26.2 满足工具链门槛；
- 使用指定 API 的 App 需要随包提交隐私清单和有效的 required-reason；
- App Store Connect 仍需单独填写 App Privacy，且 iOS App 必须提供隐私政策 URL；
- 构建的 Bundle ID 对应 App 记录，版本号与 build number 用于 App Store Connect
  的版本/构建映射；首次上传前必须确认标识符。

官方参考：

- [Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Manage App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds)
- [App information reference](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Overview of export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance)
- [`ITSAppUsesNonExemptEncryption`](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption)
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Upload app previews and screenshots](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots)

## 6. 每次候选版本的验收命令

```bash
# 阶段 0～4 全量回归 + 发行静态检查
tools/release/validate_ios_release.sh

# Release 模拟器构建
CONFIGURATION=Release ./xcode.sh ios-sim

# Release arm64 通用设备编译（默认不签名）
CONFIGURATION=Release ./xcode.sh ios-device

# Release 无签名 archive
./xcode.sh ios-archive

# 检查 archive 的版本、架构、隐私清单、动态库和遗留符号
python3 tools/release/validate_ios_archive.py build/archives/NewPirate.xcarchive
```

账号准备完成后，另用 `CODE_SIGNING_ALLOWED=YES` 和已选定的团队生成分发 archive。
签名 archive 通过上传校验、真机和 TestFlight 测试后，才可把发行结论改为 GO。

本轮已验证的无签名 archive 只作为工程证据，默认位于
`build/archives/NewPirate.xcarchive`，不纳入版本控制。完整结果见
[`ios-release-engineering-iteration-1.md`](ios-release-engineering-iteration-1.md)。

## 7. 上线前逐项签字

- [ ] 产品：第一章范围、名称和商业模式确认；
- [ ] 程序：完整回归、Release 模拟器、设备编译、archive 验证通过；
- [ ] 测试：真机矩阵无 P0/P1，存档升级与重装路径通过；
- [ ] 用户研究：两轮外测阈值通过，原始匿名证据归档；
- [x] 美术：图标、三类核心叙事和两个最高分辨率设备组已完成内部商店评审；
- [ ] 运营/法务：隐私政策、支持 URL、年龄分级、出口合规和版权确认；
- [ ] 账号负责人：Bundle ID、签名、App 记录和上传校验通过。
