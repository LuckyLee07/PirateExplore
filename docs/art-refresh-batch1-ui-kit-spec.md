# Batch 1 UI Kit Production Spec

Date: 2026-06-14

This document defines the production requirements for Batch 1 of the near-term
art refresh.

Batch 1 should refresh the shared UI skin only. It should not change gameplay
logic or screen flow.

## Style Target

**Clean hand-painted nautical UI with parchment, brass, wood, sea-blue, and
coral-red accents.**

The in-game UI should be lighter and cleaner than the old dark teal shell, but
not as complex as the promotional concept art.

## Production Rules

1. Keep every filename unchanged.
2. Keep every pixel dimension unchanged.
3. Keep transparent padding stable where the current asset has transparent
   edges.
4. Keep button normal/pressed pairs visually related.
5. Keep Scale9 assets stretch-safe in the center area.
6. Avoid embedded text in PNG assets unless the old asset is already text-only.
7. Prefer icon and material changes over layout changes.
8. Validate every batch on iOS simulator before moving to screen-specific work.

## Palette

Recommended colors:

| Role | Color |
| --- | --- |
| parchment fill | `#F1DDAF` to `#FFF1C8` |
| parchment shadow | `#9E7242` |
| brass rim | `#C58A2E` to `#F2C45B` |
| dark brass line | `#5B351D` |
| warm wood | `#6F3F22` to `#A96534` |
| sea-blue shell | `#176B7A` to `#2FA8B4` |
| coral primary button | `#C9552E` to `#F07B3D` |
| readable dark text | `#3A2416` |
| readable light text | `#FFF3D2` |

## Group A: Shared Buttons

These are the safest first assets to repaint because they are heavily reused.

| Asset | Size | State | Direction |
| --- | ---: | --- | --- |
| `Images/btn/ann01_a.png` | 128 x 59 | normal | small coral/wood action button |
| `Images/btn/ann01_b.png` | 128 x 59 | pressed | darker inset pressed state |
| `Images/btn/ann02_a.png` | 124 x 53 | normal | compact top utility button |
| `Images/btn/ann02_b.png` | 124 x 53 | pressed | compact top pressed state |
| `Images/btn/ann03_a.png` | 176 x 61 | normal | medium primary button |
| `Images/btn/ann03_b.png` | 176 x 61 | pressed | medium pressed state |
| `Images/btn/ann05_a.png` | 190 x 64 | normal | wide action button |
| `Images/btn/ann05_b.png` | 190 x 64 | pressed | wide pressed state |

Visual requirements:

- brass rim with clean silhouette
- no heavy neon outline
- center area must support Chinese text labels
- pressed state should read without changing touch size

Acceptance:

- button text remains readable at current font sizes
- no text touches rim or corners
- touch bounds still match visible button

## Group B: Panels And Rows

| Asset | Size | Type | Direction |
| --- | ---: | --- | --- |
| `Images/UI/tankuang_04.png` | 64 x 64 | Scale9 panel | parchment small panel with brass corner accents |
| `Images/UI/dibantiao_02.png` | 64 x 64 | Scale9 row | parchment row cell, subtle border |
| `Images/UI/MaskBg_1.png` | 100 x 100 | Scale9 info panel | translucent parchment or pale sea-blue info box |
| `Images/UI/tankuang_01.png` | 572 x 437 | modal | main parchment modal shell |
| `Images/UI/tankuang_03.png` | 578 x 870 | modal | tall parchment modal shell |
| `Images/Fight/dikuang_07.png` | 572 x 664 | modal | battle chest/reward modal shell |

Scale9 requirements:

- keep corners visually stable
- center should be low-texture enough for labels
- avoid strong ornamental details in stretch area
- transparent outer pixels should remain transparent

Acceptance:

- panels stretch without visible warped ornaments
- light panels still have readable text after `DataManager.lua` color tuning

## Group C: Global Shell

| Asset | Size | Direction |
| --- | ---: | --- |
| `Images/UI/TopBg.png` | 640 x 100 | cleaner sea-blue top shell with reduced skull/menu weight |
| `Images/UI/BottomBg.png` | 640 x 136 | wood/brass bottom nav shell, lighter than current |
| `Images/UI/TitleBg.png` | 640 x 67 | parchment/brass title strip |
| `Images/UI/TopDecor.png` | 203 x 25 | small brass nautical divider |
| `Images/UI/TopButtonGroupBg.png` | 640 x 61 | repository tab strip |
| `Images/UI/InfoSplit.png` | 640 x 1 | subtle brass or shadow divider |
| `Images/MainMenu/di_a.png` | 640 x 170 | center action base, wood/brass compass motif |

