---
name: commit
description: Write git commit messages in strict Conventional Commits v1.0.0 style with hard line wraps. Use whenever you are about to write a commit message in any repo (unless that repo's own CLAUDE.md overrides the format).
---

# Commit

Write every commit message in **strict Conventional Commits v1.0.0**
(https://www.conventionalcommits.org/en/v1.0.0/#specification) with **hard line
wraps**. A repo's own CLAUDE.md overrides these rules.

## Structure

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

## Rules

- **type** — lowercase. Common set: `feat` (new feature, MINOR), `fix` (bug fix,
  PATCH), `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`,
  `revert`.
- **scope** — optional noun in parentheses naming the area, e.g. `feat(api):`.
- **description** — imperative mood, lowercase start, **no trailing period**.
- **breaking changes** — add `!` before the colon (e.g. `feat(api)!:`) and/or a
  `BREAKING CHANGE: <desc>` footer (the token MUST be uppercase).
- **body** — optional; starts one blank line after the description. Explains what
  and why, not how.
- **footers** — one blank line after the body; `Token: value` form. Tokens use
  `-` instead of spaces (e.g. `Reviewed-by:`), except `BREAKING CHANGE`.

## Tone

Write the body business-casual — like a developer leaving a note for teammates.
Be to the point; add detail only where clarity needs it. Avoid LLM tells: overly
formal or passive phrasing, exhaustive enumeration of every change, restating the
diff, "per ADR-XXXX" name-drops, and em-dash pile-ups. Plain sentences beat
polished ones.

## Granularity

Prefer several small, logical commits over one large one. Each commit should
stand on its own and be reviewable in isolation (e.g. scaffold, then CI, then
dev tooling as separate commits). Commit as each unit of work lands, not all at
the end.

## Hard line wraps

- **Subject** (the `<type>...: <description>` line) — keep ≤ 50 characters; never
  exceed 72.
- **Body and footers** — hard-wrap at **72 columns**. Insert real newlines; do
  not rely on soft wrapping.

## Before committing

Confirm: subject ≤ 50 chars, imperative and lowercase with no trailing period,
type from the set above, and every body/footer line wrapped at 72.
