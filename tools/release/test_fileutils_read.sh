#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/newpirate-fileutils.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

clang++ \
  -std=c++11 \
  -Wall -Wextra -Werror \
  -fsanitize=address,undefined \
  -fno-omit-frame-pointer \
  -I "$ROOT/src/engine/cocos2d-x/cocos/2d/platform" \
  "$ROOT/tools/release/test_fileutils_read.cpp" \
  -o "$BUILD_DIR/test_fileutils_read"

ASAN_OPTIONS=detect_leaks=0 UBSAN_OPTIONS=halt_on_error=1 \
  "$BUILD_DIR/test_fileutils_read"
