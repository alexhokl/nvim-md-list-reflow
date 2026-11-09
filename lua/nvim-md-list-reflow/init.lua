local config = require("nvim-md-list-reflow.config")
local reflow = require("nvim-md-list-reflow.reflow")

local M = {}

--- Reflow and strip list prefixes in [start_line, end_line] of the current
--- buffer. Returns true on success.
M.format_range = reflow.format_range

--- `operatorfunc` target: reflows the lines between '[ and '].
M.operatorfunc = reflow.operatorfunc

-- Both modes use the operator pattern: the mapping only sets `operatorfunc`
-- and returns "g@" (expression mappings must not change text). Neovim then
-- calls the operatorfunc with '[ / '] set to the motion target or the visual
-- selection.
local function set_operatorfunc()
	vim.o.operatorfunc = "v:lua.require'nvim-md-list-reflow'.operatorfunc"
	return "g@"
end

--- `formatexpr` target used when `override_gq` is enabled. Ranges with a
--- list item are reflowed by the plugin; anything else (and auto-wrap
--- while typing in insert mode) returns 1 so Vim formats internally.
function M.formatexpr()
	if vim.v.char ~= "" then
		return 1
	end
	local first = vim.v.lnum
	local last = first + vim.v.count - 1
	local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
	if not reflow.has_list(lines) then
		return 1
	end
	reflow.format_range(first, last)
	return 0
end

local function attach(bufnr, opts)
	if opts.keymap then
		local map_opts = {
			noremap = true,
			silent = true,
			desc = "Reflow markdown list (bullet/numbered)",
			buffer = bufnr,
			expr = true,
		}
		vim.keymap.set("n", opts.keymap, set_operatorfunc, map_opts)
		vim.keymap.set("x", opts.keymap, set_operatorfunc, map_opts)
	end
	if opts.override_gq then
		vim.bo[bufnr].formatexpr = "v:lua.require'nvim-md-list-reflow'.formatexpr()"
	end
end

function M.setup(opts)
	opts = config.merge(opts)
	if not opts.keymap and not opts.override_gq then
		return
	end

	local group = vim.api.nvim_create_augroup("nvim_md_list_reflow", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = opts.ft,
		callback = function(args)
			attach(args.buf, opts)
		end,
	})

	-- When lazy-loaded on `ft`, the triggering buffer's FileType event has
	-- already fired, so map buffers that already match.
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.tbl_contains(opts.ft, vim.bo[bufnr].filetype) then
			attach(bufnr, opts)
		end
	end
end

return M
