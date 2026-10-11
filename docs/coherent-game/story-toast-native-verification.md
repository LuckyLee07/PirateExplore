# Story, startup and toast native verification

Verified the coherent presentation source in the existing Cocos LuaEngine / surfaceless EGL harness. No native desktop GUI, player profile, save, network, publishing or production-code edits were used by this verification task.

## Result

`tools/tests/coherent_story_toast_native.lua` passes: **13,816 assertions, zero failures**, at **480 × 800** and **640 × 1136** logical viewports.

The test loads the actual packaged plot CSV through the repository's existing read-only Record/LZSS fixture decoder, uses actual packaged images and fonts, and runs real Cocos actions and native MenuItem activation. Director viewport/scene selection and read-only DataManager access are in-memory boundaries.

## Coverage

- All seven opening scenes: actual text, 25 px clean font, original line content, native screen bounds, 154 × 58 Next control, original artwork, and at least 8 px separation between the art and narrative label region.
- Each original opening sentence fits one measured native line at both target viewports. Narrative labels avoid the Next control.
- Natural completion, double Next activation, a subsequent scheduled natural end, full natural seven-scene sequence, and full Next-driven sequence. Scene replacement and final callbacks remain one-shot.
- Cleanup after Next cancels the pending completion callback.
- All **24 packaged story overlays**: original content/order, clean font, measured screen bounds, completion/stay callbacks once, and layer removal.
- Startup: shared clean sea/harbor/boat world, clean title font and title bounds, unchanged 240 px loading footer and loading marker construction.
- Ordinary toasts: actual 28 px CJK font measurement, immediate filling of three free slots, ten-message FIFO order, each message once, a three-card limit, at least 12 px gaps, central safe-region bounds, complete long wrapped Chinese text, and queue drain.
- Alchemy receipt: clean font and measured bounds.
- Explicit legacy opt-out: original three-part plot scene, 36 × 36 skip control, original 30 px narrative font, original startup heading font, original 38 px toast font, and repeated-skip callback guard.

## Additional checks

These existing Lua regressions also pass against the same production source:

- `tutorial_lifecycle_regression.lua`: 9 passed, 0 failed
- `toast_stack_regression.lua`: FIFO, wrapping, lifecycle suspension/replacement, stale callback invalidation and production-only quiet behavior
- `alchemy_feedback_regression.lua`: receipt accumulation/reset, separate important notices and lifecycle safety

Read-only font cmap audit of the decoded packaged plot CSV found all **496 distinct CJK characters** in `CleanVoyageSans-Regular.ttf`, with none missing.

## Issue found and rechecked

The initial presentation used five-line story positions that extended below the 480 × 800 viewport and approached the Next region at 640 × 1136. This was reported to the implementation owner. After the production layout was corrected, the final native bounds and art/text/control separation checks all passed.

## Reproduce

From the repository root:

```sh
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
./build/linux/tests/tutorial-log-native tools/tests/coherent_story_toast_native.lua
```

For the existing logic regressions, use the available Lua 5.1 runner:

```sh
LUA=/workspace/scratch/79976da795e7/PirateExplore-initial/build/linux/tests/lua-ui-tests
"$LUA" tools/tests/tutorial_lifecycle_regression.lua
"$LUA" tools/tests/toast_stack_regression.lua
"$LUA" tools/tests/alchemy_feedback_regression.lua
```

## Boundaries

These are isolated native component/action/geometry tests, not an interactive full-game pixel acceptance pass. Full Director rendering/transitions and pointer-based event dispatch are outside this harness; scene routing is observed through its fixture and native MenuItem activation is exercised directly. The retained original narrative images are checked as framed vignettes, not claimed as newly redrawn assets. Existing toast lifecycle regressions were run in their Lua-fixture mode; the new toast typography/wrapping/queue checks use actual native Cocos objects.
