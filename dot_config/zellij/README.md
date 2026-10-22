# Zellij

The original tmux-style zjstatus bar stays at the bottom. Tab formatting, icons,
indicators and the working-directory display are unchanged. Only its leftmost
mode badge changes color according to the current mode.

The `status-bar` alias now loads `plugins/rounded-status.wasm`, a small native
status-bar derivative with the official Zellij keybinding discovery code. A
background controller opens its hint strip only outside **Normal** and **Tmux**.
Returning to either mode closes the strip; there is no blank reserved row.

## Hint appearance and placement

The first element has a flat left edge. Its right edge and the other elements
use Nerd Font `` (U+E0B4). Reversed colors on subsequent left edges make them
concave, while the right edges are convex. Set the host terminal to a Nerd Font
with Powerline Extra glyphs.

The strip is a one-row, borderless, pinned floating pane immediately above the
bottom bar. It temporarily overlays the terminal's last content row while a
mode is active; it does not resize, split or rearrange terminal panes. It is
launched without focus, follows terminal resize and tab changes, and closes
when returning to Normal/Tmux. Other floating panes retain their own bindings.

## Mode colors

Both the lower mode badge and the upper strip's first element use this mapping:

| Mode | ANSI background |
| --- | --- |
| Normal | Blue (4) |
| Tmux | Yellow (3) |
| Locked | Red (1) |
| Pane | Green (2) |
| Tab | Cyan (6) |
| Resize | Magenta (5) |
| Move | Bright red (9) |
| Scroll | Bright blue (12) |
| EnterSearch | Bright yellow (11) |
| Search | Bright magenta (13) |
| RenameTab | Bright cyan (14) |
| RenamePane | Bright green (10) |
| Session | White (7) |
| Prompt | Bright white (15) |

All colors come from the terminal's ANSI palette. Keep `mode_*` in
`layouts/tmux.kdl` and `mode_style` in the plugin source in sync when changing
colors. Tabs retain the original blue/black styling and have no half circles.

## Apply

The checked-in WASM is built against **Zellij 0.45.1**; Rust is not needed to use
it. Apply the files and start a new session:

```sh
chezmoi apply ~/.config/zellij
zellij --layout tmux --session mode-hints-check
```

Grant the local status-bar plugin's permissions on first launch. The initial
permission dialog is intentionally selectable; only after granting access does
the background controller become non-selectable. It reads application state,
changes its helper pane's position, and launches the helper instance. It never
executes shell commands. Existing or resurrected sessions retain their saved
layout; use a new session when checking the change.

- Normal and `Ctrl b` (Tmux): bottom zjstatus only.
- `Ctrl p`, `Ctrl t`, `Ctrl n`, `Ctrl s`, `Ctrl o`: show the relevant hints.
- `Ctrl s`, then `s`, then `Enter`: switch through Scroll, search input and results.
- `Esc` outside text entry: hide the strip on return to Normal.

The hint extraction follows the official status-bar's recognized action
patterns and reads the effective keymap. It does not enumerate arbitrary
`MessagePlugin` actions. `Ctrl h/j/k/l` still use vim-zellij-navigator, and
`Ctrl h` therefore overrides the default Move-mode entry shortcut.

## Rebuild or test

Plugin source, locked dependencies and the upstream MIT license are included in
`plugins/rounded-status/`. `src/hints.rs` is adapted from Zellij v0.45.1 commit
`efd8fd5a89a20c07a111d248ad7fce53848d2c18`. When upgrading Zellij, update the
pinned `zellij-tile` version and review upstream action/keymap API changes.

With Rust installed:

```sh
cd ~/.config/zellij/plugins/rounded-status
cargo build --release --locked --target wasm32-wasip1
cp target/wasm32-wasip1/release/rounded-status.wasm ../rounded-status.wasm
```

Tests run as WASI without a desktop or Zellij server (Node 22+):

```sh
cargo test --locked --target wasm32-wasip1 --no-run
node run-tests.mjs target/wasm32-wasip1/debug/deps/rounded_status-<hash>.wasm
```

The tests cover visibility transitions, no-focus launches, rapid re-entry,
resize and tab tracking, flat first edges, rounded subsequent edges, distinct
mode colors, actual remapped keys and narrow terminal widths.
