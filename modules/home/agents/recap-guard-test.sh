#!/usr/bin/env bash
# What recap-guard must and must not stop, driven the way Claude Code drives it:
# a JSON payload on stdin naming a transcript file, and an exit status.
#
#   bash recap-guard-test.sh [path to hook]
#
# Defaults to the installed hook, so the normal use is "rebuild, then run this".
# Four of the five cases are false positives it used to produce; the fifth is
# the one real claim, and it must still be caught or the hook is decoration.
set -euo pipefail

hook="${1:-$HOME/.claude/recap-guard-hook}"
[[ -x "$hook" ]] || { echo "recap-guard-test: no hook at $hook" >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failed=0

# Transcript records, in the shape Claude Code writes them: newline-delimited
# JSON, oldest first, sub-agent traffic mixed into the same file.
user() { jq -nc --arg ts "$1" --arg text "$2" \
  '{type:"user",isSidechain:false,timestamp:$ts,message:{content:$text}}'; }
assistant() { jq -nc --arg ts "$1" --arg text "$2" --argjson side "${3:-false}" \
  '{type:"assistant",isSidechain:$side,timestamp:$ts,message:{content:[{type:"text",text:$text}]}}'; }
tool() { jq -nc --arg ts "$1" --arg cmd "$2" \
  '{type:"assistant",isSidechain:false,timestamp:$ts,message:{content:[{type:"tool_use",name:"Bash",input:{command:$cmd}}]}}'; }

check() { # <name> <transcript> <quiet|stops>
  local want="$3" got
  if jq -nc --arg t "$2" '{transcript_path:$t,stop_hook_active:false}' | "$hook" >/dev/null 2>&1
  then got=quiet; else got=stops; fi
  if [[ "$got" == "$want" ]]; then
    printf 'ok   %s\n' "$1"
  else
    printf 'FAIL %s (wanted %s, got %s)\n' "$1" "$want" "$got"
    failed=1
  fi
}

# A sub-agent's report is not the message the user is about to read, and in a
# session with sub-agents it is most of the transcript.
{ user 2026-01-01T10:00:00Z "go"
  assistant 2026-01-01T10:01:00Z "Renamed the column and updated the docs."
  assistant 2026-01-01T10:02:00Z "The PR is open and blocked on #99." true
} >"$work/sidechain.jsonl"
check "a sub-agent's report is not graded" "$work/sidechain.jsonl" quiet

# The hook can win the race with the response's own text record. Grading the
# message before it means grading the previous turn -- which, right after a
# block, is the agent's own re-check sentence.
{ user 2026-01-01T10:00:00Z "go"
  assistant 2026-01-01T10:01:00Z "Re-checked just now: issue #156 is closed."
  user 2026-01-01T10:02:00Z "thanks"
  tool 2026-01-01T10:03:00Z "ls"
} >"$work/unflushed.jsonl"
check "the previous turn is not graded" "$work/unflushed.jsonl" quiet

# A recap written under the command that proves it is fresh by construction.
{ user 2026-01-01T10:00:00Z "what is the state"
  tool 2026-01-01T10:01:00Z "tea pr list"
  assistant 2026-01-01T10:02:00Z "PR #251 is open, labelled Kind/Feature."
} >"$work/verified.jsonl"
check "a claim checked this turn passes" "$work/verified.jsonl" quiet

# The failure the hook exists for: state asserted from memory, nothing run.
{ user 2026-01-01T10:00:00Z "wrap up"
  tool 2026-01-01T10:01:00Z "sed -n 1,5p README.md"
  assistant 2026-01-01T10:02:00Z "PR !149 is still open and blocked on sow-tools#122."
} >"$work/stale.jsonl"
check "an unchecked claim is stopped" "$work/stale.jsonl" stops

# Saying what you did is never stale.
{ user 2026-01-01T10:00:00Z "wrap up"
  assistant 2026-01-01T10:02:00Z "Moved 818 entries and added the key column."
} >"$work/did.jsonl"
check "a recap of its own work passes" "$work/did.jsonl" quiet

[[ "$failed" -eq 0 ]] || exit 1
echo "recap-guard-test: stops the claim nobody checked, and nothing else"
