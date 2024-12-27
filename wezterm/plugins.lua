local wezterm = require 'wezterm' --[[@as Wezterm]]
local resurrect =
  wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'
local workspace_switcher =
  wezterm.plugin.require 'https://github.com/MLFlexer/smart_workspace_switcher.wezterm'

local M = {}

local keys = {
  -- write current state
  {
    key = 'w',
    mods = 'LEADER',
    action = wezterm.action_callback(function(win, pane)
      resurrect.save_state(resurrect.workspace_state.get_workspace_state())
    end),
  },
  -- read saved state
  {
    key = 'r',
    mods = 'LEADER',
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_load(win, pane, function(id, label)
        local type = string.match(id, '^([^/]+)') -- match before '/'
        id = string.match(id, '([^/]+)$') -- match after '/'
        id = string.match(id, '(.+)%..+$') -- remove file extention
        local opts = {
          relative = true,
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        }
        if type == 'workspace' then
          local state = resurrect.load_state(id, 'workspace')
          resurrect.workspace_state.restore_workspace(state, opts)
        elseif type == 'window' then
          local state = resurrect.load_state(id, 'window')
          resurrect.window_state.restore_window(pane:window(), state, opts)
        elseif type == 'tab' then
          local state = resurrect.load_state(id, 'tab')
          resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        end
      end)
    end),
  },
  -- switch workspace
  {
    key = 's',
    mods = 'LEADER',
    action = workspace_switcher.switch_workspace(),
  },
}

function M.apply(config)
  for _, key in ipairs(keys) do
    table.insert(config.keys, key)
  end
end

return M
