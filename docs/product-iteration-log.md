# Product Iteration Log

This log records product-facing changes made after the long-term roadmap was
created.

## 2026-06-18: Batch A, First-Session Clarity

Goal:

Make the first session point more clearly toward the core pirate loop:

```text
alchemy -> build warehouse -> gather resources -> build shipyard/training camp
-> assign food and crew -> sail
```

Changed files:

- `bin/res/scripts/LuaClass/MainMenu.lua`
- `bin/res/scripts/LuaClass/DataManager.lua`
- `bin/res/scripts/LuaClass/Resource.lua`
- `bin/res/scripts/LuaClass/Expedition.lua`
- `bin/res/scripts/LuaClass/BaseView.lua`

What changed:

- Rewrote the opening system messages to frame the fantasy as rebuilding a
  stranded pirate crew.
- Rewrote locked-button tips so they explain the unlock route instead of only
  saying the feature is unavailable.
- Added a one-time next-step message when alchemy unlocks construction.
- Rewrote the first gather message so it points back to building shipyard and
  training camp.
- Rewrote first shipyard reward messaging so the player knows to assign crew
  and food before sailing.
- Rewrote talent/intel locked tips to point back to the first expedition.

Validation:

- `luac -p bin/res/scripts/LuaClass/MainMenu.lua`
- `luac -p bin/res/scripts/LuaClass/DataManager.lua`
- `luac -p bin/res/scripts/LuaClass/Resource.lua`
- `luac -p bin/res/scripts/LuaClass/Expedition.lua`
- `luac -p bin/res/scripts/LuaClass/BaseView.lua`
- iOS simulator build:
  - `xcodebuild -project projects/ios_mac/NewPirate.xcodeproj -scheme 'NewPirate iOS' -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 12 Pro,OS=26.2' -derivedDataPath build/DerivedData/ios-sim USE_HEADERMAP=NO CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=NO build`
- iOS simulator launch:
  - installed and launched bundle `com.fancyGame.NewPirate`
- Launch screenshot:
  - `docs/product-iteration-launch-check.png`

Result:

- All five modified Lua files passed syntax checks.
- iOS simulator build succeeded.
- App launched into the current warehouse screen using the original UI art
  baseline.

Still required:

- Run a fresh-save iOS simulator session.
- Verify that the first-session message order is not too dense.
- Verify that locked-button toasts fit on the phone viewport.
- Verify that the player can reach first expedition without guessing.
- Tune building/resource pacing if first expedition takes too long.

## 2026-07-16: Product Baseline V2

Goal:

Reassess the product after reviewing the complete original planning, art, and
development archive under `/Users/lizi/Desktop/Pirate`, then establish one
authoritative baseline for future iteration.

Documentation changes:

- Added `docs/product-iteration-plan-v2.md` as the current Chinese product and
  development baseline.
- Repositioned the game from a management-first RPG to a story-driven dark
  fantasy pirate exploration RPG.
- Defined the four product pillars: cursed bottle and sixteen runes, fog-of-war
  sea exploration, ship-to-boarding combat, and crew/ship identity.
- Added a keep/rework/defer/archive matrix for legacy systems.
- Defined a 15-20 minute first-chapter vertical slice and a sixteen-week roadmap.
- Added product, art, engineering, data, QA, and decision acceptance criteria.
- Marked `docs/product-long-term-iteration-plan.md` as a historical document.
- Added the current documentation entry points to `README.md`.

Result:

Future product decisions should use `docs/product-iteration-plan-v2.md` as the
single current baseline. The next execution step is Phase 0: first-chapter flow,
map nodes, system isolation, minimal data definitions, and test-save setup.

## 2026-07-16: V2 Phase 0, Design And Engineering Baseline

Goal:

Create an isolated, testable V2 foundation before implementing the first-chapter
vertical slice.

Implemented:

- Added a central `V2Config` for product phase, feature gates, save namespace,
  QA profiles, and unavailable-feature messages.
- Isolated V2 role, map, mission, and first-plot state from legacy saves.
- Disabled legacy achievement, ranking, diamond store, charging, push gifts,
  seven-day rewards, eternal arena, rating/ads, and paid map unlock flows.
- Reframed the first-session system copy around the cursed bottle and damaged
  ship instead of a generic stranded-island management loop.
