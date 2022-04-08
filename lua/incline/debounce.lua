local Debounce = {}

Debounce.cancel = function(self)
  if self.timer then
    self.timer:stop()
    self.timer = nil
  end
end

Debounce.call = function(self, ...)
  self:cancel()
  local args = { ... }
  self.timer = vim.defer_fn(function()
    self:immediate(unpack(args))
  end, self.opts.threshold)
end

Debounce.immediate = function(self, ...)
  self:cancel()
  self.fn(...)
end

-- ref() returns a normal function which, when called, calls Debounce:call()
-- bound to the original instance.
-- Useful for using Debounce with an API that doesn't accept callable tables.
Debounce.ref = function(self)
  return function(...)
    self:call(...)
  end
end

local function make(fn, opts)
  opts = vim.tbl_extend('force', {
    threshold = 100,
  }, opts or {})
  return setmetatable({
    fn = fn,
    opts = opts,
  }, { __index = Debounce, __call = Debounce.call })
end

return make
