#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
lua "$ROOT/mods/edu_core/tests/test_content.lua" "$ROOT/mods/edu_core"
lua "$ROOT/mods/edu_core/tests/test_progress.lua" "$ROOT/mods/edu_core"
