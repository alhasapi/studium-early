#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
lua "$ROOT/tests/test_logic.lua" "$ROOT"
lua "$ROOT/tests/test_integration.lua" "$ROOT"
