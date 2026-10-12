# Clean service and reward pages

## Scope and baseline

Local implementation is based on `fea3360bb451c595773c7ae8e3f69a1d7861424d`.
Owned production surfaces are Ranking/InputNameView, DiamondStore/PushGiftView,
SevenDayBonus and CDKView. No shared BaseView, WarmTheme, MainMenu, economy CSV,
save schema, native bridge or endpoint was changed. No publication is included.

The new compositions are explicit Warm-only branches. `WARM_PIRATE_V1=false`
keeps the prior visual routes. The service-only helper uses the existing
BaseView coherent page shell, original DialogueView stack and original AlertView
owners. No additional navigation, CDK settings entry, offer auto-opening,
debug control, subscription or billing endpoint was introduced.

## Presentation and precise art

- Ranking and nickname use a new faceted gold/teal medal. A real server's long
  names wrap at readable size in variable-height rows.
- Seven-day reward uses a new faceted chest and displays all seven actual CSV
  reward sets, with explicit received, available and future-day states.
- CDK, store and gift surfaces use the same chest, font and native controls.
  Real-money and virtual-diamond prices remain visibly different.
- Production-speed and offline-duration effects use a new faceted hourglass.
  First-strike (talent 2005) and hunger resistance (talent 2003) reuse the exact
  corresponding lightning/food props from the Talent support family. Coin
  grants use the existing clean coin resource. Names, descriptions, actual
  costs and repeat/one-per-tier limits remain the authoritative data.
- Old framed thumbnails are not silently mixed into the clean store. Portal,
  return-scroll, dragon and pure-diamond item families do not yet have approved
  exact replacement props. Those entries are deliberately text-first, without
  an arbitrary replacement icon. These four families remain an art acceptance
  gate, not a claim of completed game-wide item artwork.

Original transparent PNGs, separate prompts, source IDs, dimensions and hashes
are archived in `Images/UI/CleanVoyage/Support/service-props-v1.json`. No image
postprocessing was performed. There are three new, namespaced props; existing
packed assets were not overwritten.

## Controller contracts retained

- Ranking's HTTP response validation, request serial, pending state, disposed
  guard, server-confirmed nickname save and completion callbacks remain intact.
  The empty configured service URL reports unavailable truthfully. No fabricated
  ranking entries or configured production endpoint were added.
- Nickname remains eight characters and rejects whitespace; pending, error and
  offline responses preserve editable text. Parent teardown invalidates a late
  callback and closes the owned nickname dialog.
- CDK preserves the native platform/UserCenter/interface gate and the optional
  explicitly configured HTTP route. A successful already-submitted HTTP result
  still grants its original validated gift exactly once even after dismissal.
- Store initialization/normalization remains before the visual branch. This
  includes existing `roleMapBuyItems` clearing, unlocked/new/bought flags,
  initial gift records and store persistence. Opening this screen was already
  stateful; it is not incorrectly classified as a read-only screen.
- Virtual buying retains the original order: recheck current item/bought state,
  `addDiamond(-price)`, `buyGoodsInDiamondStore`, next/repeat flag handling,
  `checkAndstepNextGift`, then load/save normalized store data. The legacy
  spend-before-grant-failure behavior is preserved and tested; no refund or new
  economy rule was invented. A failed retained confirmation cannot spend twice.
- Virtual goods retain their original dtype=0/manual confirmation semantics,
  including staying open on early grant/buy-state failure. Real-money gifts
  retain the original dtype=2 AlertView native OK/Cancel handlers. They are not
  collapsed into a common transaction owner.
- Both old/new gift views share the original PurchaseAvailability platform gate
  and payType handoff. PushGift retains the original delayed buy readiness and
  DialogueView close/owner behavior. Linux never receives a synthetic success.
- Gift expiry advances to the original next gift/duration. The timer and owned
  DataManager listener/closure alias are released at teardown; stale row and
  refresh callbacks are rejected. Store drag/clipped-row handling uses native
  SDButton with the established support clipping guard.
