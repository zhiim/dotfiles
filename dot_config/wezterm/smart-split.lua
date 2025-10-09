local wezterm = require 'wezterm' --[[@as Wezterm]]
local action = wezterm.action

local M = {}

local direction_keys = {
  h = 'Left',
  j = 'Down',
  k = 'Up',
  l = 'Right',
}

local function is_vim(pane)
  return pane:get_user_vars().IS_NVIM == 'true'
end
local function is_ssh(pane)
  local domain_name = pane:get_domain_name()
  if string.match(domain_name, '^SSH') then
    return true
  end
  return false
end

function M.smart_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == 'resize' and 'META' or 'CTRL',
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) or is_ssh(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action(
          action.SendKey {
            key = key,
            mods = resize_or_move == 'resize' and 'META' or 'CTRL',
          },
          pane
        )
      else
        if resize_or_move == 'resize' then
          win:perform_action(
            action.AdjustPaneSize { direction_keys[key], 3 },
            pane
          )
        else
          win:perform_action(
            action.ActivatePaneDirection(direction_keys[key]),
            pane
          )
        end
      end
    end),
  }
end

return M
