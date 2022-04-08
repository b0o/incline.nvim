local defaults = {
  render = function(buf)
    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t')
  end,

  -- Control which windows and buffers aerial should ignore.
  -- If close_behavior is "global", focusing an ignored window/buffer will
  -- not cause the aerial window to update.
  -- If open_automatic is true, focusing an ignored window/buffer will not
  -- cause an aerial window to open.
  -- If open_automatic is a function, ignore rules have no effect on aerial
  -- window opening behavior; it's entirely handled by the open_automatic
  -- function.
  ignore = {
    -- Ignore unlisted buffers. See :help buflisted
    unlisted_buffers = true,

    -- List of filetypes to ignore.
    filetypes = {},

    -- Ignored buftypes.
    -- Can be one of the following:
    -- false or nil - No buftypes are ignored.
    -- "special"    - All buffers other than normal buffers are ignored.
    -- table        - A list of buftypes to ignore. See :help buftype for the
    --                possible values.
    -- function     - A function that returns true if the buffer should be
    --                ignored or false if it should not be ignored.
    --                Takes two arguments, `bufnr` and `buftype`.
    buftypes = 'special',

    -- Ignored wintypes.
    -- Can be one of the following:
    -- false or nil - No wintypes are ignored.
    -- "special"    - All windows other than normal windows are ignored.
    -- table        - A list of wintypes to ignore. See :help win_gettype() for the
    --                possible values.
    -- function     - A function that returns true if the window should be
    --                ignored or false if it should not be ignored.
    --                Takes two arguments, `winid` and `wintype`.
    wintypes = 'special',
  },
}

local M = { config = vim.deepcopy(defaults) }

M.setup = function(config)
  config = config or {}
  for k, v in pairs(config) do
    local c = M.config[k]
    assert(c ~= nil, 'invalid config key: ' .. k)
    if type(c) == 'table' and not vim.tbl_islist(c) then
      M.config[k] = vim.tbl_extend('force', c, v)
    else
      M.config[k] = v
    end
  end
  return M
end

return setmetatable(M.config, {
  __index = M,
  __newindex = function()
    assert(false, 'use setup() to configure incline')
  end,
})