- Seven-day claim executes the original callback. Singleton, claimStarted,
  isClosed, claim-time date recheck, date/count encoding, actual CSV grants and
  exactly-once save are retained, including completion/rollback behavior.

## Native evidence and reproducibility

Source `../linux-runtime/env.sh`, then run:

```
PIRATE_BUILD_DIR=../PirateExplore-shutdown-fix/build/linux \
  python3 tools/tests/coherent_service_support_render.py
python3 tools/tests/coherent_service_support_art_regression.py
```

The rendering runner builds the existing production-backed Cocos/EGL offscreen
harness and runs the new native test. It opens no GLFW application window and
uses only mutable in-memory data/service spies. It does not read/write a player
profile, make network requests, call a billing service or change a real account.

Default captures are in `/tmp/coherent-service-support`. Each filename includes
its actual render-target pixel dimensions. The page canvas is 480×800 logical
units, uniformly fitted to the target. These are actual native component
renders, not natural progression or physical GLFW-window acceptance.

Five sizes are covered: 480×800, 540×900, 640×960, 640×1067, 720×1280. All include
ranking offline/loaded, nickname entry, seven-day reward, CDK entry, store,
virtual confirmation, gift confirmation and push gift. Additional 480×800
captures cover pending/empty/failure/long-name ranks; first/second/third/sixth/
seventh claim days; CDK unavailable; empty/full stores; and ready push gift.
Native visible-label bounds and minimum type-size checks run with the captures.

Behavior coverage uses the actual native controller methods and callback order:
HTTP pending/failure/stale results, nickname save and duplicate submit, CDK late
one-shot success after close, reward singleton/date/reentrant cases, exact
virtual costs, once/repeat/next goods, shortage, late bought state, grant failure,
repeated cancellation, no residual store subscription alias, empty/full 29-row
catalog, clipped and dragged controls, gift expiry, payType and buy delay.

The test also runs with the existing `tutorial-log-native` executable (captures
are optional there), so the aggregate native glob can include it. Existing
`auxiliary_ui_regression.lua`, `purchase_availability_regression.lua` and
`tutorial_lifecycle_regression.lua` pass without weakening their expectations
under the explicit legacy opt-out. The original six real-money guarded call
sites remain six shared controller entry points across both presentations.

## Remaining gates

1. Shared font rebuild: the baseline subset lacks `绩`, used in the new ranking
   score labels. The shared owner will add it without dropping prior coverage.
   Ranking visual acceptance is blocked until those glyphs are visible and the
   native captures are rerun.
2. Four exact item-art families listed above still need their family-wide art
   integration. Removing old thumbnails is not claimed as finished item art.
3. Independent actual-window QA must check scroll stencils, keyboard/IME,
   owner returns and normal notification-triggered SevenDayBonus in the full
   GLFW app. This component work does not assert those unperformed stages.
4. The final integrated aggregate and old-save/natural-progression checks belong
   to the integration/review pass. The Linux checkout still has no configured
   ranking/CDK service or functioning Linux IAP bridge.

## Integrated follow-up: font and dynamic depth

The integrated candidate adds only the missing U+7EE9 (绩) glyph while preserving
all 2,059 previously shipped codepoints and the complete font license unchanged.
The new sheets now give opaque paper, header and text-field faces explicit
background depths. This engine resets sibling arrival order after rendering;
adding later feedback could otherwise reorder equal-depth backgrounds over text.

The real native render suite now adds/removes 28 empty siblings on live service
sheets. All 74 exact before/after pixel comparisons pass across five sizes,
alongside all 98 service controller checks. Restoring the old equal-depth
production expressions makes this pixel regression fail (gift offer dynamic
addition), proving the test catches the defect. Compiler outputs now use a
process-private temporary directory to avoid parallel reviewer collisions.
Actual desktop/IME/platform acceptance remains separate and pending.
