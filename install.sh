#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/luanti" ]; then
  DEST="${XDG_DATA_HOME:-$HOME/.local/share}/luanti/mods"
elif [ -d "$HOME/.minetest" ]; then
  DEST="$HOME/.minetest/mods"
else
  DEST="${XDG_DATA_HOME:-$HOME/.local/share}/luanti/mods"
fi
mkdir -p "$DEST"
for mod in "$ROOT"/mods/edu_*; do cp -a "$mod" "$DEST/"; done
printf 'Installed Studium mods in %s\n' "$DEST"
