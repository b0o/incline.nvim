# incline.nvim [![Version](https://img.shields.io/github/v/tag/b0o/incline.nvim?style=flat&color=yellow&label=version&sort=semver)](https://github.com/b0o/incline.nvim/releases) [![License: MIT](https://img.shields.io/github/license/b0o/incline.nvim?style=flat&color=green)](https://mit-license.org) [![Test Status](https://img.shields.io/github/workflow/status/b0o/incline.nvim/test?label=tests)](https://github.com/b0o/incline.nvim/actions/workflows/test.yaml)

Lightweight floating statuslines, intended for use with Neovim's new global statusline (`set laststatus=3`).

**This plugin is very early in development**. It's currently just a proof-of-concept. **Expect bugs and breaking changes.**

![Screenshot of incline.nvim running in Neovim](https://user-images.githubusercontent.com/21299126/162644089-7f1ff22b-dedf-4bbf-a0ac-6dc6bf2f602b.png)

## Install

[Packer](https://github.com/wbthomason/packer.nvim):

```lua
use "b0o/incline.nvim"
```

## Usage

```lua
require('incline').setup()
```

## Changelog

```
07 Apr 2022                                                             v0.0.1
  Initial Release
```

## License

&copy; 2022 Maddison Hellstrom

Released under the MIT License.
