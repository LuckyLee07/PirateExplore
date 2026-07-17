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
  ./xcode.sh ios-archive
  ./xcode.sh open

Environment:
  CONFIGURATION=Debug|Release
  ARCHS=x86_64|arm64 (iOS Simulator defaults to the host architecture)
  ARCHIVE_PATH=/path/to/NewPirate.xcarchive
  CODE_SIGNING_ALLOWED=NO|YES (ios-archive defaults to NO)
  NEWPIRATE_CANDIDATE_ID=development|<version-build-candidate>
  NEWPIRATE_SOURCE_COMMIT=<Git SHA> (defaults to HEAD or HEAD-dirty)
USAGE
}

ACTION="${1:-mac}"

resolve_source_commit() {
  if [[ -n "${NEWPIRATE_SOURCE_COMMIT:-}" ]]; then
    echo "$NEWPIRATE_SOURCE_COMMIT"
    return
  fi
  local commit
  if ! commit="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null)"; then
    echo "unversioned"
    return
  fi
  if ! git -C "$ROOT_DIR" diff --quiet --ignore-submodules -- \
      || ! git -C "$ROOT_DIR" diff --cached --quiet --ignore-submodules --; then
    commit="${commit}-dirty"
  fi
  echo "$commit"
}

NEWPIRATE_SOURCE_COMMIT="$(resolve_source_commit)"
NEWPIRATE_CANDIDATE_ID="${NEWPIRATE_CANDIDATE_ID:-development}"
IOS_PROVENANCE_SETTINGS=(
  "NEWPIRATE_SOURCE_COMMIT=$NEWPIRATE_SOURCE_COMMIT"
  "NEWPIRATE_CANDIDATE_ID=$NEWPIRATE_CANDIDATE_ID"
)

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
      IPHONEOS_DEPLOYMENT_TARGET=12.0 \
      ARCHS="${ARCHS:-$(uname -m)}" \
      ONLY_ACTIVE_ARCH=NO \
      "${IOS_PROVENANCE_SETTINGS[@]}" \
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
      IPHONEOS_DEPLOYMENT_TARGET=12.0 \
      ARCHS="${ARCHS:-arm64}" \
      ONLY_ACTIVE_ARCH=NO \
      "${IOS_PROVENANCE_SETTINGS[@]}" \
      build
    ;;
  ios-archive)
    ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/archives/NewPirate.xcarchive}"
    if [[ -e "$ARCHIVE_PATH" ]]; then
      echo "Archive already exists: $ARCHIVE_PATH" >&2
      echo "Remove it or set ARCHIVE_PATH to a new location before retrying." >&2
      exit 2
    fi
    xcodebuild -quiet \
      -project "$PROJECT_PATH" \
      -scheme "NewPirate iOS" \
      -configuration Release \
      -sdk iphoneos \
      -destination generic/platform=iOS \
      -archivePath "$ARCHIVE_PATH" \
      -derivedDataPath "$ROOT_DIR/build/DerivedData/ios-device" \
      USE_HEADERMAP=NO \
      CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}" \
      IPHONEOS_DEPLOYMENT_TARGET=12.0 \
      ARCHS="${ARCHS:-arm64}" \
      ONLY_ACTIVE_ARCH=NO \
      "${IOS_PROVENANCE_SETTINGS[@]}" \
      archive
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
