local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

local smart_nav = require('smart-split').smart_nav

local mouse_bindings = {
  -- disable copy on selection
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.Nop,
  },
  -- copy and paste with right click
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action_callback(function(window, pane)
      ---@diagnostic disable-next-line: redundant-parameter
      local has_selection = (window:get_selection_text_for_pane(pane) ~= '')
      if has_selection then
        window:perform_action(
          wezterm.action.CopyTo 'ClipboardAndPrimarySelection',
          pane
        )
        ---@diagnostic disable-next-line: param-type-mismatch
        window:perform_action(wezterm.action.ClearSelection, pane)
      else
        window:perform_action(wezterm.action { PasteFrom = 'Clipboard' }, pane)
      end
    end),
  },
}

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

for i = 1, 9 do
  -- CTRL+ALT + number to activate that tab
  table.insert(keys, {
    key = tostring(i),
    mods = 'LEADER',
    action = wezterm.action.ActivateTab(i - 1),
  })
end

function M.apply(config)
  config.leader = { key = 'b', mods = 'ALT', timeout_milliseconds = 1000 }
  config.keys = keys
  config.mouse_bindings = mouse_bindings
end

return M
