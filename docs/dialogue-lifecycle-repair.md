# DialogueView scene ownership repair

## Confirmed failure

The native 540px QA run encountered `Child must be non-nil` when defeat's
“变强” action attempted to open PushGiftView. Fast fixture-driven transitions
and a delayed Home offer exposed the problem; that sequence does not establish
how often ordinary play encounters it.

The smaller reproducer needs neither combat nor saved data: show DialogueView
in scene A, clean up and destroy A, then show another DialogueView in scene B.
The former global manager still counted A's view and held A's destroyed native
mask. Its non-nil Lua wrapper reached `reorderChild`. Running the old production
source against real Cocos nodes reproduced the same assertion and process crash.

## Repair

- Each scene owns its modal registrations and backdrop; a paused scene retains
  its stack independently of a pushed scene.
- Dedicated native child nodes observe cleanup without replacing a subclass's
  existing script handler. Scene cleanup invalidates its registrations before
  native nodes are destroyed.
- Repeated show/close and duplicate late callbacks are idempotent. A close
  callback captures its original registration and cannot affect a reopened
  view or another scene's mask.
- Bulk dismissal snapshots its current-scene views before removing them.
- Content-only `removeAllChildren` preserves the private lifecycle observer.
  This keeps the existing Lackmaterial partial-purchase `reflush` registered
  while it replaces its UI children, so the rebuilt close button still works.
- The original tint, scale animation timings, touch swallowing, view callbacks,
  and gameplay data remain unchanged. Empty masks are removed after explicit
  close/bulk dismissal. An external node-removal callback only hides its empty
  mask until reuse or scene cleanup, avoiding sibling-vector mutation inside
  native lifecycle iteration; that mask has no input listener.

## Checks

`tools/tests/dialogue_lifecycle_regression.lua` executes the actual module with
strict native-order lifecycle fixtures: seven cases failed against the original
source; all eight current cases pass after repair. Cases cover replace/destruction,
push/re-entry, cross-scene delayed close, duplicate show/close, pending-close
bulk dismissal, stale callback after reopen, external removal, subclass
handlers, safe native cleanup iteration, and the actual Lackmaterial reflush.
Independent review caught the content-rebuild regression in the first repair;
the additional case prevents its return.

The optional `tools/tests/dialogue_lifecycle_native.lua` uses the already-built
headless Cocos/EGL harness from the chart lifecycle tests:

```sh
build/linux/tests/lua-ui-tests tools/tests/dialogue_lifecycle_regression.lua
build/linux/tests/chart-lifecycle-native tools/tests/dialogue_lifecycle_native.lua
```

Set `LD_LIBRARY_PATH` as for the Linux runtime and `MESA_SHADER_CACHE_DISABLE=true`
when needed. This second script uses real Cocos scenes, nodes, script handlers,
actions, and destruction. Its scene-selection accessor is supplied locally;
it is not full Director scene-stack or GUI acceptance. Its four relevant
PASS lines establish the bounded check; the reusable harness's trailing chart
summary does not mean this script also reran chart cases. No player save,
window, network, or billing service is used. The real Lackmaterial UI builds two
material rows, invokes native MenuItem activation on the first purchase,
rebuilds the remaining row, and activates its rebuilt close button. Only the
economy, guide and toast boundaries use in-memory fixtures; the expected single
coin/item mutation is asserted. `PIRATE_DIALOGUE_SOURCE` optionally
selects a baseline source file for reproducing the old failure.

The existing aggregate suite also passed after the change (171 PASS lines).
Cold native GUI verification remains separate: repeat nested material dialogs,
the rapid Home/sea/fight sequence, defeat → “变强” → close → return, and verify
the returned scene remains interactive with its own modal count.
