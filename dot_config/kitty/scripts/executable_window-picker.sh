#!/usr/bin/env bash
set -euo pipefail

scope="${1:-tab}"

case "$scope" in
  tab)
    data=$(kitten @ ls \
      --match-tab "window_id:${KITTY_WINDOW_ID:?}")
    ;;
  global)
    data=$(kitten @ ls)
    ;;
  *)
    echo "Usage: $0 {tab|global}" >&2
    exit 1
    ;;
esac

selected=$(
  jq -r --argjson self "${KITTY_WINDOW_ID:?}" '
    .[] as $os
    | $os.tabs[] as $tab
    | $tab.windows[]
    | select(.id != $self)
    | [
        (.id | tostring),
        ("OS " + ($os.id | tostring)),
        ("TAB " + ($tab.title // "")),
        (.title // ""),
        (.cwd // ""),
        ((.cmdline // []) | join(" "))
      ]
    | map(tostring | gsub("[\t\r\n]"; " "))
    | @tsv
  ' <<< "$data" |
    fzf \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --nth=2.. \
      --reverse \
      --border \
      --prompt="${scope}> " \
      --header="Search by tab / title / cwd / command"
) || exit 0

id="${selected%%$'\t'*}"

kitten @ focus-window --match "id:$id"
