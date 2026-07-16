#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/newpirate-texture-atlas.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

clang++ \
  -std=c++11 \
  -Wall -Wextra -Werror \
  -fsanitize=address,undefined \
  -fno-omit-frame-pointer \
  -I "$ROOT/src/engine/cocos2d-x/cocos/2d" \
  "$ROOT/tools/release/test_texture_atlas_allocation.cpp" \
  -o "$BUILD_DIR/test_texture_atlas_allocation"

ASAN_OPTIONS=detect_leaks=0 UBSAN_OPTIONS=halt_on_error=1 \
  "$BUILD_DIR/test_texture_atlas_allocation"
