# Coherent crew, recruitment and material recovery pages

Warm-only composition in `TrainMode.lua` and `Lackmaterial.lua`. Legacy
constructors remain available through `WARM_PIRATE_V1=false`.

## Presentation

- Train uses the shared 480×800 page shell, with real owned/assigned totals,
  readable profession rows and an explicit recruitment preview. An empty roster
  has harbor scenery, a concrete next step, the actual sailor and its exact price.
  It no longer creates the three-part utility footer or system feed.
- Roster rows retain skill-detail taps and promotion entry. Stock refreshes keep
  the roster's scroll position. Existing guide handles reference the visible
  recruit item; reaching maximum rank still exposes the real skill details.
- Promotion presents all actual profession choices and one selected detail:
  actual portrait, stats, skill/buff description, owned/required material rows,
  acquisition buttons and one confirmation action.
- Synthesis uses a bounded ingredient list and a single explicit one-item action.
  Acquisition sheets show deficits, costs and valid production/market/exploration
  routes. Gold shortage links to the existing warehouse/alchemy route.
- Lackmaterial uses a bounded scrolling sheet instead of increasing the dialog
  beyond the viewport. Exact deficits update from live stock. Production links
  appear only when ProductionSources finds a real unlocked worker recipe.
- All sheets have one close control. Source replacement removes the full obsolete
  dialogue stack, then follows the original Dispatch destination. Reopening the
  transaction reads current stock; this change does not introduce new route
  history or an automatic transaction-return mechanism.

## Preserved transaction and lifecycle contracts

- Recruitment invokes the original local Recruit closure only after explicit
  confirmation. The shipped 3-gold cost, one sailor, guide step 11, achievement and
  queue update remain unchanged. Insufficient gold stays on a readable recovery
  sheet and offers alchemy.
- Promotion retains the original material-deduction order and delegates crew
  replacement, achievement and selected-unit clamping to changeJobCallBack.
  The source crew is resolved again by ID, avoiding an obsolete sorted index.
- Synthesis retains grant-then-deduct order and one output. Purchases retain
  addCoin → addPackItemWithId → parent refresh. No economy, unlock, engine or save
  schema code was modified. Page/sheet construction and choice selection are
  read-only.
- Native button generations, current-stock validation, disposed/closing guards
  and one-shot commit state reject stale/repeated actions. Native cleanup removes
  every added subscription and clears singleton handles. Source routes clear
  nested sheets before changing the production page.
- Existing SDButton implementation, listeners, hold behavior and legacy callbacks
  were not changed.

## Verification

`tools/tests/coherent_crew_pages_native.lua` passed using actual Cocos/EGL,
shipped CSVs/assets/font and isolated in-memory transaction spies, at 480×800,
540×900, 640×960, 640×1067 and 720×1280. The exact terminal marker was checked:
`coherent crew pages native: PASS`.

Coverage includes empty roster, real confirmed recruitment, insufficient gold,
guide 11, achievements, all five sailor profession choices, absent materials,
late-stock/stale native buttons, exact promotion and synthesis deltas,
selected-unit clamping, nested purchasing, all acquisition route families,
locked/unlocked and zero-assigned-worker production, full shipped crew roster,
large counts, roster scroll retention, an eight-row shortage list, full nested
stack removal, native label bounds and complete subscription cleanup.

Also passed: Lua source parsing, `git diff --check`,
`crew_recovery_regression.lua`, `crew_skill_details_regression.lua`, and
`management_ui_regression.lua` (including existing SDButton tap/hold coverage).

These are headless native geometry/transaction tests, not a natural fresh-save
playthrough or pixel screenshot acceptance. GUI review, real route screenshots,
full-game continuity and final aggregate font regeneration remain integration
checks. No GUI was opened/restarted, no profile was modified, and no commit or
publication was performed.
