#!/bin/bash
# Iris preview: print the full description for the row under the cursor.
# Shown by default; '?' just toggles it off/on. Word-wrapped ourselves via
# `fmt` at the preview pane's actual width ($FZF_PREVIEW_COLUMNS, set by fzf)
# because fzf's own --preview-window wrap is a character wrap, not a word
# wrap, and was cutting words in half mid-line.
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/skill-row.sh"

data_file="$1"
name="$2"
author="$3"
desc=$(skill_row_field "$data_file" "$name" "$author" desc)
printf '%s' "$desc" | fmt -w "${FZF_PREVIEW_COLUMNS:-60}"
