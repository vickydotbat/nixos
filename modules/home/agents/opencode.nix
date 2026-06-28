{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.opencode;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
in
{
  options.theorem.home.agents.opencode = {
    enable = lib.mkEnableOption "OpenCode terminal AI agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.opencode;
      defaultText = lib.literalExpression "pkgs.opencode";
      description = "OpenCode package to install.";
    };

    persist = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist OpenCode configuration under `~/.config/opencode` when Home
        persistence is available. Disable this on hosts where the agent should
        begin with a blank configuration after each reboot.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];
    })

    # (lib.optionalAttrs hasHomePersistence {
    #   home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persist) {
    #     directories = [
    #       ".config/opencode"
    #     ];
    #   };
    # })
  ];
}
