local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

local leader_table = 'leader'

local function toggle_key(tab_id)
  return 'keybindings_disabled_tab_' .. tab_id
end

function M.is_tab_locked(tab_id)
  return wezterm.GLOBAL[toggle_key(tab_id)] == true
end

function M.read_toggle(window)
  return M.is_tab_locked(window:active_tab():tab_id())
end

local function leader_owner_key(window)
  return 'keybindings_leader_window_' .. window:window_id()
end

wezterm.on('toggle-my-toggle', function(window, pane)
  local locked = not M.read_toggle(window)
  wezterm.GLOBAL[toggle_key(window:active_tab():tab_id())] = locked or nil
  -- Do not leave a pending leader or copy/search mode intercepting input.
  local active_table = window:active_key_table()
  if active_table == 'copy_mode' or active_table == 'search_mode' then
    window:perform_action(wezterm.action.CopyMode 'Close', pane)
  end
  window:perform_action(wezterm.action.ClearKeyTableStack, pane)
end)

local function is_tab_navigation(action)
  return action == 'ActivateLastTab'
    or (type(action) == 'table'
      and (action.ActivateTab ~= nil or action.ActivateTabRelative ~= nil))
end

local function guarded_binding(binding, allow_locked)
  local allowed = allow_locked or is_tab_navigation(binding.action)
  return {
    key = binding.key,
    mods = binding.mods,
    action = wezterm.action_callback(function(window, pane)
      local action = binding.action
      if M.read_toggle(window) and not allowed then
        action = wezterm.action.SendKey {
          key = binding.key,
          mods = binding.mods,
        }
      end
      window:perform_action(action, pane)
    end),
  }
end

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
  -- Slower scroll up/down (3 lines instead of Page Up/Down)
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = 'NONE',
    action = wezterm.action.ScrollByLine(-3),
    alt_screen = false,
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = 'NONE',
    action = wezterm.action.ScrollByLine(3),
    alt_screen = false,
  },
}

local keys = {
  {
    key = '[',
    mods = 'LEADER',
    action = wezterm.action.ActivateCopyMode,
  },
  {
    key = ']',
    mods = 'LEADER',
    action = wezterm.action.Search { CaseInSensitiveString = '' },
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
  -- Only tab navigation bypasses the lock; other shortcuts go to tmux/ssh.
  config.disable_default_key_bindings = true
  config.keys = {}
  config.key_tables = {}
  local normal_actions = {}
  local function add_binding(binding, allow_locked)
    local guarded = guarded_binding(binding, allow_locked)
    table.insert(config.keys, guarded)
    normal_actions[binding.key .. '|' .. binding.mods] = guarded.action
  end

  for _, binding in ipairs(wezterm.gui.default_keys()) do
    add_binding(binding)
  end
  for _, binding in ipairs(keys) do
    if binding.mods ~= 'LEADER' then
      add_binding(binding)
    end
  end

  -- Keep Alt+b available in locked tabs for n/p/1-9; each following action
  -- still checks the lock, so creating/closing/splitting tabs stays disabled.
  config.leader = nil
  add_binding({
    key = 'b',
    mods = 'ALT',
    action = wezterm.action_callback(function(window, pane)
      wezterm.GLOBAL[leader_owner_key(window)] = window:active_tab():tab_id()
      window:perform_action(
        wezterm.action.ActivateKeyTable {
          name = leader_table,
          one_shot = true,
          timeout_milliseconds = 1000,
        },
        pane
      )
    end),
  }, true)

  local toggle_binding = {
    key = '0',
    mods = 'CTRL',
    action = wezterm.action.EmitEvent 'toggle-my-toggle',
  }
  table.insert(config.keys, toggle_binding)
  normal_actions['0|CTRL'] = toggle_binding.action

  local leader_keys = { toggle_binding }
  for _, binding in ipairs(keys) do
    if binding.mods == 'LEADER' then
      local guarded = guarded_binding {
        key = binding.key,
        mods = 'NONE',
        action = binding.action,
      }
      table.insert(leader_keys, {
        key = guarded.key,
        mods = guarded.mods,
        action = wezterm.action_callback(function(window, pane)
          local action = guarded.action
          -- A mouse tab switch must not carry a pending leader to another tab.
          if wezterm.GLOBAL[leader_owner_key(window)]
            ~= window:active_tab():tab_id()
          then
            action = normal_actions[guarded.key .. '|' .. guarded.mods]
              or wezterm.action.SendKey {
                key = guarded.key,
                mods = guarded.mods,
              }
          end
          window:perform_action(action, pane)
        end),
      })
    end
  end
  config.key_tables[leader_table] = leader_keys

  for name, bindings in pairs(wezterm.gui.default_key_tables()) do
    local guarded = {}
    for _, binding in ipairs(bindings) do
      table.insert(guarded, guarded_binding(binding))
    end
    table.insert(guarded, toggle_binding)
    config.key_tables[name] = guarded
  end
  config.mouse_bindings = mouse_bindings
end

return M
