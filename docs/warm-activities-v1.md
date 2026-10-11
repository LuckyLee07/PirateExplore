# Warm Q v1 activity pages

`LuaClass/WarmActivities.lua` provides `open(kind, owner)` for `crew`, `ship`,
`collection`, and `log`. It is used only by the Warm Q home. It does not change
legacy Home, Dispatch behavior, economy, exploration, fog, or save schemas.

## Data and deliberate boundaries

- Crew pages use the owned profession counts, the current selection, and (during
  an active sea state) actual battle-party counts. Names, portraits, base stats,
  and skills come from the shipped soldier/skill/buff tables. A selection is a
  subset of stock, not additional owned crew. No named recruit or skill is added.
- The ship page reads actual capacity, cabin size, ship identity and ship HP.
  Upgrade suggestions are exactly `HarborGoals.list`; the eventual build or make
  page still owns material validation and spending. `材料来源` opens the existing
  `HarborGoals.sources` read-only advice. Market, gathering and alchemy actions
  re-check the live shortage, real listing and original unlocks before entering
  existing pages; market routing retains the actual resource focus. The warm ship illustration is
  scene decoration; it does not promise an unlocked vessel or cosmetic change.
- Collection is explicitly **current inventory**, with stock and aboard amounts
  separated in item detail. It is not a permanent discovery index. Consumed items
  disappear, and no treasure lore, cosmetic placement, unlock, or purchase is
  invented. Every positive held item remains reachable through pagination.
- The log displays only persisted `AdventureProgress` milestones and clearly
  distinguishes pending sea results from completed returns. It does not create a
  new chronological history. Old saves get an honest missing-ledger explanation.
  `航线与港务线索` exposes the complete `AdventureProgress.getHarborStatus`
  advice, including remaining reward prerequisites and next-voyage guidance.
  Native font measurements split long Unicode text into complete bounded pages
  without dropping characters. Existing achievement records retain the original
  shipyard gate and use MainMenu’s achievement utility route.
- No automatic recruitment, assignment, construction, crafting, or reward claim
  occurs when viewing any page. The zero-crew recovery path uses `CrewRecovery`
  to lead to existing alchemy, training-camp construction, or recruitment.

## Navigation and lifecycle

The activity is one full-screen, touch-swallowing child of its owner. Closing
only removes the activity, preserving all owner content. Switching activity tabs
reuses the layer. Crew and item Back first return to their list. Page controls
and detail callbacks carry a render generation, so stale taps cannot invoke
removed entries. Route callbacks re-read the live save and unlock gates.

Generic navigation prefers `MainMenu.openRoute` so original visit side effects
remain intact. Focused construction/manufacturing/market entries still retain
their requested target. Existing Dispatch routes are `gotoTrain`, `moveToExpedition`, `gotoBuild`,
`gotoMake`, `moveToRepository`, `moveToResource`, `gotoStore`, and
`gotoAchievement`. All economy-bearing actions
remain in those original pages. Cleanup unregisters every activity listener,
clears the owner's reference, and removes the legacy dispatcher's retained short
callback keys. Removing an ancestor also performs this cleanup.

Identity-specific new art can be supplied as `Images/UI/Warm/crew-{id}.png`.
`A.crewPortrait(id, width, height)` checks this optional path first and falls back
to the same profession’s existing `MasterTheme` portrait. Generic Q characters
are not assigned to unrelated professions. Resource icons use the authoritative
`iconName` field, while soldier icons use `icon`.

The layout is authored at 480 × 800 and uniformly fitted inside the current
logical visible size. The warm sea/ship are unlettered native sprites. All text,
buttons, inventory icons, and state-dependent quantities are native Cocos nodes.

## Verification

Run from the repository root:

```
build/linux/tests/lua-ui-tests tools/tests/warm_activities_regression.lua
```

The focused regression uses actual packaged CSV data and the existing mock-Cocos
harness. It covers zero writes, real profession/skill names, held versus selected
quantities, sea cargo, live removal of selected detail, complete pagination,
repeat/stale clicks, late unlock changes, prerequisite/recipe routes, wiped-crew
recovery, persisted/pending milestones, ancestor disposal, subscription cleanup,
original MainMenu route preference and achievement gates, contextual material
source focus/Back/late gates, full harbor advice/Back, and
480 × 800 / 640 × 1066 / 540 × 900 canvas bounds.

`tools/tests/warm_activities_native.lua` also runs through the existing
`tutorial-log-native` surfaceless EGL/LuaEngine harness. It has passed real Cocos
asset construction, font bounds, MenuItem detail/back/assignment actions, owner
preservation, source/brief navigation, long Unicode measured pagination,
and ancestor cleanup at logical 640 × 960/1067/1136. The initial
verification used an existing compatible harness binary against this
checkout’s current Lua and assets; it did not initialize a game or open a save.

These tests do not replace native pixel and full gameplay interaction validation. Linux native
QA is coordinated with the overall Warm Q implementation; no mobile/device
acceptance or publication is implied.
