#!/usr/bin/env bash
# scan_and_run.sh — preflight: verify env vars, fail-fast before starting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"
export PATH="$HOME/flutter-sdk/bin:$PATH"

if [ ! -f "$ENV_FILE" ]; then
  echo "WARNING: $ENV_FILE not found — using built-in defaults"
fi

# shell-source .env if present (only lines that start with WATCH_)
if [ -f "$ENV_FILE" ]; then
  echo "=== loading env from $ENV_FILE ==="
  set -a
  source "$ENV_FILE"
  set +a
fi

echo "=== media roots ==="
for key in MUSIC IMAGES SHOWS MOVIES PORN; do
  val="${WATCH_${key}_ROOT:-}"
  echo "  $key = ${val:-<unset>}"
done
