local M = {}

local config = require 'incline.config'
local manager = require 'incline.manager'

M.is_enabled = function()
  return manager.state.initialized
end

M.enable = function()
  manager.setup()
end

M.disable = function()
  manager.destroy()
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

return M
