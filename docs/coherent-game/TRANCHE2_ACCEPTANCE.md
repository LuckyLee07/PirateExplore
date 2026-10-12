# Tranche 2 acceptance ledger

Base: visual checkpoint 685b6a3 plus tested Linux lifecycle and curl-compatibility commits through b7599f6. This tranche is isolated from the published checkpoint. Independent source/component review passed; final integrated regression passed on 2026-10-11; independent actual-window acceptance remains pending.

| Surface | Implementation | Native geometry / callbacks | Actual window | Remaining gate |
|---|---|---|---|---|
| Shared management shell | Explicit opt-in, navy task header, readable cream body, compact back | PASS at 480–720 width; repeated/stale back | Pending | Full route transitions |
| Ordinary construction / manufacture | Dedicated selected-recipe composition | PASS: 41,424 assertions; all 67 construction +115 manufacturing recipes | Pending | Actual GUI |
| Market | Product selection, actual unit/total price, ownership, one purchase control, bulk chooser | PASS at 480–720; ten-item transaction, shortage/cancel, stale control | Pending | 62 shipped catalog entries and sold-out repeated-input guard pass; actual GUI pending |
| Crew / recruitment / promotion / materials | Implemented | PASS: five sizes, empty/full roster, 3-gold recruit, exact promotion/synthesis, all acquisition routes | Pending | Actual empty recovery and nested sheets |
| Resources / warehouse | Implemented | PASS: 4,336 assertions; scaled touches, original cooldown, workers, stock, 1/10/all sales | Pending | Actual repeated controls and live production |
| Events / loot | Implemented | PASS: 88,756 event assertions across 344 records/ten families/both occupation states/five sizes; loot/chest exact-once and actual event callback order | Pending | Natural and controlled actual-window encounters/loot |
| Battle stage / later maps / support utilities | Next tranche | Pending | Pending | Per-surface gameplay and art coverage |

The surgical native shutdown change is a separate stability commit/worktree, tested against unchanged checkpoint-1 resources. Do not mix its acceptance with these page changes. No Mac or mobile acceptance is claimed.

Shared sans font regenerated against all current Lua and decoded CSV text: all 2,059 glyphs/metrics were identical to the existing licensed font, so existing byte-exact font retained. Coverage regression passes. Cargo/chest and market offscreen Cocos renders were inspected; these do not substitute for actual-window gameplay QA.

## Independent review fixes

Three reproduced issues were corrected and independently retested: supply-page drags no longer activate allocation, sale information or repeated holds; disposed market, crew and shortage views clear their owned DataManager callback aliases as well as native listeners; chest-description drags no longer trigger the inherited tap-began dismissal. Stationary holds, original transactions and legacy opt-out remain covered.

The offscreen chest test dispatches actual GLView touches into the running Cocos scene at five viewport sizes. It verifies visibility and content movement, and rejects an in-memory counterfactual restoring the old dismissal listener. The headless helper supplies only a fixed 96-DPI display metric because Linux Device::getDPI requires an X display; renderer, ScrollView and event dispatch are production implementations. This is component input coverage, not desktop acceptance.

Independent component review: GO, 2026-10-11. All seven page suites were rerun separately, including real subscription-method cleanup probes, supply drag cancellation counterfactuals and chest dispatched-drag counterfactuals. No unresolved source blocker was found. Economy CSVs, save schemas, geography, engine code and unrelated battle logic are unchanged in this tranche. The checkpoint must still pass the separately recorded desktop route matrix before publication review.

Final integrated run passed: Warm and legacy opt-out regressions, all component native suites, actual dispatched chest gestures with failing old-handler counterfactual, curl header compatibility, all HTTP shutdown cases, original map adapter and font coverage. Desktop route entries remain pending above.
