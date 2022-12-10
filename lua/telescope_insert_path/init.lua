local tele_status_ok, telescope = pcall(require, "telescope")
if not tele_status_ok then
	return
end

local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local insert_path = function(prompt_bufnr, close, location, vim_mode)
  if close then
    actions.close(prompt_bufnr)
  end

  -- TODO: get all selections by using
  -- local picker = action_state.get_current_picker(prompt_bufnr)
  --print(vim.inspect(picker._multi._entries))
  --print(vim.inspect(picker._selection_entry))
  local entry = action_state.get_selected_entry(prompt_bufnr)
  local filename = entry.value
  -- fnamemodify with :p appends a trailing slash to directories
  local filepath = vim.fn.fnamemodify(entry.cwd, ':p') .. filename

  if location ~= nil then
    vim.cmd([[normal! ]] .. location)
  end

  vim.api.nvim_put({ filepath }, "", true, true)

  if vim_mode == "n" then
    vim.cmd [[stopinsert]]
  elseif vim_mode == "i" then
    vim.cmd [[startinsert!]]  -- put the cursor after the inserted text (!)
  else
    -- unchanged
  end
end

local insert_path_i = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "i", nil)
end

local insert_path_I = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "I", nil)
end

local insert_path_a = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "a", nil)
end

local insert_path_A = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "A", nil)
end

local insert_path_o = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "o", nil)
end

local insert_path_O = function(prompt_bufnr)
  return insert_path(prompt_bufnr, true, "O", nil)
end
