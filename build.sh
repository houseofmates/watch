#!/usr/bin/env bash
# build.sh — clean, analyze, build, and optionally serve watch
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$$0")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="$HOME/flutter-sdk/bin:$PATH"

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

COMMAND="${1:-build}"

# ── find a free port ─────────────────────────────────────────────────────────
_free_port() {
  local port="$1"
  (echo > /dev/tcp/127.0.0.1/$port) >/dev/null 2>&1 && return 1 || return 0
}

find_port() {
  local ports=(8080 8081 3000 5000 8000 8888 9000)
  for p in "${ports[@]}"; do
    if _free_port "$p"; then
      echo "$p"; return 0
    fi
  done
  # fallback: ask the kernel
  python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1',0)); print(s.getsockname()[1]); s.close()"
}

# ── build ─────────────────────────────────────────────────────────────────────
case "$COMMAND" in
  build|"")
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
    ;;

  # ── serve web on an unused localhost port ─────────────────────────────────
  serve)
    echo "=== building web ==="
    flutter build web --release "${DART_DEFINES[@]}"

    PORT="${2:-$(find_port)}"
    echo "=== serving on http://localhost:$PORT ==="
    echo "  Press Ctrl+C to stop"
    echo ""
    cd build/web
    exec python3 -m http.server "$PORT"
    ;;

  # ── serve web on a chosen port ─────────────────────────────────────────────
  serve-port)
    PORT="${2:-$(find_port)}"
    echo "=== building web ==="
    flutter build web --release "${DART_DEFINES[@]}"
    echo "=== serving on http://localhost:$PORT ==="
    cd build/web && exec python3 -m http.server "$PORT"
    ;;

  # ── tunnel — build → serve → cloudflared quick-tunnel ─────────────────────
  tunnel)
    PORT="${2:-$(find_port)}"
    echo "=== building web ==="
    flutter build web --release "${DART_DEFINES[@]}"

    echo "=== starting web server on http://localhost:$PORT ==="
    python3 -m http.server "$PORT" --directory build/web &
    SERVER_PID=$!
    trap "kill $SERVER_PID 2>/dev/null" EXIT
    sleep 1

    echo "=== launching cloudflared quick-tunnel on port $PORT ==="
    echo ""
    cloudflared tunnel --url "http://localhost:$PORT"
    ;;

  # ── quick-tunnel alias — no build, just cloudflared ────────────────────────
  quick)
    PORT="${2:-$(find_port)}"
    echo "=== serving build/web on http://localhost:$PORT (no rebuild) ==="
    python3 -m http.server "$PORT" --directory build/web &
    SERVER_PID=$!
    trap "kill $SERVER_PID 2>/dev/null" EXIT
    sleep 1
    echo ""
    cloudflared tunnel --url "http://localhost:$PORT"
    ;;

  *)
    echo "usage: $0 {build|serve [port]|serve-port <port>|tunnel [port]|quick [port]}"
    echo ""
    echo "  build        clean + analyze + linux + web + apk  (default)"
    echo "  serve [8080] build web and start python http.server on first free port"
    echo "  serve-port    start server on a specific port"
    echo "  tunnel        build + serve locally + launch cloudflared quick-tunnel"
    echo "  quick         skip build, serve existing build/web + cloudflared"
    exit 1
    ;;
esac
