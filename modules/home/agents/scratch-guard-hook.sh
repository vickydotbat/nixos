# Body of the scratch-guard hook. `writeShellApplication` supplies the shebang
# and `set -euo pipefail`, so this file starts at the work. Kept beside the
# module rather than inlined so the test script can drive it before a rebuild:
#
#   bash modules/home/agents/scratch-guard-test.sh modules/home/agents/scratch-guard-hook.sh
payload=$(cat)
event=$(jq -r '.hook_event_name // ""' <<<"$payload")
agent=$(jq -r '.agent_id // ""' <<<"$payload")
sid=$(jq -r '.session_id // ""' <<<"$payload")

# agent_id is present only when the hook fires inside a subagent. The main
# thread is the one legitimate owner of the session folder, so it passes.
[ -n "$agent" ] || exit 0

dir="/tmp/$sid/$agent"

if [ "$event" = "SubagentStart" ]; then
  mkdir -p "$dir"
  jq -n --arg dir "$dir" '{
    hookSpecificOutput: {
      hookEventName: "SubagentStart",
      additionalContext: (
        "Scratch folder for this subagent: " + $dir + " (already created). "
        + "Write every scratch file there, with the full path in every command. "
        + "/tmp/$CLAUDE_CODE_SESSION_ID itself is shared with every sibling subagent; "
        + "reading or writing directly in it is refused."
      )
    }
  }'
  exit 0
fi

# Every string in the tool input at once: a Bash command line, a Write or Edit
# file_path, whatever a future tool names a path.
text=$(jq -r '[.tool_input | .. | strings] | join("\n")' <<<"$payload")

# Both spellings of the shared folder: the resolved session id, and the
# variable the doctrine tells agents to write.
pattern="/tmp/($sid|\\\$\{?CLAUDE_CODE_SESSION_ID\}?)(/[^\"'\`[:space:]]*)?"
bad=$(grep -oE "$pattern" <<<"$text" | grep -vE "^/tmp/[^/]+/$agent(/|\$)" | sort -u | head -3) || true

[ -n "$bad" ] || exit 0

{
  printf 'scratch-guard: refused. This is the shared session folder:\n'
  while IFS= read -r line; do printf '  %s\n' "$line"; done <<<"$bad"
  printf 'Every sibling subagent writes it under the same obvious names, and a\n'
  printf 'collision is silent: two pull request bodies already swapped that way.\n'
  printf 'Use your own folder instead: %s\n' "$dir"
} >&2
exit 2
