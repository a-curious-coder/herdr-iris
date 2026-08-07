#!/bin/bash
# Iris: the skill row's one owner.
#
# build-rows.sh emits tab-separated skill rows (agent, name, author, desc,
# path). list-skills.sh, open-skill.sh, and preview.sh each need to look up
# one field of the row a user has selected, by (name, author). Source this
# file and call skill_row_field instead of writing another awk -F'\t' lookup
# — the column order is private to this file, not duplicated at each call
# site (it changed once already, in the "drop agent column" commit).
#
# Only agent/desc/path are supported: name and author are lookup keys, never
# fetched back, so there's no caller for those two as values.
skill_row_field() { # $1 data_file $2 name $3 author $4 field(agent|desc|path)
  local data_file="$1" name="$2" author="$3" field="$4" col
  case "$field" in
    agent) col=1 ;;
    desc) col=4 ;;
    path) col=5 ;;
    *) return 1 ;;
  esac
  awk -F'\t' -v n="$name" -v a="$author" -v c="$col" \
    '$2 == n && $3 == a { print $c; exit }' "$data_file"
}
