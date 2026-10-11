# Warm Q v1: coverage of the 30-screen concept catalog

Reviewed against the working warm branch on **2026-10-11 UTC**. This is a
screen/feature mapping, not a claim that all 30 designs are independently built
or that every proposed gameplay rule has shipped.

## Canonical design input and reading this map

The source is `pirate-concepts-v1/catalog-plan.json`, version
`pirate-concepts-v1`, containing **S01–S24 and T01–T06**. Its SHA-256 is
`bb374a40f819f77ba93bb3323c01de72f602438c32ed1033e22e11b4c1cd2091`.
The catalog itself calls the screens functional proposals and says P0 screens
may be combined into panels. IDs, names and priorities below retain that source;
implementation descriptions come from the current Lua code, not the pictures.

- **Native adaptation**: a new native warm page, panel or state exists. This does
  not mean all mechanics or every visual detail in its concept are implemented.
- **Preserved / adapted**: the original playable route remains, with warm chrome
  or a related new panel. It is not a newly built version of the whole concept.
- **Deferred / decision**: a distinct proposed feature or rule is absent and
  needs a future scope/design decision. It must not be presented as playable.

## Screen-by-screen coverage

| ID | Canonical screen / priority | Current native route and coverage | Remaining concept gap or explicit difference |
|---|---|---|---|
| S01 | 船上家园 / P0 | **Native adaptation.** `WarmHomeLayer` is the ship home. Ship hotspots open crew, upgrades, permanent collection and voyage records; settings and ship business are contextual sheets. Actual cargo expansion adds a home badge/crate, and an explicitly selected owned memorial appears on the fixed display. | The primary action opens preparation before the existing sea map. This is not a new free-sailing home world, a direct new route-selector, or the concept's sail-growth system. Decorative captain/mate artwork is not proof of an additional owned crew member. |
| S02 | 航海图 / P0 | **Preserved / adapted.** `WarmDeparture` leads through `Expedition` into the existing `Explore` chart. `SeaChartTheme`, `AdventureNavigationView` and known-route guidance provide a warm screen-space shell and actual route information. | No new pre-departure illustrated route-selection page, duration/risk catalog, or lighthouse/new-sail route set. Existing chapters and progression remain authoritative. |
| S03 | 出航准备 / P0 | **Native adaptation.** Home → preparation uses `WarmDeparture` on the real `ExpeditionLayer`: live crew/food/item quantities, capacity, remaining cargo space, item/skill detail, current ship and rescue/supply objective. Existing guarded `AdventureProgress.depart` owns departure and its save. | The game still requires food and at least one real crew member, and uses actual cabin/cargo capacity. It does **not** implement fixed 3 hearts, 4 cargo slots, one permanent companion, two lure charges, or the draft's food-free departure. |
| S04 | 岛屿探索 / P0 | **Preserved / adapted.** Existing tile exploration, chart panning, obstacles, events, encounters and fog remain playable; the chart HUD/panels have warm presentation. | No new on-foot island hotspot world or v2 free-sailing control system. Actual food, combat and map rules remain; there is no substitute three-heart exploration ruleset. |
| S05 | 遭遇决策 / P0 | **Native adaptation of an existing encounter.** The real wreck event opens `AdventureDialog` → `WarmDialog` with actual rescue/supply and eligible profession options, costs/rewards, disabled explanations and a leave-to-reorganize option. `AdventureProgress.resolveEvent` remains the decision boundary. | No universal two-use “诱敌造通路” command, saved lure-charge system, or newly authored catalog encounter network. Original combat/other event pages still coexist. |
| S06 | 宝物取舍 / P0 | **Preserved / adapted.** Original event rewards and sea inventory remain responsible for pickup/cargo. The wreck checks real capacity before committing and never silently discards food. The new permanent memorial is handled separately after eligible successful return. | No new ordinary/unique-loot picking page or one-/two-slot treasure taxonomy. Ordinary materials remain inventory, rather than all being sold automatically. There is no implemented “leave once, never pick up again” treasure rule or atomic replacement selector. |
| S07 | 撤离返航 / P0 | **Preserved / adapted.** Actual map movement back to the original port remains possible. Known-route guidance shows discovered-path direction, steps and minimum food, without moving the player. Existing original return actions and their quoted conditions remain available. | No new island-to-boat boarding sequence. The original optional return method can involve a scroll or diamonds after the applicable free return; it has not been replaced with the catalog's exclusively walked, fee-free boarding flow. |
| S08 | 归航结算 / P0 | **Native completed-result summary.** `WarmReturnResult` opens on the new Home only after a successful original return commit, showing actual net currencies/materials, surviving crew and any genuinely new memorial. Existing `AdventureProgress.returnVoyage` remains authoritative. | This is a review of one durable settlement, never a second claim or pending choice. No ordinary-loot automatic sale. Old active voyages get a transient honest summary without new historical records. |
| S09 | 失利救援 / P0 | **Preserved failure, extended genuine record.** Original death/no-food handling and `AdventureProgress.failVoyage` remain; eligible failed voyages are recorded. `WarmCollection` shows genuine lost/returned cargo distinctions. Empty-crew recovery leads to real alchemy, camp construction or recruitment. | The proposal's free rescue with no permanent crew loss has not replaced original losses, revival handling or mission-item exceptions. Do not claim that all companions survive or only a new treasure category can be lost. No separate warm rescue scene is built. |
| S10 | 船员名册 / P1 | **Native adaptation.** Home → crew opens `WarmActivities`: actual owned profession counts, current assignment, pagination, state-responsive recovery and links to original training and preparation. Sparse rosters do not create additional people. | The existing cabin may permit several units; this is not a new exactly-one narrative-companion selection system or a discovery silhouette roster. |
| S11 | 伙伴详情 / P1 | **Native adaptation, merged detail.** Tapping a real roster entry opens its actual profession, owned/assigned quantities, base attributes and shipped skill/buff explanation. Identity-specific warm art falls back to the same profession's existing portrait. | No invented named-person biography, relationship system, new skill, lure applicability or twice-per-voyage charge. Assignment is performed by original preparation, not by a new character unlock. |
| S12 | 结识伙伴 / P1 | **Preserved story flag; new screen deferred.** The existing rescue outcome can establish 林恩 in the harbor and expose real navigation clues. That saved outcome is reflected in crew/harbor guidance and genuine wreck memory provenance. | There is no separate “邀请加入 / 稍后再说” recruitment encounter, no 小芽 recruitment, and no new selectable crew identity granted from decorative art. A saved harbor NPC outcome is not an additional combat unit. |
| S13 | 船只改装 / P0 | **Native adaptation.** Home → upgrades opens `WarmActivities` ship capabilities, actual `HarborGoals`, material-source drilldown, and existing build/make access. `WarmUpgrade` supplies direct previews for first cargo recipe 1148 and furnace 1176. Home observes actual cargo capacity for visible growth. | Growth uses original recipe materials and effects. No new sail speed, new sail ownership, sail-gated routes, arbitrary part purchases or ship-damage system is added. Later original recipes remain in manufacturing. |
| S14 | 改装确认 / P0 | **Native adaptation with a bounded real transaction.** `WarmUpgrade` shows current/resulting ability, exact costs and stock, Cancel/Confirm, prerequisites, insufficient/already-owned states and success. The original craft effects are staged and committed once; repeat, stale and failed-save attempts are guarded. | Direct warm confirmation is limited to cargo 1148 and furnace 1176. It is not the catalog's fixed gold-only sail purchase or a general transaction engine for all recipes. Missing forge construction opens the original focused build page and is not auto-purchased. |
| S15 | 外观布置 / P2 | **Small native subset implemented.** An owned wreck memorial opens a fixed-display preview in `WarmCollection`. Confirm places/removes it through `WarmMemories.setDisplay`; Cancel preserves the previous display and ownership. Home renders the selected memorial. | Only the one genuine owned memorial and one fixed display are supported. No blue shell, cosmetic shop, multiple furnishing slots, free placement, dragging or construction/collision system. The broader P2 decoration feature is deferred. |
| S16 | 宝物收藏 / P0 | **Native bounded collection.** Home → 船舱珍藏 opens `WarmCollection`; it distinguishes permanent keepsake ownership from `WarmActivities` current inventory. The only collectible is 沉船航图残页, earned from an eligible real wreck choice followed by successful return. | This is a one-item memento collection, not a complete treasure catalog. It does not turn ordinary inventory into permanent collectibles, allocate cargo slots, sell a collectible, or retroactively award historical discoveries. |
| S17 | 宝物故事 / P1 | **Merged native detail.** The owned memorial view shows its saved first voyage and a short account selected from that actual wreck choice. It connects to voyage records and display preview. | No independent multi-item story library, invented island itinerary, fabricated discovery date or inferred past rescue. The decorative concept shell story is not implemented. |
| S18 | 航海日志 / P1 | **Native bounded log.** Home → 航海日志 opens `WarmCollection` records of eligible new successful/failed voyages, with per-voyage outcome, actual event choice, cargo and currency-change detail. `航线线索` leads to current `WarmActivities` milestones, complete paginated harbor advice and gated original achievements. | Only the most recent 20 genuine records are retained. No old-save voyage history is reconstructed, no unvisited named-island sequence is fabricated, and no claim/reward button is added to logs. Current progression guidance is separate from per-voyage history. |
| S19 | 港口 / P2 | **Original access preserved; new scene deferred.** Home → 船务 exposes original building, manufacturing, resource, warehouse/alchemy and store routes, plus existing utility pages. Return goes back to the ship. | This is a contextual route sheet, not the optional illustrated social/trading port scene. It does not add NPC schedules, real-player markets or a new port simulation. |
| S20 | 交易 / P2 | **Original store preserved; proposed economy deferred.** The original store is reachable from 船务 and genuine material-source links; its existing unlock checks, listings and price rules remain. Original diamond/gift utility access is also preserved. | The catalog's gold-only optional-tool shop and blanket exclusion of diamonds/gifts are **not** implemented. No new collectible or companion sale is introduced, and no new auto-sale economy should be inferred from the warm appearance. Legacy payment/online-service availability remains subject to the repository's existing backend limitations. |
| S21 | 委托 / P2 | **Deferred as a new warm feature.** Existing mission mechanisms remain in their original gameplay context; this branch does not replace them. | No new S21 accept/claim/abandon commission board, middle-term goal catalog or commission reward economy. Preserving old mission behavior is not acceptance of the new optional-commission specification. |
| S22 | 首次引导 / P0 | **Preserved / adapted.** Original guide steps, hidden guide targets, visit side effects, starter flow and gameplay-v1 wreck guidance remain; startup/loading, contextual dialogs and new help receive warm presentation. Zero-crew guidance retains a real recovery route. | No independently authored 30-screen tutorial or new tutorial for lure/three-heart/four-slot rules. Original guide tests are not proof that every proposed new onboarding and first-failure criterion has been completed. |
| S23 | 设置 / P0 | **Native adaptation.** Owner-bound `WarmSettings` exposes existing sound, music and next-battle effects preferences plus help describing current gameplay. Close restores the same caller rather than replacing it with Home. | No unsupported text-size, reduced-motion, language, accessibility-certification, save/restart or new paid-setting controls. A settings modal is not a newly implemented gameplay pause guarantee. |
| S24 | 暂停与存档 / P0 | **Native sailing pause and explicit checkpoint.** `WarmPause` opens at a settled safe tile, freezes applicable running ship/sea actions, blocks input, and offers same-scene continue, verified save status and original return conditions. | No invented title route or cloud sync. Map and role saves are two writes, not cross-file atomic; partial failure is explicitly reported. Fight, active event, movement and hunger states cannot open a misleading safe pause. |
| T01 | 货舱已满 / P0 | **Existing capacity handling plus native preparation feedback.** Preparation shows actual used/free capacity and lets players reduce selected goods. The wreck rejects overflow before committing and explains how to leave and reorganize the existing bag. | No fixed four-slot capacity or one-/two-slot swap-comparison dialog; no multi-item atomic replacement purchase/pickup. The current capacity and original inventory actions remain authoritative. |
| T02 | 航线未解锁 / P1 | **Existing gates preserved; proposed route condition deferred.** Original dock, chapter, recipe and profession requirements remain, with actual clues and disabled explanations. | No “complete lighthouse island AND own new sail” route condition or progress card exists. The two proposed conditions are not replaced by fabricated completion ticks or a paid unlock. |
| T03 | 金币不足 / P0 | **Native adapted shortage state.** `WarmUpgrade` shows required/held/missing materials or coins, disables an unavailable confirmation, and leaves state untouched. `HarborGoals.sources` points to actual gathering, listed market goods or alchemy. The selected project can be revisited. | This is original recipe/stock insufficiency, not a new gold-only sail shortage or an automatic-loot-sale economy. No recharge redirect is added by the new upgrade panel; existing business pages retain their original behavior. |
| T04 | 收藏空状态 / P0 | **Native adaptation.** `WarmCollection` explicitly explains that a new real wreck event must be completed and brought safely home before the first memorial is owned. Preparation is reachable, and current inventory remains separately accessible. | No decorative fake owned shell or advance credit for a pending event. Legacy/incompatible records have distinct read-only explanations. The CTA uses existing preparation rather than a newly built S02 selector. |
| T05 | 离开航程确认 / P0 | **Native adapted leave confirmation.** Pause → 查看返航条件 opens the existing native return quote/confirmation; cancel continues the same voyage, while confirmation rechecks the original free/scroll/diamond contract atomically. | This is original paid/scroll return where applicable, not a new free abandon/rescue or treasure-discard system. Closing the app is not abandonment. |
| T06 | 中断后继续 / P0 | **Native restored-voyage notice.** `WarmPause.resumeNotice` presents the actually restored map, position and food before continuing the same saved voyage. The original pending-fight recovery path remains authoritative. | No new voyage is created. No guarantee of arbitrary-crash recovery across two files, pending settlement choices, every old version or cross-device/cloud saves. Corrupt/future collection data remains read-only. |

