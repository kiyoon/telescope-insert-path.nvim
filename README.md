# telescope-insert-path.nvim

Set of [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) actions to insert file path on the current buffer.

<img src="https://user-images.githubusercontent.com/12980409/206919320-aa0d9b79-771e-4560-9cb3-9787d1c6460f.gif" width="100%"/>

### Supported Path Types

- Absolute path
- Relative path (to current working directory)
- Relative path (to buffer file)

### Supported Insert Locations

- `i`: before cursor
- `a`: after cursor
- `I`: beginning of the line
- `A`: end of the line
- `o`: new line after
- `O`: new line before

### Supported Vim Modes after Insertion

You can configure it to be in these three modes after insertion:

- Insert
- Normal
- Visual mode with the path selected

### Supported Telescope Modes

- Multiple selections
- Any modes (Find files, Live grep, ...)

## Installation

Install using vim-plug:

```vim
Plug 'kiyoon/telescope-insert-path.nvim'
```

Install using packer:

```lua
use {'kiyoon/telescope-insert-path.nvim'}
```

Setup telescope with path actions in vimscript / lua:

```lua
local path_actions = require('telescope_insert_path')

require('telescope').setup {
  defaults = {
    mappings = {
      n = {
        -- E.g. Type `[i`, `[I`, `[a`, `[A`, `[o`, `[O` to insert relative path and select the path in visual mode.
        -- Other mappings work the same way with a different prefix.
        ["["] = path_actions.insert_reltobufpath_visual,
        ["]"] = path_actions.insert_abspath_visual,
        ["{"] = path_actions.insert_reltobufpath_insert,
        ["}"] = path_actions.insert_abspath_insert,
        ["-"] = path_actions.insert_reltobufpath_normal,
        ["="] = path_actions.insert_abspath_normal,
	-- If you want to get relative path that is relative to the cwd, use
	-- `relpath` instead of `reltobufpath`
        -- You can skip the location postfix if you specify that in the function name.
        -- ["<C-o>"] = path_actions.insert_relpath_o_visual,
      }
    }
  }
}
```
