# telescope-insert-path.nvim

Set of [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) actions to insert file path on the current buffer.

### Supported Path Types
- Absolute path
- Relative path

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
        ["pi"] = path_actions.insert_relpath_i_visual,
        ["pI"] = path_actions.insert_relpath_I_visual,
        ["pa"] = path_actions.insert_relpath_a_visual,
        ["pA"] = path_actions.insert_relpath_A_visual,
        ["po"] = path_actions.insert_relpath_o_visual,
        ["pO"] = path_actions.insert_relpath_O_visual,
        ["Pi"] = path_actions.insert_abspath_i_visual,
        ["PI"] = path_actions.insert_abspath_I_visual,
        ["Pa"] = path_actions.insert_abspath_a_visual,
        ["PA"] = path_actions.insert_abspath_A_visual,
        ["Po"] = path_actions.insert_abspath_o_visual,
        ["PO"] = path_actions.insert_abspath_O_visual,
        -- Additionally, there's insert and normal mode mappings for the same actions:
        -- ["<leader>pi"] = path_actions.insert_relpath_i_insert,
        -- ["<leader><leader>pi"] = path_actions.insert_relpath_i_normal,
        -- ...
      }
    }
  }
}
EOF
```
