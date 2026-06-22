#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${PEEKPAIRS_PROFILE_CONFIGURATION:-release}"
TEMPLATE="${1:-Time Profiler}"
DURATION="${PEEKPAIRS_PROFILE_DURATION:-20s}"
BOARD_DIMENSION="${PEEKPAIRS_PROFILE_BOARD_DIMENSION:-8}"
WINDOW_WIDTH="${PEEKPAIRS_PROFILE_WINDOW_WIDTH:-760}"
SEED="${PEEKPAIRS_PROFILE_SEED:-42}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
PROFILE_DIR="${PEEKPAIRS_PROFILE_DIR:-$ROOT_DIR/tmp/perf/$RUN_ID}"
SUPPORT_DIR="$PROFILE_DIR/support"
TRACE_PATH="$PROFILE_DIR/PeekPairs-${TEMPLATE// /-}.trace"

mkdir -p "$SUPPORT_DIR/PeekPairs"

cat > "$SUPPORT_DIR/PeekPairs/settings.json" <<JSON
{
  "boardSize" : {
    "dimension" : $BOARD_DIMENSION
  },
  "defaultWindowWidth" : $WINDOW_WIDTH,
  "hotkeys" : [],
  "minimizeOnFocusLoss" : false
}
JSON

APP_DIR="$("$ROOT_DIR/scripts/package-app.sh" "$CONFIGURATION" | tail -n 1)"

cleanup() {
    pkill -x PeekPairs >/dev/null 2>&1 || true
}
trap cleanup EXIT
cleanup

echo "Trace: $TRACE_PATH"
echo "Template: $TEMPLATE"
echo "Duration: $DURATION"
echo "Board: ${BOARD_DIMENSION}x${BOARD_DIMENSION}"
echo "Seed: $SEED"

set +e
xcrun xctrace record \
    --template "$TEMPLATE" \
    --time-limit "$DURATION" \
    --output "$TRACE_PATH" \
    --env PEEKPAIRS_SUPPORT_DIR="$SUPPORT_DIR" \
    --env PEEKPAIRS_AUTOSTART=1 \
    --env PEEKPAIRS_SEED="$SEED" \
    --launch -- "$APP_DIR/Contents/MacOS/PeekPairs"
status=$?
set -e

if [[ "$status" != "0" && "$status" != "54" ]]; then
    exit "$status"
fi

echo "Saved trace: $TRACE_PATH"
