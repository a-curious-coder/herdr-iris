#!/bin/bash
# Iris: print "origin_pane\tfocused_agent\torigin_cwd" for the pane that
# opened this popup. Shared by list-skills.sh (needs it for the header and
# the Enter-to-type target) and build-rows.sh (needs it for scoping) so
# there's exactly one place that knows how pane/agent detection works.
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
if command -v herdr >/dev/null 2>&1; then
  panes_json=$(herdr pane list 2>/dev/null || true)
  origin_pane=$(jq -r '.result.panes[]? | select(.focused == true) | .pane_id' <<<"$panes_json" 2>/dev/null | head -n1 || true)
  if [[ -n "$origin_pane" ]]; then
    origin_cwd=$(jq -r --arg pid "$origin_pane" \
      '.result.panes[]? | select(.pane_id == $pid) | (.foreground_cwd // .cwd // empty)' <<<"$panes_json" 2>/dev/null || true)
    focused_agent=$(jq -r --arg pid "$origin_pane" \
      '.result.panes[]? | select(.pane_id == $pid) | .agent // empty' <<<"$panes_json" 2>/dev/null || true)
  fi
fi

printf '%s\t%s\t%s\n' "$origin_pane" "$focused_agent" "$origin_cwd"
