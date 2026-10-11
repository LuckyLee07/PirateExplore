# Warm v1 native acceptance

Date: 2026-10-11 UTC. This is a playable native adaptation, with the exact design
coverage and outstanding concept differences in [the 30-screen map](warm-v1-screen-coverage.md).

## Verified

- Original Cocos2d-x/Lua Linux build completed. Actual desktop play at 480×800,
  540×900, and the shorter 480×720 aspect. Departure main action, back, food
  decrement/increment, crew selection and collection actions remain accessible.
- Two isolated fresh game profiles were used, never an existing player save.
  First voyage: selected one actual crew and 20 food; followed original fog map;
  resolved rescue for 3 food and 2 iron; walked home. Original first-return
  resources were received. Existing travel costs, fog and rescue rules remained.
- A voyage already active before the memorial feature returned without a
  retrospective memorial field. A new eligible voyage earned exactly one
  `wreck_chart_fragment` and one genuine return record.
- Collection preview cancellation left display unselected. Explicit confirmation
  placed the owned chart on the home pedestal. Cold process restart restored it.
- Built forge through the original route for 25 gold, 15 stone and 2 iron. Cargo
  preview showed the original 5 wood / 5 cloth recipe; cancellation did not craft.
  Confirmation upgraded 20 to 30 once. Cold restart restored 30 and the home crate.
- Voyage detail showed its actual 25-gold change and returned 2 iron / 10 food;
  reviewing it did not grant anything again.
- Pause/checkpoint was exercised on the actual third voyage at map 1, tile
  10,9 with 8 food. Original return quote cancellation preserved the voyage.
  Cold restart presented the continue-last-voyage notice; decoded selected state
  matched before restart exactly (including voyage 3, position and food). Continue
  stayed in the same scene and normal harbor return produced one result summary.
- The native completed-return summary showed true committed amounts; dismissal
  did not award again. Actual pending-scene timing uncovered and fixed a resume
  notice attached to the outgoing scene; a real Director transition regression
  now prevents that regression. Final quoted-return confirmation also exposed
  reentrant removal of a dialog owner token during onExit; that token is now
  cleared before closing its sheet. The same actual confirmation path was
  repeated successfully with the durable result and no native/Lua error.
- Sound setting persisted through cold restart. Native crew, inventory, ship,
  collection, log, settings, preparation and contextual navigation were opened.
- Full legacy aggregate passed with `WARM_PIRATE_V1=false`; final warm runner
  passed eleven module parses and all 20 suites (eight logic, twelve real Cocos/EGL).
  Font glyph coverage and `git diff --check` passed.

The component tests additionally cover stale callbacks, modal owner removal,
repeat/cancel, save failures and atomic rollback/retry, long crew lists, cargo-log
pagination, malformed/future record preservation, and original talent/achievement
cascade parity during upgrades. These are isolated fixtures, not claims of a
full manual endgame playthrough. The running-dialog fixture retains nodes for
stale-callback assertions and does not independently reproduce the original
desktop teardown assertion; the actual before/after UI run is that fix’s crash
evidence.

## Limits

Mac/iOS/Android builds and touch devices are not verified. Linux cloud audio
reports FMOD device initialization errors, so audible playback is not accepted;
settings persistence is verified. Multiplayer, account-backed rankings/payments,
all combat classes, every progression chapter and device safe-area insets have
not been end-to-end exercised. Existing legacy gameplay is preserved; consult the
coverage map before describing any optional concept as implemented.

## Run safely from source

Build using the repository's existing Linux dependencies and `./linux.sh build`.
Use an explicitly separate profile:

```sh
PIRATE_SAVE_DIR="$PWD/build/warm-v1-preview" ./linux.sh run 480 800
```

This does not migrate or overwrite another save directory. Width/height may be
changed to `540 900` or `480 720`. Warm presentation is the default; embedding/test
callers may set Lua global `WARM_PIRATE_V1=false` before loading views to retain the
previous presentation. Original A/B/C branches are unchanged.
