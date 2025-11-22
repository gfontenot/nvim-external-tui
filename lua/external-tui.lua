local M = {}

-- Store terminal references for each registered tool
local terminals = {}

-- Extract text from visual selection
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

-- Generate callback function name from command name
local function generate_callback_name(user_cmd)
  return 'EditLineFrom' .. user_cmd
end

-- Generate the editor command string for the external tool's config
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

-- NOTE: I think i good feature when user can custom the floating window
-- Open terminal in floating window
local function open_floating_terminal(cmd)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  vim.api.nvim_set_option_value('winhl', 'Normal:Normal', { win = win })

  ---@diagnostic disable-next-line: deprecated
  -- Start terminal in the buffer
  vim.fn.termopen(cmd, { -- deprecated but okay
    on_exit = function()
      -- Mark terminal as closed when it exits
      for k, term_data in pairs(terminals) do
        if term_data.buf == buf then
          terminals[k].closed = true
          break
        end
      end
    end,
  })

  -- Enter terminal mode
  vim.cmd('startinsert')

  return {
    buf = buf,
    win = win,
    closed = false,
    toggle = function(self)
      if vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_close(self.win, true)
      end
      if vim.api.nvim_buf_is_valid(self.buf) then
        vim.api.nvim_buf_delete(self.buf, { force = true })
      end
      self.closed = true
    end,
  }
end

-- Add a new external TUI tool integration
function M.add(opts)
  -- Validate required options
  assert(opts.user_cmd, 'user_cmd is required')
  assert(opts.cmd, 'cmd is required')

  local user_cmd = opts.user_cmd
  local cmd = opts.cmd
  local text_arg = opts.text_arg
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
    if search_text and text_arg then
      -- Escape the search text for shell
      local escaped_text = vim.fn.shellescape(search_text)
      launch_cmd = launch_cmd .. ' ' .. text_arg .. ' ' .. escaped_text
    end

    -- Open terminal in floating window and store reference
    -- NOTE: No more snacks just use external neovim floeating window
    -- see: https://youtu.be/5PIiKDES_wc?si=QncNmwbXJP2lZKhs
    terminals[user_cmd] = open_floating_terminal(launch_cmd)
  end

  -- Register the global callback function
  _G[callback_name] = function(file_path, line)
    -- Close the terminal if it's open
    local term = terminals[user_cmd]
    if term and not term.closed then
      term:toggle()
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

return M
