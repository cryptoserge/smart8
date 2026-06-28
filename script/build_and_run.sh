#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Smart8"
BUNDLE_ID="com.cryptoserge.smart8"
MIN_SYSTEM_VERSION="14.0"
BUILD_CONFIGURATION="${SMART8_BUILD_CONFIGURATION:-debug}"
BUILD_ARCHS="${SMART8_BUILD_ARCHS:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

SWIFT_BUILD_ARGS=()
case "$BUILD_CONFIGURATION" in
  debug)
    ;;
  release)
    SWIFT_BUILD_ARGS=(-c release)
    ;;
  *)
    echo "SMART8_BUILD_CONFIGURATION must be debug or release" >&2
    exit 2
    ;;
esac

for arch in $BUILD_ARCHS; do
  SWIFT_BUILD_ARGS+=(--arch "$arch")
done

swift build "${SWIFT_BUILD_ARGS[@]}"
BUILD_BINARY="$(swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$ROOT_DIR/Assets/Smart8.icns" "$APP_RESOURCES/Smart8.icns"
cp "$ROOT_DIR/Assets/HeroDripper.png" "$APP_RESOURCES/HeroDripper.png"
cp "$ROOT_DIR/Assets/MetricTemperature.png" "$APP_RESOURCES/MetricTemperature.png"
cp "$ROOT_DIR/Assets/MetricPowder.png" "$APP_RESOURCES/MetricPowder.png"
cp "$ROOT_DIR/Assets/MetricWater.png" "$APP_RESOURCES/MetricWater.png"
cp "$ROOT_DIR/Assets/MetricPours.png" "$APP_RESOURCES/MetricPours.png"

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
  <string>Smart8.icns</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSBluetoothAlwaysUsageDescription</key>
  <string>HARIO Smart7へ接続し、レシピ送信、抽出停止、排水操作を行うためにBluetoothを使用します。</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  --build-only|build-only)
    ;;
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
    echo "usage: $0 [run|--build-only|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
