# PeekPairs

PeekPairs is a native macOS memory game built in SwiftUI/AppKit. It is designed for quick hotkey-driven rounds, dark-mode glass UI, animated 3D card flips, automatic focus-loss pause, persistent local stats, and configurable global shortcuts.

## Build

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"

swift test
scripts/package-app.sh debug
open dist/PeekPairs.app
```

The packaged app is written to `dist/PeekPairs.app`.

## Controls

- Gear button or `Command-,`: settings popup
- Sparkle button: new round
- Default global shortcuts:
  - `Control-Option-Command-M`: open paused board
  - `Control-Option-Command-N`: open and start a new game
  - `Control-Option-Command-P`: resume current game or start one

Settings and history are saved locally in `~/Library/Application Support/PeekPairs`.

## QA

Set `PEEKPAIRS_SEED=<number>` before launching the app to force deterministic shuffles for repeatable UI verification. Normal launches use fresh random seeds.
