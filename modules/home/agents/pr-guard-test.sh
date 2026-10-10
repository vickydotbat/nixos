#!/usr/bin/env bash
# What pr-guard must and must not stop, driven the way Claude Code drives it: a
# JSON payload on stdin, and an exit status. 0 means allowed, 2 means refused.
#
#   bash pr-guard-test.sh [path to hook]
#
# Defaults to the installed hook, so the normal use is "rebuild, then run this".
# The forge is stood in for by tiny `tea` and `gh` scripts on PATH, so the test
# never reaches a real server, and HOME points at a scratch folder so a real
# allowance is never spent.
set -euo pipefail

hook="${1:-$HOME/.claude/pr-guard-hook}"
[[ -x "$hook" ]] || { echo "pr-guard-test: no hook at $hook" >&2; exit 1; }

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/home/.claude"

# The stand-in forge answers from files the cases below write.
cat >"$scratch/bin/tea" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
  "api user") echo '{"login":"me","full_name":"Me Myself"}' ;;
  "pulls list") cat "$PR_GUARD_TEST_PULLS" ;;
  *) exit 1 ;;
esac
EOF
cat >"$scratch/bin/gh" <<'EOF'
#!/usr/bin/env bash
[[ "$1 $2" == "pr list" ]] && cat "$PR_GUARD_TEST_GH"
EOF
chmod +x "$scratch/bin/tea" "$scratch/bin/gh"
export PATH="$scratch/bin:$PATH" HOME="$scratch/home"
export PR_GUARD_TEST_PULLS="$scratch/pulls.json" PR_GUARD_TEST_GH="$scratch/gh.json"

# One repository on a feature branch, one on main.
repo() {
  git init -q -b main "$scratch/$1"
  git -C "$scratch/$1" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q --allow-empty -m init
  [[ $2 == main ]] || git -C "$scratch/$1" switch -q -c "$2"
}
repo feature feat/one
repo trunk main

failed=0

# SESSION, when set, goes in the payload as the session ID.
run() {
  local cwd=$1 tool=$2 input=$3
  printf '{"tool_name":"%s","cwd":"%s","session_id":"%s","tool_input":%s}' "$tool" "$cwd" "${SESSION:-}" "$input" \
    | "$hook" >/dev/null 2>&1 && echo 0 || echo $?
}
cmd() { printf '{"command":%s}' "$(printf '%s' "$1" | jq -Rs .)"; }

expect() {
  local want=$1 cwd=$2 command=$3 got
  got=$(run "$scratch/$cwd" Bash "$(cmd "$command")")
  [[ $got == "$want" ]] || { echo "FAIL want $want, got $got: ($cwd) $command"; failed=1; }
}

# Mine on feat/one, and somebody else's on their branch.
echo '[{"index":"7","head":"feat/one","author":"me"},{"index":"8","head":"theirs","author":"Someone Else"}]' >"$scratch/pulls.json"
echo '[{"number":7,"headRefName":"feat/one"}]' >"$scratch/gh.json"

# Untouched: reads, lists, and anything that is not a forge or git-spice.
expect 0 feature 'tea pr list'
expect 0 feature 'tea pulls 7 --comments'
expect 0 feature 'gh pr view 7 --comments'
expect 0 feature 'gs log short'
expect 0 feature 'git push'

# Updating the branch that already owns the open pull request.
expect 0 feature 'tea pr create --base main --head feat/one'
expect 0 feature 'gs branch submit'
expect 0 feature 'gh pr create --fill'

# A second pull request beside mine, by every door.
expect 2 feature 'tea pr create --base main --head feat/two'
expect 2 feature 'tea pulls create --head=feat/two'
expect 2 feature 'gh pr create --head feat/two'
expect 2 feature 'gs branch submit --branch feat/two'
expect 2 feature 'gs bs --branch feat/two'
expect 2 feature "tea api -X POST -d '{}' repos/o/r/pulls"
expect 2 trunk 'cd ../feature && tea pr create --head feat/two'

# Somebody else's open pull request is not mine to count.
echo '[{"index":"8","head":"theirs","author":"Someone Else"}]' >"$scratch/pulls.json"
expect 0 feature 'tea pr create --base main --head feat/two'

# Gitea names an author by full name when the account has one.
echo '[{"index":"9","head":"feat/one","author":"Me Myself"}]' >"$scratch/pulls.json"
expect 2 feature 'tea pr create --head feat/two'

