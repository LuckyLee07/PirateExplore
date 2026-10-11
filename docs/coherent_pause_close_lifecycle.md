# Shared-sheet/window-close lifecycle repair

## Defect and repair

Closing the native desktop window while the pause sheet was open crashed with
`Node still marked as running on node destruction`, followed by a segmentation
fault. The pause owner’s exit observer called `layer:close(false)` while the
scene itself was exiting.

This Cocos version marks a scene non-running *before* traversing its children.
Removing its still-running pause sibling at that moment both changes the child
list being traversed and causes `detachChild` to skip native `onExit`. Without
an artificial test retain, the pause subtree can be destroyed while still
marked running.

`WarmPause` now immediately clears ownership, removes its touch listener and
releases paused-target retains, but leaves a still-running sibling attached
when the scene is already non-running. The native scene traversal exits and
cleans up the sheet normally. Ordinary Continue and standalone owner removal
retain their existing immediate behavior. A stale retained Continue control
also checks the disposed state before accessing the destroyed layer.

The same defect was reproduced and repaired in `WarmDialog` and
`WarmSettings`. Their default `owner=scene` path has a second hazard: the
sheet's own exit handler must leave its observer sibling in the native scene
traversal. Both now separate disposal from detachment and preserve the
scene-owned observer until native teardown handles it. Retained settings
controls cannot change preferences after disposal.

Checkpoint writes, partial-write reporting, cargo, food, pending outcomes,
return pricing and the pause/resume rules are unchanged. The scrim color is
unrelated: removing only the new lifecycle guard reproduces the original
native crash with the current appearance and checkpoint code intact.

## Automated evidence

Run with the same compiler/runtime environment used by `linux.sh`:

```sh
python3 tools/tests/coherent_pause_close_regression.py
```

This builds an isolated surfaceless native harness against the existing Linux
engine libraries. It does not open the desktop GUI or any player profile.
The Lua fixture can also run in `tutorial-log-native` for replacement/close
coverage; the dedicated runner additionally checks final Director destruction
and all crash counterfactuals. `run-coherent-game-tests.sh` invokes it separately.
Coverage:

- Real running scenes with autorelease pools drained before teardown
- Unretained production-style sheets, with and without a successful checkpoint
- Owner-before-sheet and sheet-before-owner native traversal order
- Descendant exit exactly once, no orphan sheet in the replacement scene
- Frozen sailing work, immediate Continue and once-only continuation
- Standalone owner removal and harmless retained stale controls
- Dialog/settings explicit close, owner-only removal, scene replacement,
  nested/default-scene owners, both sibling orders and stale controls
- Actual `Director::end` / `purgeDirector` after Lua returns, matching the
  native window-close termination path, with five unretained sheets: saved
  pause, owner-bound dialog/settings, and default-scene dialog/settings
- Five counterfactuals: independently removing each sheet's scene-exit guard
  or either dialog/settings scene-owner observer guard produces the native
  running-node destruction assertion and exit signal 11

The pre-existing `warm_pause_native.lua`, `warm_resume_transition_native.lua`,
`warm_dialog_scene_transition_native.lua`, `warm_settings_native.lua`,
`warm_home_dialog_native.lua` and `warm_pause_regression.lua` also pass unchanged. The last one covers encrypted role cold reload, partial
map/role checkpoint failure, retry and unchanged cargo/economy/voyage state.

The old pause native fixture retained the sheet and used scenes that had never
entered. Even a real running-scene test with an extra sheet retain can mask
this specific destruction bug; production-style lifetime is essential here.

Full-game desktop X/reopen and original player-save verification are separate
reviewer checks. The isolated tests do not claim to replace those checks.
