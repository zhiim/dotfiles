return {
  -- Normal colors
  foreground = '#c0caf5',
  background = '#24283b',

  -- Cursor colors
  cursor_bg = '#c0caf5',
  cursor_fg = '#24283b',
  cursor_border = '#c0caf5',
  compose_cursor = '#ff9e64',

  -- Selection colors
  selection_bg = '#2e3c64',
  selection_fg = '#c0caf5',

  split = '#7aa2f7',
  scrollbar_thumb = '#292e42',

  ansi = {
    '#1d202f',
    '#f7768e',
    '#9ece6a',
    '#e0af68',
    '#7aa2f7',
    '#bb9af7',
    '#7dcfff',
    '#a9b1d6',
  },
  brights = {
    '#414868',
    '#f7768e',
    '#9ece6a',
    '#e0af68',
    '#7aa2f7',
    '#bb9af7',
    '#7dcfff',
    '#c0caf5',
  },

  tab_bar = {
    -- background of empty area in the tab bar
    background = '#24283b',

    -- color of the active tab
    active_tab = {
      fg_color = '#1f2335',
      bg_color = '#7aa2f7',
      intensity = 'Bold',
    },

    -- color of the inactive tabs
    inactive_tab = {
      fg_color = '#545c7e',
      bg_color = '#292e42',
    },

    -- color of the inactive tabs when hover
    inactive_tab_hover = {
      fg_color = '#7aa2f7',
      bg_color = '#292e42',
      italic = true,
    },

    -- color of new tab button
    new_tab = {
      fg_color = '#7aa2f7',
      bg_color = '#24283b',
    },

    -- color of new tab button when hover
    new_tab_hover = {
      fg_color = '#7aa2f7',
      bg_color = '#24283b',
      intensity = 'Bold',
    },
  },
}
