# 《海上探险家》V2：App Store Connect 合规提交包（迭代 1）

日期：2026-07-16

候选范围：iOS 2.0.0（build 1），Bundle ID `com.fancyGame.NewPirate`

本轮结论：**仓库内的商店文案、审核路径、内容分级事实、提交清单与准备态校验已经完成；开发者账号、真实联系信息、公开 URL、有效分发签名、上传构建、后台问卷、价格和发行地区仍未完成，严格提交校验保持失败，总体上线继续 HOLD。**

## 1. 为什么要建立独立提交包

工程可构建、商店截图合格和隐私页面有模板，并不代表 App Store Connect 已具备可提交状态。后台还要求产品页字段、App 记录、审核联系方式、年龄分级、App Privacy、出口合规、价格与地区、签名构建等彼此一致的信息；其中一部分可以从仓库事实生成，另一部分只能由有权限的账号或业务负责人确认。

本轮将两类信息明确分开：

- **仓库事实**：版本、Bundle ID、名称、功能范围、文案字节数、无登录/无广告/无内购、隐私清单、内容描述、截图设备组和审核路径；
- **外部事实**：Apple ID、SKU、名称可用性、法律主体、支持联系方式、公开 URL、开发者团队、证书/描述文件、上传 build ID、后台问卷结果、价格和发行地区。

外部事实没有证据时保持 `null`、`false` 或 `pending_external`，不使用示例域名、旧公司名、历史邮箱或推测的账号值填充。

## 2. Apple 当前字段基线

截至本文日期，按 Apple 当前帮助文档整理的主要限制如下：

| 字段 | 当前要求 | 本项目处理 |
| --- | --- | --- |
| App 名称 | 2～30 字符 | “海上探险家”，5 字；后台可用性待验证 |
| 副标题 | 不超过 30 字符 | “航海探索与船队成长”，9 字 |
| 宣传文本 | 不超过 170 字符 | 独立纯文本文件，当前 46 字符 |
| 描述 | 不超过 4000 字符，纯文本 | 当前 300 字符；只描述第一章已实现能力 |
| 关键词 | 不超过 100 UTF-8 字节；逗号分隔，不放 App/公司名 | 当前 90 字节；每项多于 2 个字符 |
| Privacy Policy URL | iOS 必填 | `V2-018` 阻塞，当前不填假地址 |
| Support URL | 必填，页面需有真实联系信息 | `V2-018` 阻塞，模板完成但未部署 |
| Copyright | 必填，年份加权利人；Apple 自动显示版权符号 | 权利主体未确认，保持空值 |
| 截图 | 必填，必须展示 App 实际使用状态 | 两个设备组共 8 张玩家截图已通过内部检查 |
| Review contact | 姓名、邮箱、电话供审核联系 | 真实负责人未提供，保持空值 |
| Review notes | 最多 4000 UTF-8 字节 | 当前 1261 字节，包含完整第一章审核路径 |
| 登录信息 | 仅在登录必需时提供 | 本候选无需登录，不创建虚假测试账号 |
| 年龄分级 | 必须回答问卷；`Unrated` 不能发布 | 内容事实已盘点，后台问卷未提交 |
| What’s New | 首个版本不显示，后续版本必填 | 2.0.0 是否属于现有 App 的更新需账号侧确认后处理 |

官方参考：

