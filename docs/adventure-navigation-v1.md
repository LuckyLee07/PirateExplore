# Known-route navigation v1

## Integration (no movement ownership)

Require `LuaClass/AdventureNavigation` as `Navigation`, and `LuaClass/AdventureNavigationView` as `NavigationView`.

After map, player and fog are ready, and after a successful move has assigned `playerTitlePosition` and cleared fog:

```lua
NavigationView.refresh(self, Navigation.query(self, {breadCoefficient = breadCoefficient}))
```

Pass Explore's local live `breadCoefficient`, not a duplicated talent lookup. Refresh after event resolution/rewards which change tiles or food, too. No scheduled movement, queued commands or persistent route state exists. In the existing out-of-map guard, show `Navigation.boundaryMessage` and return as before; do not charge food or move the ship.

`query` returns `status` (`ok`, `at_port`, `no_known_route`, `out_of_bounds`, `unavailable`). Successful queries include `path` (inclusive endpoints), `nextStep`, `direction`, `steps`, `costCalls`, `minimumFood`, `foodShortfall`, `port`. All coordinates are TMX grid positions. The endpoint is the actual `Objects/Start` tile on this map, including reloads; the stale legacy `bothPosition` field is deliberately ignored. Reaching it does not automatically return to the base.

## Navigation model

* Read live `fogManager.data` (fallback: current ExploreDataManager fog). Only `fogId == 0` is explored. Nonzero partial fog is not a valid route cell.
* Mirror Explore's block-properties check for both block layers. Active event tiles are excluded as transit cells, even when they might be interactively resolvable. The current position and port may be event endpoints; event entry does not call `costbread`. Tables without an event ID are rejected conservatively.
* Four-neighbour BFS finds the actual shortest known route. All admissible transit tiles call `costbread`, so this also minimizes movement food under the current game rules. Obstacles and unknown cells are never geometric shortcuts.
* Food estimation repeats the exact `decimal + (1 - coefficient)` arithmetic and at-most-one debit per call used in Explore, without rounding fractional talent state. Replenishing an empty bag clears accumulated debt as in Explore. Displayed food is the movement-only lower bound with supplies available. It does not model starvation as free safe travel, incidental encounters, combat, healing or optional event costs.
* Result is never labelled a safe route. If an event blocks every known way, report no known route rather than cross it automatically.

## First-voyage generation and earned clues

`Navigation.tutorialPoint(owner)` returns `point, reason`. The caller must restrict it to the authorized new-save first-chapter onboarding. It selects empty terrain 2–4 real moves from Start, preferring four, with a real out-and-back path of at most eight steps. It may inspect unknown terrain as a **generation validation**, but does not reveal fog, replace tiles, move the player or grant rewards. It returns `x`, `y`, `path`, `steps`, `minFood`, `direction` (relative to port). Never use this hidden-terrain `path` as the player's known-route overlay. Persist the chosen objective only through the progress owner. If no valid tile exists, return nil and keep progression uncommitted; do not invent a coordinate or reward.

`Navigation.gateClue(owner, {origin = 'port'})` derives one real gate from this save's live layout and actual stronghold CSV name (`传送点`). Omitting origin uses the current ship position, and the text explicitly says so. Caller gates this information behind the earned clue state. Zero or multiple gates return diagnostics instead of an invented/random bearing. The query does not prove full-map gate reachability, regenerate maps or introduce a key requirement.

## UI

The read-only strip sits above the existing bottom HUD and does not register touch handlers. The map overlay draws only returned known-route edges, labels the port and next step, and is replaced/removed whenever the result changes. Existing controls retain their hitboxes. The panel and font dimensions scale from the 640-wide design and have layout regression coverage at 480×800 and 540×900. These are mocked layout checks, not a claim of device screenshot QA.

## Tests

```sh
/workspace/shared/lua51 tools/tests/known_route_regression.lua
/workspace/shared/lua51 tools/tests/adventure_navigation_ui_regression.lua
```

Coverage: island detour vs geometric distance, unknown/partial fog, blocking events, four edges/corners, exact fractional food and zero-food shortfall, debt reset, read-only adapter, actual gate direction and ambiguous gate rejection, hidden-terrain generation without fog changes, phone-sized strip bounds and stale route-overlay disposal. Full live first/second-chapter playthrough and native screenshots remain integration acceptance work.

## Second-voyage material clue

`Navigation.supplyClue(owner)` joins actual layout IDs with `eventManger.csvData`, requires `changeToMaterialsLayer`, a positive `dropitems` entry, a fully explored event tile and a real known route to that endpoint. It prioritizes wood/iron drop IDs (`1007`/`1008`, as used in the packaged material records), then real route length. It returns `status='ok'`, `text`, `direction`, `target`, `name`, `id`, `materialId`, `steps`. A visit still requires the original occupation/collection costs, combat and cargo handling; the helper grants nothing. Missing, hidden, blocked, consumed or unreliable targets yield `status='not_found'` and an exploration prompt, with no target coordinates. Unit tests cover known iron vs hidden wood, unknown/partial fog nondisclosure, missing drops, blocking and consumed event cells.
