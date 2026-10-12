# PirateExplore: next two coherent-game tranches

Prepared 2026-10-11. The implementation baseline is visual checkpoint `685b6a3`, followed by the separately tested Linux lifecycle fix `b11cf222`. This plan records remaining surface and art work; it is not a claim of native acceptance for those surfaces.

## Recommendation

1. **Tranche 2: finish the everyday playable surfaces.** Redesign the six production dashboards, real event families, nested recovery/material pages and loot allocation, not merely their framing. Keep the accepted combat/world rendering while this tranche closes reachable actions. Deliver coherent production → voyage → event → loot → growth navigation, plus fixture coverage of other event branches. Do not start broad battle/world asset changes concurrently with this pages tranche.
2. **Tranche 3: close the whole-game surface and art inventory.** Complete the actual battle stages and actors, all chapter environments, world-map transitions, remaining crew/enemy/item art and every reachable utility/store/reward/support page. Repeat whole-game continuity and compatibility acceptance. Do not label Tranche 2 a complete game reskin, and do not label Tranche 3 complete while an active route still has the inherited composition or an unreviewed mixed-style art family.

Neither tranche changes economy, event outcomes, combat rules, movement turns, food rules, save schemas, geography, map randomization, unlocks, reward ownership, online/IAP behavior or the engine. No save reset or new profile marker is needed for the presentation work below.

## What the current code actually provides

- The current first batch handles the Warm shell, preparation, return/failure, growth/collection/log support, focused forge, dialog framing and combat framing. `ART_AND_SCOPE.md` explicitly excludes a finished redraw of actors/decks/story art and the composition of original business pages.
- `BaseView:applyManagementTheme()` replaces background/title/button faces while retaining original geometry. `ManagementTheme` is already Warm-aware. More token replacement cannot turn the existing recipe tables, three-part footer and competing controls into coherent dashboards.
- `DialogTheme` intentionally keeps most unspecified card/panel surfaces dark because many callers own white labels. Changing its default to cream would break contrast. New light page layouts must opt in and recolor the associated labels together.
- `EventLayer.lua` still uses its own `eventLabel` helper backed by `MasterTheme`, fixed fractions of viewport height, and a repeated full-screen two-button layout. `EventBaseView` and detail tables are separate hosts. This is a composition job, not just a shared-modal job.
- `CombatTheme.deckPath()` points to inherited `Adventure/Combat/*-deck-b.png`; `FightMode` still creates original cannon sprites, boss images, portrait controls and fixed-position combat tables. Its framing-only tests expressly verify unchanged deck/chest asset selection.
- Production CSV readout: 468 resource records with 125 distinct nonempty `iconName` strings; 323 fighter records with 42 distinct icons (22 `j_*` crew and 20 `g_*` bosses); 345 stronghold records dispatch through ten event-function families. These are useful coverage denominators, not a claim that every CSV record is currently obtainable.
- The 16 original TMXs are 64×64 orthogonal tile maps: chapter 1 is 21×21, chapter 2 31×31, chapters 3–8 grow from 41×41 to 91×91, and chapters 9–16 are 101×101. Actual layer order varies. Chapter 16 has duplicate volcanic atlas declarations. Theme choice cannot be `mapIndex % themeCount` or the first tileset in a map.

## File ownership and integration boundaries

### Immediate pages-v3 dispatch (highest impact, independent files)

Use a new worktree from the accepted frozen checkpoint; no work in the reviewer or shutdown-fix checkout. The following split supersedes the broader role grouping for Tranche 2 parallel assignments:

1. **Gathering + warehouse:** `Resource.lua`, `Repository.lua`; tests named `coherent_production_dashboard_*`. Implement worker allocation, gathering summaries/action, warehouse tabs/detail/sale affordances and alchemy presentation.
2. **Build + manufacture + store:** `BuildMode.lua`, `MakeMode.lua`, `StoreMode.lua`; tests `coherent_catalog_*`. Preserve focused forge guards, all original recipes/prices/IDs, focus routes and bulk purchase.
3. **Crew recovery + materials:** `TrainMode.lua`, `Lackmaterial.lua`; tests `coherent_crew_material_*`. Includes `ChangeJobView` and `MaterialView` classes defined inside `TrainMode.lua`; they cannot be assigned to a separate simultaneous editor. Keep zero-crew recruit/recovery and all source routes reachable.
4. **Event choices + details:** `EventBaseView.lua`, `EventLayer.lua`, `EventDetailsLayer.lua`; tests `coherent_events_*`. Defer `WorldMapLayer` art/layout to Tranche 3, but verify its handoff remains functional.
5. **Loot allocation + chest:** `FightMode.lua` only in `FightRewardScene`, `FightBoxView`, `FightBoxViewAlert` presentation; tests `coherent_loot_*`. No battle math/stage reskin yet.
6. **Integration owner only:** `BaseView`, `ManagementTheme`, `DialogTheme`, `MainMenu`, `Dispatch`, `WarmTheme`, font and aggregate scripts. Publish a helper signature/geometry contract before workers consume it; workers request shared changes rather than patching common files. Native shutdown fix remains separate.

