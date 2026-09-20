#!/bin/sh
# Regenerate the translation template for every Studium mod.
#
# Luanti's get_translator() loads mods/<mod>/locale/<language>.po at runtime, so
# the templates produced here are what a translator starts from. They are
# generated with --no-location and a pinned creation date so that regenerating
# them produces an identical file: a diff then means the translatable strings
# really changed, which is what CI checks.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if ! command -v xgettext >/dev/null 2>&1; then
  echo "xgettext is required; install the gettext package" >&2
  exit 1
fi

found=0
for dir in "$ROOT"/mods/edu_*; do
  [ -d "$dir" ] || continue
  mod=$(basename "$dir")
  found=1
  mkdir -p "$dir/locale"
  pot="$dir/locale/template.pot"

  xgettext \
    --language=Lua \
    --keyword=S \
    --from-code=UTF-8 \
    --no-location \
    --package-name="$mod" \
    --output="$pot" \
    "$dir"/*.lua

  # xgettext stamps the current time and marks the header fuzzy. Pin the date so
  # regeneration is reproducible, and drop the fuzzy flag so translation tools
  # treat the header as usable.
  sed -e 's/^"POT-Creation-Date:.*/"POT-Creation-Date: 1970-01-01 00:00+0000\\n"/' \
      -e '/^#, fuzzy$/d' "$pot" > "$pot.new"
  mv "$pot.new" "$pot"

  count=$(grep -c '^msgid "' "$pot" || true)
  # The header entry is itself a msgid, so anything above one is a real string.
  printf '%s: %d translatable string(s)\n' "$mod" "$((count - 1))"
done

if [ "$found" -eq 0 ]; then
  echo "no Studium mods found under $ROOT/mods" >&2
  exit 1
fi
