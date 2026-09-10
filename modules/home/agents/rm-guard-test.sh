#!/usr/bin/env bash
# What rm-guard must and must not stop, driven the way Claude Code drives it:
# a JSON payload on stdin carrying the command and the working directory, and
# an exit status. 0 means allowed, 2 means refused.
#
#   bash rm-guard-test.sh [path to hook]
#
# Defaults to the installed hook, so the normal use is "rebuild, then run this".
set -euo pipefail

hook="${1:-$HOME/.claude/rm-guard-hook}"
[[ -x "$hook" ]] || { echo "rm-guard-test: no hook at $hook" >&2; exit 1; }

# Not under /tmp: the hook exempts scratch space there, which would make every
# case below pass for the wrong reason.
work="$(mktemp -d "$HOME/.rm-guard-test.XXXXXX")"
trap 'chmod -R u+w "$work"; rm -rf "$work"' EXIT
failed=0

# A repo with one tracked file, one untracked file, and one ignored directory.
repo="$work/repo"
mkdir -p "$repo/src" "$repo/scratch" "$repo/node_modules"
git -C "$repo" init -q
git -C "$repo" config user.email t@t
git -C "$repo" config user.name t
echo tracked > "$repo/src/tracked.txt"
echo node_modules > "$repo/.gitignore"
git -C "$repo" add src/tracked.txt .gitignore
git -C "$repo" commit -qm init
echo new > "$repo/scratch/untracked.txt"
echo junk > "$repo/node_modules/junk.js"
# Ignored, but nothing regenerates it: the case the disposable list must not
# swallow.
echo "SECRET=1" > "$repo/scratch/.env"
printf '.env\n' >> "$repo/.gitignore"

# A directory with no repo at all.
outside="$work/outside"
mkdir -p "$outside"
echo irreplaceable > "$outside/notes.txt"

check() { # <name> <cwd> <command> <allow|refuse>
  local name=$1 dir=$2 cmd=$3 want=$4 got
  if jq -nc --arg c "$cmd" --arg d "$dir" '{tool_input:{command:$c},cwd:$d}' \
    | "$hook" >/dev/null 2>&1; then
    got=allow
  else
    got=refuse
  fi
  if [[ "$got" != "$want" ]]; then
    echo "rm-guard-test: FAIL $name — wanted $want, got $got" >&2
    failed=1
  fi
}

check "tracked dir"      "$repo"    "rm -rf src"                    allow
check "untracked file"   "$repo"    "rm -rf scratch/untracked.txt" refuse
check "wildcard sweep"   "$repo"    "rm scratch/*"                      refuse
check "ignored dir"      "$repo"    "rm -rf node_modules"           allow
check "ignored .env"     "$repo"    "rm -rf scratch/.env"           refuse
check "env inside dir"   "$repo"    "rm -rf scratch"                refuse
check "outside any repo" "$outside" "rm -rf ."                      refuse
check "git rm"           "$repo"    "git rm -r src"                 allow
check "single named rm"  "$repo"    "rm scratch/untracked.txt"          allow
check "after &&"         "$repo"    "echo hi && rm -rf scratch/untracked.txt" refuse
check "find -delete"     "$outside" "find . -name '*.txt' -delete"  refuse
check "subdir cwd"       "$repo/scratch" "rm -rf untracked.txt"     refuse
check "parent hop"       "$repo/src" "rm -rf ../scratch"            refuse
check "tmp scratch"      "$work"    "rm -rf /tmp/scratch-dir"       allow

[[ "$failed" -eq 0 ]] || exit 1
echo "rm-guard-test: blocks the deletes git cannot undo, and nothing else"
