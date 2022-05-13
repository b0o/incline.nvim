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

M.register = function(hl, group_name)
  if type(hl) == 'string' then
    hl = { group = hl }
  end
  if group_name == nil then
    group_name = M.get_pseudonym(hl)
  end

  local cmd = { lhs = { 'highlight' }, rhs = {} }
  for key, val in pairs(hl) do
    if key == 'default' then
      table.insert(cmd.lhs, 2, 'default')
    elseif key == 'group' then
      table.insert(cmd.lhs, 'link')
      table.insert(cmd.rhs, val)
    else
      table.insert(cmd.rhs, key .. '=' .. val)
    end
  end

  table.insert(cmd.lhs, group_name)

  local cmd_str = table.concat(cmd.lhs, ' ') .. ' ' .. table.concat(cmd.rhs, ' ')
  if not cache[group_name] or cmd_str ~= cache[group_name] then
    if not hl.default then
      cache[group_name] = cmd_str
    end
    vim.cmd(cmd_str)
  end

  return group_name
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

M.buf_add_highlight = function(buf, ...)
  return a.nvim_buf_add_highlight(buf, M.namespace, ...)
end

M.buf_clear = function(buf)
  return a.nvim_buf_clear_namespace(buf, M.namespace, 0, -1)
end

M.setup = function()
  M.clear()
  M.namespace = a.nvim_create_namespace 'incline'
  for hl_group, hl in pairs(config.highlight.groups) do
    M.register(hl, hl_group)
  end
end

return M
