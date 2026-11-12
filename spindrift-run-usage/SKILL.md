---
name: spindrift-run-usage
description: Break down a spindrift dispatch's token usage from its host-side pass log — per pass (role, turns, start/end/peak context, output), per model, and per subagent — and check a "Run usage" issue comment against it. Use when the user asks whether a run's token counts are right, how big a pass's context got, what a subagent cost, or why a usage number looks odd.
---

# Spindrift run usage

Answer usage questions about a spindrift dispatch from its pass log, not from
the issue comment alone. The comment is a summary; the log is the ground truth.
Applies to the `claude` Driver's stream-json logs.

## 1. Find the right log

Logs live in the checkout the daemon or launcher ran from, under
`<checkout>/.spindrift/logs/`:

- `issue-<N>.log` — the current (or latest) dispatch of issue N.
- `issue-<N>.log.<k>` — a rotated-aside retry within that dispatch.
- `issue-<N>-fix-<p>.log`, `issue-<N>-conflict-resolve.log` — extra pass logs
  of the same dispatch, when the launcher split them out.
- `issue-<N>.log.prior-run.<k>` — an **earlier dispatch**, quarantined when a
  new one started (a rerun, e.g. after merge conflicts). It is a separate run.

The "Run usage" comment a dispatch posts sums `issue-<N>.log`, its `.<k>`
rotations, and the fix/conflict-resolve logs — never `.prior-run.<k>`. So:

- To check a comment posted before a rerun, read the `.prior-run.<k>` log
  whose dispatch posted it (match the `Record:` line or timestamps).
- Never mix a live rerun's `issue-<N>.log` into an earlier run's numbers; each
  dispatch posts its own comment, and a whole-issue cost is their sum.

Confirm with `ls -la` (sizes, mtimes) before reading; a log still being
written has no final `result` for its current pass.

## 2. Run the breakdown

```sh
bash <skill-dir>/scripts/run-usage.sh <checkout>/.spindrift/logs/issue-<N>.log.prior-run.1
```

It prints three Markdown tables in well under a second, even for multi-MB logs:

- **Passes (main loop)** — pass number and role (from the launcher's
  `pass_start` markers; split on `result` events with role `?` if there are
  none), turns, distinct main-loop API calls, context on the first and last
  call, peak context, and output tokens for the pass, subagents included.
- **Models** — distinct calls, uncached input, cache read, cache write split
  5m/1h, and output. These columns are what the issue comment's per-model
  table shows; they should match it exactly.
- **Subagents** — one row per spawned subagent: the pass it ran in, its
  `subagent_type`, model, calls, first/last context, cache read and write, and
  the spawn description.

For a single number the tables don't give, query the log with `jq` directly,
reusing the same rules (below). Run `scripts/run-usage.test.sh` after editing
the script.

## 3. Read the numbers correctly

- **Uncached input is ~2 tokens per call, by design.** Claude Code puts a cache
  breakpoint at the end of every message, so almost the whole prompt bills as
  cache read or cache write. "Uncached input: 420" over 210 calls is correct,
  and says nothing about prompt size. Total input processed = uncached + cache
  read + cache write.
- **Context of a call** = `input_tokens + cache_creation_input_tokens +
  cache_read_input_tokens`. A pass's first call is its starting context
  (system prompt, tools, CLAUDE.md, pass prompt, issue); the last is where it
  ended. Peak ≠ end means the pass compacted. The ~10k cache read every pass
  starts with is the prefix shared across sessions (tools and preamble).
- **Output comes only from `result` events' `modelUsage`.** Per-call
  `message.usage.output_tokens` in the stream is a mid-stream placeholder and
  undercounts wildly (3.9k vs 131.7k in one run). Each pass is its own session
  with its own `session_id`, so summing `modelUsage` across results does not
  double-count. A result's top-level `usage.output_tokens` is the main loop
  only; `modelUsage` includes subagents. Per-subagent output is not
  recoverable from the log.
- **Dedupe calls on `message.id`.** claude-code re-emits a multi-block message
  once per content block with identical usage; counting lines overcounts.
- **Expect a small gap against `modelUsage` input/cache-read.** `modelUsage`
  can count a few internal calls the stream never emits (seen: 428 vs 420
  uncached, ~0.9% cache read). The comment's input and cache columns come from
  the stream, so they can run slightly low; that is not a bug in the sum.
- **Cache write split:** an assistant message's `cache_creation` object gives
  5m vs 1h; a message without it counts all writes as 5m, as the launcher does.

## 4. Before blaming the code

If a number disagrees with what the launcher "should" do, check which code
posted it: compare the daemon checkout's commit (`git -C <checkout> log -1`)
against the code you are reading, and `git fetch` first — a stale local
`main` is not the code that ran.
