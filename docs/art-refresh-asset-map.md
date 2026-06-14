# Art Refresh Asset Map

Date: 2026-06-14

This document is the Batch 0 output for the near-term art refresh. It maps the
current visual structure, identifies the first assets to repaint, and calls out
integration risks before production art starts.

## Current Baseline

The game is built around an old 640 x 1136 portrait layout.

Key global dimensions:

| Asset | Size | Role |
| --- | ---: | --- |
| `Images/Background/MainBackGround.png` | 640 x 1136 | full-screen base background |
| `Images/UI/TopBg.png` | 640 x 100 | top currency/status shell |
| `Images/UI/TitleBg.png` | 640 x 67 | title bar inside `BaseView` |
| `Images/UI/BottomBg.png` | 640 x 136 | bottom navigation/status shell |
| `Images/MainMenu/di_a.png` | 640 x 170 | bottom center action decoration |
| `Images/UI/TopButtonGroupBg.png` | 640 x 61 | repository category tab background |
| `Images/Background/*.png` | 640 x 440 | per-screen middle background illustration |

Important code owners:

| File | Responsibility |
| --- | --- |
| `bin/res/scripts/LuaClass/MainMenu.lua` | top currency bar, bottom navigation, global `UITopHeight` and `UIBottomHeight` |
| `bin/res/scripts/LuaClass/BaseView.lua` | common screen shell, title bar, middle background, bottom info area, center action button |
| `bin/res/scripts/LuaClass/AlertView.lua` | common modal dialogs and confirm/cancel buttons |
| `bin/res/scripts/LuaClass/Repository.lua` | warehouse tabs and inventory list |
| `bin/res/scripts/LuaClass/MakeMode.lua` | crafting list rows |
| `bin/res/scripts/LuaClass/Expedition.lua` | expedition preparation list rows and set-sail action |
| `bin/res/scripts/LuaClass/FightMode.lua` | ship battle, boarding battle, battle rewards, battle result views |
| `bin/res/scripts/LuaClass/SDButton.lua` | custom button touch behavior based on image content size |
| `bin/res/scripts/LuaClass/DataManager.lua` | global font and UI text colors |

## Resource Inventory

Current image resource counts under `bin/res/assets/Images`:

| Folder | Count | Notes |
| --- | ---: | --- |
| `Icon` | 179 | item, soldier, and functional icons |
| `UI` | 96 | shared frames, bars, tabs, popups, top/bottom shell |
| `Map` | 56 | exploration map and world-map UI |
| `MainMenu` | 34 | bottom navigation and center action buttons |
| `Fight` | 29 | ship battle, battle HUD, chests, HP/skill bars |
| `Boss` | 20 | sea monster and boss portraits |
| `btn` | 20 | shared rectangular buttons |
| `charging` | 20 | monetization/revive UI |
| `DiamondStore` | 16 | store banners and buttons |
| `Plot` | 9 | plot images |
| `Background` | 8 | common screen backgrounds |
| `SevenDayBonus` | 6 | login reward UI |

Lua files with literal image references: 35 files.

## Highest-Frequency Literal References

These are the best candidates for Batch 1 because replacing them improves many
screens at once.

| Asset | Literal references | Current size | Batch 1 action |
| --- | ---: | ---: | --- |
| `Images/btn/ann05_b.png` | 46 | 190 x 64 | repaint in place |
| `Images/btn/ann03_a.png` | 27 | 176 x 61 | repaint in place |
| `Images/UI/tankuang_04.png` | 26 | 64 x 64 | repaint as Scale9-safe panel |
| `Images/btn/ann01_a.png` | 25 | 128 x 59 | repaint in place |
| `Images/btn/ann03_b.png` | 24 | 176 x 61 | repaint in place |
| `Images/btn/ann01_b.png` | 22 | 128 x 59 | repaint in place |
| `Images/UI/cancel_button.png` | 20 | 58 x 58 | repaint in place |
| `Images/btn/ann05_a.png` | 18 | 190 x 64 | repaint in place |
| `Images/UI/dibantiao_02.png` | 18 | 64 x 64 | repaint as Scale9-safe row |
| `Images/UI/xingxing01.png` | 10 | 30 x 30 | repaint in place |
| `Images/UI/tankuang_01.png` | 10 | 572 x 437 | repaint modal shell |
| `Images/UI/DiamondBg.png` | 10 | 53 x 53 | repaint resource chip icon |
| `Images/UI/ButtonSplit.png` | 10 | 7 x 108 | repaint or remove after UI review |

