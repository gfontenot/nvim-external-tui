local external_tui = require('external-tui')
local generate_editor_command = external_tui._private.generate_editor_command

describe('generate_editor_command', function()
  it('generates command with default formats', function()
    local result = generate_editor_command('EditLineFromTest')
    assert.equals(
      'nvim --server $NVIM --remote-send \'<cmd>lua EditLineFromTest("%file", %line)<CR>\'',
      result
    )
  end)

  it('uses default formats when nil is passed', function()
    local result = generate_editor_command('EditLineFromTest', nil, nil)
    assert.matches('%%file', result)
    assert.matches('%%line', result)
  end)

  it('uses custom file_format', function()
    local result = generate_editor_command('MyCallback', '${file}', '%line')
    assert.equals(
      'nvim --server $NVIM --remote-send \'<cmd>lua MyCallback("${file}", %line)<CR>\'',
      result
    )
  end)

  it('uses custom line_format', function()
    local result = generate_editor_command('MyCallback', '%file', '${line}')
    assert.equals(
      'nvim --server $NVIM --remote-send \'<cmd>lua MyCallback("%file", ${line})<CR>\'',
      result
    )
  end)

  it('uses both custom formats', function()
    local result = generate_editor_command('MyCallback', '{{file}}', '{{line}}')
    assert.equals(
      'nvim --server $NVIM --remote-send \'<cmd>lua MyCallback("{{file}}", {{line}})<CR>\'',
      result
    )
  end)

  it('includes callback name in lua command', function()
    local result = generate_editor_command('CustomCallback')
    assert.matches('CustomCallback', result)
  end)

  it('contains server flag', function()
    local result = generate_editor_command('Test')
    assert.matches('%-%-server', result)
  end)

  it('contains remote-send flag', function()
    local result = generate_editor_command('Test')
    assert.matches('%-%-remote%-send', result)
  end)

  it('references NVIM environment variable', function()
    local result = generate_editor_command('Test')
    assert.matches('%$NVIM', result)
  end)
end)
