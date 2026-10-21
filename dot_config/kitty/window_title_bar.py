"""Render a theme-colored lock pill beside each pane's title."""

from typing import TYPE_CHECKING

from kitty.fast_data_types import get_boss, get_options

if TYPE_CHECKING:
    from kitty.window_title_bar import WindowTitleData


# Shared with key_mappings.py and tab_bar.py; Kitty loads these via runpy.
LOCK_ATTRIBUTE = "_kitty_navigation_locked"
LOCK_ICON = ""


def color_sequence(color: int, *, background: bool = False) -> str:
    channel = 48 if background else 38
    return f"\x1b[{channel};2;{color >> 16};{(color >> 8) & 255};{color & 255}m"


def draw_window_title(data: "WindowTitleData") -> str:
    window = get_boss().window_id_map.get(data.window_id)
    if window is None:
        return ""

    tab = window.tabref()
    locked = getattr(window, LOCK_ATTRIBUTE, getattr(tab, LOCK_ATTRIBUTE, False))
    options = get_options()
    accent = color_sequence(int(options.color1))
    if not locked:
        # Keep an inset even without a badge; activity markers use the theme red.
        return f" {accent}"

    if data.is_active:
        background = options.window_title_bar_active_background
        fallback = options.active_tab_background
    else:
        background = options.window_title_bar_inactive_background
        fallback = options.inactive_tab_background
    bar_bg = color_sequence(
        int(fallback if background is None else background), background=True
    )
    pill_bg = color_sequence(int(options.color1), background=True)
    pill_fg = color_sequence(int(options.background))
    # Match tab_bar.py's rounded Powerline pills, restoring the bar background
    # before the activity marker, progress and title supplied by the template.
    return (
        f" {bar_bg}{accent}"
        f"{pill_bg}{pill_fg} {LOCK_ICON} "
        f"{bar_bg}{accent} "
    )
