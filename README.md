# Incline.nvim [![Version](https://img.shields.io/github/v/tag/b0o/incline.nvim?style=flat&color=yellow&label=version&sort=semver)](https://github.com/b0o/incline.nvim/releases) [![License: MIT](https://img.shields.io/github/license/b0o/incline.nvim?style=flat&color=green)](https://mit-license.org) [![Test Status](https://img.shields.io/github/workflow/status/b0o/incline.nvim/test?label=tests)](https://github.com/b0o/incline.nvim/actions/workflows/test.yaml)

Lightweight floating statuslines, intended for use with Neovim's new global statusline (`set laststatus=3`).

**This plugin is very early in development**. It doesn't have a ton of features or testing yet. Please [open an issue](https://github.com/b0o/incline.nvim/issues/new) if you have a suggestion or encounter any problems!

![Screenshot of Incline.nvim running in Neovim](https://user-images.githubusercontent.com/21299126/162644089-7f1ff22b-dedf-4bbf-a0ac-6dc6bf2f602b.png)

## Install

[Packer](https://github.com/wbthomason/packer.nvim):

```lua
use "b0o/incline.nvim"
```

## Usage

```lua
require('incline').setup()
```

## Configuration

Incline's default configuration:

```lua
require('incline').setup {
  render = function(props)
    local bufname = vim.api.nvim_buf_get_name(props.buf)
    if bufname == '' then
      return '[No name]'
    else
      bufname = vim.fn.fnamemodify(bufname, ':t')
    end
    return bufname
  end,
  debounce_threshold = 30,
  window = {
    width = 'fit',
    placement = { horizontal = 'right', vertical = 'top' },
    margin = {
      horizontal = { left = 1, right = 1 },
      vertical = { bottom = 0, top = 1 },
    },
    padding = { left = 1, right = 1 },
    padding_char = ' ',
    zindex = 50,
  },
  ignore = {
    floating_wins = true,
    unlisted_buffers = true,
    filetypes = {},
    buftypes = 'special',
    wintypes = 'special',
  },
}
```

See [`incline.txt`](https://github.com/b0o/incline.nvim/blob/main/doc/incline.txt) for full documentation of all configuration options.

## Changelog

```
14 Apr 2022                                                             v0.0.2
  Add documentation
  Make position, size, and content configurable
  Validate user configuration against schema
  Add tests for configuration and schema
  Refactor, fix bugs, and improve stability

07 Apr 2022                                                             v0.0.1
  Initial Release
```

## License

&copy; 2022 Maddison Hellstrom

Released under the MIT License.
