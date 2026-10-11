# Matching native Linux production runner

Clean CMake RelWithDebInfo build completed from recovered Stage 1 native source f9691e6cc593e7a3320611cf0da86f1bf74ceb96. All engine and application objects and archives were rebuilt in this separate directory. No artifacts from PirateExplore-initial were reused. All 2,235 native/build input files were unchanged across compilation.

Installed runner: ../clean-first-voyage-runtime/bin/PirateExplore

SHA-256: 9e292e313ea60446e3db75d0f1643a2d03b00195ad837deb70db271a3ec108c3

The build runner and installed copy are byte-identical. Dynamic dependencies resolve under ../linux-runtime/env.sh, including this directory's newly built libkazmath. No dependencies point to the initial checkout. Both Resources and engine-scripts in the runtime remain linked to the clean-first-voyage integration checkout.

## Verification

- Full production build and subsequent no-op build pass.
- Native atomic-save helper passes replacement, open/write/flush/rename failure, stale temporary file, and retry checks.
- Real Record native test passes encode/decode, atomic replacement, cold reader, failure preservation, real Lua boolean binding, baseline byte equality, and both-direction legacy format compatibility.
- Native binding/render source checks pass all eight TMX flag combinations and invalid input; repeated DrawTriangle submits initialized vertices.
- Build-entry preflight passes; destructive developer menu remains disabled.
- No game GUI launched; no player profile opened. Graphical/EGL acceptance belongs to the separate QA task.

## Reproduction

From the restored repository, install the Linux prerequisites listed in README and run `PIRATE_BUILD_DIR=/absolute/empty/build ./linux.sh build`. Four jobs is the recorded default. The native build uses CMake RelWithDebInfo. The original cloud-only `rebuild-native.sh` and detailed build logs remain QA provenance outside this source package; the portable repository build entry is `linux.sh`.

The included build-provenance.json records compiler, inputs, commands and outcome. Detailed cloud QA records (native-source-sha256-before.txt, native-source-sha256-after.txt, binary-dynamic-section.txt, runtime-dependencies.log, configure.log, build.log, rebuild-noop.log, native-source-checks.log and record-atomic-native.log) are external build-workspace records, not adjacent files or required source inputs.

An isolated Lua 5.1.4 CLI built against the matching engine library is available at tests/lua-ui-tests relative to the external native build directory for regression checks; it is not bundled in the source ZIP.
