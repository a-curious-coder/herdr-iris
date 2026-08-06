#!/bin/bash
# Iris: fuzzy cheatsheet of AI agent skills/rules.
# Scoped to the focused pane's detected agent when herdr reports one;
# otherwise lists every agent's skills, grouped and labelled.
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

IFS=$'\t' read -r origin_pane focused_agent _ < <(bash "$script_dir/detect-origin.sh")
rows=$(bash "$script_dir/build-rows.sh")

if [[ -z "$rows" ]]; then
  echo "No skills found${focused_agent:+ for agent '$focused_agent'}."
  read -r -p "Press enter to close..." _
  exit 0
fi

# Prefix each agent uses to invoke a skill by name. Only add an entry here
# once it's confirmed — an unmapped agent just means Enter won't type
# anything back, not a guess at wrong syntax.
prefix_for_agent() {
  case "$1" in
    claude) printf '/' ;;
    codex) printf '$' ;;
  esac
}

if command -v fzf >/dev/null 2>&1; then
  data_file=$(mktemp "${TMPDIR:-/tmp}/iris-rows.XXXXXX")
  trap 'rm -f "$data_file"' EXIT
  printf '%s\n' "$rows" > "$data_file"

  # Vim-like: no input box at all until '/' summons it (--no-input hides the
  # box and its cursor, not just the filtering — nothing types until then).
  # 'q' quits like 'esc' while browsing; once '/' is pressed it's rebound
  # back to a normal query character (so searching for the "qa" skill works).
  # layout=reverse-list keeps the list top-down (a→z at top) while the
  # prompt itself stays pinned to the bottom of the screen, like vim's own
  # '/' command line, instead of a boxed search bar up top.
  # No agent column: when scoped to one agent it's constant (already in the
  # header), and when unscoped it's still tracked in $data_file for the
  # Enter/preview lookups below, just not worth a visible column.
  # 'o' opens the skill's file in $VISUAL/$EDITOR (falls back to vi) via
  # fzf's execute() — switches to the alternate screen for the editor, then
  # returns to this same list once it exits. 'ctrl-r' re-runs build-rows.sh
  # and rewrites $data_file via reload.sh, so editing a skill with 'o' and
  # coming back shows the fresh description without closing the popup.
  # (No refresh is actually required on Claude's side for the change itself
  # to take effect — it watches skill directories and live-detects SKILL.md
  # edits within the session per code.claude.com/docs/en/skills. This reload
  # is purely so *Iris's own list* stops showing what's now a stale snapshot.)
  sel=$(printf '%s\n' "$rows" \
    | awk -F'\t' '{printf "%-14s  %s\n", $3, $2}' \
    | fzf --header="Iris${focused_agent:+ · $focused_agent} · / to search author+name · ? description · o edit · ctrl-r reload" \
          --prompt="/" --no-sort --exact --layout=reverse-list --no-input \
          --bind='q:abort' \
          --bind='/:show-input+enable-search+clear-query+rebind(q)' \
          --bind='?:toggle-preview' \
          --bind="o:execute(bash '$script_dir/open-skill.sh' '$data_file' {2} {1})" \
          --bind="ctrl-r:reload(bash '$script_dir/reload.sh' '$script_dir' '$data_file')" \
          --preview="bash '$script_dir/preview.sh' '$data_file' {2} {1}" \
          --preview-window='right:50%') || true

  if [[ -n "${sel:-}" ]]; then
    author=$(awk '{print $1}' <<<"$sel")
    name=$(awk '{print $2}' <<<"$sel")
    agent=$(awk -F'\t' -v n="$name" -v a="$author" '$2 == n && $3 == a { print $1; exit }' "$data_file")
    prefix=$(prefix_for_agent "$agent")
    if [[ -n "$prefix" && -n "$origin_pane" ]]; then
      herdr pane send-text "$origin_pane" "${prefix}${name}" >/dev/null 2>&1 || true
    fi
  fi
else
  printf '%s\n' "$rows" | awk -F'\t' '{printf "%-8s  %-28s  %-14s  %s\n", $1, $2, $3, $4}'
  read -r -p "Press enter to close..." _
fi
