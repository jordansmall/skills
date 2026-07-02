---
name: orchestrate-issues
description: Orchestrate an AFK agent fleet that clears ready-for-agent issues end to end — claim, TDD, commit, green CI, merge, relabel.
disable-model-invocation: true
---

# Orchestrate Issues

Clear every `ready-for-agent` issue autonomously, one self-contained
**pipeline** per issue: **claim → scout → TDD → commit → review → green →
merge → complete**. Two invariants hold throughout:

- **The label is the baton.** An issue's lifecycle label is the single source
  of truth for its state: `ready-for-agent` (unclaimed) → `agent-in-progress`
  (a worker owns it) → `agent-complete` (PR merged). Move the label at exactly
  the two moments below, nowhere else.
- **Haiku scouts, Sonnet builds, Opus reviews.** Cheap to read, mid to write,
  top to judge the gate: exploration subagents run on `haiku`, implementation on
  `sonnet`, and the review that gates an unattended merge on `opus`.

## 1. Collect

`gh issue list --label ready-for-agent`. Read each issue body in full.

Completion: you hold every ready issue with its full text.

## 2. Order by dependency

Scan each issue for blockers ("depends on #N", "blocked by #N", or a prose
dependency). Group into waves: independent issues share a wave and run in
parallel; a dependent issue waits in a later wave until its blocker reaches
`agent-complete`.

Completion: every issue sits in a wave, and no issue precedes its blocker.

## 3. Run the pipeline per issue

Spawn **one `sonnet` worker per issue** and dispatch the current wave's workers
concurrently. Hand each worker only its issue; it owns the whole pipeline and
returns only an outcome, so the orchestrator's context stays flat no matter how
wide the wave. Each worker runs these stages in order — do not skip or reorder:

1. **Claim** — relabel `ready-for-agent` → `agent-in-progress` as the first
   action, before any code. This hands over the baton and stops a second worker
   taking the issue.
2. **Scout** — delegate exploration to a `haiku` Explore subagent that locates
   where the change goes: the files, the seams, the existing tests. Keep this on
   `haiku`; do not read the codebase inline on `sonnet`. The scout's map stays
   inside the worker, never reaching the orchestrator.
3. **Build** — implement test-first via `/tdd` (red → green → refactor) using
   the scout's map, then commit with `/commit` (Conventional Commits).
4. **Review** — spawn a *fresh* `opus` reviewer, not the builder, to review the
   branch against `main` via `/review` (Standards + Spec): does the diff do what
   the issue asked, and does it follow repo standards? A different, stronger
   model with clean context is the point — orthogonal judgment on the last gate
   before an unattended merge, not an author grading its own work.
   On a blocking finding, loop back to **Build**: the worker still holds its
   build context, so it fixes in place, re-commits, and re-reviews. Re-**Scout**
   (a fresh `haiku` pass) only when the finding invalidates the map — the change
   sits in the wrong place, or a call site or module was missed — since patching
   the wrong spot won't clear it. Never advance with a finding unaddressed.
   Reviewing the local branch here, before the PR, keeps review churn off CI.
5. **PR** — push the branch and open a PR that closes the issue (`Closes #N`).
6. **Green** — `gh pr checks <pr> --watch`. On red, fix and re-push; never
   advance on red.
7. **Merge** — once checks are green, merge the PR.
8. **Complete** — relabel `agent-in-progress` → `agent-complete`.

As each worker returns `agent-complete`, run `/compact` in the orchestrator
session before starting the next wave. The worker already kept its scout and
build detail out of the orchestrator; this clears the leftover PR and CI chatter.

Completion: for every issue in the wave, a clean review and green CI backed the
merge, and the label reads `agent-complete`.

## 4. Report

One line per issue: number, PR link, merge status. Flag any issue that stalled
(red CI or a review finding it could not resolve, an unmet dependency) with the
reason, and leave it on `agent-in-progress` for a human.
