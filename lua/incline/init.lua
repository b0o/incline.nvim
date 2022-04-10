local M = {}

local config = require 'incline.config'
local manager = require 'incline.manager'

M.setup = function(_config)
  config.setup(_config or {})
  manager.setup()
end

return M
