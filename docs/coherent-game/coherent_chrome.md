# Shared business, dialog and combat chrome

The enabled clean presentation uses the shared WarmTheme cream/navy/teal palette
and CleanVoyageSans font. The explicit `WARM_PIRATE_V1=false` path retains the
legacy presentation.

## Presentation changes

- Business headers and currency controls use native cream/white panels, navy text,
  teal add controls, and simplified native currency symbols. Header dimensions,
  currencies, purchase callbacks, hidden guide targets and navigation are intact.
- Management sheets use a continuous quiet cream field, an eight-point maximum
  corner radius and teal primary actions. Original table/footer geometry and
  SDButton callback, long-press, selected/disabled and red-dot state are retained.
- Unknown caller-owned white dialog text stays on dark navy surfaces. Normal and
  selected surfaces retain contrast greater than 7:1. Only explicit paper callers
  receive light surfaces. Modal geometry and all confirmation/dismissal flows stay
  unchanged.
- Combat uses the clean voyage's existing sunny caustic sea. Native navy caption,
  status and bottom-action backing replace broad brush framing. Actor/chest assets,
  HP source geometry, timing, fight state and reward rules are unchanged.

## Verification

Passed with Lua 5.1:

- `management_ui_regression.lua`
- `dialog_theme_regression.lua`
- `home_master_regression.lua`
- `warm_business_regression.lua` (updated appearance assertions; original action
  checks retained, plus sans typography and white-on-navy contrast assertions)
- `warm_navigation_settings_regression.lua`
- `coherent_chrome_regression.lua`
- `coherent_chrome_navigation_regression.lua`

Passed with the real Cocos/EGL harness:

- `warm_business_native.lua`: 640×960, 640×1067 and 640×1136 component geometry,
  fonts, action state/listeners, repeat/cancel/confirm/manual close, opt-out and
  zero gameplay/save writes.
- `coherent_chrome_native.lua`: same three viewports; real CJK font instantiation,
  encounter text width, sunny sea, caption/status/HP/dialog bounds, legacy opt-out,
  and unchanged actor/reward asset selection.

These are fixture and native-component checks, not screenshot review, a running
full-game GUI acceptance pass, or mobile-device acceptance. No game instance was
restarted and no player profile, purchase or publication was performed.
