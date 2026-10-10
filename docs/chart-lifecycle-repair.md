# Chart renderer lifecycle repair

## Scope

This repair leaves maps, GIDs, economy, saves, and authored images unchanged.

- Fog, grid, and coast programs rebuild in place on the engine's actual context-recreated event, after render-target restoration. Native child nodes retain shader objects and own event lifetime, including maps paused below another scene and maps destroyed before entering.
- RenderTexture cache listeners run even while their owner scene is paused. Destruction unregisters their retained listeners. Background snapshots keep the live FBO usable when Android preserves its context, and only replace the previous cached image after successful readback.
- The existing Android GL-thread pause hook now dispatches the snapshot event. Normal resume does not reset shader IDs; actual context recreation retains the existing nativeInit route.
- Coast masks reapply their linear sampling after restoration. Original tile atlases keep their nearest sampling.
- Four chart blend calls now use this engine's real two-number Lua API. The previous table arguments logged warnings and left defaults unchanged. The intended GL_ONE / GL_ONE_MINUS_SRC_ALPHA values are unchanged.
- Optional shader failures return false rather than aborting. Failed shader/program names are freed, link status is checked in release builds, and GLEW diagnostic callbacks use the callable function pointers. Fog can use its native shader if custom compilation fails.
- Missing optional repainted terrain atlases are checked before cache lookup, avoiding repeated expected-missing-file warnings.

## Reproduce

Build the Linux application normally, then run:

```sh
bash tools/tests/run-adventure-ui-tests.sh
python3 tools/tests/run_chart_lifecycle_native.py
```

For the extracted Linux SDK, set PIRATE_RUNTIME as for linux.sh. PIRATE_BUILD_DIR selects an alternate existing Unix Makefiles build tree. The native lifecycle harness additionally needs EGL development headers/libraries. It writes test outputs only under the build tree and opens no game scene, desktop window, input device, or player save.

The harness runs the real Cocos LuaEngine, event dispatcher, GLProgram, textures and render targets on surfaceless EGL. It compiles the real RenderTexture/TextureCache/Texture2D cache branch with CC_ENABLE_CACHE_TEXTURE_DATA=1 in test-only objects, plus the actual Android nativeOnPause function body with Linux export macros. It does not substitute a mocked event implementation.

Covered cases:

- Preserved-context pause and repeated background notifications preserve live mask pixels and shader handles
- Actual EGL context destruction/recreation preserves mask pixels, restores coast linear filters, and relinks fog/grid/coast shaders
- Active, exited/paused, and re-entered native nodes recover without duplicate callbacks
- Cleanup after pause, repeated cleanup, never-entered direct destruction, and render-target destruction between background and foreground leave no callbacks to disposed nodes
- Real invalid vertex/fragment GLSL and varying-mismatch link failure clear handles without aborting; subsequent valid compilation succeeds
- The production optional-fog fallback and restore fallback use the native shader, and the same retained custom shader can recover on the next successful restore

Expected shader error diagnostics are deliberately produced by the failure tests. Successful runs include native grid-composite, shader-fallback and lifecycle PASS lines and exit zero.

## Limits

This is Linux native source/GL verification, not an Android NDK build, device driver test, or full Director scene-stack/mobile lifecycle acceptance. The supplied checkout has no Android application project. iOS/macOS/Windows application project entries are also absent. Their build and device acceptance remains blocked until original project entries and suitable toolchains are restored. Fresh Linux GUI play remains the separate check for the changed blend call's visible coast appearance.

The legacy particleTexture.png warning is benign: baise.plist contains embedded textureImageData and the engine decodes it when the external filename is absent. Cloud audio-output and remote time-service failures do not establish a local rendering defect.

## Full-scene grid alpha follow-up

Fresh native GUI play caught a compositing error that the earlier isolated test missed: the authored grid PNG retains RGB (225, 251, 243) in its alpha-zero interior. This engine uploads it as straight alpha on Linux. Once the blend call actually used GL_ONE, the old fragment shader added those invisible RGB values over the whole chart.

The grid fragment now normalizes straight-alpha input before premultiplied blending. Texture2D.hasPremultipliedAlpha selects the already-premultiplied branch when appropriate, and the same variant is restored after context loss. The accepted 0.42 ink tint and 0.42 opacity are explicit so the correction preserves the previous low-contrast line RGB rather than brightening the grid.

The replacement pixel test uses the real grid PNG, including transparent interior texels. On sea, pale-sand and forest backgrounds, the corrected output preserves clear pixels exactly and matches the accepted old shader plus its actual GL_SRC_ALPHA default to within one RGB byte. A native Cocos test additionally uses the actual uploaded texture, installed grid shader, and native blend factors, including after repeated context loss. This replaces the old test's artificially pre-multiplied input that concealed the defect. Full-scene cold-start screenshots remain the visual acceptance check.
