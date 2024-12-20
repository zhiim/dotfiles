-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- Changing the color scheme:
config.color_scheme = 'OneDark (base16)'
config.use_fancy_tab_bar = false

-- Diable system title bar, and put window management buttons into tab bar
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'

-- Set widows size at starup
config.initial_rows = 30
config.initial_cols = 120

config.font = wezterm.font_with_fallback {
  { family = 'JetBrains Mono', weight = 'Medium' },
  { family = '思源黑体', weight = 'Medium' },
}

-- disable ligatures
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

-- use WSL by default
-- config.default_domain = "WSL:openSUSE-Tumbleweed"

-- Default launching Programs
-- config.default_prog = { "pwsh.exe", "-nol" }
-- config.default_prog = { "D:\\msys2\\usr\\bin\\fish.exe", "-i", "-l" }

-- config.launch_menu = {
-- 	{
-- 		label = "PowerShell",
-- 		args = { "pwsh.exe", "-nol" },
-- 		domain = { DomainName = "local" },
-- 	},
-- 	{
-- 		label = "Fish",
-- 		args = { "D:\\msys2\\usr\\bin\\fish.exe", "-i", "-l" },
-- 		domain = { DomainName = "local" },
-- 	},
-- }

-- How many lines of scrollback you want to retain per tab
config.scrollback_lines = 3500

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == 'true'
end
local function is_ssh(pane)
  local process_name =
    string.gsub(pane:get_foreground_process_name(), '(.*[/\\])(.*)', '%2')
  return process_name == 'ssh' or process_name == 'ssh.exe'
end

local direction_keys = {
  h = 'Left',
  j = 'Down',
  k = 'Up',
  l = 'Right',
}

local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == 'resize' and 'META' or 'CTRL',
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = {
            key = key,
            mods = resize_or_move == 'resize' and 'META' or 'CTRL',
          },
        }, pane)
      elseif is_ssh(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = {
            key = key,
            mods = resize_or_move == 'resize' and 'META' or 'CTRL',
          },
        }, pane)
      else
        if resize_or_move == 'resize' then
          win:perform_action(
            { AdjustPaneSize = { direction_keys[key], 3 } },
            pane
          )
        else
          win:perform_action(
            { ActivatePaneDirection = direction_keys[key] },
            pane
          )
        end
      end
    end),
  }
end

config.leader = { key = 'b', mods = 'ALT', timeout_milliseconds = 1000 }
config.keys = {
  {
    key = '[',
    mods = 'LEADER',
    action = wezterm.action.ActivateCopyMode,
  },
  {
    key = 'l',
    mods = 'LEADER',
    action = wezterm.action.ShowLauncher,
  },
  -- Create a new tab in the same domain as the current pane.
  {
    key = 'c',
    mods = 'LEADER',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  -- Close a tab.
  {
    key = 'X',
    mods = 'LEADER',
    action = wezterm.action.CloseCurrentTab { confirm = true },
  },
  -- Close a pane.
  {
    key = 'x',
    mods = 'LEADER',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  -- active next tab
  {
    key = 'n',
    mods = 'LEADER',
    action = wezterm.action.ActivateTabRelative(1),
  },
  -- active previous tab
  {
    key = 'p',
    mods = 'LEADER',
    action = wezterm.action.ActivateTabRelative(-1),
  },
  -- splitting pane vertically
  {
    mods = 'LEADER',
    key = '=',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- splitting pane horizontally
  {
    mods = 'LEADER',
    key = '-',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  split_nav('move', 'h'),
  split_nav('move', 'j'),
  split_nav('move', 'k'),
  split_nav('move', 'l'),
  -- resize panes
  split_nav('resize', 'h'),
  split_nav('resize', 'j'),
  split_nav('resize', 'k'),
  split_nav('resize', 'l'),
}

-- and finally, return the configuration to wezterm
return config
