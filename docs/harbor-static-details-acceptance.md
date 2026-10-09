# Harbor static-detail polish

Starting local commit: `dacb9a8288826ae5f32d84108999251784795c99` (same tree as the published approved-master version).

Only three static visual elements were polished: currency icons, the fixed home title/compass artwork, and the coral navigation selection stroke. The four transparent production crops are documented in `Images/UI/Adventure/Master/Details/README.md`. The original atlas is retained separately and was not overwritten. The title artwork is fixed text; monetary values, plus controls, selection state, all other game text and button interactions remain native.

MainMenu's fallback retains the original native icons/title/compass/brush if files are missing or cannot be decoded. When title art loads, the previous visible label and compass are hidden to avoid duplication. Uniform scale preserves the gem's non-square proportions. Only these detail textures explicitly use bilinear filtering. Lanczos-prefiltered production crops avoid aliasing at phone size without unsupported non-power-of-two mipmaps; the old engine's mipmap method asserts power-of-two dimensions.

## Checked

- Actual native game at 540×960 and 480×800: clean RGBA compositing, no opaque black rectangle/glow, readable static title, unchanged whole-page layout.
- Original gold-plus control opens its existing purchase panel; it was closed without purchasing. Voyage and Base navigation still switch correctly, with the brush reflecting selection.
- Dynamic money/diamond labels and their event updates, purchase/route/guide callbacks, global font choices, 59×59 logical plus targets and four 160×118 logical navigation targets are unchanged.
- `static_home_art_regression.lua` covers missing assets, synthetic assets, decode failure and actual packaged PNGs at both logical screen heights; repeated home appearance does not accumulate title/compass nodes.
- The existing full Lua UI suite and `git diff --check` pass. Final native logs have no Lua error or traceback; historical audio/time-sync warnings are unchanged.
- Independent code-scope review passed. Actual GUI was verified separately rather than inferred from mocks.
- QA used a separate profile. The original chapter-six profile's eight hashes remain unchanged. No resource grant, purchase, save-structure edit, economic change, or chapter replay occurred.

Gold shown in before/after screenshots can differ because the independent game's original timers continue running; screenshots are not presented as identical-value comparisons. Previous gameplay/platform acceptance limits still apply. This document does not imply remote publication or merge.
