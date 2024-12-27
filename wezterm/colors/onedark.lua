return {
  -- Normal colors
  background = '#282c34',
  foreground = '#abb2bf',

  -- Cursor colors
  cursor_bg = '#d55fde',
  cursor_fg = '#282c34',

  -- Selection colors
  selection_bg = '#d55fde',
  selection_fg = '#abb2bf',

  ansi = {
    '#282c34',
    '#ef596f',
    '#89ca78',
    '#e5c07b',
    '#61afef',
    '#d55fde',
    '#2bbac5',
    '#abb2bf',
  },
  brights = {
    '#5c6370',
    '#f38897',
    '#a9d89d',
    '#edd4a6',
    '#8fc6f4',
    '#e089e7',
    '#4bced8',
    '#c8cdd5',
  },

  tab_bar = {
    -- background of empty area in the tab bar
    background = '#282c34',
    inactive_tab_edge = '#282c34',

    -- color of the active tab
    active_tab = {
      bg_color = '#e089e7',
      fg_color = '#282c34',
      intensity = 'Bold',
    },

    -- color of the inactive tabs
    inactive_tab = {
      fg_color = '#5c6370',
      bg_color = '#282c34',
    },

    -- color of the inactive tabs when hover
    inactive_tab_hover = {
      fg_color = '#e089e7',
      bg_color = '#282c34',
      italic = true,
    },

    -- color of new tab button
    new_tab = {
      fg_color = '#e089e7',
      bg_color = '#282c34',
    },

    -- color of new tab button when hover
    new_tab_hover = {
      fg_color = '#282c34',
      bg_color = '#e089e7',
      intensity = 'Bold',
    },
  },
}
