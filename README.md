# telescope-insert-path.nvim

Set of [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) actions to insert file path on the current buffer.

### Supported Locations
- `i`: before cursor
- `a`: after cursor
- `I`: beginning of the line
- `A`: end of the line
- `o`: new line after
- `O`: new line before

### Supported Vim Modes
After inserting the path on your file, it can be in any modes:
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
        ["pi"] = path_actions.insert_relpath_i_insert,
        ["pI"] = path_actions.insert_relpath_I_insert,
        ["pa"] = path_actions.insert_relpath_a_insert,
        ["pA"] = path_actions.insert_relpath_A_insert,
        ["po"] = path_actions.insert_relpath_o_insert,
        ["pO"] = path_actions.insert_relpath_O_insert,
        ["Pi"] = path_actions.insert_abspath_i_insert,
        ["PI"] = path_actions.insert_abspath_I_insert,
        ["Pa"] = path_actions.insert_abspath_a_insert,
        ["PA"] = path_actions.insert_abspath_A_insert,
        ["Po"] = path_actions.insert_abspath_o_insert,
        ["PO"] = path_actions.insert_abspath_O_insert,
        ["<leader>pi"] = path_actions.insert_relpath_i_visual,
        ["<leader>pI"] = path_actions.insert_relpath_I_visual,
        ["<leader>pa"] = path_actions.insert_relpath_a_visual,
        ["<leader>pA"] = path_actions.insert_relpath_A_visual,
        ["<leader>po"] = path_actions.insert_relpath_o_visual,
        ["<leader>pO"] = path_actions.insert_relpath_O_visual,
        ["<leader>Pi"] = path_actions.insert_abspath_i_visual,
        ["<leader>PI"] = path_actions.insert_abspath_I_visual,
        ["<leader>Pa"] = path_actions.insert_abspath_a_visual,
        ["<leader>PA"] = path_actions.insert_abspath_A_visual,
        ["<leader>Po"] = path_actions.insert_abspath_o_visual,
        ["<leader>PO"] = path_actions.insert_abspath_O_visual,
        -- Additionally, there's normal mode mappings for the same actions:
        -- ["<leader><leader>pi"] = path_actions.insert_relpath_i_normal,
        -- ...
      }
    }
  }
}
EOF
```
