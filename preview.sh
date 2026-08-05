#!/bin/bash
# Athenaeum preview: print the full description for the row under the cursor.
# Shown by default; '?' just toggles it off/on. Word-wrapped ourselves via
# `fmt` at the preview pane's actual width ($FZF_PREVIEW_COLUMNS, set by fzf)
# because fzf's own --preview-window wrap is a character wrap, not a word
# wrap, and was cutting words in half mid-line.
data_file="$1"
agent="$2"
name="$3"
desc=$(awk -F'\t' -v a="$agent" -v n="$name" '$1 == a && $2 == n { print $3; exit }' "$data_file")
printf '%s' "$desc" | fmt -w "${FZF_PREVIEW_COLUMNS:-60}"
