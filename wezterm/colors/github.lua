return {
  -- Normal colors
  background = '#22272e',
  foreground = '#adbac7',

  -- Cursor colors
  cursor_bg = '#adbac7',
  cursor_fg = '#22272e',
  cursor_border = '#adbac7',
  compose_cursor = '#c93c37',

  -- Selection colors
  selection_bg = '#2e4c77',
  selection_fg = '#adbac7',

  split = '#539bf5',
  scrollbar_thumb = '#292e42',

  ansi = {
    '#545d68',
    '#f47067',
    '#57ab5a',
    '#c69026',
    '#539bf5',
    '#b083f0',
    '#39c5cf',
    '#909dab',
  },
  brights = {
    '#636e7b',
    '#ff938a',
    '#6bc46d',
    '#daaa3f',
    '#6cb6ff',
    '#dcbdfb',
    '#56d4dd',
    '#cdd9e5',
  },

  tab_bar = {
    -- background of empty area in the tab bar
    background = '#22272e',

    -- color of the active tab
    active_tab = {
      fg_color = '#1f2335',
      bg_color = '#539bf5',
      intensity = 'Bold',
    },

    -- color of the inactive tabs
    inactive_tab = {
      fg_color = '#adbac7',
      bg_color = '#22272e',
    },

    -- color of the inactive tabs when hover
    inactive_tab_hover = {
      fg_color = '#539bf5',
      bg_color = '#22272e',
      italic = true,
    },

    -- color of new tab button
    new_tab = {
      fg_color = '#539bf5',
      bg_color = '#22272e',
    },

    -- color of new tab button when hover
    new_tab_hover = {
      fg_color = '#539bf5',
      bg_color = '#22272e',
      intensity = 'Bold',
    },
  },
}
