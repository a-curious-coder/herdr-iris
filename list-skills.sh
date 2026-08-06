#!/bin/bash
# Athenaeum: fuzzy cheatsheet of AI agent skills/rules.
# Scoped to the focused pane's detected agent when herdr reports one;
# otherwise lists every agent's skills, grouped and labelled.
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# --- 1. Which pane opened us, and which agent (if any) owns it? ------------
# ponytail: placement="popup" panes never receive $HERDR_PANE_ID (confirmed
# against herdr.dev/docs/plugins/ — a popup "has no pane ID"), and the
# context JSON's `focused_pane_id` proved unreliable (returned pane IDs
# that didn't exist in `herdr pane list` on two separate live runs). So:
# `herdr pane list`'s own `.focused == true` row is the only source —
# herdr's docs guarantee a popup "does not change plugin focus context",
# so the pane you pressed the key from stays marked focused throughout.
origin_pane=""
origin_cwd=""
if command -v herdr >/dev/null 2>&1; then
  panes_json=$(herdr pane list 2>/dev/null || true)
  origin_pane=$(jq -r '.result.panes[]? | select(.focused == true) | .pane_id' <<<"$panes_json" 2>/dev/null | head -n1 || true)
  [[ -n "$origin_pane" ]] && origin_cwd=$(jq -r --arg pid "$origin_pane" \
    '.result.panes[]? | select(.pane_id == $pid) | (.foreground_cwd // .cwd // empty)' <<<"$panes_json" 2>/dev/null || true)
fi

# herdr pane list gives every pane's .agent field (confirmed via `herdr pane
# list` — see docs/plugins/ for the runtime env vars this reads).
focused_agent=""
if [[ -n "$origin_pane" ]] && command -v herdr >/dev/null 2>&1; then
  focused_agent=$(herdr pane list 2>/dev/null \
    | jq -r --arg pid "$origin_pane" \
      '.result.panes[]? | select(.pane_id == $pid) | .agent // empty' 2>/dev/null || true)
fi

# --- 2. Per-agent skill sources ---------------------------------------------
# ponytail: only Claude (SKILL.md frontmatter) and Cursor (.mdc rule
# frontmatter) have a verified, documented file format as of Aug 2026.
# Every other herdr-recognised agent (codex, gemini, opencode, copilot,
# cline, devin, droid, amp, grok, kimi, kiro, kilo, qoder, qodercli, pi,
# hermes) gets a stub line instead of a guessed-at file format. Add a
# `list_<agent>` function + a case arm below once that agent ships a real
# skills convention worth reading.

cwd="$origin_cwd"

# Handles both `field: value` on one line and a `field: >`/`field: |` block
# scalar (folds continuation lines into one line — every ponytail plugin
# skill uses this style, so it's not an edge case).
frontmatter_field() { # $1 file, $2 field name -> prints value
  awk -v f="$2" '
    BEGIN { in_fm=0; in_block=0; buf="" }
    /^---$/ {
      in_fm++
      if (in_fm == 2 && in_block) { print buf; exit }
      next
    }
    in_fm==1 && in_block {
      if ($0 ~ /^[ \t]+/) {
        line=$0
        sub(/^[ \t]+/, "", line)
        buf = (buf=="" ? line : buf" "line)
        next
      }
      print buf
      exit
    }
    in_fm==1 && $0 ~ "^"f":" {
      val=$0
      sub("^"f": *", "", val)
      gsub(/^"|"$/, "", val)
      if (val ~ /^[|>][+-]?$/ || val == "") { in_block=1; buf=""; next }
      print val
      exit
    }
  ' "$1"
}

