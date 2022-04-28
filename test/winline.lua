Describe('the incline.winline module', function()
  It('should be required as "incline.winline"', function()
    Expect({ require, 'incline.winline' }).To.Evaluate()
  end)

  local Winline = require 'incline.winline'

  Describe('the config module', function()
    Describe('the parse_render_result function', function()
      It('should parse nested render results', function()
        Expect(Winline.parse_render_result {
          'a',
          'b',
          'c',
          {
            'd',
            'e',
            guibg = 'red',
          },
          'f',
          guifg = 'blue',
        }).To.DeepEqual {
          text = 'abcdef',
          hls = {
            { range = { 0, 6 }, group = 'incline__guifg_blue' },
            { range = { 3, 5 }, group = 'incline__guibg_red' },
          },
        }
      end)
      It('should parse deeply nested render results', function()
        Expect(Winline.parse_render_result {
          'a',
          'b',
          'c',
          {
            'd',
            {
              'e',
              guibg = 'green',
            },
            'f',
            guibg = 'red',
          },
          'g',
          guifg = 'blue',
        }).To.DeepEqual {
          text = 'abcdefg',
          hls = {
            { range = { 0, 7 }, group = 'incline__guifg_blue' },
            { range = { 3, 6 }, group = 'incline__guibg_red' },
            { range = { 4, 5 }, group = 'incline__guibg_green' },
          },
        }
      end)
      It('should parse very deeply nested render results', function()
        Expect(Winline.parse_render_result {
          'foo',
          {
            'bar',
            {
              {
                'baz',
                gui = 'italic',
              },
              'qux',
              guibg = 'green',
            },
            {
              'ham',
              {
                'spam',
                {
                  'glam',
                  gui = 'underline',
                },
              },
            },
            guibg = 'red',
          },
          'blam',
          guifg = 'blue',
        }).To.DeepEqual {
          text = 'foobarbazquxhamspamglamblam',
          hls = {
            { range = { 0, 27 }, group = 'incline__guifg_blue' },
            { range = { 3, 23 }, group = 'incline__guibg_red' },
            { range = { 6, 12 }, group = 'incline__guibg_green' },
            { range = { 6, 9 }, group = 'incline__gui_italic' },
            { range = { 19, 23 }, group = 'incline__gui_underline' },
          },
        }
      end)
      It('should parse render results with nils and empty tables', function()
        Expect(Winline.parse_render_result {
          'foo',
          {
            'bar',
            {
              {
                'baz',
                nil,
                { nil },
                nil,
                { {}, {}, { {} } },
                gui = 'italic',
              },
              'qux',
              guibg = 'green',
            },
            {
              'ham',
              {
                'spam',
                {
                  'glam',
                  gui = 'underline',
                },
              },
            },
            guibg = 'red',
          },
          'blam',
          guifg = 'blue',
        }).To.DeepEqual {
          text = 'foobarbazquxhamspamglamblam',
          hls = {
            { range = { 0, 27 }, group = 'incline__guifg_blue' },
            { range = { 3, 23 }, group = 'incline__guibg_red' },
            { range = { 6, 12 }, group = 'incline__guibg_green' },
            { range = { 6, 9 }, group = 'incline__gui_italic' },
            { range = { 19, 23 }, group = 'incline__gui_underline' },
          },
        }
      end)
      It('should parse render results with numbers and strings', function()
        Expect(Winline.parse_render_result { 1, '2', 3, '4' }).To.DeepEqual { text = '1234', hls = {} }
      end)
      It('should parse empty render results', function()
        Expect(Winline.parse_render_result {}).To.DeepEqual { text = '', hls = {} }
        Expect(Winline.parse_render_result { {} }).To.DeepEqual { text = '', hls = {} }
        Expect(Winline.parse_render_result { { { {} } } }).To.DeepEqual { text = '', hls = {} }
        Expect(Winline.parse_render_result { nil, nil, nil, '', {}, nil }).To.DeepEqual { text = '', hls = {} }
      end)
    end)
  end)
end)
