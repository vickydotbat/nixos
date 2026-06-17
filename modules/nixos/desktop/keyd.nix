{
  config,
  lib,
  ...
}:
let
  cfg = config.theorem.nixos.desktop.keyd;
in
{
  options.theorem.nixos.desktop.keyd = {
    enable = lib.mkEnableOption "keyd support";

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Host-specific keyd map configuration.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.keyd = {
      enable = true;
      keyboards = cfg.settings;
    };
  };
}
