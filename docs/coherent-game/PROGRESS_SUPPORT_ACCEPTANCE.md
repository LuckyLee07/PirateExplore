# Talent and Achievement support pages

Local-only implementation from frozen `169a4242c641fd4e14c76c4e74867d60d774df2f`.

## Presentation

Warm explicitly opts into the shared 480×800 page shell. Talent uses the original newest-earned ordering, compact semantic illustrated rows, live money/diamond and chapter context. Achievement uses actual saved achievement flags, original progress sources, points, and the original sorted locked auto-talent threshold. A threshold already satisfied is described as a point condition, not a promise that other automatic conditions have passed. Exhausting locked point talents removes the former threshold. Neither page adds a claim action.

There is one Back to the original Dispatch route. Talent retains gated Intelligence; Achievement retains gated Talent and Intelligence. Original alchemy `SDButton`, native listener, `normalSpr`/`selectSpr`, `ProgressTimer`, callback, cooldown and earned long-press controller are retained. Their presentation is relocated; the drawn cooldown underline reads the original timer. Original guide401 is still Dispatch-owned; Achievement clears guide402 exactly once on disposal. Explicit `WARM_PIRATE_V1=false` keeps the pre-existing illustrated Talent and grid Achievement paths.

Each instance has unique DataManager aliases. Cleanup unregisters native handles then clears only matching owned closure aliases; it does not remove another page or gameplay subscriber. Row generations stop stale informational callbacks. Scroll gestures cancel row taps, including offset-only movement and out-of-clip release.

## Art provenance

`Images/UI/CleanVoyage/Support/progress-props-v1.png` is a byte-for-byte copy of an OpenAI built-in image generation on 2026-10-11. It is a 1254×1254 RGBA transparent raster atlas. The adjacent JSON records source, semantic identities, bounded native texture crops and stable logical anchors. No existing packed atlas, item identity or data table was overwritten. The entire atlas was visually inspected; native captures then verified 42/60/78/98/104-point consumption.

Generation specification: production pirate-game 3×3 transparent sprite atlas, isolated dimensional props with upper-left sunlight, brass/gold, teal, cream and dark wood. Row one: nautical compass, gold star medal with teal ribbons, alchemy flask with gold liquid and coins. Row two: precision target/arrow, dodge feather/teal swoosh, hunger-resistance food barrel. Row three: first-strike lightning charm, scouting spyglass, neutral talent skill badge. No lettering, grid, paper cards or backgrounds. Prompt explicitly requested clean, rounded faceted 2.5D mobile-game artwork, not flat/vector placeholders. The output was imported unchanged; sprite cropping is only a presentation texture rectangle.

## Verified locally

- `coherent_progress_support_native.lua`: production Cocos nodes, shipped CSVs, original BaseView/SDButton and *actual DataManager register/unregister/postEvent implementations*.
- The final ordinary native fixture passes 9,428 assertions; the offscreen dispatched-gesture variant adds four assertions.
- Five viewports: 480×800, 540×900, 640×960, 640×1067, 720×1280. Talent empty/sparse/full/unknown, Achievement empty/full/max, large currency/points, refresh, reverse-earned ordering, true points/thresholds, same-size scroll retention, informative details, original guides, actual alchemy hold gesture/release and remaining cooldown.
- Real native event subscriptions across simultaneous pages; exact handle/alias cleanup; unrelated subscriber preservation; no disposed callback reward; no role/CSV writes from populated-state construction, refresh or detail display.
- `coherent_progress_support_render.py`: native offscreen Cocos/EGL captures all six states across all five viewports (30 PNGs), and uses actual scene entry/event dispatch/native ScrollView motion to prove an achievement drag does not open details. No GLFW window or user profile is opened.
- Existing `talent_ui_regression.lua`, `alchemy_feedback_regression.lua`, `gather_cooldown_regression.lua`, `auxiliary_ui_regression.lua`, font coverage, Lua parse and whitespace checks pass.

Commands (using an existing build/runtime):

```sh
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
NATIVE=/workspace/scratch/79976da795e7/PirateExplore-shutdown-fix/build/linux/tests/tutorial-log-native
"$NATIVE" tools/tests/coherent_progress_support_native.lua
PIRATE_BUILD_DIR=/workspace/scratch/79976da795e7/PirateExplore-shutdown-fix/build/linux \
  python3 tools/tests/coherent_progress_support_render.py
python3 tools/tests/coherent_progress_support_art_regression.py
```

The native fixture is picked up by the existing aggregate's `coherent_*native.lua` glob. The optional rendering runner and art metadata check are explicit commands. Offscreen PNGs are native component evidence, not full-GLFW visual acceptance or natural progression. The independent GUI reviewer still owns whole-app screenshots, clipping continuity and old-save review. The original BaseView migration write for missing `roleAlchemyCanLongPress` is not new page logic; no save schema or economy owner changed.
