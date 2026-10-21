"""Show manual tab and window navigation locks in each pane's title bar."""

from typing import TYPE_CHECKING

from kitty.fast_data_types import get_boss

if TYPE_CHECKING:
    from kitty.window_title_bar import WindowTitleData


# Shared with key_mappings.py and tab_bar.py; Kitty loads these via runpy.
LOCK_ATTRIBUTE = "_kitty_navigation_locked"


def draw_window_title(data: "WindowTitleData") -> str:
    window = get_boss().window_id_map.get(data.window_id)
    if window is None:
        return ""

    tab = window.tabref()
    markers = []
    if tab is not None and getattr(tab, LOCK_ATTRIBUTE, False):
        markers.append("[TAB LOCK]")
    if getattr(window, LOCK_ATTRIBUTE, False):
        markers.append("[WIN LOCK]")

    return " ".join(markers) + " " if markers else ""
