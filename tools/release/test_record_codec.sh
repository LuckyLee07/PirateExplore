#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/newpirate-record-codec.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

clang++ \
  -std=c++11 \
  -Wall -Wextra \
  -fsanitize=address,undefined \
  -fno-omit-frame-pointer \
  -I "$ROOT/src/NewPirate/common/UtilTools" \
  "$ROOT/tools/release/test_record_codec.cpp" \
  "$ROOT/src/NewPirate/common/UtilTools/RecordCodec.cpp" \
  "$ROOT/src/NewPirate/common/UtilTools/LZSS.cpp" \
  -o "$BUILD_DIR/test_record_codec"

ASAN_OPTIONS=detect_leaks=0 UBSAN_OPTIONS=halt_on_error=1 \
  "$BUILD_DIR/test_record_codec" "$@"
