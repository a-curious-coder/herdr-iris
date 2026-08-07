#!/bin/bash
# Iris: open the selected skill's file in the user's editor.
# Invoked by fzf's execute() (bound to 'o') — fzf switches to the alternate
# screen for this, so a full-screen editor like nvim works normally, and
# fzf resumes the same list on its own once the editor exits.
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/skill-row.sh"

data_file="$1"
name="$2"
author="$3"
path=$(skill_row_field "$data_file" "$name" "$author" path)
[[ -n "$path" && -f "$path" ]] || exit 0
"${VISUAL:-${EDITOR:-vi}}" "$path"
