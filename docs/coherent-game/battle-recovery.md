# Coherent battle defeat and revival

## Scope

Recovery-only successor to `3565e7be850bd35bac7aa4996b3c41d54cb06aa0`.
No new bitmap art, economy changes, save-format changes, player profiles,
platform purchases or publication. `WarmFailureResult` remains separately owned.

Both normal battle types now dispatch their actual zero-HP branch to a clean
recovery choice. Declining reveals an empty, sunlit version of the existing
battle deck, clear original loss consequences, one `回港整备` primary and an
explicitly optional `查看付费礼包（可选）` secondary. The illustrated map boat
was deliberately not reused because it contains two painted people, which
would falsely suggest surviving crew after defeat.

The choice displays the current diamond balance and shortfall. Below 50, the
muted action says `钻石不足 · 查看说明`; it invokes the original insufficient-funds
explanation and cannot revive or debit. At 50 or above, it displays the exact
`50 钻石复活` action. The balance is refreshed while open and again at the tap.
The original `DataManager:addDiamond(-50,true)` still validates the real balance.
Successful revival invokes the existing event-layer `safeBackToLayer` once.
An absent event return target is checked before a debit. The result text uses
the existing player-facing destination `复活据点` rather than a technical record.

The original loss callback receives the same captured `fightResult`. Eternal
challenge failure retains its two-second automatic callback and has no gift
upsell or new normal-voyage settlement. With `WARM_PIRATE_V1=false`, both old
AlertView constructors and the entire old loss overlay remain unchanged.
Only the two exact opt-in dispatches are stripped in the existing conservation
test before its 71 original-method byte comparisons.

## Input and lifecycle

- Duplicate prompts/results reuse one live presentation.
- A shortage modal or gift blocks underlying recovery actions.
- Paid and return handlers reject rapid, reentrant, stale and disposed input.
- Closing/reopening presentation does not reuse a stale action generation.
- Gift Close drops its native reference; reopening does not purchase.
- Individual owner removal retires its own sibling gift. Whole-scene exit
  invalidates it without editing the child vector during native traversal.
- All presentation schedules and touch listeners are removed on disposal.

## Verification

Evidence directory: `/workspace/shared/pirate-defeat-recovery/`.
Native checks use the corrected shutdown-fix build, after sourcing
`/workspace/scratch/79976da795e7/linux-runtime/env.sh`, never the old coherent
binary. Lua is `/workspace/shared/lua51`.

Passed:

- `warm_battle_recovery_native.lua`: real ship/boarding constructors and original
  zero-HP update, 360×640 and 480×800 geometry/font checks; actual native menu
  touches in the render harness; shortage, decline, gift close/reopen, return,
  exact 50 revival, duplicate/rapid/stale actions and missing original target.
- Exact 49/50 boundary plus 49 → 50 → 49 → 50 balance changes while the choice
  stays open. A previously affordable caption cannot cause an invalid debit.
- Eternal original two-second timing and both legacy opt-out constructors.
- `warm_battle_recovery_lifecycle_native.lua`: actual PushGiftView delay, original
  product ID, unsupported Linux and supported bridge spies, close/reopen,
  economic-state immutability, stale return/purchase and owner cleanup. Its
  render run additionally checks a genuinely running owner's removal and
  full-scene replacement. No billing bridge is contacted.
- `coherent_battle_recovery_shortage_native.lua`: actual reviewed `ff1a060`
  DataManager method with this recovery UI; Linux, missing Android bridge,
  supported iPhone spy, 49/50, changed balance, native reentry, original in-map
  route 999, cancel, no failed debit and exactly one successful original write.
- Existing clean battle conservation, clean battle native and boarding-body
  native suites.
- Full Warm aggregate: 22 suites passed, 0 failed (8 logic, 14 native).

The shortage integration test intentionally requires the truthful shortage
successor, already selected by the integration lead. From this recovery-only
branch it was run with `PIRATE_RECOVERY_DATA_MANAGER` pointing at the reviewed
DataManager in the diamond-shortage worktree. After integration, no override is
needed. No other worktree was edited.

