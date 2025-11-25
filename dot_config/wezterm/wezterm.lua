-- Pull in the wezterm API
local wezterm = require("wezterm") --[[@as Wezterm]]

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- Set widows size at starup
config.initial_rows = 30
config.initial_cols = 120

config.font = wezterm.font_with_fallback({
	{ family = "JetBrainsMono Nerd Font", weight = "Medium" },
	{ family = "Noto Sans CJK SC", weight = "Medium" },
})

config.font_size = 12.0

-- disable ligatures
-- config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- use WSL
-- config.default_domain = 'WSL:openSUSE-Tumbleweed'

-- Default launching Programs
-- config.default_prog = { 'pwsh.exe', '-nol' }
-- config.default_prog = { "D:\\msys2\\usr\\bin\\fish.exe", "-i", "-l" }

-- config.launch_menu = {
--   {
--     label = 'PowerShell',
--     args = { 'pwsh.exe', '-nol' },
--     domain = { DomainName = 'local' },
--   },
--   {
--     label = 'Fish',
--     args = { 'D:\\msys2\\usr\\bin\\fish.exe', '-i', '-l' },
--     domain = { DomainName = 'local' },
--   },
-- }

-- How many lines of scrollback you want to retain per tab
config.scrollback_lines = 3500

local theme = "github"

require("colors").apply(config, theme)
require("tab").apply(config, theme)
require("mappings").apply(config)
require("commend_palette").apply()
-- require('plugins').apply(config)

return config
