# skills

Jordan Small's personal [Claude Code](https://claude.com/claude-code) skills.
Each subdirectory is one skill — a `SKILL.md` with YAML frontmatter — symlinked
into `~/.claude/skills/` so Claude Code picks it up.

This is the canonical home for my own skills. New skills go here (not in any
shared or third-party skills repo), get committed, then symlinked into
`~/.claude/skills/`.

## Skills

- **commit** — write git commit messages in strict Conventional Commits v1.0.0
  with hard line wraps.
- **orchestrate-issues** — orchestrate an AFK agent fleet that clears
  `ready-for-agent` GitHub issues end to end: order by dependency, then per
  issue claim, scout, build test-first, review, and merge.
- **principle-fix-root-causes** — when debugging, trace each symptom to its root
  cause and fix it there; reproduce first, ask why until you reach it, and
  resist guards that only silence the crash.
- **principle-laziness-protocol** — bias toward deletion, a flat call hierarchy,
  and the smallest diff that solves the problem; question every new signal
  threaded through a layer.
- **principle-redesign-from-first-principles** — when integrating a new
  requirement, redesign as if it had been a foundational assumption from day
  one instead of bolting it on.
- **release-notes** — turn a `CHANGELOG.md` into a skimmable `RELEASE_NOTES.md`,
  one section per version with a theme, a breaking-change status line, and
  plain-language highlights.

## Adding a skill

Create `<name>/SKILL.md`, commit it, then link it in:

```sh
ln -s ~/dev/src/jordansmall/skills/<name> ~/.claude/skills/<name>
```

## Provenance

The three `principle-*` skills are adapted from the [`pstack`
plugin](https://github.com/cursor/plugins/tree/main/pstack), MIT licensed —
the notice travels with them in [`LICENSES/pstack-MIT.txt`](LICENSES/pstack-MIT.txt).

The guidance is unchanged. The one edit is dropping each skill's
`disable-model-invocation: true` frontmatter field, which would otherwise make
the skill invocable only by a human typing `/name` — never by Claude itself, and
never [preloaded into a subagent](https://code.claude.com/docs/en/sub-agents).
That field exists for workflows with side effects you want to time yourself
(`/deploy`, `/commit`); an advisory principle has none, and is worth loading
precisely when Claude recognizes the situation it describes. Dropping it is also
what lets these skills bake into a headless agent harness, where there is no
human to type the slash command.
