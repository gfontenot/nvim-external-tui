describe('M.add command creation', function()
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
    -- Clean up created commands and globals
    pcall(vim.api.nvim_del_user_command, 'TestCmd')
    pcall(vim.api.nvim_del_user_command, 'AnotherCmd')
    _G['EditLineFromTestCmd'] = nil
    _G['EditLineFromAnotherCmd'] = nil
    package.loaded['snacks'] = nil
    package.loaded['external-tui.terminal'] = nil
    package.loaded['external-tui'] = nil
  end)

  it('creates user command with specified name', function()
    external_tui.add({
      user_cmd = 'TestCmd',
      cmd = 'test-tool',
    })

    local commands = vim.api.nvim_get_commands({})
    assert.is_not_nil(commands.TestCmd)
  end)

  it('command accepts arguments', function()
    external_tui.add({
      user_cmd = 'TestCmd',
      cmd = 'test-tool',
    })

    local commands = vim.api.nvim_get_commands({})
    assert.equals('*', commands.TestCmd.nargs)
  end)

  it('command has descriptive help text', function()
    external_tui.add({
      user_cmd = 'TestCmd',
      cmd = 'my-custom-tool',
    })

    local commands = vim.api.nvim_get_commands({})
    assert.matches('my%-custom%-tool', commands.TestCmd.definition)
  end)

  it('can create multiple commands', function()
    external_tui.add({ user_cmd = 'TestCmd', cmd = 'tool1' })
    external_tui.add({ user_cmd = 'AnotherCmd', cmd = 'tool2' })

    local commands = vim.api.nvim_get_commands({})
    assert.is_not_nil(commands.TestCmd)
    assert.is_not_nil(commands.AnotherCmd)
  end)
end)
