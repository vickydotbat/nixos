#!/usr/bin/env bash
# What container-guard must and must not stop, driven the way Claude Code
# drives it: a JSON payload on stdin and an exit status. 0 allows, 2 refuses.
#
#   bash container-guard-test.sh [path to hook]
#
# Defaults to the installed hook, so the normal use is "rebuild, then run this".
set -euo pipefail

hook="${1:-$HOME/.claude/container-guard-hook}"
[[ -x "$hook" ]] || { echo "container-guard-test: no hook at $hook" >&2; exit 1; }
failed=0

expect() {
  local want=$1 cmd=$2 got=0
  jq -n --arg c "$cmd" '{tool_input: {command: $c}}' | "$hook" >/dev/null 2>&1 || got=$?
  if [[ $got -ne $want ]]; then
    echo "FAIL (want $want, got $got): $cmd" >&2
    failed=1
  fi
}

# No ceiling: refused, behind wrappers and the long spelling too.
expect 2 'podman run --rm alpine true'
expect 2 'timeout 60 docker run -d nginx'
expect 2 'docker container run nginx'
expect 2 'FOO=1 podman create img'

# A ceiling in any spelling passes.
expect 0 'cd x && podman run --memory=4g alpine true'
expect 0 'docker run --memory 4g alpine'
expect 0 'docker run -m 2g alpine'
expect 0 'podman run -m2g alpine'

# Not a container start.
expect 0 'docker ps -a'
expect 0 'docker compose up -d'
expect 0 'docker exec c /bin/true'
expect 0 'echo podman run is fine in text'

[[ $failed -eq 0 ]] && echo "container-guard-test: all cases pass"
exit "$failed"
