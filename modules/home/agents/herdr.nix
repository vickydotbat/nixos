# herdr, a terminal multiplexer for coding agents, in the
# theorem.home.agents namespace.
#
# herdr keeps its own config/session state under ~/.herdr and is managed
# imperatively (`herdr` writes it itself). Nix owns the binary version, so
# don't use herdr's self-updater; bump nixpkgs instead.
#
# The one piece Nix does own is the Claude Code integration. `herdr integration
# install claude` writes a hook script into ~/.claude/hooks and an entry into
# settings.json, both outside any generation and both invisible to a rebuild.
# The copy beside this file is that script, verbatim, installed at the path
# herdr itself looks at — `herdr integration status` reads that path to decide
# whether the integration is present, so taking it over is the only way to own
# it without herdr writing a second copy back.
#
# Owning it costs a pin. The vendored script speaks integration protocol
# version 9, and a newer herdr may expect a newer one. `integrationPinnedFor`
# is the version it was taken from, and the build warns when the package moves
# past it. Re-vendor then: run `herdr integration install claude` against a
# throwaway HOME, copy the file it writes over `herdr-claude-hook.sh`, and bump
# the pin.
{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.herdr;
  hookPath = "${config.home.homeDirectory}/.claude/hooks/herdr-agent-state.sh";
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
in
{
  options.theorem.home.agents.herdr = {
    enable = lib.mkEnableOption "herdr agent multiplexer";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.herdr;
      defaultText = lib.literalExpression "pkgs.herdr";
      description = "The herdr package to install.";
    };

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = "Persist `~/.herdr` (config, layouts, session state) when Home persistence is active.";
    };

    claudeHook = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Install herdr's Claude Code SessionStart hook declaratively, instead
          of letting `herdr integration install claude` write it into the home
          directory outside any generation.
        '';
      };

      timeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 10;
        description = ''
          Seconds Claude Code waits for the hook. It reports the session to a
          local socket with its own half-second timeout, so this bound only
          covers a herdr that is not answering at all.
        '';
      };

      integrationPinnedFor = lib.mkOption {
        type = lib.types.str;
        default = "0.9.0";
        description = ''
          The herdr version the vendored hook script was taken from. The build
          warns when the installed package differs, because the script carries
          an integration protocol version herdr may have moved past.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];
    })

    (lib.mkIf (cfg.enable && cfg.claudeHook.enable) {
      # Reported through `warnings` rather than `lib.warnIf`, which would force
      # the package version while the configuration that defines it is still
      # being built.
      warnings = lib.optional (cfg.package.version != cfg.claudeHook.integrationPinnedFor) ''
        theorem.home.agents.herdr: the Claude hook was vendored from herdr ${cfg.claudeHook.integrationPinnedFor}, but ${cfg.package.version} is installed.
        Re-vendor herdr-claude-hook.sh and bump integrationPinnedFor.
      '';

      # Verbatim, including its own `command -v python3 || exit 0` guard.
      # Wrapping it to pin an interpreter would change the behaviour of a
      # script herdr owns the contents of, for no gain: the guard already
      # makes a missing python3 a quiet no-op.
      home.file.".claude/hooks/herdr-agent-state.sh" = {
        source = ./herdr-claude-hook.sh;
        executable = true;
        # `herdr integration status` decides whether the integration is present
        # by reading this exact path. Install anywhere else and herdr believes
        # it is missing, writes its own copy back, and both run until a rebuild
        # strips one — the drift this module exists to end. `force` because the
        # hand-written copy is already sitting there.
        force = true;
      };

      home.activation.herdrClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings="${config.home.homeDirectory}/.claude/settings.json"

        $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
        [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

        # Strip any stale herdr entry, drop groups left empty, then append the
        # canonical one, quoted the way herdr writes it so a reinstall
        # produces a byte-identical line rather than a second entry. Writing
        # through a temp file keeps the original intact if jq chokes.
        $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
          --arg hook ${lib.escapeShellArg hookPath} \
          --arg q "'" \
          --argjson timeout ${toString cfg.claudeHook.timeout} \
          '
            .hooks.SessionStart = (
              ((.hooks.SessionStart // [])
               | map(.hooks |= map(select(.command | test("herdr-agent-state") | not)))
               | map(select(.hooks | length > 0)))
              + [{ matcher: "*",
                   hooks: [{ type: "command",
                             command: ("bash " + $q + $hook + $q + " session"),
                             timeout: $timeout }] }]
            )
          ' "$settings" > "$settings.tmp" \
          && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
      '';
    })

    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistState) {
        directories = [ ".herdr" ];
      };
    })
  ];
}
