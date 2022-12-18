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
```vim
" For lua users, delete the first and the last line.
lua << EOF
local path_actions = require('telescope_insert_path')

require('telescope').setup {
  defaults = {
    mappings = {
      n = {
        ["[i"] = path_actions.insert_relpath_i_visual,
        ["[I"] = path_actions.insert_relpath_I_visual,
        ["[a"] = path_actions.insert_relpath_a_visual,
        ["[A"] = path_actions.insert_relpath_A_visual,
        ["[o"] = path_actions.insert_relpath_o_visual,
        ["[O"] = path_actions.insert_relpath_O_visual,
        ["]i"] = path_actions.insert_abspath_i_visual,
        ["]I"] = path_actions.insert_abspath_I_visual,
        ["]a"] = path_actions.insert_abspath_a_visual,
        ["]A"] = path_actions.insert_abspath_A_visual,
        ["]o"] = path_actions.insert_abspath_o_visual,
        ["]O"] = path_actions.insert_abspath_O_visual,
        -- Additionally, there's insert and normal mode mappings for the same actions:
        -- ["{i"] = path_actions.insert_relpath_i_insert,
        -- ["{I"] = path_actions.insert_relpath_I_insert,
        -- ...
        -- ["-i"] = path_actions.insert_relpath_i_normal,
        -- ["-I"] = path_actions.insert_relpath_I_visual,
        -- ...
	-- If you want to get relative path that is relative to the file path, use
	-- `reltobufpath` instead of `relpath`
      }
    }
  }
}
EOF
```
