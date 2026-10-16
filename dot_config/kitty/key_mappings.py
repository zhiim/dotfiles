"""Dispatch keyboard shortcuts and smart-splits.nvim callbacks with a tab-local lock."""

from typing import TYPE_CHECKING

from kittens.tui.handler import result_handler

if TYPE_CHECKING:
    from kitty.boss import Boss
    from kitty.tabs import Tab
    from kitty.window import Window


DIRECTIONS = {"h": "left", "j": "bottom", "k": "top", "l": "right"}
DIRECTION_KEYS = {value: key for key, value in DIRECTIONS.items()}
DIRECTION_KEYS.update(up="k", down="j")
LOCK_ATTRIBUTE = "_kitty_navigation_locked"


def main(args: list[str]) -> None:
    """No terminal UI is needed; Kitty invokes handle_result directly."""


def resize_towards(tab: "Tab", window: "Window", key: str, amount: int = 3) -> None:
    if amount < 1:
        raise ValueError("Resize amount must be positive")
    neighbors = tab.current_layout.neighbors_for_window(window, tab.windows)
    horizontal = key in ("h", "l")
    before, after = ("left", "right") if horizontal else ("top", "bottom")
    if not (neighbors.get(before) or neighbors.get(after)):
        return

    # Move the right/bottom edge if possible; at the outer edge move left/top.
    # This preserves directional resizing instead of always shrinking for h/k.
    grow = key in ("l", "j")
    if not neighbors.get(after):
        grow = not grow
    quality = (
        ("wider" if grow else "narrower")
        if horizontal
        else ("taller" if grow else "shorter")
    )
    tab.resize_window(quality, amount)


@result_handler(no_ui=True)
def handle_result(
    args: list[str], answer: object, target_window_id: int, boss: "Boss"
) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return
    tab = window.tabref()
    if tab is None:
        return

    operation = args[1]
    if operation == "toggle":
        # Keep state on the tab, not the kitten module (Kitty reloads kittens).
        setattr(tab, LOCK_ATTRIBUTE, not getattr(tab, LOCK_ATTRIBUTE, False))
        tab.mark_tab_bar_dirty()
        return
    if operation == "close-tab":
        # Kitty's close_tab can skip confirmation for single-pane tabs.
        # Confirm explicitly without changing global close preferences.
        def close_if_confirmed(confirmed: bool) -> None:
            if confirmed:
                boss.close_tab_no_confirm(tab)

        boss.confirm(
            "Close this tab and all its panes?",
            close_if_confirmed,
            window=window,
            title="Close tab?",
        )
        return
    if operation not in ("move", "resize"):
        raise ValueError(f"Unknown key mapping operation: {operation}")

    key = args[2]
    direction = DIRECTIONS[key]
    # smart-splits v2.1.1 emits base64 of 1 plus a newline, not "true".
    # Match the upstream Kitty config: presence marks Neovim, removal clears it.
    if getattr(tab, LOCK_ATTRIBUTE, False) or "IS_NVIM" in window.user_vars:
        modifier = "ctrl" if operation == "move" else "alt"
        window.send_key(f"{modifier}+{key}")
    elif operation == "move":
        tab.neighboring_window(direction)
    else:
        resize_towards(tab, window, key)
