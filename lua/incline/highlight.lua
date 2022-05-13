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

M.register = function(hl, group, opts)
  if type(group) == 'table' and opts == nil then
    opts = group
    group = nil
  end
  opts = opts or {}
  local skip_cache = false

  if type(hl) == 'string' then
    hl = { group = hl }
  else
    hl = vim.deepcopy(hl)
  end
  if group == nil then
    group = M.get_pseudonym(hl)
  end

  local cmd = { 'highlight' }
  if hl.default then
    table.insert(cmd, 'default')
    hl.default = nil
    skip_cache = true
  end
  if hl.group then
    table.insert(cmd, 'link')
  end
  table.insert(cmd, group)
  if hl.group then
    table.insert(cmd, hl.group)
    hl.group = nil
  end

  for opt, val in pairs(hl) do
    table.insert(cmd, opt .. '=' .. val)
  end

  local cmd_str = table.concat(cmd, ' ')
  if opts.force or not cache[group] or cmd_str ~= cache[group] then
    if not skip_cache then
      cache[group] = cmd_str
    end
    vim.cmd(cmd_str)
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