- [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
- [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)
- [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

后台字段和限制会变化；每次实际提交前应重新打开官方页面复核，而不是长期复制本文数值。

## 3. 本轮交付物

| 文件 | 用途 | 状态 |
| --- | --- | --- |
| `app-store-submission-manifest.json` | 机器可读的候选版本、产品页、审核、问卷、签名和地区状态 | 已建立；外部值保持未完成 |
| `metadata/zh-CN/promotional-text.txt` | 可直接复制的宣传文本 | 准备态通过 |
| `metadata/zh-CN/description.txt` | 可直接复制的纯文本描述 | 准备态通过 |
| `metadata/zh-CN/keywords.txt` | 100 字节内关键词 | 准备态通过 |
| `metadata/review-notes.zh-CN.txt` | 审核人员操作路径和范围说明 | 准备态通过 |
| `age-rating-content-inventory.json` | 年龄问卷逐项内容事实和证据 | 已盘点，待内容负责人确认 |
| `tools/release/validate_app_store_submission.py` | 准备态/严格态双层校验 | 已接入发行回归 |

文本不再只存在于 Markdown 草案中。这样可以减少从文档复制时引入项目符号、标题、旧文案或超长字段的风险。

## 4. 简体中文产品页结论

### 4.1 名称与定位

- 名称：“海上探险家”；
- 副标题：“航海探索与船队成长”；
- 主分类暂按 `Games` 准备，但仍需负责人确认主分类和游戏子分类；
- 当前范围明确为“完整第一章”，不宣传十六海域、多人联机、排行榜或开放世界；
- 描述明确当前无广告、抽卡、钻石商城和付费复活，避免与旧功能或未来规划混淆。

### 4.2 关键词

最终准备文本为：

```text
海盗冒险,远洋航海,海上战斗,迷雾探索,船队成长,接舷战斗,符文剧情
```

该文本为 90 UTF-8 字节，各词超过 2 个字符，不重复 App 名称，也没有竞品或无法兑现的功能词。实际发布后再根据搜索表现迭代，不应在首发前靠堆词扩大承诺。

### 4.3 审核路径

审核备注使用普通玩家入口，不依赖 QA 环境变量或隐藏手势：

1. 启动后进入第一章；
2. “握住水晶瓶”，选择模块并“驶入第一片迷雾”；
3. 选择安全或风险航线并处理事件；
4. 进行舰炮战，随后开始接舷；
5. 取得符文、返航并完成一次升级；
6. 顶部“隐私与支持”可以查看本地说明，真实 URL 配置后显示网页按钮。

备注同时说明无账号、无广告、无内购、无跟踪、本地存档和离线玩法边界，减少审核人员误找测试账号或旧功能的概率。

## 5. 年龄分级内容盘点

### 5.1 当前保守答案

`age-rating-content-inventory.json` 覆盖当前问卷相关的应用内控制、联网能力、成熟主题、性内容、暴力和随机/赌博内容。关键结论为：

| 内容项 | 准备答案 | 依据 |
| --- | --- | --- |
| 卡通/奇幻暴力 | Frequent | 舰炮与接舷是第一章反复执行的核心玩法 |
| 枪械或其他武器 | Frequent | 舰炮、重炮甲板和接舷武器持续出现 |
| 恐怖或恐惧主题 | Frequent | 诅咒、黑潮低语、诅咒罗盘、海魂追猎者贯穿首章 |
| 写实暴力/血腥 | None | 没有写实伤口、血液或真实人物伤害表现 |
| 性内容/裸露 | None | 当前第一章未发现 |
| 粗俗语言 | None，待复读确认 | 数据表未发现，提交前仍需内容负责人复读最终显示文本 |
| 酒精/烟草/药物 | None，待复核 | V2 可达内容未发现，不以旧版不可达内容代答 |
| 模拟赌博/真钱赌博 | None | V2 feature gate 关闭旧抽卡、赌博和商业化路径 |
| Loot Boxes | None | 没有付费随机物品或抽卡 |
| UGC/聊天/社交/广告 | None | 候选功能和二进制均不包含 |
| 不受限网页访问 | None | 没有内嵌浏览器，只能主动打开两个固定 HTTPS 页面 |

### 5.2 预期等级与边界

Apple 当前 iOS 26 分级定义中，频繁的卡通/奇幻暴力、枪械或武器、恐惧主题都可能进入 13+ 档。因此本轮将 **13+ 作为保守的预期最低等级**，不使用 4+ 或 9+ 做营销性低报。

这不是后台最终结果。内容负责人需在候选画面冻结后确认每个主观频率，账号负责人再把答案录入 App Store Connect；最终以后台计算的全球与地区分级为准。若结果是 `Unrated`，不得提交。

“Made for Kids”当前保持未选择。该选择在 App 获批后具有不可逆影响，必须由产品和合规负责人明确决定，不能因为美术卡通化就自动勾选。

## 6. App Privacy 与出口合规

提交清单当前准备答案为：

- Tracking：No；
- Data Collected：No；
- 无账号、广告、分析、崩溃上报、第三方数据 SDK 或内购；
- `PrivacyInfo.xcprivacy` 中跟踪为 `false`、跟踪域名为空、收集数据类型为空；
- `ITSAppUsesNonExemptEncryption = false`；
- 当前 iOS 候选已移除旧 curl/OpenSSL、WebSocket、XMLHttpRequest 和 LuaSocket；
- 隐私与支持页属于玩家主动打开的固定 HTTPS 外链。

这些答案仍需由签名 TestFlight 构建的网络复核支持。后台 App Privacy 和出口合规问卷没有实际提交前，清单状态只能是 `prepared_not_submitted`。

## 7. 账号、设备与签名预检

本轮只做了只读审计，没有创建证书、描述文件、App 记录或修改开发者账号。2026-07-17 的 `V2-026` 指纹关联复核更新了本节旧快照：

- 当前 `Apple Development` 私钥身份有效至 2027-04-19，并与覆盖 `24U7H6TL68.*`、有效至 2027-05-12 的开发 Profile 指纹匹配；原“2023 年过期”结论来自按同名证书人工取值，已经废止；
- 工程没有已确认的 `DEVELOPMENT_TEAM`，团队候选 `24U7H6TL68` 仍需账号负责人确认；
- 没有匹配 `com.fancyGame.NewPirate` 的 `Apple Distribution` 私钥身份和 App Store Profile；
- 已配对 iPhone 12 Pro 与 iPad mini 状态在连续采样间波动，最终复核均 unavailable，没有实际签名安装或真机体验证据；
- 因此仍只能使用无签名 archive 做工程内容验证，不能上传 App Store Connect，也不能关闭真机或 TestFlight 门槛。

权威详情及可复跑命令见 [`apple-signing-readiness-iteration-2.md`](apple-signing-readiness-iteration-2.md)。

任何证书申请、自动 provisioning、App 记录创建或设备安装都会改变外部账号/设备状态，需由账号负责人在明确授权和正确团队下执行。

## 8. 双层校验策略

### 8.1 准备态

常规回归执行：

```bash
python3 tools/release/validate_app_store_submission.py
```

准备态验证：

- manifest 版本与 Xcode 的 Bundle ID、version、build 一致；
- 名称、副标题、宣传文本、描述、关键词和审核备注符合当前长度/字节限制；
- 文案不含占位符、Markdown 标题或未实现功能承诺；
- 隐私答案与打包隐私清单一致；
- 年龄分级描述项完整，并保留 13+ 的保守基线；
- 截图清单与候选版本、设备组一致；
- 外部字段缺失会被逐项打印，但不会阻止内部代码回归。

当前准备态通过，并明确报告 30 个外部门槛未完成。

### 8.2 严格提交态

最终提交前执行：

```bash
python3 tools/release/validate_app_store_submission.py --strict
```

严格态要求全部具备：

- App 记录的 Apple ID、SKU、Bundle ID 归属和名称可用性；
- 两个公开 URL、权利人、分类、子分类和价格；
- 审核联系人和已选择的上传 build；
- App Privacy、年龄分级和出口合规后台提交状态；
- 内容负责人确认、后台计算等级和 Made for Kids 明确选择；
- 开发者团队、Distribution 身份、App Store profile、签名 archive 和上传 build ID；
- TestFlight 网络复核、上传校验、发行地区和发布方式。

严格态还会验证公开 URL 只能是非保留域名的 HTTPS 地址、App 内 URL 与 manifest 完全一致、版权格式和地区合规条件。当前严格态按预期失败，证明外部门槛没有被准备态误关闭。

## 9. App Store Connect 操作顺序

建议有权限的负责人按下列顺序执行，避免后置字段反复返工：

1. 确认开发者团队、法律主体和 `com.fancyGame.NewPirate` 的 Bundle ID 归属；
2. 验证“海上探险家”名称可用，创建或确认 App 记录，记录 Apple ID 与不可变 SKU；
3. 确认支持邮箱和权利人，生成、审核并部署隐私政策/支持页面；
4. 把两个真实 HTTPS URL 同步写入 App 和 manifest，执行线上页面严格校验；
5. 创建有效 Distribution 证书与 App Store profile，生成签名 archive 并运行 archive 校验；
6. 上传构建，在 TestFlight 做启动、真机矩阵、隐私外链和网络行为复核；
7. 上传截图，复制已校验的名称、副标题、宣传文本、描述、关键词和审核备注；
8. 完成 App Privacy 和出口合规问卷；
9. 由内容负责人确认盘点后完成年龄分级问卷，记录后台计算等级；
10. 确认主分类/游戏子分类、价格、发行地区、地区合规和发布方式；
11. 选择 build，填写审核联系人并逐项回读产品页；
12. 执行全部严格校验和全量发行回归，证据归档后再提交审核。

## 10. 当前 30 个严格门槛分组

| 分组 | 数量 | 当前缺口 |
| --- | ---: | --- |
| App 记录 | 4 | Apple ID、SKU、Bundle ID 归属、名称可用性 |
| 产品页 | 6 | 隐私/支持 URL、版权、分类确认、游戏子分类、价格 |
| 审核 | 4 | 联系人姓名/邮箱/电话、选择上传 build |
| 隐私 | 2 | 后台问卷提交、TestFlight 网络复核 |
| 年龄分级 | 4 | 问卷提交、计算等级、内容确认、Made for Kids 选择 |
| 出口合规 | 1 | 后台问卷提交 |
| 分发签名与上传 | 6 | 团队、证书、profile、签名 archive、build ID、上传校验 |
| 可用性 | 3 | 发行地区、地区确认、发布方式 |

任何一项未完成，都不能把 manifest 改成“通过”。对中国大陆或韩国等地区的额外合规字段，只有在实际发行地区包含对应市场时才要求填写，但地区选择本身必须先由负责人确认。

## 11. 与现有发布门槛的关系

- `V2-014` 继续负责开发者账号、签名、App 记录和上传；
- `V2-018` 继续负责真实主体、支持邮箱、隐私/支持 URL 与线上验证；
- 新增 `V2-019` 负责 App Store Connect 元数据、问卷、分类、价格、地区和审核提交的一致性；
- `V2-006` 和真机矩阵仍负责外部用户与真实设备证据；
- 本轮准备包不能替代上述门槛，只让缺口变得结构化、可校验、可交接。

## 12. 关闭 `V2-019` 的完成定义

只有同时满足以下条件才可关闭：

1. manifest 中全部外部字段来自真实账号/负责人证据；
2. 产品页文本与最终可达功能逐项回读一致；
3. App Privacy、年龄分级和出口合规均在后台完成；
4. 分类、价格、发行地区与发布方式获得负责人确认；
5. 审核联系人可实际响应，审核备注对应已选择的上传 build；
6. 签名 TestFlight 包的网络与真机行为符合声明；
7. `validate_app_store_submission.py --strict` 通过；
8. 全量发行回归、签名 archive 校验和 App Store Connect 上传校验通过；
9. 后台字段截图或导出、测试记录和提交构建 ID 已归档。

在此之前，权威结论保持 HOLD。

## 13. 本轮实际验收记录

- `tools/release/validate_ios_release.sh`：阶段 0～4、19 项问题登记、发行静态、8 张商店截图、隐私/支持模板和 App Store 提交准备态全部通过；
- `python3 tools/release/validate_app_store_submission.py`：准备态通过；名称 5 字、副标题 9 字、宣传文本 46 字、描述 300 字、关键词 90 字节、审核备注 1261 字节；
- `python3 tools/release/validate_app_store_submission.py --strict`：按预期失败并完整列出 30 个外部门槛；
- `CONFIGURATION=Release ./xcode.sh ios-sim`：命令退出成功，现有 Release 产物为 arm64，Bundle ID、version 和 build 与 manifest 一致；本轮没有把模拟器服务告警当作运行验收；
- `validate_ios_archive.py build/archives/NewPirate-privacy-support-final.xcarchive`：既有无签名 archive 内容复验通过；本轮只改提交资料与工具，没有生成或冒充签名 archive；
- 严格公网 URL、真实设备、TestFlight 网络和 App Store Connect 上传检查均未执行，因为对应真实条件不存在。
