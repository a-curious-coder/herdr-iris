#!/usr/bin/env bash
# Self-check for build-rows.sh's frontmatter_fields() — the only non-trivial
# pure logic in this plugin (block-scalar folding, quote-stripping,
# field-order independence). No framework: run this directly.
#
# Sources just the function's definition out of build-rows.sh (rather than
# duplicating its body here, or sourcing the whole file — which would run
# build-rows.sh's top-level side effects: shelling out to detect-origin.sh,
# reading the skill-lock file and settings files). Verified this extraction
# matches a live call before relying on it.
set -uo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source <(sed -n '/^frontmatter_fields()/,/^}/p' "$script_dir/build-rows.sh")

failures=0

assert_eq() { # $1 expected $2 actual $3 case description
  if [[ "$1" != "$2" ]]; then
    echo "FAIL: $3"
    echo "  expected: [$1]"
    echo "  actual:   [$2]"
    failures=$((failures + 1))
  fi
}

check() { # $1 case description $2 file content $3 expected name $4 expected desc
  local f
  f=$(mktemp)
  printf '%s' "$2" > "$f"
  IFS=$'\x1f' read -r name desc < <(frontmatter_fields "$f")
  assert_eq "$3" "$name" "$1 (name)"
  assert_eq "$4" "$desc" "$1 (desc)"
  rm -f "$f"
}

check "one-line unquoted field" \
"---
name: one-liner
description: a plain description
---
body" \
"one-liner" "a plain description"

check "block-scalar folding" \
"---
name: block-skill
description: >
  A description
  that wraps across
  multiple lines.
---
body" \
"block-skill" "A description that wraps across multiple lines."

check "reordered fields" \
"---
description: desc comes first here
name: reordered-skill
---
body" \
"reordered-skill" "desc comes first here"

check "missing description" \
"---
name: no-desc-skill
metadata:
  type: test
---
body" \
"no-desc-skill" ""

check "quoted one-line value" \
"---
description: \"A quoted description\"
name: quoted-skill
---
body" \
"quoted-skill" "A quoted description"

check "no frontmatter delimiters at all" \
"just a plain markdown file
with no frontmatter block" \
"" ""

if [[ "$failures" -eq 0 ]]; then
  echo "test-frontmatter.sh: all checks passed"
  exit 0
else
  echo "test-frontmatter.sh: $failures failure(s)"
  exit 1
fi
