# Construction and manufacturing pages

Branch: `codex/coherent-pages-v3`. Presentation-only changes to the ordinary
construction and manufacturing routes, using the shared coherent page shell.
The existing focused construction route remains unchanged.

## Composition

The ordinary pages now have a quiet three-row native scrolling recipe list and
one selected recipe detail below it. Rows have an original item illustration,
name, material sufficiency, and a restrained new-item marker. A flat tint marks
the selection; rows are not independent cards or repeated action buttons.

The selected detail shows each original material's current and required quantity,
with insufficient values differentiated in both the row/status wording and color.
The only primary action is in the footer. It explicitly says `查看缺少材料` when
short, and otherwise says `建设` or `制造 1 件`. Built recipes and empty/locked
states have no purchase or repeated construction action. Back remains secondary.

The selected original item illustration is still an actual `SDButton`. Its
single-click and long-press paths show the original name, description, and recipe
comment in an owner-bound information sheet. It sits outside the scrolling clip,
so its real scaled hitbox does not inherit the old oversized row touch extension.
The list itself uses native TableView cell selection and scrolling. Recipe assets
with no icon use a neutral functional icon instead of a failed image decode.

The visible shop, alchemy, scrolling system feed, star strip, pulsing button light,
and per-row transaction buttons are absent from these opted-in pages. Their
existing Home/business routes remain available. This does not disable or rewrite
those features. Original non-warm page implementations are retained.

## State and behavior conservation

- Source list identity and order are retained; presentation does not sort, filter,
  save, or manufacture an unlocked recipe.
- Building IDs, resource IDs, costs, grants, and original `useResouces` /
  `cheackResoucesOK` functions are unchanged.
- Manufacturing passes the live row's original `sortId` to the original
  `createSuccessCheck(kUnlockMake, sortId)` owner, including duplicate-resource
  recipes. Its original deduction/grant operation still grants one item.
- Construction still calls the original unlock owner after the original material
  deductions. No direct save, economy, or upgrade implementation was introduced.
- Tutorial gates are rechecked at the click. New markers, close-time unlock
  cleanup, and manufacturing's original close-time guide step are preserved.
- Live pack, money, relevant recipe-list, and guide changes refresh the page.
  Offset refresh follows the old row-count delta convention with safe clamping.
  The optional manufacturing focus target uses the original `focusOffset` lookup.
- Selection follows recipe identity across list changes; an exhausted recipe moves
  to its live neighbor. The unlocked owner remains responsible for row changes.
- In-flight transaction events are suppressed until the original transaction
  completes. Old-generation buttons, repeated old activations, active modals,
  Back in progress, removed rows, late locks, and disposed views cannot transact.
- Native cleanup and explicit destruction remove all four page subscriptions,
  including the legacy DataManager short-key alias.

## Verification

Executed against the real existing Linux Cocos/EGL harness, with this checkout as
its working directory and isolated in-memory economy/unlock boundary spies.
No player save, app profile, or GUI was used or changed.

```sh
source ../linux-runtime/env.sh
/workspace/shared/lua51 tools/tests/coherent_recipe_pages_regression.lua
MESA_SHADER_CACHE_DISABLE=true \
  ../PirateExplore-coherent/build/linux/tests/tutorial-log-native \
  tools/tests/coherent_recipe_pages_native.lua
```

Native coverage includes 480×800, 540×900, 640×960, 640×1136, and 720×1280;
actual LabelTTF/font/bounds, native TableView geometry, all material rows,
original list identity, exact deductions and one-item grant, ID/sortId routing,
shortages, stale/repeated actions, late locks, modal/Back blocking, live offsets,
focus, empty states, empty-to-newly-unlocked transitions, and explicit/native-cleanup lifecycle.

The real SDButton touch methods are exercised with native world-space coordinate
conversion: press/release, press/long-press/release, and an outside rejection.
All 67 shipped construction rows and 115 shipped produce rows are independently
selected at 480×800. Their full costs, identity, fonts, readable detail sizes, and
read-only browsing are checked. Native suite: **41,424 assertions passed**.

The existing focused-forge Lua and native suites still pass, including the
separate focused route's exact three-resource transaction. Bundled font coverage
and `git diff --check` also pass.

These are real native component tests with controlled state, not a claim of
natural full-game progression or desktop visual acceptance. The independent
reviewer owns actual GUI interaction and visual approval. No commit, publish,
engine, economy, save format, or platform changes belong to this work.
