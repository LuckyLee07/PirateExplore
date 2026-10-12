# Cargo allocation and chest pages

Local pages-v3 implementation. No publication, save migration, economy-table edit, combat calculation or battle-stage change.

## Composition

- The active `FightRewardScene` has one cream cargo sheet over the shared clean sea, responsive hold/found columns, per-unit volume, important-item status, a live capacity bar and one primary `完成装载` action. `尽量装船` keeps the existing bulk-order semantics. Empty lists are explicit.
- Chest presentation retains six independent slots and the original open/revealed state distinction. Faceted native wooden chest art has closed lids and open cavities. `空箱`, earned and unearned reward captions share the below-chest baseline. Earned reward commitment remains in the original `openBox` method; closing does not claim again.
- Details retain original names/descriptions, with a bounded scroll region for long chest text. Retry prices and available diamonds are visible. The optional seven-diamond continuation sheet retains its separate original price.
- `WARM_PIRATE_V1=false` retains the previous layout. Resource icons still use authoritative `ItemIcon` art/fallbacks; this art inventory is inherited/mixed and requires the later semantic icon-art tranche. This is not an icon-fidelity completion claim.

## Contract and lifecycle

The original bag/list sorting, single-item transfers, gold's all-at-once zero-volume transfer, bulk stop-at-first-blocked behavior, capacity floor, retained zero-volume items, required quest items and food warning remain intact. `settleCargo` retains pack write → original callback → `isClosed` order; an in-progress flag now blocks synchronous listener/callback reentry. External cleanup does not settle staged cargo, and stale controls are inert.

Chest reward probability calculations, first-chest guarantees, actual grant owners, 2/4/8-diamond retry amounts, seven-diamond optional continuation, give-up fake reveals and original completion delay remain unchanged. Generation/disposal/completion guards block repeated/stale opens and duplicate scene transitions. Ordinary event rewards still carry a false fight result.

## Verification

Passed on 2026-10-11:

- `coherent_loot_pages_native.lua`: actual production constructors/methods with shipped CSVs and native nodes, at 480×800, 540×900, 640×960, 640×1067 and 720×1280 logical sizes. Checks full/empty/overflow hold, reversible transfers, exact gold/quest/reserved quantities, no opening-time grants, late input, external cleanup, repeated settlement and synchronous callback/state-listener reentry.
- Chest native cases: failure, insufficient diamonds, original paid retry, all three successful first-chest rewards, give-up unearned reveals without grants, optional seven-diamond shortage/continue/cancel, long scrolling descriptions, repeated completion and new-chest reentry.
- The actual `EventLayer:enterRewardLayer` method is invoked with a navigation spy: push → pack commit → pop → refresh committed bag → next-layer callback once. This is a production callback contract check, not a claim of full-game natural-play acceptance.
- `coherent_loot_pages_regression.lua`: guard-removed counterfactual duplicates commit/callback; actual guard gives exactly one write and one callback while preserving false event results.
- Legacy opt-out: `loot_capacity_regression.lua`, `chest_footer_regression.lua`, `item_icon_offer_regression.lua`, `occupied_event_copy_regression.py`; Lua parsing, font coverage and whitespace checks.
- `coherent_loot_pages_render.py`: actual offscreen Cocos/EGL pixels for cargo, closed chests and revealed chests at all five dimensions. Also invokes real native TableView touch begin/end at transformed/scaled visible coordinates, verifying the selected food row and rejecting outside-clip touches. No SDButton is used by the new cargo lists.

Reproduce core tests from the repository root:

```sh
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
/workspace/shared/lua51 tools/tests/coherent_loot_pages_regression.lua
EGL_PLATFORM=surfaceless /workspace/scratch/79976da795e7/PirateExplore-coherent/build/linux/tests/tutorial-log-native tools/tests/coherent_loot_pages_native.lua
```

Render evidence using the existing Linux build:

```sh
PIRATE_BUILD_DIR=/workspace/scratch/79976da795e7/PirateExplore-coherent/build/linux \
COHERENT_LOOT_CAPTURE_DIR=/workspace/shared/pirate-audit/loot-pages \
python3 tools/tests/coherent_loot_pages_render.py
```

The offscreen helper creates no GLFW window. A harmless GLFW platform-detection warning can appear while its headless GLView adapter initializes; rendering uses surfaceless EGL. Native labels, sprites, menus and clipping are rendered to a full-size FBO. These are not physical desktop-window screenshots. Full GLFW route/camera/stencil review, natural battle→reward→map progression, real save continuity, and aggregate cross-page acceptance remain parent/reviewer gates.

### Inherited over-capacity cargo correction

An actual reviewed chest flow can commit 22 cargo into a 20-capacity hold before entering reward allocation. The Warm hint now inspects the remaining loot volumes: zero-volume currency/quest items remain collectible even when full or overfull; mixed loot distinguishes them from volume-bearing items that require space. After all rewards are collected it explicitly retains the over-capacity amount and permits the original completion behavior. No cargo is automatically trimmed and no transfer/grant rule changes.

Native coverage at every matrix size now includes 22/20 plus currency-only rewards, mixed currency/volume-bearing rewards, essential zero-volume quest rewards, already-empty rewards, collection-to-empty transitions and exactly-full currency-only rewards. It verifies read-only copy construction, original blocked-volume behavior, exact-once gold, quest settlement refusal before pickup and unchanged overfull persisted cargo. Additional rendered evidence: `cargo-overfull-currency-WIDTHxHEIGHT.png`.
