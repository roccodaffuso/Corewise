#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
set -euo pipefail

MODE="${1:-preview}"
if [[ "$MODE" == "--help" || "$MODE" == "-h" ]]; then
  MODE="help"
else
  shift || true
fi

APP_NAME="Corewise"
BUNDLE_ID="dev.corewise.Corewise"
MIN_SYSTEM_VERSION="14.0"
APP_VERSION="${COREWISE_VERSION:-0.1.0}"
BUILD_NUMBER="${COREWISE_BUILD_NUMBER:-2}"
NOTARY_PROFILE="${COREWISE_NOTARY_PROFILE:-}"
DEVELOPER_IDENTITY="${COREWISE_DEVELOPER_IDENTITY:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist/releases"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/corewise-release.XXXXXX")"
APP_BUNDLE="$STAGING_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
DMG_ROOT="$STAGING_DIR/dmg"
MOUNT_DIR="$STAGING_DIR/mount"
MOUNTED=0

usage() {
  cat <<'USAGE'
usage: script/package_release.sh <preview|release> [options]

Modes:
  preview  Build a universal Developer ID-signed DMG without notarizing it.
  release  Build, sign, notarize, staple, and verify a public DMG.

Options:
  --version VERSION         Bundle version in numeric A.B.C form.
  --build NUMBER            Positive integer bundle build number.
  --notary-profile PROFILE  Keychain profile created with notarytool.
  -h, --help                Show this help.

Environment equivalents:
  COREWISE_VERSION
  COREWISE_BUILD_NUMBER
  COREWISE_DEVELOPER_IDENTITY
  COREWISE_NOTARY_PROFILE
USAGE
}

