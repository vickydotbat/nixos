# rtk (Rust Token Killer), a CLI proxy that filters noisy command output before
# a coding agent has to read it, in the theorem.home.agents namespace.
#
# Package-only: rtk keeps its own state under ~/.local/share/rtk (a SQLite
# database behind `rtk gain`) and optional filters at ~/.config/rtk/filters.toml.
# Nix owns the binary version, so bump pkgs/rtk.nix rather than letting rtk
# update itself.
#
# Do not run `rtk init`. It writes a 148-line command table into CLAUDE.md and
# stamps HTML markers so it can rewrite the file later. The guidance this system
# actually uses is a short block in ~/.claude/CLAUDE.md instead.
{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.rtk;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
in
{
  options.theorem.home.agents.rtk = {
    enable = lib.mkEnableOption "rtk token-filtering CLI proxy";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.rtk;
      defaultText = lib.literalExpression "pkgs.rtk";
      description = "The rtk package to install.";
    };

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist `~/.local/share/rtk` (savings database) and `~/.config/rtk`
        (optional `filters.toml`) when Home persistence is active. Losing these
        costs only the `rtk gain` history; filtering itself keeps working.
      '';
    };

    telemetry = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Allow rtk's daily anonymous usage ping. Upstream ships this disabled and
        opt-in; this option exists so the choice is written down rather than
        assumed. When false, `RTK_TELEMETRY_DISABLED=1` is exported so an
        imperative `rtk telemetry enable` cannot silently turn it back on.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];

      home.sessionVariables = lib.mkIf (!cfg.telemetry) {
        RTK_TELEMETRY_DISABLED = "1";
      };
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistState) {
        directories = [
          ".local/share/rtk"
          ".config/rtk"
        ];
      };
    })
  ];
}
