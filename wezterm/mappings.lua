local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

local smart_nav = require('smart-split').smart_nav

local keys = {
  {
    key = '[',
    mods = 'LEADER',
    action = wezterm.action.ActivateCopyMode,
  },
  {
    key = 'l',
    mods = 'LEADER',
    action = wezterm.action.ShowLauncherArgs {
      flags = 'FUZZY|LAUNCH_MENU_ITEMS|DOMAINS',
    },
  },

  -- ━━ TABS AND PANES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
    key = '=',
    mods = 'LEADER',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- splitting pane horizontally
  {
    key = '-',
    mods = 'LEADER',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  smart_nav('move', 'h'),
  smart_nav('move', 'j'),
  smart_nav('move', 'k'),
  smart_nav('move', 'l'),
  smart_nav('resize', 'h'),
  smart_nav('resize', 'j'),
  smart_nav('resize', 'k'),
  smart_nav('resize', 'l'),
}

function M.apply(config)
  config.leader = { key = 'b', mods = 'ALT', timeout_milliseconds = 1000 }
  config.keys = keys
end

return M
