local t = require('test.testutil')
local n = require('test.functional.testnvim')()

-- Opens a scratch buffer with textwidth=40 and `lines`, runs
-- format_range(first, last) and returns its result and the buffer lines.
local function format(lines, first, last)
  return unpack(n.exec_lua(function(l, s, e)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].textwidth = 40
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, l)
    local ok = require('nvim-md-list-reflow').format_range(s, e)
    return { ok, vim.api.nvim_buf_get_lines(buf, 0, -1, false) }
  end, lines, first, last))
end

local function has_list(lines)
  return n.exec_lua(function(l)
    return require('nvim-md-list-reflow.reflow').has_list(l)
  end, lines)
end

local function before_each()
  n.clear()
  n.exec_lua(function()
    vim.opt.runtimepath:append(vim.fn.getcwd())
  end)
end

t.describe('has_list', function()
  t.before_each(before_each)

  t.it('detects bullet and numbered items', function()
    t.eq(true, has_list({ 'prose', '- item' }))
    t.eq(true, has_list({ '  1. item' }))
    t.eq(true, has_list({ '2) item' }))
  end)

  t.it('ignores prose and bare numbers', function()
    t.eq(false, has_list({ 'prose', '2026 was a year', '' }))
  end)
end)

t.describe('format_range', function()
  t.before_each(before_each)

  t.it('wraps a bullet item with a hanging indent', function()
    local ok, lines = format({
      '- one two three four five six seven eight nine ten eleven',
    }, 1, 1)
    t.eq(true, ok)
    t.eq({
      '- one two three four five six seven',
      '  eight nine ten eleven',
    }, lines)
  end)

  t.it('indents numbered items by the full marker width', function()
    local _, lines = format({
      '1. one two three four five six seven eight nine ten',
      '10) one two three four five six seven eight nine ten',
    }, 1, 2)
    t.eq({
      '1. one two three four five six seven',
      '   eight nine ten',
      '10) one two three four five six seven',
      '    eight nine ten',
    }, lines)
  end)

  t.it('joins continuation lines into the item', function()
    local _, lines = format({
      '- alpha',
      '  beta',
      'gamma',
    }, 1, 3)
    t.eq({ '- alpha beta gamma' }, lines)
  end)

  t.it('treats indented bullets as nested items', function()
    local _, lines = format({
      '- alpha',
      '  - beta',
      'gamma',
    }, 1, 3)
    t.eq({ '- alpha', '  - beta gamma' }, lines)
  end)

  t.it('keeps blank lines between items', function()
    local _, lines = format({
      '- alpha',
      '  beta',
      '',
      '- gamma',
    }, 1, 4)
    t.eq({ '- alpha beta', '', '- gamma' }, lines)
  end)

  t.it('does not add markers to prose before the first item', function()
    local _, lines = format({
      'some prose that is long enough to need wrapping here',
      '- item',
    }, 1, 2)
    t.eq({
      'some prose that is long enough to need',
      'wrapping here',
      '- item',
    }, lines)
  end)

  t.it('leaves bare numbers without a delimiter as prose', function()
    local _, lines = format({ '2026 was a year' }, 1, 1)
    t.eq({ '2026 was a year' }, lines)
  end)

  t.it('is a no-op on an already formatted line', function()
    local before, after, lines = unpack(n.exec_lua(function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].textwidth = 40
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '- short' })
      local tick = vim.b[buf].changedtick
      require('nvim-md-list-reflow').format_range(1, 1)
      return { tick, vim.b[buf].changedtick, vim.api.nvim_buf_get_lines(buf, 0, -1, false) }
    end))
    t.eq({ '- short' }, lines)
    t.eq(before, after)
  end)

  t.it('undoes the whole reflow in one step', function()
    local original = {
      '- one two three four five six seven eight nine ten eleven',
      '  twelve',
      '- thirteen fourteen fifteen sixteen seventeen eighteen',
    }
    local reflowed, undone = unpack(n.exec_lua(function(l)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].textwidth = 40
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, l)
      -- Start a fresh undo block so `u` only reverts the reflow.
      vim.bo[buf].undolevels = vim.bo[buf].undolevels
      require('nvim-md-list-reflow').format_range(1, 3)
      local after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      vim.cmd('silent undo')
      return { after, vim.api.nvim_buf_get_lines(buf, 0, -1, false) }
    end, original))
    t.neq(original, reflowed)
    t.eq(original, undone)
  end)
end)
