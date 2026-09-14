#!/bin/sh
set -eu

if ! command -v luanti >/dev/null 2>&1; then
  echo "luanti is not installed; skipping live smoke test"
  exit 0
fi

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
WORLD="$TMP/world"
LOG="$TMP/luanti.log"
PORT=$((20000 + ($$ % 20000)))
mkdir -p "$WORLD"
cat > "$WORLD/world.mt" <<EOF
world_name = studium-smoke
gameid = minetest
backend = sqlite3
player_backend = sqlite3
auth_backend = sqlite3
load_mod_edu_core = true
load_mod_edu_arithmetic = true
load_mod_edu_number_blocks = true
load_mod_edu_english_blocks = true
load_mod_edu_logic_blocks = true
EOF

# Use the installed Studium mods, matching a user's real installation.
set +e
timeout 5 luanti --server --port "$PORT" --world "$WORLD" --logfile "$LOG" --quiet
status=$?
set -e
if [ "$status" -ne 0 ] && [ "$status" -ne 124 ]; then
  cat "$LOG"
  exit "$status"
fi
if grep -Eiq 'ERROR\[Main\]|Lua: Runtime error|not found|Failed to load' "$LOG"; then
  cat "$LOG"
  exit 1
fi
if ! grep -q 'Server for gameid=' "$LOG"; then
  cat "$LOG"
  echo "Luanti did not reach server startup" >&2
  exit 1
fi
printf 'Luanti live smoke test passed\n'
