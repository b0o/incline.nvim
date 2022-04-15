local config = require 'incline.config'

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

function Winline:win_config(opts)
  opts = opts or {}
  local cfg = {
    win = self.target_win,
    relative = 'win',
    style = 'minimal',
    focusable = false,
    height = 1,
    zindex = config.window.zindex,
    anchor = 'SW',
    col = 0,
  }

  local win_height = a.nvim_win_get_height(self.target_win)
  local win_width = a.nvim_win_get_width(self.target_win)
  local cw = config.window

  if cw.width == 'fill' then
    cfg.width = win_width
  elseif cw.width == 'fit' then
    cfg.width = math.min(opts.content_len, win_width)
  elseif type(cw.width) == 'number' then
    if cw.width > 0 and cw.width <= 1 then
      cfg.width = math.floor(cw.width * win_width)
    else
      cfg.width = cw.width
    end
  end

  local placement = cw.placement
  if placement.vertical == 'bottom' then
    cfg.row = win_height - cw.margin.vertical.bottom
  elseif placement.vertical == 'top' then
    -- TODO: detect if window is below tabline and, if so, avoid overlapping it
    -- Then, users can set margin.vertical.top to 0 and let the winline overlap
    -- the window separator but not the tabline.
    cfg.row = cw.margin.vertical.top
  end

  if placement.horizontal == 'left' then
    cfg.col = cw.margin.horizontal.left
  elseif placement.horizontal == 'right' then
    cfg.col = win_width - opts.content_len - cw.margin.horizontal.right
  elseif placement.horizontal == 'center' then
    cfg.col = math.floor((win_width / 2) - (cfg.width / 2))
  end

  cfg.col = math.max(cfg.col, cw.margin.horizontal.left)

  cfg.width = math.min(cfg.width, win_width - (cw.margin.horizontal.left + cw.margin.horizontal.right))
  cfg.width = math.max(cfg.width, 1)

  return cfg
end

function Winline:win(opts)
  if self.hidden then
    return
  end
  opts = opts or {}

  if self._win and a.nvim_win_is_valid(self._win) then
    if opts.refresh then
      a.nvim_win_set_config(self._win, self:win_config { content_len = opts.content_len })
    end
    return self._win
  end

  local wincfg = self:win_config { content_len = opts.content_len }
  wincfg.noautocmd = true
  self._win = a.nvim_open_win(self:buf(), false, wincfg)
  return self._win
end

function Winline:render(opts)
  if self.hidden or not self:is_alive() then
    return
  end
  opts = opts or {}

  local target_buf = a.nvim_win_get_buf(self.target_win)
  local content = config.render { buf = target_buf, win = self.target_win }

  if config.window.padding.left > 0 then
    local pad = string.rep(config.window.padding_char, config.window.padding.left)
    content = pad .. content
  end
  if config.window.padding.right > 0 then
    local pad = string.rep(config.window.padding_char, config.window.padding.right)
    content = content .. pad
  end

  if self.content and #content ~= #self.content then
    opts.refresh = true
  end

  self.content = content
  self:win { refresh = opts.refresh, content_len = #self.content }
  a.nvim_buf_set_lines(self:buf(), 0, -1, false, { self.content })
end

function Winline:hide()
  self.hidden = true
  if self._win and a.nvim_win_is_valid(self._win) then
    a.nvim_win_close(self._win, false)
  end
end

function Winline:show()
  self.hidden = false
  self:render { refresh = true }
end

function Winline:toggle()
  if self.hidden then
    self:show()
  else
    self:hide()
  end
end

function Winline:destroy()
  if self._buf and a.nvim_buf_is_valid(self._buf) then
    a.nvim_buf_delete(self._buf, { unload = false })
  end
  if self._win and a.nvim_win_is_valid(self._win) then
    a.nvim_win_close(self._win, false)
  end
end

local function make(target_win)
  return setmetatable({
    target_win = target_win,
    hidden = false,
    content = nil,
    _win = nil,
    _buf = nil,
  }, { __index = Winline })
end

return make
