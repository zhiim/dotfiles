# Zellij

The `tmux` layout has two one-row bars at the bottom:

- Zellij's built-in `status-bar` above: mode shortcuts in normal mode, and
  contextual action shortcuts after entering pane, tab, resize, scroll/search,
  session, or tmux mode. It reads the effective keymap, including overrides.
- `zjstatus` below: the existing tmux-style tabs and focused pane's directory,
  with a label for the active mode.

The native bar uses `classic true` so a one-row pane shows action hints rather
than the newer compact UI. It adapts hints to terminal width. Both bars live in
`default_tab_template`, so new tabs and swap layouts retain them. This layout
always reserves two rows, including in normal mode; no extra plugin is needed.

`themes/ansi-tmux.kdl` is based on Zellij's built-in `ansi` theme. It uses the
terminal's ANSI palette: black backgrounds, blue shortcuts/tabs, and yellow
active modes. Other components retain the upstream ANSI colors.

## Apply and check

Apply these files with chezmoi, then start a **new** session so the layout takes
effect. Reattaching an existing or resurrected session retains its saved layout.

```sh
chezmoi apply ~/.config/zellij
zellij --layout tmux --session mode-hints-check
```

Try these keys:

| Keys | Expected hint row |
| --- | --- |
| `Ctrl p` | Pane focus, splits, close, fullscreen, rename |
| `Ctrl t` | Tab navigation, create, close, rename, sync |
| `Ctrl n` | Resize directions and increase/decrease |
| `Ctrl s` | Scroll, page movement, search, scrollback editor |
| `Ctrl s`, then `s` | Search input; `Enter` enters search results |
| `Ctrl o` | Session actions and plugin launchers |
| `Ctrl b` | Tmux mode, matching recognized custom actions |
| `Esc` (outside text entry) | Mode shortcuts return; tmux tabs remain below |

The native bar shows recognized actions, not an exhaustive list of every custom
binding (for example, arbitrary `MessagePlugin` calls). Existing keybindings are
unchanged. `Ctrl h/j/k/l` still go through vim-zellij-navigator; in particular,
`Ctrl h` overrides the default shortcut for entering Move mode.

To return to a single row, remove the `zellij:status-bar` pane from
`layouts/tmux.kdl` and start a new session.