The old `purchase_availability_regression.lua` fixture still fails at the
pre-existing Warm service-helper stub (`S` is boolean) on this base. It is not
counted as passing; actual native gift/platform checks above cover this change.

## Reproduce

```
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
export LUA_BIN=/workspace/shared/lua51
export WARM_NATIVE_BIN=/workspace/scratch/79976da795e7/PirateExplore-shutdown-fix/build/linux/tests/tutorial-log-native
tools/tests/run-warm-v1-tests.sh
$LUA_BIN tools/tests/coherent_battle_stage_regression.lua
$WARM_NATIVE_BIN tools/tests/coherent_battle_stage_native.lua
$WARM_NATIVE_BIN tools/tests/coherent_boarding_bodies_native.lua
$WARM_NATIVE_BIN tools/tests/coherent_battle_recovery_shortage_native.lua
PIRATE_BUILD_DIR=/workspace/scratch/79976da795e7/PirateExplore-shutdown-fix/build/linux \
COHERENT_BATTLE_CAPTURE_DIR=/workspace/shared/pirate-defeat-recovery \
python3 tools/tests/coherent_battle_recovery_render.py
```

Primary component captures:

- `revive-boarding-360x640.png`: zero-diamond choice, actual combat underneath
- `revive-exact-50-360x640.png`: exact affordable boundary
- `defeat-boarding-360x640.png`, `defeat-boarding-480x800.png`: empty-deck loss scene
- Equivalent `revive-cannon-*` and `defeat-cannon-*` captures

These are real Cocos/EGL component renders and isolated-state tests, not a new
natural playthrough or desktop GUI acceptance. Whole-game GUI verification is
owned by the independent audit task. Mobile billing success is not verified.

## Shortage ownership repair (integrated 3124589 successor)

The independent review exposed an ownership gap hidden by the earlier shortage
fixture: the real `DataManager:addDiamond` opened a scene-owned shortage dialog,
and its real gift survived removal of the recovery owner. The fix adds an
optional fourth, per-call presentation context. Recovery supplies its owner,
a liveness guard and its tracked gift presentation function. Ordinary callers
and the `WARM_PIRATE_V1=false` branch keep their original ownership and behavior.
The debit remains the original exact `-50`, alert flag `true`, and unmodified
DataManager validation/write. Product ID and in-map depth `999` are unchanged.

The existing WarmDialog owner observer now retires the shortage prompt. The
recovery observer retires both directly opened and shortage-opened gifts,
clears its pointer, marks purchase callbacks closed, hides the view, removes
listeners and stops descendant actions. An individual running-owner exit removes
the exact gift sibling. Full-scene exit invalidates it without erasing scene
children during native traversal. Unrelated dialogs are never swept.

New `warm_battle_recovery_shortage_ownership_native.lua` executes the actual
DataManager shortage method, actual WarmDialog and actual PushGiftView together.
It covers both orphan routes, retained controls, delayed Buy, destroy/cleanup,
running detach and full-scene replacement, unrelated scene dialogs, cancel and
fresh retry, live platform availability, the original product/depth, exact 49/50
and changed balance, reentrant successful debit, default callers and legacy
opt-out. It is discovered by the Warm aggregate and explicitly included in the
recovery render runner. The earlier narrow integration fixture was adjusted to
observe the explicit owner and use a native gift node. The source-conservation
fixture normalizes only the exact six already-reviewed recovery hook lines and
the explicit presentation-context addition; its whole-file checksums and
intentional gameplay-mutation counterfactuals remain unchanged. The 71-method
battle conservation check now shares that same exact normalization.

Evidence: `/workspace/shared/pirate-audit/recovery-shortage-ownership/`.
The isolated native suite passes 243 assertions. Its genuine running-scene
render run passes 424 assertions, including detach/destroy/cleanup/full-scene
exit with retained stale shortage and real gift controls. No real payment,
player profile, GUI, or publication was used. This is component acceptance,
not evidence of a natural whole-game run or mobile payment success.
