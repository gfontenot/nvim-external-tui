local external_tui = require('external-tui')
local generate_callback_name = external_tui._private.generate_callback_name

describe('generate_callback_name', function()
  it('prepends EditLineFrom to command name', function()
    local result = generate_callback_name('Scooter')
    assert.equals('EditLineFromScooter', result)
  end)

  it('handles single character command', function()
    local result = generate_callback_name('X')
    assert.equals('EditLineFromX', result)
  end)

  it('handles command with numbers', function()
    local result = generate_callback_name('Tool123')
    assert.equals('EditLineFromTool123', result)
  end)

  it('handles empty string', function()
    local result = generate_callback_name('')
    assert.equals('EditLineFrom', result)
  end)

  it('preserves case of command name', function()
    local result = generate_callback_name('MyTUITool')
    assert.equals('EditLineFromMyTUITool', result)
  end)

  it('handles lowercase command name', function()
    local result = generate_callback_name('lazygit')
    assert.equals('EditLineFromlazygit', result)
  end)
end)
