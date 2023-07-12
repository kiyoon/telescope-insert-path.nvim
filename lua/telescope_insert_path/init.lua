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

-- returns the git root of the project or the cwd
local function get_git_root()
    local handler = io.popen('git rev-parse --show-toplevel')

    if not handler then return nil end

    local output = handler:read('*a')
    local ret = handler:close()

    if ret then return trim(output) else return vim.fn.getcwd() end
end

local function get_git_root_or_cwd()
    local root = get_git_root()
    
    if not root then
        return vim.fn.getcwd()
    end

    return root
end

-- given a file path and a dir, return relative path of the file to a given dir
local function get_relative_path(file, dir)
	local absfile = vim.fn.fnamemodify(file, ":p")
	local absdir = vim.fn.fnamemodify(dir, ":p")

	if string.ends(absdir, "/") then
		absdir = absdir:sub(1, -2)
	else
		error("dir (" .. dir .. ") is not a directory")
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
    elseif relative == "git" then
        local git_root = get_git_root()

        if not git_root then
            error("can't get git root")
        end

        filename = get_relative_path(entry.path, git_root)
    elseif relative == "source" then
        filename = get_relative_path(entry.path, path_actions.source_dir)
	else
		-- absolute path
		filename = entry.path
	end
	return filename
end

local function insert_path(prompt_bufnr, relative, location, vim_mode)
	if
		location ~= "i"
		and location ~= "I"
		and location ~= "a"
		and location ~= "A"
		and location ~= "o"
		and location ~= "O"
	then
		location = vim.fn.nr2char(vim.fn.getchar())
		if
			location ~= "i"
			and location ~= "I"
			and location ~= "a"
			and location ~= "A"
			and location ~= "o"
			and location ~= "O"
		then
			-- escape
			return nil
		end
	end

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

--- Check if a file or directory exists in this path
local function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

--- Check if a directory exists in this path
local function isdir(path)
   -- "/" works on both Unix and Windows
   return exists(path.."/")
end

local function get_default_source_dir()
    local source = ''

    if vim.g.telescope_insert_path_source_dir then
        source = get_git_root_or_cwd() .. "/" .. vim.g.telescope_insert_path_source_dir
    else
        source = get_git_root_or_cwd()
    end

    if isdir(source) then
        return source
    else
        return get_git_root_or_cwd()
    end
end

-- source_dir
path_actions.set_source_dir = function(dir)
    if dir then
        path_actions.source_dir = dir
    else
        local root = get_git_root()

        if not root then root = vim.fn.getcwd() end

        path_actions.source_dir = root .. '/' .. vim.fn.input("insert source directory: " .. root .. "/", "", "dir")
    end
end

path_actions.source_dir = get_default_source_dir()

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

path_actions.insert_relgit_I_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "I", "i")
end

path_actions.insert_relgit_a_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "a", "i")
end

path_actions.insert_relgit_A_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "A", "i")
end

path_actions.insert_relgit_o_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "o", "i")
end

path_actions.insert_relgit_O_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "O", "i")
end

path_actions.insert_relsource_i_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "i", "i")
end

path_actions.insert_relsource_I_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "I", "i")
end

path_actions.insert_relsource_a_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "a", "i")
end

path_actions.insert_relsource_A_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "A", "i")
end

path_actions.insert_relsource_o_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "o", "i")
end

path_actions.insert_relsource_O_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "O", "i")
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

path_actions.insert_relgit_i_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "i", "n")
end

path_actions.insert_relgit_I_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "I", "n")
end

path_actions.insert_relgit_a_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "a", "n")
end

path_actions.insert_relgit_A_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "A", "n")
end

path_actions.insert_relgit_o_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "o", "n")
end

path_actions.insert_relgit_O_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "O", "n")
end

path_actions.insert_relsource_i_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "i", "n")
end

path_actions.insert_relsource_I_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "I", "n")
end

path_actions.insert_relsource_a_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "a", "n")
end

path_actions.insert_relsource_A_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "A", "n")
end

path_actions.insert_relsource_o_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "o", "n")
end

path_actions.insert_relsource_O_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "O", "n")
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

path_actions.insert_relgit_i_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "i", "v")
end

path_actions.insert_relgit_I_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "I", "v")
end

path_actions.insert_relgit_a_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "a", "v")
end

path_actions.insert_relgit_A_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "A", "v")
end

path_actions.insert_relgit_o_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "o", "v")
end

path_actions.insert_relgit_O_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "git", "O", "v")
end

path_actions.insert_relsource_i_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "i", "v")
end

path_actions.insert_relsource_I_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "I", "v")
end

path_actions.insert_relsource_a_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "a", "v")
end

path_actions.insert_relsource_A_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "A", "v")
end

path_actions.insert_relsource_o_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "o", "v")
end

path_actions.insert_relsource_O_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "source", "O", "v")
end

-- Generic actions
-- Get location input from the user (i, I, a, A, o, O)
path_actions.insert_reltobufpath_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", nil, "v")
end

path_actions.insert_relpath_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", nil, "v")
end

path_actions.insert_abspath_visual = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", nil, "v")
end

path_actions.insert_reltobufpath_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", nil, "n")
end

path_actions.insert_relpath_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", nil, "n")
end

path_actions.insert_abspath_normal = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", nil, "n")
end

path_actions.insert_reltobufpath_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "buf", nil, "i")
end

path_actions.insert_relpath_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "cwd", nil, "i")
end

path_actions.insert_abspath_insert = function(prompt_bufnr)
	return insert_path(prompt_bufnr, "abs", nil, "i")
end

return path_actions
