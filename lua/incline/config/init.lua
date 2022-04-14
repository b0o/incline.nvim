local Schema = require 'incline.config.schema'
local vx = require 'incline.config.validate'

local M = {}

M.schema = Schema('config', function(s)
  return {
    -- Function to render the statusline content.
    -- The function is called with a single argument which is a table containing
    -- the following properties:
    --  - buf: the buffer handle for the target window's buffer
    --  - win: the window handle for the target window
    render = s:entry(function(props)
      local bufname = vim.api.nvim_buf_get_name(props.buf)
      if bufname == '' then
        return '[No name]'
      else
        bufname = vim.fn.fnamemodify(bufname, ':t')
      end
      return bufname
    end, vx.func),

    -- Minimum number of milliseconds between updates/renders.
    -- If multiple events occur within the threshold, they are batched into a single render.
    debounce_threshold = s:entry(30, vx.number.whole),

    window = {
      placement = {
        vertical = s:entry('top', vx.any { 'top', 'bottom' }),
        horizontal = s:entry('right', vx.any { 'left', 'right', 'center' }),
      },
      width = s:entry(
        'fit',
        vx.any {
          'fill',
          'fit',
          vx.number.natural,
          vx.number.percentage,
        }
      ),
      margin = {
        horizontal = s:entry(
          { left = 1, right = 1 },
          vx.any {
            vx.number.whole,
            vx.table.of {
              left = vx.number.whole,
              right = vx.number.whole,
            },
          },
          function(v)
            if type(v) == 'number' then
              v = { left = v, right = v }
            end
            return v
          end
        ),
        vertical = s:entry(
          { top = 1, bottom = 0 },
          vx.any {
            vx.number.whole,
            vx.table.of {
              top = vx.number.whole,
              bottom = vx.number.whole,
            },
          },
          function(v)
            if type(v) == 'number' then
              v = { top = v, bottom = v }
            end
            return v
          end
        ),
      },
      padding = s:entry(
        { left = 1, right = 1 },
        vx.any {
          vx.number.whole,
          vx.table.of {
            left = vx.number.whole,
            right = vx.number.whole,
          },
        },
        function(v)
          if type(v) == 'number' then
            v = { left = v, right = v }
          end
          return v
        end
      ),
      padding_char = s:entry(' ', vx.string.length(1)),
      zindex = s:entry(50, vx.number.natural),
    },

    -- Control which windows Incline should ignore.
    ignore = {
      -- Ignore unlisted buffers. See :help buflisted
      unlisted_buffers = s:entry(true, vx.bool),

      -- Ignore floating windows.
      floating_wins = s:entry(true, vx.bool),

      -- List of filetypes to ignore.
      filetypes = s:entry({}, vx.list.of(vx.string)),

      -- Ignored buftypes.
      -- Can be one of the following:
      -- false or nil - No buftypes are ignored.
      -- "special"    - All buffers other than normal buffers are ignored.
      -- table        - A list of buftypes to ignore. See :help buftype for the
      --                possible values.
      -- function     - A function that returns true if the buffer should be
      --                ignored or false if it should not be ignored.
      --                Takes two arguments, `bufnr` and `buftype`.
      buftypes = s:entry(
        'special',
        vx.any {
          'special',
          vx.func,
          vx.list.of(vx.any {
            '',
            'acwrite',
            'help',
            'nofile',
            'nowrite',
            'quickfix',
            'terminal',
            'prompt',
          }),
        }
      ),

      -- Ignored wintypes.
      -- Can be one of the following:
      -- false or nil - No wintypes are ignored.
      -- "special"    - All windows other than normal windows are ignored.
      -- table        - A list of wintypes to ignore. See :help win_gettype() for the
      --                possible values.
      -- function     - A function that returns true if the window should be
      --                ignored or false if it should not be ignored.
      --                Takes two arguments, `winid` and `wintype`.
      wintypes = s:entry(
        'special',
        vx.any {
          'special',
          vx.func,
          vx.list.of(vx.any {
            '',
            'autocmd',
            'command',
            'loclist',
            'popup',
            'preview',
            'quickfix',
            'unknown',
          }),
        }
      ),
    },
  }
end)

return setmetatable({
  setup = function(config)
    M.config = M.schema:parse(config)
  end,
}, {
  __index = function(_, k)
    if M[k] then
      return M[k]
    end
    if M.config == nil then
      M.config = M.schema:default()
    end
    if k == 'config' then
      return M.config
    end
    return M.config[k]
  end,
})
