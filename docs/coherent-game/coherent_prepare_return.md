# Coherent preparation and completed return

## Presentation changes

- Preparation now uses the same CleanVoyage sea, harbor and boat assets as Home and exploration. A compact navy header keeps Back and the live coin balance readable.
- The ship name, voyage counter, objective, roster, remaining stock, selected quantities and cargo figures remain sourced from the existing game state. The manifest uses open cream rows and separators instead of a stack of filled cards.
- The one primary departure button reads **驶向大海** when food and a companion are selected. Existing missing-food, missing-crew, full-cargo and save-failure guidance remains beside it.
- The completed-return sheet is a quiet **航程结算 / 已保存** receipt. It explicitly labels warehouse changes as net changes and explains that these include original supplies, subsidy and return consumption.
- **准备下次出航** closes the receipt before calling the existing Home primary route. Home retains recovery and unlock routing. **留在港口** is always available; **看看珍藏** appears only when the completed result actually contains a new memory.

## Boundaries retained

`Expedition` still owns loadout selection, inventory changes, food production callbacks, quantity holds, fill, validation and departure. `WarmDeparture` does not replace any of those callbacks. Its existing objective action still uses `AdventureProgress.setObjective`.

`WarmReturnResult.before`, `.complete` and `.lines` are unchanged. A result remains a single-use, post-commit snapshot. Opening, paging, closing or following a route never saves, grants, reclaims or settles anything. The presentation retains its generation, owner, disposal and already-presented guards. Old active voyages are not backfilled into history.

## Verification

Run from the repository root:

```sh
/workspace/shared/lua51 tools/tests/warm_departure_regression.lua
/workspace/shared/lua51 tools/tests/warm_return_result_regression.lua
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
MESA_SHADER_CACHE_DISABLE=true build/linux/tests/tutorial-log-native tools/tests/warm_departure_native.lua
MESA_SHADER_CACHE_DISABLE=true build/linux/tests/tutorial-log-native tools/tests/coherent_prepare_return_native.lua
```

All four passed on this checkout. The focused native test covers:

- Real Cocos nodes and packaged CleanVoyage assets/font
- Preparation at 480×800, 540×960 and 720×1280
- Live quantity changes and accurate remaining-cargo text/bar
- Receipt layout at 480×800, 640×960 and 640×1136
- Exact displayed money/diamond changes, honest warehouse heading and conditional collection route
- Long-result pagination and stale pager callbacks
- Single-use onward preparation, duplicate presentation and no write/grant calls

The existing departure native suite additionally passes 640×960, 640×1067 and 640×1136 with actual SDButton/Menu activation, long holds, production closure retention and post-departure guards. Hero height is pixel-aligned to avoid a float32 clipping-edge overshoot.

These are isolated native fixtures. They do not claim full-game visual acceptance, a player-save run, mobile acceptance or publishing.
