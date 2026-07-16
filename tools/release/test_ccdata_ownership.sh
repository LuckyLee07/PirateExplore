#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/newpirate-ccdata.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

clang++ \
  -std=c++11 \
  -Wall -Wextra \
  -Wno-self-assign-overloaded -Wno-self-move \
  -fsanitize=address,undefined \
  -fno-omit-frame-pointer \
  -DCC_TARGET_OS_MAC \
  -I "$ROOT/src/engine/cocos2d-x/cocos" \
  -I "$ROOT/src/engine/cocos2d-x/cocos/base" \
  -I "$ROOT/src/engine/cocos2d-x/cocos/2d" \
  -I "$ROOT/src/engine/cocos2d-x/cocos/2d/platform/mac" \
  "$ROOT/tools/release/test_ccdata_ownership.cpp" \
  "$ROOT/src/engine/cocos2d-x/cocos/base/CCData.cpp" \
  -o "$BUILD_DIR/test_ccdata_ownership"

ASAN_OPTIONS=detect_leaks=0 UBSAN_OPTIONS=halt_on_error=1 \
  "$BUILD_DIR/test_ccdata_ownership"
