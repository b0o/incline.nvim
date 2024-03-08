local M = {}

local config = require 'incline.config'
local manager = require 'incline.manager'
local highlight = require 'incline.highlight'

M.is_enabled = function()
  return manager.state.initialized
end

M.enable = function()
  highlight.setup()
  manager.setup()
end

M.disable = function()
  manager.destroy()
  highlight.clear()
end

M.toggle = function()
  if M.is_enabled() then
    M.disable()
  else
    M.enable()
  end
end

M.setup = function(_config)
  config.setup(_config)
  M.enable()
end

M.refresh = function()
  if not M.is_enabled() then
    return
  end
  manager.update { refresh = true }
end

return M
