return {
  -- Normal colors
  foreground = '#cdcecf',
  background = '#192330',

  -- Cursor colors
  cursor_bg = '#cdcecf',
  cursor_border = '#cdcecf',
  cursor_fg = '#192330',
  compose_cursor = '#f4a261',

  -- Selection colors
  selection_bg = '#2b3b51',
  selection_fg = '#cdcecf',

  scrollbar_thumb = '#71839b',
  split = '#131a24',
  visual_bell = '#cdcecf',

  ansi = {
    '#393b44',
    '#c94f6d',
    '#81b29a',
    '#dbc074',
    '#719cd6',
    '#9d79d6',
    '#63cdcf',
    '#dfdfe0',
  },
  brights = {
    '#575860',
    '#d16983',
    '#8ebaa4',
    '#e0c989',
    '#86abdc',
    '#baa1e2',
    '#7ad5d6',
    '#e4e4e5',
  },

  tab_bar = {
    -- background of empty area wn the tab bar
    background = '#131a24',
    inactive_tab_edge = '#131a24',
    inactive_tab_edge_hover = '#212e3f',

    -- color of the actwve tab
    active_tab = {
      bg_color = '#71839b',
      fg_color = '#192330',
      intensity = 'Normal',
      italic = false,
      strikethrough = false,
      underline = 'None',
    },

    -- color of the inactive tabs
    inactive_tab = {
      bg_color = '#212e3f',
      fg_color = '#aeafb0',
      intensity = 'Normal',
      italic = false,
      strikethrough = false,
      underline = 'None',
    },

    -- color of the inactive tabs when hover
    inactive_tab_hover = {
      bg_color = '#29394f',
      fg_color = '#cdcecf',
      intensity = 'Normal',
      italic = false,
      strikethrough = false,
      underline = 'None',
    },

    -- color of new tab button
    new_tab = {
      bg_color = '#192330',
      fg_color = '#aeafb0',
      intensity = 'Normal',
      italic = false,
      strikethrough = false,
      underline = 'None',
    },

    -- color of new tab button when hover
    new_tab_hover = {
      bg_color = '#29394f',
      fg_color = '#cdcecf',
      intensity = 'Normal',
      italic = false,
      strikethrough = false,
      underline = 'None',
    },
  },
}
