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

-- TODO: Certain events like CursorHold/CursorMoved should only re-render the focused winline
local update = Debounce(function(opts)
  opts = opts or {}
  local events = state.events

  if not state.current_tab or events.TabEnter then
    state.current_tab = a.nvim_get_current_tabpage()
  end
  if not state.tabpages[state.current_tab] then
    state.tabpages[state.current_tab] = Tabpage(state.current_tab)
  end

  local changes = {}
  if opts.refresh then
    changes = { layout = true, windows = true, focus = true, render = true }
  end
  if events.WinNew or events.WinClosed then
    changes.windows = true
    changes.layout = true
  end
  if events.WinScrolled or events.BufWinEnter or events.BufWinLeave or events.OptionSet then
    changes.layout = true
  end
  if events.WinEnter or events.WinLeave or events.TabEnter or events.TabNewEntered then
    changes.focus = true
  end
  if events.CursorHold or events.CursorHoldI or events.CursorMoved or events.CursorMovedI then
    changes.render = true
  end

  if changes.layout or changes.windows or changes.focus or changes.render then
    state.tabpages[state.current_tab]:update(changes)
  end
  state.events = {}
end)

M.win_get_tabpage = function(win)
  win = util.resolve_win(win)
  if not a.nvim_win_is_valid(win) then
    return
  end
  return M.state.tabpages[a.nvim_win_get_tabpage(win)]
end

M.win_get_winline = function(win)
  win = util.resolve_win(win)
  local tab = M.win_get_tabpage(win)
  if not tab then
    return
  end
  return tab:get_winline(win)
end

M.destroy = function()
  if not state.initialized then
    return
  end
  util.clear_augroup()
  for _, tabpage in ipairs(state.tabpages) do
    tabpage:destroy()
  end
  state.current_tab = nil
  state.tabpages = {}
  state.events = {}
  state.initialized = false
end

M.setup = function()
  if state.initialized then
    update.threshold = config.debounce_threshold
    update:immediate { refresh = true }
    return
  end
  local events = {
    'WinNew',
    'WinClosed',
    'WinEnter',
    'WinLeave',
    'WinScrolled', -- WinScrolled is used to detect window resizes
    'TabEnter',
    'TabNewEntered',
    'BufWinEnter',
    'BufWinLeave',
    'CursorHold',
    'CursorHoldI',
    'CursorMoved',
    'CursorMovedI',
  }
  util.autocmd(events, {
    callback = function(e)
      state.events[e.event] = true
      update()
    end,
  })
  update:immediate { refresh = true }
  state.initialized = true
end

return M
