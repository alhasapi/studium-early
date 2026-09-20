#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
lua "$ROOT/tests/test_logic.lua" "$ROOT"
lua "$ROOT/tests/test_integration.lua" "$ROOT"
lua "$ROOT/tests/test_picture_assets.lua" "$ROOT"
lua "$ROOT/tests/test_word_coverage.lua" "$ROOT"
