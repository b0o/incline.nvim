local config = require 'incline.config'
local highlight = require 'incline.highlight'

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

function Winline:get_content_len()
  return self.content and vim.fn.strchars(self.content.text) or 0
end

function Winline:get_win_config(opts)
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
    cfg.width = math.min(self:get_content_len(), win_width)
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
    cfg.col = win_width - self:get_content_len() - cw.margin.horizontal.right
  elseif placement.horizontal == 'center' then
    cfg.col = math.floor((win_width / 2) - (cfg.width / 2))
  end

  cfg.col = math.max(cfg.col, cw.margin.horizontal.left)

  cfg.width = math.min(cfg.width, win_width - (cw.margin.horizontal.left + cw.margin.horizontal.right))
  cfg.width = math.max(cfg.width, 1)

  return cfg
end

function Winline:get_win_opts()
  local winhl = {}
  for k, v in pairs(config.window.winhighlight[self.focused and 'active' or 'inactive']) do
    table.insert(winhl, k .. ':' .. v)
  end
  return vim.tbl_extend('force', config.window.options, {
    winhighlight = table.concat(winhl, ','),
  })
end

function Winline:refresh()
  if not self._win or not a.nvim_win_is_valid(self._win) then
    local wincfg = self:get_win_config()
    wincfg.noautocmd = true
    self._win = a.nvim_open_win(self:buf(), false, wincfg)
  else
    a.nvim_win_set_config(self._win, self:get_win_config())
  end
  for opt, val in pairs(self:get_win_opts()) do
    a.nvim_win_set_option(self._win, opt, val)
  end
end

function Winline:win(opts)
  if self.hidden then
    return
  end
  opts = opts or {}
  if opts.refresh or not (self._win and a.nvim_win_is_valid(self._win)) then
    self:refresh()
  end
  return self._win
end

function Winline:parse_content(content)
  if type(content) == 'string' then
    content = { content }
  end

  if config.window.padding.left > 0 then
    local pad = string.rep(config.window.padding_char, config.window.padding.left)
    table.insert(content, 1, pad)
  end
  if config.window.padding.right > 0 then
    local pad = string.rep(config.window.padding_char, config.window.padding.right)
    table.insert(content, pad)
  end

  local res = { text = '', hls = {} }

  for _, part in ipairs(content) do
    local text
    if type(part) == 'table' then
      text = part[1] or part.text
      part[1] = nil
      part.text = nil
    else
      assert(type(part) == 'string', 'expected table or string')
      text = part
      part = {}
    end
    assert(type(text) == 'string', 'expected text')
    if not vim.tbl_isempty(part) then
      local reslen = #res.text
      table.insert(res.hls, {
        group = part.group or highlight.register(part),
        range = { reslen, reslen + #text },
      })
    end
    res.text = res.text .. text
  end
  return res
end

-- TODO: Avoid unnecessary renders after :focus()/:blur()/:hide()/:show() are called
function Winline:render(opts)
  if self.hidden or not self:is_alive() then
    return
  end
  opts = opts or {}

  local target_buf = a.nvim_win_get_buf(self.target_win)
  local content = self:parse_content(config.render { buf = target_buf, win = self.target_win, focused = self.focused })

  if self.content and not vim.deep_equal(content, self.content) then
    opts.refresh = true
  end

  self.content = content
  self:win { refresh = opts.refresh }
  local buf = self:buf()
  a.nvim_buf_clear_namespace(buf, highlight.namespace, 0, -1)
  a.nvim_buf_set_lines(buf, 0, -1, false, { self.content.text })
  for _, hl in ipairs(content.hls) do
    a.nvim_buf_add_highlight(buf, highlight.namespace, hl.group, 0, unpack(hl.range))
  end
end

function Winline:hide()
  self.hidden = true
  if self._win and a.nvim_win_is_valid(self._win) then
    a.nvim_win_close(self._win, false)
  end
end

function Winline:focus()
  self.focused = true
  if config.hide.focused_win then
    self:hide()
  else
    self:refresh()
  end
end

function Winline:blur()
  self.focused = false
  if config.hide.focused_win then
    self:show()
  else
    self:refresh()
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
    focused = false,
    content = {},
    _win = nil,
    _buf = nil,
  }, { __index = Winline })
end

return make