Do not hide original controls without a reachable replacement bound to the same real action. Guides may still require invisible retained handles, but that is separate from the visible player route. The six dashboard and ten event families must remain available under exactly their current gates. Freeze the integrated pages candidate before independent native QA; one GUI owner at a time.

All paths below are relative to the repository. One owner at a time per listed file. Workers should propose changes to another owner's file rather than editing it concurrently.

### A. Shared presentation/integration owner

Owns `bin/res/scripts/LuaClass/{WarmTheme,ManagementTheme,DialogTheme,BaseView,MainMenu,Dispatch}.lua`, new shared layout primitives, `tools/build_clean_voyage_font.py`, `bin/res/assets/fonts/CleanVoyageSans-Regular.ttf`, aggregate runners and acceptance documentation.

- Add bounded page geometry, text fitting/wrapping, section headers, actionable rows, quiet empty states and a single action-dock contract. Use an explicit per-page opt-in; do not automatically restyle every `BaseView` subclass.
- Keep public handles used by existing controllers: title/background references, `setBtn`, `leftBtn`, `rightBtn`, info labels, progress object, original menu and guide targets. A skin wrapper must preserve `SDButton` object/listener/click-area/long-press state.
- Unify Back placement via existing `approvedPage` / `keepNavigation` presentation hooks. `MainMenuLayer:setApprovedPagePresentation`, `setHomePresentation` and `applyWarmNavigationAppearance` already decide when to hide global chrome. Avoid adding another global footer.
- Do not introduce a second routing framework. Preserve `MainMenuLayer:openRoute`, `openUtilityRoute` and `Dispatch:setViewWithDirection`/stack teardown. Warm utility Back currently returns Home through `Dispatch:backToLastView`; a redesign must not silently invent a different navigation history.
- Integrate font once after all new player text lands; preserve the font license and previous glyph set. Do not have parallel owners regenerate the font.

### B. Production dashboard owner

Owns `{Repository,Resource,BuildMode,MakeMode,TrainMode,StoreMode,Lackmaterial}.lua` and any extracted presentation-only dashboard module. `LocalProduction`, `ProductionSources`, `CrewRecovery`, DataManager and packed CSVs remain read-only transaction/data dependencies.

- Extend the already accepted focused forge path, do not replace or regress it.
- Use page-specific composition for inventory/alchemy, gathering, construction, manufacturing, crew training and shop. Share only layout primitives and row components.
- Own material-shortage and acquisition layouts as part of the production chain; they are not an unrelated late polish pass.

### C. Event and transition owner

Owns `{EventBaseView,EventLayer,EventDetailsLayer,WorldMapLayer,PlotLayer,PlotMode}.lua` and a new presentation-only `EventPresentation.lua` if useful. Coordinate WorldMap work with the environment-art owner, but keep one Lua owner.

- Preserve `EventManger`, map layout managers and event queue mutation as read-only dependencies.
- Do not spend effort on `rewardLayer.lua` or the commented `EventRewardLayer:create` path unless a route audit finds an actual active caller. Active event rewards go to `FightRewardScene` in `FightMode.lua`.

### D. Combat and loot owner

Owns `{FightMode,CombatTheme}.lua` and any extracted presentation-only combat/reward view modules. `FightDataManager`, effect calculations and real item transfer functions remain authoritative.

- A single owner handles both combat and `FightRewardScene`: splitting by file would otherwise create a hot conflict.
- Extract scene construction only when that makes layout safe. Do not move battle calculations or reward commits into the new view module.

### E. World presentation owner

Owns `{SeaChartTheme,SeaChartWorldTheme,SeaChartSlice,CleanVoyageView,CleanVoyageHUD}.lua`, new presentation-only world manifest, and tightly scoped presentation adapter calls in `{Explore,AdventureSea}.lua`. Integration owner reviews any edit to these two production hosts.

- `CleanFirstMap.lua`, every TMX, `FogManager`, `ExploreDataManager`, `MapLayoutManagers`, `KnownRoute`, `AdventureNavigation`, `EventManger`, save controllers and original move/food functions are read-only contracts.
- New assets and parameters may change rendering. They may not change collision masks, semantic visibility, map IDs, saved coordinates or the selected original TMX.

### F. Art/semantic asset owner

Owns new clean art, import scripts and provenance/semantic manifests. Uses namespaced clean assets; does not overwrite original packed atlases or economy tables. Coordinates lookup changes through the owner of the consumer Lua file.

- Own `ResourceTheme.lua` and `ItemIcon.lua` lookup/placeholder presentation changes as a single semantic asset boundary.
- Inventory exact `(type, record ID, original icon name)` aliases before replacing art. `ResourceTheme` already uses exact-ID guards for shared `w_12.png` sword tiers. Do not replace all aliases globally with one distinct weapon or profession.
- Produce crop/alpha/dimension/anchor metadata, source provenance and a visual contact sheet for each family. Review contact sheets before integration, then verify actual native scale; a contact sheet alone is not acceptance.

### G. Independent QA owner

Owns new isolated tests/capture manifests and review notes. No implementation edits while reviewing a frozen candidate. No concurrent GUI driver. Tests use disposable profiles; old-save parity uses independent copies and retains untouched source profiles.

## Tranche 2: concrete implementation order

### T2.0 Freeze the shared page contract before parallel layouts

Owner A; dependency: accepted first batch.