- Added the Chapter 1 flow, node map, system-isolation baseline, and validation
  report.
- Added 11 readable V2 source tables for the chapter, five resources, seven map
  nodes, four crew roles, two ship modules, events, enemies, rewards, and
  dialogue.
- Added automatic Lua, config, schema, foreign-key, scope, and runtime-gate
  validation.

Validation:

- `tools/v2/validate_phase0.sh` passed.
- 11 content tables and 46 rows passed validation.
- arm64 iOS simulator build, install, and launch passed on `NewPirate Fresh QA`.
- Fresh V2 save displayed the water-bottle opening sequence.
- iOS device compile-only build passed with code signing disabled.

Result:

Phase 0 acceptance gates passed. Phase 1 can implement the playable gray-box
Chapter 1 slice using the isolated V2 data and save baseline.

## 2026-07-16: V2 Phase 1, Playable Chapter 1 Graybox

Goal:

Turn the Phase 0 design contract into a complete, recoverable Chapter 1 flow
that starts from a fresh save and does not depend on legacy long-term systems.

Implemented:

- Added deterministic CSV-to-Lua runtime export with stale-output checks.
- Added a pure Lua Chapter 1 state machine covering opening, preparation,
  exploration, events, naval combat, boarding combat, rune clue, settlement,
  upgrade, completion, failure, retry, and port recovery.
- Added immediate scoped saving after every valid chapter action.
- Added isolated `player`, `qa_explore`, and `qa_combat` runtime entries.
- Added a full-screen graybox surface with a seven-node map, current objective,
  resources, route/module context, battle transfer feedback, and valid actions.
- Hid legacy economy/menu chrome and the legacy random-event overlay in V2.
- Moved the V2 opening into the chapter flow and isolated the legacy audio
  backend after diagnosing a CoreAudio deadlock on the iOS 26.2 simulator.

Validation:

- `tools/v2/validate_phase1.sh` passed.
- Safe and risky routes, both upgrades, ship-to-boarding transfer, defeat,
  retreat, retry, recovery, invalid actions, and save fallback passed.
- arm64 iOS simulator build, install, fresh entry, combat QA entry, and extended
  process stability passed.
- Validation screenshots are stored in `docs/v2/phase-1-opening.png` and
  `docs/v2/phase-1-combat.png`.

Result:

The Chapter 1 graybox is playable as a complete product loop. Phase 2 can now
deepen exploration and combat decisions without replacing the data, save, or
chapter-flow foundations.

## 2026-07-16: V2 Phase 2, Exploration And Combat Decisions

Goal:

Turn the complete graybox into an explainable decision prototype with meaningful
route, target, timing, skill, and recovery tradeoffs.

Implemented:

- Added source-driven route, balance, and battle-action tables.
- Added navigator intel that trades provisions for exact route risk and reward.
- Quantified reinforced-hull and heavy-gun module tradeoffs.
- Added deck targeting, gun suppression, retaliation reduction, and explicit
  boarding timing.
- Added one active skill for each Chapter 1 crew role.
- Preserved one clear ship-to-boarding transfer rule and surfaced its result.
- Added causal victory reports and explicit retry/port-recovery costs.
- Upgraded the V2 save schema to 2 with safe profile fallback.

Validation:

- `tools/v2/validate_phase2.sh` passed, including all Phase 0 and Phase 1 tests.
- 14 source/runtime tables and 72 records passed export and contract checks.
- Exploration intel, module capacity, naval targets, crew skills, transfer,
  battle reports, retreat, retry, and recovery costs passed pure Lua tests.
- arm64 simulator build, `qa_explore`/`qa_combat` runtime layouts, and device
  compile-only build passed.

Result:

Phase 2 acceptance gates passed. Phase 3 can focus on content, art, dialogue,
animation, and approved audio without changing the Chapter 1 decision model.

## 2026-07-16: V2 Phase 3, Content And Art Sample

Goal:

Turn the explainable Chapter 1 prototype into a representative product sample
with authored events, distinct hero compositions, character dialogue, enemy
presentation, animation, and stable audio cues.

Implemented:

- Expanded Chapter 1 to eight authored events and thirteen source-mapped
  choices, including route-specific events, black tide, and cursed compass.
