local config = require 'incline.config'
local util = require 'incline.util'
local Winline = require 'incline.winline'

local a = vim.api

local Tabpage = {}

function Tabpage:render()
  for _, winline in pairs(self.children) do
    winline:render()
  end
end

function Tabpage:load_wins()
  local children = {}
  local wins = a.nvim_tabpage_list_wins(self.tab)
  for _, win in ipairs(wins) do
    if not util.is_ignored_win(win) then
      local child = self.children[win]
      self.children[win] = nil
      if child == nil then
        child = Winline(win)
      end
      children[win] = child
    end
  end
  for _, child in pairs(self.children) do
    child:destroy()
  end
  self.children = children
end

function Tabpage:update(changes)
  changes = changes or {}
  if changes.windows then
    self:load_wins()
  end
  if (changes.windows or changes.focus or changes.layout) and config.hide.only_win then
    local hide
    if config.hide.only_win == 'count_ignored' then
      hide = #util.tabpage_list_fixed_wins(self.tab) == 1
    else
      hide = vim.tbl_count(self.children) <= 1
    end
    if hide then
      if not self.only_win_hidden then
        _, self.only_win_hidden = next(self.children)
        if self.only_win_hidden then
          self.only_win_hidden:hide()
        end
      end
      return
    elseif self.only_win_hidden then
      self.only_win_hidden:show()
      self.only_win_hidden = nil
    end
  end
  if changes.focus then
    if self.focused_win and self.children[self.focused_win] then
      self.children[self.focused_win]:blur()
    end
    local foc = a.nvim_get_current_win()
    if self.children[foc] then
      self.children[foc]:focus()
      self.focused_win = foc
    end
  end
  for _, winline in pairs(self.children) do
    winline:render { refresh = changes.layout }
  end
end

function Tabpage:get_winline(win)
  return self.children[win]
end

function Tabpage:destroy()
  for _, winline in pairs(self.children) do
    winline:destroy()
  end
  self.children = {}
  self.focused_win = nil
end

local function make(tab)
  if tab == nil or tab == 0 then
    tab = vim.api.nvim_get_current_tabpage()
  end
  return setmetatable({
    tab = tab,
    -- NOTE: do not maintain a persistent reference to the children table.
    -- The table is discarded and re-created after each call to load_wins().
    children = {},
    focused_win = nil,
    only_win_hidden = nil,
  }, { __index = Tabpage })
end

return make
