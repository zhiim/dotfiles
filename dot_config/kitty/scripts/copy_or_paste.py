from kittens.tui.handler import result_handler


def main(args: list[str]) -> None:
    pass


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: object, target_window_id: int, boss) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    if window.text_for_selection():
        window.copy_to_clipboard()
        window.clear_selection()
    else:
        boss.paste_from_clipboard()
