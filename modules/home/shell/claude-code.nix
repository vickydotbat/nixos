# /nix/nixos/modules/home/shell/claude-code.nix
{
  config,
  lib,
  options,
  pkgs,
  repository ? {
    path = "/nix/nixos";
    group = "nixcfg";
  },
  ...
}:

let
  cfg = config.theorem.home.shell.claude;

  hasHomePersistence = (options ? home) && (options.home ? persistence);
  persistenceEnabled = config.theorem.home.base.persistence.enable or false;
in
{
  options.theorem.home.shell.claude = {
    enable = lib.mkEnableOption "Claude Code";

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = "Persist ~/.claude and ~/.claude.json across reboots.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ pkgs.claude-code ];
    })

    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistState) {
        directories = [ ".claude" ];
        files = [ ".claude.json" ];
      };
    })
  ];
}
