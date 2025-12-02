describe('M.setup', function()
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

  it('exists as a function', function()
    assert.is_function(external_tui.setup)
  end)

  it('accepts empty options', function()
    assert.has_no_error(function()
      external_tui.setup({})
    end)
  end)

  it('accepts nil options', function()
    assert.has_no_error(function()
      external_tui.setup()
    end)
  end)

  it('accepts terminal_provider option', function()
    assert.has_no_error(function()
      external_tui.setup({ terminal_provider = 'builtin' })
    end)
  end)
end)

describe('terminal provider selection', function()
  before_each(function()
    package.loaded['snacks'] = nil
    package.loaded['external-tui.terminal'] = nil
    package.loaded['external-tui'] = nil
  end)

  after_each(function()
    package.loaded['snacks'] = nil
    package.loaded['external-tui.terminal'] = nil
    package.loaded['external-tui'] = nil
  end)

  it('terminal module exposes has_snacks for testing', function()
    local terminal = require('external-tui.terminal')
    assert.is_boolean(terminal._private.has_snacks)
  end)
end)
