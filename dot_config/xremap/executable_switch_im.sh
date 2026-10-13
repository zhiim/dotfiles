#!/usr/bin/env bash
set -euo pipefail

REMOTE=fcitx5-remote
RIME=rime
US=keyboard-us

current="$("$REMOTE" -n)"

case "$current" in
    "$RIME")
        exec "$REMOTE" -s "$US"
        ;;
    "$US")
        exec "$REMOTE" -s "$RIME"
        ;;
    *)
        echo "current IM is neither Rime nor US：$current" >&2
        exit 1
        ;;
esac