## Batch 1 Drop-In Asset Set

The first production art batch should keep filenames and pixel dimensions stable.
This is the safest way to prove the new style in-game.

### Shared Buttons

| Asset group | Files | Notes |
| --- | --- | --- |
| small action button | `Images/btn/ann01_a.png`, `Images/btn/ann01_b.png` | used by expedition, crafting, build/train/store actions |
| medium action button | `Images/btn/ann03_a.png`, `Images/btn/ann03_b.png` | used by alerts, fight buttons, ranking, rewards |
| wide action button | `Images/btn/ann05_a.png`, `Images/btn/ann05_b.png` | high-frequency sell/debug/store type button |
| top utility button | `Images/btn/ann02_a.png`, `Images/btn/ann02_b.png` | top left/right navigation in `BaseView` |
| cancel/close | `Images/UI/cancel_button.png`, `Images/UI/cancel_button1.png` | modal close and setting style close |

Art direction: wood or coral-red button body, brass rim, simple pressed state.
Avoid neon glow and heavy bevels.

### Shared Panels And Rows

| Asset | Current size | Notes |
| --- | ---: | --- |
| `Images/UI/tankuang_04.png` | 64 x 64 | common Scale9 small panel |
| `Images/UI/dibantiao_02.png` | 64 x 64 | common Scale9 row panel |
| `Images/UI/dibantiao_03.png` | 530 x 108 | larger row panel |
| `Images/UI/tankuang_01.png` | 572 x 437 | common modal |
| `Images/UI/tankuang_03.png` | 578 x 870 | tall modal |
| `Images/UI/MaskBg_1.png` | 100 x 100 | bottom info box Scale9 panel |
| `Images/Fight/dikuang_07.png` | 572 x 664 | fight chest / modal shell |

Art direction: parchment fill, subtle fiber texture, brass or warm-wood corner
accents. Preserve transparent padding and Scale9-stretchable center.

### Top, Bottom, And Title Shell

| Asset | Current size | Notes |
| --- | ---: | --- |
| `Images/UI/TopBg.png` | 640 x 100 | controls `UITopHeight` |
| `Images/UI/BottomBg.png` | 640 x 136 | controls `UIBottomHeight` |
| `Images/UI/TitleBg.png` | 640 x 67 | common screen title |
| `Images/UI/TopDecor.png` | 203 x 25 | title decoration |
| `Images/UI/TopButtonGroupBg.png` | 640 x 61 | repository filter tabs |
| `Images/UI/InfoSplit.png` | 640 x 1 | bottom info separator |

Art direction: lighter sea-blue top shell, parchment title area, brass dividers.
Keep dimensions unchanged during Batch 1.

### Resource Chips And Utility Icons

| Asset group | Files | Notes |
| --- | --- | --- |
| currencies | `Images/UI/CoinBg.png`, `Images/UI/DiamondBg.png`, `Images/UI/ditiao_01.png`, `Images/UI/AddMoneyBtn.png`, `Images/UI/AddMoneyBtn1.png` | top bar and purchase shortcuts |
| steppers | `Images/UI/AddCircleBtn.png`, `Images/UI/AddCircleBtn1.png`, `Images/UI/SubCircleBtn.png`, `Images/UI/SubCircleBtn1.png` | expedition and numeric controls |
| badges | `Images/UI/RedPoint.png`, `Images/UI/num_circlebg.png`, `Images/UI/lock.png`, `Images/UI/xingxing01.png` | notifications, counts, locks, stars |
| tab buttons | `Images/UI/c_quanbu_*`, `Images/UI/c_zhuangbei_*`, `Images/UI/c_ziyuan_*`, `Images/UI/c_suipian_*`, `Images/UI/c_qita_*` | repository filters |

Art direction: simple icon-first shapes. Keep labels readable against parchment.

### Main Menu Action Shell

