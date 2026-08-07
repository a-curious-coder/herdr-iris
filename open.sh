#!/usr/bin/env bash
# Action `cmc.iris.open`: opens the `list` popup pane (see herdr-plugin.toml).
#
# Runs on the herdr server (no TTY, and only the server's own minimal PATH —
# see detect-origin.sh's ponytail note for why that matters), so it re-execs
# via $HERDR_BIN_PATH rather than a bare `herdr` lookup on PATH.
set -uo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"

exec "$herdr_bin" plugin pane open \
  --plugin cmc.iris \
  --entrypoint list \
  --placement popup
