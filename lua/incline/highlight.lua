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
  hl = type(hl) == 'table' and hl or { group = hl }
  group_name = group_name or M.get_pseudonym(hl)

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

--- Apply highlight group to range of text.
---
---@param bufnr integer Buffer number to apply highlighting to
---@param higroup string Highlight group to use for highlighting
---@param start [integer,integer]|string Start of region as a (line, column) tuple or string accepted by |getpos()|
---@param finish [integer,integer]|string End of region as a (line, column) tuple or string accepted by |getpos()|
M.buf_add_highlight = function(bufnr, higroup, start, finish)
  return vim.hl.range(bufnr, M.namespace, higroup, start, finish)
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
