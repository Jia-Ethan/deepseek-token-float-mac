#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="DeepSeek Token Float"
PRODUCT_NAME="DeepSeekTokenFloatMac"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

swift build -c release --package-path "$ROOT_DIR"
BIN_DIR="$(swift build -c release --package-path "$ROOT_DIR" --show-bin-path)"
BIN_PATH="$BIN_DIR/$PRODUCT_NAME"

if [[ ! -x "$BIN_PATH" ]]; then
  echo "Missing release executable: $BIN_PATH" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/$PRODUCT_NAME"
cp "$ROOT_DIR/BuildSupport/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod 755 "$MACOS_DIR/$PRODUCT_NAME"

echo "Packaged: $APP_DIR"
