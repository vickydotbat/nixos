#!/usr/bin/env bash
# What issue-guard must and must not stop, driven the way Claude Code drives
# it: a JSON payload on stdin carrying the command, and an exit status. 0 means
# allowed, 2 means refused.
#
#   bash issue-guard-test.sh [path to hook]
#
# Defaults to the installed hook, so the normal use is "rebuild, then run this".
set -euo pipefail

hook="${1:-$HOME/.claude/issue-guard-hook}"
[[ -x "$hook" ]] || { echo "issue-guard-test: no hook at $hook" >&2; exit 1; }

failed=0

run() {
  printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$1" | jq -Rs .)" \
    | "$hook" >/dev/null 2>&1 && echo 0 || echo $?
}

allow() {
  local got
  got=$(run "$1")
  [[ $got == 0 ]] || { echo "FAIL allow: $1 (exit $got)"; failed=1; }
}

refuse() {
  local got
  got=$(run "$1")
  [[ $got == 2 ]] || { echo "FAIL refuse: $1 (exit $got)"; failed=1; }
}

# Half a thread: the body without the comments.
refuse 'gh issue view 12'
refuse 'gh pr view 12'
refuse 'gh issue view 12 --repo owner/name'
refuse 'cd /tmp && gh issue view 12'
refuse 'tea issues 12'
refuse 'tea i 7'
refuse 'tea pulls 3'
refuse 'tea pr 3'

# The whole thread, in every form that carries the comments.
allow 'gh issue view 12 --comments'
allow 'gh pr view 12 -c'
allow 'gh issue view 12 --json title,body,comments'
allow 'gh issue view 12 --web'
allow 'tea issues 12 --comments'
allow 'tea pulls 3 --comments'

# Not a detail view at all.
allow 'gh issue list'
allow 'gh pr list --state open'
allow 'gh issue create --title x --body y'
allow 'tea issues list'
allow 'tea issues create --title x'
allow 'gh api repos/owner/name/issues/12'
allow 'git status'

[[ $failed == 0 ]] && echo "issue-guard-test: all cases pass"
exit "$failed"
