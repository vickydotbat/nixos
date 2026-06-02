{
  config,
  lib,
  ...
}:

let
  cfg = config.vicky.nixos.base.boot;
in
{
  options.vicky.nixos.base.boot.enable = lib.mkEnableOption "base boot configuration";

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    boot.loader.efi.canTouchEfiVariables = true;
  };
}
