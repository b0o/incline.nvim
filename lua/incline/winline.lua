local config = require 'incline.config'
local highlight = require 'incline.highlight'
local util = require 'incline.util'

local a = vim.api

local M = {}

local HIDE_PERSIST = 1
local HIDE_TEMP = 2

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

  vim.bo[self._buf].filetype = 'incline'
  vim.bo[self._buf].buftype = 'nofile'
  vim.bo[self._buf].bufhidden = 'wipe'
  vim.bo[self._buf].buflisted = false
  vim.bo[self._buf].swapfile = false

  return self._buf
end

function Winline:get_content_len()
  return self.content and self.content.text and a.nvim_strwidth(self.content.text) or 0
end

function Winline:get_win_geom_row()
  local cw = config.window
  local placement = cw.placement
  if placement.vertical == 'top' then
    -- if margin-top is 0, avoid overlapping tabline, and avoid overlapping
    -- statusline if laststatus is not 3

    -- TODO(willothy): this can obviously be simplified a lot, there is a good bit of repetition
    if a.nvim_win_get_position(self.target_win)[1] <= 1 then
      if cw.margin.vertical.top == 0 then
        if
            config.window.overlap.tabline
            -- don't try to overlap tabline if it doesn't exist
            and (vim.o.showtabline > 1 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1))
        then
          return cw.margin.vertical.top - 1
          -- only overlap winbar if it exists and is configured to overlap
        elseif config.window.overlap.winbar or vim.wo[self.target_win].winbar == '' then
          return cw.margin.vertical.top
        else
          return cw.margin.vertical.top + 1
        end
        -- ensure we skip the winbar if we are overlapping it
      elseif config.window.overlap.winbar or vim.wo[self.target_win].winbar == '' then
        return cw.margin.vertical.top - 1
      else
        return cw.margin.vertical.top
      end
    end
    -- only overlap border if user has set it
    if config.window.overlap.borders then
      return cw.margin.vertical.top - 1
    elseif config.window.overlap.winbar == false and vim.wo[self.target_win].winbar ~= '' then
      return cw.margin.vertical.top + 1
    else
      return cw.margin.vertical.top
    end
  elseif placement.vertical == 'bottom' then
    if
        vim.o.laststatus ~= 3
        or (
          (
            a.nvim_win_get_position(self.target_win)[1]
            + a.nvim_win_get_height(self.target_win)
            + 1 -- for global status
          ) == vim.o.lines
        )
    then
      if config.window.overlap.statusline then
        return a.nvim_win_get_height(self.target_win) - cw.margin.vertical.bottom
      else
        return a.nvim_win_get_height(self.target_win) - (cw.margin.vertical.bottom + 1)
      end
    elseif vim.o.laststatus == 3 and config.window.overlap.borders then
      return a.nvim_win_get_height(self.target_win) - cw.margin.vertical.bottom
    end

    return a.nvim_win_get_height(self.target_win) - (cw.margin.vertical.bottom + 1)
  end
  assert(false, 'invalid value for placement.vertical: ' .. tostring(placement.vertical))
end

function Winline:get_win_geom_col(win_width, width)
  local cw = config.window
  local placement = cw.placement
  local col
  if placement.horizontal == 'left' then
    col = cw.margin.horizontal.left
  elseif placement.horizontal == 'right' then
    col = win_width - width - cw.margin.horizontal.right
  elseif placement.horizontal == 'center' then
    col = math.floor((win_width / 2) - (width / 2))
  end
  return math.max(col, cw.margin.horizontal.left)
end

function Winline:get_win_geom_width(win_width)
  local cw = config.window
  local width
  if cw.width == 'fill' then
    width = win_width
  elseif cw.width == 'fit' then
    width = math.min(self:get_content_len(), win_width)
  elseif type(cw.width) == 'number' then
    if cw.width > 0 and cw.width <= 1 then
      width = math.floor(cw.width * win_width)
    else
      width = cw.width
    end
  end
  width = math.min(width, win_width - (cw.margin.horizontal.left + cw.margin.horizontal.right))
  width = math.max(width, 1)
  return width
end

function Winline:get_win_geom()
  local win_width = a.nvim_win_get_width(self.target_win)
  local win_pos = a.nvim_win_get_position(self.target_win)
  local geom = {}
  geom.height = 1
  geom.width = self:get_win_geom_width(win_width)
  geom.row = win_pos[1] + self:get_win_geom_row()
  geom.col = win_pos[2] + self:get_win_geom_col(win_width, geom.width)
  return geom
end

