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
      end, self.threshold.falling)
    end, self.threshold.rising)
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

local function make(fn, opts)
  opts = opts or {}
  opts.threshold = opts.threshold or 50
  if type(opts.threshold) == 'number' then
    opts.threshold = { rising = opts.threshold, falling = opts.threshold }
  end
  opts.threshold.rising = opts.threshold.rising or 50
  opts.threshold.falling = opts.threshold.falling or 50
  return setmetatable({
    fn = fn,
    opts = opts,
    timedout = false,
    waiting = false,
    threshold = opts.threshold,
    phase = 0,
  }, {
    __index = Debounce,
    __call = Debounce.call,
  })
end

return make
