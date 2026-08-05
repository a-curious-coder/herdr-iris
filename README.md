# Iris

<p align="center">
  <a href="https://github.com/a-curious-coder/herdr-iris/blob/main/LICENSE"><img src="https://shieldcn.dev/badge/license-MIT-4385BE.svg?variant=secondary" alt="License: MIT" /></a>
  <a href="https://herdr.dev"><img src="https://shieldcn.dev/badge/herdr-plugin-4385BE.svg?variant=secondary" alt="herdr plugin" /></a>
  <img src="https://shieldcn.dev/badge/bash-121011.svg?logo=gnu-bash&variant=secondary" alt="Bash" />
  <a href="https://github.com/a-curious-coder/herdr-iris/commits/main"><img src="https://shieldcn.dev/github/last-commit/a-curious-coder/herdr-iris.svg?variant=secondary" alt="Last commit" /></a>
</p>

A [herdr](https://herdr.dev) plugin: a fuzzy cheatsheet of AI agent skills/rules, scoped to the agent running in the pane you opened it from. Named for Iris — messenger goddess of the rainbow, who carries messages between gods and mortals — because that's exactly what it does with a skill's invocation: carries it from the list straight into your pane.

## What it does

Press a key, get a searchable list of every AI agent skill available to you — name and full description — filtered to whichever agent herdr detects on the pane you're in. Select one and it types the invocation straight into that pane.

- **Scoped by agent.** If herdr reports the focused pane's agent (e.g. `claude`), only that agent's skills show. If it can't detect one, every agent with a known skill source shows, grouped.
- **Reads real sources, not guesses.** Claude Code's `SKILL.md` frontmatter (personal `~/.claude/skills`, project-local `.claude/skills`, and every *enabled* plugin's bundled skills, correctly namespaced as `plugin-name:skill-name`) and Cursor's `.cursor/rules/*.mdc`. Every other agent herdr recognizes gets no entry at all rather than a guessed-at file format — no filler rows for agents with nothing to show.
- **Vim-like search.** Nothing types into the query box until you press `/`. Search is literal substring matching, not fuzzy.
- **Full descriptions, properly wrapped.** Shown by default in a preview pane, word-wrapped to the pane's actual width — including multi-line YAML block-scalar (`description: >`) frontmatter, which is how most plugin-bundled skills write theirs.
- **Enter types it for you.** Selecting a skill sends its invocation (`/name` for Claude, `$name` for Codex) as literal text into the originating pane — it doesn't press Enter for you, so you always get a chance to review before running it.

## Requirements

- [herdr](https://herdr.dev) 0.7.0+
- [fzf](https://github.com/junegunn/fzf) — falls back to a plain listing if missing, but you lose search/preview/Enter-to-type
- [jq](https://jqlang.org)

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

Bind a key to open it, in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+shift+k"
type = "pane"
command = "herdr plugin pane open --plugin cmc.iris --entrypoint list --placement popup"
description = "skills cheatsheet (Iris)"
```

| Key | Action |
|---|---|
| `/` | Start searching (literal substring, not fuzzy) |
| `?` | Toggle the description preview |
| `↑`/`↓`, `Ctrl-N`/`Ctrl-P` | Move the selection |
| `Enter` | Type the selected skill's invocation into the pane you opened Iris from |
| `q`, `Esc` | Close without typing anything |

## Supported agents

| Agent | Source | Status |
|---|---|---|
| Claude Code | `SKILL.md` frontmatter — personal, project-local, and enabled plugins | Full support |
| Cursor | `.cursor/rules/*.mdc` frontmatter | Best-effort |
| Everything else herdr recognizes (codex, gemini, opencode, copilot, cline, devin, droid, amp, grok, kimi, kiro, kilo, qoder, qodercli, pi, hermes) | — | No verified skills-file convention yet — contributes nothing rather than a guess |

Adding a new agent is one function: a `list_<agent>` function plus a matching `case` arm in `list-skills.sh`.

## License

[MIT](LICENSE)