function Winline:incline_overlaps_buffer_content()
  -- Check if incline is actually overlapping buffer content
  -- If it's overlapping borders, tabline, winbar, statusline, etc., return false
  local geom_row_offset = self:get_win_geom_row()
  local cw = config.window

  -- If incline is above the window content (negative offset), it's definitely
  -- overlapping non-buffer elements like tabline or border
  if geom_row_offset < 0 then
    return false
  end

  -- Check if we're on row 0 and overlapping winbar
  if geom_row_offset == 0 and cw.placement.vertical == 'top' then
    -- If winbar exists and we're configured to overlap it, we're overlapping UI not buffer
    if config.window.overlap.winbar and vim.wo[self.target_win].winbar ~= '' then
      return false
    end
  end

  -- Check if we're at bottom and overlapping statusline
  if cw.placement.vertical == 'bottom' then
    local expected_bottom = a.nvim_win_get_height(self.target_win) - (cw.margin.vertical.bottom + 1)
    -- If we're configured to overlap statusline and positioned to do so
    if config.window.overlap.statusline and geom_row_offset > expected_bottom then
      return false
    end
  end

  return true
end

function Winline:get_text_offset()
  -- Get the horizontal offset caused by sign column and line numbers
  local offset = 0

  -- Sign column width
  local signcolumn = vim.wo[self.target_win].signcolumn
  if signcolumn == 'yes' then
    offset = offset + 2
  elseif signcolumn == 'auto' then
    -- Check if there are any signs in the buffer
    local signs = vim.fn.sign_getplaced(a.nvim_win_get_buf(self.target_win), { group = '*' })
    if signs and signs[1] and #signs[1].signs > 0 then
      offset = offset + 2
    end
  elseif signcolumn:match('^yes:(%d+)') then
    local width = tonumber(signcolumn:match('^yes:(%d+)'))
    offset = offset + (width * 2)
  elseif signcolumn:match('^auto:(%d+)') then
    -- For auto:1-2, extract the max width (second number)
    local max_width = tonumber(signcolumn:match('%-(%d+)$')) or tonumber(signcolumn:match('^auto:(%d+)'))
    local signs = vim.fn.sign_getplaced(a.nvim_win_get_buf(self.target_win), { group = '*' })
    if signs and signs[1] and #signs[1].signs > 0 then
      offset = offset + (max_width * 2)
    end
  end

  -- Line number column width
  if vim.wo[self.target_win].number or vim.wo[self.target_win].relativenumber then
    local line_count = a.nvim_buf_line_count(a.nvim_win_get_buf(self.target_win))
    local num_width = math.max(vim.wo[self.target_win].numberwidth, #tostring(line_count))
    offset = offset + num_width
  end

  return offset
end

function Winline:cursor_overlaps_incline()
  -- Don't hide if incline is overlapping UI elements instead of buffer content
  if not self:incline_overlaps_buffer_content() then
    return false
  end

  -- Get incline window geometry (already accounts for borders, margins, etc)
  local geom = self:get_win_geom()

  -- Get cursor screen position within the target window
  local cursor_screen_col = a.nvim_win_call(self.target_win, vim.fn.wincol)
  local cursor_screen_row = a.nvim_win_call(self.target_win, vim.fn.winline)

  -- Get target window position
  local win_pos = a.nvim_win_get_position(self.target_win)

  -- Convert cursor position to editor coordinates (winline/wincol are 1-indexed)
  local cursor_editor_row = win_pos[1] + cursor_screen_row - 1
  local cursor_editor_col = win_pos[2] + cursor_screen_col - 1

  -- Check row overlap
  local row_matches = cursor_editor_row == geom.row

  -- Check column overlap (cursor within incline's column range)
  local col_overlaps = cursor_editor_col >= geom.col and cursor_editor_col < (geom.col + geom.width)

  return row_matches and col_overlaps
end

function Winline:visual_selection_overlaps_incline()
  -- Don't hide if incline is overlapping UI elements instead of buffer content
  if not self:incline_overlaps_buffer_content() then
    return false
  end

  local mode = a.nvim_win_call(self.target_win, vim.fn.mode)
  -- Check for visual modes: v (character), V (line), \22 (block)
  if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then
    return false
  end

  local geom = self:get_win_geom()

  -- Get visual selection positions in buffer coordinates (in target window context)
  local v_start_pos = a.nvim_win_call(self.target_win, function()
    return vim.fn.getpos 'v'
  end)
  local v_end_pos = a.nvim_win_call(self.target_win, function()
    return vim.fn.getpos '.'
  end)

  local start_line, start_col = v_start_pos[2], v_start_pos[3]
  local end_line, end_col = v_end_pos[2], v_end_pos[3]

  -- Normalize so start is before end
  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col, start_col
  end

  -- Get window position and view info
  local win_pos = a.nvim_win_get_position(self.target_win)
  local view = a.nvim_win_call(self.target_win, vim.fn.winsaveview)
  local topline = view.topline
  local leftcol = view.leftcol

  -- Calculate which screen row the incline is on relative to the window
  -- geom.row is in editor coords, win_pos[1] is window's editor row
  local incline_screen_row = geom.row - win_pos[1] + 1 -- Convert to 1-indexed window row

  -- Check if the incline's screen row is within the visual selection's line range
  -- We need to check if any line in the selection appears on incline_screen_row
  local incline_buffer_line = topline + incline_screen_row - 1

  if incline_buffer_line < start_line or incline_buffer_line > end_line then
    return false
  end

  -- Line-wise mode selects entire lines
  if mode == 'V' then
    return true
  end

  -- For character-wise and block-wise, check column overlap
  -- Get the buffer column range that's selected on this line
  local sel_start_buf_col, sel_end_buf_col

  if mode == '\22' then
    -- Block mode: same column range on all lines
    sel_start_buf_col = start_col
    sel_end_buf_col = end_col
  elseif incline_buffer_line == start_line and incline_buffer_line == end_line then
    -- Character-wise: selection all on one line
    sel_start_buf_col = start_col
    sel_end_buf_col = end_col
  elseif incline_buffer_line == start_line then
    -- Character-wise: on the start line - selected from start_col to end of line
    sel_start_buf_col = start_col
    sel_end_buf_col = math.huge
  elseif incline_buffer_line == end_line then
    -- Character-wise: on the end line - selected from start of line to end_col
    sel_start_buf_col = 1
    sel_end_buf_col = end_col
  else
    -- Character-wise: middle line - entire line selected
    return true
  end

  -- Get gutter width
  local text_offset = self:get_text_offset()

  -- Convert buffer columns to screen columns (account for horizontal scroll, tabs, etc)
  -- For each column in the incline, check if it overlaps with the selection
  for incline_editor_col = geom.col, geom.col + geom.width - 1 do
    -- Convert editor column to window screen column
    local incline_screen_col = incline_editor_col - win_pos[2] + 1 -- 1-indexed window col

    -- Convert window screen column to buffer column (account for leftcol and gutter)
    local buf_col = leftcol + incline_screen_col - text_offset

    if buf_col >= sel_start_buf_col and buf_col <= sel_end_buf_col then
      return true
    end
  end

  return false
end

function Winline:get_win_config()
  local geom = self:get_win_geom()
  return {
    zindex = config.window.zindex,
    width = geom.width,
    height = geom.height,
    row = geom.row,
    col = geom.col,
    relative = 'editor',
    style = 'minimal',
    border = 'none',
    focusable = false,
  }
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
  util.win_set_local_options(self._win, self:get_win_opts())
end

function Winline:win(opts)
  opts = opts or {}
  if opts.refresh or not (self._win and a.nvim_win_is_valid(self._win)) then
    self:refresh()
  end
  return self._win
end

-- TODO: Avoid unnecessary renders after :focus()/:blur()/:hide()/:show() are called
function Winline:render(opts)
  opts = opts or {}

  if self.hidden == HIDE_PERSIST or not self:is_alive() then
    return
  end

  -- Handle cursorline hiding
  if config.hide.cursorline == 'smart' then
    if self.focused and (self:cursor_overlaps_incline() or self:visual_selection_overlaps_incline()) then
      self:hide(HIDE_TEMP)
      return
    end
  elseif config.hide.cursorline == true or (config.hide.cursorline == 'focused_win' and self.focused) then
    -- Existing row-only check
    if (self:get_win_geom_row() + ((vim.wo[self.target_win].winbar == '') and 1 or 0))
        == a.nvim_win_call(self.target_win, vim.fn.winline) then
      self:hide(HIDE_TEMP)
      return
    end
  end

  local ok, render_result = pcall(config.render, {
    buf = a.nvim_win_get_buf(self.target_win),
    win = self.target_win,
    focused = self.focused,
  })
  if not ok then
    vim.notify_once('[Incline.nvim] render error: ' .. render_result, vim.log.levels.ERROR)
    return
  end

  if not render_result or render_result == '' then
    self:hide(HIDE_TEMP)
    return
  end
  if self.hide == HIDE_TEMP then
    self:show()
  end

  if type(render_result) ~= 'table' then
    render_result = { render_result }
  end

  local offset = 0
  if config.window.padding.left > 0 then
    offset = config.window.padding.left
  end

  local content = M.parse_render_result(render_result, offset)

  if content.text == '' then
    self:hide(HIDE_TEMP)
    return
  end

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

  local buf = self:buf()

  if content_text_changed then
    a.nvim_buf_set_lines(buf, 0, -1, false, { self.content.text })
  end
  if content_text_changed or content_hls_changed then
    highlight.buf_clear(buf)
    for _, hl in ipairs(content.hls) do
      local hl_start = { 0, hl.range[1] }
      local hl_end = { 0, hl.range[2] }
      highlight.buf_add_highlight(buf, hl.group, hl_start, hl_end)
    end
  end

  self:win { refresh = opts.refresh or content_text_len_changed }
end

function Winline:hide(mode)
  self.hidden = mode or HIDE_PERSIST
  if self._win and a.nvim_win_is_valid(self._win) then
    a.nvim_win_close(self._win, false)
    self._win = nil
  end
end

function Winline:show()
  if not self.hidden then
    return
  end
  self.hidden = false
  self:refresh()
end

function Winline:toggle()
  if self.hidden then
    self:show()
  else
    self:hide()
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

function Winline:destroy()
  if self._win and a.nvim_win_is_valid(self._win) then
    a.nvim_win_close(self._win, false)
  end
  if self._buf and a.nvim_buf_is_valid(self._buf) then
    a.nvim_buf_delete(self._buf, { unload = false })
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
