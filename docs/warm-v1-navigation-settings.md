# Warm v1 navigation and settings

## Scope

This isolated warm branch uses `WarmTheme.enabled()` (default on; explicit
`WARM_PIRATE_V1=false` opts out) to select `WarmHomeLayer`. The original Home,
route constructors, ship movement, fog, food, combat and cargo logic remain
available. The separately documented memorial extension adds versioned fields
without replacing existing save fields or economy rules.

- Warm Home supplies its own header and activities. MainMenu's legacy header,
  currency chips, four groups and moving gift decoration are hidden there.
- Native business routes keep their original unlock checks and guide side
  effects. The hidden original guide targets remain alive. The global footer
  becomes one `返回船上` action; pages already supplying a complete footer back
  action, such as Talent, do not get a second overlapping return button.
- Warm utility back actions return to the ship. Reentering an already-active
  Home refreshes it without constructing a new page. Route replacement guards
  against nil/same-view replacement and retains the native old view while its
  destruction hooks run.
- Settings opens an owner-bound native modal above the whole dispatch. It
  does not replace or reconstruct the current route. Done or the route's back
  handler closes only the sheet; route, owner, and scene removal clean up its
  scene-owned layer and touch listener. Repeated open/close is idempotent.
- Settings uses the existing sound/music/effect setters, each of which invokes
  the existing role save. Music also pauses/resumes/starts through AudioEngine.
  `战斗特效 / 下场战斗生效` reflects FightMode's real initialization behavior.
- Help describes current food consumption/risk, cargo occupancy, fog revelation,
  and supply/return planning. It does not claim free rescue, no food, automatic
  save success, a title screen, large-text support, reduced-motion support,
  restart or abandonment mechanics.

The native settings panel follows the cream/card/coral direction of board 08.
Board 10 now has an adapted sailing pause, checkpoint and restored-voyage
notice, documented in [pause/checkpoints](warm-v1-pause-checkpoints.md). It
reuses original quoted return, not a new free-abandon economy.

## Automated evidence

From the repository root, with a Lua 5.1 binary:

```sh
$LUA tools/tests/warm_navigation_settings_regression.lua
$LUA tools/tests/onboarding_navigation_regression.lua
$LUA tools/tests/tutorial_lifecycle_regression.lua
$LUA tools/tests/auxiliary_ui_regression.lua
```

The focused warm test first runs the existing complete Master Home fixture,
then checks mode-on/default and explicit opt-out, original dock gates, hidden
legacy targets, native business returns, exact-page settings restoration,
persisted toggles, audio callbacks, duplicate open, repeated close, owner and
Dispatch cleanup, and no incidental preference/game-state writes.

`tools/tests/warm_settings_native.lua` also runs in the existing
`tutorial-log-native` Cocos/EGL LuaEngine harness. It uses real production
WarmTheme/MasterTheme labels and buttons, real native MenuItem activation,
real cleanup, and in-memory settings values instead of a player save. It passes
at 640×960, 640×1067 and 640×1136: native label bounds, all six toggle state
changes, Done, duplicate-open protection, owner removal, scene teardown, and
idempotent close. No live save or map is opened.

## Native visual acceptance

These checks prove native construction and lifecycle, not final image fidelity.
The completed desktop observations are recorded in
[warm-v1-native-acceptance.md](warm-v1-native-acceptance.md).
Use the isolated native warm game profile to inspect Home → settings → Done,
Home → each unlocked business route → ship, and Home → Talent → back. Confirm
no click-through from settings and no duplicate footer/header at the target
screen sizes. Continue verifying actual exploration in the parent warm-v1
acceptance run; no map/fog runtime code is part of these changes.
