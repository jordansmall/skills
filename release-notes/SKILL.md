---
name: release-notes
description: Create or update RELEASE_NOTES.md — a skimmable, human-readable highlights file distilled from CHANGELOG.md, one section per released version. Use when the user wants release notes written, refreshed for a new tag, or a changelog turned into something a regular person can read.
---

# Release notes

Produce a `RELEASE_NOTES.md` that a regular person can skim: one section per
released version, each with a plain-language summary of what actually changed.
It's the readable companion to the machine-generated `CHANGELOG.md`, not a
replacement. Point people at the changelog for the full commit-level record.

## Where the content comes from

The source of truth is `CHANGELOG.md` (release-please generated) or, if there
isn't one, `git log` between version tags. Get the list of released versions
from `git tag --sort=-v:refname` and cross-check it against the sections you
write: every released tag gets exactly one section, newest first.

A real changelog is big and mostly noise. Don't read the whole thing into your
own context. Fan out parallel sub-agents over version ranges (grep the version
headers first to get line ranges), have each return distilled highlights for its
slice, then assemble. Keeps the 300KB of commit lines out of the main thread.

## Structure

Newest version first. Each version section is:

```
## X.Y.Z — YYYY-MM-DD

<one-line theme: what this release was mostly about>

<breaking-change status line — see below>

- **Short label.** Plain-language highlight, grouped and translated.
- ...
```

- **Theme** — one line naming what the release was about. This is the thing
  someone remembers the version by.
- **Breaking status** — every version says up front whether it has breaking
  changes, so the reader can tell at a glance:
  - none: `No breaking changes.`
  - some: `**⚠ Breaking changes** this release: <short reason>.`
- **Highlights** — 2–7 bullets. Fewer for small releases; a one-paragraph blurb
  with no bullets is fine for a tiny release. Lead each bullet with a short bold
  label, then a sentence or two in plain terms.

Flag the actual breaking items inline in the bullets too (a `**⚠ Breaking:**`
lead), and make sure those match the versions whose status line says there are
breaking changes.

## What to keep and what to cut

Keep what changed for someone *using* the tool. Group related commits into one
highlight and translate jargon into the outcome ("git calls can't hang" beats
"added context timeouts to git subprocess invocations").

Cut the noise: internal refactors, test-only changes, doc tidying, formatting
sweeps, dependency and schema-regeneration bumps. The exception is when a cluster
of small changes adds up to something a user would notice — then say that.

Don't enumerate what you left out. The preamble shouldn't list "omits refactors,
tests, dep bumps"; it's obvious and it reads like filler.

## Preamble

Short. A line on what the tool is and who the notes are for, then:

- Point at `CHANGELOG.md` for the full detail.
- Explain the **⚠ Breaking** tag, and say a breaking change *may* need a change
  on your end depending on how you use the tool — it won't affect everyone.

## Tone

Use the same voice as the `commit` skill: business-casual, like a developer
leaving a note for teammates. Be to the point; add detail only where it helps.

Avoid the usual LLM tells:

- Overly formal or passive phrasing.
- Exhaustive enumeration of every change (that's what the changelog is for).
- Restating the diff.
- "per ADR-XXXX" name-drops.
- **Em-dash pile-ups.** In this file the em-dash is only the date separator in a
  header (`## 0.6.1 — 2026-07-24`). Don't use it in prose — a comma, a period, or
  parentheses almost always reads better.

## Before finishing

- Cross-check: `grep -E '^## [0-9]' RELEASE_NOTES.md` against
  `git tag --sort=-v:refname`. Same versions, one section each.
- Confirm each version's breaking-status line agrees with its bullets: a version
  claiming "No breaking changes" shouldn't carry a `**⚠ Breaking:**` bullet, and
  vice versa.
- Sanity-check the em-dash count: the only ones should be the version-header
  date separators, one per version.
