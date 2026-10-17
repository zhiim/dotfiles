def on_tab_bar_dirty(boss, window, data) -> None:
    manager = data["tab_manager"]
    if getattr(manager, "_kitty_tab_mouse_installed", False):
        return

    original = manager.handle_tab_bar_mouse

    # custom mouse handler
    def handle_mouse(x, y, button, modifiers, action):
        bar = manager.tab_bar
        if bar.laid_out_once:
            geometry = bar.window_geometry
            in_status = False
            if (
                geometry.left <= x < geometry.right
                and geometry.top <= y < geometry.bottom
            ):
                # current character cell
                cell = int(x - geometry.left) // bar.cell_width
                # whether in mode status pill or not
                in_status_range = getattr(bar, "_kitty_status_ranges", None)
                if in_status_range:
                    in_status_start, in_status_end = in_status_range
                    in_status = in_status_start <= cell < in_status_end
            # do not process in mode status pill
            if in_status:
                return
            # do not process drag
            if button == -1:
                return
        # otherwise use built in process
        original(x, y, button, modifiers, action)

    manager.handle_tab_bar_mouse = handle_mouse
    manager._kitty_tab_mouse_installed = True
