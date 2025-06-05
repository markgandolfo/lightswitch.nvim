local Popup = require("nui.popup")
local Layout = require("nui.layout")
local event = require("nui.utils.autocmd").event

local lightswitch = {}
lightswitch.toggles = {}
lightswitch.win = nil
lightswitch.input = nil
lightswitch.layout = nil
lightswitch.filter = ""
lightswitch.selected_idx = 1

-- Constants for toggle display
local TOGGLE_ON = "[───⦿ ]"
local TOGGLE_OFF = "[⦾────]"

-- Add a toggle option to the lightswitch
function lightswitch.add_toggle(name, enable_cmd, disable_cmd, state)
	table.insert(lightswitch.toggles, {
		name = name,
		enable_cmd = enable_cmd,
		disable_cmd = disable_cmd,
		state = state or false,
	})
end

-- Execute toggle command based on cursor position
function lightswitch.execute_toggle()
	if not lightswitch.win or not lightswitch.win.winid then
		return
	end

	-- Get current cursor position
	local cursor = vim.api.nvim_win_get_cursor(lightswitch.win.winid)
	local line = cursor[1]

	-- Get filtered toggles
	local filtered_toggles = lightswitch.filter_toggles()

	-- Ensure line is within bounds
	if line < 1 or line > #filtered_toggles then
		return
	end

	-- Find the original toggle index
	local toggle_name = filtered_toggles[line].name
	local orig_idx = -1

	for i, toggle in ipairs(lightswitch.toggles) do
		if toggle.name == toggle_name then
			orig_idx = i
			break
		end
	end

	if orig_idx > 0 then
		-- Toggle the state
		local toggle = lightswitch.toggles[orig_idx]
		toggle.state = not toggle.state
		local cmd = toggle.state and toggle.enable_cmd or toggle.disable_cmd

		-- Execute the command based on its type
		if cmd then
			if cmd:match("^require%s*%(") or cmd:match("^vim%.") then
				-- It's a Lua expression
				local success, err = pcall(loadstring(cmd))
				if not success then
					vim.notify("Error executing Lua: " .. tostring(err), vim.log.levels.ERROR)
				end
			elseif cmd:match("<CR>") then
				-- It's a command with key notation
				local keys = vim.api.nvim_replace_termcodes(cmd, true, true, true)
				vim.api.nvim_feedkeys(keys, "n", false)
			else
				-- It's a regular Ex command
				vim.cmd(cmd)
			end
		else
			vim.notify("No command defined for this state", vim.log.levels.WARN)
		end

		lightswitch.refresh()
	end
end

-- Filter toggles based on search term
function lightswitch.filter_toggles()
	if lightswitch.filter == "" then
		return lightswitch.toggles
	end

	local filtered = {}
	for _, toggle in ipairs(lightswitch.toggles) do
		if string.find(string.lower(toggle.name), string.lower(lightswitch.filter)) then
			table.insert(filtered, toggle)
		end
	end
	return filtered
end

