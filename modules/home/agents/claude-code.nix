{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.claude;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
in
{
  options.theorem.home.agents.claude = {
    enable = lib.mkEnableOption "Claude Code terminal AI agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.claude-code;
      defaultText = lib.literalExpression "pkgs.claude-code";
      description = "Claude Code package to install.";
    };

    persist = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];
    })

    # (lib.optionalAttrs hasHomePersistence {
    #   home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persist) {
    #     directories = [
    #       ".claude"
    #     ];
    #   };
    # })
  ];
}
