# Warm v1 pause and restored voyage

The warm-only `暂歇` HUD button is at logical `(267, height − 38)`, sized 56×40
at 640-point width. Legacy opt-out keeps the original seven controls.

## Actual behavior

- Pause opens only on a ready, non-hungry, non-guided tile, with no movement
  queue, active gesture, disabled steering, visible event, pending event, or
  pending fight. Busy taps explain why the player must wait.
- Existing Explore/Jointed/EventManger/FogManager/MapLayoutManagers work uses
  Cocos actions. The sheet pauses only previously running action targets inside
  Explore. Unrelated targets immediately resume; already-paused targets are
  never included. A scene-owned touch-swallowing sheet plus map/steering guards
  block new movement. This pauses sailing and sea events, not all game services.
- Continue resumes the same targets in the same Explore instance. It neither
  constructs a new voyage nor charges, grants, abandons, settles or resets one.
- `查看返航条件` closes the pause and activates the existing return button. That
  button presents the current free/scroll/diamond quote; the existing return
  backend revalidates it before settlement. Pause itself performs no debit or
  return. No new free rescue or invented abandonment rule is introduced.
- An Explore restored with an existing saved tile gets a read-only
  `接着上次的航程` notice, queued on its owner until scene entry. This avoids
  attaching to the outgoing scene while `Director.replaceScene` is pending.
  The once-only flag is set only after the notice opens. Continue preserves the
  original event-entry callback.
  Existing `willFight` replay is not intercepted or changed. Missing stored tile
  means no claim that a previous location was restored.

## Explicit save and honest failure status

Opening the sheet does not save and says that this manual save has not yet run.
`保存当前航程` uses the existing storage formats and two verified writes:

1. Atomic replacement of the current `gameMapN` JSON, including its actual fog
   and map data
2. Existing complete encrypted `UserData.commitAdventure` role snapshot, with
   the current logical tile and fractional food use; cargo, crew, active voyage,
   pending outcome, currency and the original paid-return flag remain unchanged

These are two separate files, not a combined atomic checkpoint. A map-write
failure leaves both disk files unchanged. A role-write failure after map success
is explicitly reported as `海图已保存，航程保存失败；请重试`. Cold loading that
partial pair restores the previously saved role tile/fraction/cargo/active voyage
alongside the newer map/fog. The sheet does not claim that old map bytes were
preserved. Retry saves the current role position/fraction without duplicating
costs, rewards, cargo or a voyage. Only both explicit successes produce
`当前海图与航程已保存`.

## Evidence

- `warm_pause_regression.lua`: actual encrypted UserData and JSON cold reload;
  map failure, partial pair, retry, unchanged economy/cargo/voyage/return flag,
  and pending-fight/busy gates. Only isolated fixture storage is touched.
- `warm_pause_native.lua`: actual Cocos action-manager freeze/resume, unrelated
  actions, already-paused descendants, native controls/text bounds at
  640×960/1067/1136, same-scene continuation, return-button handoff, read-only
  restore notice, save-status failures and owner teardown.
- `warm_resume_transition_native.lua`: actual Director `runWithScene` and
  pending `replaceScene` with production controller routing; restored chapters
  1/5/7, duplicate pre-entry calls, one continuation, pre-entry cleanup, unchanged
  pending-fight replay and fresh arrival. The old immediate-open implementation
  fails the pre-entry assertion in an independent counterfactual check.
- `warm_exploration_native.lua`: existing seven contextual controls remain in
  place, with the warm-only pause entry added; original food and return behavior
  remains covered in warm and opt-out modes.

The automated checks do not replace the separate full-game pause/save/continue,
cold process restart, and natural walk-to-port return checks.
