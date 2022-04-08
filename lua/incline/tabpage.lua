local util = require 'incline.util'
local Winline = require 'incline.winline'

local a = vim.api

local Tabpage = {}

function Tabpage:render(opts)
  opts = opts or {}
  if not self.initialized then
    self:update()
  end
  if self.dirty then
    opts.refresh = true
  end
  for _, winline in pairs(self.children) do
    winline:render(opts)
  end
end

function Tabpage:update(opts)
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(self.tab)) do
    if not util.is_ignored_win(win) then
      wins[win] = true -- 'true' is a placeholder
    end
  end
  for win, child in pairs(self.children) do
    if not wins[win] then
      child:destroy()
      self.children[win] = nil
    else
      wins[win] = child
    end
  end
  for win, child in pairs(wins) do
    if child == true then
      child = Winline(win)
    end
    self.children[win] = child
  end
  for _, child in pairs(self.children) do
    child:update(opts)
  end

  self.initialized = true
  self.dirty = true
end

local function make(tab)
  if tab == nil or tab == 0 then
    tab = vim.api.nvim_get_current_tabpage()
  end
  assert(a.nvim_tabpage_is_valid(tab), 'invalid tabpage: ' .. tab)
  return setmetatable({
    initialized = false,
    dirty = true,
    tab = tab,
    children = {},
  }, { __index = Tabpage })
end

return make
