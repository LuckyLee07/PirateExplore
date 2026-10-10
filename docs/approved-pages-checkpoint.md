# Preparation, talents and sea-chart checkpoint

Baseline: `7497f7f8e1c890406ae735801a68287c5b5f0428`. This checkpoint implements the approved preparation and talent designs and a playable sea-chart presentation. The6fb88db recovery checkpoint recorded the two accepted management pages before the sea-coast pass. The subsequent sea-chart pass is accepted as a coherent, playable first implementation; its artwork still needs refinement and is not described as a high-fidelity or final reproduction. Remote publication is not performed by this checkpoint.

## Accepted pages

Preparation uses native controls over an unlabelled harbor backdrop: real merged inventory, selected crew and cargo capacities, item details, quantities, press-and-hold, fill and original departure validation/transaction. Minus/plus sprites retain small visual faces with centered transparent hit rectangles of at least59 logical pixels (44.25px at480px width). The original tutorial and transaction code remain. One correctness fix allows removing the last unit of a resource occupying multiple cargo spaces. Another preserves the existing food-row button during production: it updates the shared remaining-stock closure and label; a newly appearing food row uses the original rebuild. Production amounts, timing and economy are unchanged.

Talent displays only actual roleTalent entries and real CSV names/effects. The mature test profile has two entries, not the four illustrated examples. Empty and unknown entries are supported. The existing alchemy SDButton callback, cooldown and long-press entitlement are retained; intelligence retains its original map/unlock predicate. Both back controls return through the original Dispatch route. Five listeners are unregistered on disposal. The dedicated vertical paper avoids stretching the previous horizontal roster material. No learn/upgrade mechanism is added.

Native Linux540×960 final screenshots: `14-departure-final-540.png`, `15-talent-final-540.png`. The same-size approved/runtime comparisons are `departure-approved-vs-runtime-540.png` and `talent-approved-vs-runtime-540.png`.480×800 and empty/locked screenshots are in the same external evidence directory. Root and independent visual reviews accepted these two page layouts. Evidence is kept outside the repository under `/workspace/shared/b-approved-pages-evidence` and is not a game asset.

## Actual interaction checks

Independent mature and newly created QA profiles were used. The historical chapter-six profile was never launched. All eight file hashes equal the original baseline, recorded in `historical-save-verification.json`.

- True minus operations empty107×3; fill restores the selected crew. Empty crew and empty food prevent repeated departure attempts.
- Single clicks, expanded transparent edge clicks, continuous hold, fill, inventory limits and real item details operate. After the production-refresh fix, a12-second hold crossed a production tick and reduced food52 to0 while stock increased normally. A two-second plus hold selected24 food; over the next minute the selection stayed24 while production increased only remaining stock.
- Talent opens from preparation and the crew group. Real intelligence opens and closes, while a new profile receives the original unlock explanation. Alchemy invokes the original gain/cooldown behavior. Back returns to the previous page without a residual overlay.
- Sea departure retains real food/cargo. Cancelled return remains at sea; confirmed return consumes the stated15 in-game diamonds in the isolated QA profile. Returning to the harbor anchor through original movement also works.
- Four directional controls move on the real map. Real food decreases and cargo follows. A random original sea battle completed and its loot screen closed back to the chart; this is not full combat/chapter acceptance.
- Cold restart at sea restored the same tile position, food52, cargo55/60 and47% explored state. Cargo and guide dialogs open/close correctly.

## Sea-chart status and safeguards

HUD and bottom controls use actual chapter, exploration, food/cargo, guide, inventory and return callbacks. No Base navigation is inserted at sea. TMX64-pixel tile coordinates, GIDs, collisions, events, movement, fog visibility and save formats remain unchanged. Nine core Explore methods are byte-identical to the baseline.

The first candidate fog RenderTexture caused black occlusion and was rejected using a same-save A/B against the original fog. It was replaced by a small shader that retains original atlas alpha/UV and vertex opacity while outputting ink-blue. A real surfaceless GL test compiles the production shader and checks transparent/partial/opaque pixels. The grid shader only lowers visual opacity. A continuous repeating water texture replaces the rendered Sea surface for supported dt_ludi maps, retaining the original layer data and fallback. Decorations are limited to validated land cells without events and remain under the original fog.

The subsequent sea-coast pass uses a separate SpriteBatchNode stencil copied from original land tile alpha/positions, with one continuous opaque golden sand/rock/grass material. Original Blocks layers remain untouched beneath it. The ship child sprite is enlarged without changing its64-logical-unit container or movement anchor. Existing event sprites keep their original frame/anchor because they already occupy tile edges and their effect placement depends on the original anchor.

Final first-version visual reviews accept the unified B palette, HUD, real coastline and larger ship at540×960 and480×800. This is a runnable first version, with sea artwork still awaiting refinement: islands remain relatively flat, event sprites retain older artwork, water repetition is visible, and original fog boundaries are square. It is not a high-fidelity recreation of the illustrated design. Final sea images are23/24, with approved/runtime comparison25. Actual fog advancement47%→48% is captured in26 and persists after a cold restart in27 (food53, cargo56/60). Cancelled return preserves the scene; confirmation returns home and reduces only the stated15 in-game diamonds198→183 in QA.

## Tests and limits

`LUA_BIN=/workspace/shared/lua51 tools/tests/run-adventure-ui-tests.sh` passes parser checks and Home, preparation, sea HUD, talent and native triangle regressions. `tools/tests/sea_chart_renderer_regression.py` provides real GL shader pixel checks when EGL/OpenGL are available. Mock-based UI tests do not replace original alchemy timing or native interaction checks.

The packaged Noto Serif CJK Bold subset now covers all LuaClass text and decoded original CSV names/effects, preserving prior glyphs. Its full OFL license and reproducible generator are retained. No encoded CSV/game data or save format changes. Mac/iOS old LabelTTF may use a system-font fallback; matching typography and rendering on those platforms is not claimed. Existing audio and empty-URL warnings remain. No merge or remote publication is implied.

## Post-checkpoint intelligence correction

Native log inspection found an existing expiry-path error in RandomEventMode: both manager removal and TableView reload were called without their method receiver. The initially opened intelligence view could display normally while its update callback raised a native binding error when a task expired. The separately approved correction changes only these two calls to colon syntax. A regression executes the actual production removal/update methods and proves one expired item is removed/saved/reloaded per update, a live item is retained, and rewards/start times/lifetimes are untouched. Independent code review passed. This correction follows the6fb88db checkpoint; the earlier log is preserved as evidence, not described as error-free.

## Final sea fallback and safety checks

Read-only inspection of all16 shipped TMX files confirms64-pixel tiles. Supported dt_ludi land layers have84,85,78,332 and381 cells on maps1,2,3,6 and14; maximum381 is below the512-cell decoration budget, and none has tile flip flags. Other11 map themes do not receive the land stencil. Continuous water is used only where the actual Sea texture is dt_ludi (maps1,3,7,9). Automated tests cover unsupported themes, missing land/water art, wrong texture dimensions and625 cells exceeding the budget, retaining the original layers. Those theme fallbacks are code/data-tested; not every chapter was traversed in the GUI.

The final complete regression runner and real GL fog/grid/stencil pixel tests pass. After the intelligence correction, native runs through both screen sizes, land-mask sailing, fog advancement, sea restart and return contain no new Lua exception. All eight protected historical save hashes still match their original values. No full battle/chapter or Apple visual validation is claimed.