- Added eighteen plot, voyage, naval, boarding, rune, and return-to-port lines.
- Added fourteen source-driven presentation mappings across harbor, map,
  combat, and rune hero groups using approved original project art.
- Added full-screen iOS launch metadata and isolated the legacy mission toast.
- Added distinct naval enemy, boarding deck/leader, rune reward, and lightweight
  key-animation presentation.
- Added six source-mapped audio cues for sailing, cannon, boarding, victory,
  curse, and sinking.
- Reproduced the legacy iOS audio termination and replaced V2 effect playback
  with an AVFoundation bridge exposed to Lua.
- Upgraded the V2 save schema to 3 and added isolated boarding, rune, and
  settlement QA profiles.

Validation:

- `tools/v2/validate_phase3.sh` passed, including all earlier phase suites.
- 16 source/runtime tables and 124 records passed export, reference, asset,
  event, dialogue, presentation, audio, and animation checks.
- Map, naval, boarding, and rune hero compositions passed full-screen simulator
  screenshot review on iOS 26.2.
- Native cannon-cue smoke test remained stable after the old backend's failure
  was reproduced.
- arm64 simulator and compile-only iOS device builds passed.

Result:

Phase 3 implementation and automated acceptance passed. Phase 4 owns real
device experience records, two external user-test rounds, issue triage,
performance/save/resource audits, and the final Go/No-Go decision.

## 2026-07-16 — V2 Phase 4 internal test and decision baseline

Implementation:

- Added a 17-event local-only telemetry contract, bounded session records,
  persisted summaries, and a ten-gate decision source table.
- Added a preserving schema 3 to 4 save migration plus damaged-save fallback.
- Added a two-round external target-user protocol, empty result template,
  evidence-backed issue register, internal quality audit, content budget, and
  commercial-model recommendation.
- Set the decision sample to 30 FPS, capped 3x iOS framebuffers at 2x, made the
  simulator build default to the host architecture, and aligned engine targets
  to iOS 12.
- Fixed unsafe MD5 string lifetime, temporary XMLHttpRequest header iteration,
  and 64-bit renderer pointer formatting.
- Added a requirement-by-requirement completion audit and an external-test
  aggregator that validates two rounds, excludes technical failures, and
  computes the four second-round gates without claiming an overall Go.

Validation:

- `tools/v2/validate_phase4.sh` passed the complete Phase 0 to 4 chain: 18
  source/runtime tables, 17 telemetry events, ten gates, both chapter paths,
  recovery, content, presentation, audio, migration, and record bounds.
- The arm64 iOS 26.2 simulator build installed and rendered the full-screen
  `qa_combat` composition correctly; the final candidate remained alive about
  26 seconds after AVFoundation cannon playback was triggered.
- The 2x framebuffer candidate measured 102.7 MB physical footprint (103.7 MB
  peak), down from 139.0 MB before the cap. Simulator CPU remained 88.7% and
  was localized to the legacy OpenGL/GLEngine software-rendering path.
- arm64 compile-only iOS device build passed. Real-device experience remains
  unverified.
- External-test analyzer unit coverage passed for a complete pass, threshold
  failure, incomplete sample with technical exclusion, and invalid input.

Result:

The Phase 4 internal candidate baseline is complete. The product decision is
HOLD—not Go—until a real device pass and two external rounds satisfy all four
user gates. No participant results were fabricated or inferred from internal
automation.

## 2026-07-16 — V2 Phase 4 simulator size matrix

Implemented:

- Added a stable three-size simulator matrix covering iPhone SE 3, iPhone 12
  Pro, and iPad A16 portrait layouts.
- Captured source-controlled `qa_combat` and `qa_explore` evidence for the
  short-screen phone and iPad extremes.
- Isolated the Xcode 26.2 iPhone 12/13 mini `rdar:45025538` wrong-screen-model
  defect as a test-environment limitation instead of changing product layout.
- Extended Phase 4 validation to require the matrix document and exact PNG
  dimensions.

Validation:

- iPhone SE 3 rendered the complete five-action `qa_combat` screen at
  750×1334 and remained alive for at least 8 minutes 58 seconds.
- iPad A16 rendered the complete three-action `qa_explore` screen at
  1640×2360 and remained alive for at least 5 minutes 59 seconds.