## Coverage count, not a completion percentage

All 30 catalog entries are mapped. 18 have new native panels/states or bounded
subsets (S01, S03, S05, S08, S10, S11, S13–S18, S23, S24, T03–T06). Eleven
retain original routes/mechanics with adapted presentation or guidance (S02,
S04, S06, S07, S09, S12, S19, S20, S22, T01, T02). S21 remains deferred.
The 18 include partial features such as one fixed exhibit; they are not 18
fully implemented concept specifications. In particular, P2 port/trade scenes,
commissions, unrestricted decoration and the proposed replacement economy are
not delivered.

## Boundaries that must stay visible

### Original exploration and fog are preserved

The warm changes style screen-space chart chrome. They do not replace
`FogManager`, map tiles, collision, exploration revelation or the original chart
renderer with the illustrated concept maps. Wreck markers still depend on
actual revealed fog, and known-return guidance uses discovered traversable
space. The route overlay is informational, not automatic movement. **The later
free-sailing v2 design is outside this implementation.**

### Permanent collection is not current inventory

`WarmActivities` storage shows held quantities that can change or be consumed.
`WarmCollection` owns the separate permanent keepsake view. `WarmMemories`
currently defines only `wreck_chart_fragment` (沉船航图残页): a non-tradeable,
non-functional memorial of a real eligible wreck decision and safe return.
It neither consumes cargo space nor acts as a chapter key or extra economic
reward. Failure does not grant it; already-owned copies are not awarded again.
An already-active pre-feature voyage or old completion flag does not backfill
ownership. The first genuine source remains fixed.

