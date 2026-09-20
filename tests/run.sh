#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for mod in edu_core edu_arithmetic edu_number_blocks edu_english_blocks edu_logic_blocks; do
  "$ROOT/mods/$mod/tests/run.sh"
done
for file in "$ROOT"/mods/edu_core/*.lua "$ROOT"/mods/edu_*/*.lua; do
  luac -p "$file"
done

# The translation templates are generated, so a stale one means someone added a
# translatable string without regenerating. Regenerate and check nothing moved.
if command -v xgettext >/dev/null 2>&1 && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  "$ROOT/tools/update-locale.sh" >/dev/null
  # status, not diff: a template that has never been committed is just as stale.
  # A glob pathspec would not expand to a directory prefix, so filter by hand.
  stale=$(git -C "$ROOT" status --porcelain -- mods | grep '/locale/' || true)
  if [ -n "$stale" ]; then
    echo "locale templates are stale; commit the result of tools/update-locale.sh" >&2
    echo "$stale" >&2
    exit 1
  fi
fi

printf 'Studium regression checks passed\n'
