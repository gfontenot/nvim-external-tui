# nvim-external-tui

A Neovim plugin that allows you to seamlessly integrate external TUIs (for
example, an application like [scooter](https://github.com/thomasschafer/scooter)) that can be launched from Neovim
and then re-use the original Neovim instance for editing.

## Why?

There are a number of tools that have support for configuring external editor
commands, but they don't all need to have dedicated Neovim plugins. Tools like
[yazi](https://github.com/sxyazi/yazi) and [lazygit](https://github.com/jesseduffield/lazygit) have enough community support (and additional
feature requirements) that make it reasonable to have a dedicated plugin to
support their integration, but we don't always need/want that level of
integration from our tools. Often just being able to configure the external
editor (and adding a command to launch the tool) is more than enough. That's
where nvim-external-tui comes in.

## Features

- Simple API for registering external TUI tools
- Automatic command creation with visual selection support
- Terminal window management (floating by default)
- Bidirectional communication between Neovim and external tools
- Support for pre-launch and post-callback hooks
- Automatic callback function generation

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'gfontenot/nvim-external-tui',
  dependencies = {
    'folke/snacks.nvim', -- Optional: provides enhanced terminal management
  },
  config = function()
    -- Your tool configurations here
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'gfontenot/nvim-external-tui',
  requires = {
    'folke/snacks.nvim', -- Optional: provides enhanced terminal management
  },
  config = function()
    -- Your tool configurations here
  end
}
```

## Usage

### Basic Example

Assume you have a tool named `neatui` that does neat things in a tui, and
allows you to launch an editor to perform manual tasks. It has the following
API:

```
❯ neatui --help
Usage: neatui [OPTIONS]

Options:
      --editor <EDITOR>             Command to use when launching external editor
      --prefill-text <SEARCH_TEXT>  Text to prefill a field that will be used to do neat things
  -h, --help                        Print help
  -V, --version                     Print version
```

To integrate this tool into Neovim yourself, you'd need to maintain a number
of custom configuration pieces:

1. A user command that is able to launch a terminal for this command
   (including support for ranges and arguments to prefill text)
2. The code required to present that terminal (including state tracking in
   order to be able to dismiss the terminal when finished)
3. The editor command to call back into Neovim using `--remote-send`

This isn't an _overwhelming_ amount of configuration, but if you start to add
multiple tools that need this kind of configuration it can get out of hand
quickly. However, with nvim-external-tui, integration looks like this:

```lua
local external_tui = require('external-tui')

local config = external_tui.add({
  user_cmd = 'Neatui',          -- Creates :Neatui command
  cmd = 'neatui',               -- External command to run
  text_flag = '--prefill-text', -- Flag to pass selected/input text to the command
  editor_command = '--editor',  -- Flag for configuring the external editor
})
```

This creates a `:Neatui` command that:
- Launches a floating window running the `neatui` application
- Accepts visual selection: `:'<,'>Scooter`
- Accepts arguments: `:Scooter search_term`
- Opens without arguments: `:Scooter`
- Re-uses the original Neovim instance when performing editor actions

### Getting the Editor Command

If your command doesn't support overriding the editor command via the cli and
instead requires it to be specified in an external config, you can still use
this plugin and it can still help you configure the bidirectional support. The
`add()` function returns a table with the editor command that needs to be
configured in your external tool. This table can be used to print out the
commands you need to add to your external config in order to get the
integration working:

```lua
local config = external_tui.add({ ... })

print(config.editor_command)
-- Output: nvim --server $NVIM --remote-send '<cmd>lua EditLineFromNeatui("%file", %line)<CR>'
print(config.callback_name)
-- Output: EditLineFromNeatui
```

### Advanced Usage

nvim-external-tui also supports optional pre/post launch hooks that you can
use to perform actions automatically:

```lua
external_tui.add({
  user_cmd = 'Neatui',
  cmd = 'neatui',
  text_flag = '--prefill-text',
  editor_flag = '--editor',

  -- Called before launching the TUI
  pre_launch = function(text)
    print("Launching with text:", text)
    vim.cmd('write') -- Save current buffer
  end,

  -- Called after opening the file
  post_callback = function(file_path, line)
    vim.cmd('normal! zz') -- Center the line on screen
  end,
})
```

## API Reference

### `external_tui.add(opts)`

Register a new external TUI tool integration.

#### Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `user_cmd` | `string` | Yes | - | Neovim command name (e.g., 'Scooter' creates `:Scooter`) |
| `cmd` | `string` | Yes | - | External command to execute (e.g., 'scooter') |
| `text_flag` | `string` | No | `nil` | Flag for passing selected text (e.g., '--search-text') |
| `editor_flag` | `string` | No | `nil` | Flag for passing editor command (e.g., '--editor') |
| `file_format` | `string` | No | `'%file'` | Template variable for file path in tool's config |
| `line_format` | `string` | No | `'%line'` | Template variable for line number in tool's config |
| `pre_launch` | `function` | No | `nil` | Hook called before launching TUI: `function(search_text)` |
| `post_callback` | `function` | No | `nil` | Hook called after opening file: `function(file_path, line)` |

#### Returns

Table with:
- `editor_command`: String to configure in external tool
- `callback_name`: Name of the generated callback function

### Template Variables

The editor command uses template variables that the external tool should replace:
- `%file` - Full path to the selected file
- `%line` - Line number to jump to

These defaults can be overridden by passing the `file_format` and `line_format` options.

## Example Config: [scooter](https://github.com/thomasschafer/scooter)
```lua
local external_tui = require('external-tui')

external_tui.add({
  user_cmd = 'Scooter',
  cmd = 'scooter',
  text_flag = '--search-text',
  editor_flag = '--editor-command',
})
```

For versions of Scooter before 0.8.4, you would need to omit the `editor_flag`
option in the plugin config, and instead set the command in the Scooter config
directly:
```toml
# ~/.config/scooter/config.toml
[editor_open]
command = "nvim --server $NVIM --remote-send '<cmd>lua EditLineFromScooter(\"%file\", %line)<CR>'"
```

## Requirements

- Neovim >= 0.9.0
- [snacks.nvim](https://github.com/folke/snacks.nvim) (optional) - If installed, snacks.nvim will be used for terminal management. Otherwise, a builtin floating terminal is used.

## Acknowledgements

This plugin is heavily inspired by the Neovim integration for
[scooter](https://github.com/thomasschafer/scooter), as evidenced by the heavy use of that tool in the examples.
The original code used for this plugin is a modified version of the sample
code in that project, generalized for arbitrary tool usage and wrapped up in
a plugin format.
