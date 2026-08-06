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

- **Iris scopes the list to your agent.** herdr reports which agent runs in your pane, for example `claude`. Iris shows only that agent's skills. If herdr reports no agent, Iris shows every agent's skills, grouped by agent.
- **Iris reads real skill files, not guesses.** For Claude Code, Iris reads `SKILL.md` frontmatter. Iris reads three sources: your personal skills folder (`~/.claude/skills`), the current project's skills folder (`.claude/skills`), and every enabled plugin's skills. Iris marks each plugin skill with its plugin name, for example `plugin-name:skill-name`. For Cursor, Iris reads `.cursor/rules/*.mdc` frontmatter. For every other agent herdr recognizes, Iris shows nothing. Iris does not guess at a file format it has not confirmed.
- **Search is literal, not fuzzy.** Press `/` to start a search. Before you press `/`, no key types into the search box. Iris matches your search text against the skill's name and its author, as plain substrings.
- **Iris shows a real author, not a guess.** SKILL.md has no author field. Iris does not read an author field from a skill file. For a personal skill, Iris checks the skill-installer tool's own record (`~/.agents/.skill-lock.json`). If that record names a source repo, Iris shows the repo owner as the author. If not, Iris shows "you". For a plugin skill, Iris shows the owner of the plugin's marketplace repo.
- **Iris shows the full description, wrapped to fit.** The description shows by default, in a preview pane next to the list. Iris wraps the text at whole words, to the preview pane's real width. Iris also reads a multi-line YAML description (`description: >`), which most plugin skills use.
- **Press `o` to edit a skill.** Iris opens the skill's file in your editor (`$VISUAL`, then `$EDITOR`, then `vi`). Close the editor. Iris shows the list again. Claude Code does not need a restart to see your edit. Claude Code watches its skill folders. Claude Code reads a changed `SKILL.md` file during the same session. This is documented behavior, not a guess (see [Claude Code's skills docs](https://code.claude.com/docs/en/skills)).
- **Press `Ctrl-R` to reload the list.** Iris built its list once, when you opened it. Iris does not update that list on its own. Press `Ctrl-R` after you edit, rename, or add a skill, to see the change in the list.
- **Press `Enter` to type the skill into your pane.** Iris adds the right prefix for the agent: `/` for Claude, `$` for Codex. Iris types this text into the pane you opened Iris from. Iris does not press Enter for you. You choose when to run it.
- **Iris hides a skill you turned off.** Claude Code hides a skill set to `"off"` in `skillOverrides`. Claude Code also refuses to run that skill by name. Iris checks the same setting before it builds the list. Iris checks your project settings first, then your personal settings. Iris hides an "off" skill the same way. Iris still shows a skill set to `"user-invocable-only"`. That setting exists for a person to type the skill's name by hand.

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
