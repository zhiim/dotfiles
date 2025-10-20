local wezterm = require("wezterm") --[[@as Wezterm]]

local M = {}

local toggle_file = wezterm.config_dir .. "/wezterm_toggle"

local function read_toggle()
	local f = io.open(toggle_file, "r")
	-- if no file exists, create it with default value false
	if not f then
		local wf = io.open(toggle_file, "w")
		if wf then
			wf:write("false")
			wf:close()
		end
	end
	-- read the value from the file
	if f then
		local v = f:read("*l")
		f:close()
		return v == "true"
	end
	return false
end

local function write_toggle(value)
	local f = io.open(toggle_file, "w")
	if f then
		f:write(value and "true" or "false")
		f:close()
	end
end

local my_toggle = read_toggle() -- toggle keybindings on/off, to work with tmux/ssh

wezterm.on("toggle-my-toggle", function(window, pane)
	my_toggle = not my_toggle
	write_toggle(my_toggle)
	if my_toggle then
		window:toast_notification("Keybindings Toggle", "keybindings are disabled", nil, 4000)
	else
		window:toast_notification("Keybindings Toggle", "keybindings are enabled", nil, 4000)
	end
	window:perform_action(wezterm.action.ReloadConfiguration, pane)
end)

local smart_nav = require("smart-split").smart_nav

local mouse_bindings = {
	-- disable copy on selection
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.Nop,
	},
	-- copy and paste with right click
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			---@diagnostic disable-next-line: redundant-parameter
			local has_selection = (window:get_selection_text_for_pane(pane) ~= "")
			if has_selection then
				window:perform_action(wezterm.action.CopyTo("ClipboardAndPrimarySelection"), pane)
				---@diagnostic disable-next-line: param-type-mismatch
				window:perform_action(wezterm.action.ClearSelection, pane)
			else
				window:perform_action(wezterm.action({ PasteFrom = "Clipboard" }), pane)
			end
		end),
	},
}

local keys = {
	{
		key = "[",
		mods = "LEADER",
		action = wezterm.action.ActivateCopyMode,
	},
	{
		key = "l",
		mods = "LEADER",
		action = wezterm.action.ShowLauncherArgs({
			flags = "FUZZY|LAUNCH_MENU_ITEMS|DOMAINS",
		}),
	},

	-- ━━ TABS AND PANES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	-- Create a new tab in the same domain as the current pane.
	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	-- Close a tab.
	{
		key = "X",
		mods = "LEADER",
		action = wezterm.action.CloseCurrentTab({ confirm = true }),
	},
	-- Close a pane.
	{
		key = "x",
		mods = "LEADER",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	-- active next tab
	{
		key = "n",
		mods = "LEADER",
		action = wezterm.action.ActivateTabRelative(1),
	},
	-- active previous tab
	{
		key = "p",
		mods = "LEADER",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	-- splitting pane vertically
	{
		key = "=",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	-- splitting pane horizontally
	{
		key = "-",
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	smart_nav("move", "h"),
	smart_nav("move", "j"),
	smart_nav("move", "k"),
	smart_nav("move", "l"),
	smart_nav("resize", "h"),
	smart_nav("resize", "j"),
	smart_nav("resize", "k"),
	smart_nav("resize", "l"),
}

for i = 1, 9 do
	-- CTRL+ALT + number to activate that tab
	table.insert(keys, {
		key = tostring(i),
		mods = "LEADER",
		action = wezterm.action.ActivateTab(i - 1),
	})
end

function M.apply(config)
	if not my_toggle then
		config.leader = { key = "b", mods = "ALT", timeout_milliseconds = 1000 }
		config.keys = keys
		config.mouse_bindings = mouse_bindings
	else
		config.keys = {}
	end
	table.insert(config.keys, {
		key = "t",
		mods = "CTRL|ALT",
		action = wezterm.action.EmitEvent("toggle-my-toggle"),
	})
end

return M