list_claude() {
  local dirs=("$HOME/.claude/skills")
  [[ -n "$cwd" && -d "$cwd/.claude/skills" ]] && dirs+=("$cwd/.claude/skills")
  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    for f in "$dir"/*/SKILL.md; do
      [[ -f "$f" ]] || continue
      name=$(frontmatter_field "$f" name)
      [[ -z "$name" ]] && name=$(basename "$(dirname "$f")")
      desc=$(frontmatter_field "$f" description)
      printf 'claude\t%s\t%s\n' "$name" "$desc"
    done
  done
  list_claude_plugin_skills
}

# Plugin skills live outside ~/.claude/skills entirely and are invoked as
# /plugin-name:skill-name (confirmed verbatim in code.claude.com/docs/en/skills:
# "Plugin skills use a plugin-name:skill-name namespace, so they cannot
# conflict with other levels" — a personal skill and a plugin skill sharing
# a base name, e.g. ponytail-review, are two separate, both-typeable
# skills, not a collision to resolve). Only enabled plugins are scanned.
list_claude_plugin_skills() {
  [[ -f "$HOME/.claude/settings.json" ]] || return 0
  local plugin marketplace dir f name desc
  while IFS='@' read -r plugin marketplace; do
    [[ -n "$plugin" && -n "$marketplace" ]] || continue
    for dir in \
      "$HOME/.claude/plugins/marketplaces/$marketplace/skills" \
      "$HOME/.claude/plugins/marketplaces/$marketplace/plugins/$plugin/skills"
    do
      [[ -d "$dir" ]] || continue
      for f in "$dir"/*/SKILL.md; do
        [[ -f "$f" ]] || continue
        name=$(frontmatter_field "$f" name)
        [[ -z "$name" ]] && name=$(basename "$(dirname "$f")")
        desc=$(frontmatter_field "$f" description)
        printf 'claude\t%s:%s\t%s\n' "$plugin" "$name" "$desc"
      done
    done
  done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$HOME/.claude/settings.json" 2>/dev/null)
}

list_cursor() {
  [[ -n "$cwd" && -d "$cwd/.cursor/rules" ]] || return 0
  for f in "$cwd"/.cursor/rules/*.mdc; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f" .mdc)
    desc=$(frontmatter_field "$f" description)
    printf 'cursor\t%s\t%s\n' "$name" "$desc"
  done
}

KNOWN_AGENTS="pi claude codex gemini cursor devin cline opencode copilot kimi kiro droid amp grok hermes kilo qodercli qoder"

collect_for() {
  case "$1" in
    claude) list_claude ;;
    cursor) list_cursor ;;
    *) return 0 ;; # ponytail: no known skill source for this agent yet — contribute nothing, not a filler row
  esac
}

rows=""
if [[ -n "$focused_agent" ]]; then
  rows=$(collect_for "$focused_agent")
else
  for a in $KNOWN_AGENTS; do
    out=$(collect_for "$a")
    [[ -n "$out" ]] && rows+="$out"$'\n'
  done
fi

rows=$(printf '%s\n' "$rows" | sed '/^$/d' | sort -t $'\t' -k2,2)

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
  data_file=$(mktemp "${TMPDIR:-/tmp}/athenaeum-rows.XXXXXX")
  trap 'rm -f "$data_file"' EXIT
  printf '%s\n' "$rows" > "$data_file"

  # Vim-like: no input box at all until '/' summons it (--no-input hides the
  # box and its cursor, not just the filtering — nothing types until then).
  # 'q' quits like 'esc' while browsing; once '/' is pressed it's rebound
  # back to a normal query character (so searching for the "qa" skill works).
  # layout=reverse-list keeps the list top-down (a→z at top) while the
  # prompt itself stays pinned to the bottom of the screen, like vim's own
  # '/' command line, instead of a boxed search bar up top.
  sel=$(printf '%s\n' "$rows" \
    | awk -F'\t' '{printf "%-8s  %s\n", $1, $2}' \
    | fzf --header="Athenaeum${focused_agent:+ · $focused_agent} · / to search · ? to hide description" \
          --prompt="/" --no-sort --exact --layout=reverse-list --no-input --nth=2 \
          --bind='q:abort' \
          --bind='/:show-input+enable-search+clear-query+rebind(q)' \
          --bind='?:toggle-preview' \
          --preview="bash '$script_dir/preview.sh' '$data_file' {1} {2}" \
          --preview-window='right:50%') || true

  if [[ -n "${sel:-}" ]]; then
    agent=$(awk '{print $1}' <<<"$sel")
    name=$(awk '{print $2}' <<<"$sel")
    prefix=$(prefix_for_agent "$agent")
    if [[ -n "$prefix" && -n "$origin_pane" ]]; then
      herdr pane send-text "$origin_pane" "${prefix}${name}" >/dev/null 2>&1 || true
    fi
  fi
else
  printf '%s\n' "$rows" | awk -F'\t' '{printf "%-8s  %-28s  %s\n", $1, $2, $3}'
  read -r -p "Press enter to close..." _
fi
