#!/bin/sh
set -eu

BIN=""
for candidate in luanti minetest; do
  if command -v "$candidate" >/dev/null 2>&1; then
    BIN="$candidate"
    break
  fi
done
if [ -z "$BIN" ]; then
  if [ "${STUDIUM_REQUIRE_LUANTI:-}" = "1" ]; then
    echo "Luanti is required but was not found on PATH" >&2
    exit 1
  fi
  echo "Luanti is not installed; skipping live smoke test"
  exit 0
fi

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
WORLD="$TMP/world"
LOG="$TMP/luanti.log"
PORT=$((20000 + ($$ % 20000)))
MARKER="STUDIUM_SMOKE_LOADED_FROM_CHECKOUT"

# Luanti searches the user's mods directory before the world's worldmods, so an
# installed copy silently shadows the checkout and the test passes against code
# that is not in the repository. Run with a private home: the games directory is
# linked back in, but the mods directory is empty.
USER_PATH="$HOME/.minetest"
[ -d "$USER_PATH" ] || USER_PATH="$HOME/.local/share/luanti"
FAKE_HOME="$TMP/home"
case "$USER_PATH" in
  "$HOME/.minetest") FAKE_PATH="$FAKE_HOME/.minetest" ;;
  "$HOME/.local/share/luanti") FAKE_PATH="$FAKE_HOME/.local/share/luanti" ;;
  *) FAKE_PATH="$FAKE_HOME/.minetest" ;;
esac
mkdir -p "$FAKE_PATH/mods"
if [ -d "$USER_PATH/games" ]; then
  ln -s "$USER_PATH/games" "$FAKE_PATH/games"
fi

# Load the working tree by placing it in the world's own mods directory.
mkdir -p "$WORLD/worldmods"
for mod in "$ROOT"/mods/edu_*; do
  cp -r "$mod" "$WORLD/worldmods/"
done

# Mark the checkout copy so the run can prove which sources it actually loaded.
FIRST_LINE="$WORLD/worldmods/edu_core/init.lua"
{
  printf 'minetest.log("action", "%s")\n' "$MARKER"
  cat "$FIRST_LINE"
} > "$TMP/init.lua"
mv "$TMP/init.lua" "$FIRST_LINE"

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

set +e
env -u XDG_DATA_HOME HOME="$FAKE_HOME" timeout 5 "$BIN" --server --port "$PORT" --world "$WORLD" --logfile "$LOG" --quiet
status=$?
set -e
if [ "$status" -ne 0 ] && [ "$status" -ne 124 ]; then
  cat "$LOG"
  exit "$status"
fi
if ! grep -q "$MARKER" "$LOG"; then
  cat "$LOG"
  echo "Luanti loaded an installed mod copy instead of the checkout" >&2
  exit 1
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