- The existing iPhone 12 Pro full-screen baseline remained the modern-phone
  reference. Simulator build succeeded after restoring the formal project
  state.

Result:

Internal simulator layout coverage is complete without claiming real-device or
external-user evidence. The Phase 4 decision remains HOLD until those deferred
gates are executed.

## 2026-07-17 — V2 内部样片精修第 3 轮：因果反馈闭环

目标：

在不扩建第二海域、不改变存档和战斗数值的前提下，让玩家在接舷前看到
舰炮结果预估，并在首章完成后理解本次升级会怎样影响下一航程。

实现：

- 新增与战斗状态同源的接舷预估：甲板完整为 100/100，击毁后为
  65/100，并明确显示剩余甲板破坏和削弱值；
- 接舷按钮同步显示敌军预估，进入接舷后继续显示实际传递结果；
- 完成页按真实升级选择显示船体 +20 或火炮齐射 +25，并解释其对下一
  航程的实际用途；
- 紧凑布局和专项回归覆盖三行战斗反馈，问题以 `V2-033 / P2` 登记并修复。

验收：

- 专项状态机、阶段 0–4 与发行级静态/原生安全回归全部通过；
- iPhone SE 3 的甲板完整预估与击毁后接舷传递两张 750×1334 实图通过，
  截图后进程持续稳定；
- Release 模拟器、device compile 与无签名 archive 构建通过，archive 内容
  验证通过。

结论：

本轮只提升内部样片的可理解性和成长回报，不把内部自动化当作外部用户
数据，也不改变阶段 4 的外部 `HOLD` 状态。

## 2026-07-17 — V2 内部样片精修第 4 轮：首航决策预览

目标：

降低首航前 60 秒的信息拼装成本，让模块与航线选择在提交前直接显示成本、
战斗影响和成长收益。

实现：

- 皇家港模块按钮显示加固船体耐久 +20，以及重炮甲板齐射 +45 / 补给 -1；
- 出航按钮随当前模块更新，默认配置明确可直接出航；
- 未测绘航线明确标为盲选，测绘按钮说明花 1 补给查看后果；
- 测绘后按钮直接显示安全路线的接舷 +10，以及暗礁近路的船体 -10 和战利品；
- 新增 `qa_harbor`、`qa_explore_intel` 隔离档与 `V2-034 / P2` 专项回归。

验收：

- 专项状态机、阶段 0–4 与发行级静态/原生安全回归全部通过；
- iPhone SE 3 的港口模块与已测绘航线两张 750×1334 实图通过，首次
  截图发现的中文按钮缩字/断行问题已在本轮内修正并复验；
- Release 模拟器、device compile 与无签名 archive 构建通过，archive
  内容验证通过。

结论：

本轮不增加首航步骤、不改变实际成本与结果，也不扩建第二海域。

## 2026-07-17 — V2 内部样片精修第 5 轮：战利品到成长

目标：

让玩家在返航升级支付前理解本次获得了什么、资源能换什么，以及选择会怎样
改变下一航程。

实现：

- 结算页拆分追猎者物资和符文线索的增量与用途；
- 升级按钮显示木材-10到耐久+20、铁料-15到齐射+25的完整转化；
- 升级说明把船体容错与甲板/接舷优势连接到下一航程；
- 新增 `qa_upgrade` 隔离档与 `V2-035 / P2` 专项回归。

验收：

- 专项状态机、阶段 0–4 与发行级静态/原生安全回归全部通过；
- iPhone SE 3 的战利品结算与首次升级两张 750×1334 实图通过，截图后
  进程持续稳定；
- Release 模拟器、device compile 与无签名 archive 构建通过，archive
  内容验证通过。

结论：

本轮只提升既有首章奖励的可解释性，不增加新的经济或长期成长系统。

## 2026-07-17 — V2 内部样片精修第 6 轮：失败恢复决策

目标：

让玩家在失败后选择原地重试或返港恢复前，明确知道成本、保留项、清除项
和返回阶段，避免因担心隐藏损失而不敢继续。

实现：

- 失败页明确原地重试补给 -1、保留当前航线和已确认战利品，并从舰炮战
  重新开始；
