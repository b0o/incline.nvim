local M = {}

M.load = function(preset)
  return require('incline.presets.' .. preset)
end

return setmetatable(M, {
  __index = function(_, k)
    return M.load(k)
  end,
})
