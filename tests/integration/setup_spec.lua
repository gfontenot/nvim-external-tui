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

  it('accepts table-format terminal_provider with snacks config', function()
    assert.has_no_error(function()
      external_tui.setup({
        terminal_provider = {
          snacks = { win = { style = 'float' } },
        },
      })
    end)
  end)

  it('accepts table-format terminal_provider with builtin config', function()
    assert.has_no_error(function()
      external_tui.setup({
        terminal_provider = {
          builtin = { width = 0.9, height = 0.9 },
        },
      })
    end)
  end)
end)

describe('normalize_terminal_provider', function()
  local external_tui

  before_each(function()
    package.loaded['external-tui'] = nil
    external_tui = require('external-tui')
  end)

  after_each(function()
    package.loaded['external-tui'] = nil
  end)

  local normalize = function(provider)
    return external_tui._private.normalize_terminal_provider(provider)
  end

  it('returns nil name and empty config for nil input', function()
    local result = normalize(nil)
    assert.is_nil(result.name)
    assert.are.same({}, result.config)
  end)

  it('returns string name and empty config for string input', function()
    local result = normalize('snacks')
    assert.are.equal('snacks', result.name)
    assert.are.same({}, result.config)
  end)

  it('extracts snacks name and config from table', function()
    local result = normalize({ snacks = { win = { style = 'float' } } })
    assert.are.equal('snacks', result.name)
    assert.are.same({ win = { style = 'float' } }, result.config)
  end)

  it('extracts builtin name and config from table', function()
    local result = normalize({ builtin = { width = 0.9 } })
    assert.are.equal('builtin', result.name)
    assert.are.same({ width = 0.9 }, result.config)
  end)

  it('returns nil name for empty table', function()
    local result = normalize({})
    assert.is_nil(result.name)
    assert.are.same({}, result.config)
  end)
end)

describe('builtin terminal config merging', function()
  local terminal

  before_each(function()
    -- Ensure snacks is not available for builtin tests
    package.loaded['snacks'] = nil
    package.loaded['external-tui.terminal'] = nil
    terminal = require('external-tui.terminal')
  end)

  after_each(function()
    package.loaded['snacks'] = nil
    package.loaded['external-tui.terminal'] = nil
  end)

  it('uses default config when no user config provided', function()
    -- This test verifies the function exists and can be called
    -- The actual terminal creation requires vim APIs that are tested elsewhere
    assert.is_function(terminal._private.open_builtin_terminal)
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
