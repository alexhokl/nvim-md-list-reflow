-- lua/nvim-md-list-reflow/reflow.lua
-- Reflow markdown bullet and numbered lists like `gq`, then strip
-- list prefixes from wrapped continuation lines (each item keeps its
-- marker on its first line only; numbers are preserved as written).
local M = {}

local BULLET_PREFIX = "^(%s*[-*+]%s+)"
local ORDERED_PREFIX = "^(%s*%d+[%.%)]%s+)"

local function is_blank(line)
	return line:match("^%s*$") ~= nil
end

local function list_prefix(line)
	return line:match(BULLET_PREFIX) or line:match(ORDERED_PREFIX)
end

local function rtrim(s)
	return (s:gsub("%s+$", ""))
end

-- Remove any leading whitespace and optional list marker.
local function strip_leader(line)
	line = (line:gsub("^%s*[-*+]?%s*", "", 1))
	return (line:gsub("^%s*%d+[%.%)]%s+", "", 1))
end

--- Split the range into segments: a list line (bullet or numbered)
--- starts a segment and following non-blank, non-list lines attach
--- to it as continuations. Blank lines break segments and are never
--- reflowed. Lines before the first list marker form plain (no-strip)
--- segments.
local function build_segments(lines)
	local segments = {}
	local cur = nil
	for idx, line in ipairs(lines) do
		local prefix = list_prefix(line)
		if prefix ~= nil then
			cur = { start = idx, finish = idx, prefix = prefix }
			segments[#segments + 1] = cur
		elseif is_blank(line) then
			cur = nil
		elseif cur ~= nil then
			cur.finish = idx
		else
			cur = { start = idx, finish = idx, prefix = nil }
			segments[#segments + 1] = cur
		end
	end
	return segments
end

--- Apply a buffer change, merging all changes of one format_range call
--- into a single undo block.
local function change(state, fn)
	if state.started then
		pcall(vim.cmd, "undojoin")
	end
	fn()
	state.started = true
end

--- Join the lines of one segment into a single logical line.
local function join_segment(lines, prefix, indent)
	local pieces = {}
	local first = prefix ~= nil and lines[1]:sub(#prefix + 1) or lines[1]:sub(#indent + 1)
	first = rtrim(first)
	if first ~= "" then
		pieces[#pieces + 1] = first
	end
	for i = 2, #lines do
		local body = rtrim(strip_leader(lines[i]))
		if body ~= "" then
			pieces[#pieces + 1] = body
		end
	end
	if prefix ~= nil then
		local text = table.concat(pieces, " ")
		if text == "" then
			return rtrim(prefix)
		end
		return rtrim(prefix) .. " " .. text
	end
	return indent .. table.concat(pieces, " ")
end

--- Reflow one segment [start_line, end_line]: join it to a single line,
--- reflow that line with the built-in `gq`, then replace the list
--- prefix of every wrapped continuation line with an equal-width run of
--- spaces (hanging indent). Plain segments keep their indent, no strip.
local function format_segment(state, start_line, end_line, prefix)
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local indent = prefix ~= nil and "" or (lines[1]:match("^%s*") or "")
	local joined = join_segment(lines, prefix, indent)

	local tw = vim.bo.textwidth
	if #lines == 1 and lines[1] == joined and (tw <= 0 or vim.fn.strdisplaywidth(joined) <= tw) then
		return
	end

	if #lines ~= 1 or lines[1] ~= joined then
		change(state, function()
			vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, { joined })
		end)
	end
	end_line = start_line

	local new_end = start_line
	if tw > 0 then
		local count_before = vim.api.nvim_buf_line_count(0)
		change(state, function()
			vim.cmd("keepjumps normal! " .. start_line .. "ggVgq")
		end)
		new_end = start_line + (vim.api.nvim_buf_line_count(0) - count_before)
	end

	if new_end <= start_line then
		return
	end

	local pad = prefix ~= nil and string.rep(" ", #prefix) or indent
	local out = vim.api.nvim_buf_get_lines(0, start_line, new_end, false)
	local changed = false
	for idx, line in ipairs(out) do
		local new_line = pad .. strip_leader(line)
		if new_line ~= line then
			out[idx] = new_line
			changed = true
		end
	end
	if changed then
		change(state, function()
			vim.api.nvim_buf_set_lines(0, start_line, new_end, false, out)
		end)
	end
end

local function format_range_impl(start_line, end_line)
	start_line = math.max(1, start_line)
	end_line = math.min(end_line, vim.api.nvim_buf_line_count(0))
	if start_line > end_line then
		return
	end

	local saved_cursor = vim.fn.getcurpos()
	local saved_formatexpr = vim.bo.formatexpr
	local saved_formatprg = vim.o.formatprg
	vim.bo.formatexpr = ""
	vim.o.formatprg = ""

	local ok, err = pcall(function()
		local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
		local segments = build_segments(lines)
		local state = { started = false }
		-- Bottom-up so earlier segments keep their line numbers.
		for i = #segments, 1, -1 do
			local seg = segments[i]
			format_segment(state, start_line + seg.start - 1, start_line + seg.finish - 1, seg.prefix)
		end
	end)

	vim.bo.formatexpr = saved_formatexpr
	vim.o.formatprg = saved_formatprg
	if not ok then
		error(err)
	end

	local count = vim.api.nvim_buf_line_count(0)
	if saved_cursor[2] > count then
		saved_cursor[2] = count
	end
	vim.fn.setpos(".", saved_cursor)
end

--- Reflow and strip list prefixes in [start_line, end_line].
function M.format_range(start_line, end_line)
	local ok, err = pcall(format_range_impl, start_line, end_line)
	if not ok then
		vim.notify("nvim-md-list-reflow: " .. err, vim.log.levels.ERROR)
		return false
	end
	return true
end

function M.operatorfunc()
	M.format_range(vim.fn.line("'["), vim.fn.line("']"))
end

return M
