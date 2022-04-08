local config = require 'incline.config'
local util = require 'incline.util'

local a = vim.api

local Winline = {}

function Winline:is_valid()
  return a.nvim_win_is_valid(self.parent.win)
end

function Winline:buf()
  if not self:is_valid() then
    return
  end
  if self._buf and a.nvim_buf_is_valid(self._buf) then
    return self._buf
  end
  self._buf = a.nvim_create_buf(false, true)
  a.nvim_buf_set_option(self._buf, 'filetype', 'gl')
  self.dirty = true
  return self._buf
end

function Winline:win_config(opts)
  if not self:is_valid() then
    return
  end
  local c = {
    win = self.parent.win,
    width = a.nvim_win_get_width(self.parent.win) - 2,
    row = 0,
    col = 2,
    bufpos = { 1000000, 0 },
    relative = 'win',
    style = 'minimal',
    focusable = false,
    height = 1,
    zindex = 50,
  }
  if opts then
    c = vim.tbl_extend('force', c, opts)
  end
  return c
end

function Winline:win(opts)
  if not self:is_valid() then
    return
  end
  opts = opts or {}
  if self._win and a.nvim_win_is_valid(self._win) then
    if opts.refresh then
      a.nvim_win_set_config(self._win, self:win_config())
    end
    return self._win
  end
  self._win = a.nvim_open_win(self:buf(), false, self:win_config())
  util.autocmd('WinClosed', {
    pattern = tostring(self.parent.win),
    once = true,
    callback = function()
      vim.schedule(function()
        self:destroy()
      end)
    end,
  })
  util.autocmd('WinClosed', {
    pattern = tostring(self._win),
    once = true,
    callback = function()
      vim.schedule(function()
        self:update { refresh = true }
      end)
    end,
  })
  self.dirty = true
  return self._win
end

function Winline:update(opts)
  if not self:is_valid() then
    return false
  end
  opts = opts or {}
  self:win { refresh = opts.refresh }
  if self.dirty then
    self:render(opts)
  end
end

function Winline:render(opts)
  if not self:is_valid() then
    return false
  end
  opts = opts or {}
  local buf = self:buf()
  if not self.dirty and not opts.refresh then
    return
  end
  local data = config.render(self.parent.buf, self.parent.win)
  a.nvim_buf_set_lines(buf, 0, -1, false, { data })
  self.dirty = false
  return true
end

function Winline:destroy()
  if a.nvim_buf_is_valid(self._buf) then
    a.nvim_buf_delete(self._buf, { unload = false })
  end
  if a.nvim_win_is_valid(self._win) then
    a.nvim_win_close(self._win, false)
  end
end

local function make(parent_win, opts)
  assert(a.nvim_win_is_valid(parent_win), 'invalid window: ' .. parent_win)
  opts = opts or {}
  local parent = {
    win = parent_win,
    buf = a.nvim_win_get_buf(parent_win),
  }
  return setmetatable({
    parent = parent,
    dirty = true,
    _win = nil,
    _buf = nil,
  }, { __index = Winline })
end

return make