# A stack, opened or submitted.
expect 2 feature 'gs stack submit'
expect 2 feature 'gs ss'
expect 2 feature 'gs upstack submit'
expect 2 feature 'gs branch create feat/two'
expect 2 feature 'gs bc feat/two'
expect 0 trunk 'gs branch create feat/two'

# With a session ID, one effort is one open pull request. Session A opens
# feat/a, so A's next pull request is refused while feat/a is open, and
# session B, another effort, opens its own.
echo '[{"index":"8","head":"theirs","author":"Someone Else"}]' >"$scratch/pulls.json"
SESSION=A expect 0 feature 'tea pr create --base main --head feat/a --title "Fix the cache (PLAT-1)"'
echo '[{"index":"10","head":"feat/a","author":"me","title":"Fix the cache (PLAT-1)"}]' >"$scratch/pulls.json"
SESSION=A expect 0 feature 'tea pr create --base main --head feat/a'
SESSION=A expect 2 feature 'tea pr create --base main --head feat/a2 --title "More (PLAT-9)"'
SESSION=A expect 2 feature "tea api -X POST -d '{}' repos/o/r/pulls"
SESSION=B expect 0 feature 'tea pr create --base main --head feat/b --title "Unrelated (GAME-2)"'

# An open pull request that names a ticket refuses another one naming it, from
# any session, whether the ticket is in the title or the branch name.
SESSION=C expect 2 feature 'tea pr create --base main --head feat/c --title "Two tickets (GAME-3, PLAT-1)"'
SESSION=C expect 2 feature 'tea pr create --base main --head plat-1-follow-up'
SESSION=C expect 0 feature 'tea pr create --base main --head feat/c --title "Other (PLAT-11)"'

# Once A's pull request is gone, A opens the next one.
echo '[]' >"$scratch/pulls.json"
SESSION=A expect 0 feature 'tea pr create --base main --head feat/a2 --title "More (PLAT-9)"'

# A depot/<user> pull request never counts, with or without a session.
echo '[{"index":"11","head":"depot/2","author":"me","title":"Depot changes (PLAT-1)"}]' >"$scratch/pulls.json"
expect 0 feature 'tea pr create --base main --head feat/two'
SESSION=D expect 0 feature 'tea pr create --base main --head feat/d --title "Fix (PLAT-1)"'
echo '[{"number":12,"headRefName":"depot/2","title":"Depot"}]' >"$scratch/gh.json"
expect 0 feature 'gh pr create --head feat/two'

# A forge that cannot answer is not a forge that said "none".
rm -f "$scratch/pulls.json"
expect 2 feature 'tea pr create --head feat/two'

# No AI credit in text sent to the forge, inline or through a body file.
printf 'Fixes the thing.\n' >"$scratch/clean.md"
printf 'Fixes the thing.\n\nGenerated with [Claude Code](https://claude.com/claude-code)\n' >"$scratch/footer.md"
printf 'Fixes the thing.\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n' >"$scratch/trailer.md"
expect 0 feature "tea comment 7 \"\$(cat $scratch/clean.md)\""
expect 2 feature "tea comment 7 \"\$(cat $scratch/footer.md)\""
expect 2 feature "tea pr edit 7 -d \"\$(cat $scratch/trailer.md)\""
expect 2 feature "gh pr edit 7 --body-file $scratch/footer.md"
expect 2 feature "gh issue comment 7 -F $scratch/trailer.md"
expect 2 feature 'gh pr edit 7 --body "Done. Generated with Claude Code"'
expect 0 feature 'gh pr edit 7 --body "Generated with the parser"'

# Only Vicky mints an allowance.
expect 2 feature 'touch ~/.claude/pr-guard-allow'
got=$(run "$scratch/feature" Write '{"file_path":"'"$HOME"'/.claude/pr-guard-allow","content":""}')
[[ $got == 2 ]] || { echo "FAIL Write of the allowance was not refused (exit $got)"; failed=1; }

# One allowance lets one refused command through, then it is spent.
touch "$HOME/.claude/pr-guard-allow"
expect 0 feature 'gs stack submit'
[[ ! -e $HOME/.claude/pr-guard-allow ]] || { echo "FAIL the allowance was not spent"; failed=1; }
expect 2 feature 'gs stack submit'

if [[ $failed -eq 0 ]]; then echo "pr-guard-test: all cases pass"; fi
exit "$failed"