The new voyage log records actual later results, including failure, and keeps
20 recent entries. It does not invent dates, old voyages, named destinations,
relationships, losses or treasure discoveries. The current harbor-advice panel
is a live summary, not reconstructed historical evidence.

### This is not the draft's replacement economy

Food, original capacity/crew counts, combat, original failure losses, ordinary
inventory and existing currency/service routes remain. Only the bounded new
memorial/display/log extension and the two original-recipe atomic warm upgrade
confirmations add the documented state behavior. The draft's automatic ordinary
loot sale, no-food travel, three-heart health, two lure uses, gold-only stores,
new-sail route gates and free immortal-companion rescue would require explicit
future gameplay design and acceptance. A matching color palette is not evidence
that those rules exist.

### Optional expansion and partial coverage

S15 has only the fixed one-memorial display subset. S19–S21 remain original
business access or deferred P2 concepts, not newly built port/trade/commission
scenes. S12 and T02 retain substantive proposal gaps; the new pause/continue/return
confirmation adapts existing lifecycle rules rather than adopting free abandon. These statuses should remain in release notes and review
summaries; the phrase “all 30 screens implemented” would be inaccurate.

## Implementation references and evidence limits

Primary code is under `bin/res/scripts/LuaClass/`:

- `WarmHome.lua`, `WarmTheme.lua`, `WarmDeparture.lua`, `Expedition.lua`
- `WarmActivities.lua`, `HarborGoals.lua`, `CrewRecovery.lua`, `WarmUpgrade.lua`
- `WarmCollection.lua`, `WarmMemories.lua`, `AdventureProgress.lua`
- `WarmSettings.lua`, `WarmDialog.lua`, `MainMenu.lua`, `Dispatch.lua`
- `Explore.lua`, `SeaChartTheme.lua`, `AdventureSea.lua`,
  `AdventureNavigationView.lua`, `StartupTheme.lua`

