#!/bin/bash
# Athenaeum preview: print the full description for the row under the cursor.
# Shown by default; '?' just toggles it off/on. Word-wrapped ourselves via
# `fmt` at the preview pane's actual width ($FZF_PREVIEW_COLUMNS, set by fzf)
# because fzf's own --preview-window wrap is a character wrap, not a word
# wrap, and was cutting words in half mid-line.
data_file="$1"
name="$2"
author="$3"
desc=$(awk -F'\t' -v n="$name" -v a="$author" '$2 == n && $3 == a { print $4; exit }' "$data_file")
printf '%s' "$desc" | fmt -w "${FZF_PREVIEW_COLUMNS:-60}"
