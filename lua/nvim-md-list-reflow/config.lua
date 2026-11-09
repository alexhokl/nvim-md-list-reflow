local M = {}

M.defaults = {
	keymap = "<leader>gq", -- set to false to skip creating the mapping
	ft = { "markdown" },
	override_gq = false, -- reflow lists with the built-in `gq` too (via formatexpr)
}

function M.merge(opts)
	opts = opts or {}
	local keymap = opts.keymap
	if keymap == nil then
		keymap = M.defaults.keymap
	end
	local override_gq = opts.override_gq
	if override_gq == nil then
		override_gq = M.defaults.override_gq
	end
	return {
		keymap = keymap,
		ft = opts.ft or M.defaults.ft,
		override_gq = override_gq,
	}
end

return M
