#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_PATH="$ROOT_DIR/projects/ios_mac/NewPirate.xcodeproj"
CONFIGURATION="${CONFIGURATION:-Debug}"

usage() {
  cat <<'USAGE'
Usage:
  ./xcode.sh mac
  ./xcode.sh ios-sim
  ./xcode.sh ios-device
  ./xcode.sh open

Environment:
  CONFIGURATION=Debug|Release
  ARCHS=x86_64|arm64
USAGE
}

ACTION="${1:-mac}"

case "$ACTION" in
  -h|--help|help) usage; exit 0 ;;
  mac|ios-sim|ios|ios-device|open) ;;
  *) usage; exit 1 ;;
esac

if [[ ! -f "$PROJECT_PATH/project.pbxproj" ]]; then
  printf 'Apple application project is missing: %s\n' "$PROJECT_PATH" >&2
  printf 'Restore the original projects/ios_mac application project before building. See README.md; this checkout currently provides a Linux build entry only.\n' >&2
  exit 2
fi
if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'Apple build/open actions require macOS and the original Xcode project.\n' >&2
  exit 2
fi
if [[ "$ACTION" != "open" ]] && ! command -v xcodebuild >/dev/null 2>&1; then
  printf 'xcodebuild is unavailable. Install/select Xcode on the Mac before building.\n' >&2
  exit 2
fi

case "$ACTION" in
  mac)
    xcodebuild -quiet \
      -project "$PROJECT_PATH" \
      -scheme "NewPirate Mac" \
      -configuration "$CONFIGURATION" \
      -derivedDataPath "$ROOT_DIR/build/DerivedData/mac" \
      USE_HEADERMAP=NO \
      ARCHS="${ARCHS:-x86_64}" \
      ONLY_ACTIVE_ARCH=NO \
      build
    ;;
  ios-sim|ios)
    xcodebuild -quiet \
      -project "$PROJECT_PATH" \
      -scheme "NewPirate iOS" \
      -configuration "$CONFIGURATION" \
      -sdk iphonesimulator \
      -derivedDataPath "$ROOT_DIR/build/DerivedData/ios-sim" \
      USE_HEADERMAP=NO \
      CODE_SIGNING_ALLOWED=NO \
      ARCHS="${ARCHS:-x86_64}" \
      ONLY_ACTIVE_ARCH=NO \
      build
    ;;
  ios-device)
    xcodebuild -quiet \
      -project "$PROJECT_PATH" \
      -scheme "NewPirate iOS" \
      -configuration "$CONFIGURATION" \
      -sdk iphoneos \
      -destination generic/platform=iOS \
      -derivedDataPath "$ROOT_DIR/build/DerivedData/ios-device" \
      USE_HEADERMAP=NO \
      CODE_SIGNING_ALLOWED=NO \
      ARCHS="${ARCHS:-arm64}" \
      ONLY_ACTIVE_ARCH=NO \
      build
    ;;
  open)
    open "$PROJECT_PATH"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
