"""Render complete left-aligned pane labels using the tab bar palette."""

from typing import TYPE_CHECKING

from kitty.fast_data_types import (
    get_boss,
    get_options,
    truncate_point_for_length,
    wcswidth,
)
from kitty.progress import ProgressState
from kitty.utils import sanitize_control_codes

if TYPE_CHECKING:
    from kitty.window_title_bar import WindowTitleData


# Shared with key_mappings.py and tab_bar.py; Kitty loads these via runpy.
LOCK_ATTRIBUTE = "_kitty_navigation_locked"
LOCK_ICON = ""


def color_sequence(color: int, *, background: bool = False) -> str:
    channel = 48 if background else 38
    return f"\x1b[{channel};2;{color >> 16};{(color >> 8) & 255};{color & 255}m"


def fit_text(text: str, cells: int) -> str:
    """Leave room for the right cap, including with wide/combining titles."""
    if cells <= 0:
        return ""
    text = (
        sanitize_control_codes(text)
        .replace("\n", " ")
        .replace("\r", " ")
        .replace("\t", " ")
    )
    if wcswidth(text) <= cells:
        return text
    if cells == 1:
        return "…"
    return text[: truncate_point_for_length(text, cells - 1)] + "…"


def draw_window_title(data: "WindowTitleData") -> str:
    window = get_boss().window_id_map.get(data.window_id)
    if window is None:
        return ""

    tab = window.tabref()
    locked = getattr(window, LOCK_ATTRIBUTE, getattr(tab, LOCK_ATTRIBUTE, False))
    options = get_options()
    if data.is_active:
        fg = int(options.active_tab_foreground)
        bg = int(options.color1 if locked else options.active_tab_background)
    else:
        fg = int(options.inactive_tab_foreground)
        bg = int(options.inactive_tab_background)
    outer_bg = int(options.tab_bar_background)

    title = f"{LOCK_ICON} " if locked else ""
    if data.has_activity_since_last_focus:
        title += options.tab_activity_symbol
    progress = window.progress
    if progress.state is ProgressState.indeterminate:
        title += "[…] "
    elif progress.state is not ProgressState.unset and progress.percent > 0:
        title += f"[{progress.percent}%] "
    title += data.title

    width = max(1, window.screen.columns)
    body = fit_text(title, width - 3)
    if locked and not data.is_active and body.startswith(LOCK_ICON):
        # Like inactive tabs, keep the label quiet and highlight only its lock.
        body = f"{color_sequence(int(options.color1))}{LOCK_ICON}{color_sequence(fg)}{body[1:]}"
    body = f" {body} " if width >= 3 else " " * (width - 1)
    # The label starts flush left with a flat edge. Only its right edge is round.
    return (
        f"{color_sequence(fg)}{color_sequence(bg, background=True)}{body}"
        f"{color_sequence(bg)}{color_sequence(outer_bg, background=True)}"
        f"{color_sequence(fg)}"
    )
