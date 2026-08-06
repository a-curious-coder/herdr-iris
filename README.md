# Iris

<p align="center">
  <a href="https://github.com/a-curious-coder/herdr-iris/blob/main/LICENSE"><img src="https://shieldcn.dev/badge/license-MIT-4385BE.svg?variant=secondary" alt="License: MIT" /></a>
  <a href="https://herdr.dev"><img src="https://shieldcn.dev/badge/herdr-plugin-4385BE.svg?variant=secondary" alt="herdr plugin" /></a>
  <img src="https://shieldcn.dev/badge/bash-121011.svg?logo=gnu-bash&variant=secondary" alt="Bash" />
  <a href="https://github.com/a-curious-coder/herdr-iris/commits/main"><img src="https://shieldcn.dev/github/last-commit/a-curious-coder/herdr-iris.svg?variant=secondary" alt="Last commit" /></a>
</p>

Iris is a plugin for [herdr](https://herdr.dev). Iris shows a searchable list of your AI agent skills. Iris types the skill you select into your pane.

The name comes from Iris, the Greek messenger goddess. Iris carries a skill's name from the list into your pane, the same way.

## What Iris does

Press a key. Iris opens a list of skills. The list shows the skills for the agent in your pane. Select a skill. Iris types the skill into that pane.

- Scoped to your agent, or grouped by agent if herdr can't detect one
- Reads real skill files: Claude Code's `SKILL.md`, Cursor's `.cursor/rules`
- Search by name or author, literal text, not fuzzy (`/`)
- Real author, not a guess: the skill-installer's own record, or "you"
- Full description, word-wrapped, in a preview pane (`?`)
- Edit a skill in your own editor (`o`), reload the list after (`Ctrl-R`)
- Types the skill into your pane, doesn't run it for you (`Enter`)
- Hides a skill you've turned off (`skillOverrides`)

Full detail on each of these: [FEATURES.md](FEATURES.md).

## Requirements

- [herdr](https://herdr.dev), version 0.7.0 or later.
- [fzf](https://github.com/junegunn/fzf) and [jq](https://jqlang.org). `herdr plugin install` installs both for you, through Homebrew, apt, dnf, or pacman (see `install-deps.sh`). If none of these tools are on your machine, install stops and shows you the one command to run by hand. Without fzf, Iris still shows the list, as plain text. Without fzf, search, the preview, edit, reload, and type-to-pane do not work.

## Install

```
herdr plugin install a-curious-coder/herdr-iris
```

### Local development

```
git clone https://github.com/a-curious-coder/herdr-iris.git
herdr plugin link ./herdr-iris
```

## Usage

Add a key binding in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+shift+k"
type = "pane"
command = "herdr plugin pane open --plugin cmc.iris --entrypoint list --placement popup"
description = "skills cheatsheet (Iris)"
```

| Key | Action |
|---|---|
| `/` | Start a search, by name or author (literal text, not fuzzy) |
| `?` | Show or hide the description preview |
| `o` | Open the skill's file in your editor. Close the editor to return to the list |
| `Ctrl-R` | Rebuild the list from disk |
| `↑`/`↓`, `Ctrl-N`/`Ctrl-P` | Move the selection up or down |
| `Enter` | Type the selected skill into the pane you opened Iris from |
| `q`, `Esc` | Close Iris. Type nothing |

## Supported agents

| Agent | Skill source | Status |
|---|---|---|
| Claude Code | `SKILL.md` frontmatter: personal, project, and enabled plugins | Full support |
| Cursor | `.cursor/rules/*.mdc` frontmatter | Best effort |
| Every other agent herdr recognizes (codex, gemini, opencode, copilot, cline, devin, droid, amp, grok, kimi, kiro, kilo, qoder, qodercli, pi, hermes) | None found | No confirmed skill file format yet |

To add a new agent: write a `list_<agent>` function in `build-rows.sh`. Add a matching case to `collect_for`.

## License

Iris uses the [MIT license](LICENSE).
