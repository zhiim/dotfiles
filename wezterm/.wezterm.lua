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

-- Diable system title bar, and put window management buttons into tab bar
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- Set widows size at starup
config.initial_rows = 30
config.initial_cols = 120

config.font = wezterm.font("JetBrains Mono", { weight = "Bold" })

-- Default launching Programs
-- config.default_prog = { "pwsh.exe" }

-- How many lines of scrollback you want to retain per tab
config.scrollback_lines = 3500

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
				}, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

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
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	-- resize panes
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),
	-- {
	-- 	key = "l",
	-- 	mods = "LEADER",
	-- 	action = wezterm.action.ActivatePaneDirection("Right"),
	-- },
	-- {
	-- 	key = "h",
	-- 	mods = "LEADER",
	-- 	action = wezterm.action.ActivatePaneDirection("Left"),
	-- },
	-- {
	-- 	key = "j",
	-- 	mods = "LEADER",
	-- 	action = wezterm.action.ActivatePaneDirection("Down"),
	-- },
	-- {
	-- 	key = "k",
	-- 	mods = "LEADER",
	-- 	action = wezterm.action.ActivatePaneDirection("Up"),
	-- },
}

-- and finally, return the configuration to wezterm
return config
