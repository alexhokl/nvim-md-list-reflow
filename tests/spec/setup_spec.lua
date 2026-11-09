local M = require("nvim-md-list-reflow")

local function expand(s)
  return vim.api.nvim_replace_termcodes(s, true, true, true)
end

local function new_buf(filetype)
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = filetype
  return buf
end

local function has_map(buf, mode, lhs)
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
    if map.lhs == expand(lhs) then
      return true
    end
  end
  return false
end

describe("setup", function()
  after_each(function()
    pcall(vim.api.nvim_del_augroup_by_name, "nvim_md_list_reflow")
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= vim.api.nvim_get_current_buf() then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end)

  it("maps the key in normal and visual mode on markdown buffers", function()
    M.setup({ keymap = ",q" })
    local buf = new_buf("markdown")
    assert.is_true(has_map(buf, "n", ",q"))
    assert.is_true(has_map(buf, "x", ",q"))
  end)

  it("does not map the key on other filetypes", function()
    M.setup({ keymap = ",q" })
    local buf = new_buf("text")
    assert.is_false(has_map(buf, "n", ",q"))
  end)

  it("maps markdown buffers that were opened before setup", function()
    local buf = new_buf("markdown")
    M.setup({ keymap = ",q" })
    assert.is_true(has_map(buf, "n", ",q"))
  end)

  it("creates no mapping when keymap is false", function()
    M.setup({ keymap = false })
    local buf = new_buf("markdown")
    assert.is_false(has_map(buf, "n", "<leader>gq"))
    assert.is_false(has_map(buf, "x", "<leader>gq"))
  end)

  it("reflows the motion target through the mapping", function()
    M.setup({ keymap = ",q" })
    local buf = new_buf("markdown")
    vim.bo[buf].textwidth = 40
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "- one two three four five six seven eight nine ten eleven",
    })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.api.nvim_feedkeys(expand(",qip"), "x", false)
    assert.are.same({
      "- one two three four five six seven",
      "  eight nine ten eleven",
    }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)
end)
