describe('M.add return value and callbacks', function()
  local external_tui

  before_each(function()
    -- Mock snacks dependency
    package.loaded['snacks'] = {
      terminal = {
        open = function()
          return { closed = false, toggle = function() end }
        end,
      },
    }
    package.loaded['external-tui.terminal'] = nil
    package.loaded['external-tui'] = nil
    external_tui = require('external-tui')
  end)

  after_each(function()
    -- Clean up globals and commands
    _G['EditLineFromTestCmd'] = nil
    _G['EditLineFromCustom'] = nil
    pcall(vim.api.nvim_del_user_command, 'TestCmd')
    pcall(vim.api.nvim_del_user_command, 'Custom')
    package.loaded['snacks'] = nil
    package.loaded['external-tui.terminal'] = nil
    package.loaded['external-tui'] = nil
  end)

  it('returns editor_command string', function()
    local result = external_tui.add({
      user_cmd = 'TestCmd',
      cmd = 'test-tool',
    })

    assert.is_string(result.editor_command)
    assert.matches('nvim %-%-server', result.editor_command)
    assert.matches('EditLineFromTestCmd', result.editor_command)
  end)

  it('returns callback_name', function()
    local result = external_tui.add({
      user_cmd = 'TestCmd',
      cmd = 'test-tool',
    })

    assert.equals('EditLineFromTestCmd', result.callback_name)
  end)

  it('registers global callback function', function()
    external_tui.add({
      user_cmd = 'TestCmd',
      cmd = 'test-tool',
    })

    assert.is_function(_G['EditLineFromTestCmd'])
  end)

  it('editor_command uses custom file_format', function()
    local result = external_tui.add({
      user_cmd = 'Custom',
      cmd = 'tool',
      file_format = '${filepath}',
    })

    assert.matches('%${filepath}', result.editor_command)
  end)

  it('editor_command uses custom line_format', function()
    local result = external_tui.add({
      user_cmd = 'Custom',
      cmd = 'tool',
      line_format = '${linenum}',
    })

    assert.matches('%${linenum}', result.editor_command)
  end)
end)

describe('callback function behavior', function()
  local external_tui

  before_each(function()
    -- Mock snacks dependency
    package.loaded['snacks'] = {
      terminal = {
        open = function()
          return { closed = false, toggle = function() end }
        end,
      },
    }
    package.loaded['external-tui.terminal'] = nil
    package.loaded['external-tui'] = nil
    external_tui = require('external-tui')
  end)

  after_each(function()
    _G['EditLineFromTestCmd'] = nil
    pcall(vim.api.nvim_del_user_command, 'TestCmd')
    package.loaded['snacks'] = nil
    package.loaded['external-tui.terminal'] = nil
    package.loaded['external-tui'] = nil
  end)

  it('callback opens file at specified line', function()
    external_tui.add({
      user_cmd = 'TestCmd',
      cmd = 'test-tool',
    })

    local tmpfile = vim.fn.tempname()
    vim.fn.writefile({ 'line1', 'line2', 'line3' }, tmpfile)

    _G['EditLineFromTestCmd'](tmpfile, 2)

    local cursor = vim.api.nvim_win_get_cursor(0)
    assert.equals(2, cursor[1])

    vim.fn.delete(tmpfile)
  end)

  it('callback calls post_callback hook', function()
    local hook_called = false
    local hook_args = {}

    external_tui.add({
      user_cmd = 'TestCmd',
      cmd = 'test-tool',
      post_callback = function(file, line)
        hook_called = true
        hook_args = { file = file, line = line }
      end,
    })

    local tmpfile = vim.fn.tempname()
    vim.fn.writefile({ 'line1', 'line2', 'line3', 'line4', 'line5' }, tmpfile)

    _G['EditLineFromTestCmd'](tmpfile, 5)

    assert.is_true(hook_called)
    assert.equals(tmpfile, hook_args.file)
    assert.equals(5, hook_args.line)

    vim.fn.delete(tmpfile)
  end)

  it('callback skips file open if already viewing target file', function()
    external_tui.add({
      user_cmd = 'TestCmd',
      cmd = 'test-tool',
    })

    local tmpfile = vim.fn.tempname()
    vim.fn.writefile({ 'line1', 'line2', 'line3' }, tmpfile)

    -- First open the file
    vim.cmd.edit(tmpfile)

    -- Now call callback for same file - should not error
    assert.has_no_error(function()
      _G['EditLineFromTestCmd'](tmpfile, 2)
    end)

    local cursor = vim.api.nvim_win_get_cursor(0)
    assert.equals(2, cursor[1])

    vim.fn.delete(tmpfile)
  end)
end)
