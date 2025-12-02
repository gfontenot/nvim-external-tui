local M = {}

-- Check if snacks.nvim is available
local has_snacks, snacks = pcall(require, 'snacks')

-- Builtin floating terminal implementation
local function open_builtin_terminal(cmd)
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

-- Open terminal using best available backend
function M.open(cmd)
  if has_snacks then
    local term = snacks.terminal.open(cmd, { win = { style = 'float' } })
    return {
      closed = term.closed,
      close = function(self)
        term:toggle()
        self.closed = true
      end,
    }
  else
    return open_builtin_terminal(cmd)
  end
end

-- Expose for testing
M._private = {
  open_builtin_terminal = open_builtin_terminal,
  has_snacks = has_snacks,
}

return M
