# Failed-voyage continuity

The new `WarmFailureResult` closes the gap between a saved failed voyage and Home. It is presentation only. Its sole production hook is inside `Explore:returnToBase`:

1. In enabled AdventureProgress v1 mode, capture cargo and existing revival counts before `Killed` or `NoBread` settlement.
2. Let the existing `Explore:addDeadData`, `AdventureProgress.failVoyage` and existing cleanup run unchanged. Their failed-save return exits before any result or Home transition.
3. Confirm the same voyage is now inactive, player status is Home, battle cargo and battle queue are cleared, and any genuine durable result is a failure.
4. Show the outcome only after `gotoMainUI` has produced the new Home owner.

No hook is added to legacy saves or normal return. No save schema, reward, revival, battle or loss transaction is changed.

## Outcome semantics

- The reason distinguishes battle defeat from exhausted food.
- Lost companions are the positive delta in the committed revival record, not invented survivors or a comparison with crew already left at Home.
- Ordinary cargo and sea coins are reported as not returned.
- Original `carryType=2` mission exceptions are named separately as retained. The original failure transaction remains their only owner.
- A log link appears only when the matching failed voyage was actually recorded. No historical backfill, treasure or reward is created.
- **重整船员与补给** closes first and calls the existing Home primary handler. Empty-fleet recovery and ordinary preparation stay state-responsive. It never departs automatically.

The failure sheet uses Home's existing outcome slot to block background actions. Touch swallowing, owner cleanup, single presentation, callback generation and closed-state guards prevent duplicate or stale actions.

## Verified fixtures

```sh
/workspace/shared/lua51 tools/tests/coherent_failure_result_regression.lua
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
MESA_SHADER_CACHE_DISABLE=true build/linux/tests/tutorial-log-native tools/tests/coherent_failure_result_native.lua
```

Both pass. The regression invokes the exact production return callback and real death-record assembler on the existing encrypted transaction fixture. It verifies both failure causes, failed-storage retry, exact crew/cargo losses, retained mission items, post-commit/new-Home order and repeated-callback suppression.

The native test uses actual Home and Cocos nodes at 480×800, 640×960 and 640×1136. It verifies text bounds, both causes, long-result pagination, no clickthrough, stale callbacks, once-only preparation/log routing and owner disposal. It also activates the real Home primary handler for empty-crew recovery and normal preparation. Presentation operations perform zero writes.

Existing `adventure_return_ui_transaction_audit.lua`, `adventure_state_audit.lua` and `warm_return_result_regression.lua` also pass after the hook. This does not claim a full-game defeat visual run, mobile acceptance or publication.

## Retained-cargo pagination correction

Actual defeat testing with four loss rows and one retained mission shard exposed a split heading: the retained label landed at the bottom of one page and its item appeared on the next under the fixed lost-cargo title. The receipt now paginates lost and retained categories independently, with the correct category heading repeated on every page. Capture, transactions, save data and recovery routes are unchanged.

Native regression now covers 360×640 as well as the prior three sizes and traverses every long receipt page. It verifies category headings, retained-item separation, text bounds, stale page controls and zero presentation writes. The original production failure transaction regression still passes for both causes and failed-save retry. Actual desktop successor pixels remain pending.
