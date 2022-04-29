local config = require 'incline.config'
local highlight = require 'incline.highlight'
local util = require 'incline.util'

local a = vim.api

local M = {}

function M.parse_render_result(node, offset)
  if type(node) == 'string' or type(node) == 'number' then
    return { text = tostring(node), hls = {} }
  end
  assert(type(node) == 'table', 'expected render result node to be string or table')
  offset = offset or 0
  local res = {
    text = '',
    hls = {},
  }
  for _, child in ipairs(node) do
    local inner_content = M.parse_render_result(child, offset + #res.text)
    local new_text = inner_content.text or ''
    if #new_text > 0 then
      res.text = res.text .. new_text
      vim.list_extend(res.hls, inner_content.hls)
    end
  end
  local group = node.group
  if not group then
    local keys = util.tbl_onlykeys(node)
    if not vim.tbl_isempty(keys) then
      group = highlight.register(keys)
    end
  end
  if group then
    table.insert(res.hls, 1, {
      group = group,
      range = { offset, offset + #res.text },
    })
  end
  return res
end

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
  return self.content and self.content.text and a.nvim_strwidth(self.content.text) or 0
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
    if type(v) == 'table' then
      v = highlight.register(v)
    end
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

-- TODO: Avoid unnecessary renders after :focus()/:blur()/:hide()/:show() are called
function Winline:render(opts)
  if self.hidden or not self:is_alive() then
    return
  end
  opts = opts or {}

  local render_result = config.render {
    buf = a.nvim_win_get_buf(self.target_win),
    win = self.target_win,
    focused = self.focused,
  }
  if type(render_result) ~= 'table' then
    render_result = { render_result }
  end

  local offset = 0
  if config.window.padding.left > 0 then
    offset = config.window.padding.left
  end

  local content = M.parse_render_result(render_result, offset)

  if config.window.padding.left > 0 then
    local pad = string.rep(config.window.padding_char, config.window.padding.left)
    content.text = pad .. content.text
  end
  if config.window.padding.right > 0 then
    local pad = string.rep(config.window.padding_char, config.window.padding.right)
    content.text = content.text .. pad
  end
  if config.window.padding.right > 0 then
    table.insert(render_result, string.rep(config.window.padding_char, config.window.padding.right))
  end

  local prev_content_len = (self.content and self.content.text) and #self.content.text or 0
  local content_text_changed = prev_content_len ~= content.text
  local content_text_len_changed = not self.content or not self.content.text or #self.content.text ~= #content.text
  local content_hls_changed = not self.content
    or not self.content.hls
    or not vim.deep_equal(self.content.hls, content.hls)

  self.content = content

  self:win { refresh = opts.refresh or content_text_len_changed }
  local buf = self:buf()

  if content_text_changed then
    a.nvim_buf_set_lines(buf, 0, -1, false, { self.content.text })
  end
  if content_text_changed or content_hls_changed then
    a.nvim_buf_clear_namespace(buf, highlight.namespace, 0, -1)
    for _, hl in ipairs(content.hls) do
      a.nvim_buf_add_highlight(buf, highlight.namespace, hl.group, 0, unpack(hl.range))
    end
  end
end

function Winline:hide()
  if self.hidden then
    return
  end
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
  if not self.hidden then
    return
  end
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

return setmetatable({}, {
  __index = M,
  __call = function(_, ...)
    return make(...)
  end,
})
