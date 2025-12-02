local M = {}

---@class external-tui.AddOpts
---@field user_cmd string Neovim command name to create
---@field cmd string External command to execute
---@field text_flag? string Flag for passing selected text
---@field text_arg? string @deprecated Use text_flag instead
---@field editor_flag? string Flag for passing editor command
---@field file_format? string Template for file path (default: '%file')
---@field line_format? string Template for line number (default: '%line')
---@field pre_launch? fun(text: string?): nil Called before launching TUI
---@field post_callback? fun(file_path: string, line: integer): nil Called after file selection

---@class external-tui.AddResult
---@field editor_command string Command string for external tool config
---@field callback_name string Name of generated callback function

---@class external-tui.TerminalProviderConfig
---@field snacks? table Snacks terminal config @see https://github.com/folke/snacks.nvim/blob/main/docs/terminal.md
---@field builtin? external-tui.BuiltinConfig Builtin terminal config

---@class external-tui.SetupOpts
---@field terminal_provider? 'snacks'|'builtin'|external-tui.TerminalProviderConfig

---@class external-tui.NormalizedProvider
---@field name? 'snacks'|'builtin'
---@field config table

-- Plugin configuration
local config = {
  terminal_provider = nil, -- string ('snacks'|'builtin') or table ({ snacks = {...} } | { builtin = {...} })
}

---Normalize terminal_provider to { name, config } format
---@param provider? string|external-tui.TerminalProviderConfig
---@return external-tui.NormalizedProvider
local function normalize_terminal_provider(provider)
  if provider == nil then
    return { name = nil, config = {} }
  elseif type(provider) == 'string' then
    return { name = provider, config = {} }
  elseif type(provider) == 'table' then
    if provider.snacks then
      return { name = 'snacks', config = provider.snacks }
    elseif provider.builtin then
      return { name = 'builtin', config = provider.builtin }
    end
  end
  return { name = nil, config = {} }
end

-- Store terminal references for each registered tool
local terminals = {}

---Configure the plugin
---@param opts? external-tui.SetupOpts
function M.setup(opts)
  opts = opts or {}
  if opts.terminal_provider then
    config.terminal_provider = opts.terminal_provider
  end
end

---Extract text from visual selection
---@return string
local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_line = end_pos[2] - 1
  local end_col = end_pos[3]

  local lines = vim.api.nvim_buf_get_text(0, start_line, start_col, end_line, end_col, {})
  return table.concat(lines, '\n')
end

---Generate callback function name from command name
---@param user_cmd string
---@return string
local function generate_callback_name(user_cmd)
  return 'EditLineFrom' .. user_cmd
end

---Generate the editor command string for the external tool's config
---@param callback_name string
---@param file_format? string
---@param line_format? string
---@return string
local function generate_editor_command(callback_name, file_format, line_format)
  file_format = file_format or '%file'
  line_format = line_format or '%line'

  return string.format(
    'nvim --server $NVIM --remote-send \'<cmd>lua %s("%s", %s)<CR>\'',
    callback_name,
    file_format,
    line_format
  )
end

---Add a new external TUI tool integration
---@param opts external-tui.AddOpts
---@return external-tui.AddResult
function M.add(opts)
  -- Validate required options
  assert(opts.user_cmd, 'user_cmd is required')
  assert(opts.cmd, 'cmd is required')

  -- Handle deprecated text_arg option
  if opts.text_arg then
    vim.deprecate('text_arg', 'text_flag', '1.0', 'external-tui', false)
    opts.text_flag = opts.text_flag or opts.text_arg
  end

  local user_cmd = opts.user_cmd
  local cmd = opts.cmd
  local text_flag = opts.text_flag
  local editor_flag = opts.editor_flag
  local file_format = opts.file_format or '%file'
  local line_format = opts.line_format or '%line'
  local pre_launch = opts.pre_launch
  local post_callback = opts.post_callback

  -- Generate callback function name
  local callback_name = generate_callback_name(user_cmd)

  -- Generate the editor command string
  local editor_command = generate_editor_command(callback_name, file_format, line_format)

  -- Build the full command for the external tool
  local full_cmd = cmd
  if editor_flag then
    full_cmd = full_cmd .. ' ' .. editor_flag .. '="' .. editor_command:gsub('"', '\\"') .. '"'
  end

  -- Create the terminal opener function
  local function open_tui(args)
    local search_text = nil

    -- Handle range (visual selection)
    if args.range > 0 then
      search_text = get_visual_selection()
    -- Handle arguments
    elseif args.args and args.args ~= '' then
      search_text = args.args
    end

    -- Call pre-launch hook if provided
    if pre_launch then
      pre_launch(search_text)
    end

    -- Build command with search text if provided
    local launch_cmd = full_cmd
    if search_text and text_flag then
      -- Escape the search text for shell
      local escaped_text = vim.fn.shellescape(search_text)
      launch_cmd = launch_cmd .. ' ' .. text_flag .. ' ' .. escaped_text
    end

    -- Open terminal and store reference
    local provider_opts = normalize_terminal_provider(config.terminal_provider)
    terminals[user_cmd] = require('external-tui.terminal').open(launch_cmd, {
      provider = provider_opts.name,
      config = provider_opts.config,
    })
  end

  -- Register the global callback function
  _G[callback_name] = function(file_path, line)
    -- Close the terminal if it's open
    local term = terminals[user_cmd]
    if term and not term.closed then
      term:close()
    end

    -- Check if file is already open to avoid redundant operations
    local current_path = vim.fn.expand('%:p')
    local target_path = vim.fn.fnamemodify(file_path, ':p')

    if current_path ~= target_path then
      vim.cmd.edit(vim.fn.fnameescape(file_path))
    end

    -- Jump to the specified line
    vim.api.nvim_win_set_cursor(0, { line, 0 })

    -- Call post-callback hook if provided
    if post_callback then
      post_callback(file_path, line)
    end
  end

  -- Create the user command
  vim.api.nvim_create_user_command(user_cmd, open_tui, {
    range = true,
    nargs = '*',
    desc = 'Open ' .. cmd .. ' TUI',
  })

  -- Return the editor command for the user to configure in their tool's config
  return {
    editor_command = editor_command,
    callback_name = callback_name,
  }
end

-- Expose private functions for testing
M._private = {
  get_visual_selection = get_visual_selection,
  generate_callback_name = generate_callback_name,
  generate_editor_command = generate_editor_command,
  normalize_terminal_provider = normalize_terminal_provider,
}

return M
