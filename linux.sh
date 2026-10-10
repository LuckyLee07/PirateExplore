#!/usr/bin/env bash
# Native Cocos2d-x/Lua Linux build; no mocks or browser replacement.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="${PIRATE_BUILD_DIR:-$ROOT/build/linux}"
if [[ -n "${PIRATE_RUNTIME:-}" ]]; then
  export PATH="$PIRATE_RUNTIME/usr/bin:$PATH"
  export LD_LIBRARY_PATH="$PIRATE_RUNTIME/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export CPATH="$PIRATE_RUNTIME/usr/include:$PIRATE_RUNTIME/usr/include/x86_64-linux-gnu${CPATH:+:$CPATH}"
  export LIBRARY_PATH="$PIRATE_RUNTIME/usr/lib/x86_64-linux-gnu${LIBRARY_PATH:+:$LIBRARY_PATH}"
  export CMAKE_PREFIX_PATH="$PIRATE_RUNTIME/usr${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
fi
case "${1:-build}" in
  build)
    cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=RelWithDebInfo
    cmake --build "$BUILD" --parallel "${BUILD_JOBS:-4}"
    ;;
  run)
    shift
    # Keep validation saves separate from any existing player profile.
    export XDG_CONFIG_HOME="${PIRATE_SAVE_DIR:-$BUILD/player-data}"
    mkdir -p "$XDG_CONFIG_HOME/PirateExplore"
    exec "$BUILD/bin/PirateExplore" "$@"
    ;;
  *) echo "Usage: $0 {build|run [width height]}" >&2; exit 2 ;;
esac
