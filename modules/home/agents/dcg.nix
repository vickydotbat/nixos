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
#
# `dcg doctor` reports the hook as NOT REGISTERED because it compares the
# command string against the resolved store binary path without following the
# symlink. Cosmetic: the hook fires and blocks fine through the stable path.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.dcg;
  hookPath = "${config.home.homeDirectory}/.claude/dcg-hook";
  tomlFormat = pkgs.formats.toml { };
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

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          packs.enabled = [ "containers.podman" "database.sqlite" ];
        }
      '';
      description = ''
        Written to `~/.config/dcg/config.toml`. `dcg init` documents the full
        schema. `general.self_heal_hook` is forced off here: self-healing is
        what re-writes the hook to a garbage-collectable store path, and the
        activation script below owns the hook entry instead.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    theorem.home.agents.dcg.settings.general.self_heal_hook = false;

    xdg.configFile."dcg/config.toml".source = tomlFormat.generate "dcg-config.toml" cfg.settings;
    home.packages = [ cfg.package ];

    home.file.".claude/dcg-hook".source = "${cfg.package}/bin/dcg";

    home.activation.dcgClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      # Strip every dcg command (including store-path rewrites dcg itself
      # makes, even when merged into an entry alongside other hooks), drop
      # entries left empty, then prepend the canonical one. Writing through a
      # temp file keeps the original intact if jq chokes.
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg hook ${lib.escapeShellArg hookPath} \
        '
          .hooks.PreToolUse = (
            [{ matcher: "Bash|PowerShell",
               hooks: [{ type: "command", command: $hook }] }]
            + ((.hooks.PreToolUse // [])
               | map(.hooks |= map(select(.command | test("/dcg(-hook)?$") | not)))
               | map(select(.hooks | length > 0)))
          )
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
