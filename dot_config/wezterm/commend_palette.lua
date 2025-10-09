local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

function M.apply()
  wezterm.on('augment-command-palette', function(_, _)
    -- add custom commands to the command palette
    return {
      {
        brief = 'Rename tab',
        icon = 'md_rename_box',

        action = wezterm.action.PromptInputLine {
          description = 'Enter new name for tab',
          initial_value = 'Tab',
          action = wezterm.action_callback(function(window, _, line)
            if line then
              window:active_tab():set_title(line)
            end
          end),
        },
      },
    }
  end)
end

return M
