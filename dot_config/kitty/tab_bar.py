import sys
from os.path import basename
from typing import TYPE_CHECKING

from kitty.fast_data_types import (
    get_boss,
    get_options,
    truncate_point_for_length,
    wcswidth,
)
from kitty.tab_bar import as_rgb
from kitty.utils import sanitize_control_codes

if TYPE_CHECKING:
    from kitty.fast_data_types import Screen
    from kitty.tab_bar import DrawData, ExtraData, TabBarData


# Shared contract with key_mappings.py; the renderer is loaded via runpy, not
# as a package, so it must not depend on the config directory being on sys.path.
LOCK_ATTRIBUTE = "_kitty_navigation_locked"
FOCUS_ICON = "󰻿"
STACK_ICON = ""
LOCK_ICON = ""
TAB_MAX_WIDTH = 18


def fit_text(text: str, cells: int) -> str:
    """Truncate by terminal cells (including wide/combining text), not bytes."""
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


def draw_text(
    screen: "Screen", text: str, fg: int, bg: int, bold: bool = False
) -> None:
    screen.cursor.fg = as_rgb(fg)
    screen.cursor.bg = as_rgb(bg)
    screen.cursor.bold = bold
    screen.cursor.italic = False
    screen.draw(text)


def draw_pill(
    screen: "Screen",
    body: str,
    fg: int,
    bg: int,
    outer_bg: int,
    leading: str = " ",
    trailing: str = " ",
    bold: bool = False,
) -> None:
    """Draw a rounded Powerline pill where semicircles use fg=bg and bg=outer_bg."""
    draw_text(screen, f"{leading}", bg, outer_bg)
    draw_text(screen, body, fg, bg, bold=bold)
    draw_text(screen, f"{trailing}", bg, outer_bg)


def os_icon(window) -> str:
    if window is not None:
        command = window.child.foreground_cmdline
        if window.ssh_kitten_cmdline() or (command and basename(command[0]) == "ssh"):
            return "󰢹"
    return "" if sys.platform.startswith("linux") else ""


def mode_status(boss, window, options) -> tuple[str, int]:
    # for kitty_grab
    if window is not None and window.title == "kitty_pager.sh":
        return " COPY", int(options.color2)

    mode = boss.mappings.current_keyboard_mode_name.replace("_", " ").upper()
    mode = mode.removesuffix(" MODE")
    if mode == "LEADER":
        return " LEADER", int(options.color6)
    return f"{os_icon(window)} NORMAL", int(options.active_tab_background)


def draw_right_status(screen: "Screen", manager, options, bg: int) -> None:
    active = manager.active_tab
    if active is None:
        return
    window = active.active_window
    session = active.active_session_name or "default"
    title = window.title if window is not None else ""
    available = max(0, screen.columns - screen.cursor.x - 1)
    if available < 4:
        return
    session_budget = min(24, available // 2) if title else available
    session_text = fit_text(f"󰗘 {session} ", session_budget)
    title_text = fit_text(f"󰙀 {title}", available - wcswidth(session_text))
    start = screen.columns - wcswidth(session_text + title_text)
    screen.cursor.x = start
    draw_text(screen, session_text, int(options.foreground), bg, bold=True)
    draw_text(screen, title_text, int(options.color5), bg)


def draw_tab(
    draw_data: "DrawData",
    screen: "Screen",
    tab: "TabBarData",
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: "ExtraData",
) -> int:
    boss = get_boss()
    options = get_options()
    # get tab manager
    manager = boss.os_window_map.get(tab.os_window_id)
    # get active tab
    active = manager.active_tab if manager is not None else None
    # get current tab
    real_tab = boss.tab_for_id(tab.tab_id) if tab.tab_id > 0 else None
    # whether current tab is locked or not
    locked = real_tab is not None and getattr(real_tab, LOCK_ATTRIBUTE, False)
    bg = int(draw_data.default_bg)
    # max available length for current tab
    budget = min(max_tab_length, screen.columns - before)

    tab_bar = manager.tab_bar
    # used to record (start, end) position of mod status pill, use empty value at startup
    if not extra_data.for_layout and index == 1 and manager is not None:
        tab_bar._kitty_status_ranges = None
        tab_bar._kitty_mode_pill_degraded = False

    # draw the keyboard mode status pill
    if index == 1:
        window = active.active_window if active is not None else None
        # get keyboard mode of current active window
        status, status_bg = mode_status(boss, window, options)
        # left half circle + statu widith + right space + right half circle
        pill_width = wcswidth(status) + 3
        start = screen.cursor.x
        # whither there is sufficient space for current_tab_pill (length 5)
        if budget - 5 >= pill_width:
            draw_pill(
                screen,
                status,
                int(draw_data.active_fg),
                status_bg,
                bg,
                leading="",
                bold=True,
            )
        else:
            # only display keyboard mode status, no half circle
            prefix = fit_text(f"{status} ", max(0, budget - 5))
            draw_text(screen, prefix, int(draw_data.active_fg), status_bg, bold=True)
            tab_bar._kitty_mode_pill_degraded = True

        budget -= screen.cursor.x - start
        if (
            not extra_data.for_layout
            and manager is not None
            and screen.cursor.x > start
        ):
            manager.tab_bar._kitty_status_ranges = (start, screen.cursor.x)

    width = max(0, min(TAB_MAX_WIDTH, budget))
    # current active tab
    if tab.is_active:
        if locked:
            icon, accent = LOCK_ICON, int(options.color1)
        elif tab.layout_name == "stack":
            icon, accent = STACK_ICON, int(options.color3)
        else:
            icon, accent = FOCUS_ICON, int(draw_data.active_bg)
        outer_bg = int(draw_data.active_fg)
        body = f" {icon} "
        if width >= wcswidth(body) + 2 and not getattr(
            tab_bar, "_kitty_mode_pill_degraded", False
        ):
            draw_pill(screen, body, outer_bg, accent, outer_bg, leading="", trailing="")
        else:
            draw_text(screen, fit_text(body, width), outer_bg, accent)
    # not active tab
    else:
        inactive_bg = int(draw_data.inactive_bg)
        label = fit_text(f" {index}# ", width)
        accent = (
            int(options.color1)
            if locked
            else int(options.color3)
            if tab.layout_name == "stack"
            else int(draw_data.active_bg)
        )
        draw_text(screen, label, accent, inactive_bg, bold=True)
        remaining = width - wcswidth(label)
        title = fit_text(tab.title, remaining - 1)
        draw_text(screen, title, int(draw_data.inactive_fg), inactive_bg)
        if remaining > wcswidth(title):
            draw_text(screen, " ", int(draw_data.inactive_fg), inactive_bg)

    end = screen.cursor.x

    # reset cursor status
    screen.cursor.bold = screen.cursor.italic = False
    screen.cursor.fg = screen.cursor.bg = 0

    if is_last and not extra_data.for_layout and manager is not None:
        draw_right_status(screen, manager, options, bg)
        # Kitty erases from the cursor to EOL after drawing the final tab.
        screen.cursor.x = screen.columns
    return end
