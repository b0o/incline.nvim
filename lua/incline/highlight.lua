local config = require 'incline.config'

local a = vim.api

local M = { namespace = -1 }
local cache = {}

M.clear = function()
  for hi in pairs(cache) do
    vim.cmd('highlight clear ' .. hi)
  end
  cache = {}
end

M.link = function(from, to, opts)
  if opts.force or not cache[from] or cache[from] ~= to then
    vim.cmd(string.format('highlight! link %s %s', from, to))
    cache[from] = to
  end
  return from
end

M.register = function(hl, group, opts)
  if type(group) == 'table' and opts == nil then
    opts = group
    group = nil
  end
  opts = opts or {}
  if type(hl) == 'string' then
    return M.link(group, hl, opts)
  end
  if group == nil then
    group = M.get_pseudonym(hl)
  end
  if opts.force or not cache[group] or not vim.deep_equal(hl, cache[group]) then
    local hi = 'highlight! default ' .. group
    for opt, val in pairs(hl) do
      hi = hi .. ' ' .. opt .. '=' .. val
    end
    vim.cmd(hi)
    cache[group] = hl
  end
  return group
end

M.get_pseudonym = function(hl)
  local name = 'incline'
  local keys = vim.tbl_keys(hl)
  table.sort(keys)
  for _, arg in ipairs(keys) do
    local val = hl[arg]
    name = ('%s__%s_%s'):format(name, arg, tostring(val):gsub('[^%w]', ''):lower())
  end
  return name
end

M.setup = function()
  M.clear()
  M.namespace = a.nvim_create_namespace 'incline'
  for hl_group, hl in pairs(config.highlight.groups) do
    M.register(hl, hl_group)
  end
end

return M