Implementation warning:

- `TopBg.png` height controls `UITopHeight`.
- `BottomBg.png` height controls `UIBottomHeight`.
- Do not change these sizes in Batch 1.

Acceptance:

- top and bottom chrome look lighter
- screen safe area still works
- no existing button shifts unexpectedly

## Group D: Resource And Utility Icons

| Asset | Size | Direction |
| --- | ---: | --- |
| `Images/UI/CoinBg.png` | 53 x 53 | gold coin icon with brass frame |
| `Images/UI/DiamondBg.png` | 53 x 53 | blue gem icon with brass frame |
| `Images/UI/ditiao_01.png` | 163 x 37 | compact resource chip backing |
| `Images/UI/AddMoneyBtn.png` | 48 x 48 | plus button normal |
| `Images/UI/AddMoneyBtn1.png` | 48 x 48 | plus button pressed |
| `Images/UI/RedPoint.png` | 24 x 24 | coral notification dot |
| `Images/UI/xingxing01.png` | 30 x 30 | brass/gold star marker |
| `Images/UI/num_circlebg.png` | 22 x 22 | small count badge |
| `Images/UI/cancel_button.png` | 58 x 58 | clean close button |
| `Images/UI/cancel_button1.png` | 58 x 58 | alternate close button |

Acceptance:

- icons are readable at native size
- resource chips do not feel like monetization-first UI
- notification red dot remains obvious but not harsh

## Group E: Expedition Steppers

| Asset | Size | Direction |
| --- | ---: | --- |
| `Images/UI/AddCircleBtn.png` | 50 x 50 | brass plus normal |
| `Images/UI/AddCircleBtn1.png` | 50 x 50 | brass plus pressed |
| `Images/UI/SubCircleBtn.png` | 50 x 50 | brass minus normal |
| `Images/UI/SubCircleBtn1.png` | 50 x 50 | brass minus pressed |
| `Images/UI/NumberBox.png` | 74 x 28 | parchment number capsule |

Acceptance:

- plus/minus symbols are clear without text
- current long-press behavior remains obvious enough
- row density remains unchanged

## Group F: Repository Tabs

| Asset set | Size | Direction |
| --- | ---: | --- |
| `Images/UI/c_quanbu_a.png`, `c_quanbu_b.png` | 116 x 38 | selected/unselected tab |
| `Images/UI/c_zhuangbei_a.png`, `c_zhuangbei_b.png` | 116 x 38 | selected/unselected tab |
| `Images/UI/c_ziyuan_a.png`, `c_ziyuan_b.png` | 116 x 38 | selected/unselected tab |
| `Images/UI/c_suipian_a.png`, `c_suipian_b.png` | 116 x 38 | selected/unselected tab |
| `Images/UI/c_qita_a.png`, `c_qita_b.png` | 116 x 38 | selected/unselected tab |

Recommendation:

- In Batch 1, keep these as text-based tabs if the existing screen still relies
  on text labels.
- In a later pass, convert to icon + text tabs if the layout is updated.

Acceptance:

- selected state is clear
- old tab strip no longer feels dark and metallic

## Text Color Adjustment

Batch 1 will likely need a small code-side color change because the new panels
are lighter.

Current colors:

```lua
BaseColor = cc.c3b(215, 199, 165)
WriteColor = cc.c3b(229, 229, 229)
RedColor = cc.c3b(255, 0, 0)
```

Recommended direction:

- `BaseColor`: dark warm brown for parchment body text
- `WriteColor`: light cream for text on dark/coral buttons
- add a separate dark panel text color later if needed

Do not change colors globally until the first replacement assets are visible
in-game. The current screens still depend on light text over dark backgrounds.

## Batch 1 Verification Screens

After assets are integrated, verify at least:

1. Warehouse / repository screen
2. Expedition preparation screen
3. Crafting / manufacturing screen
4. Any common alert dialog
5. Top currency bar and bottom navigation on the default first screen

Verification requirements:

- no missing image logs
- no button size shifts
- no unreadable white text on parchment
- no touch target mismatch
- no title or count text overlap
- iOS simulator launches successfully

## Do Not Include In Batch 1

- ship battle art replacement
- boss or monster repaint
- full item icon catalog repaint
- App Store screenshots
- harbor scene redesign
- world map redesign
- gameplay or economy changes
