#!/usr/bin/env bash
# build.sh — clean, analyze, and build watch for all targets
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="$HOME/flutter-sdk/bin:$PATH"

# Load .env if present (optional — settings_repo reads it via dart-define at runtime)
# For flutter builds, pass paths as --dart-define so they're baked into the binary
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"
DART_DEFINES=()
if [ -f "$ENV_FILE" ]; then
  echo "=== loading env from $ENV_FILE ==="
  set -a
  source "$ENV_FILE"
  set +a
  for var in WATCH_MUSIC_ROOT WATCH_IMAGES_ROOT WATCH_SHOWS_ROOT WATCH_MOVIES_ROOT WATCH_PORN_ROOT; do
    val="${!var:-}"
    if [ -n "$val" ]; then
      DART_DEFINES+=("--dart-define=$var=$val")
    fi
  done
fi

echo "=== flutter clean ==="
flutter clean

echo "=== flutter pub get ==="
flutter pub get

echo "=== flutter analyze ==="
flutter analyze lib/ || echo "(analyze had warnings — non-fatal)"

echo "=== build: Linux ==="
flutter build linux --release --no-tree-shake-icons "${DART_DEFINES[@]}"

echo "=== build: Web ==="
flutter build web --release "${DART_DEFINES[@]}"

echo "=== build: Android APK ==="
flutter build apk --release "${DART_DEFINES[@]}"

RELEASES="$SCRIPT_DIR/releases"
mkdir -p "$RELEASES"

cp build/linux/x64/release/bundle/* "$RELEASES/"
cp -r build/web "$RELEASES/web"
cp build/app/outputs/flutter-apk/app-release.apk "$RELEASES/watch-release.apk" 2>/dev/null || true

echo ""
echo "=== builds complete ==="
echo "  Linux bundle : releases/"
echo "  Web          : releases/web/"
echo "  APK          : releases/watch-release.apk"
