return setmetatable({}, {
  __index = function(_, k)
    return require('incline.presets.' .. k)
  end,
})
