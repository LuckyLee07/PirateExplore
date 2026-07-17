# 海上探险家 V2：iOS 发行就绪基线

日期：2026-07-17

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
| 本地存档耐久性 | 通过 | `V2-020` 已关闭；底层容器边界、LZSS 容量、原子写入、32 位旧档与物理截断恢复通过 ASan/UBSan 和 iOS Release 运行验收 |
| 原生缓冲所有权 | 通过 | `V2-021` 已关闭；Cocos `Data` 的复制/移动自赋值、别名复制及 `fastSet`/移动替换通过静态分析和 ASan/UBSan 回归 |
| 本地文件安全读取 | 通过 | `V2-022` 已关闭；启动/资源共用读取路径验证定位、非负长度、上限、分配和完整读取，空文件及失败路径通过 ASan/UBSan 回归 |
| 旧配置迁移所有权 | 通过 | `V2-023` 已关闭；旧 `UserDefault.xml` 的无效、空根、缺键和迁移路径由 RAII 统一释放，专项压力回归与 Release 静态分析通过 |
| 纹理图集缓冲边界 | 通过 | `V2-024` 已关闭；0 容量不分配、不向空地址清零，负值、乘法溢出、16 位索引上限和部分分配失败均有运行时保护与 ASan/UBSan 回归 |
| iOS 主视图输入契约 | 通过 | `V2-025` 已关闭；MRC 组合文本和复制属性在视图销毁时释放并移除通知观察者，`UITextInput` 选区接口保持非空返回，Release 静态分析归零 |
| Apple 签名就绪预检 | 通过 | `V2-026` 已关闭；以身份/Profile 证书指纹联合校验有效期、团队、Bundle ID、工程团队和真机状态，并提供开发/分发严格失败门禁 |
| Apple 真机稳定性预检 | 通过 | `V2-027` 已关闭；改用 devicectl 官方 JSON，开发严格模式要求同一物理设备至少三次连续满足配对、连接、开发者模式和 DDI 条件，设备标识脱敏 |
| iOS 签名产物完整性 | 通过 | `V2-028` 已关闭；联合验证 strict codesign、Info/signature/entitlements/Profile、leaf 证书指纹、有效期、arm64 与开发/分发模式；当前只证明 Development App |
| App Store 最终聚合门禁 | 通过 | `V2-029` 已关闭；30 个外部字段零 pending 后强制运行 strict manifest、公网页面、archive 内容和 Distribution App；空/skipped/failed 均 HOLD |
| 真机体验证据门禁 | 通过 | `V2-031` 已关闭内部工具缺口；三类设备必须同候选完成 14 项检查和最低时长，最终只接受同一个 TestFlight build；当前零记录，体验门槛仍未通过 |
| 总体产品上线聚合门禁 | 通过 | `V2-032` 已关闭内部工具缺口；联合完整发行、外测、TestFlight 真机、App Store 和候选一致性；当前 47 项 pending，总体仍 HOLD |
| archive 产物溯源 | 通过 | `V2-037` 已关闭；App 内嵌候选 ID、源码提交与 dirty 状态，clean 候选同时校验 HEAD、App/dSYM UUID 与二进制 SHA-256 |
| 隐私/支持内部准备 | 通过 | V2 顶栏入口、本地说明、公开页面模板、渲染和分层校验工具完成；真实 URL 仍由 `V2-018` 阻塞 |
| App Store Connect 内部准备 | 通过 | 提交 manifest、纯文本元数据、审核路径、年龄分级事实盘点和准备/严格双层校验完成；账号侧填写仍由 `V2-019` 阻塞 |
| Release 自动验收 | 通过 | 阶段 0～4、发行静态、Release arm64 模拟器、无签名 device archive 与 archive 内容检查通过；详见 `ios-release-engineering-iteration-1.md` |

隐私结论只对应当前提交候选。签名包进入 TestFlight 后仍需做一次网络流量复核；
若以后接入统计、崩溃上报、账号、广告或内购，必须同步更新代码、隐私清单和
App Store Connect 隐私问卷。

## 4. 仍然阻塞上线的门槛

