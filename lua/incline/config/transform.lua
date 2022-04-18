local M = {}

M.extend = function(val, entry)
  return vim.tbl_extend('force', entry.default, val)
end

M.replace = function(val)
  return val
end

M.reset = function(_, entry)
  return entry.default
end

return M
