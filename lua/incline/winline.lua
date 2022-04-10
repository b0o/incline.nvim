local config = require 'incline.config'
local util = require 'incline.util'

local a = vim.api

local Winline = {}

function Winline:is_alive()
  return a.nvim_win_is_valid(self.target_win)
end

function Winline:buf()
  if self._buf and a.nvim_buf_is_valid(self._buf) then
    return self._buf
  end
  self._buf = a.nvim_create_buf(false, true)
  a.nvim_buf_set_option(self._buf, 'filetype', 'incline')
  return self._buf
end

function Winline:win_config()
  return {
    win = self.target_win,
    width = a.nvim_win_get_width(self.target_win) - 2,
    row = 0,
    col = 2,
    bufpos = { 1000000, 0 },
    relative = 'win',
    style = 'minimal',
    focusable = false,
    height = 1,
    zindex = 50,
  }
end

function Winline:win(opts)
  opts = opts or {}
  if self._win and a.nvim_win_is_valid(self._win) then
    if opts.refresh then
      a.nvim_win_set_config(self._win, self:win_config())
    end
    return self._win
  end
  local wincfg = self:win_config()
  wincfg.noautocmd = true
  self._win = a.nvim_open_win(self:buf(), false, wincfg)
  return self._win
end

function Winline:render(opts)
  if not self:is_alive() then
    return
  end
  opts = opts or {}
  self:win { refresh = opts.refresh }
  local buf = self:buf()
  local target_buf = a.nvim_win_get_buf(self.target_win)
  local data = config.render { buf = target_buf, win = self.target_win }
  a.nvim_buf_set_lines(buf, 0, -1, false, { data })
end

function Winline:destroy()
  if a.nvim_buf_is_valid(self._buf) then
    a.nvim_buf_delete(self._buf, { unload = false })
  end
  if a.nvim_win_is_valid(self._win) then
    a.nvim_win_close(self._win, false)
  end
end

local function make(target_win)
  return setmetatable({
    target_win = target_win,
    _win = nil,
    _buf = nil,
  }, { __index = Winline })
end

return make
