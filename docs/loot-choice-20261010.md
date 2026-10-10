# Capacity-safe, understandable loot choices

Status: source implementation and callback regression passed; native acceptance pending. This is the second small iteration after the preserved first-round checkpoint `c9daa074`.

## Before evidence

The original `FightRewardScene:pickUpAllRewards` partial-pickup branch in `FightMode.lua` used `ceil(remaining/cubage)`. The read-only baseline script `/tmp/pirate-loot-overflow-proof.lua` decoded the shipped CSV and executed the original production method and list helper. With capacity 20, 19 food aboard and 2 units dropped:

| Actual resource | Unit volume | Original result | Correct result |
| --- | ---: | ---: | ---: |
| 1012 暗钢 | 2 | 21/20, one taken | 19/20, none fit |
| 1022 秘银 | 2 | 21/20, one taken | 19/20, none fit |
| 1076 恒金锭 | 2 | 21/20, one taken | 19/20, none fit |
| 1039 攻城冲车 | 5 | 24/20, one taken | 19/20, none fit |

This is an actual-code/real-CSV controlled reproduction, **not natural-play evidence**. The first native natural voyage separately proved the unlabeled food-for-iron exchange existed; see [the natural replay report](growth-loop-natural-play-20261010.md).

## Minimal implementation

- Use `floor` for the number of complete units that fit. If zero fit, keep both lists and capacity unchanged and give the existing toast route an actionable instruction.
- Guard stale row taps and late input after closing. No item is automatically discarded, prioritized or swapped.
- Keep all original prices, volumes, capacity, close behavior, task-item blocking and zero-volume pickup rules.
- Add two contextual text lines above the ragged paper edge. Following a rejected native capture, logical y centers are 184 and 156; each line is uniformly fitted to at most 26 px high and viewport width minus 32. The list lower edges move from 150 to 200 and their heights decrease by 50, preserving the original list tops and first rows. Action centers/hitboxes stay y=60 and 176×61. The dedicated hint strip adds no panel or input-consuming element.
- Full hold: “货舱已满：点左侧腾位，点右侧拾取” / “关闭后，右侧物品将被丢弃”. Ordinary loot: “点左侧移出，点右侧拾取”. After moving food: state the actual food remaining, remind the player to retain return supplies, and retain the right-column/close consequence. Zero food is additionally colored as a warning. Empty loot simplifies the message.

The hint explains that moving cargo out is reversible while this screen is open. It deliberately does **not** say to use “全部拾取” after freeing space: that unchanged function can reload food moved into the right column.

## Regression

Run from repository root:

```
$LUA tools/tests/loot_capacity_regression.lua
```

The test loads the production `FightRewardScene` and list helper, decodes the actual packaged resource table, and executes the real row, bulk-pickup and close callbacks with strict node fixtures. Covered:

- Real volumes 1, 2 and 5 with remaining space 0, 1, 2 and 5; small total capacities 0, 1, 2 and 5; quantity conservation and repeated pickup.
- No automatic food discard. Zero-volume gold first in the list is collected once at full capacity. A separately staged blocked-positive-volume-first order verifies that bulk pickup still stops there and leaves later gold alone; clicking that specific gold row still works. No arbitrary-order scan or priority change is claimed.
- Full 20-food hold → move 3 food → take 3 iron → reverse part of that exchange; only intentional closing persists the chosen left column.
- Important task prop blocks closing until picked up; reserved zero-volume carried items restored unchanged.
- Last food moved out and taken back, zero-food warning, stale/empty rows, repeated close and late inputs.
- Bulk pickup still may reload moved-out food; no hidden preference was introduced.
- Original button boundaries and list tops at viewport widths 480, 540 and 640, including simulated taller CJK line metrics. The reserved 50 px strip must not intercept list input.

These tests do not replace native typography, hit-target or synthetic 2/5-volume fixture acceptance. The independent player will use an isolated controlled profile for those item volumes and a natural second voyage for ordinary food/material decisions when feasible.

No changes to gift prompts, paid long-press, alchemy, resource prices, chart travel, combat or other inventories are in this patch.


## Rejected first native layout and correction

Native screenshot `growth-play-20261010/32-fixture-cargo2-before.png` at 540 pixels showed the second hint line crossing the paper's irregular bottom edge. Its dark lower glyphs fell onto the dark action background and became unreadable; source bounding-box tests alone had missed this texture boundary. The same controlled run confirmed that 19/20 cargo plus a 2-space reward no longer picks a fractional-fit unit.

The correction moves both lines fully onto paper at y=184/156 and reserves the bottom 50 px of each list view so the text cannot overlap or intercept a row. The list tops, first-row position and both original buttons remain fixed. Updated regression checks each line's lower extent is at least 143 and upper extent is below 200, with a 26 px height cap. Native 480/540 screenshots and actual final-row scrolling/tapping remain required before accepting the revised layout.

## Missing artwork found during native inspection

The actual shipped CSV has an empty `iconName` for siege ram 1039. Its name, quantity, five-space volume and recipe are intact; the CSV has not been changed. The previous direct-sprite condition skipped this row's artwork entirely in both columns, as visible in native screenshots 46/47.

Both loot columns now use the existing `ItemIcon.sprite` helper at the same (50,60) position. Correct artwork retains its exact source path, dimensions and scale. Nil/empty icon names, missing files and decode failures use the pre-existing bounded neutral paper placeholder; tests execute both actual cell-rendering callbacks for all five cases. This is safe missing-art presentation, **not dedicated siege-ram artwork**. A future identity-correct siege-ram illustration remains outstanding and has not been substituted with a different weapon.

The final narrow native recheck will verify the same placeholder before and after transferring the ram between columns, while food retains its existing artwork. No more runtime changes are planned within this bounded iteration.
