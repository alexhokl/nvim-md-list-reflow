# AGENTS.md

## What this is

Pure-Lua Neovim plugin. No build step. "Installing" means pointing a plugin
manager at this directory.

## Layout

| File | Purpose |
|---|---|
| `lua/nvim-md-list-reflow/init.lua` | `setup()`, keymaps (operator pattern via `g@`), public API |
| `lua/nvim-md-list-reflow/reflow.lua` | Segmenting, joining, `gq` reflow and hanging indent |
| `lua/nvim-md-list-reflow/config.lua` | Defaults and option merging |

## Testing

Framework: plenary.nvim (busted-style), run headless in a real Neovim because
reflow relies on the built-in `gq` and `textwidth`.

```bash
task test   # bootstraps plenary into tests/.deps/ on first run
```

`tests/minimal_init.lua` removes the user's config directory from the
runtimepath so personal ftplugins/keymaps don't leak into the tests.

## Conventions

- Plugin code under `lua/` uses tabs; specs under `tests/` use 2 spaces.
- Use `vim.notify()` with a log level for user-facing messages, never `print()`.
- Keep all buffer changes from one reflow in one undo block (`undojoin`).
