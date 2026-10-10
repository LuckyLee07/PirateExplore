# Current prepared enemy information

## Source and bounded behavior

The existing boarding prebattle screen now shows two paper-white lines: `当前敌人 · <name>` and `开战生命 <hp> · 攻击 <power>`. The source is the same single `fightFighterData` object already passed to `FightDataManager:addEnemyFighterData` in `EventLayer:getsAndSetsEnemyLayerInfoByEnemy`. Its HP and attack already include `enemy.coefficient` and the existing `math.ceil` rounding. Presentation does not read a second soldier record, call preparation twice, roll drops, instantiate a battle, change rewards, or inspect the remaining encounter queue.

`FightMode` copies this prepared object's `hp` and `power` into the current boarding enemy's `m_hp` and `m_atk`; `Fighter:reset()` starts its HP at `m_hp`. The label explicitly says **starting health**, rather than implying persistent injury, current/max health during combat, damage prediction, or a recommendation that the player's crew will win. The existing battle screen still owns live current/max HP.

The first site entry still has no enemy preparation and therefore no enemy stats. The information appears after the original occupy/enter action prepares the current opponent and before the existing fight button starts combat. Later floors show only their newly prepared current opponent. The generic site entry is not converted into a map preview.

The ship encounter path prepares both cannon data and a later boarding opponent, but starts through its separate immediate ship-battle flow without this EventLayer prebattle display. This change intentionally clears/suppresses the boarding preview in that path; it does not reveal the later opponent, mislabel per-cannon power, or add a new ship confirmation screen. The original 21008→11005 ship replacement remains untouched.

## Layout and lifecycle

The two lines use 22 px paper-white text and fit individually to viewport width minus 48. They occupy a band between the retained site context and original current-enemy prose. The context is capped at 72 px rendered height, the current-enemy prose at 60 px rendered height, and that prose moves down 24 px. Existing fight/leave button coordinates and touch targets do not change. Reset restores the description's original position and the narrative/prose scales.

Every new event refresh, preparation, hide, occupied revisit and completion clears the complete preview group. Invalid or missing names/finite stats produce no guessed preview. Existing exact-ID/exact-copy correction for reef 3106, paper-white grade plus colored marker, original narratives, history, and completed-site cleanup are preserved.

## Verification

- `python3 tools/tests/prebattle_enemy_preview_regression.py`: passed against production preparation/render callbacks with read-only decoded packaged records. Covers reef floor 1 octopus 4 HP / 1 attack, floor 2 strongman 6 / 2, coefficient 1.25 producing 8 / 3, exact single preparation lookup and original reward RNG count, repeated pure redraw, long-name/large-number and wrapped-text bands at 480×800 and 540×900, invalid-data suppression, hide/completion/occupied/noncombat reuse, and ship replacement/suppression. Both encrypted CSV files remain byte-identical.
- `python3 tools/tests/occupied_event_copy_regression.py`: passed, including existing reef correction, ranks, both enemy preparations, all nine materials, occupied cleanup and history preservation.
- Lua parse and `git diff --check`: passed.
- Aggregate attempt in the concurrent integration worktree stopped in the unrelated Home subscription assertion (expected 11, got 14). This is not a full aggregate pass; the integration owner must rerun after the parallel Home changes/tests settle.
- Native visual acceptance is pending the single GUI owner's run. Source geometry and mocked measurements do not establish actual Chinese font readability.

## Native acceptance handoff

External fixture `linux-runtime/growth-play-20261010/round4-enemy-preview-fixture.lua` uses the real `initDataController`, `FightDataManager`, `WoWUtils` and `cleanUpController` lifecycle. It requires a separately named disposable fixture profile; it does not start/fabricate a battle or touch the natural save. Modes: `event-entry`, `event-floor1`, `event-floor2`, `event-coefficient`, `event-enemy-long`, `event-reuse`, and `event-occupied` (existing rank stress modes also remain). Long-enemy mode is explicitly synthetic presentation data. Inspect both native viewport sizes for narrative/name/stats/prose separation, readable paper text, intact buttons, and no preview remnants after completion. Preserve natural progression evidence separately from these controlled displays.
