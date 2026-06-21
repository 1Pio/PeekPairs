#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-release}"
RELEASE_DIR="$ROOT_DIR/release"
ZIP_PATH="$RELEASE_DIR/PeekPairs.app.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"
INSTALL_PATH="${PEEKPAIRS_INSTALL_PATH:-/Applications/PeekPairs.app}"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/module-cache"

APP_DIR="$("$ROOT_DIR/scripts/package-app.sh" "$CONFIGURATION" | tail -n 1)"

mkdir -p "$RELEASE_DIR"
rm -f "$ZIP_PATH" "$CHECKSUM_PATH"

(cd "$(dirname "$APP_DIR")" && /usr/bin/zip -qry -X "$ZIP_PATH" "$(basename "$APP_DIR")")
shasum -a 256 "$ZIP_PATH" | awk '{print $1}' > "$CHECKSUM_PATH"

if [[ "${PEEKPAIRS_SKIP_INSTALL:-0}" != "1" ]]; then
    rm -rf "$INSTALL_PATH"
    ditto "$APP_DIR" "$INSTALL_PATH"
fi

echo "App: $APP_DIR"
echo "Release: $ZIP_PATH"
echo "Checksum: $CHECKSUM_PATH"
if [[ "${PEEKPAIRS_SKIP_INSTALL:-0}" != "1" ]]; then
    echo "Installed: $INSTALL_PATH"
fi
