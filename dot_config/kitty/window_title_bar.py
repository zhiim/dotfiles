"""Show the pane's effective manual navigation lock in its title bar."""

from typing import TYPE_CHECKING

from kitty.fast_data_types import get_boss

if TYPE_CHECKING:
    from kitty.window_title_bar import WindowTitleData


# Shared with key_mappings.py and tab_bar.py; Kitty loads these via runpy.
LOCK_ATTRIBUTE = "_kitty_navigation_locked"
LOCK_ICON = ""


def draw_window_title(data: "WindowTitleData") -> str:
    window = get_boss().window_id_map.get(data.window_id)
    if window is None:
        return ""

    tab = window.tabref()
    locked = getattr(window, LOCK_ATTRIBUTE, getattr(tab, LOCK_ATTRIBUTE, False))
    return f"{LOCK_ICON} " if locked else ""
