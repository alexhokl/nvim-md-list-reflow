local M = {}

M.defaults = {
	keymap = "<leader>gq", -- set to false to skip creating the mapping
	ft = { "markdown" },
}

function M.merge(opts)
	opts = opts or {}
	local keymap = opts.keymap
	if keymap == nil then
		keymap = M.defaults.keymap
	end
	return {
		keymap = keymap,
		ft = opts.ft or M.defaults.ft,
	}
end

return M
