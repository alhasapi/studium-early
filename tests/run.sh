#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for mod in edu_number_blocks edu_english_blocks edu_logic_blocks; do
  "$ROOT/mods/$mod/tests/run.sh"
done
for file in "$ROOT"/mods/edu_core/*.lua "$ROOT"/mods/edu_*/*.lua; do
  luac -p "$file"
done
printf 'Studium regression checks passed\n'
