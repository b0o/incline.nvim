local M = {}

local islist = vim.islist or vim.tbl_islist

M.extend = function(val, entry)
  if type(val) ~= 'table' then
    return val
  end
  if islist(entry.default) and islist(val) then
    local res = vim.deepcopy(entry.default)
    vim.list_extend(res, val)
    return res
  else
    return vim.tbl_extend('force', entry.default, val)
  end
end

M.replace = function(val)
  return val
end

M.reset = function(_, entry)
  return entry.default
end

return M
