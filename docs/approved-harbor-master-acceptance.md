# Approved full-scene harbor master: implementation and acceptance

## Baseline and scope

The user approved the 941×1672 full-scene harbor composition and four navigation groups. Local starting commit is `2b8d204a00c77741628ad826c6e8373f59464067`. The previous unpublished home refinement and this implementation must be published on top of the existing draft PR through ordinary commits; no force-push or merge is authorized.

This replaces the prior stacked home design. It does not restyle the expedition or sea chart, change economy/data tables, alter battle rules, or change the save format. The old page safety dimensions remain top 100 / bottom 136; the four-group navigation has an independent 118-unit visual area.

## Native component implementation

- One clean, uniformly cover-fitted harbor backdrop. It contains no text, UI, numbers, character cards or controls.
- Actual native title, live currency values and independent purchase buttons over paper materials. Each purchase target is 59×59 logical units, at least 44 physical pixels at the smaller tested size.
- An ink-brush ship-status plaque reads the current `roleShipId` resource name, selected cargo, food, keys and capacity progress.
- One paper roster carries actual selected unit data. Up to three selected units are represented in three slots, including repeating the same profession when three units of that profession are selected. Zero/one/two-person formations retain neutral empty positions; unillustrated professions retain their real CSV name and a neutral silhouette. Higher-count formations use per-type quantities.
- Transparent 107/102/124 portrait cells are separate assets. Pale-blue painted backing reuses a brush-alpha stencil; it is not an embedded fake roster.
- The supply state and main action are real text/buttons. The main action enters preparation, or the original construction/initial alchemy route while prerequisites remain locked. It never silently enters a voyage or instantiates expedition just to populate Home.

## Four navigation groups and original availability

- Base: Home
- Voyage: original preparation
- Crew sheet: recruitment, talent/growth, achievements
- Port sheet: construction, warehouse, crafting, gathering, market, alchemy, ranking, settings, diamond store

The original seven primary route gates and guide side effects are retained. Alchemy stays directly reachable for the first tutorial; settings retains the warehouse gate. Achievement/ranking group shortcuts inherit the shipyard prerequisite from their original expedition-page entry. Existing purchase callbacks remain intact. Menus use native text/hitboxes and close on their close button, selection, or outside tap; repeating/opening/replacing a sheet removes its prior touch listener.

## Typography and licensing

`fonts/HarborSerif-Bold.ttf` is a renamed UI subset derived from Noto Serif CJK Bold, converted from CFF to TrueType outlines for the legacy renderer. It retains the source Adobe copyright and SIL OFL 1.1 notice; full notices are bundled in `fonts/HarborSerif-LICENSE.txt`. The distribution-package notice also includes its separately identified packaging license and does not change the font's OFL license.

`tools/build_harbor_heading_font.py` documents the build route. The shipped face covers the current UI and the original resource/soldier table characters. The custom subset name avoids relying on the upstream font name. No absolute cloud font path is used at runtime. Only approved-home headings, primary action and type labels use this face; lighter text uses Noto Serif CJK SC on Linux or Songti SC on Apple platforms, with the original font fallback elsewhere. Missing bundled-font fallback is explicit. Mac/iOS font rendering is not claimed as tested.

## Native runtime acceptance

Separate mature and genuine first-run QA profiles were used. The preserved chapter-six profile was not launched or modified; all eight baseline file hashes remained equal.

Actual screenshots were captured at 540×960 and 480×800 for mature selected crew, empty formation and locked/new-player states. The 540×960 runtime screenshot was placed beside an equally sized rendering of the exact approved master for visual comparison.

Verified through native interaction:

- Base → real preparation through both the primary action and Voyage group.
- Crew sheet → talent page → original Back; Port sheet → warehouse. Original non-home header and content styling stay intact, while grouped navigation stays usable.
- Crew/Port sheet opening, replacement, outside dismissal and close-button dismissal; no residual overlay intercepts the next page.
- Real preparation minus controls changed 107×3 → 107×1 → empty; Home showed one actual person/two empty positions and then three neutral positions. Filling restored the true three-person roster.
- On the initial profile, Voyage was blocked with the original shipyard explanation. The main action opened the original alchemy scene, including its original delayed tutorial hand and furnace. Returning without using alchemy preserved money 0, diamonds 0, empty inventory, empty crew and empty selection.
- Cold restarts restored the respective real profile and composition. The compact layout keeps the same scene/roster/action hierarchy and usable group sheets.
- Routine production floats are quiet on Home. Already-visible routine floats are tagged and cleared on Home entry, and queued routine messages are not replayed over Home. Important errors/unlocks stay visible. No production calculation, resource update, log write or timing was changed.

A native API mismatch (`DrawNode.drawCircle` unavailable in this older engine) was discovered on the first run and replaced with supported drawing calls before acceptance. Final-run logs have no Lua error/traceback. Existing audio-device warnings and the original empty-URL time-sync warning remain.

## Automated verification

`LUA_BIN=/path/to/lua5.1 tools/tests/run-adventure-ui-tests.sh`

The suite parses the relevant runtime Lua and uses original Header/DataManager event semantics plus real decoded packaged CSV data. It verifies actual professions/ship names, portrait-cell identity, three-slot empty/partial states, read-only snapshots, seven-event Home cleanup, live currency, purchase callbacks, all primary/utility gates, original guide effects, repeated modal lifecycle/touch cleanup, other-page appearance restoration, and production-only notification filtering. Existing expedition and chart regressions also pass. The bundled heading TTF was opened and its required Chinese/number glyph coverage verified. Native CMake build reaches 100%; `git diff --check` passes.

Mock rendering checks are not substituted for the native screenshots. No new battle, full chapter, economy rebalance, macOS/iOS or audio acceptance is claimed. Original promotion popups/boat behavior is retained and no purchase was made.

## Submission gate

The parent and independent visual reviewer accepted the 540×960 master comparison after the focused typography, blue portrait-backing and navigation-scale refinements. Final compact/state screenshots were re-reviewed, including the capacity-aware locked-slot correction; the independent reviewer confirmed both sizes and all three states pass with no remaining visual blocker. Functional evidence and the narrow code review also passed. Remote publication status must be verified separately; this document does not claim a push or merge.

Font platform boundary: the bundled file-path face is selected only by the verified Linux renderer. Apple explicitly uses its Songti SC system-family fallback, because this legacy engine does not register a bundled font automatically. Other targets use the original font. No claim of cross-platform identical typography is made.

Capacity refinement: positions beyond the real roleCabinSize are marked “未解锁” with weaker neutral artwork. A 0/1 ship therefore has one available empty position and two visibly locked ones; the three-position composition never implies extra capacity.
