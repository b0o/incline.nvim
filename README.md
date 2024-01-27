# incline.nvim [![Version v0.0.3](https://img.shields.io/github/v/tag/b0o/incline.nvim?style=flat&color=yellow&label=version&sort=semver)](https://github.com/b0o/incline.nvim/releases) [![License: MIT](https://img.shields.io/github/license/b0o/incline.nvim?style=flat&color=green)](https://mit-license.org) [![Test Status](https://img.shields.io/github/actions/workflow/status/b0o/incline.nvim/test.yaml?branch=main&label=tests)](https://github.com/b0o/incline.nvim/actions/workflows/test.yaml)

Incline is a plugin for creating lightweight floating statuslines. It's best used with Neovim's global statusline (`set laststatus=3`).

![Screenshot of Incline.nvim running in Neovim](https://user-images.githubusercontent.com/21299126/167235114-d562ea45-155c-4d82-aaf1-95abb56398b7.png)

## Example Configurations

Incline is highly flexible, but by default it looks very plain. The core of an Incline configuration is the render function, which is a Lua function that Incline runs for each visible window. You can think of the render function like a React component - it is passed some props, and returns a tree-like data structure that describes the content and visual style of the result. Here's an example of a config with a simple render function that displays a colored filetype icon and filename:

![2024-01-26_20-07-50_region](https://github.com/b0o/incline.nvim/assets/21299126/f8c2c7d5-e14f-465d-a308-c5128c8ed4eb)
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

For more details on the render function, see [`:help incline-render`](https://github.com/b0o/incline.nvim/blob/main/doc/incline.txt#L92). Below, you'll find some more example configurations for inspiration.

### Diagnostics + Git Diff + Filename 

![Screenshot](https://user-images.githubusercontent.com/12573521/200856241-d936bd21-bdb3-4348-9108-94fc72d4f2de.png)

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
