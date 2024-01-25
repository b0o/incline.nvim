# incline.nvim [![Version v0.0.3](https://img.shields.io/github/v/tag/b0o/incline.nvim?style=flat&color=yellow&label=version&sort=semver)](https://github.com/b0o/incline.nvim/releases) [![License: MIT](https://img.shields.io/github/license/b0o/incline.nvim?style=flat&color=green)](https://mit-license.org) [![Test Status](https://img.shields.io/github/actions/workflow/status/b0o/incline.nvim/test.yaml?branch=main&label=tests)](https://github.com/b0o/incline.nvim/actions/workflows/test.yaml)

Lightweight floating statuslines, best used with Neovim's global statusline (`set laststatus=3`).

![Screenshot of Incline.nvim running in Neovim](https://user-images.githubusercontent.com/21299126/167235114-d562ea45-155c-4d82-aaf1-95abb56398b7.png)

See more screenshots and share your own in the [showcase](https://github.com/b0o/incline.nvim/discussions/categories/showcase).

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
    overlap = {
      statusline = false,
      winbar = false,
      tabline = false,
      borders = true,
    },
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