| Asset group | Files | Notes |
| --- | --- | --- |
| center action | `Images/MainMenu/an_lianj_a.png`, `Images/MainMenu/an_lianj_b.png`, `Images/MainMenu/an_yuanz_a.png`, `Images/MainMenu/an_yuanz_b.png`, `Images/MainMenu/an_zhaom_a.png`, `Images/MainMenu/an_zhaom_b.png`, `Images/MainMenu/an_caiji_a.png`, `Images/MainMenu/an_caiji_b.png` | large center actions |
| side shortcuts | `Images/MainMenu/tianf_a.png`, `Images/MainMenu/tianf_b.png`, `Images/MainMenu/qingb_a.png`, `Images/MainMenu/qingb_b.png` | talent and intel |
| bottom nav | `Images/MainMenu/cangk_*`, `caij_*`, `chuz_*`, `jians_*`, `shic_*`, `zhaom_*`, `zhiz_*` | bottom navigation |
| bottom frame | `Images/MainMenu/di_a.png` | main center decoration |

Art direction: brass circular or shield-like icons with clear silhouettes. Do
not keep the old dark menu-strip feeling.

## Batch 2 Screen-Specific Assets

These should be handled after the shared UI skin is stable.

### Expedition

Key assets:

- `Images/Background/yuanz.png`
- `Images/MainMenu/an_yuanz_a.png`
- `Images/MainMenu/an_yuanz_b.png`
- `Images/MainMenu/w_qih.png`
- `Images/UI/biaoti_long.png`
- `Images/UI/NumberBox.png`
- `Images/UI/AddCircleBtn*.png`
- `Images/UI/SubCircleBtn*.png`
- `Images/btn/ann01_*.png`
- `Images/UI/xingxing01.png`
- `Images/UI/num_circlebg.png`

Code owner: `bin/res/scripts/LuaClass/Expedition.lua`

Notes:

- The current row height is derived from `Images/btn/ann01_a.png`.
- Keep the button dimensions stable in Batch 1 or Expedition layout shifts.
- If the set-sail button becomes visually larger, update layout deliberately in
  Batch 2.

### Repository / Warehouse

Key assets:

- `Images/Background/cangk.png`
- `Images/UI/TopButtonGroupBg.png`
- repository tab assets `Images/UI/c_*`
- `Images/UI/dibantiao_02.png`
- `Images/Icon/*`
- `Images/btn/ann05_*.png`
- common `BaseView` shell assets

Code owner: `bin/res/scripts/LuaClass/Repository.lua`

Notes:

- Item icons are dynamic from CSV (`Images/Icon/` + icon name).
- Do not repaint all item icons in the first pass.
- Reframing old icons inside new item cells is acceptable for Batch 1.

### Crafting / Manufacturing

Key assets:

- `Images/Background/shic.png`
- `Images/UI/dibantiao_02.png`
- dynamic item icons from `Images/Icon/`
- `Images/UI/xingxing01.png`
- `Images/btn/ann01_*.png`

Code owner: `bin/res/scripts/LuaClass/MakeMode.lua`

Notes:

- `MakeMode` uses `cc.TableView` rows and explicit text positions.
- Row panel replacement must keep enough contrast for material requirement text.

## Batch 3 Fight Assets

Fight should be a separate batch because its composition and effects are more
screen-specific than the shared UI skin.

Key assets:

| Asset | Current size | Role |
| --- | ---: | --- |
| `Images/Fight/chuan_04.png` | 640 x 423 | ship war ship body, flipped for enemy |
| `Images/Fight/chuan_01.png` | 640 x 569 | boarding battle ship deck |
| `Images/Fight/chuan_02.png` | 101 x 185 | cannon / unit visual |
| `Images/Fight/chuan_03.png` | 101 x 73 | cannon / unit visual |
| `Images/Fight/xuetiao01.png` | 313 x 23 | HP bar background |
| `Images/Fight/xuetiao02.png` | 313 x 23 | HP bar fill |
| `Images/Fight/jntiao01.png` | 163 x 34 | skill / unit bar normal |
| `Images/Fight/jntiao02.png` | 163 x 34 | skill / unit bar selected/fill |
| `Images/Fight/zdzd_01.png` | 220 x 134 | bottom helm / auto area |
| `Images/Fight/toux_01.png` | 74 x 74 | crew portrait frame |
| `Images/Fight/fightDlg.png` | 330 x 57 | monster dialogue |
| `Images/Fight/baoxiang01.png`, `baoxiang02.png` | 184 x 239 | treasure chest states |

Code owner: `bin/res/scripts/LuaClass/FightMode.lua`

Notes:

