# Gathering and warehouse composition

Local pages-v3 presentation work, 2026-10-11. Owned production files are `Resource.lua` and `Repository.lua`; no economy, save, engine, CSV, global theme, route framework or generated art changes.

## Visible composition

Both Warm pages explicitly consume the 480×800 `BaseView:applyCoherentPageShell` contract and its shared Back action. The old dashboard is retained under a hidden parent for its original controller and guide references; it is not drawn beneath the new content. `WARM_PIRATE_V1=false` takes the untouched legacy geometry path.

- Gathering has one 416×128 manual-collection card, actual gather base, the real gather action/cooldown, a 192-point clipped worker list and a separate two-column net-production ledger. Idle/total workers are immediately above the allocation list. Empty jobs and zero net production have honest empty states. Warehouse is a quiet secondary route.
- Warehouse has five 78-point category tabs, a 316-point clipped single-column stock list, real names/quantities, and a separate 128-point alchemy card showing the actual per-click gain and hold eligibility. Category selection and scroll position survive same-category stock updates. Only positive, displayed records in the selected original type appear.
- Single-tap information opens an owner-scoped sheet whose original description is fully scrollable. Long-press inventory sale retains the original 1 / min(10, captured stock) / all quantities, worth eligibility, deduct-before-gain order and explicit cancel. No new sale or alchemy transaction implementation replaces DataManager.
- Tutorial warehouse gates still hide stock before step 2. The visible title remains 荒岛 until that gate. Step 1 tells the player how to reach unlocked construction. The original delayed alchemy guide uses the moved visible action and the same canvas coordinates. Gather and warehouse red points are remeasured for the new action face.

## Behavior preservation

The actual original `setBtn` SDButton, its listener, `setButtonProgrees` ProgressTimer, `progressSetBtn` / `dealclick` / `openclick` controller, `BaseViewLastClickCDTime`, optional repeat-press upgrade and foreground correction are retained. The same nodes are safely retained/reparented/released. Only the face and measured hitbox are compacted. The original gather closure still owns its two random formulas, item IDs 1006/1007, achievement, guide steps 3/300 and construction unlock check. Worker changes still flow through `resetWorkData(true)` and `roleProducerQueue`; net production uses the original produce/resume computation.

Warm row touch adapters convert the world touch into the scaled scroll viewport before asking the existing SDButton listener to accept it. This avoids the legacy listener's parent-local/world-space clipping mismatch without changing the engine or shared SDButton. Worker, inventory and primary-action listeners do not swallow touches. Visible clipped-out rows reject touches. Refreshed row callbacks are invalidated; disposed pages stop delayed action callbacks and remove their original observers. Information/sale sheets are owner scoped.

Original production timestamps determine the net-harvest display. The Warm countdown clamps an overdue timestamp to zero and renders minutes/seconds; it never advances production. Live queue changes refresh the net ledger even when they did not originate from a plus/minus press.

## Automated verification

`tools/tests/coherent_supply_pages_native.lua` uses actual native Cocos nodes, fonts, packaged worker/resource CSVs, native SDButton handlers and the native action manager, with in-memory DataManager spies only. It does not use a profile, GUI input or a production save. Actions are explicitly resumed in the isolated fixture; this is not a claim of running-scene or full-game GUI acceptance.

Command:

```sh
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
EGL_PLATFORM=surfaceless /workspace/scratch/79976da795e7/PirateExplore-coherent/build/linux/tests/tutorial-log-native tools/tests/coherent_supply_pages_native.lua
```

Coverage:

- 480×800, 540×900, 640×960, 640×1136 and 720×1280 native geometry/font bounds
- Actual single/held worker SDButton press, non-swallowing touches, persisted queue, visible and clipped native hit targets
- Exact deterministic original gather deltas, item IDs, achievements, guide steps and unlock boundary
- Repeat gather guard, 30-second deadline, cold reopen after 9 seconds and foreground after 12 seconds completing only the remaining 18 seconds
- Original alchemy callback and real 0.3-second action cooldown; owned/unowned hold eligibility
- Native tap information, full descriptions, hold sale, repeated confirmation, 1/10/all, undersized batch and late stock insufficiency
- Every displayed stock record, all five category counts, every worker, large counts, same-category refresh/scroll, stale row/action suppression, empty worker/stock states and observer cleanup
- Explicit legacy opt-out for both real constructors

Additional passing checks: original `item_icon_offer_regression.lua` and `local_production_integration.lua` in legacy opt-out mode; Lua 5.1 parsing and scoped `git diff --check`.

The integration owner regenerates the shared font and runs the complete aggregate. Independent desktop visual/real-input acceptance is still required. No GUI action, restart, publication, commit or save change was performed by this worker.

## Independent-review drag fix — 2026-10-11

Review reproduced a release-after-scroll defect in the begin-only row clip adapter: a 36-point finger move plus a 36-point list offset could still allocate a worker or open item information. Both page-local adapters now track the gesture in the fixed scroll viewport, cancel after more than 8 layout points of finger movement or more than 1 point of content-offset movement, and reject releases outside the viewport. Cancellation clears the pressed state and stops the SDButton normal-face action scheduler. Both the initial hold path and the subsequent direct repeat callback are guarded. Native touch cancellation is handled locally. There are no shared SDButton or engine edits, and stationary gestures retain the original single/repeated callback behavior.

The updated native suite passes 4,336 assertions, including the exact independent repro at all five viewport sizes, drag before the first hold, offset movement before hold, release beyond clipping, dragging away and returning, touch cancellation, and dragging after a valid first hold. Stationary tap and scheduled repeated hold still work after a cancelled gesture. The original external repro now reports worker allocation 2 → 2 and no warehouse modal. A read-only runtime counterfactual substituting the prior begin-only adapter fails the new worker-drag test, proving the regression covers the reported defect. Legacy item/offer checks, Lua parsing and scoped whitespace validation also pass. Full desktop input acceptance remains independent.
