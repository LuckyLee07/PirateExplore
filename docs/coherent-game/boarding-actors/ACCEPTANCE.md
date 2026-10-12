# Four-identity grounded boarding checkpoint

Base: `6b3ed5b2765ee63812765cd7fd8db118602cf4a4` (clean battle component).
This local branch adds presentation only. Desktop motion/interaction and full
game visual acceptance remain separate gates. No publication or player-profile
write is part of this checkpoint.

## Exact coverage and presentation

| CSV ID | Exact identity | Accepted source icon guard | Body |
| --- | --- | --- | --- |
| 100 | 低级船员 | `j_1.png` or exact ResourceTheme `B/crew-100.png` | Tricorn, beard, cream shirt, brown vest/strap, blue trousers, cutlass |
| 101 | 水手 | `j_2.png` or exact ResourceTheme `B/crew-101.png` | Bald, bearded, bare chest, brown strap, blue trousers, empty hands |
| 10001 | 骷髅兵 | `g_317.png` | Ivory skeleton, orange-red eye, navy clothing, cutlass |
| 10083 | 亡灵士兵 | `g_303.png` | Dark hood/armor, cyan eyes, boots, saber |

The full row ID, icon and name must all match. A shared texture alias is not a
semantic identity: `g_303.png` also names unrelated pirates/captains/wizards;
`g_317.png` also names other skeletons and unrelated creatures. No blanket alias
replacement is made. Unmapped players retain their original status portrait;
unmapped enemies retain their bounded exact original portrait. Therefore this
does not provide standing bodies for every possible team or profession.

Bodies stand on explicit deck points with separate contact shadows. Actual
fighter array entries determine the 1–6 player body slots, with two rows for a
full team. A one-member team does not receive decorative extra people. The
existing status cards remain indexed by the same fighter entries. One/six/ten
ship cannons continue to equal the actual respective team counts.

V2 art was regenerated with broader clean color planes, sturdier limbs and
mildly enlarged heads. The source illustrations face right; players retain
that orientation and enemies mirror once, making face and blade direction
point toward the player side. Mirroring is a presentation choice, not a claim
about historically specified handedness. Source PNG bytes are unchanged.

## Interaction and timing evidence

`coherent_boarding_bodies_native.lua` loads the production constructors and
native Cocos actions with isolated in-memory game state. At 480×800, 540×900,
640×960, 640×1067 and 720×1280 it checks:

- Exact four ID/icon/name mappings, unchanged source status textures and
  truthful missing-body fallback, including a different `g_303` identity.
- Full 1/2/6 teams, measured visible heights, explicit deck foot anchors and
  coincident contact shadows. Original health/death/heal tint reaches the
  mapped body and its original status portrait.
- Player and enemy approach opposite directions. Body art and its shadow move
  12 logical pixels forward at 0.1 s and return exactly at 0.2 s. Repeated
  presentation input cannot accumulate displacement.
- The actual unchanged attack method, original skill animation, damage value
  and enemy HP update ownership. Native source conservation still checks 71
  unchanged complete methods, exact food/paid/manual callback bytes and order,
  chest/reward code, and the shared CombatTheme prefix.
- Complete six-unit roster and both bottom MenuItem bounds. Actual native
  GLView touches invoke food healing/one inventory decrement, repeated-input
  cooldown protection, the exact 5-diamond deduction and original paid callback,
  and prevention of a second charge after disabling the paid item.

The native renderer captures the whole 480×800 view, with no crop, scrolling,
camera reposition or image editing. It captures the idle complete roster before
input, then another full frame after food and paid touches. Pixel checks require
both real cream and teal button regions in each frame. Top-left PNG hit regions:
paid **x27–177, y734.75–779.75**; food **x189–447, y734.75–779.75**. The full dock
ends at y788, leaving 12 pixels below. All six cards end above the dock.

Native test commands (Linux SDK/build are environment-specific):

```sh
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
export PIRATE_BUILD_DIR=/workspace/scratch/79976da795e7/PirateExplore-shutdown-fix/build/linux
export LUA_BIN=$PIRATE_BUILD_DIR/tests/lua-ui-tests
export WARM_NATIVE_BIN=$PIRATE_BUILD_DIR/tests/tutorial-log-native
$LUA_BIN tools/tests/coherent_battle_stage_regression.lua
$WARM_NATIVE_BIN tools/tests/coherent_boarding_bodies_native.lua
python3 tools/tests/coherent_battle_stage_render.py
./tools/tests/run-coherent-game-tests.sh
```

Final checkpoint results: the complete coherent-game aggregate passes, including
Warm, focused native, legacy opt-out, shutdown/lifecycle, clean map and fonts.
The body fixture passes **1,002** native assertions; the retained battle fixture
passes **1,708**. Combined real rendering/input and six-unit full-viewport pixel
checks pass, as does rejection of the counterfactual old 3× boarding pulse.
Source PNG hashes match the generated originals exactly. These are Linux
surfaceless component results and do not replace the desktop gate below.

## Limits and next gate

The staging/semantic direction is approved for the next desktop review, not a
claim of finished whole-game art. Existing status portraits, skill/particle
textures and entry curtain are unchanged. At small sizes, image minification
and compact text still require pixel judgment. Body response is a short native
translation, not skeletal/sprite-sheet animation. Full encounter transitions,
motion, interruptions and real-window food/paid/manual input remain for the
independent GUI reviewer on a disposable, precisely manifested source variant.
No Mac/mobile runtime or project acceptance is claimed.
