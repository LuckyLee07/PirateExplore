# Approved full-scene harbor production assets

The authoritative user-approved composition was 941×1672. These are clean,
unlettered components extracted/generated from that composition:

- `harbor-full.png`: exact-ratio uninterrupted scene; no text, fake counters,
  buttons, roster portraits or UI are embedded. Uniform cover-fit only.
- `materials.png`: transparent painted ink/coral/paper/currency shapes. Runtime
  sprite rectangles are defined in MasterTheme; lettering and hitboxes are native.
- `crew-trio.png`: three separate transparent cells (107 wood-shield helmsman,
  102 assault sailor, 124 ship doctor). Runtime positions use actual selected
  unit IDs and counts. Three 107 units correctly reuse the 107 art three times;
  empty/unillustrated positions have neutral silhouettes and real type labels.

The pale-blue portrait wash reuses the ink texture alpha as a native stencil.
It does not alter or invent a character. Generated source masters and unrelated
exploration variants are not included.

Heading face: `fonts/HarborSerif-Bold.ttf` is a renamed OFL 1.1 Noto Serif CJK Bold
subset with converted TrueType outlines for the legacy renderer; full source
license/copyright notices are in `fonts/HarborSerif-LICENSE.txt`. No absolute
system font path is used at runtime. The subset contains the implemented UI and
all characters from the original resource and soldier data tables. The build
helper accepts those decoded tables via `--extra-text`.

Only approved-home headings/CTA/type labels use the bundled face. Lighter body
text uses installed Noto Serif CJK SC on Linux, Songti SC on Apple platforms,
with the original game font as fallback on other platforms. A missing bundled
heading face falls back in the same way. Mac/iOS appearance has not been tested.

Font platform boundary: the bundled file-path face is selected only by the verified Linux renderer. Apple explicitly uses its Songti SC system-family fallback, because this legacy engine does not register a bundled font automatically. Other targets use the original font. No claim of cross-platform identical typography is made.
