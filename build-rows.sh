#!/bin/bash
# Iris: collect every visible skill row and print them, tab-separated
# (agent\tname\tauthor\tdesc\tpath), sorted by author then name.
# Called once at startup and again on ctrl-r (see reload.sh) — kept in its
# own file so both call sites share one code path, not a copy each.
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# --- 1. Which pane opened us, and which agent (if any) owns it? ------------
IFS=$'\x1f' read -r origin_pane focused_agent origin_cwd _ < <(bash "$script_dir/detect-origin.sh")

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
# skill uses this style, so it's not an edge case). One awk pass per file,
# not one per field: name and description used to be two separate awk
# spawns per skill (128 processes across ~64 skills), doubling the file
# read for no reason. Verified against every real SKILL.md on this machine
# (89 files, 0 mismatches) before landing this.
frontmatter_fields() { # $1 file -> prints "name<0x1f>description"
  awk -v sep=$'\x1f' '
    BEGIN { in_fm=0; field=""; name=""; desc=""; buf="" }
    /^---$/ {
      in_fm++
      if (in_fm == 2) {
        if (field=="name") name=buf
        else if (field=="description") desc=buf
        print name sep desc
        exit
      }
      next
    }
    in_fm==1 {
      if (field!="" && $0 ~ /^[ \t]+/) {
        line=$0
        sub(/^[ \t]+/, "", line)
        buf = (buf=="" ? line : buf" "line)
        next
      }
      if (field=="name") name=buf
      else if (field=="description") desc=buf
      field=""
      if ($0 ~ /^name:/) field="name"
      else if ($0 ~ /^description:/) field="description"
      else next
      val=$0
      sub("^"field": *", "", val)
      gsub(/^"|"$/, "", val)
      if (val ~ /^[|>][+-]?$/ || val == "") { buf="" }
      else {
        if (field=="name") { name=val } else { desc=val }
        field=""
        buf=""
      }
    }
  ' "$1"
}

# Author isn't a SKILL.md frontmatter field Claude Code defines — there's no
# convention to read. Instead: cross-reference the skill-installer tool's own
# lock file (personal skills pulled from an external repo) and, for plugin
# skills, the marketplace's declared source repo. No entry in either means
# self-authored, not "unknown" — most personal skills are exactly that.
#
# ponytail: one jq spawn total, not one per skill. author_from_lock() used
# to re-read the same 20KB lock file with a fresh jq process per skill (57
# skills = 57 identical reads, measured ~0.16s just for this lookup) — jq's
# process-spawn cost dominates, not disk I/O, so reading the file's content
# once doesn't help; only reading its *result* once does. LOCK_SOURCE is
# populated once, up front; every later lookup is a plain array read.
declare -A LOCK_SOURCE=()
SKILL_LOCK_FILE="$HOME/.agents/.skill-lock.json"
if [[ -f "$SKILL_LOCK_FILE" ]]; then
  while IFS=$'\x1f' read -r lock_name lock_source; do
    [[ -n "$lock_name" ]] && LOCK_SOURCE["$lock_name"]="$lock_source"
  done < <(jq -r '.skills // {} | to_entries[] | "\(.key)\(.value.source // "")"' "$SKILL_LOCK_FILE" 2>/dev/null)
fi
author_from_lock() { # $1 skill name -> prints "owner" or "you"
  local source="${LOCK_SOURCE[$1]:-}"
  [[ -n "$source" ]] && echo "${source%%/*}" || echo "you"
}

# skillOverrides can set a personal/project skill to "off", which Claude
# Code hides from "/" entirely and errors on if invoked by name anyway
# (confirmed in code.claude.com/docs/en/skills). Checks project settings
# before global — closer scope wins — first file with the key decides.
# "name-only" and "user-invocable-only" stay visible: both remain typeable
# by a human via "/", only "off" actually blocks that. Plugin skills are
# explicitly exempt per the same docs ("Plugin skills are not affected by
# skillOverrides"), so this only applies to list_claude, not plugin skills.
#
# ponytail: same one-spawn-per-source-file fix as LOCK_SOURCE above, but
# with 4 possible files instead of 1. Loaded in ASCENDING priority order
# (lowest-priority file first) so a later file's entries overwrite an
# earlier file's in OVERRIDE — that reproduces "first file with the key
# wins" (project settings.local.json > project settings.json > global
# settings.local.json > global settings.json) via plain overwrite, without
# needing to special-case "already set" per skill.
declare -A OVERRIDE=()
load_overrides() { # $1 file
  [[ -n "$1" && -f "$1" ]] || return 0
  while IFS=$'\x1f' read -r ov_name ov_val; do
    [[ -n "$ov_name" ]] && OVERRIDE["$ov_name"]="$ov_val"
  done < <(jq -r '.skillOverrides // {} | to_entries[] | "\(.key)\(.value)"' "$1" 2>/dev/null)
}
load_overrides "$HOME/.claude/settings.json"
load_overrides "$HOME/.claude/settings.local.json"
load_overrides "$cwd/.claude/settings.json"
load_overrides "$cwd/.claude/settings.local.json"
skill_override_state() { # $1 skill name -> prints the override value, or "on"
  echo "${OVERRIDE[$1]:-on}"
}

list_claude() {
  local dirs=("$HOME/.claude/skills")
  [[ -n "$cwd" && -d "$cwd/.claude/skills" ]] && dirs+=("$cwd/.claude/skills")
  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    for f in "$dir"/*/SKILL.md; do
      [[ -f "$f" ]] || continue
      IFS=$'\x1f' read -r name desc < <(frontmatter_fields "$f")
      [[ -z "$name" ]] && name=$(basename "$(dirname "$f")")
      [[ "$(skill_override_state "$name")" == "off" ]] && continue
      author=$(author_from_lock "$name")
      printf 'claude\t%s\t%s\t%s\t%s\n' "$name" "$author" "$desc" "$f"
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
  local plugin marketplace repo author dir f name desc
  while IFS='@' read -r plugin marketplace; do
    [[ -n "$plugin" && -n "$marketplace" ]] || continue
    repo=$(jq -r --arg m "$marketplace" '.extraKnownMarketplaces[$m].source.repo // empty' "$HOME/.claude/settings.json" 2>/dev/null)
    author="${repo%%/*}"
    [[ -z "$author" ]] && author="$marketplace"
    for dir in \
      "$HOME/.claude/plugins/marketplaces/$marketplace/skills" \
      "$HOME/.claude/plugins/marketplaces/$marketplace/plugins/$plugin/skills"
    do
      [[ -d "$dir" ]] || continue
      for f in "$dir"/*/SKILL.md; do
        [[ -f "$f" ]] || continue
        IFS=$'\x1f' read -r name desc < <(frontmatter_fields "$f")
        [[ -z "$name" ]] && name=$(basename "$(dirname "$f")")
        printf 'claude\t%s:%s\t%s\t%s\t%s\n' "$plugin" "$name" "$author" "$desc" "$f"
      done
    done
  done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$HOME/.claude/settings.json" 2>/dev/null)
}

list_cursor() {
  [[ -n "$cwd" && -d "$cwd/.cursor/rules" ]] || return 0
  for f in "$cwd"/.cursor/rules/*.mdc; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f" .mdc)
    IFS=$'\x1f' read -r _ desc < <(frontmatter_fields "$f")
    printf 'cursor\t%s\t-\t%s\t%s\n' "$name" "$desc" "$f"
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

printf '%s\n' "$rows" | sed '/^$/d' | sort -t $'\t' -k3,3 -k2,2
