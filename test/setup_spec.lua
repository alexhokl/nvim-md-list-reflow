local t = require('test.testutil')
local n = require('test.functional.testnvim')()

local function setup(opts)
  n.exec_lua(function(o)
    require('nvim-md-list-reflow').setup(o)
  end, opts)
end

-- Opens a listed scratch buffer with `filetype`, makes it current and
-- returns its number.
local function new_buf(filetype)
  return n.exec_lua(function(ft)
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].filetype = ft
    return buf
  end, filetype)
end

-- Whether `lhs` has a buffer-local mapping in `mode` in buffer `buf`.
local function has_map(buf, mode, lhs)
  return n.exec_lua(function(b, m, l)
    return vim.api.nvim_buf_call(b, function()
      return vim.fn.maparg(l, m, false, true).buffer == 1
    end)
  end, buf, mode, lhs)
end

local function formatexpr(buf)
  return n.api.nvim_get_option_value('formatexpr', { buf = buf })
end

local function get_lines(buf)
  return n.api.nvim_buf_get_lines(buf, 0, -1, false)
end

t.describe('setup', function()
  t.before_each(function()
    n.clear()
    n.exec_lua(function()
      vim.opt.runtimepath:append(vim.fn.getcwd())
    end)
  end)

  t.it('maps the key in normal and visual mode on markdown buffers', function()
    setup({ keymap = ',q' })
    local buf = new_buf('markdown')
    t.eq(true, has_map(buf, 'n', ',q'))
    t.eq(true, has_map(buf, 'x', ',q'))
  end)

  t.it('does not map the key on other filetypes', function()
    setup({ keymap = ',q' })
    local buf = new_buf('text')
    t.eq(false, has_map(buf, 'n', ',q'))
  end)

  t.it('maps markdown buffers that were opened before setup', function()
    local buf = new_buf('markdown')
    setup({ keymap = ',q' })
    t.eq(true, has_map(buf, 'n', ',q'))
  end)

  t.it('creates no mapping when keymap is false', function()
    setup({ keymap = false })
    local buf = new_buf('markdown')
    t.eq(false, has_map(buf, 'n', '<leader>gq'))
    t.eq(false, has_map(buf, 'x', '<leader>gq'))
  end)

  t.it('leaves formatexpr alone by default', function()
    setup({})
    local buf = new_buf('markdown')
    t.eq('', formatexpr(buf))
  end)

  t.it('sets formatexpr on markdown buffers when override_gq is on', function()
    setup({ override_gq = true })
    local md = new_buf('markdown')
    local txt = new_buf('text')
    t.eq("v:lua.require'nvim-md-list-reflow'.formatexpr()", formatexpr(md))
    t.eq('', formatexpr(txt))
  end)

  t.it('supports override_gq without a keymap', function()
    setup({ keymap = false, override_gq = true })
    local buf = new_buf('markdown')
    t.neq('', formatexpr(buf))
    t.eq(false, has_map(buf, 'n', '<leader>gq'))
  end)

  t.describe('with override_gq', function()
    local function gq_buf(lines)
      setup({ keymap = false, override_gq = true })
      local buf = new_buf('markdown')
      n.api.nvim_set_option_value('textwidth', 40, { buf = buf })
      n.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      n.api.nvim_win_set_cursor(0, { 1, 0 })
      return buf
    end

    t.it('reflows lists with gq', function()
      local buf = gq_buf({
        '- one two three four five six seven eight nine ten eleven',
      })
      n.feed('gqip')
      t.eq({
        '- one two three four five six seven',
        '  eight nine ten eleven',
      }, get_lines(buf))
    end)

    t.it('falls back to the built-in gq for non-list text', function()
      local prose = {
        'plain prose that is long enough to need wrapping by gq',
        '  and a second line with a different indent',
      }
      local buf = gq_buf(prose)
      n.feed('gqip')
      local got = get_lines(buf)

      n.api.nvim_set_option_value('formatexpr', '', { buf = buf })
      n.api.nvim_buf_set_lines(buf, 0, -1, false, prose)
      n.api.nvim_win_set_cursor(0, { 1, 0 })
      n.command('normal! gqip')
      t.eq(get_lines(buf), got)
    end)

    t.it('repeats gqq with .', function()
      local buf = gq_buf({
        '- one two three four five six seven eight nine ten eleven',
        '1. one two three four five six seven eight nine ten',
      })
      n.feed('gqq')
      n.api.nvim_win_set_cursor(0, { 3, 0 })
      n.feed('.')
      t.eq({
        '- one two three four five six seven',
        '  eight nine ten eleven',
        '1. one two three four five six seven',
        '   eight nine ten',
      }, get_lines(buf))
    end)
  end)

  t.it('reflows the motion target through the mapping', function()
    setup({ keymap = ',q' })
    local buf = new_buf('markdown')
    n.api.nvim_set_option_value('textwidth', 40, { buf = buf })
    n.api.nvim_buf_set_lines(buf, 0, -1, false, {
      '- one two three four five six seven eight nine ten eleven',
    })
    n.api.nvim_win_set_cursor(0, { 1, 0 })
    n.feed(',qip')
    t.eq({
      '- one two three four five six seven',
      '  eight nine ten eleven',
    }, get_lines(buf))
  end)
end)
