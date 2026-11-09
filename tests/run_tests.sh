#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPS_DIR="$REPO_ROOT/tests/.deps"
PLENARY_DIR="$DEPS_DIR/plenary.nvim"

if [ ! -d "$PLENARY_DIR" ]; then
  echo "Bootstrapping plenary.nvim -> $PLENARY_DIR"
  mkdir -p "$DEPS_DIR"
  git clone --depth 1 https://github.com/nvim-lua/plenary.nvim "$PLENARY_DIR"
fi

cd "$REPO_ROOT"
nvim --headless --noplugin -u "$REPO_ROOT/tests/minimal_init.lua" \
  -c "lua require('plenary.test_harness').test_directory('tests/spec/', { minimal_init = 'tests/minimal_init.lua' })" \
  -c "qa"