local M = require("nvim-md-list-reflow")

local function with_buf(lines, fn)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].textwidth = 40
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  fn(buf)
  vim.api.nvim_buf_delete(buf, { force = true })
end

local function get_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

describe("format_range", function()
  it("wraps a bullet item with a hanging indent", function()
    with_buf({
      "- one two three four five six seven eight nine ten eleven",
    }, function(buf)
      assert.is_true(M.format_range(1, 1))
      assert.are.same({
        "- one two three four five six seven",
        "  eight nine ten eleven",
      }, get_lines(buf))
    end)
  end)

  it("indents numbered items by the full marker width", function()
    with_buf({
      "1. one two three four five six seven eight nine ten",
      "10) one two three four five six seven eight nine ten",
    }, function(buf)
      M.format_range(1, 2)
      assert.are.same({
        "1. one two three four five six seven",
        "   eight nine ten",
        "10) one two three four five six seven",
        "    eight nine ten",
      }, get_lines(buf))
    end)
  end)

  it("joins continuation lines into the item", function()
    with_buf({
      "- alpha",
      "  beta",
      "gamma",
    }, function(buf)
      M.format_range(1, 3)
      assert.are.same({ "- alpha beta gamma" }, get_lines(buf))
    end)
  end)

  it("treats indented bullets as nested items", function()
    with_buf({
      "- alpha",
      "  - beta",
      "gamma",
    }, function(buf)
      M.format_range(1, 3)
      assert.are.same({ "- alpha", "  - beta gamma" }, get_lines(buf))
    end)
  end)

  it("keeps blank lines between items", function()
    with_buf({
      "- alpha",
      "  beta",
      "",
      "- gamma",
    }, function(buf)
      M.format_range(1, 4)
      assert.are.same({ "- alpha beta", "", "- gamma" }, get_lines(buf))
    end)
  end)

  it("does not add markers to prose before the first item", function()
    with_buf({
      "some prose that is long enough to need wrapping here",
      "- item",
    }, function(buf)
      M.format_range(1, 2)
      assert.are.same({
        "some prose that is long enough to need",
        "wrapping here",
        "- item",
      }, get_lines(buf))
    end)
  end)

  it("leaves bare numbers without a delimiter as prose", function()
    with_buf({ "2026 was a year" }, function(buf)
      M.format_range(1, 1)
      assert.are.same({ "2026 was a year" }, get_lines(buf))
    end)
  end)

  it("is a no-op on an already formatted line", function()
    with_buf({ "- short" }, function(buf)
      local tick = vim.b[buf].changedtick
      M.format_range(1, 1)
      assert.are.same({ "- short" }, get_lines(buf))
      assert.are.equal(tick, vim.b[buf].changedtick)
    end)
  end)

  it("undoes the whole reflow in one step", function()
    local original = {
      "- one two three four five six seven eight nine ten eleven",
      "  twelve",
      "- thirteen fourteen fifteen sixteen seventeen eighteen",
    }
    with_buf(original, function(buf)
      -- Start a fresh undo block so `u` only reverts the reflow.
      vim.bo[buf].undolevels = vim.bo[buf].undolevels
      M.format_range(1, 3)
      assert.are_not.same(original, get_lines(buf))
      vim.cmd("silent undo")
      assert.are.same(original, get_lines(buf))
    end)
  end)
end)
