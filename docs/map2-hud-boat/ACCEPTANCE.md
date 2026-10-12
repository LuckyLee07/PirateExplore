# Map 2 compact HUD and actor follow-up

Base: `6106b2b579712438681ed05ecd594c8cd3f135ee`.
This is a runtime-only presentation delta. `RAISED_MAP2_LIVE` remains default off.
Neither the tested core nor the original TMX, native controller, source fog,
camera transforms, event IDs, economy, collision, movement, saves or assets change.

## What changes

- Shared WarmTheme panels/buttons/fonts replace the stacked legacy HUD in this
  one opt-in view. Food, cargo and pause remain visible; chapter/map/exploration
  sit in one small status line. One compact context panel retains useful return
  direction, steps and minimum sailing food. Low food and route food shortfalls
  take priority. Full objective, patrol caveats and route limitations remain in
  the chart sheet. Cargo, chart, existing journal and original return are reachable.
- Four shafted indicators are authored in the native projected directions:
  up → NE, left → NW, right → SE, down → SW. They activate the original controls.
- The existing four clean-voyage ship images attach beneath the real native
  actor through an inverse presentation projection. Native actions remain the
  sole motion authority; there is no second actor or independently animated path.
  Opacity/color reflect original visual state. Native source-art actions retain
  original artwork for their action lifetime, then clean artwork returns.
- The old coast-effect FBO sampling gutter is clipped at exact TMX boundaries.
  Only the decorative edge sprite is wrapped; the source decorative group stays
  in its original map position, order and ownership. Native fog is not replaced.
  A child of the existing chart background matches outside-map ink to opaque fog.
- HUD visibility and the old objective hit strip have bounded presentation
  leases. Other owners/maps continue using the original hit test. Last unmount
  restores the exact installed original function; stale callbacks cannot act.
- New HUD buttons use owner-local accepted-BEGIN gesture generations. Synchronous
  hide/show, actual modal attachment and owner exit cancel held gestures, even if
  reopening happens before a scheduler tick. The original native controls remain
  unchanged. Only new HUD native menus are touch-disabled; local listeners retain
  the shared item visuals/actions and enforce cancellation before activation.
  Owner-local method leases preserve arguments/returns and restore only their own
  wrappers, leaving newer decorators intact.

## Native verification

Run from this worktree after sourcing `linux-runtime/env.sh`. The dedicated
fixture uses the reviewed Cocos/EGL map runner with only an added test-only
Begin/Move/End/Cancel dispatcher API. Production engine source is unchanged.

Build recipe:

```
PIRATE_BUILD_DIR=/path/to/shutdown-fix/build/linux \
CLEAN_WORLD_BUILD_DIR=/path/to/clean-world-native \
RAISED_MAP2_LIVE_BUILD_DIR=/new/output \
python3 tools/tests/build_raised_map2_live_native.py
```

Run `raised_map2_live_native.lua` (ordinary baseline with `LIVE_BASELINE_ONLY=1`),
`raised_map2_live_objects_native.lua` at `OBJECT_WIDTH=480` and `360`, and
`raised_map2_hud_boat_native.lua` at `HUD_WIDTH=480 HUD_HEIGHT=800` and
`HUD_WIDTH=360 HUD_HEIGHT=640`. Set `RAISED_MAP2_LIVE_CAPTURE_DIR` independently
for each run, `LIVE_FULL_THEME=1` and `MESA_SHADER_CACHE_DISABLE=true`.

The dedicated test covers every projected heading through actual native input,
per-step food and continuous actor attachment; cancellation, drag-away, rapid
input, held-modal and busy transitions; synced/no-sync hide/show, event, actual
pause/dialog/journal roundtrips, detach/reentry and fresh tap recovery; actual pause/chart/journal; delegation
to original cargo/return actions; warning/visibility; source-art opacity,
rotation, anchor, Show/Hide and action-time toggles; native actor replacement;
second-owner/nested/stale lifecycle; decorated method overload/return
conservation and non-overwriting teardown; boundary-camera fringe counterfactual;
six active/paused GL context recoveries; exact save/model neutrality and cleanup.

`verify_raised_map2_hud_boat.py --evidence <folder>` checks native image/context
parity, original partial/unknown fog pixels, outside-map counterfactual, bounded
listener/VBO counts, all protected existing files against the exact base, and
the test-only C++ delta. A strict log gate rejects native/Lua errors even when
the harness subsequently prints a success marker. Separate existing controller/object, conservation,
mutation-counterfactual, legacy and clean-first-map regressions are rerun.

## Explicit limits

This is seeded Linux native evidence, not natural progression, mobile-device
acceptance or GUI approval. The focused cargo/return probes verify delegation,
not their full application contents. Actual isolated desktop source/pixels,
full event/return flows and final user approval remain required. No publication,
upload, production activation or real payment was performed.
