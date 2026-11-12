#!/usr/bin/env bash
# Break a spindrift claude-driver pass log down by pass, model, and subagent.
#
#   run-usage.sh LOG        # e.g. .spindrift/logs/issue-123.log.prior-run.1
#
# Prints three Markdown tables. Context = input + cache write + cache read of
# one API call. Calls dedupe on message.id: claude-code re-emits a multi-block
# message once per block with identical usage. Output comes only from result
# events' modelUsage, because per-call output_tokens in the stream is a
# mid-stream placeholder.
set -u

if [[ $# -ne 1 || ! -r $1 ]]; then
  echo "usage: run-usage.sh LOG (readable claude-driver pass log)" >&2
  exit 2
fi
command -v jq >/dev/null || { echo "run-usage.sh: jq not found" >&2; exit 2; }

log=$1
jq -nRr --arg path "$log" '
def n: . // 0;
def pk: tostring;
def cell: tostring | gsub("\\|"; "\\|") | gsub("\n"; " ");

reduce (inputs | fromjson? | objects) as $e (
  {p: 1, closed: false, role: {}, seen: {}, spawn: {}, passes: {}, models: {},
   subs: {}, suborder: [], record: null};

  if $e.type == "spindrift_op" then
    ($e.spindrift_op // {}) as $op
    | if $op.op == "pass_start" then
        .p = $op.pass | .closed = false | .role[$op.pass | pk] = $op.role
        | .passes[$op.pass | pk] //= {}
      elif $op.op == "dispatch_start" then
        .record = $op.dispatch_start.record_id
      else . end

  elif $e.type == "assistant" and ($e.message.usage | type) == "object" then
    (if .closed then .p += 1 | .closed = false else . end)
    | .p as $p
    | reduce ($e.message.content // [] | if type == "array" then .[] else empty end
              | select(.type == "tool_use" and (.name == "Agent" or .name == "Task")))
        as $s (.; .spawn[$s.id] = {st: ($s.input.subagent_type // "?"),
                                   d: ($s.input.description // ""), p: $p})
    | ($e.message.id // "") as $id
    | if $id != "" and .seen[$id] then .
      else
        (if $id != "" then .seen[$id] = true else . end)
        | $e.message.usage as $u
        | ($u.cache_creation_input_tokens | n) as $cw
        | ($u.cache_read_input_tokens | n) as $cr
        | (($u.input_tokens | n) + $cw + $cr) as $ctx
        | ($e.message.model // "unknown") as $m
        | .models[$m].calls += 1
        | .models[$m].in += ($u.input_tokens | n)
        | .models[$m].cr += $cr
        | .models[$m].cw5 += (if $u.cache_creation then $u.cache_creation.ephemeral_5m_input_tokens | n else $cw end)
        | .models[$m].cw1h += ($u.cache_creation.ephemeral_1h_input_tokens | n)
        | if $e.parent_tool_use_id == null then
            .passes[$p | pk] |= (
              .calls += 1 | .first //= $ctx | .last = $ctx
              | .peak = ([.peak | n, $ctx] | max))
          else
            $e.parent_tool_use_id as $k
            | (if .subs[$k] == null then .suborder += [$k] else . end)
            | (.spawn[$k] // {st: "?", d: "", p: $p}) as $sp
            | .subs[$k] |= (
                .p = $sp.p | .st = $sp.st | .d = $sp.d | .m = $m
                | .calls += 1 | .first //= $ctx | .last = $ctx
                | .cr += $cr | .cw += $cw)
          end
      end

  elif $e.type == "result" then
    (.p | pk) as $p
    | ($e.modelUsage // {}) as $mu
    | .passes[$p].turns += ($e.num_turns | n)
    | .passes[$p].out += (if ($mu | length) > 0
                          then [$mu[].outputTokens | n] | add
                          else $e.usage.output_tokens | n end)
    | reduce ($mu | to_entries[]) as $kv (.; .models[$kv.key].out += ($kv.value.outputTokens | n))
    | .closed = true

  else . end
)
| . as $s
| "# Run usage: \($path)",
  (if $s.record then "", "Record: `\($s.record)`" else empty end),
  "",
  "## Passes (main loop)",
  "",
  "| Pass | Role | Turns | Main calls | Start ctx | End ctx | Peak ctx | Output |",
  "| --- | --- | --- | --- | --- | --- | --- | --- |",
  ($s.passes | to_entries | sort_by(.key | tonumber)[]
    | .key as $k | .value as $v
    | "| \($k) | \($s.role[$k] // "?") | \($v.turns | n) | \($v.calls | n) | \($v.first | n) | \($v.last | n) | \($v.peak | n) | \($v.out // "?") |"),
  "",
  "## Models",
  "",
  "| Model | Calls | Uncached input | Cache read | Cache write 5m | Cache write 1h | Output |",
  "| --- | --- | --- | --- | --- | --- | --- |",
  ($s.models | to_entries | sort_by(.key)[]
    | .value as $v
    | "| \(.key) | \($v.calls | n) | \($v.in | n) | \($v.cr | n) | \($v.cw5 | n) | \($v.cw1h | n) | \($v.out // "?") |"),
  "",
  "## Subagents",
  "",
  "| Pass | Type | Model | Calls | Start ctx | End ctx | Cache read | Cache write | Description |",
  "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
  ($s.suborder[] | $s.subs[.]
    | "| \(.p) | \(.st | cell) | \(.m) | \(.calls) | \(.first) | \(.last) | \(.cr) | \(.cw) | \(.d | cell) |")
' "$log"