- 返港恢复明确金币 -5、保留已确认战利品、清除航线损伤并回到皇家港；
- 两个按钮同步预览关键成本与去向，补给不足时引导到有效恢复路径；
- 新增 `qa_failed` 隔离档与 `V2-036 / P2` 专项回归，锁定两条路径的资源
  和状态保留边界。

验收：

- 专项状态机、阶段 0–4 与发行级静态/原生安全回归全部通过；
- iPhone SE 3 的失败恢复页 750×1334 实图通过，截图后 Release 进程持续
  运行至 56 秒；
- Release 模拟器、device compile 与无签名 archive 构建通过，archive
  内容验证通过。

结论：

本轮不改变恢复成本、战斗数值或存档 schema，只把既有安全恢复边界变成
选择前可见的玩家承诺。真实挫败感和恢复选择理解率仍需外测。

## 2026-07-17 — V2 第一章内部样片冻结审计

结论：

- 六轮内部精修及 10 张 iPhone SE 小屏证据全部通过；
- 40 个问题中没有尚可由内部继续修复的开放 P0/P1；
- 阶段 0–4、发行级回归、Release 模拟器、device compile 和最终 archive
  已形成可重复证据链；
- 第一章内部样片状态改为 `FROZEN`，停止无外部证据驱动的功能扩张；
- 产品立项和发行状态继续 `HOLD`，不得扩建第二海域，也不把内部候选冒充
  真机、外测或 App Store 通过。

后续只在条件具备时按“冻结候选 → 同候选真机矩阵 → 外测 R1 → P0/P1
修复 → 外测 R2 → Go/No-Go”顺序推进。

## 2026-07-17 — 冻结后发行工程第 1 轮：archive 产物溯源

实现：

- iOS App 内嵌候选 ID、源码 Git 提交和 tracked 工作树 dirty 状态；
- `xcode.sh` 对 simulator、device 和 archive 使用同一套身份注入；
- archive 内容校验支持精确候选/提交匹配，并可强制 clean provenance；
- 新增候选记录工具，联合可执行文件与 dSYM UUID、SHA-256、版本和提交；
- `V2-037 / P1` 登记并关闭。

验收：

- 专项、阶段 0–4 与发行级回归通过；
- Release simulator/device compile 通过，模拟器 App 实际显示 `HEAD-dirty`；
- `NewPirate-provenance-iteration-1.xcarchive` 精确身份校验通过；
- 同一 dirty archive 被 clean 候选门禁预期拒绝。

结论：

本轮没有改变冻结样片内容。下一轮从干净提交生成 `2.0.0-1-internal`
候选并登记二进制指纹；外测、真机和 App Store 状态继续 HOLD。

## 2026-07-17 — 冻结后发行工程第 2 轮：内部候选固化

实现与验收：

- 从干净提交 `e6dc27f` 生成 `2.0.0-1-internal` 无签名 archive；
- 内嵌 source commit 精确匹配且不带 `-dirty`；
- 记录 App/dSYM 的 SHA-256、大小与共同 Mach-O UUID，以及 Info.plist 哈希；
- 新增候选记录 schema 与 `--verify-record` 反向复验，篡改哈希、UUID、字段
  或身份均失败；
- `V2-038 / P1` 登记并关闭，阶段 0–4 与发行级回归通过。

结论：

内部候选身份与字节基线已经固化；`product-launch-manifest` 仍保持 HOLD/null，
不把内部无签名候选冒充最终 TestFlight 或 App Store release commit。

## 2026-07-17 — 冻结后发行工程第 3 轮：archive 全树完整性

修正：

- 发现 schema 1 只覆盖可执行文件、dSYM 和 Info.plist，资源文件替换仍可能
  绕过候选记录；
- schema 2 对所有 archive 文件、目录和符号链接按相对路径生成规范树摘要；
- 摘要覆盖条目类型、路径、权限、大小、文件哈希与链接目标，排除 mtime；
- 真实候选记录升级为 769 个条目、22,039,977 文件字节和全树 SHA-256；
- `V2-039 / P1` 登记并关闭。

验收：

专项证明内容、权限、路径与符号链接目标变化均改变摘要；真实
`2.0.0-1-internal` 记录反向复验、archive 内容检查和完整发行回归通过。

