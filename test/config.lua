Describe('the incline.config module', function()
  It('should be required as "incline.config"', function()
    Expect({ require, 'incline.config' }).To.Evaluate()
  end)

  local c = require 'incline.config'
  local schema = require 'incline.config.schema'

  Describe('the schema', function()
    local csv = function(path, val)
      local tail = table.remove(path)
      local cfg = {}
      local target = cfg
      for _, k in ipairs(path) do
        target[k] = {}
        target = target[k]
      end
      target[tail] = val
      local _, err = c.schema:parse(cfg)
      return err == nil
    end
    Describe('the validate() method', function()
      Describe('should validate config entries', function()
        It('should validate window.placement.vertical entries', function()
          Expect(csv({ 'window', 'placement', 'vertical' }, 'bottom')).To.Be.True()
          Expect(csv({ 'window', 'placement', 'vertical' }, 'top')).To.Be.True()
          Expect(csv({ 'window', 'placement', 'vertical' }, 'foo')).To.Be.False()
          Expect(csv({ 'window', 'placement', 'vertical' }, 1)).To.Be.False()
        end)

        It('should validate window.width entries', function()
          Expect(csv({ 'window', 'width' }, 'fill')).To.Be.True()
          Expect(csv({ 'window', 'width' }, 'fit')).To.Be.True()
          Expect(csv({ 'window', 'width' }, 10)).To.Be.True()
          Expect(csv({ 'window', 'width' }, 0.0001)).To.Be.True()
          Expect(csv({ 'window', 'width' }, 0.5)).To.Be.True()
          Expect(csv({ 'window', 'width' }, 0.9999)).To.Be.True()
          Expect(csv({ 'window', 'width' }, 1.0000)).To.Be.True()
          Expect(csv({ 'window', 'width' }, 0)).To.Be.False()
          Expect(csv({ 'window', 'width' }, 1.0001)).To.Be.False()
          Expect(csv({ 'window', 'width' }, 5.5)).To.Be.False()
          Expect(csv({ 'window', 'width' }, -0.5)).To.Be.False()
          Expect(csv({ 'window', 'width' }, -10)).To.Be.False()
          Expect(csv({ 'window', 'width' }, 'foo')).To.Be.False()
        end)

        It('should validate window.margin.horizontal entries', function()
          Expect(csv({ 'window', 'margin', 'horizontal' }, 0)).To.Be.True()
          Expect(csv({ 'window', 'margin', 'horizontal' }, 10)).To.Be.True()
          Expect(csv({ 'window', 'margin', 'horizontal' }, { left = 10, right = 5 })).To.Be.True()
          Expect(csv({ 'window', 'margin', 'horizontal' }, { left = 20, right = 0 })).To.Be.True()
          Expect(csv({ 'window', 'margin', 'horizontal' }, 'foo')).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, -1)).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, -1.5)).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, 1.5)).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, 0.5)).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, { right = 0 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, { left = 0 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, {})).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, { foo = 1 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, { left = -1, right = 0 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, { left = 'foo', right = 0 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, { left = true, right = 0 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'horizontal' }, { left = 1, right = 2, bottom = 3 })).To.Be.False()
        end)

        It('should validate window.margin.vertical entries', function()
          Expect(csv({ 'window', 'margin', 'vertical' }, 0)).To.Be.True()
          Expect(csv({ 'window', 'margin', 'vertical' }, 10)).To.Be.True()
          Expect(csv({ 'window', 'margin', 'vertical' }, { top = 10, bottom = 5 })).To.Be.True()
          Expect(csv({ 'window', 'margin', 'vertical' }, { top = 20, bottom = 0 })).To.Be.True()
          Expect(csv({ 'window', 'margin', 'vertical' }, 'foo')).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, -1)).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, -1.5)).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, 1.5)).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, 0.5)).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, { bottom = 0 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, { top = 0 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, {})).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, { foo = 1 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, { top = -1, bottom = 0 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, { top = 'foo', bottom = 0 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, { top = true, bottom = 0 })).To.Be.False()
          Expect(csv({ 'window', 'margin', 'vertical' }, { top = 1, bottom = 2, left = 3 })).To.Be.False()
        end)

        It('should validate window.padding entries', function()
          Expect(csv({ 'window', 'padding' }, 0)).To.Be.True()
          Expect(csv({ 'window', 'padding' }, 10)).To.Be.True()
          Expect(csv({ 'window', 'padding' }, { left = 10, right = 5 })).To.Be.True()
          Expect(csv({ 'window', 'padding' }, { left = 20, right = 0 })).To.Be.True()
          Expect(csv({ 'window', 'padding' }, 'foo')).To.Be.False()
          Expect(csv({ 'window', 'padding' }, -1)).To.Be.False()
          Expect(csv({ 'window', 'padding' }, -1.5)).To.Be.False()
          Expect(csv({ 'window', 'padding' }, 1.5)).To.Be.False()
          Expect(csv({ 'window', 'padding' }, 0.5)).To.Be.False()
          Expect(csv({ 'window', 'padding' }, { right = 0 })).To.Be.False()
          Expect(csv({ 'window', 'padding' }, { left = 0 })).To.Be.False()
          Expect(csv({ 'window', 'padding' }, {})).To.Be.False()
          Expect(csv({ 'window', 'padding' }, { foo = 1 })).To.Be.False()
          Expect(csv({ 'window', 'padding' }, { left = -1, right = 0 })).To.Be.False()
          Expect(csv({ 'window', 'padding' }, { left = 'foo', right = 0 })).To.Be.False()
          Expect(csv({ 'window', 'padding' }, { left = true, right = 0 })).To.Be.False()
          Expect(csv({ 'window', 'padding' }, { left = 1, right = 2, bottom = 3 })).To.Be.False()
        end)

        It('should validate window.padding_char entries', function()
          Expect(csv({ 'window', 'padding_char' }, ' ')).To.Be.True()
          Expect(csv({ 'window', 'padding_char' }, '  ')).To.Be.False()
          Expect(csv({ 'window', 'padding_char' }, '')).To.Be.False()
          Expect(csv({ 'window', 'padding_char' }, 1)).To.Be.False()
          Expect(csv({ 'window', 'padding_char' }, {})).To.Be.False()
        end)

        It('should validate window.options entries', function()
          Expect(csv({ 'window', 'options' }, { winblend = 30 })).To.Be.True()
          Expect(csv({ 'window', 'options' }, { winhighlight = 'Normal:Foobar' })).To.Be.False()
        end)

        It('should validate window.winhighlight entries', function()
          Expect(csv({ 'window', 'winhighlight' }, { active = { Normal = 'Foo' }, inactive = { Normal = 'Bar' } })).To.Be.True()
          Expect(csv({ 'window', 'winhighlight' }, { active = { Normal = 'Foo' }, inactive = {} })).To.Be.True()
          Expect(csv({ 'window', 'winhighlight' }, { active = {}, inactive = {} })).To.Be.True()
          Expect(csv({ 'window', 'winhighlight' }, { active = {} })).To.Be.True()
          Expect(csv({ 'window', 'winhighlight' }, { active = { Normal = 'Foo' } })).To.Be.True()
          Expect(csv({ 'window', 'winhighlight' }, { inactive = { Normal = 'Bar' } })).To.Be.True()
          Expect(csv({ 'window', 'winhighlight' }, {})).To.Be.True()
          Expect(csv({ 'window', 'winhighlight' }, { Normal = 'Foo' })).To.Be.True()
          Expect(csv({ 'window', 'winhighlight' }, { active = {}, Normal = 'Foo' })).To.Be.False()
          Expect(csv({ 'window', 'winhighlight' }, { active = 'Normal:Foo', inactive = 'Normal:Bar' })).To.Be.False()
          Expect(csv({ 'window', 'winhighlight' }, 'Normal:Foo')).To.Be.False()
        end)

        It('should validate ignore.unlisted_buffers entries', function()
          Expect(csv({ 'ignore', 'unlisted_buffers' }, true)).To.Be.True()
          Expect(csv({ 'ignore', 'unlisted_buffers' }, false)).To.Be.True()
          Expect(csv({ 'ignore', 'unlisted_buffers' }, '')).To.Be.False()
          Expect(csv({ 'ignore', 'unlisted_buffers' }, 1)).To.Be.False()
        end)

        It('should validate ignore.floating_wins entries', function()
          Expect(csv({ 'ignore', 'floating_wins' }, true)).To.Be.True()
          Expect(csv({ 'ignore', 'floating_wins' }, false)).To.Be.True()
          Expect(csv({ 'ignore', 'floating_wins' }, '')).To.Be.False()
          Expect(csv({ 'ignore', 'floating_wins' }, 1)).To.Be.False()
        end)

        It('should validate ignore.filetypes entries', function()
          Expect(csv({ 'ignore', 'filetypes' }, {})).To.Be.True()
          Expect(csv({ 'ignore', 'filetypes' }, { 'javascript' })).To.Be.True()
          Expect(csv({ 'ignore', 'filetypes' }, { 'javascript', 'css' })).To.Be.True()
          Expect(csv({ 'ignore', 'filetypes' }, { 'javascript', 'css', 1 })).To.Be.False()
          Expect(csv({ 'ignore', 'filetypes' }, { 1 })).To.Be.False()
          Expect(csv({ 'ignore', 'filetypes' }, { {} })).To.Be.False()
          Expect(csv({ 'ignore', 'filetypes' }, 'javascript')).To.Be.False()
        end)

        It('should validate ignore.buftypes entries', function()
          Expect(csv({ 'ignore', 'buftypes' }, 'special')).To.Be.True()
          Expect(csv({ 'ignore', 'buftypes' }, {})).To.Be.True()
          Expect(csv({ 'ignore', 'buftypes' }, { '' })).To.Be.True()
          Expect(csv({ 'ignore', 'buftypes' }, { 'acwrite' })).To.Be.True()
          Expect(csv({ 'ignore', 'buftypes' }, { 'acwrite', 'help' })).To.Be.True()
          Expect(csv({ 'ignore', 'buftypes' }, { 'prompt', 'acwrite', 'help' })).To.Be.True()
          Expect(csv({ 'ignore', 'buftypes' }, function() end)).To.Be.True()
          Expect(csv({ 'ignore', 'buftypes' }, 0)).To.Be.False()
          Expect(csv({ 'ignore', 'buftypes' }, '')).To.Be.False()
          Expect(csv({ 'ignore', 'buftypes' }, 'help')).To.Be.False()
          Expect(csv({ 'ignore', 'buftypes' }, { 'special' })).To.Be.False()
          Expect(csv({ 'ignore', 'buftypes' }, { '', 1 })).To.Be.False()
          Expect(csv({ 'ignore', 'buftypes' }, { '', 'foo' })).To.Be.False()
          Expect(csv({ 'ignore', 'buftypes' }, { '', false })).To.Be.False()
          Expect(csv({ 'ignore', 'buftypes' }, { function() end })).To.Be.False()
        end)

        It('should validate ignore.wintypes entries', function()
          Expect(csv({ 'ignore', 'wintypes' }, 'special')).To.Be.True()
          Expect(csv({ 'ignore', 'wintypes' }, {})).To.Be.True()
          Expect(csv({ 'ignore', 'wintypes' }, { '' })).To.Be.True()
          Expect(csv({ 'ignore', 'wintypes' }, { 'autocmd' })).To.Be.True()
          Expect(csv({ 'ignore', 'wintypes' }, { 'autocmd', 'preview' })).To.Be.True()
          Expect(csv({ 'ignore', 'wintypes' }, { 'popup', 'autocmd', '' })).To.Be.True()
          Expect(csv({ 'ignore', 'wintypes' }, function() end)).To.Be.True()
          Expect(csv({ 'ignore', 'wintypes' }, 0)).To.Be.False()
          Expect(csv({ 'ignore', 'wintypes' }, '')).To.Be.False()
          Expect(csv({ 'ignore', 'wintypes' }, 'preview')).To.Be.False()
          Expect(csv({ 'ignore', 'wintypes' }, { 'special' })).To.Be.False()
          Expect(csv({ 'ignore', 'wintypes' }, { '', 1 })).To.Be.False()
          Expect(csv({ 'ignore', 'wintypes' }, { '', 'foo' })).To.Be.False()
          Expect(csv({ 'ignore', 'wintypes' }, { '', false })).To.Be.False()
          Expect(csv({ 'ignore', 'wintypes' }, { function() end })).To.Be.False()
        end)

        It('should validate highlight.groups entries', function()
          Expect(csv({ 'highlight', 'groups' }, { Foo = { guifg = 'ff0000' } })).To.Be.True()
          Expect(csv({ 'highlight', 'groups' }, { Foo = { guifg = 'ff0000' }, Bar = { gui = 'test' } })).To.Be.True()
          Expect(csv({ 'highlight', 'groups' }, { Foo = { guifg = 'ff0000' }, Bar = { blend = 1 } })).To.Be.True()
          Expect(csv({ 'highlight', 'groups' }, { Foo = { guifg = 'ff0000', default = true }, Bar = { blend = 1 } })).To.Be.True()
          Expect(csv({ 'highlight', 'groups' }, { Foo = { group = 'Foo', default = true } })).To.Be.True()
          Expect(csv({ 'highlight', 'groups' }, {})).To.Be.True()
          Expect(csv({ 'highlight', 'groups' }, { Foo = { guifg = 'ff0000', efault = true }, Bar = { blend = 1 } })).To.Be.False()
          Expect(csv({ 'highlight', 'groups' }, { Foo = { guifg = true } })).To.Be.False()
          Expect(csv({ 'highlight', 'groups' }, { { guifg = 'ff0000' } })).To.Be.False()
          Expect(csv({ 'highlight', 'groups' }, { { guifg = 'ff0000', group = 'Foo' } })).To.Be.False()
        end)
      end)
    end)

    Describe('the default() method', function()
      It('should return a table matching the schema', function()
        local default = c.schema:default()
        Expect(default).To.Be.A.Table()
        Expect(default).To.HaveFieldPaths {
          { 'render', Which.Is.A.Function },
          { 'debounce_threshold', Which.Is.A.Table },
          { 'window', Which.Is.A.Table },
          { 'window.overlap', Which.Is.A.Table },
          { 'window.overlap.winbar' },
          { 'window.overlap.tabline' },
          { 'window.placement', Which.Is.A.Table },
          { 'window.placement.vertical' },
          { 'window.placement.horizontal' },
          { 'window.width' },
          { 'window.margin', Which.Is.A.Table },
          { 'window.padding', Which.Is.A.Table },
          { 'window.padding_char', Which.Is.A.String },
          { 'ignore', Which.Is.A.Table },
          { 'ignore.unlisted_buffers', Which.Is.A.Boolean },
          { 'ignore.floating_wins', Which.Is.A.Boolean },
          { 'ignore.filetypes', Which.Is.A.ListLike },
          { 'ignore.buftypes' },
          { 'ignore.wintypes' },
        }
      end)
    end)

    Describe('the parse() method', function()
      It('should return a table matching the schema when passed a value', function()
        local parsed = c.schema:parse { window = { placement = { vertical = 'bottom' } } }
        Expect(parsed).To.Be.A.Table()
        Expect(parsed).To.HaveFieldPaths {
          { 'render', Which.Is.A.Function },
          { 'debounce_threshold', Which.Is.A.Table },
          { 'window', Which.Is.A.Table },
          { 'window.placement', Which.Is.A.Table },
          { 'window.placement.vertical' },
          { 'window.placement.horizontal' },
          { 'window.overlap', Which.Is.A.Table },
          { 'window.overlap.winbar' },
          { 'window.overlap.tabline' },
          { 'window.width' },
          { 'window.margin', Which.Is.A.Table },
          { 'window.padding', Which.Is.A.Table },
          { 'window.padding_char', Which.Is.A.String },
          { 'ignore', Which.Is.A.Table },
          { 'ignore.unlisted_buffers', Which.Is.A.Boolean },
          { 'ignore.floating_wins', Which.Is.A.Boolean },
          { 'ignore.filetypes', Which.Is.A.ListLike },
          { 'ignore.buftypes' },
          { 'ignore.wintypes' },
        }
        Expect(parsed.window.placement.vertical).To.Equal 'bottom'
      end)

      It('should return a table with the specified fields updated', function()
        local parsed = c.schema:parse {
          window = {
            placement = {
              vertical = 'bottom',
            },
            width = 12,
          },
        }
        Expect(parsed.window.placement.vertical).To.Equal 'bottom'
        Expect(parsed.window.width).To.Equal(12)
      end)

      It('should not be affected by empty fields', function()
        Expect(c.schema:parse {
          window = { placement = {} },
        }).To.DeepEqual(c.schema:default())
        Expect(c.schema:parse {
          window = {},
        }).To.DeepEqual(c.schema:default())
      end)

      It('should throw an error if passed a config with an invalid value', function()
        local s, err
        s, err = c.schema:parse { window = { placement = { vertical = 'downunder' } } }
        Expect(s).To.Equal(schema.result.INVALID_VALUE)
        Expect(err).To.Equal 'window.placement.vertical'

        s, err = c.schema:parse { debounce_threshold = -2 }
        Expect(s).To.Equal(schema.result.INVALID_VALUE)
        Expect(err).To.Equal 'debounce_threshold'

        s, err = c.schema:parse { debounce_threshold = 2.2 }
        Expect(s).To.Equal(schema.result.INVALID_VALUE)
        Expect(err).To.Equal 'debounce_threshold'
      end)

      It('should throw an error if passed a config with an invalid field', function()
        local s, err
        s, err = c.schema:parse { window = { placement = { Vertical = 'bottom' } } }
        Expect(s).To.Equal(schema.result.INVALID_FIELD)
        Expect(err).To.Equal 'window.placement.Vertical'

        s, err = c.schema:parse { window = { lacement = { vertical = 'bottom' } } }
        Expect(s).To.Equal(schema.result.INVALID_FIELD)
        Expect(err).To.Equal 'window.lacement'

        s, err = c.schema:parse { 'foo' }
        Expect(s).To.Equal(schema.result.INVALID_FIELD)
        Expect(err).To.Equal '[1]'

        s, err = c.schema:parse { window = { 'foo' } }
        Expect(s).To.Equal(schema.result.INVALID_FIELD)
        Expect(err).To.Equal 'window[1]'
      end)

      Describe('fields with default "extend" transformers', function()
        It('should extend the default values', function()
          local default = c.schema:default()
          local parsed = c.schema:parse {
            window = {
              options = {
                winblend = 22,
              },
            },
          }
          Expect(vim.tbl_keys(default.window.options)).To.Be.LongerThan(1)
          Expect(vim.tbl_keys(parsed.window.options)).To.Have.Length(#vim.tbl_keys(default.window.options) + 1)
          Expect(parsed.window.options.winblend).To.Equal(22) -- From extension
        end)
      end)

      Describe('fields passed "replace" transforms', function()
        It('should replace the default values', function()
          local default = c.schema:default()
          local options = {
            winblend = 22,
          }
          local parsed = c.schema:parse {
            window = {
              options = c.schema.transforms.replace(options),
            },
          }
          Expect(vim.tbl_keys(default.window.options)).To.Be.LongerThan(1)
          Expect(vim.tbl_keys(parsed.window.options)).To.Have.Length(1)
          Expect(parsed.window.options).To.DeepEqual(options)
        end)
      end)
    end)
  end)

  Describe('the config module', function()
    It("should use the default config if setup isn't called", function()
      local default = c.schema:default()
      Expect(c.config).To.DeepEqual(default)
      Expect(c.ignore.unlisted_buffers).To.Equal(default.ignore.unlisted_buffers)
      c.reset()
    end)

    It('should update the config when setup is called', function()
      local cfg = { ignore = { wintypes = { 'autocmd' } } }
      local default = c.schema:default()
      Expect({ c.setup, cfg }).To.Evaluate()
      Expect(c.config).To.Not.DeepEqual(default)
      Expect(c.config.ignore.wintypes).To.DeepEqual(cfg.ignore.wintypes)
      Expect(c.config.window).To.DeepEqual(default.window)
      c.reset()
    end)

    It('should use the previous config as the fallback', function()
      local cfgs = {
        { ignore = { wintypes = { 'autocmd' } } },
        { debounce_threshold = { rising = 13, falling = 37 } },
      }
      local default = c.schema:default()

      Expect({ c.setup, cfgs[1] }).To.Evaluate()
      Expect(c.config).To.Not.DeepEqual(default)
      Expect(c.config.ignore.wintypes).To.DeepEqual(cfgs[1].ignore.wintypes)
      Expect(c.config.ignore.wintypes).To.Not.DeepEqual(default.ignore.wintypes)
      Expect(c.config.debounce_threshold).To.Not.Equal(cfgs[1].debounce_threshold)

      local cfg1 = vim.deepcopy(c.config)

      Expect({ c.setup, cfgs[2] }).To.Evaluate()
      Expect(c.config).To.Not.DeepEqual(default)
      Expect(c.config).To.Not.DeepEqual(cfg1)
      Expect(c.config.ignore.wintypes).To.DeepEqual(cfgs[1].ignore.wintypes)
      Expect(c.config.ignore.wintypes).To.DeepEqual(cfg1.ignore.wintypes)
      Expect(c.config.ignore.wintypes).To.Not.DeepEqual(default.ignore.wintypes)
      Expect(c.config.debounce_threshold).To.Not.Equal(cfgs[1].debounce_threshold)
      Expect(c.config.debounce_threshold).To.Equal(cfgs[2].debounce_threshold)
      c.reset()
    end)

    It('should display a notification if there is an error in the config', function()
      local notify_called = false
      vim.notify = function()
        notify_called = true
      end
      local default = c.schema:default()
      c.setup { non_existant_key = 123 }
      Expect(notify_called).To.Be.True()
      Expect(c.config).To.DeepEqual(default)
      c.reset()
    end)
  end)
end)