-- Refresh the UI display
function lightswitch.refresh()
	if not lightswitch.win or not lightswitch.win.bufnr then
		return
	end

	local filtered_toggles = lightswitch.filter_toggles()
	local lines = {}

	-- Create display lines with toggles but no selection arrows
	for _, toggle in ipairs(filtered_toggles) do
		local toggle_indicator = toggle.state and TOGGLE_ON or TOGGLE_OFF
		local name_padded = toggle.name .. string.rep(" ", 12 - #toggle.name)
		table.insert(lines, string.format("%s  %s", toggle_indicator, name_padded))
	end

	-- Update buffer content
	vim.api.nvim_buf_set_lines(lightswitch.win.bufnr, 0, -1, false, lines)

	-- Ensure cursor stays within bounds after filtering
	if lightswitch.win.winid and vim.api.nvim_win_is_valid(lightswitch.win.winid) then
		local cursor = vim.api.nvim_win_get_cursor(lightswitch.win.winid)
		local row = math.min(cursor[1], #lines)
		if row < 1 and #lines > 0 then
			row = 1
		end
		if row > 0 then -- Only set cursor if there are lines
			vim.api.nvim_win_set_cursor(lightswitch.win.winid, { row, cursor[2] })
		end
	end

	-- Set search text line
	if lightswitch.input and lightswitch.input.bufnr then
		vim.api.nvim_buf_set_lines(lightswitch.input.bufnr, 0, -1, false, { "Search: " .. lightswitch.filter })
	end
end

-- Show the lightswitch UI
function lightswitch.show()
	if lightswitch.layout then
		lightswitch.layout:unmount()
		lightswitch.layout = nil
	end

	-- Reset filter when opening
	lightswitch.filter = ""

	-- Calculate height based on number of toggles (min 5, max 15)
	local num_toggles = #lightswitch.toggles
	local content_height = math.min(math.max(num_toggles, 5), 15) + 5

	-- Create the main popup window
	lightswitch.win = Popup({
		border = {
			style = "rounded",
			text = {
				top = " LightSwitch ",
				top_align = "center",
			},
		},
		position = "50%",
		size = {
			width = 40,
			height = content_height,
		},
		buf_options = {
			modifiable = true,
			readonly = false,
		},
		win_options = {
			winblend = 10,
			winhighlight = "Normal:Normal",
			cursorline = true, -- Highlight the current line
		},
	})

	-- Create the search input popup
	lightswitch.input = Popup({
		border = {
			style = "rounded",
			text = {
				top = "",
				top_align = "center",
			},
		},
		position = "50%",
		size = {
			width = 40,
			height = 1,
		},
		buf_options = {
			modifiable = true,
			readonly = false,
		},
		win_options = {
			winblend = 10,
			winhighlight = "Normal:Normal",
		},
	})

	-- Set up the layout
	lightswitch.layout = Layout(
		{
			position = "50%",
			size = {
				width = 42,
				height = content_height + 5, -- +5 for padding and search
			},
		},
		Layout.Box({
			Layout.Box(lightswitch.win, { size = content_height }),
			Layout.Box(lightswitch.input, { size = 3 }),
		}, { dir = "col" })
	)

	-- Mount the layout
	lightswitch.layout:mount()

	-- Update UI with toggles
	lightswitch.refresh()

	-- Use Neovim's native j/k for navigation with cursor highlighting
	-- Toggle with <CR> or <Space>
	lightswitch.win:map("n", "<CR>", function()
		lightswitch.execute_toggle()
	end)

	lightswitch.win:map("n", "<Space>", function()
		lightswitch.execute_toggle()
	end)

	lightswitch.win:map("n", "q", function()
		lightswitch.layout:unmount()
		lightswitch.layout = nil
	end)

	lightswitch.win:map("n", "<Esc>", function()
		lightswitch.layout:unmount()
		lightswitch.layout = nil
	end)

	-- Set up search functionality
	lightswitch.win:map("n", "/", function()
		vim.api.nvim_set_current_win(lightswitch.input.winid)
		vim.api.nvim_buf_set_lines(lightswitch.input.bufnr, 0, -1, false, { "Search: " })
		vim.api.nvim_win_set_cursor(lightswitch.input.winid, { 1, 8 }) -- Position after "Search: "
		vim.cmd("startinsert!")
	end)

	lightswitch.input:map("i", "<CR>", function()
		local search_line = vim.api.nvim_buf_get_lines(lightswitch.input.bufnr, 0, 1, false)[1]
		lightswitch.filter = string.sub(search_line, 9) -- Remove "Search: " prefix
		lightswitch.refresh()

		-- Return focus to the main window
		vim.api.nvim_set_current_win(lightswitch.win.winid)
		vim.cmd("stopinsert")
	end)

	lightswitch.input:map("i", "<Esc>", function()
		-- Clear search on escape
		lightswitch.filter = ""
		lightswitch.refresh()
		vim.api.nvim_set_current_win(lightswitch.win.winid)
		vim.cmd("stopinsert")
	end)

	-- Prevent backspace from deleting "Search: " prefix
	lightswitch.input:map("i", "<BS>", function()
		local cursor = vim.api.nvim_win_get_cursor(lightswitch.input.winid)
		if cursor[2] <= 8 then
			-- Don't allow backspace at or before position 8
			return ""
		else
			-- Allow normal backspace
			return vim.api.nvim_replace_termcodes("<BS>", true, true, true)
		end
	end, { expr = true })

	-- Add autocmd for real-time search
	vim.api.nvim_create_autocmd({ "TextChangedI" }, {
		buffer = lightswitch.input.bufnr,
		callback = function()
			local search_line = vim.api.nvim_buf_get_lines(lightswitch.input.bufnr, 0, 1, false)[1]
			if search_line then
				-- Ensure "Search: " prefix is maintained
				if not search_line:match("^Search: ") then
					vim.api.nvim_buf_set_lines(lightswitch.input.bufnr, 0, 1, false, { "Search: " })
					vim.api.nvim_win_set_cursor(lightswitch.input.winid, { 1, 8 })
				else
					lightswitch.filter = string.sub(search_line, 9) -- Remove "Search: " prefix
					lightswitch.refresh()
				end
			end
		end,
	})

	-- Prevent cursor from moving before "Search: "
	vim.api.nvim_create_autocmd({ "CursorMovedI" }, {
		buffer = lightswitch.input.bufnr,
		callback = function()
			local cursor = vim.api.nvim_win_get_cursor(lightswitch.input.winid)
			if cursor[2] < 8 then
				vim.api.nvim_win_set_cursor(lightswitch.input.winid, { 1, 8 })
			end
		end,
	})

	-- Set initial focus and cursor position
	vim.api.nvim_set_current_win(lightswitch.win.winid)
	vim.api.nvim_win_set_cursor(lightswitch.win.winid, { 1, 0 }) -- Start at first item
end

-- Initialize with some default toggles
function lightswitch.setup(opts)
	opts = opts or {}
	lightswitch.toggles = {}

	-- Add default toggles if no options provided
	if not opts.toggles or #opts.toggles == 0 then
		lightswitch.add_toggle("Copilot", "Copilot enable", "Copilot disable", "Copilot status")
	else
		for _, toggle in ipairs(opts.toggles) do
			lightswitch.add_toggle(toggle.name, toggle.enable_cmd, toggle.disable_cmd, toggle.state)
		end
	end
end

-- Create the command
vim.api.nvim_create_user_command("LightSwitchShow", function()
	lightswitch.show()
end, {})

return lightswitch
