local tele_status_ok, _ = pcall(require, "telescope")
if not tele_status_ok then
	return
end

local path_actions = setmetatable({}, {
	__index = function(_, k)
		error("Key does not exist for 'telescope_insert_path': " .. tostring(k))
	end,
})

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

function string.starts(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

function string.ends(String, End)
	return End == "" or string.sub(String, -string.len(End)) == End
end

-- given a file path and a dir, return relative path of the file to a given dir
local function get_relative_path(file, dir)
	local absfile = vim.fn.fnamemodify(file, ":p")
	local absdir = vim.fn.fnamemodify(dir, ":p")

	if string.ends(absdir, "/") then
		absdir = absdir:sub(1, -2)
	else
		error("dir is not a directory")
	end
	local num_parents = 0
	local absolute_path = false
	local searchdir = absdir
	while not string.starts(absfile, searchdir) do
		local searchdir_new = vim.fn.fnamemodify(searchdir, ":h")
		if searchdir_new == searchdir then
			-- reached root directory
			absolute_path = true
			break
		end
		searchdir = searchdir_new
		num_parents = num_parents + 1
	end

	if absolute_path then
		return absfile
	else
		return string.rep("../", num_parents) .. string.sub(absfile, string.len(searchdir) + 2)
	end
end

local function get_path_from_entry(entry, relative)
	local filename
	if relative == "buf" then
		-- path relative to current buffer
		local selection_abspath = entry.path
		local bufpath = vim.fn.expand("%:p")
		local bufdir = vim.fn.fnamemodify(bufpath, ":h")
		filename = get_relative_path(selection_abspath, bufdir)
	elseif relative == "cwd" then
		-- path relative to current working directory
		filename = entry.filename
	else
		-- absolute path
		filename = entry.path
	end
	return filename
end

local function insert_path(prompt_bufnr, relative, location, vim_mode)
	local picker = action_state.get_current_picker(prompt_bufnr)

	actions.close(prompt_bufnr)

	local entry = action_state.get_selected_entry(prompt_bufnr)

	-- local from_entry = require "telescope.from_entry"
	-- local filename = from_entry.path(entry)
	local filename = get_path_from_entry(entry, relative)

	local selections = {}
	for _, selection in ipairs(picker:get_multi_selection()) do
		local selection_filename = get_path_from_entry(selection, relative)

		if selection_filename ~= filename then
			table.insert(selections, selection_filename)
		end
	end

	-- normal mode
	vim.cmd([[stopinsert]])

	local put_after = nil
	if location == "i" then
		put_after = false
	elseif location == "I" then
		vim.cmd([[normal! I]])
		put_after = false
	elseif location == "a" then
		put_after = true
	elseif location == "A" then
		vim.cmd([[normal! $]])
		put_after = true
	elseif location == "o" then
		vim.cmd([[normal! o ]]) -- add empty space so the cursor respects the indent
		vim.cmd([[normal! x]]) -- and immediately delete it
		put_after = true
	elseif location == "O" then
		vim.cmd([[normal! O ]])
		vim.cmd([[normal! x]])
		put_after = true
	end

	local cursor_pos_visual_start = vim.api.nvim_win_get_cursor(0)

	-- if you use nvim_put it's hard to know the range of the new text.
	-- vim.api.nvim_put({ filename }, "", put_after, true)
	local line = vim.api.nvim_get_current_line()
	local new_line
	if put_after then
		local text_before = line:sub(1, cursor_pos_visual_start[2] + 1)
		new_line = text_before .. filename .. line:sub(cursor_pos_visual_start[2] + 2)
		cursor_pos_visual_start[2] = text_before:len()
	else
		local text_before = line:sub(1, cursor_pos_visual_start[2])
		new_line = text_before .. filename .. line:sub(cursor_pos_visual_start[2] + 1)
		cursor_pos_visual_start[2] = text_before:len()
	end
	vim.api.nvim_set_current_line(new_line)

	local cursor_pos_visual_end

	-- put the multi-selections
	if #selections > 0 then
		-- start with empty line
		-- table.insert(selections, 1, "")
		for _, selection in ipairs(selections) do
			vim.cmd([[normal! o ]]) -- add empty space so the cursor respects the indent
			vim.cmd([[normal! x]]) -- and immediately delete it
			vim.api.nvim_put({ selection }, "", true, true)
		end
		cursor_pos_visual_end = vim.api.nvim_win_get_cursor(0)
	else
		cursor_pos_visual_end = { cursor_pos_visual_start[1], cursor_pos_visual_start[2] + filename:len() - 1 }
	end

	if vim_mode == "v" then
		-- There is a weird artefact if we go into visual mode before putting text. #1
		-- So we go into visual mode after putting text.
		vim.api.nvim_win_set_cursor(0, cursor_pos_visual_start)
		vim.cmd([[normal! v]])
		vim.api.nvim_win_set_cursor(0, cursor_pos_visual_end)
	elseif vim_mode == "n" then
		vim.api.nvim_win_set_cursor(0, cursor_pos_visual_end)
	elseif vim_mode == "i" then
		vim.api.nvim_win_set_cursor(0, cursor_pos_visual_end)
		-- append like 'a'
		vim.cmd([[startinsert]])
		vim.cmd([[call cursor( line('.'), col('.') + 1)]])
	end
end

-- insert mode mappings
path_actions.insert_abspath_i_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "i", "i")
end

