local config = require 'incline.config'

local Debounce = {}

function Debounce:cancel()
  if self.timer then
    self.timer:stop()
    self.timer = nil
  end
end

function Debounce:call(...)
  local args = { ... }
  if self.phase == 0 then
    self.phase = 1
    self.timer = vim.defer_fn(function()
      self:immediate(unpack(args))
      self.phase = 2
      self.timer = vim.defer_fn(function()
        if self.waiting then
          self:immediate(unpack(args))
        end
        self.waiting = false
        self.phase = 0
      end, config.debounce_threshold.falling)
    end, config.debounce_threshold.rising)
  elseif self.phase == 2 then
    self.waiting = true
  end
end

function Debounce:immediate(...)
  self:cancel()
  self.fn(...)
end

-- ref() returns a normal function which, when called, calls Debounce:call()
-- bound to the original instance.
-- Useful for using Debounce with an API that doesn't accept callable tables.
function Debounce:ref()
  return function(...)
    self:call(...)
  end
end

local function make(fn)
  return setmetatable({
    fn = fn,
    timedout = false,
    waiting = false,
    phase = 0,
  }, {
    __index = Debounce,
    __call = Debounce.call,
  })
end

return make
