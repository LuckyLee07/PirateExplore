# B harbor refinement: focused home-page acceptance

Local starting point: `2cb208fd7ed6c5a4a0be676d93ebaf1eb6355e65` (first-batch source). The API-published draft PR uses separate commit identities with the same source tree. This work does not reset that history or merge the PR.

## Scope and presentation

Only the home layout, its dedicated header/footer appearance, reusable home illustrations and supporting home-only behavior were refined. The shared first-batch BTheme, expedition, chart, economy tables and save structure are unchanged.

The page now reads as harbor → actual selected crew and supplies → one primary action → illustrated talent/construction entrances. The duplicate brand heading and three equally weighted number cards are gone. Body copy uses regular Arial (native CJK fallback); headings use the existing bold face. Small native rounded controls and quiet paper-colored surfaces replace large stacks of solid cards. Images use uniform cover scaling.

A selected type 107 ×3 is one wood-shield helmsman portrait with its real count, not three invented characters. Type 124 is shown only when selected. Reserve count is inventory minus selected units. All other crew types use a neutral silhouette with the actual CSV type name. Three usable key types (1037, 1038, 1061) are summarized from the real selection.

The original eight routes are retained. Initial tutorial locks still hide the original seven routes until guide step 1, as before; no route was removed or silently grouped. The new-player main action sends the player to the existing alchemy/warehouse route; after that prerequisite, a still-locked shipyard sends the player to construction. An unlocked shipyard sends the player to preparation, never directly into a voyage.

## Quiet production feedback

Only the three routine production floating-text call sites in NotificationNode use `ToastUtil:productionString`. While the active view is Home, those notifications do not float across crew and supplies. Calculation, save writes, timing, resource refresh and existing log writes are unchanged. Errors, unlocks, rewards and other pages retain the existing toast path. This adds no event listener, queue, timer or persisted preference.

## Actual native QA

Tested with separate mature and genuine new-player QA profiles in the assistant-owned Linux desktop. The historical chapter-six save remained separate and its original eight file hashes were unchanged.

- 540×960 and 480×800: mature selection, empty formation and locked new-player home all rendered in the actual native game. On the shorter display only harbor height and spacing contract; body text is not globally scaled down.
- Mature profile: 107 wood-shield helmsman ×3, one reserve doctor, saved food and keys. Portrait and counts agree with the selection. Clearing three crew through original preparation controls yields the true neutral empty state and four reserves.
- Home → preparation and Home → talents → Back function correctly. Original non-home header/footer styling returns on departure and the home styling is restored on return. No hidden Home input intercepts the legacy pages.
- The locked state came from an empty save directory through the original intro, without save editing or automatic expedition initialization. It showed zero money/diamonds, 0/1 crew and 0/20 cargo. The main action reached the existing alchemy scene and original tutorial hand/furnace. A round trip without using alchemy retained money 0, diamonds 0, empty inventory, empty crew and empty selected formation.
- Cold restarts of each QA profile preserved their real state. No new Lua exception or traceback was observed; existing Linux audio/empty time-sync URL warnings remain.

## Automated checks

`LUA_BIN=/path/to/lua5.1 tools/tests/run-adventure-ui-tests.sh`

The native bundled Lua 5.1 parser validates nine relevant files. `home_b_v2_regression.lua` uses real Header constants and DataManager event semantics with mocked native rendering. It covers mature/empty/locked/mixed crew, string quantities, three key types, read-only role/CSV snapshots, all main-action branches, current message/coin refresh, home-only chrome restoration, five navigation cycles and exact native-listener cleanup, and production-only toast silence with original error/unlock/off-home behavior. Existing preparation and chart suites also pass. Rendering mocks are not claimed as screenshot acceptance.

## Review gate and limits

Parent and independent visual reviewer both gave final approval after inspecting the clean mature, empty-formation and locked screenshots at both sizes. The independent reviewer confirmed no clipping/overlap, visible main action and illustrated entrances, accurate crew/empty states, readable first-run guidance, and removal of routine production-toast obstruction. This approval covers the home refinement only. Remote publication remains a separate verified step; no merge is authorized.

No new battle, full chapter, macOS/iOS or audio acceptance is claimed. Non-home production screens and original promotion popups remain outside this refinement.
