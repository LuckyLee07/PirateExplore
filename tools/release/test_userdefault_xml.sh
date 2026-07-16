#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/newpirate-userdefault-xml.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

clang++ \
  -std=c++11 \
  -Wall -Wextra -Werror \
  -fsanitize=address,undefined \
  -fno-omit-frame-pointer \
  -DCC_TARGET_OS_MAC \
  -I "$ROOT/src/engine/cocos2d-x/cocos/2d" \
  -I "$ROOT/src/engine/cocos2d-x/cocos/base" \
  -I "$ROOT/src/engine/cocos2d-x/cocos/2d/platform/mac" \
  -I "$ROOT/src/engine/cocos2d-x/external/tinyxml2" \
  "$ROOT/tools/release/test_userdefault_xml.cpp" \
  "$ROOT/src/engine/cocos2d-x/external/tinyxml2/tinyxml2.cpp" \
  -o "$BUILD_DIR/test_userdefault_xml"

ASAN_OPTIONS=detect_leaks=0 UBSAN_OPTIONS=halt_on_error=1 \
  "$BUILD_DIR/test_userdefault_xml"
