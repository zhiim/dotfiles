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

local function basename(s)
  if s == nil then
    return nil
  end
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

function M.apply(config, theme)
  -- Diable system title bar, and put window management buttons into tab bar
  ---@diagnostic disable-next-line: assign-type-mismatch
  -- config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

  config.use_fancy_tab_bar = false
  config.tab_max_width = 18

  local colors, _ = wezterm.color.load_scheme(
    wezterm.config_dir .. '/colors/' .. theme .. '.toml'
  )

  local normal = colors.foreground

  local tabbar_bg = colors.tab_bar.background

  local red = colors.ansi[2]
  local green = colors.ansi[3]
  local yellow = colors.ansi[4]
  local blue = colors.ansi[5]
  local magenta = colors.ansi[6]
  local cyan = colors.ansi[7]

  local inactive_bg = colors.tab_bar.inactive_tab.bg_color
  local inactive_fg = colors.tab_bar.inactive_tab.fg_color
  local inactive_hover_bg = colors.tab_bar.inactive_tab_hover.bg_color
  local inactive_hover_fg = colors.tab_bar.inactive_tab_hover.fg_color
  local active_bg = colors.tab_bar.active_tab.bg_color
  local active_fg = colors.tab_bar.active_tab.fg_color

  -- change window management buttons
  -- config.tab_bar_style = {
  -- 	window_hide = wezterm.format({
  -- 		{ Foreground = { Color = normal } },
  -- 		{ Text = " " .. wezterm.nerdfonts.md_window_minimize .. " " },
  -- 	}),
  -- 	window_hide_hover = wezterm.format({
  -- 		{ Background = { Color = active_bg } },
  -- 		{ Foreground = { Color = active_fg } },
  -- 		{ Text = " " .. wezterm.nerdfonts.md_window_minimize .. " " },
  -- 	}),
  -- 	window_maximize = wezterm.format({
  -- 		{ Foreground = { Color = normal } },
  -- 		{ Text = " " .. wezterm.nerdfonts.md_window_maximize .. " " },
  -- 	}),
  -- 	window_maximize_hover = wezterm.format({
  -- 		{ Background = { Color = active_bg } },
  -- 		{ Foreground = { Color = active_fg } },
  -- 		{ Text = " " .. wezterm.nerdfonts.md_window_maximize .. " " },
  -- 	}),
  -- 	window_close = wezterm.format({
  -- 		{ Foreground = { Color = normal } },
  -- 		{ Text = " " .. wezterm.nerdfonts.md_window_close .. " " },
  -- 	}),
  -- 	window_close_hover = wezterm.format({
  -- 		{ Background = { Color = colors.ansi[2] } },
  -- 		{ Foreground = { Color = normal } },
  -- 		{ Text = " " .. wezterm.nerdfonts.md_window_close .. " " },
  -- 	}),
  -- }

  wezterm.on('format-tab-title', function(tab, _, _, _, hover, max_width)
    local bg = inactive_fg
    local fg = inactive_bg
    if tab.is_active then
      bg = active_bg
      fg = active_fg
    end
    if not tab.is_active and hover then
      bg = inactive_hover_fg
      fg = inactive_hover_bg
    end

    if tab.is_active then
      return {
        { Background = { Color = fg } },
        { Foreground = { Color = bg } },
        { Text = '' },
        { Background = { Color = bg } },
        { Foreground = { Color = fg } },
        {
          Text = ' '
            .. wezterm.nerdfonts.md_image_filter_center_focus_strong
            .. ' ',
        },
        { Background = { Color = fg } },
        { Foreground = { Color = bg } },
        { Text = '' },
      }
    end

    local tab_index = tostring(tab.tab_index + 1)

    local tab_name = get_tab_name(tab)
    tab_name = wezterm.truncate_right(tab_name, max_width - 5)

    return {
      { Background = { Color = fg } },
      { Foreground = { Color = active_bg } },
      { Attribute = { Intensity = 'Bold' } },
      { Text = ' ' .. tab_index .. '#' },
      { Background = { Color = fg } },
      { Foreground = { Color = bg } },
      { Attribute = { Intensity = 'Normal' } },
      { Text = ' ' .. tab_name .. ' ' },
    }
  end)

  wezterm.on('update-status', function(window, pane)
    local logo = ''
    -- if in Windows, show wsl, fish or windows logo
    if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
      logo = wezterm.nerdfonts.md_microsoft_windows
      local launch_pro = basename(pane:get_foreground_process_name())
      if launch_pro == 'wslhost.exe' then
        logo = wezterm.nerdfonts.md_linux
      elseif launch_pro == 'fish.exe' then
        logo = wezterm.nerdfonts.md_fish
      end
    -- if in Linux, show linux (Arch) logo
    elseif wezterm.target_triple == 'x86_64-unknown-linux-gnu' then
      logo = wezterm.nerdfonts.linux_archlinux
    end
    -- if in ssh domain, show ssh logo
    if string.match(pane:get_domain_name(), '^SSH') then
      logo = wezterm.nerdfonts.md_remote_desktop
    end

    -- format the text to be displayed in mode status block (all caps with no underscores)
    local function format_mode_text(mode_text)
      -- replace underscores with spaces
      local new_string = string.gsub(mode_text, '_+', ' ')

      -- capitalise all letters
      new_string = string.upper(new_string)

      -- remove 'MODE' from the end of the string
      if string.sub(new_string, -5) == ' MODE' then
        new_string = string.sub(new_string, 1, -6)
      end

      return new_string
    end

    local mode
    local mode_bg_colour
    local mode_fg_colour = tabbar_bg
    if require('mappings').read_toggle() then
      mode = wezterm.nerdfonts.fa_lock .. ' LOCKED'
      mode_bg_colour = red
    elseif window:active_key_table() then
      mode = format_mode_text(window:active_key_table())
      if mode == 'COPY' then
        mode = ' ' .. mode
        mode_bg_colour = green
      elseif mode == 'SEARCH' then
        mode = wezterm.nerdfonts.fa_search .. ' ' .. mode
        mode_bg_colour = yellow
      else
        -- fallback
        mode = logo .. ' NORMAL'
        mode_bg_colour = active_bg
      end
    elseif window:leader_is_active() then
      mode = wezterm.nerdfonts.fa_dot_circle_o .. ' LEADER'
      mode_bg_colour = cyan
    else
      mode = logo .. ' NORMAL'
      mode_bg_colour = active_bg
    end

    window:set_left_status(wezterm.format {
      { Background = { Color = mode_fg_colour } },
      { Foreground = { Color = mode_bg_colour } },
      { Text = ' ' },
      { Background = { Color = mode_bg_colour } },
      { Foreground = { Color = active_fg } },
      { Text = mode },
      { Background = { Color = mode_fg_colour } },
      { Foreground = { Color = mode_bg_colour } },
      { Text = ' ' },
    })

    window:set_right_status(wezterm.format {
      { Attribute = { Intensity = 'Bold' } },
      { Text = wezterm.nerdfonts.md_animation .. ' ' },
      { Text = window:active_workspace() .. ' ' },
      { Foreground = { Color = magenta } },
      { Attribute = { Intensity = 'Normal' } },
      { Text = wezterm.nerdfonts.md_collage .. ' ' },
      { Text = pane:get_title() .. ' ' },
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
