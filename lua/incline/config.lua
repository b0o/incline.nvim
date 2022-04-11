local defaults = {

  -- Function to render the statusline content.
  -- The function is called with a single argument which is a table containing
  -- the following properties:
  --  - buf: the buffer handle for the target window's buffer
  --  - win: the window handle for the target window
  render = function(props)
    local bufname = vim.api.nvim_buf_get_name(props.buf)
    if bufname == '' then
      return ' [No name]'
    end
    return ' ' .. vim.fn.fnamemodify(bufname, ':t')
  end,

  -- Minimum number of milliseconds between updates/renders.
  -- If multiple events occur within the threshold, they are batched into a single render.
  debounce_threshold = 30,

  -- Control which windows Incline should ignore.
  ignore = {
    -- Ignore unlisted buffers. See :help buflisted
    unlisted_buffers = true,

    -- Ignore floating windows.
    floating_wins = false,

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
