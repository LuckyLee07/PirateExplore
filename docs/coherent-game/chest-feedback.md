# Chest reward feedback: focused follow-up

Base: `3565e7be850bd35bac7aa4996b3c41d54cb06aa0`. Local-only change.

## Result

A coherent chest now reports the actual reward in its existing persistent detail
line: `金币 × 50 · 已收入`, for example. The opened chest still retains its item
icon and earned quantity. Inspecting a revealed prize says `未获得`; it does not
imply a grant. Opening, reinspection, and description scrolling create no extra
success toasts. The item description remains intact and scrollable.

## Exact production scope

Only three production Lua files change:

- `FightMode.lua`: pass reward quantity/earned state to the existing detail
  renderer; opt out of currency success tips for coherent chests; keep the
  material-only generic success tip on the legacy path.
- `ExploreBagController:addCoin(amount, isTip)`: the new optional final argument
  suppresses only the two success tips when explicitly false. The default,
  including all existing ordinary/manual callers, retains both original tips.
- `DataManager:addDiamond(amount, bIsShowAlert, isTip)`: the new optional final
  argument suppresses only the positive success tip when explicitly false.
  The second argument still controls shortage alerts exactly as before. All
  preexisting callers retain their old behavior.

No random selection, first-three-free behavior, grant, arithmetic, overflow,
mission, callback, save ownership, immediate diamond credit, or paid-retry code
changes. Existing setRoleData calls and their argument order remain intact.
No generic ToastUtil filtering, timer, global quiet mode, or combat changes.

## Verification

- Helper logic and real Cocos/native helper matrices: omitted/true/false success
  flag; positive/zero/negative amounts; all combinations of the original
  shortage-alert flag; exact values, write count and write-before-feedback.
- Actual native constructors and MenuItem callbacks at 480×800, 540×900,
  640×960 and 720×1280. Deterministic test rewards use the original grant paths:
  50 map coins, two material items and the original first-time five diamonds.
  Three opens have exactly three writes, zero success toasts, and three
  successive exact detail receipts. Permanent gold remains unchanged.
- Retained stale controls, repeated current controls, first-time-close ownership
  and callback-once behavior; direct full/overfull material grants; empty chest,
  insufficient diamonds, original two-diamond retry/spend-before-grant ordering;
  give-up and unearned-prize inspection without grants.
- Real dispatched native description drag remains visible and scrolls. Existing
  cargo tests cover transfers, mission/reserved items, settlement reentry,
  overflow and actual EventLayer handoff.
- Actual legacy chest constructor keeps the original four tips across the same
  three awards: coin gain, coin total, generic material success, diamond gain.
  Ordinary manual currency rewards and errors are unchanged.
- Whole-file conservation normalizes only the exact reviewed feedback edits in
  all three production files back to the frozen base bytes. The original 71
  method checksums are unchanged and still run after that same narrow
  normalization. Deliberate grant/counter mutations remain detectable.
- Independent native counterfactuals restore each old coin, material or diamond
  toast in memory; each fails the zero-duplicate assertion on the actual chest
  callback. The existing tap-began counterfactual fails real dragging.

The new tests are automatically included by the coherent aggregate's file globs;
the existing native render runner now also runs the focused chest sequence and
its three toast counterfactuals. Test outputs and offscreen captures are retained
under `/workspace/shared/pirate-audit/chest-feedback` in the task environment.

## Boundaries

These are in-memory Cocos/EGL component and source-conservation checks. The
fixture replaces persistent storage with an instrumented in-memory store and
observes original shortage text without entering the shop. No GUI, real player
profile, network purchase, publication or full-game replay was performed by
this task. Independent desktop review owns actual-application acceptance.
