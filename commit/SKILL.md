---
name: commit
description: Write git commit messages in strict Conventional Commits v1.0.0 style with hard line wraps. Use whenever you are about to write a commit message in any repo — including commits made mid-task, amends, squashes, and rewording — unless that repo's own CLAUDE.md overrides the format.
---

# Commit

Write every commit message in **strict Conventional Commits v1.0.0**
(https://www.conventionalcommits.org/en/v1.0.0/#specification) with **hard line
wraps**. A repo's own CLAUDE.md overrides these rules.

The spec defines structure only. The length limits below are the separate git
convention (readable `git log --oneline`, 80-column terminals) layered on top.

## Structure

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

## Rules

- **type** — lowercase, one of: `feat` (new feature, MINOR), `fix` (bug fix,
  PATCH), `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`,
  `revert`. Pick by what the change *is*, not what prompted it: a doc-only fix
  is `docs`, a behavior-preserving restructure is `refactor`, deps and tooling
  are `build`/`chore`.
- **scope** — optional noun in parentheses naming the area, e.g. `feat(api):`.
- **description** — imperative mood, lowercase start, **no trailing period**.
  Identifiers and proper nouns keep their case (`fix(go): HTTPError ...`).
  Don't repeat the type word: `fix(schema): correct doc pointer`, not
  `fix(schema): fix doc pointer`.
- **breaking changes** — add `!` before the colon (e.g. `feat(api)!:`) and/or a
  `BREAKING CHANGE: <desc>` footer (the token MUST be uppercase).
- **body** — optional; starts one blank line after the description. Explains
  what and why, not how. Skip it when the subject says everything.
- **footers** — one blank line after the body. Either `Token: value` or
  `Token #value` (e.g. `Closes #42`, `Refs #17`). Tokens use `-` instead of
  spaces (`Reviewed-by:`), except `BREAKING CHANGE`. Put `BREAKING CHANGE`
  first, issue refs next, and trailers your environment requires (e.g.
  `Co-Authored-By:`) last, verbatim.
- **revert** — `revert: <original subject>` with a `Refs: <sha>` footer.

## Length and wrapping

- **Subject** — **72 characters is the hard limit**, counting the whole line
  including `type(scope): `. Aim for 50 or fewer; going past 50 is fine when a
  shorter subject would lose meaning.
- **Body and footers** — hard-wrap at **72 columns** with real newlines; never
  rely on soft wrapping.
- **Unbreakable content** — URLs, long paths/identifiers, and fenced code
  blocks stay on one line even past 72. Never split a URL to fit.

## Tone

Write the body business-casual — like a developer leaving a note for teammates.
Be to the point; add detail only where clarity needs it. Avoid LLM tells: overly
formal or passive phrasing, exhaustive enumeration of every change, restating the
diff, "per ADR-XXXX" name-drops, and em-dash pile-ups. Plain sentences beat
polished ones.

## Granularity

When you are committing, prefer several small, logical commits over one large
one. Each should stand on its own and be reviewable in isolation (e.g.
scaffold, then CI, then dev tooling). This shapes *how* you split work you were
asked to commit — it isn't license to commit when nobody asked.

## Committing

Pass the message through a heredoc with `-F -` so your line breaks survive.
Avoid `-m "..."`, which invites one unwrapped line, and stacked `-m` flags.

```sh
git commit -F - <<'EOF'
fix(auth): refresh token before expiry

Tokens minted near the hour boundary expired mid-request. Refresh
when less than five minutes remain instead of waiting for a 401.

Closes #42
EOF
```

Then lint what landed and amend if it reports an error (warnings are advisory):

```sh
git log -1 --format=%B | bash <skill-dir>/scripts/check-msg.sh
```

`<skill-dir>` is this skill's directory. The script checks the prefix, subject
length (error over 72, warning over 50), trailing period, blank second line,
and 72-column wrapping with the exemptions above.

## Examples

```
feat(console)!: drop the legacy picks endpoint

The console now drives picks through the loop API, so the old endpoint
has no callers. Removing it lets the server stop carrying two auth
paths.

BREAKING CHANGE: /api/picks is gone; use /api/loop/picks.
Refs #644
```

Bad → good:

- `Fix: Updated the parser to handle empty input.` →
  `fix(parser): handle empty input`
- `fix(schema): fix continuousDispatch doc pointer` →
  `docs(schema): correct continuousDispatch pointer`
