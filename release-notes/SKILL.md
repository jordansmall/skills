---
name: release-notes
description: Create or update RELEASE_NOTES.md — a skimmable, human-readable highlights file distilled from CHANGELOG.md (or git history between version tags), one section per released version. Use whenever the user wants release notes written, refreshed or extended for a new tag, a "what's new in vX" write-up, or a changelog turned into something a regular person can read — even if they don't say "release notes".
---

# Release notes

Produce a `RELEASE_NOTES.md` that a regular person can skim: one section per
released version, each with a plain-language summary of what actually changed.
It's the readable companion to `CHANGELOG.md`, not a replacement. Point people
at the changelog for the full commit-level record.

## First: create or update?

Check whether `RELEASE_NOTES.md` already exists.

- **Doesn't exist:** write the whole file (preamble plus every released
  version).
- **Exists:** only add sections for released versions it's missing, in the
  right position (newest first). Leave the preamble and existing sections
  byte-for-byte alone. People hand-edit release notes, and silently rewriting
  their wording is the fastest way to make the skill untrustworthy. If an
  existing section looks factually wrong, say so in your reply instead of
  fixing it, unless the user asked for a rewrite.

## What counts as a release

A version is released when it has a git tag. Get the list with
`git tag --sort=-v:refname` and keep only version-shaped tags. Every released
tag gets exactly one section, newest first.

Commits after the newest tag are unreleased. Leave them out. Notes describe
what people can actually install, and an "Unreleased" section goes stale the
moment the next tag lands. Mention in your reply that there's unreleased work
if there's a lot of it.

**Dates:** prefer the date in the changelog's version header (that's what the
release tooling published). Fall back to the tag date
(`git log -1 --format=%cs <tag>`) when there's no changelog.

## Where the content comes from

Use `CHANGELOG.md` when there is one. Common shapes: release-please /
conventional-changelog (`## [X.Y.Z](compare-link) (date)` with `### Features`,
`### Bug Fixes`, `### ⚠ BREAKING CHANGES` subsections) and Keep a Changelog
(`## [X.Y.Z] - date` with `### Added/Changed/Fixed/Removed`). Without a
changelog, use `git log --format='%h %s%n%b' <prev-tag>..<tag>` per version;
for the oldest tag, use everything up to it.

**Breaking changes** come from, in order of trust:

1. A `⚠ BREAKING CHANGES` subsection in the changelog.
2. A `!` after the type/scope in a commit subject (`feat!:`, `fix(api)!:`).
3. A `BREAKING CHANGE:` or `BREAKING-CHANGE:` footer in a commit body.
4. Keep a Changelog `### Removed` entries, and `### Changed` entries that
   clearly alter existing behaviour or interfaces. Use judgement here; this is
   the only signal that isn't explicit.

Don't invent breaking changes from feature size, and don't drop one just
because it seems minor. If the source says breaking, it's breaking.

## Large changelogs: fan out

A real changelog is big and mostly noise. If it's more than a few hundred
lines, don't read it all into your own context. Grep the version headers to
get line ranges, then fan out parallel sub-agents, one per version or small
range of versions. Sub-agents don't see this skill, so give each one:

- The exact line range (or tag range) to read, and the repo path.
- The keep/cut rules and the tone rules below (paste them in).
- This return format, per version, so assembly is mechanical:

  ```
  VERSION: X.Y.Z
  DATE: YYYY-MM-DD
  THEME: <one line>
  BREAKING: none | <short reason>
  HIGHLIGHTS:
  - **Label.** One or two plain sentences.
  ```

Then assemble, and do a final consistency pass over voice, label style and
punctuation, since several authors wrote the pieces. Sub-agents sometimes
embellish (a motive, an example command, a number) that the changelog never
states, so spot-check concrete specifics against the source before they go in.

For a small changelog (or an update adding one or two versions), just read the
relevant slice yourself.

## Structure

Newest version first. Each version section is:

```
## X.Y.Z — YYYY-MM-DD

<one-line theme: what this release was mostly about>

<breaking-change status line>

- **Short label.** Plain-language highlight, grouped and translated.
- ...
```

- **Header:** version without the `v` prefix, an em-dash, then the date.
- **Theme:** one line naming what the release was about. This is what someone
  remembers the version by.
- **Breaking status:** every version says up front whether it has breaking
  changes, exactly one of:
  - `No breaking changes.`
  - `**⚠ Breaking changes** this release: <short reason>.`
- **Highlights:** 2–7 bullets. Fewer for small releases. A tiny release can
  swap the bullets for a one-paragraph blurb, but it still keeps its theme and
  breaking-status lines, so every section scans the same way. Lead each bullet
  with a short bold label ending in a period, then a sentence or two in plain
  terms.

Flag the actual breaking items inline too, written exactly like this:

```
- **⚠ Breaking: `count` is now `tally`.** Update scripts and aliases that
  call `tallyho count`.
```

Every version with a breaking status line has at least one such bullet, and
versions with `No breaking changes.` have none. For each breaking bullet, say
what the reader may need to do, if anything. In update mode, if the existing
file already uses a different breaking-bullet style, match it instead.

## What to keep and what to cut

Keep what changed for someone *using* the tool. Group related commits into one
highlight and translate jargon into the outcome ("git calls can't hang" beats
"added context timeouts to git subprocess invocations").

Cut the noise: internal refactors, test-only changes, doc tidying, formatting
sweeps, CI, dependency and schema-regeneration bumps. The exception is when a
cluster of small changes adds up to something a user would notice; then say
that.

Don't enumerate what you left out. The preamble shouldn't list "omits
refactors, tests, dep bumps"; it's obvious and reads like filler.

## Preamble

Short. A line on what the tool is and who the notes are for, then:

- Point at `CHANGELOG.md` for the full detail (or the git history, if there's
  no changelog).
- Explain the **⚠ Breaking** tag, and say a breaking change *may* need a change
  on your end depending on how you use the tool; it won't affect everyone.

## Tone

Business-casual, like a developer leaving a note for teammates. Be to the
point; add detail only where it helps.

**Hard-wrap prose at 80 columns**, with bullet continuation lines indented two
spaces to line up under the bullet text. The file gets read raw in terminals,
editors and diffs as often as it gets rendered, and long lines are miserable
there. Headers and lines that are mostly a URL can run long. In update mode,
wrap the sections you add even if older sections aren't wrapped.

Avoid the usual LLM tells:

- Overly formal or passive phrasing.
- Exhaustive enumeration of every change (that's what the changelog is for).
- Restating the diff, or internal identifiers a user never sees (ADR numbers,
  issue numbers, internal type and function names).
- Marketing words: "seamless", "robust", "powerful", "enhanced experience".
- **Em-dashes in prose.** The em-dash appears only as the date separator in a
  version header. Anywhere else, a comma, period, colon, or parentheses reads
  better.

## Before finishing

- **Versions:** `grep -E '^## [0-9]' RELEASE_NOTES.md` matches
  `git tag --sort=-v:refname` (minus the `v`): same versions, same order, one
  section each, no unreleased section.
- **Breaking consistency:** each version's status line agrees with its bullets.
- **Em-dashes:** `grep -o '—' RELEASE_NOTES.md | wc -l` equals the number of
  version sections.
- **Wrapping:** `awk 'length > 80' RELEASE_NOTES.md` shows only headers or URL
  lines (plus untouched older sections in update mode).
- **Update mode:** `git diff RELEASE_NOTES.md` shows only added lines.
