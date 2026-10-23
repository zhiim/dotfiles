#!/usr/bin/env bash
set -euo pipefail

scope="${1:-tab}"

case "$scope" in
  tab|global) ;;
  *)
    echo "Usage: $0 {tab|global}" >&2
    exit 1
    ;;
esac

for command in kitten jq fzf; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "window-picker: missing dependency: $command" >&2
    exit 1
  fi
done

self="${KITTY_WINDOW_ID:?Run this script inside Kitty}"
# Query all tabs so their displayed numbers stay the same in both scopes.
data=$(kitten @ ls)
windows=$(jq --argjson self "$self" --arg scope "$scope" '
  [
    .[] as $os
    | $os.tabs | to_entries[]
    | .key as $tab_index | .value as $tab
    | select($scope == "global" or any($tab.windows[]; .id == $self or .is_self == true))
    | $tab.windows | to_entries[]
    | .key as $window_index | .value
    | select(.id != $self)
    | (.foreground_processes // []) as $processes
    | {
        id,
        os_id: $os.id,
        tab_number: ($tab_index + 1),
        tab_id: $tab.id,
        tab_title: ($tab.title // ""),
        window_number: ($window_index + 1),
        title: (.title // ""),
        cwd: ($processes[0].cwd // .cwd // ""),
        program: (($processes[0].cmdline[0] // .cmdline[0] // "") | split("/") | last),
        command: (if ($processes | length) > 0 then
          [$processes[] | (.cmdline // []) | join(" ")] | join("\n")
        else (.cmdline // []) | join(" ") end),
        active: (.is_active // false)
      }
  ]
' <<< "$data")

if [[ "$windows" == '[]' ]]; then
  echo "window-picker: no other windows in scope '$scope' (try 'global' for all tabs)." >&2
  exit 0
fi

# Store only display metadata, not the environment included in Kitty's ls output.
details=$(mktemp)
trap 'rm -f -- "$details"' EXIT
printf '%s\n' "$windows" > "$details"

rows=$(jq -r --arg home "$HOME" '
  def clean: gsub("[\u0000-\u001f\u007f-\u009f]"; " ");
  def column($width):
    clean | if length > $width then .[:($width - 1)] + "…"
    else . + (" " * ($width - length)) end;
  def short_cwd:
    if . == $home then "~"
    elif startswith($home + "/") then "~" + .[($home | length):]
    else . end;
  .[]
  | (["36", "35", "33", "32", "34", "31"][((.tab_number - 1) % 6)]) as $color
  | [
      (.id | tostring),
      ("\u001b[" + $color + "m" +
        (("O" + (.os_id | tostring) + "/T" + (.tab_number | tostring) +
          " #" + (.tab_id | tostring) + " " + .tab_title) | column(30)) + "\u001b[0m"),
      (((if .active then "*" else " " end) + "W" + (.window_number | tostring) +
        " #" + (.id | tostring)) | column(11)),
      (.title | column(32)),
      (.cwd | short_cwd | column(36)),
      (.program | clean)
    ]
  | join("\t")
' <<< "$windows")

preview_filter='
  def clean: gsub("[\u0000-\u0008\u000b-\u001f\u007f-\u009f]"; " ");
  .[] | select(.id == $id)
  | "OS:       \(.os_id)\nTab:      \(.tab_number) (id=\(.tab_id))\nTab name: \(.tab_title)\nWindow:   \(.window_number) (id=\(.id))\nTitle:    \(.title)\nCWD:      \(.cwd)\n\nForeground command(s):\n\(.command)"
  | clean
'
printf -v preview_command 'jq -r --argjson id {1} %q %q' "$preview_filter" "$details"

if selected=$(fzf \
  --ansi \
  --delimiter=$'\t' \
  --with-nth=2.. \
  --reverse \
  --border \
  --no-sort \
  --prompt="${scope}> " \
  --header=$'TAB (OS/number/id/name)          WINDOW      TITLE                            CWD                                  APP\n* = active window in its tab | Enter: focus | Ctrl-/: preview | Esc: cancel' \
  --with-shell='bash -c' \
  --preview="$preview_command" \
  --preview-window='down,40%,wrap' \
  --bind='ctrl-/:toggle-preview' <<< "$rows"); then
  id="${selected%%$'\t'*}"
  kitten @ focus-window --match "id:$id"
else
  status=$?
  case "$status" in
    1|130) exit 0 ;;
    *) exit "$status" ;;
  esac
fi


帮我看这个脚本，有没有问题，并解释一下