Add explicit page/body bounds and light-surface/text-role helpers, measured for the existing portrait coordinate system. Dashboard, event, battle and utility owners consume the same CleanVoyageSans, navy text, cream panels, teal primary and quiet secondary controls. A page may have zero primary actions when read-only; do not create one merely to meet a count. A selected transaction detail has at most one strongly emphasized commit action; Back/Cancel and drilldowns stay secondary.

Acceptance: native helper bounds at the first-batch viewports, dark legacy caller contrast retained, opt-out tests retained, no route, save or event writes from construction. New UI must keep real item/resource/crew names and quantities visible rather than hiding mechanics behind scenery.

### T2.1 Replace all six recurring production dashboards

Owner B after T2.0; can run alongside T2.2/T2.3.

- **Repository:** warehouse category tabs and live stock list first; item detail and genuine uses second; alchemy as one clear, measured action with actual cooldown/availability. Keep the original long-press eligibility and voluntary cost/gain behavior. Do not conflate current stock with keepsakes or voyage history.
- **Resource:** one collection-focused action area with actual production summaries, availability and elapsed cooldown. It must remain useful with no unlocked gather resources and after a return that changes stock.
- **Build:** browsable current/unlocked/locked construction catalog; selected building with all real prerequisites and costs, exact current ownership and one build/shortage action. Preserve focused `BuildLayer:create(focusBuildId)` as a direct-entry variant.
- **Make:** recipe catalog with selected recipe, available/required material counts, quantity adjustment and manufacture action. Preserve `focusResourceId`, all quantity limits and the existing missing-material route.
- **Train:** current roster/profession selection, recruit/train/evolve requirements and actual possessed versus assigned counts. Separate information from the selected commit action. Preserve every training mode and crew recovery route; do not fabricate new owned characters through decorative art.
- **Store:** real catalog and owned counts, selected item price and stock/lock constraints, quantity controls and original purchase action. Preserve bottom/focused entry and distinguish in-game goods from platform purchase utility pages.
- **Material dialogs:** parent-owned compact sheet with exact deficit, valid acquisition destinations and one obvious close. Returning from a source refreshes the same transaction context; replacing a sibling route removes the full obsolete modal stack.

Acceptance per page: empty/sparse/full lists, locked/unlocked variants, longest recipe, large numbers, late stock change while open, unavailable focus ID, repeated clicks, long press where supported, shortage → source → return, category switching, scroll state, close/reopen and cold stock refresh. Assert identical original callbacks and transaction deltas, guide step changes and listener cleanup. Dashboard implementation must not duplicate `LocalProduction` or DataManager logic in view code.

### T2.2 Redesign actual events and their child pages

Owner C after T2.0. Shared resource/crew art can land incrementally through F.

Use a compact site header with actual name/type/state, a restrained scene illustration keyed to the real event family, readable description/outcome/cost sections, and one chosen action plus secondary leave. Long options/arena levels live in a clipped scroll area, never under fixed controls. Occupied sites must clearly show their post-occupation description; an encounter preview is not a second gameplay outcome.

Cover the actual ten CSV dispatch families, using their existing handlers:

1. `changeToEnemyLayer` → `enterFightLayer` → `fightIsOver`
2. `changeToMaterialsLayer` → `enterMaterials` → active `enterRewardLayer`
3. `changeToSupplyPoint` → `enterSupplyPoint`
4. `changeToPubLayer` → `enterPubLayer`
5. `changeToBlackMarket` → `enterBlackMarket`
6. `changeToResurrectionLayer` → `enterResurrectionLayer`
7. `changeToNextMapEnter` → `enterNextMapEnter`
8. `changeToTeleportLayer` → `enterTeleport`
9. `changeToArenaLayer`
10. `changeToEternalArena` → `showMultipleButtons` / `checkJumpToEternalArena` / `enterToEternalArenaByLevel`

The four detail-cell builders remain connected to their real actions: `initCemeteryCell` → `reliveCallBack` / `buryCallBack`; `initPubBarCell` → `buyHeroCallBack`; `initBMarketCell` → `buyItemCallBack`; `initPackageCell` and `showCellInfo` for cargo information. Preserve `checkDatas`/`trySaveLimitedData`, `viewWillClose`, `close` and `leaveCalBack` behavior. Preserve the current skill provenance/details, prices, required tools, capacity constraints and limits.

Lifecycle acceptance: entering a child cannot unfreeze the map; closing exactly once reaches the correct parent; original `EventManger:freezeOwnerOperations`, `unreezeOwnerOperations`, `anEventHasTriggered`, `anEventHasToGiveUp` and `allEventsHasTriggered` remain the event/queue owners. Native tests must check visible event layers, minesweeper, nested detail closure and HUD restoration on both render paths.

### T2.3 Complete cargo allocation and chest pages; preserve combat contracts

Owner D after T2.0. Scope `FightMode.lua` edits to `FightRewardScene`, `FightBoxView` and `FightBoxViewAlert` constructors/presentation, retaining their data callbacks. Do not concurrently assign this file to a combat-stage worker. Event owner depends only on documented scene callbacks.

