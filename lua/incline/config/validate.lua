local M = {}

M.callable = function(val)
  local t = type(val)
  if t == 'function' then
    return true
  end
  if t == 'table' then
    local mt = getmetatable(val)
    return mt and M.callable(mt.__call)
  end
  return false
end

local wrapped = function(base, tbl)
  local newindex_inner
  newindex_inner = function(self, fn)
    return function(val, ...)
      local ok, res = pcall(fn, val, ...)
      if ok and M.callable(res) then
        return newindex_inner(self, res)
      end
      return self(val) and res
    end
  end
  return setmetatable(tbl or {}, {
    __call = function(_, val)
      return base(val)
    end,
    __newindex = function(self, key, fn)
      rawset(self, key, newindex_inner(self, fn))
      rawset(self, '_' .. key, fn)
    end,
  })
end

M.notNil = function(val)
  return val ~= nil
end

M.any = function(accepted)
  return function(val)
    for _, acc in ipairs(accepted) do
      if M.callable(acc) and acc(val) then
        return true
      elseif acc == val then
        return true
      end
    end
    return false
  end
end

M.all = function(required)
  return function(val)
    for _, req in ipairs(required) do
      if not req(val) then
        return false
      end
    end
    return true
  end
end

M.type = function(accepted)
  return function(val)
    return type(val) == accepted
  end
end

M.bool = M.type 'boolean'
M.func = M.type 'function'

M.table = wrapped(M.type 'table')
M.table.of_all = function(fields)
  return function(val)
    local keys = {}
    for k in pairs(val) do
      keys[k] = true
    end
    for k, v in pairs(fields) do
      if not v(val[k]) then
        return false
      end
      keys[k] = nil
    end
    return vim.tbl_isempty(keys)
  end
end

M.table.of_any = function(fields)
  return function(val)
    for k, v in pairs(val) do
      if not fields[k] or not fields[k](v) then
        return false
      end
    end
    return true
  end
end

M.table.including = function(fields)
  return function(val)
    for k, v in pairs(fields) do
      if not val[k] or not v(val[k]) then
        return false
      end
    end
    return true
  end
end

M.map = function(keys, vals)
  return function(val)
    if not M.table(val) then
      return false
    end
    for k, v in pairs(val) do
      if not (keys(k) and vals(v)) then
        return false
      end
    end
    return true
  end
end

M.string = wrapped(M.type 'string')
M.string.length = function(len)
  return function(val)
    return #val == len
  end
end

M.string.match = function(pat)
  return function(val)
    return string.match(val, pat) ~= nil
  end
end

M.number = wrapped(M.type 'number')

M.number.lt = function(max)
  return function(val)
    return val < max
  end
end

M.number.le = function(max)
  return function(val)
    return val <= max
  end
end

M.number.gt = function(max)
  return function(val)
    return val > max
  end
end

M.number.ge = function(max)
  return function(val)
    return val >= max
  end
end

M.number.between = function(min, max)
  return function(val)
    return val > min and val < max
  end
end

M.number.between_l_inc = function(min, max)
  return function(val)
    return val >= min and val < max
  end
end

M.number.between_r_inc = function(min, max)
  return function(val)
    return val > min and val <= max
  end
end

M.number.between_inc = function(min, max)
  return function(val)
    return val >= min and val <= max
  end
end

M.number.positive = M.number._gt(0)
M.number.negative = M.number._lt(0)
M.number.positive_inc = M.number._ge(0)
M.number.negative_inc = M.number._le(0)

M.number.int = function(val)
  return math.fmod(val, 1) == 0
end

-- whole numbers are integers greater than or equal to 0
M.number.whole = M.all { M.number._int, M.number._ge(0) }

-- natural numbers are integers greater than or equal to 1
M.number.natural = M.all { M.number._int, M.number._ge(1) }

-- percentages are numbers between 0 and 1, inclusive
M.number.percentage = M.number._between_r_inc(0, 1)

M.list = wrapped(vim.tbl_islist)

M.list.of = function(of)
  return function(val)
    for _, el in ipairs(val) do
      if not of(el) then
        return false
      end
    end
    return true
  end
end

M.highlight = {}
M.highlight.args = M.table.of_any {
  start = M.string,
  stop = M.string,
  cterm = M.string,
  ctermfg = M.string,
  ctermbg = M.string,
  gui = M.string,
  guifg = M.string,
  guibg = M.string,
  guisp = M.string,
  blend = M.any { M.string, M.number.int },
  font = M.string,
}

M.highlight.link = M.table.of_all {
  group = M.string,
}

M.highlight.any = M.any { M.highlight.args, M.highlight.link }

return M
