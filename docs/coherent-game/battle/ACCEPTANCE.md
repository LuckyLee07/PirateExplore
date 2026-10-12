# Clean battle stage component checkpoint

This document records the historical stage-only checkpoint. The subsequent
four-identity standing-body tranche and its separate acceptance gates are
documented in `../boarding-actors/ACCEPTANCE.md`; the legacy-art limitations
below still apply to identities outside that bounded mapping.

Base: reviewed page checkpoint `169a4242c641fd4e14c76c4e74867d60d774df2f`.
This is an isolated local presentation tranche. No publication, application
window manipulation, existing player profile write, economy/save/map rewrite,
or Mac/mobile acceptance is included.

## Implemented

- The accepted clean honey/cream/blue-trim boarding and broadside decks, with
  the accepted full graphite-blue cannon. Original PNG bytes are preserved.
  Rear guns sample the accepted full cannon's top; rejected short art is absent.
- Original logical deck sizes (640×569 and 640×423) and cannon sizes (101×185
  and 101×73). Art normalization lives in a child, separate from recoil scale.
  Enemy reflection is on that visual child. Whole-stage width normalization
  keeps guns, damage anchors and bombing nodes in one logical coordinate space.
- One cream encounter header, original description/name/rank and enemy HP;
  compact distinct player team HP; only the actually embarked 1–6 crew cards,
  with exact original icon, name, skill, cooldown and mode-dependent individual HP.
- Food is the teal primary action with live stock and a bounded gold cooldown.
  The smaller cream instant action clearly displays its unchanged 5-diamond cost.
  Both are the original MenuItems with their original callback functions.
- The exact CSV enemy portrait is bounded to a 160-pixel logical box. The
  presentation pulse is 1.12× rather than 3×, keeping its original 0.2-second
  duration and reset. Ambient fade retains its original 1/1/1-second sequence,
  with the modern range changed to 82–100% opacity. Legacy opt-out is unchanged.

## Evidence and verification

`coherent_battle_stage_native.lua` uses production battle constructors and
native Cocos actions with isolated in-memory team/inventory data. Both exact
actor texture identity and bounded enemy/crew pulse reset are checked. At 480×800,
540×900, 640×960, 640×1067 and 720×1280 it checks 1/6 boarding crew, 1/6/10 guns,
visible text bounds, exact aggregate versus individual HP, manual/auto input,
food depletion/heal/cooldown, shortage and exact-once 5-diamond callbacks,
bounded attack/reset timing, both real animated cannon flames and muzzle
attachment. Separate frames exercise curtain time 0, .15, .6 and after 1.6 s;
the original callback runs once at its original time.

`coherent_battle_stage_regression.lua` pins byte checksums of 71 unchanged
complete function blocks plus the exact manual, food and paid callback bodies.
It protects combat damage, outcomes, saves, transitions, chest/reward code and
all pre-existing shared CombatTheme helpers from incidental rewriting.

`coherent_battle_stage_render.py` builds the existing shared surfaceless
Cocos/EGL renderer against a compatible Linux build and runs the native fixture.
It renders real textures/fonts and production nodes, and dispatches real GLView
touches through native Menu hit testing for food, paid and manual controls.
A counterfactual restoring the old 3× pulse must fail native action sampling. It does not open a desktop
window or replace actual-window gameplay acceptance.

Commands (SDK/build location is environment-specific):

```sh
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
export PIRATE_BUILD_DIR=/workspace/scratch/79976da795e7/PirateExplore-shutdown-fix/build/linux
export LUA_BIN=$PIRATE_BUILD_DIR/tests/lua-ui-tests
export WARM_NATIVE_BIN=$PIRATE_BUILD_DIR/tests/tutorial-log-native
$LUA_BIN tools/tests/coherent_battle_stage_regression.lua
$WARM_NATIVE_BIN tools/tests/coherent_battle_stage_native.lua
python3 tools/tests/coherent_battle_stage_render.py
./tools/tests/run-coherent-game-tests.sh
```

Latest final-source results: the full coherent-game aggregate passed, including
Warm, focused native, legacy opt-out, clean map and font suites. 1,698 battle
native assertions passed; 71 complete unchanged
methods and both normalized effect bodies passed source conservation. The
old 3× pulse counterfactual was rejected by the actual native action.

## Open acceptance gates

- Actual-window play and route transitions on the independently controlled
  disposable profile are pending. No desktop pass is inferred from these tests.
- This does **not** finish the naturally scaled full-body actor requirement.
  Enemy and crew art remains the exact old identity art. Ghost portraits can
  still look faint/tiny because transparency is embedded in their old texture;
  shrinking the old portrait is not a new standing actor. The semantic actor
  inventory covers 323 records / 42 texture aliases, not 42 equivalent identities.
- Existing effect textures and the moving white entry curtain remain original.
  The transient curtain must be judged at its documented times, separately from
  persistent HP/UI. Particle, buff and complete natural encounter route pixel
  acceptance remain part of desktop review.
- At compact widths, crew controls are intentionally compact. Native typography
  bounds pass, but text size, portrait readability and the occupied deck's final
  composition still require independent pixel review. All-in-one HP and
  one-by-one individual HP are different data; neither team HP is discarded.
- There is no claim of changed art for every profession, boss, later map, or
  completed whole-game visual coherence from this stage tranche.
