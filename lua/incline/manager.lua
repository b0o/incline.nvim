local config = require 'incline.config'
local util = require 'incline.util'
local Debounce = require 'incline.debounce'
local Tabpage = require 'incline.tabpage'

local a = vim.api

local M = {
  state = {
    initialized = false,
    tabpages = {},
    current_tab = nil,
    events = {},
  },
}

local state = M.state

local update = Debounce(function()
  local changes = { layout = false, windows = false }
  local events = state.events
  if not state.current_tab or events.TabEnter then
    state.current_tab = a.nvim_get_current_tabpage()
  end
  if not state.tabpages[state.current_tab] then
    state.tabpages[state.current_tab] = Tabpage(state.current_tab)
    return
  end
  if events.WinNew or events.WinClosed then
    changes.windows = true
    changes.layout = true
  end
  if events.WinScrolled or events.BufWinEnter or events.BufWinLeave or events.OptionSet then
    changes.layout = true
  end
  state.tabpages[state.current_tab]:update(changes)
  state.events = {}
end, { threshold = config.debounce_threshold })

M.setup = function()
  if state.initialized then
    return
  end
  for _, event in ipairs {
    'WinNew',
    'WinClosed',
    'WinScrolled', -- WinScrolled is used to detect window resizes
    'TabEnter',
    'BufWinEnter',
    'BufWinLeave',
  } do
    util.autocmd(event, {
      callback = function()
        state.events[event] = true
        update()
      end,
    })
  end
  update:immediate()
  state.initialized = true
end

return M
