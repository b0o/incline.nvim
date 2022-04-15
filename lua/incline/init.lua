local M = {}

local config = require 'incline.config'
local manager = require 'incline.manager'

M.setup = function(_config)
  config.setup(_config)
  manager.setup()
end

return M
