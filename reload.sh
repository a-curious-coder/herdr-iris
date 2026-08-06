#!/bin/bash
# Iris: regenerate $data_file and print the fresh display list, for fzf's
# reload() action (bound to ctrl-r) to swap in as the new candidate list.
set -euo pipefail
script_dir="$1"
data_file="$2"
bash "$script_dir/build-rows.sh" > "$data_file"
awk -F'\t' '{printf "%-14s  %s\n", $3, $2}' "$data_file"
