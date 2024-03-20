-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- Changing the color scheme:
config.color_scheme = "OneDark (base16)"

-- Default launching Programs
-- config.default_prog = { "pwsh.exe" }

-- How many lines of scrollback you want to retain per tab
config.scrollback_lines = 3500

config.leader = { key = "b", mods = "ALT", timeout_milliseconds = 1000 }
config.keys = {
	{
		key = "l",
		mods = "ALT",
		action = wezterm.action.ShowLauncher,
	},
	-- Create a new tab in the same domain as the current pane.
	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
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
		mods = "LEADER",
		key = "=",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	-- splitting pane horizontally
	{
		mods = "LEADER",
		key = "-",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "l",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	{
		key = "h",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
}

-- and finally, return the configuration to wezterm
return config
