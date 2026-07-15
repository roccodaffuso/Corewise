#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Corewise"
BUNDLE_ID="dev.corewise.Corewise"
MIN_SYSTEM_VERSION="14.0"
APP_VERSION="${COREWISE_VERSION:-0.1.0}"
BUILD_NUMBER="${COREWISE_BUILD_NUMBER:-3}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
FINAL_APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/corewise-bundle.XXXXXX")"
APP_BUNDLE="$STAGING_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

trap 'rm -rf "$STAGING_DIR"' EXIT

resolve_codesign_identity() {
  if [[ -n "${COREWISE_CODESIGN_IDENTITY:-}" ]]; then
    printf '%s' "$COREWISE_CODESIGN_IDENTITY"
    return
  fi

  local identity
  identity="$(/usr/bin/security find-identity -v -p codesigning | /usr/bin/awk -F'"' '/Apple Development:/ { print $2; exit }')"
  if [[ -z "$identity" ]]; then
    identity="$(/usr/bin/security find-identity -v -p codesigning | /usr/bin/awk -F'"' '/Developer ID Application:/ { print $2; exit }')"
  fi
  printf '%s' "${identity:--}"
}

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"
BUILD_PRODUCTS="$(swift build --show-bin-path)"
RESOURCE_BUNDLE="$BUILD_PRODUCTS/Corewise_Corewise.bundle"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
if [[ -d "$RESOURCE_BUNDLE" ]]; then
  cp -R "$RESOURCE_BUNDLE/." "$APP_RESOURCES/"
fi
cp "$ROOT_DIR/LICENSE" "$APP_RESOURCES/LICENSE.txt"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>Corewise.icns</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026 Rocco D’Affuso</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

CODESIGN_IDENTITY="$(resolve_codesign_identity)"
/usr/bin/xattr -cr "$APP_BUNDLE"
/usr/bin/xattr -d com.apple.FinderInfo "$APP_BUNDLE" 2>/dev/null || true
/usr/bin/xattr -d 'com.apple.fileprovider.fpfs#P' "$APP_BUNDLE" 2>/dev/null || true
/usr/bin/codesign --force --sign "$CODESIGN_IDENTITY" --identifier "$BUNDLE_ID" --timestamp=none "$APP_BUNDLE"
/usr/bin/xattr -cr "$APP_BUNDLE"
/usr/bin/codesign --verify --deep --verbose=2 "$APP_BUNDLE"

rm -rf "$FINAL_APP_BUNDLE"
mkdir -p "$DIST_DIR"
ditto "$APP_BUNDLE" "$FINAL_APP_BUNDLE"
APP_BUNDLE="$FINAL_APP_BUNDLE"
/usr/bin/codesign --verify --deep --verbose=2 "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
