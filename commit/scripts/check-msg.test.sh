#!/usr/bin/env bash
# Tests for check-msg.sh. Run: bash commit/scripts/check-msg.test.sh
set -u

here=$(cd "$(dirname "$0")" && pwd)
check="$here/check-msg.sh"
fails=0

# expect <name> <want-exit> <want-grep|-> <message>
expect() {
  local name=$1 want_exit=$2 want_out=$3 msg=$4 out got
  out=$(printf '%s' "$msg" | bash "$check" 2>&1)
  got=$?
  if [[ $got -ne $want_exit ]]; then
    echo "FAIL $name: exit $got, want $want_exit"; echo "$out"; fails=$((fails + 1)); return
  fi
  if [[ $want_out != - ]] && ! grep -qE -- "$want_out" <<<"$out"; then
    echo "FAIL $name: output missing /$want_out/"; echo "$out"; fails=$((fails + 1)); return
  fi
  echo "ok   $name"
}

long80=$(printf 'x%.0s ' {1..40})

expect "clean subject only" 0 '^$' 'feat(api): add retry budget'

expect "clean with body and footers" 0 '^$' 'fix(auth): refresh token before expiry

Tokens minted near the hour boundary expired mid-request. Refresh
when less than five minutes remain.

Closes #42
Co-Authored-By: Claude <noreply@anthropic.com>'

expect "missing type prefix" 1 'error: .*type' 'add retry budget'

expect "unknown type" 1 'error: .*type' 'feature: add retry budget'

expect "breaking bang accepted" 0 '^$' 'feat(api)!: drop v1 endpoints'

expect "subject over 72 is an error" 1 'error: .*subject.*72' \
  'feat(console): add a remarkably long description that keeps going past the cap'

expect "subject over 50 only warns" 0 'warn: .*subject.*50' \
  'feat(console): research-pick and unpick in detail modal'

expect "trailing period" 1 'error: .*period' 'fix: handle empty input.'

expect "no blank line after subject" 1 'error: .*blank' 'fix: handle empty input
body starts too early'

expect "body line over 72" 1 'error: line 3' "fix: handle empty input

$long80"

expect "long URL line exempt" 0 '^$' 'docs: link the spec

See https://www.conventionalcommits.org/en/v1.0.0/#specification-for-the-long-version-of-it'

expect "long unbreakable token exempt" 0 '^$' 'fix: correct store path

/nix/store/abcdefghijklmnopqrstuvwxyz0123456789-some-really-long-derivation-name'

expect "long line in fenced block exempt" 0 '^$' "test: pin repro

\`\`\`
$long80
\`\`\`"

expect "uppercase start warns" 0 'warn: .*lowercase' 'fix(go): HTTPError wraps the cause'

expect "repeated type word warns" 0 'warn: .*repeats' 'fix(schema): fix doc pointer'

expect "empty message" 1 'error: .*empty' ''

expect "footers split by blank line" 1 'error: .*footers.*one block' 'fix: handle empty input

Explain why here.

Refs: #1879

Co-Authored-By: Claude <noreply@anthropic.com>'

expect "footer-only message split by blank line" 1 'error: .*footers.*one block' 'chore: bump deps

Refs #12

Co-Authored-By: Claude <noreply@anthropic.com>'

expect "trailing blank lines after footers ok" 0 '^$' 'fix: handle empty input

Explain why here.

Refs #1879
Co-Authored-By: Claude <noreply@anthropic.com>


'

tmp=$(mktemp)
printf 'chore: bump deps\n' >"$tmp"
if bash "$check" "$tmp" >/dev/null 2>&1; then echo "ok   file argument"; else echo "FAIL file argument"; fails=$((fails + 1)); fi
rm -f "$tmp"

echo
if [[ $fails -gt 0 ]]; then echo "$fails failing"; exit 1; fi
echo "all passed"
