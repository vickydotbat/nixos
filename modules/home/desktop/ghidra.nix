{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.theorem.home.desktop.ghidra;
  hasHomePersistence = options.home ? persistence;
in
{
  options.theorem.home.desktop.ghidra = {
    enable = lib.mkEnableOption "Ghidra";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ghidra;
      defaultText = lib.literalExpression "pkgs.ghidra";
      description = "Ghidra package installed for this user.";
    };

    persistConfig = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.home.base.persistence.enable;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = "Persist Ghidra user configuration when Home persistence is active.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        cfg.package
      ];
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistConfig) {
        directories = [
          ".config/ghidra"
          ".ghidra"
        ];
      };
    })
  ];
}
