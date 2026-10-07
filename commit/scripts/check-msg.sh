#!/usr/bin/env bash
# Lint a commit message against the commit skill's rules.
#
#   check-msg.sh [FILE]              # FILE, or stdin when omitted
#   git log -1 --format=%B | check-msg.sh
#
# Prints "error: ..." / "warn: ..." lines. Exits 1 on any error, 0 otherwise
# (warnings never fail).
set -u

types='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
errors=0

err() { echo "error: $*"; errors=$((errors + 1)); }
warn() { echo "warn: $*"; }

lines=()
while IFS= read -r line || [[ -n $line ]]; do
  lines+=("$line")
done < "${1:-/dev/stdin}"

if [[ ${#lines[@]} -eq 0 || -z ${lines[0]} ]]; then
  err "empty message or empty subject line"
  exit 1
fi

subject=${lines[0]}
prefix_re="^($types)(\([^()]+\))?!?: (.+)$"

if [[ $subject =~ $prefix_re ]]; then
  type=${BASH_REMATCH[1]}
  desc=${BASH_REMATCH[3]}
  [[ $desc =~ ^[A-Z] ]] &&
    warn "description should start lowercase (fine for identifiers/proper nouns)"
  first=${desc%% *}
  [[ $first == "$type" || $first == "${type}ed" || $first == "${type}es" ]] &&
    warn "description repeats the type word '$type'"
else
  err "subject must be '<type>[(scope)][!]: <description>' with type one of: ${types//|/, }"
fi

len=${#subject}
if ((len > 72)); then
  err "subject is $len chars; hard limit is 72"
elif ((len > 50)); then
  warn "subject is $len chars; aim for 50 or fewer"
fi

[[ $subject == *. ]] && err "subject has a trailing period"

if [[ ${#lines[@]} -gt 1 && -n ${lines[1]} ]]; then
  err "line 2 must be blank (separates subject from body)"
fi

fenced=0
for ((i = 1; i < ${#lines[@]}; i++)); do
  line=${lines[i]}
  if [[ $line =~ ^[[:space:]]*\`\`\` ]]; then
    fenced=$((1 - fenced))
    continue
  fi
  ((${#line} <= 72 || fenced)) && continue
  # Unbreakable content can't be wrapped: URLs and single long tokens.
  [[ $line == *://* ]] && continue
  trimmed=${line#"${line%%[![:space:]]*}"}
  [[ $trimmed != *[[:space:]]* ]] && continue
  err "line $((i + 1)) is ${#line} chars; wrap body/footers at 72"
done

# git only parses the final paragraph as trailers, so a blank line inside
# the footer block silently demotes everything above it to body text.
trailer_re='^(BREAKING CHANGE|[A-Za-z][A-Za-z-]*)(: | #)'
all_trailers() {
  local l
  for l in "$@"; do [[ $l =~ $trailer_re ]] || return 1; done
}
end=${#lines[@]}
while ((end > 2)) && [[ -z ${lines[end - 1]} ]]; do end=$((end - 1)); done
start=$end
while ((start > 2)) && [[ -n ${lines[start - 1]} ]]; do start=$((start - 1)); done
if ((start > 2)) && all_trailers "${lines[@]:start:end-start}"; then
  prev_end=$((start - 1))
  prev_start=$prev_end
  while ((prev_start > 2)) && [[ -n ${lines[prev_start - 1]} ]]; do prev_start=$((prev_start - 1)); done
  if ((prev_end > prev_start)) && all_trailers "${lines[@]:prev_start:prev_end-prev_start}"; then
    err "footers must be one block; remove the blank line at line $((prev_end + 1))"
  fi
fi

((errors == 0))
