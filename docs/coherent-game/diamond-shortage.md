# Platform-aware diamond shortage feedback

Separate follow-up based on immutable chest checkpoint
`7db8e9d0604387dcf6329b7e96938e47f36ece98`.

## Production change

Only a 20-line Warm presentation branch inside the existing
`DataManager:addDiamond` shortage helper is added. It runs after the original
`bIsShowAlert == false` early return and before the untouched legacy AlertView.

- Unsupported platform or missing purchase bridge: “钻石不足，当前平台暂不支持充值购买。”
  with one “知道了” dismiss action. No gift/shop/purchase action is offered.
- Supported platform with bridge: “钻石不足，可查看充值选项。购买结果由平台确认。”
  with “查看充值选项” and “取消”. The first action invokes the original
  `PushGiftView:create():show(999)` in-map or `:show()` at home. It only opens
  the existing options. A local once guard prevents repeated/reentrant routing.
- Uses the existing WarmDialog surface, font, scene ownership and close logic.
  Gift routing still precedes the dialog's close. The scene-owned sheet reuses
  itself when a shortage is requested repeatedly.
- `WARM_PIRATE_V1=false`, the original shortage body/callback, false-alert
  suppression, every arithmetic/write path, return values and success flags
  remain unchanged. No billing bridge call, purchase, grant, save or item
  application was added.

## Verification

- Logic executes the actual method and PurchaseAvailability. Linux/macOS/Windows,
  unknown platform and missing bridge get dismiss-only options. The actual mobile
  constants (iPhone/iPad/Android) retain home/in-map gift routes and once-only
  action calls. False-alert returns before even checking platform availability.
- Native Cocos tests exercise the real WarmDialog with actual MenuItem callbacks
  at 480×800, 540×900, 640×1136 and 720×1280. Checked dismiss/Cancel, repeated
  shortage, rapid/stale and synchronous reentry, original route-before-close
  ordering even through synchronous reentry (the original callback retains its
  sheet until it returns), no profile writes on shortage, and unchanged successful arithmetic.
- The actual DiamondStore constructor and original virtual-item confirmation run
  with zero diamonds at 480×800 and 540×900. Failed purchase closes its original
  confirmation, shows the truthful shortage, returns to the store on dismiss,
  and can reopen/cancel. Rapid callbacks apply zero items and write zero state.
- Real offscreen captures show unsupported and supported sheets. Source
  conservation removes only the explicit new presentation branch plus the prior
  reviewed chest feedback changes; original whole-file bytes and 71-method
  checks remain pinned. Existing chest free/retry/overflow/drag tests pass.
- Every character of the new copy is present in the actual bundled
  CleanVoyageSans-Regular.ttf cmap. The font regression now checks this explicit
  Warm branch against its actual font in addition to preserving the legacy
  coverage check. No shared font file changes.

Evidence is retained under `/workspace/shared/pirate-audit/diamond-shortage` in
this task environment. All role storage is in-memory. Purchase is replaced by
a failure trap, and supported gift routing is observed without entering billing.
No GUI, player profile, external network, charge, publish or deployment occurred.
A native counterfactual proves that returning nil from the repeated-action guard
closes the sheet too early; the guard now returns false to preserve callback order.
Actual desktop pixel acceptance is owned by the independent application reviewer.
