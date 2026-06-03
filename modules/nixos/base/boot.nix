{
  config,
  lib,
  ...
}:
#TODO: We always use boot. Break this up so it is always enabled by default, but allow different versions: Grub, possibly Lanzaboot options, etc.
let
  cfg = config.theorem.nixos.base.boot;
in
{
  options.theorem.nixos.base.boot.enable = lib.mkEnableOption "base boot configuration";

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    boot.loader.efi.canTouchEfiVariables = true;
  };
}