- Redesign `FightRewardScene` as legible cargo-versus-found-item allocation with unmistakable transfer direction, capacity and remaining important-item status. Preserve item-by-item moves, bulk pickup, zero-volume currency behavior, reserved/mission items, `isClosed`, callback and commit ownership. The live two-table layout currently hard-codes 250-point columns and large offsets; measure widths from the viewport instead of copying it into a new skin.
- `FightBoxView`/`FightBoxViewAlert` remain part of loot coverage: original `openBox`, `giveUpCallback`, `useDiamondCallback`, limits and costs still apply.

Acceptance: production encounter → ship battle → boarding battle → win/defeat → reward/return; normal and eternal failure; one and full supported fighter teams; effects on/off; healing empty/ready/cooldown; diamond shortage; interrupt/pushed scene/resume; full cargo, gold, reserved items, important-item refusal, manual transfers and bulk pickup repeated twice. Compare original damage/timing/outcome and all resource deltas. Fixture art variety is separate from natural combat acceptance.

### T3.0a Prove clean presentation on original maps before mass asset work

Owner E with F at the start of Tranche 3, after the pages tranche is accepted. This is an architectural/visual gate, not a save migration.

Recommended default: retain original orthogonal world/camera/input and upgrade the existing `SeaChartWorldTheme` surface/landmark/event/ship art to clean faceted, sunlit 2.5D. Preserve six actual biome identities (sand, forest, volcanic, ice, violet, ghost) with consistent lighting, contact shadows and readable event scale. This can achieve a coherent art family without requiring every scene to have the first map's isometric camera.

Prototype all of: legacy map 1 near port, map 2 crossing a mixed-family coast, and chapter 16 or another 101×101 mixed-family stress map. Include revealed and unrevealed cells, a traversable event, occupied variant and two overlapping land layers where applicable. Compare directly to the accepted clean map 1 at native size. If the result still reads as a different game, do not claim full all-map fidelity or just recolor more textures; use the generalized-adapter work described below as the Tranche 3 renderer requirement.

Acceptance for this gate: same saved tile/geography, input/camera behavior, fog semantics and callbacks, plus visual sign-off on materials/landmark depth/ship/event scale. No map data migration or `cleanFirstMapVersion` write. Profile this proof on a large map before authoring all six families.

## All-map feasibility and exact implementation constraints

### Why a broad CleanVoyageView enable is unsafe

`CleanVoyageView` is explicitly a map-one adapter. These dependencies are not general:

- `mount()` is gated by `CleanFirstMap.isEnabled(dm,mapIndex)`, which is a versioned **geography** contract for new-profile map 1. Reusing that marker for a renderer on other maps would conflate presentation with saved geography.
- `shipPoint()` and `drawWorld()` use fixed `CleanFirstMap.port()` `(7,11)` and a cosmetic berth offset. The correct reusable read-only port is already available from `AdventureNavigation.port(owner)`, derived from the real TMX `Objects/Start`.
- Two suppressed/overlaid land patches are hard-coded at x=5..6,y=7..8 and x=4..7,y=12..15, with fixed 290/590-width art; the 470-width harbor is positioned by fixed offsets. These are authored map-one compositions, not universal coast primitives.
- Terrain treats `Blocks_1`/`Blocks_2` presence/properties as full logical diamonds and uses one palm-coast art for connected components. It does not reproduce the original per-pixel atlas alpha, six family identity, flip transforms and actual layer order used by the world renderer.
- Event art specializes only three mines plus the tutorial wreck. Other markers use the inherited Meta sprite frame. Occupation is inferred from signed event properties; a generic renderer needs the real current layout/received/occupied state and animation semantics.
- Each refresh removes/rebuilds all world children and enumerates the map; discovery also regenerates a fragment program from nearby known cells and builds clipping stencils. That bounded 21×21 design has no accepted 101×101 performance or context-restoration evidence.
- It hides `owner.moveLayer`, including original world-space actors, effects, markers and guides. Existing Explore clean touch handling ignores drag/pinch and selects one of four directions around a fixed boat focus. Enabling it on legacy saves would change their chart-control behavior unless pan/zoom/recenter is explicitly reimplemented.
- The all-map HUD needs chapter-aware goal copy. `CleanVoyageHUD.refresh` currently checks the tutorial point without checking its `mapIndex` before showing nearby-wreck guidance.

### What SeaChartWorldTheme already gets right

`familyForLayer` joins actual cached source/replacement atlas identity. `landLayers` enumerates actual Blocks layers in native z-order. `addWater`/`addLand` preserve layer offsets, source atlas alpha and tile transforms; `placeMaskTile` handles all eight Tiled flip states. Land uses 16×16 chunks; coast uses 15×15 interiors with gutters and 256-pixel POT render targets; detail placement has safe land foundations and avoids event centers. `onContextRestored` and shader restoration are already integrated. Meta/grid/fog remain above terrain. This is a strong reusable foundation and avoids an engine rewrite.

Implement the clean family as namespaced asset selection/manifest parameters around those methods, retaining original alpha masks and lower-level lifecycle code. Do not casually change atlas sampling: tightly packed replacement atlases are nearest-filtered for a reason. Fog may receive a lighter clean color, but original alpha and premultiplied blend must be unchanged. New raised silhouettes must not reveal landmarks through a partially explored region; native fog-edge QA remains required even with unchanged z-order.

