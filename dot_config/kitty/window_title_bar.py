"""Render flat tab-colored pane labels on the terminal's background."""

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
    """Fit titles by terminal cells, including wide/combining characters."""
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
    outer_bg = int(window.screen.color_profile.default_bg)

    title = f"{LOCK_ICON} " if locked else ""
    if data.has_activity_since_last_focus:
        title += options.tab_activity_symbol
    progress = window.progress
    if progress.state is ProgressState.indeterminate:
        title += "[…] "
    elif progress.state is not ProgressState.unset and progress.percent > 0:
        title += f"[{progress.percent}%] "
    title += data.title

    # Use the title screen's actual width, which can include terminal padding.
    title_screen = window._title_bar_screen
    if title_screen is not None:
        # Match the native screen background too, including partial edge cells.
        title_screen.screen.color_profile.default_bg = (
            window.screen.color_profile.default_bg
        )
    title_width = (
        title_screen.screen.columns
        if title_screen is not None
        else window.screen.columns
    )
    width = max(1, title_width)
    body = fit_text(title, width - 2 if width >= 2 else width)
    body_width = wcswidth(body) + (2 if width >= 2 else 0)
    if locked and not data.is_active and body.startswith(LOCK_ICON):
        # Like inactive tabs, keep the label quiet and highlight only its lock.
        body = f"{color_sequence(int(options.color1))}{LOCK_ICON}{color_sequence(fg)}{body[1:]}"
    body = f" {body} " if width >= 2 else body
    # Explicitly paint the unused cells: Kitty otherwise clears them using its
    # default title-bar background, which falls back to the tab's label color.
    padding = " " * (width - body_width)
    return (
        f"{color_sequence(fg)}{color_sequence(bg, background=True)}{body}"
        f"{color_sequence(outer_bg, background=True)}{padding}"
    )
