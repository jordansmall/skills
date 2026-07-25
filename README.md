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
- **release-notes** — turn a `CHANGELOG.md` into a skimmable `RELEASE_NOTES.md`,
  one section per version with a theme, a breaking-change status line, and
  plain-language highlights.

## Adding a skill

Create `<name>/SKILL.md`, commit it, then link it in:

```sh
ln -s ~/dev/src/jordansmall/skills/<name> ~/.claude/skills/<name>
```