`SeaChartSlice` is another map-one authored component with exact 21×21 dimensions, GID footprint and origin guard. Its inherited painted coast must receive matching clean art or be explicitly suppressed for the clean world mode after equivalent coverage is accepted. It must not paint over arbitrary later-map geography.

### If identical first-map isometric presentation is required

It is feasible without changing a TMX or save schema, but it is a real rendering-adapter tranche, not a switch flip. Keep the original hidden map as the gameplay model. Add a separate display-capability selector, independent of saved `cleanFirstMapVersion`, and a generic projection/view model. This selector must have no player-data writes.

Required work before enabling it globally:

1. Read port, layer families, offsets, real tile flags/alpha and live event state from current map/managers; eliminate the fixed harbor/patch assumptions. Keep authored clean map-one composition as an explicit map-one preset only.
2. Derive/clip deterministic terrain chunks from the original footprint; render only legitimately visible event/land content. Keep collision and turn decisions in `Explore:jointedCalBack`/existing move path. Never use the visual silhouette as collision truth.
3. Provide bounded incremental discovery updates, reused shader programs and viewport culling for 101×101 maps; preserve/reuse the existing context-restoration mechanism rather than recompiling the world every step.
4. Project live route marks, occupation/disappearance/effects and tutorial guidance consistently; suppress no original gameplay information merely because `moveLayer` is hidden.
5. Preserve chart pan/zoom/recenter capability and exact inverse picking for old profiles; map the four logical cardinal directions consistently in the projected view. Cancels, held input, boat contact, map boundary and HUD interactions must remain inert where expected.
6. Handle map replacement, pushed combat, resumed voyage, player recenter, old active pending event, fog toggles and cleanup without stale nodes/schedulers. Keep compact HUD guards for animation, event layer, movement queues, disabled controls and all modal states.
7. Prove all 16 actual maps and independent old active saves before global activation. A safe fallback can prevent crashes for unknown source data; it cannot be counted as visual completion if it leaves an ordinary shipped map unstyled.

The safe default and this generalized adapter are alternatives for presentation, not two concurrent world systems to partially combine. Decide from T3.0a native comparison. Neither alternative authorizes remaking coast geography, hiding original routes, free sailing or a save migration.

## Tranche 3: complete the remaining game

### T3.0b Complete the actual combat stage

Owner D with F art, after loot/page changes in the shared `FightMode.lua` have been integrated and accepted. No parallel owner edits this file.

- Redraw ship and boarding deck art, both cannon views, chest states and battle-control frames into the accepted clean low-poly family. Replace fixed coordinate assumptions with a presentation layout computed from visible bounds. Keep `playerActors`, `enemyActors`, `enemyEffectActors`, ship/effect nodes, HP bars and cooldown-bar arrays available to original animation/update code.
- Stage both combat types through `FightScene:initShipWarUIScene` and `initAboardWarUIScene`. Actual enemies use real `soilderId`/CSV names; crew use real owned/embarked fighters. Display geometry must not add fighters, cannons or attacks.
- Distinguish a stable logical/effect anchor from replacement art dimensions. `runAttackEffect`, `injuredEffect`, `shakeEffect`, animation and particle routines read actor size/position and attach child effects; simply dropping a different-sized PNG into an old node will misplace effects.
- Preserve `FightScene:attack`, `miaoshaAttack`, healing/cooldown callback, `update`, buffers, `showCurtainEffect`, `setFightOverCallback`, `gotoFightRewardScene` and failure/revive behavior. Controls must expose real food/diamond costs before activation; do not turn costs into cosmetic buttons.

Acceptance: both actual battle types, full/one-fighter teams, actual crew/boss identity, effects and health/cooldown controls, stable anchors under original animations, no change to timing/damage/outcomes or costs. Then rerun event→combat→loot→map/defeat paths against the complete stage.

### T3.1 Finish all maps and chapter selection

Owners E + F; depends on T3.0a gate. C owns `WorldMapLayer.lua` callbacks/layout.

- Complete the selected clean approach for all six real atlas families and all 16 original maps, plus the versioned clean first map. Use clean biome-specific rocks/trees/ice/ruins instead of placing palms everywhere. Retain same sunlight direction, readable water and shore contrast, event scale and boat identity.
- Complete event art for every active normal/occupied/disappeared/locked marker family in the 512×384 event atlas contract; keep real Meta GID meanings. Dynamic `MapLayoutManagers` layout occurs before the renderer uses current events.
- Replace the stitched `worldMapBottom/Mid/Top`, chapter buttons/fogs/locks and ship-route art with a clean chapter overview preserving the CSV chapter coordinates, available chapter set and original scroll/navigation model. Any re-layout of display-only chapter cards must still use the original chapter IDs and lock checks.
- Preserve `WorldMapLayer:moveToMapByIndex`, `backToCurMap`, `enterMapByIndex`, `showBuyView`, `showChargeView`, `unlockMapDatas` and `unlockAction`. Returning invokes the original `owner:enterNextLayer(false)`; entering invokes `owner:enterNextMapEnter(true,index)`.
- Original diamond expansion-pack cost/confirm/shortage paths stay honest. Do not present an offline platform charge as successful.