| 优先级 | 门槛 | 完成定义 | 当前状态 |
| --- | --- | --- | --- |
| P0 | 开发者账号与 Bundle ID | 在正确团队中确认 `com.fancyGame.NewPirate` 可用并创建 App 记录 | `V2-014`，待外部账号操作 |
| P0 | 签名与上传 | 选择 Distribution 证书/描述文件，生成签名 archive，并通过 App Store Connect 上传校验 | `V2-014`，待外部账号操作 |
| P0 | 隐私政策、支持页与隐私问卷 | 验证真实主体/支持邮箱，部署两个公开 HTTPS 页面，配置 App 内与后台 URL；按最终二进制回答 App Privacy | `V2-018`；模板已完成，外部值与上线证据待提供 |
| P0 | 年龄分级与合规问卷 | 按奇幻战斗、恐怖元素等真实内容完成新版年龄分级和出口合规问卷 | 待 App Store Connect 操作 |
| P0 | App Store Connect 提交一致性 | 确认 App 记录、分类、价格、地区、审核联系人、所有问卷和上传构建；严格提交校验通过 | `V2-019`；仓库准备包完成，30 个外部门槛待关闭 |
| P1 | 真机矩阵 | 至少一台低端 iPhone、一台现代 iPhone 和一台 iPad 验收触控、音量、发热、帧率和恢复 | 尚未完成 |
| P1 | 两轮目标用户外测 | 按阶段 4 协议完成两轮并达到理解率、继续意愿和核心幻想回忆阈值 | `V2-006` 未关闭 |
| P1 | 商店文案与本地化 | 名称可用性、描述、关键词、支持 URL、审核备注全部在后台校验 | 已有草案，待账号侧定稿 |

以上 P0 未完成时不得上传；P1 未完成时不得把版本标记为可上线。模拟器和无签名
archive 只能证明工程可构建，不能替代真机、签名或 App Review 结果。

2026-07-17 的指纹关联预检纠正了旧结论：当前 `Apple Development` 私钥身份有效至 2027-04-19，并与覆盖目标 Bundle ID 的未过期开发 Profile 相连。上线仍受工程团队未确认、真机状态波动，以及 NewPirate Distribution identity/App Store Profile 完全缺失阻塞。详细机器证据和账号操作顺序见 [`apple-signing-readiness-iteration-2.md`](apple-signing-readiness-iteration-2.md)。

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
- [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)
- [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)
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

# 只读查看本机开发/分发签名关联状态；不修改 Apple 账号
python3 -B tools/release/apple_signing_readiness.py \
  --team-id 24U7H6TL68 --json

# Release 无签名 archive
./xcode.sh ios-archive

# 检查 archive 的版本、架构、隐私清单、动态库和遗留符号
python3 tools/release/validate_ios_archive.py build/archives/NewPirate.xcarchive

# 冻结候选还需精确匹配干净 HEAD，并记录二进制与 dSYM 指纹
python3 tools/release/archive_provenance.py build/archives/NewPirate.xcarchive \
  --expected-source-commit <冻结 Git SHA> \
  --expected-candidate-id 2.0.0-1-internal \
  --require-clean-head \
  --record-output /path/to/internal-candidate-provenance.json

# App Store Connect 准备态：允许外部字段待办，但校验文本、隐私、分级与构建一致性
python3 tools/release/validate_app_store_submission.py

# 最终提交前：要求 App 已配置真实页面，并从公网验证内容
python3 tools/release/validate_public_release_pages.py \
  --require-app-links --check-live-urls

# 最终提交前：账号、签名、上传、问卷、价格和地区全部必须有证据
python3 -B tools/release/apple_signing_readiness.py \
  --team-id <已确认团队> --require-development --require-distribution

python3 -B tools/release/validate_ios_signed_app.py /path/to/exported/App.app \
  --team-id <已确认团队> --mode distribution

python3 tools/release/validate_app_store_submission.py --strict

# App Store 提交 GO 入口；不代表产品总体可上线
python3 -B tools/release/final_app_store_gate.py --json

# 真机开发排障；最终上线必须追加 --require-testflight
python3 -B tools/release/validate_device_acceptance.py \
  /path/to/device-acceptance-records.csv --require-testflight --json

# 唯一产品总体 GO 入口；聚合完整发行、外测、真机、App Store 和同候选证据
python3 -B tools/release/final_product_launch_gate.py --json
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