## 2026-07-17 — 冻结后发行工程第 4 轮：最终候选身份闭环

修正：

- 发现最终 App Store 门禁只验证合法 archive/签名，没有把包内源码身份精确
  绑定到总体 `release_commit`；
- 签名 App 校验新增期望源码提交、候选 ID 和 clean provenance 门禁；
- archive 内容与 Distribution App 两条最终检查都从同一产品/提交 manifest 派生
  `release_commit` 与 `version-build`；
- archive 的 ApplicationPath 必须指向唯一产品 App，避免内容与签名检查分裂；
- `V2-040 / P1` 登记并关闭。

验收：

专项拒绝错误提交、错误候选、dirty provenance、缺失 release commit 和候选
manifest 不一致；当前最终 App Store 门禁仍按预期报告 30 pending，总体仍为
47 pending，完整发行回归通过且没有执行外部签名、上传或真机操作。

## 2026-08-05 — UI 2.0 第 1 轮：共享视觉骨架

实现与验收：

- 新增统一主题、五段航程、资源卡、语义按钮和舰炮/接舷进度；
- 移除持续漂浮、呼吸和旋转，改为一次性淡入与轻位移；
- 隐私与支持弹层使用同一组件语言与完整按钮触控区；
- iPhone SE 3 和 iPad A16 共 7 张运行截图通过；
- 阶段 0–4、发行级回归和 iOS 模拟器构建通过；
- 独立基线提交：`ddb76e4`。

详见 [`v2/ui-2.0-iteration-1.md`](v2/ui-2.0-iteration-1.md)。玩法、数值、存档和第二海域范围不变。

## 2026-08-05 — UI 2.0 第 2 轮：四组阶段美术

实现与验收：

- 新增港口、探索、舰炮、符文四张 1024×1024 RGB 生产背景；
- 14 个第一章演出状态按阶段组接入新图，保留 accent、animation 与 audio cue；
- 移除与新图不协调的旧前景和头像叠层；
- iPhone SE 3 覆盖玩家首屏、港口、探索、舰炮、符文、升级与失败，iPad A16 覆盖探索与舰炮；
- 内部截图不替代真机性能和外部目标用户结论，产品/发行状态继续 HOLD。

详见 [`v2/ui-2.0-iteration-2.md`](v2/ui-2.0-iteration-2.md)。

## 2026-08-06 — UI 3.0：克制的航海日志

实现与验收：

- 将目标、五资源、航程与场景合并为一条无框信息层；
- 删除重复阶段标题、图片标签、三枚元信息药丸和独立日志框；
- 非战斗使用短日志板，战斗按需扩展状态板；
- 普通、辅助、选中、主推进和危险按钮改为低噪音语义体系；
- 标题粗体、正文常规字重，每页只保留单阶段强调色；
- 以主流 iPhone 竖屏完成玩家首屏、探索、舰炮和符文四张运行复核；
- 玩法状态机、数值、存档与第二海域范围不变。

详见 [`v2/ui-3.0-style-system.md`](v2/ui-3.0-style-system.md)。产品与发行状态继续 **HOLD**。

## 2026-08-06 — UI 3.1：从整理界面到结构重设计

运行复核确认 UI 3.0 虽然减少了边框和颜色噪音，但仍沿用顶部栏、横向进度、文字资源行、大矩形卡和普通矩形按钮，第一眼容易被理解为只更换背景。

本轮据此完成结构级修正：

- 顶部建立章节号铭牌与固定船长 HUD；
- 目标改为带编号航令板，资源改为一体式五格船载仪表；
- 五段横向进度改为右侧纵向航程节点；
- 叙事区改为带页签、书脊和三列上下文的船长日志；
- 所有操作加入两位指令编号和推进/选择/辅助/风险角色块；
- 主流 iPhone 的首屏、探索、舰炮和符文四个状态重新运行复核。

本轮仍只修改表现层与布局。玩法、数值、存档、操作 ID 和第二海域范围不变，总体继续 **HOLD**。

## 2026-08-09 — UI 3.2：语义仪表、操作回执与 14 状态覆盖

目标：

让 UI 升级从“结构看起来不同”继续进入“信息读得更快、操作结果说得清楚”，并消除第一章中段状态无法稳定直达复核的盲区。