Acceptance: every map header and family, all layer orders including map 16 duplicate atlas setup, fresh/partial/full fog, corners, zoom limits/recenter, return path, blocked directions, gate transitions both ways where allowed, paid-map cancel/shortage, full-size map performance and context restoration. Byte-compare TMX/packed data/save-schema inputs against the accepted baseline.

### T3.2 Finish utility, store and support pages

Owner B or a new exclusive utility owner after production dashboards are stable. Shared A must integrate hook changes once.

Cover `Talent.lua`, `Achievement.lua`, `Ranking.lua`, `DiamondStore.lua`, `ChargeMode.lua`, `ChargingView.lua`, `CDKView.lua`, `SevenDayBonus.lua`, `RandomEventMode.lua`, `RateView.lua`, `WarmSettings.lua` and the actually reachable legacy `Setting.lua` path. Include `DialogueView`, `AlertView`, `ToastUtil` and active help/description/material overlays in the final visual audit; do not fork their transaction/lifecycle owners.

- Talent is a custom `approvedPage`, not a routine management opt-in. Give its actual tree/list and selected upgrade cost a clean layout without exposing duplicate global controls.
- Achievements show real progress, attained/locked states and reward/point information; the current grid action only opens details, so do not invent a claim action. Seven-day reward states must distinguish pending, already received and unavailable days.
- Ranking/nickname and CDK support readable entry, validation, pending/offline/error responses and Back. Do not remove a supported action solely because the service is offline in this checkout.
- Diamond goods, charge, gift and offers get clear real cost, limits and availability. Keep platform unavailable responses; no mock successful purchase, fabricated inventory or new monetary transaction.
- Settings/help preserve caller return, persistence and exact effects-setting scope. Inspect actual Warm settings during normal gameplay; the legacy Settings page is not evidence for that route.
- Rate and random-event utilities must retain their real gating/dismissal/callback semantics rather than becoming dead decoration.

Acceptance: all routes from both business pages and every nested entry; locked/unlocked/empty/large/offline states; cancel and return to exact correct owner; editable text survives appropriate interactions; repeat claim/submit/purchase cannot produce repeated grants; no service success claim without a real configured platform result.

### T3.3 Close all art and narrative families

Owner F with C/D consumer changes; no economy-table edits.

- Finish all active crew/profession, boss, resource, building, ship, weapon, event, chest and utility icons. Audit unique art identities and aliases against production CSVs. Each 42-fighter-icon and 125-resource-icon inventory entry is either clean/reviewed, intentionally shared with matching identity, or explicitly recorded unreachable; no silent “miscellaneous art” remainder.
- Connect crew art consistently across Warm roster, train, tavern, expedition and combat. Boss lookup uses `Images/Boss/`; crew uses `Images/Icon/`. A replacement resolver must respect these distinct namespaces.
- Finish opening/chapter/story illustrations in `PlotMode`/`PlotLayer` and data-selected `Images/Plot` artwork as clean low-poly story vignettes. Preserve text, ordering, tap-to-advance, callbacks, guide progression and skip/stay behavior. Do not invent different story events.
- Harmonize skill/effect frames and UI particles with the clean lighting/palette without changing damage cadence, effect triggers or hit/skill meaning. Missing original particle assets remain tracked blockers unless fixed and verified within authorized presentation scope.
- Keep PNG dimensions/alpha footprints where existing code depends on them, or add explicit presentation wrappers with stable logical anchors. Never upscale tiny portraits into large battle actors and call it finished art.

Acceptance: reviewed family contact sheets plus native screens at actual scale, no mismatched old art dominating a reachable scene, no wrong item/crew/boss identity, no changed resource stats or unlock data, reproducible imports/provenance, all relevant glyphs present.

## Shared acceptance gates for both tranches

### Behavior and ownership

- Rendering/opening/listing/closing is read-only except the existing authorized lifecycle bookkeeping. Compare gameplay snapshots before and after opening pages; separately whitelist original login/production-clock effects for cold-save comparison.
- Production callbacks stay the sole spend/grant/upgrade owners; views only invoke them. Check stale references and repeated activation after view disposal.
- Original tutorial target handles and lock/opacity states survive. A cleaner layout cannot make an incomplete-guide action reachable early or lose the highlighted target.
- Modal owner graph is tested explicitly: parent sheet → detail → material source → back; sibling replacement removes old stack; no residual mask, click-through, double handler or leaked listener/scheduler.
- Explore turn, free event-entry cases, food coefficient/decimal state, collision, queue order, fog clear values, occupation and event pickup match the original engine/managers.
- Battle/loot close callbacks, `needsPop`, and scene push/pop remain exact. Ordinary event reward is not automatically a battle victory.
- Return/failure results remain committed receipts, never a second reward claim. Zero-crew recovery still reaches a valid next departure.

### Visual evidence

Use actual native Linux screenshots of reachable screens, not concept renders. Cover the first-batch supported physical/logical viewport matrix, including 480×800, 540×900, 640×960, 640×1067 and 720×1280 where applicable; keep 480×900 comparison captures. Engine design-space and physical window captures must be labelled accurately. No control or dynamic Chinese label clips, falls outside the viewport, hides behind art, or relies on unreadable downscaling. List clipping/camera stencil must also be checked in the full GLFW app, not only the component harness.

