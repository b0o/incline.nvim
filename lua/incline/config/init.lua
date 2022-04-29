local Schema = require 'incline.config.schema'
local vx = require 'incline.config.validate'
local tx = require 'incline.config.transform'
local presets = require 'incline.presets'

local M = {}

M.schema = Schema(function(s)
  return {
    render = s:entry(presets.basic, vx.callable),
    debounce_threshold = s:entry(
      { rising = 10, falling = 50 },
      vx.any {
        vx.number.whole,
        vx.table.of_all { rising = vx.number.whole, falling = vx.number.whole },
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
            vx.table.of_all { left = vx.number.whole, right = vx.number.whole },
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
          vx.any { vx.number.whole, vx.table.of_all { top = vx.number.whole, bottom = vx.number.whole } },
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
          vx.table.of_all { left = vx.number.whole, right = vx.number.whole },
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
      winhighlight = {
        active = s:entry({
          Search = 'None',
          EndOfBuffer = 'None',
          Normal = 'InclineNormal',
        }, vx.map(vx.string, vx.any { vx.highlight.any, vx.string }), { transform = tx.extend }),
        inactive = s:entry({
          Search = 'None',
          EndOfBuffer = 'None',
          Normal = 'InclineNormalNC',
        }, vx.map(vx.string, vx.any { vx.highlight.any, vx.string }), { transform = tx.extend }),
      },
      options = s:entry(
        { wrap = false, signcolumn = 'no' },
        vx.all {
          vx.table,
          function(val)
            assert(val.winhighlight == nil, 'incline.config: use window.winhighlight, not window.options.winhighlight')
            return true
          end,
        },
        { transform = tx.extend }
      ),
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
    highlight = {
      groups = s:entry({
        InclineNormal = 'NormalFloat',
        InclineNormalNC = 'NormalFloat',
      }, vx.map(vx.string, vx.any { vx.highlight.args, vx.string }), { transform = tx.extend }),
    },
  }
end)

return setmetatable({
  setup = function(config)
    local schema, err = M.schema:parse(config, M.config)
    if err then
      local prefix = ({
        [Schema.result.INVALID_FIELD] = 'Invalid field',
        [Schema.result.INVALID_VALUE] = 'Invalid value',
        [Schema.result.INVALID_LEAF] = 'Invalid value: Expected table',
        [Schema.result.DEPRECATED] = 'Deprecated',
      })[schema]
      vim.notify(('[Incline.nvim] %s: %s'):format(prefix, err), vim.log.levels.ERROR)
      return
    end
    M.config = schema
  end,
  reset = function()
    M.config = nil
  end,
  schema = M.schema,
}, {
  __index = function(_, k)
    if M[k] then
      return M[k]
    end
    if M.schema.transforms[k] then
      return M.schema.transforms[k]
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
