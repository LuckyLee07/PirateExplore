# Initial-game B adventure UI: first batch

Base: `c53323edca69591cf8c5ab0402d7c2013c1562bd`. This is the original Lua/Cocos game, not Sunlit/V2 or a browser recreation.

## Scope

- Native read-only harbor home with live preparation/capacity/crew summaries and original feature navigation.
- Native expedition preparation with existing item details, plus/minus and hold, fill, capacity limits and selection persistence.
- Live TMX chart with themed resource HUD, actual chapter/map name, directional helm, cargo and return actions, and transparent ship art.
- Reusable harbor and ship images; text, buttons, counters and map remain runtime nodes. Original terrain, fog, tile metadata, events and battle algorithms remain unchanged.
- Original seven navigation destinations remain reachable, with home added. Existing construction, recruitment, crafting, gathering, warehouse, talents and market screens have not been restyled in this batch.
- Readability backplate for transient notices. No economy tables or save format changes.

## Native acceptance

Tested in the assistant-owned Linux desktop using the compiled Cocos executable, at **540×960** and **480×800**. Resources resolve through the executable's `Resources` symlink to `bin/res`; Lua/image updates were verified by cold restart.

A separate QA profile was restored from an earlier safe-base checkpoint. It was never launched through the historical `initial.sh` wrapper. The preserved chapter-six profile's eight files were SHA-256 compared before and after and remained unchanged.

### Passed through actual GUI

1. Home opens by default and shows real selection/capacity/standby-crew data.
2. Home → preparation; empty crew prevents departure; holding food minus reaches zero and empty food prevents departure. No inventory debit occurs on either rejected path.
3. Fill respects cargo and crew capacity. Selected items survive page changes and cold restart.
4. Preparation → talents → Back restores preparation. Warehouse and construction remain reachable, and highlighted navigation tracks the page. Repeated home/preparation switches do not leave stale panels or input blockers.
5. Double-click departure enters the real map once: keys debit by three and selected crew by three exactly once, selection clears, and battle pack holds 57 food plus three keys. Food production continues in the background, so warehouse food delta alone is not treated as a transaction count; the departure log records one 57-food transfer.
6. The directional helm moves the real ship one tile and food changes 57 → 56. The HUD reflects the new cargo usage.
7. Cargo opens and dismisses. Return opens the original 15-diamond confirmation; Cancel leaves diamonds unchanged at 213 and map controls usable.
8. Movement back onto the harbor tile returns to home naturally, preserving all three crew. This was a short navigation return, **not a battle acceptance test**.
9. Both portrait sizes render home, preparation and chart without missing controls. The compact preparation list remains scrollable.
10. Cold restart while at sea restores the same chapter, position, food 57 and cargo 60/60. Updated dark-backed notices are readable over the sand-colored preparation screen.

## Reproducible checks

From repository root:

```sh
./linux.sh build
./tools/tests/run-adventure-ui-tests.sh
```

The regression runner uses `LUA_BIN`, an installed Lua, or compiles an interpreter from the already-built bundled Lua library. Tests use Cocos node stubs and therefore complement, rather than replace, the native GUI checks. Covered: read-only home, event cleanup, eight routes and unlock gates, food/crew guards, quantity/hold/fill, capacities, saved selection, empty lists, departure payload and repeat guard, HUD bounds, movement gating, saved tile coordinates and missing-art fallback. All seven changed/new Lua files parse under bundled Lua 5.1. Native CMake build completed at 100%; `git diff --check` passes.

## Limits and observations

- No full battle, chapter completion, macOS/iOS or audio acceptance was performed.
- Existing Linux audio-device/FMOD warnings and the original empty-URL time-sync warning still appear. No new Lua exception/traceback occurred during these flows.
- Original promotional modal and roaming promotion boat remain unchanged; dismissing a modal was part of QA, no purchase was made.
- Full B-style terrain, character portrait replacement, remaining feature pages and deeper combat presentation are future work.
- Publication/merge status must be checked separately. Local acceptance does not imply a remote push or merge.
