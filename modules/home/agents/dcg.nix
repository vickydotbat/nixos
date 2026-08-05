# dcg (Destructive Command Guard), a PreToolUse hook that blocks dangerous
# shell commands (rm -rf /, git reset --hard, DROP TABLE, ...) before a coding
# agent runs them. https://github.com/Dicklesworthstone/destructive_command_guard
#
# Do not run `dcg install`: it writes the current store path of the binary into
# ~/.claude/settings.json, which rots into a dangling reference after the next
# flake update plus garbage collection. Instead this module links the binary at
# a stable path (~/.claude/dcg-hook) that Home Manager repoints on every
# rebuild, and pins the hook entry in settings.json to that path. dcg also
# "repairs" the entry back to a store path whenever it runs, so the activation
# script rewrites it every rebuild rather than only seeding it once.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.dcg;
  hookPath = "${config.home.homeDirectory}/.claude/dcg-hook";
in
{
  options.theorem.home.agents.dcg = {
    enable = lib.mkEnableOption "destructive-command guard hook for coding agents";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.dcg;
      defaultText = lib.literalExpression "pkgs.dcg";
      description = "The dcg package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".claude/dcg-hook".source = "${cfg.package}/bin/dcg";

    home.activation.dcgClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      # Drop any hook entry whose only command is dcg (including store-path
      # rewrites dcg itself makes), then prepend the canonical one. Writing
      # through a temp file keeps the original intact if jq chokes.
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg hook ${lib.escapeShellArg hookPath} \
        '
          .hooks.PreToolUse = (
            [{ matcher: "Bash|PowerShell",
               hooks: [{ type: "command", command: $hook }] }]
            + ((.hooks.PreToolUse // [])
               | map(select((.hooks | length == 1
                             and (.[0].command | test("/dcg(-hook)?$"))) | not)))
          )
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