For Tranche 2, capture all six dashboards, one real example of each of ten event families, chest and cargo transfer, and verify unchanged battle/map entry/exit continuity. For Tranche 3, add both redesigned battle stages and the world proof fixtures before broad-map acceptance. For Tranche 3, maintain a route×state matrix for every surface above, all biome families and all original maps. A static native fixture does not count as natural progression or save compatibility.

### Regression suite plan

Extend tests near their real contracts; do not delete baseline expectations solely to turn checks green:

- Run final `tools/tests/run-coherent-game-tests.sh` with the accepted Lua/native harness setup. It includes Warm suites, coherent suites, the legacy aggregate with explicit `WARM_PIRATE_V1=false`, clean-map/view/HUD checks, glyph coverage and whitespace checks.
- Add real-native dashboard tests using the pattern of `coherent_forge_native.lua` for other production pages: actual CSVs/nodes/callbacks, mutable in-memory fixtures, exact costs, late changes, empty/locked states and cleanup.
- Extend management/local-production/alchemy/gather-cooldown/crew-recovery/talent/item-icon tests for composition and state preservation.
- Add event-family-native and event-detail-lifecycle coverage, including all ten production handler bindings and post-occupation/reward return.
- Add combat-stage-native and reward-allocation-native tests; retain existing loot capacity, mission abandonment, reward, prebattle and chest footer regressions.
- Run/extend `sea_chart_world_regression.py/.lua`, camera, atlas sampling, renderer/coast, world/slice, tile flags, sea-event semantics and chart lifecycle native tests against all real maps and the 101×101 stress fixture. New art dimensions and bases must update matching semantic/alpha-footprint checks deliberately.
- Retain independent old-active-save parity, native cold-position, atomic save/return/upgrade/record, resume/pause/settings tests and natural fresh-profile play. Run the relevant checks again after the final asset/font/text integration, not only on the worker branches.

### Final stopping condition

Tranche 3 is done only when the accepted branch contains the complete reviewed route/art inventory, final aggregate checks pass with their scope honestly stated, independent native continuity and old-save parity pass, and remaining platform/service limits are documented. Linux acceptance does not imply restored Mac/iOS/Android projects, mobile/audio acceptance or working online/IAP services. Publication, archival backup and deployment remain separate instructions, outside this read-only plan.

## Primary source pointers

- `docs/coherent-game/PLAN.md`, `ART_AND_SCOPE.md`.
- `CleanVoyageView.lua`: fixed projection/port/patches, full redraw/fog program, gated mount and touch adapter. `CleanVoyageHUD.lua`: guard and goal/route copy.
- `SeaChartWorldTheme.lua`: source-family/layer/flip handling, chunked land/coast/detail, lifecycle. `SeaChartTheme.lua`: material/atlas application, fog/grid programs. `SeaChartSlice.lua`: first-map authored footprint guard.
- `Explore.lua:initMapByMapIndex`: original TMX selection, managers, fog, event loading and presentation mount order. `AdventureNavigation.lua:port/snapshot/query`: existing map-derived route truth.
- `BaseView.lua:applyManagementTheme/addInfoNode`; `ManagementTheme.lua`; `DialogTheme.lua`; `MainMenu.lua:setApprovedPagePresentation/applyWarmNavigationAppearance`; `Dispatch.lua` route and teardown functions.
- `EventLayer.lua` event handlers and active `enterRewardLayer`; `EventDetailsLayer.lua` cell builders and transaction callbacks; `EventManger.lua` freeze/unfreeze/queue ownership.
- `FightMode.lua:initShipWarUIScene/initAboardWarUIScene`, `FightRewardScene:init`, `FightBoxView`; `CombatTheme.lua` current art selection.
- `bin/res/assets/data/{resourceInfo,soilderAttribute,strongholdAttribute}.csv`, decoded read-only with the repository's existing envelope decoder; `ResourceTheme.lua` exact ID/icon aliases.

## Exact management/support callback checklist

Verified against the inspected production files; spelling below intentionally matches the existing API.

### Gathering and warehouse

- `ResourceLayer:init`, `resetWorkData(bIsSave)`, `setWorkerUIWithData`, `setResourceUIWithData`. `subButtonDidClick` and `addButtonDidClick` long-press controls call `resetWorkData(true)` and persist `roleProducerQueue`. The anonymous middle `addInfoNode` callback grants original stone/wood, increments `achievement_Collect`, advances steps 3/300 and calls `createSuccessCheck(kUnlockBuild,"1")`. Do not replace this with a new resource-grant function.
- `RepositoryLayer:init`, local `buttonClickToggle(tag)`, `initBagDataWithType(sortType)`, `reloadData`. `ItemIcon.sdButton` single tap invokes `showInfoBox`; `registerLongPressedActiveOnce` opens sell quantities 1/10/all. Existing sale closures call `addPackItemWithId(k,-quantity)` then `addCoin(price*quantity)`. Preserve `lastSortType`, original non-swallowing item touch and click-area expansion.

### Construction, recipes and store