path_actions.insert_abspath_I_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "I", "i")
end

path_actions.insert_abspath_a_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "a", "i")
end

path_actions.insert_abspath_A_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "A", "i")
end

path_actions.insert_abspath_o_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "o", "i")
end

path_actions.insert_abspath_O_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "O", "i")
end

path_actions.insert_relpath_i_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "i", "i")
end

path_actions.insert_relpath_I_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "I", "i")
end

path_actions.insert_relpath_a_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "a", "i")
end

path_actions.insert_relpath_A_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "A", "i")
end

path_actions.insert_relpath_o_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "o", "i")
end

path_actions.insert_relpath_O_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "O", "i")
end

path_actions.insert_reltobufpath_i_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "i", "i")
end

path_actions.insert_reltobufpath_I_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "I", "i")
end

path_actions.insert_reltobufpath_a_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "a", "i")
end

path_actions.insert_reltobufpath_A_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "A", "i")
end

path_actions.insert_reltobufpath_o_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "o", "i")
end

path_actions.insert_reltobufpath_O_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "O", "i")
end

-- normal mode mappings
path_actions.insert_abspath_i_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "i", "n")
end

path_actions.insert_abspath_I_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "I", "n")
end

path_actions.insert_abspath_a_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "a", "n")
end

path_actions.insert_abspath_A_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "A", "n")
end

path_actions.insert_abspath_o_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "o", "n")
end

path_actions.insert_abspath_O_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "O", "n")
end

path_actions.insert_relpath_i_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "i", "n")
end

path_actions.insert_relpath_I_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "I", "n")
end

path_actions.insert_relpath_a_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "a", "n")
end

path_actions.insert_relpath_A_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "A", "n")
end

path_actions.insert_relpath_o_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "o", "n")
end

path_actions.insert_relpath_O_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "O", "n")
end

path_actions.insert_reltobufpath_i_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "i", "n")
end

path_actions.insert_reltobufpath_I_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "I", "n")
end

path_actions.insert_reltobufpath_a_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "a", "n")
end

path_actions.insert_reltobufpath_A_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "A", "n")
end

path_actions.insert_reltobufpath_o_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "o", "n")
end

path_actions.insert_reltobufpath_O_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "O", "n")
end

-- visual mode mappings
path_actions.insert_abspath_i_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "i", "v")
end

path_actions.insert_abspath_I_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "I", "v")
end

path_actions.insert_abspath_a_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "a", "v")
end

path_actions.insert_abspath_A_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "A", "v")
end

path_actions.insert_abspath_o_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "o", "v")
end

path_actions.insert_abspath_O_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", "O", "v")
end

path_actions.insert_relpath_i_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "i", "v")
end

path_actions.insert_relpath_I_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "I", "v")
end

path_actions.insert_relpath_a_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "a", "v")
end

path_actions.insert_relpath_A_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "A", "v")
end

path_actions.insert_relpath_o_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "o", "v")
end

path_actions.insert_relpath_O_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", "O", "v")
end

path_actions.insert_reltobufpath_i_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "i", "v")
end

path_actions.insert_reltobufpath_I_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "I", "v")
end

path_actions.insert_reltobufpath_a_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "a", "v")
end

path_actions.insert_reltobufpath_A_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "A", "v")
end

path_actions.insert_reltobufpath_o_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "o", "v")
end

path_actions.insert_reltobufpath_O_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", "O", "v")
end

return path_actions
