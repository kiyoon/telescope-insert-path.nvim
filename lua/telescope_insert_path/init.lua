local tele_status_ok, telescope = pcall(require, "telescope")
if not tele_status_ok then
	return
end

local path_actions = setmetatable({}, {
  __index = function(_, k)
    error("Key does not exist for 'telescope_insert_path': " .. tostring(k))
  end,
})

local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local insert_path = function(prompt_bufnr, relative, location, vim_mode)
  local picker = action_state.get_current_picker(prompt_bufnr)

  actions.close(prompt_bufnr)

  local entry = action_state.get_selected_entry(prompt_bufnr)

  -- local from_entry = require "telescope.from_entry"
  -- local filename = from_entry.path(entry)
  local filename
  if relative then
    filename = entry.filename
  else
    filename = entry.path
  end

  local selections = {}
  for _, selection in ipairs(picker:get_multi_selection()) do
    print(selection)
    local selection_filename
    if relative then
      selection_filename = selection.filename
    else
      selection_filename = selection.path
    end

    if selection_filename ~= filename then
      table.insert(selections, selection_filename)
    end
  end

  -- normal mode
  vim.cmd [[stopinsert]]

  local put_after = nil
  if location == 'i' then
    put_after = false
  elseif location == 'I' then
    vim.cmd([[normal! I]])
    put_after = false
  elseif location == 'a' then
    put_after = true
  elseif location == 'A' then
    vim.cmd([[normal! $]])
    put_after = true
  elseif location == 'o' then
    vim.cmd([[normal! o ]])   -- add empty space so the cursor respects the indent
    vim.cmd([[normal! x]])   -- and immediately delete it
    put_after = true 
  elseif location == 'O' then
    vim.cmd([[normal! O ]])
    vim.cmd([[normal! x]])
    put_after = true 
  end

  -- put 1 character
  vim.api.nvim_put({ filename:sub(1,1) }, "", put_after, true)
  -- check if we're putting at the end of line or there's a trailing content after.
  local line_col_len = vim.api.nvim_get_current_line():len()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local trailing_content = false
  if cursor_pos[2] ~= line_col_len-1 then
    trailing_content = true
  end

  if trailing_content then
    vim.cmd([[normal! h]])
  end

  if vim_mode == 'v' then
    -- enter visual mode
    vim.cmd([[normal! v]])
  end

  -- put the rest of the filename
  if filename:len() > 1 then
    vim.api.nvim_put({ filename:sub(2) }, "", true, true)
    if trailing_content then
      vim.cmd([[normal! h]])
    end
  end

  -- put the selections
  if #selections > 0 then
    -- start with empty line
    table.insert(selections, 1, "")
    vim.api.nvim_put(selections, "", true, true)
  else
    -- make the cursor consistent
    if trailing_content then
      vim.cmd([[normal! l]])
    end
  end

  if vim_mode == 'v' or vim_mode == 'n' then
    -- go back 1 if the line was not empty because we're selecting that character.
    if trailing_content then
      vim.cmd([[normal! h]])
    end
  elseif vim_mode == 'i' then
    if trailing_content then
      vim.cmd [[startinsert]]
    else
      vim.cmd [[startinsert!]]
    end
  end
end

-- insert mode mappings
path_actions.insert_abspath_i_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "i", "i")
end

path_actions.insert_abspath_I_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "I", "i")
end

path_actions.insert_abspath_a_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "a", "i")
end

path_actions.insert_abspath_A_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "A", "i")
end

path_actions.insert_abspath_o_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "o", "i")
end

path_actions.insert_abspath_O_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "O", "i")
end

path_actions.insert_relpath_i_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "i", "i")
end

path_actions.insert_relpath_I_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "I", "i")
end

path_actions.insert_relpath_a_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "a", "i")
end

path_actions.insert_relpath_A_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "A", "i")
end

path_actions.insert_relpath_o_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "o", "i")
end

path_actions.insert_relpath_O_insert = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "O", "i")
end

-- normal mode mappings
path_actions.insert_abspath_i_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "i", "n")
end

path_actions.insert_abspath_I_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "I", "n")
end

path_actions.insert_abspath_a_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "a", "n")
end

path_actions.insert_abspath_A_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "A", "n")
end

path_actions.insert_abspath_o_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "o", "n")
end

path_actions.insert_abspath_O_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "O", "n")
end

path_actions.insert_relpath_i_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "i", "n")
end

path_actions.insert_relpath_I_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "I", "n")
end

path_actions.insert_relpath_a_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "a", "n")
end

path_actions.insert_relpath_A_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "A", "n")
end

path_actions.insert_relpath_o_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "o", "n")
end

path_actions.insert_relpath_O_normal = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "O", "n")
end

-- visual mode mappings
path_actions.insert_abspath_i_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "i", "v")
end

path_actions.insert_abspath_I_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "I", "v")
end

path_actions.insert_abspath_a_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "a", "v")
end

path_actions.insert_abspath_A_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "A", "v")
end

path_actions.insert_abspath_o_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "o", "v")
end

path_actions.insert_abspath_O_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, false, "O", "v")
end

path_actions.insert_relpath_i_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "i", "v")
end

path_actions.insert_relpath_I_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "I", "v")
end

path_actions.insert_relpath_a_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "a", "v")
end

path_actions.insert_relpath_A_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "A", "v")
end

path_actions.insert_relpath_o_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "o", "v")
end

path_actions.insert_relpath_O_visual = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "O", "v")
end

return path_actions
