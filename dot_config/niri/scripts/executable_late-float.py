#!/usr/bin/env python3
"""
Dynamically float windows after their title/app-id changes.

This is useful for windows such as the Firefox Bitwarden extension:
Firefox initially creates the window with a generic title, then updates
the title to Bitwarden afterward.
"""

from dataclasses import dataclass, field
import json
import os
import re
import subprocess
import time
from socket import AF_UNIX, SHUT_WR, socket


@dataclass(kw_only=True)
class Match:
    title: str | None = None
    app_id: str | None = None

    def matches(self, window: dict) -> bool:
        title = window.get("title") or ""
        app_id = window.get("app_id") or ""

        if self.title is None and self.app_id is None:
            return False

        if self.title is not None:
            if re.search(self.title, title) is None:
                return False

        if self.app_id is not None:
            if re.search(self.app_id, app_id) is None:
                return False

        return True


@dataclass
class Rule:
    match: list[Match] = field(default_factory=list)
    exclude: list[Match] = field(default_factory=list)

    def matches(self, window: dict) -> bool:
        if self.match and not any(item.matches(window) for item in self.match):
            return False

        if any(item.matches(window) for item in self.exclude):
            return False

        return True


RULES = [
    Rule(
        match=[
            Match(
                title=r"Bitwarden",
                app_id=r"^firefox$",
            )
        ]
    ),
]


DEFAULT_FLOAT_WIDTH = "30%"
DEFAULT_FLOAT_HEIGHT = "70%"
# DEFAULT_FLOAT_WIDTH = "420"
# DEFAULT_FLOAT_HEIGHT = "600"

ACTION_DELAY = 0.1

if not RULES:
    raise SystemExit("no RULES defined")


def niri_action(*args: str) -> bool:
    try:
        result = subprocess.run(
            ["niri", "msg", "action", *args],
            check=False,
            text=True,
            capture_output=True,
        )
    except OSError as error:
        print(f"cannot execute niri command：{error}")
        return False

    if result.returncode != 0:
        error_message = result.stderr.strip() or result.stdout.strip()
        print(f"niri action executing failed：{' '.join(args)}\n{error_message}")
        return False

    return True


def float_window(window: dict) -> None:
    window_id = window["id"]
    title = window.get("title") or ""
    app_id = window.get("app_id") or ""

    print(f"process window：id={window_id}, title={title!r}, app_id={app_id!r}")

    if not window.get("is_floating", False):
        if not niri_action(
            "move-window-to-floating",
            "--id",
            str(window_id),
        ):
            return

        time.sleep(ACTION_DELAY)

    if not niri_action(
        "set-window-width",
        "--id",
        str(window_id),
        DEFAULT_FLOAT_WIDTH,
    ):
        return

    if not niri_action(
        "set-window-height",
        "--id",
        str(window_id),
        DEFAULT_FLOAT_HEIGHT,
    ):
        return

    time.sleep(ACTION_DELAY)

    niri_action(
        "center-window",
        "--id",
        str(window_id),
    )


windows: dict[int, dict] = {}


def update_matched(window: dict) -> None:
    window_id = window["id"]

    previous = windows.get(window_id)
    matched_before = bool(previous and previous.get("matched", False))

    matched_now = any(rule.matches(window) for rule in RULES)
    window["matched"] = matched_now

    if matched_now and not matched_before:
        float_window(window)


def listen_events() -> None:
    niri_socket_path = os.environ.get("NIRI_SOCKET")

    if not niri_socket_path:
        raise SystemExit("cannot find NIRI_SOCKET")

    with socket(AF_UNIX) as niri_socket:
        niri_socket.connect(niri_socket_path)

        with niri_socket.makefile("rw") as event_file:
            event_file.write('"EventStream"\n')
            event_file.flush()
            niri_socket.shutdown(SHUT_WR)

            for line in event_file:
                try:
                    event = json.loads(line)
                except json.JSONDecodeError as error:
                    print(f"cannot resolve niri event：{error}")
                    continue

                if changed := event.get("WindowsChanged"):
                    current_windows = {}

                    for window in changed["windows"]:
                        update_matched(window)
                        current_windows[window["id"]] = window

                    windows.clear()
                    windows.update(current_windows)

                elif changed := event.get("WindowOpenedOrChanged"):
                    window = changed["window"]

                    update_matched(window)
                    windows[window["id"]] = window

                elif changed := event.get("WindowClosed"):
                    windows.pop(changed["id"], None)


if __name__ == "__main__":
    listen_events()