Detailed feature/test boundaries are in
[`warm-activities-v1.md`](warm-activities-v1.md),
[`warm-upgrade-v1.md`](warm-upgrade-v1.md),
[`warm-memories-v1.md`](warm-memories-v1.md), and
[`warm-v1-navigation-settings.md`](warm-v1-navigation-settings.md).
The separate `WarmCollection` extension supersedes the earlier activities
iteration's lack of a permanent memorial; it does not change current-stock
storage into permanent collection.

Focused Lua regressions and real Cocos/EGL tests cover the new activity,
upgrade, departure, collection, settings, dialog and memory components. Native
font/node/menu/lifecycle tests and selected interactive screenshots are useful
Linux evidence; neither constitutes a natural end-to-end playthrough of all
30 catalog concepts. This document audits code coverage and does not certify
that any deferred mechanic passed acceptance.

**Platform boundary:** the supplied checkout has a Linux x86-64 native entry
and Linux testing workflows. No macOS/iOS application build, Apple simulator,
physical Apple-device performance, signing or store release is established by
this work. The original Apple project/toolchain prerequisites described in
[`README.md`](../README.md) still apply. Linux native pixels, mouse interactions
and EGL fixtures are not substitutes for Mac/mobile font, touch, lifecycle,
audio, accessibility and performance acceptance.

This document contains no user account details, player-save contents or private
QA profile paths. It does not authorize a commit, push, deployment, economy
rewrite or v2 implementation.