- Ship war and boarding war are separate functions: `initShipWarUIScene` and
  `initAboardWarUIScene`.
- Ship war currently uses one large ship asset mirrored vertically for both
  sides. Replacement art must still read correctly when flipped.
- Boarding war uses boss portraits from `Images/Boss/`.
- Effects and buttons should not obscure skill bars or touch areas.

## Missing Literal References

These literal references are present in Lua but were not found under
`bin/res/assets` during the scan:

```text
Images/Fight/progbar_2_bg.png
Images/Fight/weigan.png
Images/Icon/d_1.png
Images/Map/explore_tip_button_bg.png
Images/UI/BigBtn.png
Images/UI/BigBtn1.png
Images/UI/BottomBtn1.png
Images/UI/BottomBtn1_a.png
Images/UI/BottomBtn2_a.png
Images/UI/BuildAlert.png
Images/UI/GatherBtn.png
Images/UI/SettingBtn1.png
Images/UI/test.png
```

Some of these are only in commented code or old branches, but they should be
checked before art replacement starts. `Images/Icon/d_1.png` is used as a
fallback in several places and should either be restored or replaced by an
existing default icon path.

## Integration Risks

### Global Layout Depends On Image Size

`MainMenu.lua` sets `UITopHeight` from `TopBg:getContentSize().height` and
`UIBottomHeight` from `BottomBg:getContentSize().height`.

Rule: keep `TopBg.png` at 640 x 100 and `BottomBg.png` at 640 x 136 in Batch 1.

### Button Touch Area Depends On Image Size

`SDButton` uses the normal image content size as the button content size. If a
replacement button changes dimensions, touch bounds and nearby label positions
change.

Rule: all Batch 1 button replacements must keep current pixel dimensions.

### Scale9 Panels Need Safe Stretch Regions

Several panels are stretched with hard-coded cap insets, especially:

- `Images/UI/dibantiao_02.png`
- `Images/UI/tankuang_04.png`
- `Images/UI/MaskBg_1.png`
- `Images/Fight/dikuang_07.png`

Rule: keep corners and borders readable under the existing Scale9 settings.

### Text Colors Must Change With Light Panels

Current global colors are defined in `DataManager.lua`:

```lua
BaseColor = cc.c3b(215, 199, 165)
WriteColor = cc.c3b(229, 229, 229)
RedColor = cc.c3b(255, 0, 0)
```

These colors were chosen for dark backgrounds. Once panels become parchment
colored, `BaseColor` and `WriteColor` need a small code-side review, or text may
lose contrast.

### Dynamic CSV Icons Cannot Be Fully Audited By Literal Search

Many item and unit icons are loaded dynamically:

- `Images/Icon/` + CSV icon name
- `Images/Boss/` + CSV icon name

Rule: do not try to replace the full icon catalog during Batch 1. Reframe old
icons first, then repaint priority icons in Batch 4.

## Recommended First Production Batch

Start with these assets only:

```text
Images/btn/ann01_a.png
Images/btn/ann01_b.png
Images/btn/ann02_a.png
Images/btn/ann02_b.png
Images/btn/ann03_a.png
Images/btn/ann03_b.png
Images/btn/ann05_a.png
Images/btn/ann05_b.png
Images/UI/tankuang_04.png
Images/UI/dibantiao_02.png
Images/UI/MaskBg_1.png
Images/UI/cancel_button.png
Images/UI/TopBg.png
Images/UI/TitleBg.png
Images/UI/BottomBg.png
Images/UI/TopDecor.png
Images/UI/CoinBg.png
Images/UI/DiamondBg.png
Images/UI/ditiao_01.png
Images/UI/AddMoneyBtn.png
Images/UI/AddMoneyBtn1.png
Images/UI/RedPoint.png
Images/UI/xingxing01.png
Images/UI/num_circlebg.png
Images/MainMenu/di_a.png
```

This set should be enough to test the new parchment/brass/wood UI skin across
the current first visible screens while keeping implementation risk low.

## Batch 0 Status

Completed:

- current image folder inventory
- literal Lua image reference scan
- top-frequency shared asset list
- key code owner map
- missing literal reference list
- Batch 1 starter asset list

Next:

- produce or receive production-ready replacement assets for the first batch
- keep dimensions and filenames stable
- integrate them behind a reversible resource backup or theme folder strategy
- launch iOS simulator and capture before/after screenshots