实现：

- 审计 179 枚旧版图标，确认其混合写实装备、早期扁平功能图标和多套描边规范，不直接回填新版 HUD；
- 建立 9 枚 UI 3.2 单色线性图标：金币、木材、铁料、补给、符文、船体、甲板、火炮、船员；
- 资源栏由单字缩写升级为“图标 + 完整资源名 + 数值”，战斗进度加入部位图形映射；
- 成功指令显示一次性结果回执，最多列出 3 个真实状态差值，额外变化折叠；
- 新增航线事件、黑潮、低语、诅咒罗盘 4 个 QA 直达档，与既有 10 档组成完整 14 状态复现矩阵；
- 使用 Apple 式即时反馈、空间一致性和克制动效原则，以及 Emil Design Engineering 的层级与因果反馈准则收敛实现，没有加入循环动画或无意义弹跳。

验收：

- Lua 主题、配置、阶段 3 和新增状态恢复测试通过；
- iOS Simulator Debug 构建通过；
- iPhone 17 / 1206×2622 px 下 14 个状态全部进入游戏并完成视觉矩阵；
- `qa_combat + fire_at_guns` 在运行态自动执行成功，回执与战斗仪表同时显示敌舰 -130、船体 -14、火炮压制 +130；
- 图标源文件与运行 PNG 尺寸进入自动校验；
- 未修改玩法数值、已有操作 ID 或存档 schema。

结论：

第一章纵切继续作为 `BASELINED` 开发基线，整款产品开发状态为 `ACTIVE`。下一轮优先完善舰炮、接舷、奖励和升级的场景内反馈；真机、签名和 App Store 工作保持 `DEFERRED_UNTIL_FINAL`。

## 2026-08-09 — UI 3.3：场景动作反馈与结果组

目标：

把 UI 3.2 已经成立的视觉骨架和数值回执推进到“动作发生处可感知、结果页面可扫视”，结束只在日志和仪表里找变化的状态。

实现：

- 新增纯数据 `sceneFeedbackItems`，统一描述舰炮、部位破坏、反击、接舷、治疗、守卫和标记的敌我锚点、数值、颜色与效果类型；
- 新增场景内短时反馈层：舰炮轨迹、受击斩线、治疗十字、目标标记和敌我数字分别落在场景左右两侧；
- 保留 UI 3.2 中部因果回执，形成“场景先感知、日志板再复核”的两级反馈；
- 新增纯数据 `outcomeGroups`，从生成数据表和当前状态构建结算、升级、失败、完成四类结果组；
- 结算展示金币/木材、铁料/符文和返港升级方向；升级展示库存与两种成本收益；失败展示原因、重试保留项和返港清除项；完成展示升级、线索和下一航程；
- 新增仅 QA 档生效的 `NEWPIRATE_V2_QA_FEEDBACK_HOLD`，用于模拟器稳定截取短反馈，玩家默认动效时序不变；
- 按 Apple Design 的空间一致性和即时反馈、Emil Design Engineering 的因果层级与克制动效原则完成收敛，没有加入循环动画、弹跳或与结算脱节的特效。

验收：

- Lua 主题测试新增舰炮、接舷、结算、升级和失败结果契约并通过；
- `./xcode.sh ios-sim` 通过；
- iPhone 17 / 1206×2622 px 运行态完成 `fire_at_guns`、`boarding_attack`、`medic_heal` 三类真实操作；
- 运行结果分别为敌舰 `-130` / 船体 `-14` / 火炮压制 `+130`，敌军 `-30` / 接舷队 `-18`，紧急包扎实际恢复 `+18`；
- 战利品结算、首次升级、失败恢复和首航完成四个页面无正文、结果组、最近记录和按钮重叠；
- UI 3.3 两组模拟器证据进入自动尺寸校验；
- 未修改玩法数值、操作 ID、存档 schema 或第二海域范围。

结论：

第一章页面的风格、语义、动作与结果反馈已经形成 UI 3.3 基线。产品开发继续 `ACTIVE`，下一轮进入船只整备、船员管理、资源/仓库和成长界面的完整产品信息架构，再推进重复远航循环；真机、签名、TestFlight 和 App Store 继续 `DEFERRED_UNTIL_FINAL`。

