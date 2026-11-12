#!/usr/bin/env bash
# Tests for run-usage.sh. Run: bash spindrift-run-usage/scripts/run-usage.test.sh
set -u

here=$(cd "$(dirname "$0")" && pwd)
run="$here/run-usage.sh"
log="$here/testdata/two-passes.log"
fails=0

# expect_row <name> <output> <exact table row>
expect_row() {
  local name=$1 out=$2 row=$3
  if grep -qxF -- "$row" <<<"$out"; then
    echo "ok   $name"
  else
    echo "FAIL $name: missing row: $row"; echo "$out"; fails=$((fails + 1))
  fi
}

out=$(bash "$run" "$log" 2>&1)

expect_row "pass 1 main-loop context" "$out" \
  '| 1 | implement | 2 | 2 | 10002 | 10204 | 10204 | 1100 |'
expect_row "pass 2 main-loop context" "$out" \
  '| 2 | review | 1 | 1 | 8002 | 8002 | 8002 | 250 |'
expect_row "opus totals dedup by message id" "$out" \
  '| claude-opus-5-5 | 3 | 6 | 24002 | 0 | 4200 | 950 |'
expect_row "sonnet totals" "$out" \
  '| claude-sonnet-5-5 | 2 | 4 | 8500 | 800 | 0 | 400 |'
expect_row "subagent row" "$out" \
  '| 1 | worker | claude-sonnet-5-5 | 2 | 4502 | 4802 | 8500 | 800 | Slice 1 |'

bare=$(grep -v '"type":"spindrift_op"' "$log" | bash "$run" /dev/stdin 2>&1)
expect_row "no markers: pass 1 split on result" "$bare" \
  '| 1 | ? | 2 | 2 | 10002 | 10204 | 10204 | 1100 |'
expect_row "no markers: pass 2 split on result" "$bare" \
  '| 2 | ? | 1 | 1 | 8002 | 8002 | 8002 | 250 |'

bash "$run" "$here/testdata/no-such.log" >/dev/null 2>&1
got=$?
if [[ $got -eq 2 ]]; then
  echo "ok   missing log exits 2"
else
  echo "FAIL missing log: exit $got, want 2"; fails=$((fails + 1))
fi

if [[ $fails -ne 0 ]]; then
  echo "$fails failed"; exit 1
fi
echo "all passed"
