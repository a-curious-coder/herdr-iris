# Context

Domain terms used across this codebase.

## Skill row

One line of `build-rows.sh`'s output: `agent\tname\tauthor\tdesc\tpath`, tab-separated. Represents one discoverable skill/rule file, scoped to whichever agent (Claude, Cursor, ...) it belongs to.

The skill row's schema is owned by `skill-row.sh` — nothing else should parse a row's columns directly. Fetch a field with `skill_row_field <data_file> <name> <author> <field>`, where `field` is `agent`, `desc`, or `path` (the only fields ever fetched by value; `name`/`author` are lookup keys, not values).

`build-rows.sh` is the only writer of skill rows. `reload.sh` and `list-skills.sh`'s own display formatting read every row for rendering (a different concern from single-field lookup) and are not required to go through `skill-row.sh`.
