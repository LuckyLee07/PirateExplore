# Event scene identity: first visual gate

This is a presentation-only candidate based on `8ddf95894d14760fee5bdf385ad9d49f18a9ad54`.
It is a three-category visual gate, not a completed ten-family rollout.

## Decoded source audit

Read the original packaged `strongholdAttribute.csv` through the existing read-only XOR/LZSS decoder. There are 345 records: one initial point without dispatch, plus 344 dispatched records across ten families:

- 282 enemy strongholds (`changeToEnemyLayer`)
- 9 material strongholds (`changeToMaterialsLayer`)
- 1 supply point, 3053 (`changeToSupplyPoint`)
- 16 taverns (`changeToPubLayer`)
- 16 black markets (`changeToBlackMarket`)
- 1 resurrection site, 3003 (`changeToResurrectionLayer`)
- 1 next-region gate, 3052 (`changeToNextMapEnter`)
- 1 world chart / teleport picker, 3002 (`changeToTeleportLayer`)
- 16 arenas (`changeToArenaLayer`)
- 1 eternal arena, 3074 (`changeToEternalArena`)

World-map selection and teleport are the same original dispatch family. Site 3052 is the separate guarded next-map transition. Shared GID 48 is NOT a semantic identity: it is both the open supply point and numerous occupied enemy sites. The new resolver requires exact ID plus expected dispatch family, then applies occupied state.

## First-gate identities

- 3108, 巨浪: original prose says a skeleton boards the player's deck. Its only original enemy is 10001, 骷髅兵. At entry the scene uses that exact identity, with no prepared HP or attack. After original fighter preparation, the body is selected by the prepared `soilderId`; stats remain the existing prepared HP/power labels. Occupied state clears the enemy and retains the deck. Neither queue preparation nor reward RNG is invoked by presentation.
- 3004, 酒馆: original `Carryitems` is `1_144_300`. The compact summary is the actual 144 探险者 and 300 金币. The scene is a small floating tavern matching the original sea-tavern meaning. It does not depict a fabricated recruit, own a crew member, or spend currency. Original full prose is retained.
- 3053, 补给点: original site is a food resupply. The displayed quantity comes from the same current `ExploreBagController.breads` records used by the original collection path; native fixtures show actual resource name 食物 × 7. The two loaves in the illustrative prop are not a quantity indicator.
- Existing approved exact resource art is reused for 3067 stone, 3068 iron and 3070 timber. Original site prose, ownership state and occupy/supply actions remain authoritative.

All other IDs and families retain their prior layout and asset mapping pending visual review. No map renderer, tile, collision, economy, save, original transaction, or EventBaseView code changed.

## Composition and lifecycle

A contextual scene takes available short-content space. Long prose is measured with real LabelTTF bounds and given a larger native clipped ScrollView. Original title, kind, state, rank, prose, prepared enemy stats, costs and any extra tips remain readable. The original primary and Leave SDButtons keep their listeners, callbacks, measured targets, generation/cooldown guards and alive/blocked behavior. Existing event shield and cleanup are unchanged.

Full-page background, header, scene sea/deck, actors and button faces have explicit z depths. This is required because the bundled `Node::visit` resets arrival order, and later non-stable equal-z sorts can repaint a background over text. The native pixel suite inserts and removes 28 empty children into each of the live event root, scene root, button controller and both buttons, then requires exact unchanged rendered pixels.

Reusing a reviewed scene for an unreviewed event restores the original full body viewport. All generated masters are preserved byte-for-byte with real alpha. Original assets were not overwritten. Exact prompts and SHA-256/alpha/dimensions are in the adjacent prompt JSON and `Images/UI/CleanVoyage/Events/provenance-v1.json`.

## Verification and evidence

Persistent evidence directory: `/workspace/shared/pirate-audit/event-scene-identity`.

- Real native Cocos/EGL pixels at 480×800, 640×960 and 720×1280: entry battle/tavern/supply/resource, prepared battle, occupied battle, long supply prose before/after actual native drag, and fallback reuse.
- 54 exact dynamic-child pixel comparisons across those 27 states.
- Existing 344-record × 2-state × 5-size regression still covers original routes, gates, costs, occupations, child recruitment/revival/market transactions, return/cleanup, battle/reward handoff and repeated/dragged/stale input.
- Existing 75-assertion GLView event-shield input suite plus original always-true shield counterfactual.
- Existing nine-resource occupied-copy regression, reef identity/rank/history checks, Lua parsing and `git diff --check`.
- No shared font modification. All added visible text uses glyphs already present in the shipped CleanVoyageSans font.

Run from the worktree:

```sh
source ../linux-runtime/env.sh
PIRATE_BUILD_DIR=../PirateExplore-coherent/build/linux python3 tools/tests/coherent_event_scene_render.py
EGL_PLATFORM=surfaceless MESA_SHADER_CACHE_DISABLE=true ../PirateExplore-coherent/build/linux/tests/tutorial-log-native tools/tests/coherent_event_pages_native.lua
PIRATE_BUILD_DIR=../PirateExplore-coherent/build/linux python3 tools/tests/coherent_event_shield_native.py
python3 tools/tests/occupied_event_copy_regression.py /workspace/shared/lua51
```

These are surfaceless real-render and in-memory controller fixtures. They do not claim desktop GUI acceptance, mobile validation, natural gameplay progression, or completion of the remaining families. The parent and independent reviewer own the next visual gate.
