#!/bin/bash
# Iris: print "origin_pane\tfocused_agent\torigin_cwd\treason" for the pane
# that opened this popup. Shared by list-skills.sh (needs it for the header
# and the Enter-to-type target) and build-rows.sh (needs it for scoping) so
# there's exactly one place that knows how pane/agent detection works.
#
# `reason` is empty on success — including the legitimate "found the pane,
# it just has no agent" case (README's documented unscoped mode). It's only
# set when detection itself broke: no-herdr, no-jq, no-focused-pane. Callers
# that don't care (build-rows.sh) just discard the field; list-skills.sh
# surfaces it in the header so a broken detection doesn't look identical to
# a normal unscoped popup.
#
# ponytail: placement="popup" panes never receive $HERDR_PANE_ID (confirmed
# against herdr.dev/docs/plugins/ — a popup "has no pane ID"), and the
# context JSON's `focused_pane_id` proved unreliable (returned pane IDs
# that didn't exist in `herdr pane list` on two separate live runs). So:
# `herdr pane list`'s own `.focused == true` row is the only source —
# herdr's docs guarantee a popup "does not change plugin focus context",
# so the pane you pressed the key from stays marked focused throughout.
set -euo pipefail

origin_pane=""
origin_cwd=""
focused_agent=""
reason=""

# ponytail: no $HERDR_BIN_PATH fallback here — confirmed (env-probed a live
# plugin pane) that herdr always injects its own bin dir onto PATH for any
# genuine plugin pane, which is the only context this script ever runs in.
# The PATH-lookup bug fixed elsewhere this session was in the keybinding's
# raw subprocess, a context this script never executes in.
if ! command -v herdr >/dev/null 2>&1; then
  reason="no-herdr"
elif ! command -v jq >/dev/null 2>&1; then
  reason="no-jq"
else
  panes_json=$(herdr pane list 2>/dev/null || true)
  origin_pane=$(jq -r '.result.panes[]? | select(.focused == true) | .pane_id' <<<"$panes_json" 2>/dev/null | head -n1 || true)
  if [[ -z "$origin_pane" ]]; then
    reason="no-focused-pane"
  else
    origin_cwd=$(jq -r --arg pid "$origin_pane" \
      '.result.panes[]? | select(.pane_id == $pid) | (.foreground_cwd // .cwd // empty)' <<<"$panes_json" 2>/dev/null || true)
    focused_agent=$(jq -r --arg pid "$origin_pane" \
      '.result.panes[]? | select(.pane_id == $pid) | .agent // empty' <<<"$panes_json" 2>/dev/null || true)
  fi
fi

# ponytail: unit separator, not a tab — bash `read` collapses consecutive
# IFS-whitespace delimiters (tab counts as whitespace even when it's the
# only char in IFS), which silently drops empty fields and shifts the rest.
printf '%s\x1f%s\x1f%s\x1f%s\n' "$origin_pane" "$focused_agent" "$origin_cwd" "$reason"
