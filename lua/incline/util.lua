local config = require 'incline.config'

local a = vim.api

local M = {}

M.resolve_win = function(win)
  win = win or 0
  if win == 0 then
    return a.nvim_get_current_win()
  end
  return win
end

M.is_ignored_filetype = function(filetype)
  local ignore = config.ignore
  return ignore.filetypes and vim.tbl_contains(ignore.filetypes, filetype)
end

M.is_ignored_buf = function(bufnr)
  bufnr = bufnr or 0
  local ignore = config.ignore
  if ignore.unlisted_buffers and not a.nvim_buf_get_option(bufnr, 'buflisted') then
    return true
  end
  if ignore.buftypes then
    local buftype = a.nvim_buf_get_option(bufnr, 'buftype')
    if ignore.buftypes == 'special' and buftype ~= '' then
      return true
    elseif type(ignore.buftypes) == 'table' then
      if vim.tbl_contains(ignore.buftypes, buftype) then
        return true
      end
    elseif type(ignore.buftypes) == 'function' then
      if ignore.buftypes(bufnr, buftype) then
        return true
      end
    end
  end
  if ignore.filetypes then
    local filetype = a.nvim_buf_get_option(bufnr, 'filetype')
    if M.is_ignored_filetype(filetype) then
      return true
    end
  end
  return false
end

M.is_floating_win = function(winid)
  return a.nvim_win_get_config(winid or 0).relative ~= ''
end

M.is_ignored_win = function(winid)
  winid = winid or 0
  local bufnr = a.nvim_win_get_buf(winid)
  if M.is_ignored_buf(bufnr) then
    return true
  end
  local ignore = config.ignore
  if ignore.floating_wins and M.is_floating_win(winid) then
    return true
  end
  if ignore.wintypes then
    local wintype = vim.fn.win_gettype(winid)
    if ignore.wintypes == 'special' and wintype ~= '' then
      return true
    elseif type(ignore.wintypes) == 'table' then
      if vim.tbl_contains(ignore.wintypes, wintype) then
        return true
      end
    elseif type(ignore.wintypes) == 'function' then
      if ignore.wintypes(winid, wintype) then
        return true
      end
    end
  end
  return false
end

local augroup
M.get_augroup = function()
  if not augroup then
    augroup = a.nvim_create_augroup('incline', { clear = true })
  end
  return augroup
end

M.clear_augroup = function()
  if augroup then
    a.nvim_del_augroup_by_id(augroup)
    augroup = nil
  end
end

M.autocmd = function(event, opts)
  return a.nvim_create_autocmd(
    event,
    vim.tbl_extend('force', {
      group = M.get_augroup(),
    }, opts)
  )
end

M.tbl_onlykeys = function(tbl)
  local res = {}
  for k, v in pairs(tbl) do
    if type(k) ~= 'number' then
      res[k] = v
    end
  end
  return res
end

return M
