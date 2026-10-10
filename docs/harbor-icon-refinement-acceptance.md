# Harbor icon contours and currency-plus alignment

Baseline: `ae9d9f5ad25591f234e68eb3a7e6f2ea8118ca07` (tree `013e2257b30147f4fcccd9ab822bb34560b2256b`). The user accepted the rest of the homepage and requested only better small-icon quality and slightly less right-aligned currency plus signs.

## Narrow scope

- Both Home purchase targets move six logical units left: gold X199→193, diamond X382→376. Their 59×59 hitboxes, callbacks, live amounts and vertical positions are unchanged. At the smaller 480-wide target this remains44.25×44.25 physical pixels.
- Small symbols use original native vector geometry: continuous cream silhouettes, curved contours and a few meaningful transparent gaps. The same requested-color geometry supports the dark roster-header icon on paper. No image texture, high-frequency distress, image generation or new raster icon dependency is added.
- Background, portrait art, crew selection logic, names, typography, action material, headline, panel layout and navigation routes retain the accepted previous implementation.

## Validation

Native Linux screenshots cover normal, empty and locked Home states at 540×960 and 480×800. The final screenshot files are `08-final-540x960.png` and `05-final-480x800.png`, with locked states `07-locked-540x960.png` and `06-locked-480x800.png`. Reference and before/after comparisons are `09-master-vs-final.png` and `10-before-vs-final.png`; these compare actual screenshots, and naturally changing QA gold amounts are not fabricated to match.

At both sizes, the moved gold/diamond plus targets open their original respective panels. Closing each panel restores normal Home input; no purchase is made. Native page checks cover Warehouse, Build, Craft, Gather, Market, Recruit, Growth, Achievement and Preparation, with repeated group opening/closing and Base return. No new triangle overlay or residual modal interception occurs. Real preparation controls empty and restore107×3; new-player0/1 still displays one available and two locked slots. Independent mature/tutorial QA profiles survive restarts. All eight historical chapter-six file hashes still equal the original baseline; that profile is not launched.

The complete Lua runner passes, including both viewport sizes, normal/empty/locked data, original gates/callbacks, native color and uniform geometry scaling, true unpainted icon negative-space samples, and no icon-file dependencies. `git diff --check` passes. The native CMake build reaches100%.

## Required one-line renderer correctness fix

The curve implementation triangulates its own concave outlines. Native inspection uncovered two legacy primitive limitations: thin `drawPolygon` triangles use automatic miter extrusion, producing invalid long edges; more importantly, `DrawNode::drawTriangle` reserved/submitted six vertices while initializing only three. The latter caused uninitialized triangles to cover the screen. After explicit project-owner approval, only `vertex_count = 2*3` was changed to `vertex_count = 3` inside `CCDrawNode.cpp::drawTriangle`. No other engine function changes. The icons use the now-correct plain triangle primitive.

`tools/tests/draw_triangle_regression.py` extracts and compiles the actual production function body against minimal buffer types, then draws100 triangles and verifies exactly300 initialized submitted vertices, unchanged following sentinels and valid fill data. This supplements, rather than substitutes for, the real recompiled GUI checks above. Ear-clipping completeness and polygon/triangle area equality were independently reviewed at actual icon sizes.

The initial broken-primitive candidates were rejected before acceptance. One intermediate X11 MIT-SHM startup failed and recovered on a fresh start; final repeated startups were stable. Existing ALSA/FMOD device warnings and the original empty-URL sync warning remain. The existing Linux/font/audio limitations remain unchanged; no new platform, battle or full-chapter acceptance is claimed.

Final visual/code reviews and remote publication are recorded separately. No merge is authorized.
