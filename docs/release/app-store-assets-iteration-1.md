# 《海上探险家》V2：App Store 商店素材迭代 1

日期：2026-07-16

版本：2.0.0（build 1）

状态：**内部验收通过；`V2-015` 已关闭**

## 1. 本轮目标与边界

本轮把发行工程基线之后仍缺失的商店视觉资产变成可直接交给 App Store Connect
的文件包，同时用真实运行画面反查发布 UI。交付范围包括：

- 一套与项目策划、美术原稿一致的 V2 App Icon；
- 简体中文 iPhone 6.9 英寸和 iPad 13 英寸截图，各 4 张；
- 素材清单、尺寸/Alpha/排序自动校验；
- 截图评审中发现的 iPhone 安全区与 iPad 布局问题修复；
- 可复验的设计依据、生成提示词、筛选记录和验收结论。

本轮只能证明素材包、模拟器运行画面和无签名发行工程满足内部门槛；不能替代
真机矩阵、目标用户外测、Distribution 签名、App Store Connect 上传校验或
App Review。

## 2. 原项目策划与美术依据

图标没有沿用旧版照片式“月夜帆船”方向，而是重新对齐 Desktop/Pirate 中的
瓶中世界、诅咒航海与羊皮海图语义。主要参考如下：

| 外部参考 | 本轮提取的设计语言 |
| --- | --- |
| `/Users/lizi/Desktop/Pirate/bin/res/assets/Images/Plot/juqing_6.png` | 水晶瓶叙事、墨色与旧纸材质 |
| `/Users/lizi/Desktop/Pirate/bin/res/assets/Images/Plot/juqing_7.png` | 瓶体轮廓与封印感 |
| `/Users/lizi/Desktop/Pirate/bin/res/assets/Images/Plot/juqing_9.png` | 黑帆船剪影与远航幻想 |
| `/Users/lizi/Desktop/Pirate/bin/res/assets/Images/Boss/g_300.png` | 轻暗黑诅咒气氛与青绿色冷光 |

最终视觉关键词为：`瓶中海盗船`、`深青海水`、`墨黑船帆`、`旧金边缘光`、
`单点珊瑚红符文`、`精致卡通 2.5D`。图标刻意不放标题、字母、骷髅徽章、
巨大月亮或复杂边框，避免在 60 px 主屏幕尺寸下变成不可辨认的纹理。

## 3. App Icon 生成、筛选与定稿

### 3.1 生成方式

模式：内置图像生成；V1 为多参考新生成，V2 为引用 V1 的精确对象编辑。

V1 提示词组：

```text
Create a premium stylized 2.5D iOS App Store icon for a dark pirate adventure.
Use the supplied legacy references only for the crystal-bottle narrative, ink-and-parchment
texture, black-sailed ship silhouette, and restrained cursed mood; create an original design.
Show a cursed pirate ship sealed inside a crystal bottle over a deep teal sea, centered and
readable at 60 px. Use ink black, deep teal, parchment gold, and one restrained coral-red
accent. Bold silhouette, clean focal hierarchy, high material polish, square edge-to-edge
composition. No text, letters, logo, watermark, giant moon, skull emblem, transparent
background, or baked rounded corners.
```

V2 精修提示词组：

```text
Precisely edit the supplied V1 icon while preserving its palette, glass material, lighting,
and premium 2.5D style. Make the bottle more upright and centered; reduce the cork; enlarge
the black-sailed pirate ship by about 25 percent; show three clearly separated masts and bold
simple sails; remove excess rigging and red wisps; keep only one small coral rune accent.
Improve silhouette recognition at 60 px. No text, letters, logo, watermark, giant moon,
skulls, alpha channel, or baked rounded corners.
```

### 3.2 筛选结果

| 版本 | 文件 | 结论 |
| --- | --- | --- |
| V1 | [`art/app-icon-concept-v1.png`](art/app-icon-concept-v1.png) | 瓶体倾斜、软木塞和细碎索具占比偏高；缩小后船体不够明确，淘汰 |
| V2 | [`art/app-icon-concept-v2.png`](art/app-icon-concept-v2.png) | 直立瓶体、黑帆船和青金色层级在 60/120 px 均可辨，定稿 |

旧版 catalog 文件没有被无痕覆盖，完整归档在
[`art/legacy-app-icon`](art/legacy-app-icon/)。V2 源图导出为 20～1024 px 的
19 个 RGB、无 Alpha 文件，并由
[`Contents.json`](../../src/NewPirate/runtime/ios/Images.xcassets/AppIcon.appiconset/Contents.json)
逐槽引用。资源编译后实际生成的 `AppIcon60x60@2x.png` 与
`AppIcon76x76@2x~ipad.png` 也通过尺寸和 Alpha 检查；iPhone 17 Pro Max
SpringBoard 实机位图预览确认瓶体与船体在主屏幕尺寸仍清楚。

## 4. 截图规格与交付清单

Apple 当前允许每个设备组上传 1～10 张 PNG/JPEG 截图；若 UI 一致，可优先提供
最高分辨率设备组并由后台缩放。本轮采用 Apple 列出的 iPhone 6.9 英寸
`1320 × 2868` 和 iPad 13 英寸 `2064 × 2752` 竖屏规格。

官方依据：

- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Upload app previews and screenshots](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots)

