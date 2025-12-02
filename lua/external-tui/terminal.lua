local M = {}

-- Check if snacks.nvim is available
local has_snacks, snacks = pcall(require, 'snacks')

-- Builtin floating terminal implementation
local function open_builtin_terminal(cmd, user_config)
  local default_config = {
    width = 0.8,
    height = 0.8,
    border = 'rounded',
    style = 'minimal',
  }
  local cfg = user_config or default_config

  local width = math.floor(vim.o.columns * cfg.width)
  local height = math.floor(vim.o.lines * cfg.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = cfg.style,
    border = cfg.border,
  })

  vim.api.nvim_set_option_value('winhl', 'Normal:Normal', { win = win })

  local term = {
    buf = buf,
    win = win,
    closed = false,
  }

  ---@diagnostic disable-next-line: deprecated
  vim.fn.termopen(cmd, {
    on_exit = function()
      term.closed = true
    end,
  })

  vim.cmd('startinsert')

  function term:close()
    if vim.api.nvim_win_is_valid(self.win) then
      vim.api.nvim_win_close(self.win, true)
    end
    if vim.api.nvim_buf_is_valid(self.buf) then
      vim.api.nvim_buf_delete(self.buf, { force = true })
    end
    self.closed = true
  end

  return term
end

-- Open terminal using snacks.nvim
local function open_snacks_terminal(cmd, user_config)
  local default_config = { win = { style = 'float' } }
  local cfg = user_config or default_config
  local term = snacks.terminal.open(cmd, cfg)
  return {
    closed = term.closed,
    close = function(self)
      term:toggle()
      self.closed = true
    end,
  }
end

-- Open terminal using specified or auto-detected backend
function M.open(cmd, opts)
  opts = opts or {}
  local provider = opts.provider
  local user_config = opts.config

  if provider == 'snacks' then
    if has_snacks then
      return open_snacks_terminal(cmd, user_config)
    else
      vim.notify('external-tui: snacks.nvim not available, falling back to builtin terminal', vim.log.levels.WARN)
      return open_builtin_terminal(cmd, user_config)
    end
  elseif provider == 'builtin' then
    return open_builtin_terminal(cmd, user_config)
  else
    -- Auto-detect (default behavior)
    if has_snacks then
      return open_snacks_terminal(cmd, user_config)
    else
      return open_builtin_terminal(cmd, user_config)
    end
  end
end

-- Expose for testing
M._private = {
  open_builtin_terminal = open_builtin_terminal,
  has_snacks = has_snacks,
}

return M