cleanup() {
  if [[ "$MOUNTED" == "1" ]]; then
    /usr/bin/hdiutil detach "$MOUNT_DIR" -quiet || true
  fi
  /bin/rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      [[ $# -ge 2 ]] || fail "--version requires a value"
      APP_VERSION="$2"
      shift 2
      ;;
    --build)
      [[ $# -ge 2 ]] || fail "--build requires a value"
      BUILD_NUMBER="$2"
      shift 2
      ;;
    --notary-profile)
      [[ $# -ge 2 ]] || fail "--notary-profile requires a value"
      NOTARY_PROFILE="$2"
      shift 2
      ;;
    -h|--help)
      MODE="help"
      shift
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

if [[ "$MODE" == "help" ]]; then
  usage
  exit 0
fi

[[ "$MODE" == "preview" || "$MODE" == "release" ]] || {
  usage >&2
  fail "mode must be preview or release"
}

[[ "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "version must use numeric A.B.C form"
[[ "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]] || fail "build number must be a positive integer"

if [[ "$MODE" == "release" && -z "$NOTARY_PROFILE" ]]; then
  fail "release mode requires --notary-profile or COREWISE_NOTARY_PROFILE"
fi

if [[ -z "$DEVELOPER_IDENTITY" ]]; then
  DEVELOPER_IDENTITY="$(/usr/bin/security find-identity -v -p codesigning | /usr/bin/awk -F'"' '/Developer ID Application:/ { print $2; exit }')"
fi
[[ -n "$DEVELOPER_IDENTITY" ]] || fail "a Developer ID Application identity is required"

printf 'Building Corewise %s (%s) for arm64…\n' "$APP_VERSION" "$BUILD_NUMBER"
swift build -c release --arch arm64
ARM64_BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"

printf 'Building Corewise %s (%s) for x86_64…\n' "$APP_VERSION" "$BUILD_NUMBER"
swift build -c release --arch x86_64
X86_64_BIN_DIR="$(swift build -c release --arch x86_64 --show-bin-path)"

[[ -x "$ARM64_BIN_DIR/$APP_NAME" ]] || fail "arm64 executable was not produced"
[[ -x "$X86_64_BIN_DIR/$APP_NAME" ]] || fail "x86_64 executable was not produced"
[[ -d "$ARM64_BIN_DIR/Corewise_Corewise.bundle" ]] || fail "resource bundle was not produced"

/bin/mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$DMG_ROOT" "$DIST_DIR"
/usr/bin/lipo -create \
  "$ARM64_BIN_DIR/$APP_NAME" \
  "$X86_64_BIN_DIR/$APP_NAME" \
  -output "$APP_BINARY"
/bin/chmod +x "$APP_BINARY"
/usr/bin/ditto "$ARM64_BIN_DIR/Corewise_Corewise.bundle" "$APP_RESOURCES"
/bin/cp "$ROOT_DIR/LICENSE" "$APP_RESOURCES/LICENSE.txt"

/usr/bin/plutil -create xml1 "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleDevelopmentRegion -string en "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleDisplayName -string "$APP_NAME" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleExecutable -string "$APP_NAME" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleIconFile -string Corewise.icns "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleIdentifier -string "$BUNDLE_ID" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleName -string "$APP_NAME" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundlePackageType -string APPL "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleShortVersionString -string "$APP_VERSION" "$INFO_PLIST"
/usr/bin/plutil -insert CFBundleVersion -string "$BUILD_NUMBER" "$INFO_PLIST"
/usr/bin/plutil -insert LSApplicationCategoryType -string public.app-category.utilities "$INFO_PLIST"
/usr/bin/plutil -insert LSMinimumSystemVersion -string "$MIN_SYSTEM_VERSION" "$INFO_PLIST"
/usr/bin/plutil -insert NSHumanReadableCopyright -string "Copyright © 2026 Rocco D’Affuso" "$INFO_PLIST"
/usr/bin/plutil -insert NSHighResolutionCapable -bool true "$INFO_PLIST"
/usr/bin/plutil -insert NSPrincipalClass -string NSApplication "$INFO_PLIST"
/usr/bin/plutil -lint "$INFO_PLIST"

ARCHS="$(/usr/bin/lipo -archs "$APP_BINARY")"
[[ "$ARCHS" == *arm64* && "$ARCHS" == *x86_64* ]] || fail "universal executable is missing an architecture: $ARCHS"

/usr/bin/xattr -cr "$APP_BUNDLE"
/usr/bin/codesign \
  --force \
  --options runtime \
  --timestamp \
  --sign "$DEVELOPER_IDENTITY" \
  --identifier "$BUNDLE_ID" \
  "$APP_BINARY"
/usr/bin/codesign \
  --force \
  --options runtime \
  --timestamp \
  --sign "$DEVELOPER_IDENTITY" \
  --identifier "$BUNDLE_ID" \
  "$APP_BUNDLE"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

/usr/bin/ditto "$APP_BUNDLE" "$DMG_ROOT/$APP_NAME.app"
/bin/ln -s /Applications "$DMG_ROOT/Applications"

if [[ "$MODE" == "release" ]]; then
  DMG_NAME="$APP_NAME-$APP_VERSION-universal.dmg"
else
  DMG_NAME="$APP_NAME-$APP_VERSION-universal-preview.dmg"
fi
DMG_PATH="$DIST_DIR/$DMG_NAME"
CHECKSUM_PATH="$DMG_PATH.sha256"

/bin/rm -f "$DMG_PATH" "$CHECKSUM_PATH"
/usr/bin/hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov \
  "$DMG_PATH"
/usr/bin/codesign --force --timestamp --sign "$DEVELOPER_IDENTITY" "$DMG_PATH"
/usr/bin/codesign --verify --verbose=2 "$DMG_PATH"
/usr/bin/hdiutil verify "$DMG_PATH"

if [[ "$MODE" == "release" ]]; then
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
  /usr/sbin/spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG_PATH"
fi

/bin/mkdir -p "$MOUNT_DIR"
/usr/bin/hdiutil attach "$DMG_PATH" -nobrowse -readonly -mountpoint "$MOUNT_DIR" -quiet
MOUNTED=1
[[ -d "$MOUNT_DIR/$APP_NAME.app" ]] || fail "mounted DMG does not contain $APP_NAME.app"
[[ -L "$MOUNT_DIR/Applications" ]] || fail "mounted DMG does not contain the Applications shortcut"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$MOUNT_DIR/$APP_NAME.app"
/usr/bin/hdiutil detach "$MOUNT_DIR" -quiet
MOUNTED=0

HASH="$(/usr/bin/shasum -a 256 "$DMG_PATH" | /usr/bin/awk '{ print $1 }')"
/usr/bin/printf '%s  %s\n' "$HASH" "$DMG_NAME" > "$CHECKSUM_PATH"

printf '\nCreated: %s\n' "$DMG_PATH"
printf 'SHA-256: %s\n' "$HASH"
printf 'Architectures: %s\n' "$ARCHS"
printf 'Signing identity: %s\n' "$DEVELOPER_IDENTITY"
if [[ "$MODE" == "preview" ]]; then
  printf 'Status: signed local preview; not notarized and not for public distribution.\n'
else
  printf 'Status: signed, notarized, stapled, and Gatekeeper-assessed release.\n'
fi
