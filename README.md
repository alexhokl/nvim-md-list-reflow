# nvim-md-list-reflow

A tiny Neovim plugin to reflow Markdown bullet and numbered lists with `gq`
while keeping a proper hanging indent.

The built-in `gq` treats a list marker as ordinary text, so wrapped lines either
lose their alignment or pick up stray markers. This plugin joins each list item
into one logical line, reflows it with the built-in `gq` (respecting
`textwidth`), then replaces the marker on every wrapped line with an equal-width
run of spaces.

```markdown
- one two three four five six seven eight nine ten eleven
10) one two three four five six seven eight nine ten
```

becomes (with `textwidth=40`)

```markdown
- one two three four five six seven
  eight nine ten eleven
10) one two three four five six seven
    eight nine ten
```

## Features

- `<leader>gq{motion}` in normal mode and `<leader>gq` in visual mode. Works like
  `gq` and is a real operator, so `.` repeats it.
- Bullets (`-`, `*`, `+`) and numbered items (`1.`, `1)`, multi-digit, indented).
  Numbers are kept as written.
- Indented markers start nested items; non-marker lines are joined into the
  item above.
- Blank lines separate items and are never reflowed. Prose before the first
  marker is reflowed as plain text, without markers.
- A bare number without a delimiter (`2026 was a year`) is treated as prose.
- A whole reflow is undone with a single `u`.
- Strictly opt-in: no auto-setup. You must call `setup()` from your config.

## Installation

### lazy.nvim

```lua
{
  "alexhokl/nvim-md-list-reflow",
  ft = "markdown",
  opts = {},
}
```

## Setup

```lua
require("nvim-md-list-reflow").setup({
  keymap      = "<leader>gq", -- set to false to skip creating the mapping
  ft          = { "markdown" },
  override_gq = false,        -- make the built-in `gq` reflow lists too
})
```

All options are optional; the values above are the defaults.

### Overriding `gq`

With `override_gq = true` the plugin sets a buffer-local `formatexpr`, so plain
`gq` (`gq{motion}`, visual `gq`, `gqq`, counts and `.`) reflows lists the same
way as the mapping.

- Ranges without a bullet or numbered item fall back to the built-in `gq`.
- Auto-wrap while typing (`formatoptions+=t`) and `gw` always use Vim's
  internal formatter.
- Neovim's LSP only sets `formatexpr` when it is empty, so the plugin's value
  wins. A `setlocal formatexpr=...` of your own (for example in an LSP
  `on_attach`) replaces it.

```lua
{
  "alexhokl/nvim-md-list-reflow",
  ft = "markdown",
  opts = { keymap = false, override_gq = true }, -- gq only, no extra mapping
}
```

### API

```lua
-- Reflow lines 10..20 of the current buffer; returns true on success.
require("nvim-md-list-reflow").format_range(10, 20)
```

## Tests

Uses the Nvim plugin test harness (`:help dev-test-plugin`). `Makefile` is
a copy of `contrib/plugin_test.mk` from the Neovim repository. On first run,
`make test` downloads the harness modules into `.deps/` (gitignored). Each
test runs against a fresh Nvim.

```
task test
task test-file -- test/reflow_spec.lua
make test NVIM_PRG=/path/to/nvim NVIM_TEST_VERSION=master
```

`NVIM_TEST_VERSION` (default `master`) should match the Nvim under test.
Remove `.deps/` to download the harness again.
