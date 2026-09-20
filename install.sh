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
for mod in "$ROOT"/mods/edu_*; do
  # Replace the installed copy instead of merging into it. A plain copy leaves
  # files that a later version renamed or dropped, and a stale file shadows the
  # current one when Luanti loads the mod.
  rm -rf "$DEST/$(basename "$mod")"
  cp -a "$mod" "$DEST/"
done
printf 'Installed Studium mods in %s\n' "$DEST"
