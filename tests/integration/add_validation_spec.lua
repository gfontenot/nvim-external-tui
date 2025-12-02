describe('M.add validation', function()
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
    package.loaded['snacks'] = nil
    package.loaded['external-tui.terminal'] = nil
    package.loaded['external-tui'] = nil
  end)

  it('throws error when user_cmd is missing', function()
    assert.has_error(function()
      external_tui.add({ cmd = 'test' })
    end, 'user_cmd is required')
  end)

  it('throws error when cmd is missing', function()
    assert.has_error(function()
      external_tui.add({ user_cmd = 'Test' })
    end, 'cmd is required')
  end)

  it('throws error when both required options are missing', function()
    assert.has_error(function()
      external_tui.add({})
    end)
  end)

  it('succeeds with minimal required options', function()
    assert.has_no_error(function()
      external_tui.add({
        user_cmd = 'TestValidation',
        cmd = 'test-tool',
      })
    end)
    -- Clean up
    pcall(vim.api.nvim_del_user_command, 'TestValidation')
    _G['EditLineFromTestValidation'] = nil
  end)
end)