- `BuildMode` normal row action: `cheackResoucesOK` → `useResouces` → `createSuccessCheck(kUnlockBuild,id)` → `initdata`/table refresh, or `Lackmaterial`. Focused flow: `initFocusedBuild`, `refreshFocusedBuild`, `attemptFocusedBuild`, `leaveFocusedBuild`, `disposeFocusedBuild`; preserve generation/busy/disposed and eligibility guards.
- `MakeMode` row action: `cheackResoucesOK` → `useResouces` → `createSuccessCheck(kUnlockMake,_sortID)`; keep `_csvID` versus `_sortID` semantics and `focusEntry(id)`.
- `StoreMode` single purchase invokes `buy(_csvID,_sortID,1,nil)`; `showmorebuy` exposes 10/100/1000 via `registerLongPressedActiveOnce`. `bulkBuyOwner` prevents stacked dialogs. `buy` calls `cheackResoucesOK` → `useResouces` → `createSuccessCheck(kUnlockStore,_sortID)`. Insufficient funds uses original `showBuyGoldBox` confirmation.
- Build/Make/Store couple `cellhight=112` with table cell sizes, scroll offsets and focus calculations. A row-height redesign must change all presentation calculations together; don't leave focus offsets tied to the old height.

### Recruitment, promotion and material acquisition

- `TrainMode` local `Recruit()` runs after the existing footer `AlertView` confirmation, deducts original coins, updates `roleSoildierQueue`, guide step 11 and training achievement.
- Roster row opens `ChangeJobView:create(_soilder,idx)` with the existing max-star gate. `ChangeJobView:init` owns requirements and promotion action; success deducts original materials then calls `TrainLayer:changeJobCallBack`, which persists the roster and clamps `roleSelectUnit` to remaining quantities.
- `MaterialView:init` (same file) owns synthesis, purchase, production, exploration and market destinations. `makeCallback` / `buyCallback` refresh its parent. Child Close must restore the right promotion/material parent, not navigate Home or keep an obsolete mask.
- `Lackmaterial` is the shared shortage sheet used by catalog pages. Its callbacks must continue to refresh original owner data and route through the existing acquisition paths.

### Utility and services

- `Talent`: custom `approvedPage`, `keepNavigation=false`; `loadTalentData`, `refreshTalentHeader`, `destory`; preserve earned ordering and subscriptions. Its alchemy uses the BaseView controller. Intelligence opens `RandomEventView` only with `roleMapInfo` and `not isEnterMap`. `Dispatch:moveToTalent` clears guide step 401.
- `Achievement`: `init`, `loadAchievementData`; local `createItem` only calls `showInfoBox(getShowInfoBoxData(itemData))`. Preserve `roleAchievement`/`roleTalent` subscriptions and guide step 402 on `destory`. Do not add a new reward-claim workflow.
- `Ranking`: `changeRankType`, `reload`, `setRequestState`, `httpConnection(Type,Amount,UserName,completion)`; `InputNameView:submitName`/`close`. Preserve pending/disposed/request-serial guards, validation and nickname save. Empty `serviceURL` means truthful unconfigured-service state.
- `DiamondStore`: `init`, `loadData`, `buyGigtUIRefresh`, `clearPoint`, `moveToPoint`, `updateCountdown`. Gift confirm calls `PurchaseAvailability.request(payType)`; virtual-item confirm rechecks `buyState`, deducts diamonds, invokes `buyGoodsInDiamondStore`, advances repeat/next item and reloads state. Loading currently normalizes saved store data and clears `roleMapBuyItems`: compatibility tests must distinguish this existing side effect from newly introduced mutation.
- `PushGiftView:init` is inside `DiamondStore.lua`: close calls `self:close`, delayed buy calls `PurchaseAvailability.request(data.payType)`. `MainMenu:openGiftOffer` owns reference/cleanup and return-to-port availability gate.
- `CDKView`: `close`, `validateCode`, `setRequestPending`, `httpConnection`, `requestNetwork`. Actual submit calls `requestNetwork(textField:getStringValue())`; native redemption is platform/interface gated. Current legacy Setting exposes CDK only when UserCenter is enabled. Do not expose debug/reset or other gated controls simply to populate the clean settings page.
- `SevenDayBonus`: `create`, local `canClaimBonus`, `loadData`, anonymous claim callback. Preserve singleton, `claimStarted`/`isClosed`, claim-time date recheck and exactly-once `roleSevenDayBonus`. `NotificationNode` schedules this page; a MainMenu-only route checklist would miss it.
- `Dispatch:gotoSetting` uses `WarmSettings.open(owner)` in Warm mode. `WarmSettings.preferences` calls existing `setSound_off`, `setMusic_off`, `setEffect_off`, which save immediately. Closing settings returns to its owner and is not a voyage-save action.

### Shared callback hazards

`BaseView:addInfoNode` owns `progressSetBtn`, `BaseViewLastClickCDTime`, remaining-cooldown resume, long-press eligibility and guide-visible state. Its left/right navigation goes to gated Talent and RandomEventView. Keep this controller intact while its layout is adapted. `resetTopRightButtonToBack` and `resetTopRightButtonToRank` replace button images after theming; opt-in order or reskin calls must account for that. `SDButton` touch listeners use `normalSpr`, `clickArea` and schedulers. `AlertView` OK-only and OK_CANCEL variants have different callback/removal behavior; do not normalize them to one new callback semantics.