| 顺序 | 场景 | iPhone 6.9 英寸 | iPad 13 英寸 | 核心表达 |
| --- | --- | --- | --- | --- |
| 1 | 迷雾探索 | [`01-exploration.png`](app-store-screenshots/zh-CN/iphone-6.9/01-exploration.png) | [`01-exploration.png`](app-store-screenshots/zh-CN/ipad-13/01-exploration.png) | 航线选择、迷雾海图与有限补给 |
| 2 | 舰炮战 | [`02-naval-combat.png`](app-store-screenshots/zh-CN/iphone-6.9/02-naval-combat.png) | [`02-naval-combat.png`](app-store-screenshots/zh-CN/ipad-13/02-naval-combat.png) | 目标部位、舰体状态与接舷时机 |
| 3 | 返港成长 | [`03-return-and-upgrade.png`](app-store-screenshots/zh-CN/iphone-6.9/03-return-and-upgrade.png) | [`03-return-and-upgrade.png`](app-store-screenshots/zh-CN/ipad-13/03-return-and-upgrade.png) | 第一章完成、船体强化与下一目标 |
| 4 | 符文线索 | [`04-rune-clue.png`](app-store-screenshots/zh-CN/iphone-6.9/04-rune-clue.png) | [`04-rune-clue.png`](app-store-screenshots/zh-CN/ipad-13/04-rune-clue.png) | 水晶瓶、诅咒与长期收集目标 |

机器可读的构建、设备、尺寸、场景和视觉复核记录位于
[`manifest.json`](app-store-screenshots/manifest.json)。

## 5. 截图取证方法

1. 用 `CONFIGURATION=Release ./xcode.sh ios-sim` 生成同一份 Release 包；
2. 在隔离的 `qa_*` 存档中只负责定位阶段，不把 QA 展示层作为截图来源；
3. 将对应章节状态复制到 `player` 命名空间，清除环境变量后重新启动独立进程；
4. 确认顶部只显示“海上探险家 · 第一章”，没有档位、QA 构图或遥测；
5. 使用 `xcrun simctl io ... screenshot` 取得系统原始像素；
6. 模拟器 PNG 默认带全不透明 Alpha，使用 ImageMagick `-alpha off` 无损移除
   Alpha 通道，不改画面内容、尺寸或构图；
7. 以原始分辨率逐张检查，再运行自动素材校验。

这种方法仍然展示正式构建实际可达的 UI、文字、数据和美术，不叠加广告语、
不合成不存在的玩法，也不把 QA 标签裁掉或涂掉。

## 6. 截图评审反向发现并修复的问题

最大尺寸评审发现 `V2-017 / P1`：

- iPhone 长标题进入 Dynamic Island 覆盖区；
- 4:3 iPad 的 640 × 960 逻辑画布仍使用高屏固定坐标，舰炮数值与操作按钮重叠。

修复新增纯 Lua 布局模型
[`V2ChapterLayout.lua`](../../bin/res/scripts/LuaClass/V2ChapterLayout.lua)：高屏保留完整构图，
短画布切换紧凑卡片、字体和按钮间距；iPhone 顶栏把章节标题下移到安全区。
[`test_v2_chapter_layout.lua`](../../tools/v2/test_v2_chapter_layout.lua) 直接验证标题安全距离、
故事卡/三排按钮/页脚不重叠以及 iPad 路线条与英雄图边界。

同时把 QA 种子状态中的“QA 已定位……”改为中性游戏叙事，并在阶段 3 回归中
禁止玩家可见字段重新出现 `QA`。QA 档位识别、专用页眉和遥测能力保持不变。

## 7. 自动验收与结果

新增
[`validate_app_store_assets.py`](../../tools/release/validate_app_store_assets.py)，自动检查：

- 两个设备组目录和 4 张固定排序文件完整；
- iPhone 全部为 1320 × 2868，iPad 全部为 2064 × 2752；
- 每张均为 8-bit RGB PNG，无 Alpha、无 `tRNS`；
- 文件不是异常小图，8 个 payload 不重复；
- manifest 与 2.0.0（1）Release、`player` 展示档和视觉复核结论一致。

本轮执行结果：

```text
V2 Phase 3 content OK
V2 chapter responsive layout OK: iPhone safe-area and iPad compact constraints passed
iOS release static validation passed
App Store assets validation passed: 8 RGB screenshots across iPhone 6.9-inch and iPad 13-inch groups
Release iOS simulator build: passed
Unsigned Release archive: passed
iOS archive content validation: passed
```

素材校验已接入 `tools/release/validate_ios_release.sh`。归档校验也会检查编译后的
iPhone/iPad 图标、无玩家可见 QA 种子文案以及响应式布局文件进入最终 `.app`。
本轮无签名归档证据位于
`build/archives/NewPirate-store-assets.xcarchive`（构建产物，不纳入版本控制）。

## 8. 本轮验收结论

| 门槛 | 结果 | 证据 |
| --- | --- | --- |
| 图标方向与小尺寸识别 | 通过 | V1/V2 对比、19 槽导出、SpringBoard 预览 |
| 图标技术规格 | 通过 | catalog 与 compiled icon 尺寸/Alpha 校验 |
| 三类核心商店叙事 | 通过 | 前三张依次为探索、舰炮、返港成长；第四张补充符文线索 |
| iPhone 6.9 英寸 | 通过 | 4 张 1320 × 2868 RGB PNG |
| iPad 13 英寸 | 通过 | 4 张 2064 × 2752 RGB PNG |
| QA/调试信息隔离 | 通过 | 玩家进程全分辨率复核 + 状态回归 |
| 安全区与控件重叠 | 通过 | 8 张视觉复核 + 纯布局约束测试 |
| `V2-015` | **fixed / closed** | 商店图标、截图包、文档和自动门禁齐全 |

总体上线结论仍为 **HOLD**：`V2-014` 账号/签名/上传、`V2-006` 两轮目标用户
外测、真机矩阵以及公开隐私政策/支持 URL 仍未完成。
