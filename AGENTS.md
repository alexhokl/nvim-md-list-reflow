# AGENTS.md

## What this is

Pure-Lua Neovim plugin. No build step. "Installing" means pointing a plugin
manager at this directory.

## Layout

| File | Purpose |
|---|---|
| `lua/nvim-md-list-reflow/init.lua` | `setup()`, keymaps (operator pattern via `g@`), `formatexpr()` for `override_gq`, public API |
| `lua/nvim-md-list-reflow/reflow.lua` | Segmenting, joining, `gq` reflow and hanging indent |
| `lua/nvim-md-list-reflow/config.lua` | Defaults and option merging |

## Testing

Framework: the Nvim plugin test harness (`:help dev-test-plugin`), run in a
real Neovim because reflow relies on the built-in `gq` and `textwidth`.
`Makefile` is a copy of `contrib/plugin_test.mk` from the Neovim repository.

```bash
task test                                # downloads the harness into .deps/ on first run
task test-file -- test/reflow_spec.lua   # = make test TEST_FILE=...
make test TEST_FILTER='reflows lists'    # filter by test name
```

- Specs live in `test/*_spec.lua` and use `require('test.testutil')` (`t`)
  and `require('test.functional.testnvim')()` (`n`).
- Each `n.clear()` starts a fresh child Nvim with `--clean`, so the user's
  config never leaks in; `before_each` appends `getcwd()` to `runtimepath`.
- Functions passed to `n.exec_lua` run in the child: pass data as arguments,
  not upvalues, and return only serializable values.
- Use `n.feed()` for keymaps and normal-mode commands.

## Conventions

- Plugin code under `lua/` uses tabs; specs under `test/` use 2 spaces.
- Use `vim.notify()` with a log level for user-facing messages, never `print()`.
- Keep all buffer changes from one reflow in one undo block (`undojoin`).
