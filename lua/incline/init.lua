local M = {}

local config = require 'incline.config'
local util = require 'incline.util'
local Debounce = require 'incline.debounce'
local Tabpage = require 'incline.tabpage'

local a = vim.api

M.state = {
  initialized = false,
  tabpages = {},
  current_tab = nil,
}

M.update = Debounce(function(opts)
  opts = opts or {}
  M.state.current_tab = a.nvim_get_current_tabpage()
  if not M.state.tabpages[M.state.current_tab] then
    M.state.tabpages[M.state.current_tab] = Tabpage(M.state.current_tab)
  end
  M.state.tabpages[M.state.current_tab]:update(opts)
end, { threshold = 100 })

M.register_autocmds = function()
  util.autocmd({
    'WinScrolled', -- WinScrolled is used to detect window resize
    'WinNew',
    'WinClosed',
    'TabEnter',
  }, {
    callback = function()
      vim.schedule(function()
        M.update { refresh = true }
      end)
    end,
  })
end

M.setup = function(_config)
  config.setup(_config or {})
  if not M.state.initialized then
    M.register_autocmds()
    M.state.initialized = true
  end
  M.update()
end

return M
