local wezterm = require 'wezterm' --[[@as Wezterm]]

local M = {}

function M.apply(config, name)
  local colors, _ = wezterm.color.load_scheme(
    wezterm.config_dir .. '/colors/' .. name .. '.toml'
  )
  config.colors = colors
end

return M
