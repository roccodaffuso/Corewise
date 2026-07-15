#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
set -euo pipefail

APP_NAME="Corewise"
BUNDLE_ID="dev.corewise.Corewise"
EXPECTED_VERSION="${COREWISE_EXPECTED_VERSION:-0.1.0}"
EXPECTED_BUILD="${COREWISE_EXPECTED_BUILD:-2}"
EXPECTED_MIN_SYSTEM="14.0"

usage() {
  printf 'usage: %s DMG_PATH EXPECTED_SHA256\n' "$(basename "$0")"
}

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

[[ $# -eq 2 ]] || {
  usage >&2
  exit 2
}

DMG_INPUT="$1"
EXPECTED_SHA256="$2"
[[ -f "$DMG_INPUT" ]] || fail "DMG does not exist: $DMG_INPUT"
[[ "$EXPECTED_SHA256" =~ ^[0-9a-fA-F]{64}$ ]] || fail "expected SHA-256 is invalid"

DMG_DIR="$(cd "$(dirname "$DMG_INPUT")" && pwd)"
DMG_PATH="$DMG_DIR/$(basename "$DMG_INPUT")"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/corewise-validation.XXXXXX")"
MOUNT_DIR="$TEMP_DIR/mount"
LAUNCH_APP="$TEMP_DIR/$APP_NAME.app"
MOUNTED=0

cleanup() {
  /usr/bin/pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  if [[ "$MOUNTED" == "1" ]]; then
    /usr/bin/hdiutil detach "$MOUNT_DIR" -quiet || true
  fi
  /bin/rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

ACTUAL_SHA256="$(/usr/bin/shasum -a 256 "$DMG_PATH" | /usr/bin/awk '{ print $1 }')"
NORMALIZED_EXPECTED_SHA256="$(printf '%s' "$EXPECTED_SHA256" | /usr/bin/tr '[:upper:]' '[:lower:]')"
[[ "$ACTUAL_SHA256" == "$NORMALIZED_EXPECTED_SHA256" ]] || {
  fail "SHA-256 mismatch: expected $EXPECTED_SHA256, got $ACTUAL_SHA256"
}

printf 'SHA-256 verified: %s\n' "$ACTUAL_SHA256"
/usr/bin/hdiutil verify "$DMG_PATH"

# The release artifact is validated as a notarized distribution container.
# Its mounted app receives the strict code-signature checks below.
xcrun stapler validate "$DMG_PATH"
/usr/sbin/spctl \
  --assess \
  --type open \
  --context context:primary-signature \
  --verbose=2 \
  "$DMG_PATH"

/bin/mkdir -p "$MOUNT_DIR"
/usr/bin/hdiutil attach \
  "$DMG_PATH" \
  -nobrowse \
  -readonly \
  -mountpoint "$MOUNT_DIR" \
  -quiet
MOUNTED=1

APP_BUNDLE="$MOUNT_DIR/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
LICENSE_FILE="$APP_BUNDLE/Contents/Resources/LICENSE.txt"
SOURCE_NOTICE="$APP_BUNDLE/Contents/Resources/SourceCode.txt"

[[ -d "$APP_BUNDLE" ]] || fail "mounted DMG does not contain $APP_NAME.app"
[[ -L "$MOUNT_DIR/Applications" ]] || fail "mounted DMG does not contain the Applications shortcut"
[[ -x "$APP_BINARY" ]] || fail "app executable is missing"
[[ -f "$INFO_PLIST" ]] || fail "Info.plist is missing"
[[ -f "$LICENSE_FILE" ]] || fail "MPL-2.0 license is missing from the app bundle"
[[ -f "$SOURCE_NOTICE" ]] || fail "source-code notice is missing from the app bundle"
grep -q "Mozilla Public License Version 2.0" "$LICENSE_FILE" || fail "bundled license is not MPL-2.0"
grep -q "https://github.com/roccodaffuso/Corewise" "$SOURCE_NOTICE" || fail "source-code notice does not identify the public repository"

/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
/usr/sbin/spctl --assess --type execute --verbose=2 "$APP_BUNDLE"

SIGNATURE_DETAILS="$(/usr/bin/codesign -d --verbose=4 "$APP_BUNDLE" 2>&1)"
[[ "$SIGNATURE_DETAILS" == *"runtime"* ]] || fail "app signature does not enable hardened runtime"
[[ "$SIGNATURE_DETAILS" == *"Timestamp="* ]] || fail "app signature does not contain a secure timestamp"

read_plist() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST"
}

[[ "$(read_plist CFBundleIdentifier)" == "$BUNDLE_ID" ]] || fail "unexpected bundle identifier"
[[ "$(read_plist CFBundleShortVersionString)" == "$EXPECTED_VERSION" ]] || fail "unexpected app version"
[[ "$(read_plist CFBundleVersion)" == "$EXPECTED_BUILD" ]] || fail "unexpected build number"
[[ "$(read_plist LSMinimumSystemVersion)" == "$EXPECTED_MIN_SYSTEM" ]] || fail "unexpected minimum macOS version"

ARCHITECTURES="$(/usr/bin/lipo -archs "$APP_BINARY")"
[[ "$ARCHITECTURES" == *"arm64"* ]] || fail "app executable is missing arm64"
[[ "$ARCHITECTURES" == *"x86_64"* ]] || fail "app executable is missing x86_64"

# Launch a temporary copy so this smoke test does not depend on the mounted
# image remaining writable. TCC and Full Disk Access still require manual QA.
/usr/bin/ditto "$APP_BUNDLE" "$LAUNCH_APP"
/usr/bin/xattr -cr "$LAUNCH_APP"
/usr/bin/open -n "$LAUNCH_APP"

LAUNCHED=0
for _ in {1..20}; do
  if /usr/bin/pgrep -x "$APP_NAME" >/dev/null; then
    LAUNCHED=1
    break
  fi
  /bin/sleep 1
done
[[ "$LAUNCHED" == "1" ]] || fail "$APP_NAME did not launch within 20 seconds"

printf 'Bundle identifier: %s\n' "$BUNDLE_ID"
printf 'Version: %s (%s)\n' "$EXPECTED_VERSION" "$EXPECTED_BUILD"
printf 'Minimum macOS: %s\n' "$EXPECTED_MIN_SYSTEM"
printf 'Architectures: %s\n' "$ARCHITECTURES"
printf 'Result: DMG integrity, notarization, Gatekeeper, app signature, metadata, and launch smoke test passed.\n'
