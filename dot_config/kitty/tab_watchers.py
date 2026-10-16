"""Preserve native tab mouse actions, adding right-click on + for the launcher."""

from kitty.fast_data_types import (
    GLFW_MOUSE_BUTTON_RIGHT,
    GLFW_RELEASE,
    get_tab_being_dragged,
)


def on_tab_bar_dirty(boss, window, data) -> None:
    manager = data["tab_manager"]
    if getattr(manager, "_kitty_tab_mouse_installed", False):
        return
    original = manager.handle_tab_bar_mouse

    def handle_mouse(x, y, button, modifiers, action):
        bar = manager.tab_bar
        if bar.laid_out_once:
            geometry = bar.window_geometry
            tab_id = 0
            in_status = False
            if geometry.left <= x < geometry.right and geometry.top <= y < geometry.bottom:
                cell = int(x - geometry.left) // bar.cell_width
                in_status = any(start <= cell < end for start, end in getattr(bar, "_kitty_status_ranges", ()))
                if not in_status:
                    tab_id = bar.tab_id_at(int(x), int(y))
            if button == -1:  # Preserve native drag processing, even over status.
                original(x, y, button, modifiers, action)
                return
            if in_status:
                # A release after pressing a real tab must reach Kitty so its
                # pending drag/click state is cleared, even over a status area.
                if get_tab_being_dragged()[0]:
                    original(x, y, button, modifiers, action)
                return
            if button == GLFW_MOUSE_BUTTON_RIGHT and not modifiers and tab_id < 0:
                if action == GLFW_RELEASE:
                    boss.command_palette()
                return
        original(x, y, button, modifiers, action)

    # Kitty 0.49 has no custom tab-bar mouse-map hook. Wrap this manager's
    # handler only; keep native selection, + left-click, rename and drag logic.
    manager.handle_tab_bar_mouse = handle_mouse
    manager._kitty_tab_mouse_installed = True
