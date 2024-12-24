local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

local function get_tab_name(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end

function M.apply(config, theme)
  -- Diable system title bar, and put window management buttons into tab bar
  ---@diagnostic disable-next-line: assign-type-mismatch
  config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'

  config.use_fancy_tab_bar = false
  config.tab_max_width = 32

  local colors = require('colors.' .. theme)
  local empty = colors.tab_bar.background

  local inactive_bg = colors.tab_bar.inactive_tab.bg_color
  local inactive_fg = colors.tab_bar.inactive_tab.fg_color
  local inactive_hover_bg = colors.tab_bar.inactive_tab_hover.bg_color
  local inactive_hover_fg = colors.tab_bar.inactive_tab_hover.fg_color
  local active_bg = colors.tab_bar.active_tab.bg_color
  local active_fg = colors.tab_bar.active_tab.fg_color

  -- change window management buttons
  config.tab_bar_style = {
    window_hide = wezterm.format {
      { Text = ' ' .. wezterm.nerdfonts.md_window_minimize .. ' ' },
    },
    window_hide_hover = wezterm.format {
      { Background = { Color = active_bg } },
      { Foreground = { Color = active_fg } },
      { Text = ' ' .. wezterm.nerdfonts.md_window_minimize .. ' ' },
    },
    window_maximize = wezterm.format {
      { Text = ' ' .. wezterm.nerdfonts.md_window_maximize .. ' ' },
    },
    window_maximize_hover = wezterm.format {
      { Background = { Color = active_bg } },
      { Foreground = { Color = active_fg } },
      { Text = ' ' .. wezterm.nerdfonts.md_window_maximize .. ' ' },
    },
    window_close = wezterm.format {
      { Text = ' ' .. wezterm.nerdfonts.md_window_close .. ' ' },
    },
    window_close_hover = wezterm.format {
      { Background = { Color = colors.ansi[2] } },
      { Foreground = { Color = active_fg } },
      { Text = ' ' .. wezterm.nerdfonts.md_window_close .. ' ' },
    },
  }

  wezterm.on('format-tab-title', function(tab, _, _, _, hover, max_width)
    local bg = inactive_bg
    local fg = inactive_fg
    if tab.is_active then
      bg = active_bg
      fg = active_fg
    end
    if not tab.is_active and hover then
      bg = inactive_hover_bg
      fg = inactive_hover_fg
    end

    local tab_num = tostring(tab.tab_index + 1)
    local tab_name = get_tab_name(tab)

    tab_name = wezterm.truncate_right(tab_name, max_width - 7)

    return {
      { Background = { Color = empty } },
      { Foreground = { Color = bg } },
      { Text = wezterm.nerdfonts.ple_lower_right_triangle },
      { Background = { Color = bg } },
      { Foreground = { Color = fg } },
      { Text = ' ' .. tab_num .. ':' .. ' ' .. tab_name .. ' ' },
      { Background = { Color = empty } },
      { Foreground = { Color = bg } },
      { Text = wezterm.nerdfonts.ple_upper_left_triangle },
    }
  end)

  local logo = ''
  if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    logo = wezterm.nerdfonts.md_microsoft_windows
  elseif wezterm.target_triple == 'x86_64-unknown-linux-gnu' then
    logo = wezterm.nerdfonts.md_linux
  end

  wezterm.on('update-status', function(window, _)
    window:set_left_status(wezterm.format {
      { Background = { Color = active_bg } },
      { Foreground = { Color = active_fg } },
      { Text = ' ' .. logo .. ' ' },
      { Background = { Color = empty } },
      { Foreground = { Color = active_bg } },
      { Text = wezterm.nerdfonts.ple_upper_left_triangle },
    })
  end)

  wezterm.on(
    'new-tab-button-click',
    function(window, pane, button, default_action)
      if default_action and button == 'Left' then
        window:perform_action(default_action, pane)
      end
      if default_action and button == 'Right' then
        window:perform_action(
          wezterm.action.ShowLauncherArgs {
            flags = 'FUZZY|LAUNCH_MENU_ITEMS|DOMAINS',
          },
          pane
        )
      end
      return false
    end
  )
end

return M