## 2026-08-09 — UI 3.4：皇家港整备中心

目标：

把 UI 升级从单张章节页扩展到第一张真实产品功能界面，让玩家能在同一港口空间理解下一航程、船只配置、核心船员和资源用途，同时不恢复旧版经济大厅。

实现：

- 新增纯数据 `V2PortModel`，从章节存档和生成数据表构建港口状态、船只、船员、货舱、就绪项与分区动作；
- 新增 `V2PortLayer`，提供航海桌、船只、船员、货舱四区固定导航；
- 章节顶部新增“整备”入口，港口保留“返回航程”，形成双向导航；
- 航海桌显示目标、船只/船员/补给就绪和下一航程目标；
- 船只页显示当前模块、计算后耐久、等级、航行损伤、两模块取舍和首次升级成本；
- 船员页显示四名核心船员的职业、主动技能、玩家可读战斗效果和远航特性，不暴露内部动作 ID；
- 货舱页显示五种资源的数量与主要/次要用途，并在结算态提供真实返港动作；
- 所有动作由 `V2ChapterState.getActions` 提供并交给现有 Controller 执行，港口没有复制玩法规则；
- 新增 QA 启动面与分区环境变量，只对 `qa_*` 档生效；
- 按 Apple Design 的空间一致性、即时反馈与动效克制，以及 Emil Design Engineering 的信息层级、单一焦点与可扫视性完成布局收敛。

验收：

- `test_v2_port_model.lua` 覆盖四区、真实船体数值、四船员、五资源与真实动作过滤；
- `./xcode.sh ios-sim` 通过；
- iPhone 17 / 1206×2622 px 完成航海桌、船只、船员、货舱、升级态和章节入口六张运行复核；
- 四区运行矩阵尺寸为 1296×676 px；
- 未修改玩法数值、已有操作 ID、存档 schema 或第二海域内容；
- 未执行真机、签名、TestFlight 或 App Store 工作。

结论：

UI 3.4 完成“完整产品界面”的第一块基线，但整款游戏仍处于 `ACTIVE` 开发。下一轮最高优先级是可重复远航：完成首章后保留已获得升级和资源，进入第二次远航准备，并让成长真实改变下一次策略。真机与发行继续 `DEFERRED_UNTIL_FINAL`。

## 2026-08-09 — 重复远航第 1 轮：成长留存

目标：

移除玩家完成首航后重置全部状态的假循环，让首次升级、库存和符文线索真正进入下一次整备，并验证成长能改变下一场战斗。

实现：

- 玩家完成态动作由 `restart_chapter` 改为 `prepare_next_voyage`，按钮明确说明“保留升级与库存”；
- QA 完成态继续保留 `restart_chapter`，产品行为与诊断重置分离；
- 下一航程准备保留船体/火炮等级、模块、五资源、四船员、第一枚符文线索、历史和遥测；
- 清理上一航次的路线、测绘、诅咒、战斗、战损、失败摘要，以及可重复普通战利品领取标记；
- 唯一符文奖励保持已领取，防止第一枚符文重复发放；
- `voyage_count` 在准备时保持 1，真实再次出航后增至 2；
- 皇家港状态与章节标题显示“第 2 次整备”，航海桌显示耐久 140、船体等级 1、已完成航次和潮汐墓场目标；
- 新增 `next_voyage_prepared` 本地遥测事件，并把当前事件契约从 17 项扩展为 18 项。

验收：

- 专项回归验证库存、船员、模块、历史、唯一符文和成长保留，以及临时状态清理；
- 船体升级后的下一战最大耐久为 140；
- 火炮升级后的下一次甲板齐射为 200，敌舰由 500 降至 300；
- iPhone 17 / 1206×2622 px 完成皇家港和章节页第 2 次整备运行复核；
- iOS Simulator Debug 构建通过；
- 未新增存档字段或修改 schema，未执行真机、签名、TestFlight 或 App Store 工作。

结论：

“升级—保留—再次整备—再次出航”的最小循环已经成立。第二次航程当前仍复用第一章路线和战斗，因此不能视为第二海域完成。下一轮进入潮汐墓场灰盒和成长驱动的差异决策，产品开发继续 `ACTIVE`，发行继续 `DEFERRED_UNTIL_FINAL`。
