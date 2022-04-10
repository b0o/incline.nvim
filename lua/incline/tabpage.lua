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
    local child = self.children[win]
    self.children[win] = nil
    if not util.is_ignored_win(win) then
      if child == nil then
        child = Winline(win)
      end
      children[win] = child
    end
  end
  for win, child in pairs(self.children) do
    child:destroy()
  end
  self.children = children
end

function Tabpage:update(changes)
  changes = changes or {}
  if changes.windows then
    self:load_wins()
  end
  for _, winline in pairs(self.children) do
    winline:render { refresh = changes.layout }
  end
end

local function make(tab)
  if tab == nil or tab == 0 then
    tab = vim.api.nvim_get_current_tabpage()
  end
  local self = setmetatable({
    tab = tab,
    -- NOTE: do not maintain a persistent reference to the children table.
    -- The table is discarded and re-created after each call to load_wins().
    children = {},
  }, { __index = Tabpage })
  self:update { windows = true, layout = true }
  return self
end

return make
