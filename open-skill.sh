#!/bin/bash
# Athenaeum: open the selected skill's file in the user's editor.
# Invoked by fzf's execute() (bound to 'o') — fzf switches to the alternate
# screen for this, so a full-screen editor like nvim works normally, and
# fzf resumes the same list on its own once the editor exits.
data_file="$1"
name="$2"
author="$3"
path=$(awk -F'\t' -v n="$name" -v a="$author" '$2 == n && $3 == a { print $5; exit }' "$data_file")
[[ -n "$path" && -f "$path" ]] || exit 0
"${VISUAL:-${EDITOR:-vi}}" "$path"
