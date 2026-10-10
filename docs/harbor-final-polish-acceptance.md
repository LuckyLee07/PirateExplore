# Harbor homepage final polish

## Scope and baseline

Baseline: local `002e01abbf7f41a03b82894fb13b88ee3a179c22`, tree `3e8c9a166e8d726d32401bb188d835f4c53c1758`. The user requested closer fidelity to the approved full-scene home. The harbor backdrop, major layout, real crew data, routing, economy, algorithms, save structures and other page content remain unchanged. Shared four-group navigation receives the same icon/label improvements.

## Presentation changes

- Layered blue brush backing replaces the flat gray-green portrait rectangles. Real crew107×3 remains three representations of the same profession, with uniformly fitted portraits and more space beneath the names.
- Native icons use cream broad forms and sparse structural detail, including asymmetric wind-filled sails, curved anchor arms, a barrel lip/hoops and open port/crate details. A noisy generated icon attempt was rejected and is not included.
- Cargo/food/key/currency text and footer labels regain clear serif weight. Ship-status horizontal and vertical dividers are visible. The food/key row was reduced one step after visual review to retain breathing space.
- The action uses a generated brush alpha edge with a native continuous coral fill. Generated white interior streaks are intentionally not displayed. The action label and routing are still native.
- Existing currency art is fitted to 34×34 logical bounds and moved five logical units inward, matching the approved small-screen icon size. Purchase button hitboxes and amounts are unchanged. Existing title art is retained.

## Native Linux acceptance

Actual app screenshots, not composites pretending to be runtime, cover 540×960 and 480×800 normal, empty and locked states. Side-by-side review composites only place the unchanged screenshot alongside a uniformly resized approved reference or previous screenshot. Screenshot gold amounts vary naturally with independent QA elapsed time; they are not presented as identical game states.

Verified interaction:

- Home primary action enters the original preparation page. Real minus controls remove all three selected helmsmen; returning displays 0/3 and neutral slots. Attempting departure with an empty team remains blocked by the original warning. Original fill control restores107×3 and the correct Home roster.
- Cold restart at the second aspect ratio restores real empty/normal selection; no fake screenshot state is injected.
- Crew sheet opens and closes; Port then opens without residual interception; its Warehouse action reaches the original warehouse. Returning to Base restores Home.
- The existing gold plus opens its original purchase panel; closing restores Home. No purchase is performed.
- On a separate untouched-in-game tutorial fixture, 0/1 displays one available empty slot and two weakened locked slots. Voyage remains blocked by the original shipyard gate. The primary action enters original alchemy, and returning without performing alchemy leaves money/diamonds/cargo/selection at zero. The tutorial fixture survives restart at both sizes.
- All eight preserved chapter-six save file SHA256 values equal their pre-project baseline. That profile is never launched. QA uses separate `final-polish-qa-data` and `final-polish-fresh-data` directories and is stopped after screenshots.

Final evidence: normal540 `10-final-540x960.png`, normal480 `07-final-480x800.png`; empty540 `05-empty-540x960.png`, empty480 `06-empty-480x800.png`; locked540 `09-locked-540x960.png`, locked480 `08-locked-480x800.png`; reference comparison `11-master-vs-final.png`, before/after `12-before-vs-final.png`. Evidence remains outside the repository.

## Automated verification and limits

`LUA_BIN=/path/to/lua5.1 tools/tests/run-adventure-ui-tests.sh` passes Lua parsing, Home/master contracts, static detail contracts, final-polish contracts, preparation regression and chart HUD regression. New final-polish tests exercise missing/synthetic/decode-failed/zero-width/zero-height/packaged brush modes, both viewport ratios and normal/empty/locked data. They verify native icon independence and geometric scaling, stencil-only action painting, native fill, safe fallbacks, original hitboxes/routes, read-only state and listener cleanup. Both shipped PNGs decode as RGBA with real transparency. `git diff --check` passes.

Final Linux logs contain no Lua traceback. Existing ALSA/FMOD missing audio-device and original empty-URL sync warnings remain. No full-chapter/battle/audio or macOS/iOS acceptance is claimed. The previously documented Apple system-font fallback remains unchanged.

The parent and independent visual reviewer accepted the final normal/empty/locked two-size evidence; the original noisy CTA/icon candidate was rejected and replaced. Remote publication is verified separately; this document does not claim a push or merge.
