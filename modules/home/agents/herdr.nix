# herdr, a terminal multiplexer for coding agents, in the
# theorem.home.agents namespace.
#
# Package-only: herdr keeps its own config/session state under ~/.herdr and is
# managed imperatively (`herdr` writes it itself). Nix owns the binary version,
# so don't use herdr's self-updater; bump nixpkgs instead.
{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.herdr;
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
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistState) {
        directories = [ ".herdr" ];
      };
    })
  ];
}
