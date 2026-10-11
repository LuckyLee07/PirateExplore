# New-profile chapter-one layout

`CleanFirstMap.mapPath(dm, index)` selects `map_1_clean_v1.tmx` only when
`index == 1` and the persisted role field `cleanFirstMapVersion` is numeric `1`.
The marker is committed atomically by `AdventureProgress.initializeNewRole`,
which is called only from DataManager's confirmed empty-role branch.

Missing or unknown markers retain the original chapter-one map. An existing
AdventureProgress v1 ledger, missing map data, incomplete guide, or saved sea
position does not opt a role in. Other chapters always use their original maps.
No old-save migration is introduced.

## Gameplay coordinates

All positions below are TMX cells, with y increasing southward. Start and port
3001 both occupy navigable cell `(7,11)`. The other fixed events remain revival
3003 at `(10,7)`, iron 3068 at `(12,8)`, and portal 3002 at `(13,10)`.
The iron coordinate retains all existing hardcoded production behavior.

The harbor mainland consists of these 50 connected cells:

| Row y | Inclusive x range |
| --- | --- |
| 12 | 5–7 |
| 13–15 | 4–7 |
| 16 | 5–7 |
| 17 | 4–8 |
| 18 | 3–9 |
| 19 | 2–10 |
| 20 | 1–11 |

`CleanFirstMap.harborLandTiles()` returns fresh copies of this footprint. It
joins the lower map boundary. The former north-west coast also extends through
`x=5–6, y=7–8`, leaving the three water rows `y=9–11` open before the harbor.
The map has 122 blocked cells and 319 cardinal-connected navigable cells.

## Artwork and collision agreement

The approved harbor illustration is placed at 470 logical pixels wide, with
its lower-left position offset `(-412,-383)` from the projected port. The land
footprint uses the conservative coast/walkway center-grid mask union with the
initial 15-cell harbor, rather than treating roofs and palms as land:

```text
px = 340 + ((x - 7) - (y - 11)) * 67
py = 468 - ((x - 7) + (y - 11)) * 37
coast: px < 68 and py < 362
walkway: 28 <= px <= 368 and abs(py - (px * 0.57 + 280.19)) < 35
```

The port is explicitly excluded from collision land. This is a conservative
mask, not a claim that every opaque ground pixel is within the footprint.
The renderer must clip harbor artwork to discovered cells intersected with
actual blocked cells plus the port. This prevents the remaining illustration
overhang from painting false ground on navigable water, including `(8,11)`.

## Event preservation

The four fixed event GIDs and identities are retained exactly. Random event
identities, counts, rewards, and rules still come from the unchanged original
stronghold CSVs, including quarry 3067 and wood 3070. All 79 candidate object
slots remain distinct, navigable and reachable, with unchanged category counts.

The original nearby slot `(7,11)` moves to `(8,11)` for the new port. Mainland
expansion also relocates these conflicting slots:

| Category | Before | After |
| --- | --- | --- |
| Interior | (2,19) | (2,18) |
| Interior | (5,16) | (4,16) |
| Interior | (5,18) | (3,17) |
| Interior | (8,18) | (9,17) |
| Interior | (4,17) | (3,16) |
| Interior | (7,17) | (9,16) |
| Interior | (6,19) | (1,19) |
| Perimeter | (11,20) | (12,20) |
| Perimeter | (9,20) | (13,20) |
| Perimeter | (4,20) | (0,19) |

The production AdventureNavigation code chooses the first-voyage wreck from
the resulting real map. No fixed wreck coordinate, free movement, food change,
or new reward system is added.

## Verification

Run from the repository root:

```sh
python3 tools/tests/clean_first_map_regression.py /path/to/lua5.1
```

This checks original-map bytes, unchanged tilesets and non-layout layers,
exact fixed events, the authored coast mask, all object slots, cardinal water
connectivity, encrypted new-role save/rollback/cold restore, strict legacy
fallback, and 32 production random layouts using the real packaged CSVs.
Production tutorial generation is tested both against those layouts and the
conservative case where every candidate slot is occupied. The route remains
2–4 cardinal steps outward, at most 8 steps round-trip, with original per-step
food accounting and no fog revelation.

These are data/logic regressions. Native visual acceptance separately verifies
the final artwork position, clipping, fog, movement and event flows.
