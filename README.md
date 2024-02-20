# 🎈 incline.nvim

[![License: MIT](https://img.shields.io/github/license/b0o/incline.nvim?style=flat&color=green)](https://mit-license.org) [![Test Status](https://img.shields.io/github/actions/workflow/status/b0o/incline.nvim/test.yaml?branch=main&label=tests)](https://github.com/b0o/incline.nvim/actions/workflows/test.yaml)

Incline is a plugin for creating lightweight floating statuslines. It works great with Neovim's global statusline (`:set laststatus=3`).

Why use Incline instead of Neovim's built-in winbar? Incline:

- Only takes up the amount of space it needs, leaving the rest of the line available for your code.
- Is highly configurable and themeable using Lua.
- Can be shown/hidden dynamically based on cursor position, focus, buffer type, or any other condition.
- Can be positioned at the top or bottom, left or right side of each window.

![Screenshot of Incline.nvim running in Neovim](https://user-images.githubusercontent.com/21299126/167235114-d562ea45-155c-4d82-aaf1-95abb56398b7.png)

## Configuration

The render function is the most important part of an Incline configuration. As the name suggests, it's called for each window in order to render its statusline. You can think of it like a React component: it's passed a table of props and returns a tree-like data structure describing the content and appearance of the statusline. For example:

```lua
function(props)
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
  local modified = vim.bo[props.buf].modified
  return {
    filename,
    modified and { '*', guifg = '#888888', gui = 'bold' } or '',
    guibg = '#111111',
    guifg = '#eeeeee',
  }
end
```

The returned value can be a string or a table which can include strings, highlight properties like foreground/background color, or even nested tables. Nested tables can contain the same sorts of things, including more nested tables. For more on the render function, see [`:help incline-render`](https://github.com/b0o/incline.nvim/blob/main/doc/incline.txt#L92).

Below are some examples to get you started.

### Icon + Filename

![Screenshot](https://github.com/b0o/incline.nvim/assets/21299126/f8c2c7d5-e14f-465d-a308-c5128c8ed4eb)

Requires [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons).

<details>
  <summary>View Code</summary>

```lua
local helpers = require 'incline.helpers'
require('incline').setup {
  window = {
    padding = 0,
    margin = { horizontal = 0 },
  },
  render = function(props)
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
    local ft_icon, ft_color = require('nvim-web-devicons').get_icon_color(filename)
    local modified = vim.bo[props.buf].modified
    local buffer = {
      ft_icon and { ' ', ft_icon, ' ', guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or '',
      ' ',
      { filename, gui = modified and 'bold,italic' or 'bold' },
      ' ',
      guibg = '#44406e',
    }
    return buffer
  end,
}
```
</details>

### Icon + Filename + Navic

![Screenshot](https://github.com/b0o/incline.nvim/assets/21299126/3fc2560a-927e-4bc2-88cc-0fb68561a2ca)

Requires [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) and [nvim-navic](https://github.com/SmiteshP/nvim-navic).

<details>
  <summary>View Code</summary>

```lua
local helpers = require 'incline.helpers'
local navic = require 'nvim-navic'
require('incline').setup {
  window = {
    padding = 0,
    margin = { horizontal = 0, vertical = 0 },
  },
  render = function(props)
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
    local ft_icon, ft_color = require('nvim-web-devicons').get_icon_color(filename)
    local modified = vim.bo[props.buf].modified
    local res = {
      ft_icon and { ' ', ft_icon, ' ', guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or '',
      ' ',
      { filename, gui = modified and 'bold,italic' or 'bold' },
      guibg = '#44406e',
    }
    if props.focused then
      for _, item in ipairs(navic.get_data(props.buf) or {}) do
        table.insert(res, {
          { ' > ', group = 'NavicSeparator' },
          { item.icon, group = 'NavicIcons' .. item.type },
          { item.name, group = 'NavicText' },
        })
      end
    end
    table.insert(res, ' ')
    return res
  end,
}
```
</details>

### Diagnostics + Git Diff + Filename 

![Screenshot](https://github.com/b0o/incline.nvim/assets/21299126/db581ae7-66b9-468a-9a8c-511539fe1cb0)

Requires [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons).

Credit: [@lkhphuc](https://github.com/lkhphuc) ([Discussion](https://github.com/b0o/incline.nvim/discussions/32))

<details>
  <summary>View Code</summary>

```lua
require('incline').setup {
  render = function(props)
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
    local ft_icon, ft_color = require('nvim-web-devicons').get_icon_color(filename)
    local modified = vim.bo[props.buf].modified and 'bold,italic' or 'bold'

    local function get_git_diff()
      local icons = { removed = '', changed = '', added = '' }
      icons['changed'] = icons.modified
      local signs = vim.b[props.buf].gitsigns_status_dict
      local labels = {}
      if signs == nil then
        return labels
      end
      for name, icon in pairs(icons) do
        if tonumber(signs[name]) and signs[name] > 0 then
          table.insert(labels, { icon .. signs[name] .. ' ', group = 'Diff' .. name })
        end
      end
      if #labels > 0 then
        table.insert(labels, { '┊ ' })
      end
      return labels
    end
    local function get_diagnostic_label()
      local icons = { error = '', warn = '', info = '', hint = '' }
      local label = {}

      for severity, icon in pairs(icons) do
        local n = #vim.diagnostic.get(props.buf, { severity = vim.diagnostic.severity[string.upper(severity)] })
        if n > 0 then
          table.insert(label, { icon .. n .. ' ', group = 'DiagnosticSign' .. severity })
        end
      end
      if #label > 0 then
        table.insert(label, { '┊ ' })
      end
      return label
    end

    return {
      { get_diagnostic_label() },
      { get_git_diff() },
      { (ft_icon or '') .. ' ', guifg = ft_color, guibg = 'none' },
      { filename .. ' ', gui = modified },
      { '┊  ' .. vim.api.nvim_win_get_number(props.win), group = 'DevIconWindows' },
    }
  end,
}
```
</details>

### More Examples

See more user-contributed configurations and share your own in the [Showcase](https://github.com/b0o/incline.nvim/discussions/categories/showcase).

## Installation

[Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'b0o/incline.nvim',
  opts = {},
  -- Optional: Lazy load Incline
  event = 'VeryLazy',
},
```

[Packer](https://github.com/wbthomason/packer.nvim):

```lua
use "b0o/incline.nvim"
```

## Usage

```lua
require('incline').setup()
```

### Configuration

Incline's default configuration:

<!--DEFAULT_CONFIG-->

```lua
require('incline').setup {
  debounce_threshold = {
    falling = 50,
    rising = 10
  },
  hide = {
    cursorline = false,
    focused_win = false,
    only_win = false
  },
  highlight = {
    groups = {
      InclineNormal = {
        default = true,
        group = "NormalFloat"
      },
      InclineNormalNC = {
        default = true,
        group = "NormalFloat"
      }
    }
  },
  ignore = {
    buftypes = "special",
    filetypes = {},
    floating_wins = true,
    unlisted_buffers = true,
    wintypes = "special"
  },
  render = "basic",
  window = {
    margin = {
      horizontal = 1,
      vertical = 1
    },
    options = {
      signcolumn = "no",
      wrap = false
    },
    padding = 1,
    padding_char = " ",
    placement = {
      horizontal = "right",
      vertical = "top"
    },
    width = "fit",
    winhighlight = {
      active = {
        EndOfBuffer = "None",
        Normal = "InclineNormal",
        Search = "None"
      },
      inactive = {
        EndOfBuffer = "None",
        Normal = "InclineNormalNC",
        Search = "None"
      }
    },
    zindex = 50
  }
}
```

<!--/DEFAULT_CONFIG-->

See [`incline.txt`](https://github.com/b0o/incline.nvim/blob/main/doc/incline.txt) for full documentation of all configuration options.

## Changelog

```
29 Apr 2022                                                             v0.0.3
  Breaking: window.options.winhighlight is deprecated
  Feat: Add highlight support
  Feat: Support hiding Incline on the only window in a tabpage
  Feat: Support hiding Incline on the focused window
  Feat: Allow tables of highlight args as winhighlight values
  Feat: Add preset render functions
  Feat: Add functions to globally enable/disable/toggle Incline
  Feat: Add config.window.options
  Feat: Add configuration transforms
  Tweak: Display notification upon invalid config rather than throwing error
  Tweak: Allow rising & falling debounce threshold to be configured separately
  Fix: Destroy child when an existing win becomes ignored
  Fix: Handle when manager.win_get_tabpage passed nil or 0
  Fix: check winline _buf and _win for nil
  Misc: Refactor, fix bugs, and improve stability

14 Apr 2022                                                             v0.0.2
  Feat: Make position, size, and content configurable
  Feat: Validate user configuration against schema
  Docs: Add documentation
  Tests: Add tests for configuration and schema
  Misc: Refactor, fix bugs, and improve stability

07 Apr 2022                                                             v0.0.1
  Initial Release
```

## License

&copy; <!--COPYRIGHT-->2022-2024 Maddison Hellstrom and contributors<!--/COPYRIGHT-->

Released under the MIT License.
