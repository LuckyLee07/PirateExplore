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
- 37 个问题中没有尚可由内部继续修复的开放 P0/P1；
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
