#!/usr/bin/env bash
# build.sh — build watch for all supported platforms
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="$HOME/flutter-sdk/bin:$PATH"

echo "=== flutter clean ==="
flutter clean

echo "=== flutter pub get ==="
flutter pub get

echo "=== flutter analyze ==="
flutter analyze lib/ || echo "analyze had warnings (non-fatal)"

echo "=== build: Linux ==="
flutter build linux --release --no-tree-shake-icons

echo "=== build: Web ==="
flutter build web --release

echo "=== build: Android APK ==="
flutter build apk --release

RELEASES="$SCRIPT_DIR/releases"
mkdir -p "$RELEASES"

cp build/linux/x64/release/bundle/* "$RELEASES/"
cp -r build/web "$RELEASES/web"
cp build/app/outputs/flutter-apk/app-release.apk "$RELEASES/watch-release.apk"

echo ""
echo "=== builds done ==="
echo "  Linux  : releases/"
echo "  Web    : releases/web/"
echo "  APK    : releases/watch-release.apk"
