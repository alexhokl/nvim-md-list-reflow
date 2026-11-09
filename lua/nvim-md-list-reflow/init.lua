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

local function map_buffer(bufnr, keymap)
	local opts = {
		noremap = true,
		silent = true,
		desc = "Reflow markdown list (bullet/numbered)",
		buffer = bufnr,
		expr = true,
	}
	vim.keymap.set("n", keymap, set_operatorfunc, opts)
	vim.keymap.set("x", keymap, set_operatorfunc, opts)
end

function M.setup(opts)
	opts = config.merge(opts)
	if not opts.keymap then
		return
	end

	local group = vim.api.nvim_create_augroup("nvim_md_list_reflow", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = opts.ft,
		callback = function(args)
			map_buffer(args.buf, opts.keymap)
		end,
	})

	-- When lazy-loaded on `ft`, the triggering buffer's FileType event has
	-- already fired, so map buffers that already match.
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.tbl_contains(opts.ft, vim.bo[bufnr].filetype) then
			map_buffer(bufnr, opts.keymap)
		end
	end
end

return M
