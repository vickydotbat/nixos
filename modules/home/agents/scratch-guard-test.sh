#!/usr/bin/env bash
# What scratch-guard must and must not stop, driven the way Claude Code drives
# it: a JSON payload on stdin, and an exit status. 0 means allowed, 2 means
# refused.
#
#   bash scratch-guard-test.sh [path to hook]
#
# Defaults to the installed hook, so the normal use is "rebuild, then run
# this". Pass scratch-guard-hook.sh to test the body before a rebuild.
set -euo pipefail

hook="${1:-$HOME/.claude/scratch-guard-hook}"
[[ -r "$hook" ]] || { echo "scratch-guard-test: no hook at $hook" >&2; exit 1; }
runner=("$hook")
[[ -x "$hook" ]] || runner=(bash -euo pipefail "$hook")

sid=test-session
agent=test-agent
failed=0

# $1 is the tool_input object, $2 the agent_id ("" for the main thread).
run() {
  printf '{"hook_event_name":"PreToolUse","session_id":"%s","agent_id":"%s","tool_input":%s}' \
    "$sid" "$2" "$1" | "${runner[@]}" >/dev/null 2>&1 && echo 0 || echo $?
}

cmd() { printf '{"command":%s}' "$(printf '%s' "$1" | jq -Rs .)"; }

allow() {
  local got
  got=$(run "$1" "${2-$agent}")
  [[ $got == 0 ]] || { echo "FAIL allow: $1 (exit $got)"; failed=1; }
}

refuse() {
  local got
  got=$(run "$1" "$agent")
  [[ $got == 2 ]] || { echo "FAIL refuse: $1 (exit $got)"; failed=1; }
}

# A subagent reaching into the shared folder, in both spellings.
refuse "$(cmd "echo body > /tmp/$sid/pr-body.md")"
refuse "$(cmd 'echo body > /tmp/$CLAUDE_CODE_SESSION_ID/pr-body.md')"
refuse "$(cmd 'echo body > /tmp/${CLAUDE_CODE_SESSION_ID}/pr-body.md')"
refuse "$(cmd 'mkdir -p /tmp/$CLAUDE_CODE_SESSION_ID')"
refuse "$(cmd "cat /tmp/$sid/out")"
refuse "{\"file_path\":\"/tmp/$sid/body.md\",\"content\":\"x\"}"

# Its own folder underneath, which is the whole point.
allow "$(cmd "echo body > /tmp/$sid/$agent/pr-body.md")"
allow "{\"file_path\":\"/tmp/$sid/$agent/body.md\",\"content\":\"x\"}"

# The main thread owns the session folder; no agent_id, no opinion.
allow "$(cmd "echo body > /tmp/$sid/pr-body.md")" ""

# Anything that is not the session folder at all.
allow "$(cmd 'ls /etc')"
allow "$(cmd 'echo x > /tmp/other-session/pr-body.md')"

# SubagentStart creates the folder and hands back the path.
start=$(printf '{"hook_event_name":"SubagentStart","session_id":"%s","agent_id":"%s","agent_type":"Explore"}' \
  "$sid" "$agent" | "${runner[@]}")
[[ -d "/tmp/$sid/$agent" ]] || { echo "FAIL: SubagentStart did not create the folder"; failed=1; }
jq -e --arg d "/tmp/$sid/$agent" \
  '.hookSpecificOutput.hookEventName == "SubagentStart"
   and (.hookSpecificOutput.additionalContext | contains($d))' >/dev/null <<<"$start" \
  || { echo "FAIL: SubagentStart context missing the path"; failed=1; }
rmdir "/tmp/$sid/$agent" "/tmp/$sid" 2>/dev/null || true

[[ $failed == 0 ]] && echo "scratch-guard-test: all checks passed"
exit "$failed"
