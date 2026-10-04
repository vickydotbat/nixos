# container-guard, a PreToolUse hook that refuses a container started with no
# memory ceiling.
#
# On 2026-10-04 an agent's test left a local game server looping in a rootless
# container. It grew to 17 GB, pushed solanine into swap, and froze the machine
# into a reboot. `theorem.nixos.base.oom` now caps the user manager's
# `user.slice`, where every rootless container lives, so the machine survives a
# runaway. This hook is the nearer rail: a container an agent starts by hand
# carries its own `--memory`, so one runaway dies alone instead of starving
# every other container in the slice.
#
# It judges `podman run|create` and `docker run|create`, the `container`
# spelling included. Compose stacks are left to their compose files, which
# carry `mem_limit` where it matters, and to the slice ceiling behind them.
#
# Same wiring as rm-guard: a stable path (~/.claude/container-guard-hook) that
# Home Manager repoints on every rebuild, pinned into settings.json by a jq
# filter that only touches container-guard entries.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.containerGuard;
  hookPath = "${config.home.homeDirectory}/.claude/container-guard-hook";

  hook = pkgs.writeShellApplication {
    name = "container-guard-hook";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      payload=$(cat)
      command=$(jq -r '.tool_input.command // ""' <<<"$payload")

      # Cheap pre-filter: nothing here applies without a container verb.
      grep -Eq '(^|[^[:alnum:]_-])(podman|docker)([[:space:]]|$)' <<<"$command" || exit 0

      while IFS= read -r segment; do
        read -ra words <<<"$segment" || true
        [ ''${#words[@]} -gt 0 ] || continue

        # Step over wrappers so `timeout 60 podman run` is still judged.
        i=0
        while [ "$i" -lt ''${#words[@]} ]; do
          case "''${words[$i]}" in
            *=* | sudo | run0 | env | command | time | nohup | exec) i=$((i + 1)) ;;
            timeout) i=$((i + 2)) ;;
            *) break ;;
          esac
        done
        [ "$i" -lt ''${#words[@]} ] || continue

        verb=''${words[$i]##*/}
        case "$verb" in
          podman | docker) ;;
          *) continue ;;
        esac

        # The first word that is not a flag is the subcommand; `container`
        # is the long spelling and the real subcommand follows it.
        sub=""
        j=$((i + 1))
        while [ "$j" -lt ''${#words[@]} ]; do
          case "''${words[$j]}" in
            -*) ;;
            container) ;;
            *) sub=''${words[$j]}; break ;;
          esac
          j=$((j + 1))
        done
        case "$sub" in
          run | create) ;;
          *) continue ;;
        esac

        capped=0
        for word in "''${words[@]:$j}"; do
          case "$word" in
            -m | -m?* | --memory | --memory=*) capped=1 ;;
          esac
        done
        [ "$capped" -eq 1 ] && continue

        printf 'container-guard: refused. %s\n' \
          "'$verb $sub' starts a container with no memory ceiling." >&2
        printf '%s\n' \
          "Add --memory=<size> sized to the job, for example --memory=4g." \
          "A runaway container once froze this machine into a reboot." >&2
        exit 2
      done < <(tr ';&|\n' '\n' <<<"$command")

      exit 0
    '';
  };
in
{
  options.theorem.home.agents.containerGuard = {
    enable = lib.mkEnableOption "guard against containers started with no memory ceiling";
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/container-guard-hook".source = "${hook}/bin/container-guard-hook";

    home.activation.containerGuardClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg hook ${lib.escapeShellArg hookPath} \
        '
          .hooks.PreToolUse = (
            ((.hooks.PreToolUse // [])
             | map(.hooks |= map(select(.command | test("/container-guard-hook$") | not)))
             | map(select(.hooks | length > 0)))
            + [{ matcher: "Bash",
                 hooks: [{ type: "command", command: $hook }] }]
          )
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
