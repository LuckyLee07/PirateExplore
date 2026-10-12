# Scoped ownership of coherent shortage presentations

## Scope and preserved behavior

This follows recovery-only `0e53df6bb2b3dd65ccfd5b70b42b67443053744b`.
Independent runtime review reproduced the same orphan prompt/gift in the actual
DiamondStore. Source inspection identified the coherent expansion selector,
chest retry/continuation and event tavern/black-market routes as additional
callers. Only these known coherent callers are opted in.

`WarmShortageOwnership` implements the optional DataManager presentation
context already introduced by the recovery repair. It never performs a debit,
credit, grant, unlock, navigation or platform purchase. A private owner child
owns each shortage dialog. This separate dialog slot is necessary for tavern
recruitment: the initial caller confirmation must finish without swallowing or
closing the new shortage explanation. There is no mutable global owner.

Each context captures its caller, scene and presentation generation. It guards
late gift purchase callbacks synchronously, tracks the exact real gift, and
retires prompt/gift on owner exit/cleanup, explicit close and known generation
changes. A scheduled observer also retires a context when external code changes
a captured guard. Retirement marks callbacks closed, hides presentation, stops
descendant actions and removes listeners immediately. It removes exact siblings
on individual owner disposal; during whole-scene traversal it leaves removal
to the native scene. WarmDialog exposes a narrow `retire` operation for that
non-removing lifecycle path. Unrelated dialogs are untouched.

The original DataManager amount, alert default, validation and write remain
unchanged. Chest retry still uses `FailDiamond[failTime]`, continuation uses 7,
store uses its shipped item price, chart uses the original expansion price,
and events use their original cost. Success/grant/callback order is unchanged.
Product IDs, supported-platform availability, truthful unsupported copy and
in-map depth 999 are preserved. Non-opted-in callers remain scene-owned;
legacy WARM=false routes do not opt into the context.

## Verification

Evidence: `/workspace/shared/pirate-audit/coherent-shortage-owners/`.
All runs use the corrected shutdown-fix build and extracted SDK environment.
Fixtures use in-memory role data and a supported-platform purchase spy. The
successful runs block service initialization and do not access a profile,
open a GUI, make a real purchase or publish anything.

New actual-caller suites execute production constructors, confirmation/debit
methods, WarmDialog and PushGiftView together:

- Store: prompt-open/gift-open remove, manual destroy, real reload, direct
  generation mismatch, full-scene replacement, retained controls, cancel/retry,
  supported spy product and the original exact virtual debit. Both native scene
  sibling orders are explicitly sorted and asserted for every disposal path.
- Events: both diamond tavern recruitment and black-market purchase; prompt-
  open/gift-open removal, close, real reload/reselection generation invalidation
  and whole-scene replacement, zero failed debit/grant, and exact successful
  original price plus one grant.
- Chest: actual failed-chest retry and seven-diamond continuation; prompt/gift
  removal, reload, give-up and full-scene replacement, unchanged failed economy,
  and exact original successful debits.
- Selector: actual EventLayer entry and paid selector confirmation; prompt/gift
  removal, detach without cleanup then reentry, modal generation replacement,
  full-scene replacement, no failed unlock and original exact successful price.

The general native suites run under the aggregate. The dedicated
`coherent_shortage_ownership_render.py` additionally uses the selector's real
GLView/Director harness to cover actual running-scene lifecycle traversal.
Existing recovery runs and all source-conservation checks remain enabled.
The chest full-file allowlist adds only the exact ownership calls; original
checksums and gameplay-mutation counterfactuals are unchanged.

The old loot-render reentrant-close counterfactual targeted the previous exact
`if offered` guard and therefore silently stopped mutating the code after the
recovery change. It now asserts the new complete guard exists, changes only
its duplicate-return behavior, and still requires the same real reentrant
callback failure. Its positive runs and all five negative counterfactuals pass.
The original failed recovery aggregate output is retained separately.

## Reproduction

```sh
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
export LUA_BIN=/workspace/shared/lua51
export PIRATE_BUILD_DIR=/workspace/scratch/79976da795e7/PirateExplore-shutdown-fix/build/linux
export WARM_NATIVE_BIN=$PIRATE_BUILD_DIR/tests/tutorial-log-native
python3 tools/tests/coherent_shortage_ownership_render.py
python3 tools/tests/coherent_loot_pages_render.py
bash tools/tests/run-coherent-game-tests.sh
```

These are real native component and interrupted-lifecycle checks. They do not
establish natural whole-game desktop acceptance or successful mobile billing.

## Retained-scene suspension follow-up

The gift-first native sibling order was also checked with scene push/pop,
which does not perform destructive cleanup. It revealed that the earlier
recovery observer could drop its gift pointer before hiding the gift or
stopping its delay. The native gift guard already rejected purchases, but the
retained presentation reappeared when the scene resumed. WarmDialog similarly
invalidated callbacks on exit without hiding its retained scene sibling.

The recovery gift observer now performs local non-removing retirement before
clearing its pointer, as the general context does. WarmDialog disposal hides
the exact retired sheet. Both gift owners also remove their exact Lua modal
registration using `DialogueViewManager:removeView`, which hides an empty mask
without removing scene children. This prevents a retired gift from remaining
in the resumed scene's modal stack; `releaseEmptyMask` is deliberately not
called during native traversal.

Permanent recovery tests now cover both native sibling orders and push/pop,
with retained prompt/gift controls, hidden presentation, stopped Buy delays,
and cleared modal registrations. General store tests cover the same two
orders and push/pop. Other general caller suites retain their direct-owner,
generation and destructive-scene checks. Evidence for this follow-up is in
`/workspace/shared/pirate-audit/shortage-suspension-retirement/`.

## Safe physical removal after lifecycle callbacks

Independent assertion-log review found a second native constraint:
`Node::removeChild` caches its child index before invoking that child's exit
callbacks. Removing a scene sibling that sorts earlier can therefore invalidate
that cached index even while the parent scene is running. A trailing unrelated
sibling can be erased incorrectly instead of producing an assertion.

All lifecycle retirement now makes prompt/gift callbacks inert, hides them,
removes listeners, stops purchase/gameplay actions and clears the exact modal
registration immediately. Physical sibling removal uses a node-owned zero-delay
cleanup action, after the native callback stack has unwound. The same rule
covers a default scene-owned dialog's observer. Explicit user close/rebind paths
remain immediate where no native parent removal is in flight. Gift retirement
is idempotent so later exit callbacks do not cancel the safe cleanup action.

The recovery and store tests retain a following scene sibling and inspect the
actual native child vector, not just parent pointers, in both sort orders.
They then advance one safe tick and check the exact retired node was removed.
Prompt/gift Buy delays are distinguished from the harmless cleanup action.
Positive recovery, caller and loot render gates now reject native `Assert
failed:` and binding error output as well as Lua errors and nonzero exit codes.
Intentional negative counterfactuals stay in their separately scoped checks.
