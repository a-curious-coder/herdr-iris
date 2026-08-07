# Iris: features in detail

This file has the full detail behind each line in the README's feature list.

## Iris scopes the list to your agent

herdr reports which agent runs in your pane, for example `claude`. Iris shows only that agent's skills. If herdr reports no agent, Iris shows every agent's skills, grouped by agent.

## Iris reads real skill files, not guesses

For Claude Code, Iris reads `SKILL.md` frontmatter. Iris reads three sources: your personal skills folder (`~/.claude/skills`), the current project's skills folder (`.claude/skills`), and every enabled plugin's skills. Iris marks each plugin skill with its plugin name, for example `plugin-name:skill-name`. For Cursor, Iris reads `.cursor/rules/*.mdc` frontmatter. For every other agent herdr recognizes, Iris shows nothing. Iris does not guess at a file format it has not confirmed.

## Search is literal, not fuzzy

Press `/` to start a search. Before you press `/`, no key types into the search box. Iris matches your search text against the skill's name and its author, as plain substrings.

## Iris shows a real author, not a guess

SKILL.md has no author field. Iris does not read an author field from a skill file. For a personal skill, Iris checks the skill-installer tool's own record (`~/.agents/.skill-lock.json`). If that record names a source repo, Iris shows the repo owner as the author. If not, Iris shows "you". For a plugin skill, Iris shows the owner of the plugin's marketplace repo.

## Iris shows the full description, wrapped to fit

The description shows by default, in a preview pane next to the list. Iris wraps the text at whole words, to the preview pane's real width. Iris also reads a multi-line YAML description (`description: >`), which most plugin skills use.

## Press `o` to edit a skill

Iris opens the skill's file in your editor (`$VISUAL`, then `$EDITOR`, then `vi`). Close the editor. Iris shows the list again. Claude Code does not need a restart to see your edit. Claude Code watches its skill folders. Claude Code reads a changed `SKILL.md` file during the same session. This is documented behavior, not a guess (see [Claude Code's skills docs](https://code.claude.com/docs/en/skills)).

## Press `Ctrl-R` to reload the list

Iris built its list once, when you opened it. Iris does not update that list on its own. Press `Ctrl-R` after you edit, rename, or add a skill, to see the change in the list.

## Press `Enter` to type the skill into your pane

Iris adds the right prefix for the agent: `/` for Claude, `$` for Codex. Iris types this text into the pane you opened Iris from. Iris does not press Enter for you. You choose when to run it.

## Iris tells you when detection breaks

Iris finds your focused pane through `herdr`. Iris needs `herdr` and `jq` to do this. If `herdr` is missing, or `jq` is missing, or Iris finds no focused pane, Iris cannot scope the list to your agent. Iris shows "degraded: ..." in the header for this case, with the reason. This message differs from Iris's normal unscoped mode. Iris shows no message in normal unscoped mode. Normal unscoped mode means: Iris found your pane, but herdr reports no agent for it.

## Iris hides a skill you turned off

Claude Code hides a skill set to `"off"` in `skillOverrides`. Claude Code also refuses to run that skill by name. Iris checks the same setting before it builds the list. Iris checks your project settings first, then your personal settings. Iris hides an "off" skill the same way. Iris still shows a skill set to `"user-invocable-only"`. That setting exists for a person to type the skill's name by hand.
