#!/usr/bin/env bash
# What git-guard must and must not stop, driven the way Claude Code drives it: a
# JSON payload on stdin, and an exit status. 0 means allowed, 2 means refused.
#
#   bash git-guard-test.sh [path to hook]
#
# Defaults to the installed hook, so the normal use is "rebuild, then run this".
# Covers branch switches, which pass anywhere, plus rules 1 and 2.
set -euo pipefail

hook="${1:-$HOME/.claude/git-guard-hook}"
[[ -x "$hook" ]] || { echo "git-guard-test: no hook at $hook" >&2; exit 1; }

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# A main checkout with a merged feature branch, and a linked worktree of it.
git init -q -b main "$scratch/repo"
g() { git -C "$scratch/repo" -c user.email=t@t -c user.name=t -c commit.gpgsign=false "$@"; }
g commit -q --allow-empty -m init
g branch feature
echo x >"$scratch/repo/file"
g worktree add -q "$scratch/wt" feature

failed=0
expect() {
  local want=$1 cwd=$2 command=$3 got
  got=$(printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":%s}}' "$cwd" "$(printf '%s' "$command" | jq -Rs .)" |
    "$hook" >/dev/null 2>&1 && echo 0 || echo $?)
  [[ $got == "$want" ]] || { echo "FAIL want $want, got $got: ($cwd) $command"; failed=1; }
}

main="$scratch/repo"
wt="$scratch/wt"

# The main checkout: a switch to a branch or a commit, new or old, passes.
expect 0 "$main" 'git checkout feature'
expect 0 "$main" 'git switch feature'
expect 0 "$main" 'git checkout -b topic'
expect 0 "$main" 'git switch -c topic'
expect 0 "$main" "git checkout $(g rev-parse HEAD)"
expect 0 "$scratch" "git -C $main switch feature"
expect 0 "$main" 'git checkout -- file'
expect 0 "$main" 'git status'

# A linked worktree switches the same way.
expect 0 "$wt" 'git switch main'
expect 0 "$wt" 'git checkout feature'

# Rule 1: no new branch from a branch that main has not merged.
git -C "$wt" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q --allow-empty -m unmerged
expect 2 "$wt" 'git checkout -b topic'
expect 2 "$wt" 'git switch -c topic'

# Rule 2: no push to main.
expect 2 "$main" 'git push origin main'
expect 0 "$wt" 'git push -u origin feature'

if [[ $failed -eq 0 ]]; then echo "git-guard-test: all cases pass"; fi
exit "$failed"
