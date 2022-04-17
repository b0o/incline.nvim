local Schema = require 'incline.config.schema'
local vx = require 'incline.config.validate'

local M = {}

M.schema = Schema('config', function(s)
  return {
    render = s:entry(function(props)
      local bufname = vim.api.nvim_buf_get_name(props.buf)
      if bufname == '' then
        return '[No name]'
      end
      return vim.fn.fnamemodify(bufname, ':t')
    end, vx.func),
    debounce_threshold = s:entry(
      { rising = 10, falling = 50 },
      vx.any {
        vx.number.whole,
        vx.table.of { rising = vx.number.whole, falling = vx.number.whole },
      },
      function(v)
        if type(v) == 'number' then
          return { rising = v, falling = v }
        end
        return v
      end
    ),
    window = {
      width = s:entry('fit', vx.any { 'fit', 'fill', vx.number.natural, vx.number.percentage }),
      placement = {
        vertical = s:entry('top', vx.any { 'top', 'bottom' }),
        horizontal = s:entry('right', vx.any { 'left', 'center', 'right' }),
      },
      margin = {
        horizontal = s:entry(
          { left = 1, right = 1 },
          vx.any {
            vx.number.whole,
            vx.table.of { left = vx.number.whole, right = vx.number.whole },
          },
          function(v)
            if type(v) == 'number' then
              return { left = v, right = v }
            end
            return v
          end
        ),
        vertical = s:entry(
          { top = 1, bottom = 0 },
          vx.any {
            vx.number.whole,
            vx.table.of { top = vx.number.whole, bottom = vx.number.whole },
          },
          function(v)
            if type(v) == 'number' then
              return { top = v, bottom = v }
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
            return { left = v, right = v }
          end
          return v
        end
      ),
      padding_char = s:entry(' ', vx.string.length(1)),
      zindex = s:entry(50, vx.number.natural),
      options = s:entry({}, vx.table),
    },
    hide = {
      focused_win = s:entry(false, vx.bool),
    },
    ignore = {
      unlisted_buffers = s:entry(true, vx.bool),
      floating_wins = s:entry(true, vx.bool),
      filetypes = s:entry({}, vx.list.of(vx.string)),
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
    M.config = M.schema:parse(config, M.config)
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
