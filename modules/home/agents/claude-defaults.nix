{
  config,
  lib,
  pkgs,
  ...
}:

# Seeds defaults into ~/.claude/settings.json without taking ownership of it.
#
# `claude-code.nix` is package-only on purpose: Claude Code writes to that file
# (theme, effortLevel, and more), so home.file would fight it. But a few keys
# have no other home — `statusLine` and `permissions.defaultMode` are not
# plugin-provided the way hooks and skills turned out to be.
#
# So: write each key only when it is absent. First rebuild on a fresh system
# sets them; after that the file is yours, and edits stick. The cost is that
# changing a value here does not propagate to a machine that already has the
# key — delete it there and rebuild, or edit it directly.
#
# `marketplaces` and `plugins` are the exception: those two keys are merged in
# on every rebuild, so a plugin listed here is installed on every machine. They
# merge instead of replace, so plugins added by hand with `/plugin` stay.

let
  cfg = config.theorem.home.agents.claudeDefaults;

  ponytail = config.theorem.home.agents.ponytail;
  caveman = config.theorem.home.agents.caveman;

  # Both badge scripts read their own flag file, ignore stdin, and print a
  # bare fragment, so concatenating them is enough. Claude Code allows exactly
  # one statusLine command, which is why this wrapper exists at all.
  statusline = pkgs.writeShellScript "claude-statusline" (
    lib.concatStringsSep "\nprintf ' '\n" (
      lib.optional ponytail.enable "${ponytail.src}/hooks/ponytail-statusline.sh"
      ++ lib.optional caveman.enable "${caveman.src}/src/hooks/caveman-statusline.sh"
    )
  );

  # settings.json gets this stable path, not the store path directly: seeding
  # happens once, and a store path baked into the file would rot into a
  # garbage-collected reference on the next `nix flake update`.
  statuslinePath = "${config.home.homeDirectory}/.claude/statusline.sh";

  # `<name> = "<owner>/<repo>"` -> the shape settings.json wants.
  marketplaces = lib.mapAttrs (_: repo: {
    source = {
      source = "github";
      inherit repo;
    };
  }) cfg.marketplaces;
in
{
  options.theorem.home.agents.claudeDefaults = {
    enable = lib.mkEnableOption "seeded Claude Code settings defaults";

    permissionMode = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "default"
          "acceptEdits"
          "auto"
          "plan"
          "dontAsk"
          "bypassPermissions"
        ]
      );
      default = "auto";
      description = ''
        Permission mode new sessions start in, written to
        `permissions.defaultMode`. The CLI calls `default` "manual".

        `null` skips the key entirely. `bypassPermissions` disables every
        permission check and is not the same as `auto`.
      '';
    };

    outputStyle = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "ELI5";
      description = ''
        Name of the output style new sessions start in, written to
        `outputStyle`. Must match the `name:` of a style in
        `~/.claude/output-styles`. `null` skips the key entirely.
      '';
    };

    statusLine = lib.mkOption {
      type = lib.types.bool;
      default = ponytail.enable || caveman.enable;
      defaultText = lib.literalExpression "ponytail.enable || caveman.enable";
      description = "Seed a statusLine badge combining whichever of ponytail and caveman are enabled.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = {
        disableWorkflows = true;
      };
      description = ''
        Settings re-applied on every rebuild, for the policy keys that should
        be the same on every machine — what is switched off, what is denied.
        Merged recursively into `settings.json`, so untouched keys survive;
        a list here replaces the list in the file rather than adding to it.

        Anything you want to change from inside the CLI belongs in an option
        above instead, not here: this overwrites such an edit on next rebuild.
      '';
    };

    marketplaces = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        mattpocock = "mattpocock/skills";
      };
      description = ''
        Claude Code plugin marketplaces, as `<name> = "<owner>/<repo>"` on
        GitHub. Written to `extraKnownMarketplaces` on every rebuild.
      '';
    };

    plugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      example = {
        "mattpocock-skills@mattpocock" = true;
      };
      description = ''
        Plugins to enable (or explicitly disable), keyed
        `<plugin>@<marketplace>`. Written to `enabledPlugins` on every rebuild;
        Claude Code then downloads and updates them itself.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mkIf cfg.statusLine {
      ".claude/statusline.sh" = {
        source = statusline;
        executable = true;
        # old hand-written statusline.sh may exist on hosts configured before this module
        force = true;
      };
    };

    home.activation.claudeDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      # `// null` rather than `has`, so a key explicitly set to null still gets
      # seeded. Writing through a temp file keeps the original intact if jq
      # chokes on hand-edited JSON.
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg statusline ${lib.escapeShellArg statuslinePath} \
        --arg mode ${lib.escapeShellArg (toString cfg.permissionMode)} \
        --arg style ${lib.escapeShellArg (toString cfg.outputStyle)} \
        --argjson marketplaces ${lib.escapeShellArg (builtins.toJSON marketplaces)} \
        --argjson plugins ${lib.escapeShellArg (builtins.toJSON cfg.plugins)} \
        --argjson settings ${lib.escapeShellArg (builtins.toJSON cfg.settings)} \
        '
          . * $settings |
          .extraKnownMarketplaces = ((.extraKnownMarketplaces // {}) + $marketplaces) |
          .enabledPlugins = ((.enabledPlugins // {}) + $plugins) |
          ${lib.optionalString cfg.statusLine ''
            if (.statusLine // null) == null
            then .statusLine = { type: "command", command: $statusline }
            else . end |
          ''}
          ${lib.optionalString (cfg.outputStyle != null) ''
            if (.outputStyle // null) == null
            then .outputStyle = $style
            else . end |
          ''}
          ${lib.optionalString (cfg.permissionMode != null) ''
            if (.permissions.defaultMode // null) == null
            then .permissions.defaultMode = $mode
            else . end |
          ''}
          .
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
