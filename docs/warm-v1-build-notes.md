# Build and try Warm v1

## Source patch

The warm changes apply to the public C gameplay-redesign tree
`68c32eed61cf69f90fa1175ab6944deeed426021`. Verified public branch: `codex/gameplay-redesign-v1`, commit
`57c5c14c25bddce268c138f003d44166f3495d94`. Stop if your branch has newer changes;
do not reset or overwrite them. The local preparation commit was
`c1326f7d`, but that local hash need not exist in your repository. Use the matching
public C checkout, check its tree, and apply the binary-safe patch on a new branch:

```sh
git rev-parse HEAD^{tree}  # must match the tree above
git switch -c preview/warm-v1
git apply --check warm-v1.patch
git apply warm-v1.patch
```

The patch includes layered PNG artwork and the updated licensed heading font.
It does not include a player profile, credentials, build output, or QA saves.
Do not apply over uncommitted changes. Existing A/B/C branches are unchanged.

## Linux

Follow the repository README prerequisites, then:

```sh
./linux.sh build
PIRATE_SAVE_DIR="$PWD/build/warm-v1-preview" ./linux.sh run 480 800
```

The explicit save directory isolates this preview. A clean profile starts with
the existing opening story. Select one crew member and food in preparation,
then sail using the original fog chart. A new voyage that resolves the wreck
and returns safely earns the chart memorial; collection allows explicit display.
Real cargo upgrade still needs the forge and its original recipe.

See [native acceptance](warm-v1-native-acceptance.md) and
[test runner](warm-v1-tests.md) for what was actually verified.

## Mac: blocked by missing original application project

This reconstructed checkout lacks `projects/ios_mac/NewPirate.xcodeproj`;
that is a limitation of this checkout, not evidence that your existing playable
Mac project is missing. The Lua/art changes can be reused in that existing
project while preserving its app project, resources wiring and save location.
The supplied patch does not remove or replace your Apple application project.

If your existing checkout already has that original project and its configured
Xcode toolchain, the existing wrapper commands are:

```sh
./xcode.sh open
./xcode.sh mac
```

The wrapper selects `NewPirate Mac` and defaults to x86_64; compatibility with
Apple Silicon or a particular Xcode release is not verified. In Xcode choose
that application's Mac scheme and Run after resolving its original dependencies.
Do not interpret the commands as a successful Mac build. You do not need to
recreate your working project to inspect or apply the Lua/resource changes. Mac/iOS signing and distribution were not performed.

## Scope

Read the [30-screen coverage map](warm-v1-screen-coverage.md). Native home,
preparation, crew, upgrades, memorial display and logs are implemented around
the existing game; other concepts have preserved mechanics or explicit gaps.
